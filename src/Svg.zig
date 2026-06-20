const std = @import("std");
const Color = @import("Color.zig").Color;
const xml = @import("xml");
const PerlinGenerator = @import("perlin").PerlinGenerator;

const shape_tags = std.StaticStringMap(void).initComptime(.{
    .{ "path", {} },
    .{ "rect", {} },
    .{ "circle", {} },
    .{ "ellipse", {} },
    .{ "line", {} },
    .{ "polyline", {} },
    .{ "polygon", {} },
    .{ "text", {} },
    .{ "tspan", {} },
    .{ "use", {} },
});

fn is_shape(name: []const u8) bool {
    return shape_tags.get(name) != null;
}

const Override = struct {
    name: []const u8,
    value: []const u8,
    inject_if_absent: bool,
};

/// Append the current `element_start` node to `out`, applying zero or more
/// attribute overrides.  All non-overridden attributes are passed through
/// verbatim (so entity refs are preserved).
fn emit_element_start(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    reader: *xml.Reader,
    overrides: []const Override,
) !void {
    var matched = [_]bool{false} ** 16; // max 16 overrides
    const n_ov = @min(overrides.len, 16);

    try out.append(allocator, '<');
    try out.appendSlice(allocator, reader.elementName());

    const n_attrs = reader.attributeCount();
    for (0..n_attrs) |i| {
        const aname = reader.attributeName(i);
        const aval_raw = reader.attributeValueRaw(i);

        var replaced = false;
        for (overrides[0..n_ov], 0..) |ov, ov_i| {
            if (std.mem.eql(u8, ov.name, aname)) {
                matched[ov_i] = true;
                if (ov.value.len > 0) {
                    try out.append(allocator, ' ');
                    try out.appendSlice(allocator, aname);
                    try out.appendSlice(allocator, "=\"");
                    try out.appendSlice(allocator, ov.value);
                    try out.append(allocator, '"');
                }
                replaced = true;
                break;
            }
        }

        if (!replaced) {
            try out.append(allocator, ' ');
            try out.appendSlice(allocator, aname);
            try out.appendSlice(allocator, "=\"");
            try out.appendSlice(allocator, aval_raw);
            try out.append(allocator, '"');
        }
    }

    for (overrides[0..n_ov], 0..) |ov, ov_i| {
        if (!matched[ov_i] and ov.inject_if_absent and ov.value.len > 0) {
            try out.append(allocator, ' ');
            try out.appendSlice(allocator, ov.name);
            try out.appendSlice(allocator, "=\"");
            try out.appendSlice(allocator, ov.value);
            try out.append(allocator, '"');
        }
    }

    try out.append(allocator, '>');
}

fn emit_verbatim(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    reader: *xml.Reader,
    node: xml.Reader.Node,
) !void {
    switch (node) {
        .eof => {},

        .xml_declaration => {},

        .element_start => try emit_element_start(out, allocator, reader, &.{}),

        .element_end => {
            try out.appendSlice(allocator, "</");
            try out.appendSlice(allocator, reader.elementName());
            try out.append(allocator, '>');
        },

        .text => try out.appendSlice(allocator, reader.textRaw()),

        .cdata => {
            try out.appendSlice(allocator, "<![CDATA[");
            try out.appendSlice(allocator, reader.cdataRaw());
            try out.appendSlice(allocator, "]]>");
        },

        .comment => {
            try out.appendSlice(allocator, "<!--");
            try out.appendSlice(allocator, reader.commentRaw());
            try out.appendSlice(allocator, "-->");
        },

        .pi => {
            try out.appendSlice(allocator, "<?");
            try out.appendSlice(allocator, reader.piTarget());
            const d = reader.piDataRaw();
            if (d.len > 0) {
                try out.append(allocator, ' ');
                try out.appendSlice(allocator, d);
            }
            try out.appendSlice(allocator, "?>");
        },

        .character_reference => {
            try out.appendSlice(allocator, "&#");
            try out.appendSlice(allocator, reader.characterReferenceName());
            try out.append(allocator, ';');
        },

        .entity_reference => {
            try out.append(allocator, '&');
            try out.appendSlice(allocator, reader.entityReferenceName());
            try out.append(allocator, ';');
        },
    }
}

const MatchFn = *const fn (element_name: []const u8) bool;

fn match_svg(name: []const u8) bool {
    return std.mem.eql(u8, name, "svg");
}

fn match_shape(name: []const u8) bool {
    return is_shape(name);
}

pub const PerlinContext = struct {
    perlin: *PerlinGenerator,
    col: usize,
    row: usize,
    freq: f64,
    base_stroke_width: f32,
};

pub const Svg = struct {
    raw_svg: []u8,

    pub fn deinit(self: Svg, allocator: std.mem.Allocator) void {
        allocator.free(self.raw_svg);
    }

    pub fn apply_cell_attributes(
        self: *Svg,
        allocator: std.mem.Allocator,
        fill_str: ?[]const u8,
        stroke_str: ?[]const u8,
        stroke_width_str: ?[]const u8,
        stroke_opacity_str: ?[]const u8,
        perlin_ctx: ?PerlinContext,
        dim_x: []const u8,
        dim_y: []const u8,
        dim_w: []const u8,
        dim_h: []const u8,
    ) !void {
        var sr: xml.Reader.Static = .init(allocator, self.raw_svg, .{});
        defer sr.deinit();
        const reader = &sr.interface;

        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);

        var shape_index: usize = 0;

        while (true) {
            const node = try reader.read();
            if (node == .eof) break;

            if (node == .element_start) {
                const ename = reader.elementName();
                if (match_svg(ename)) {
                    const ov = [_]Override{
                        .{ .name = "x", .value = dim_x, .inject_if_absent = true },
                        .{ .name = "y", .value = dim_y, .inject_if_absent = true },
                        .{ .name = "width", .value = dim_w, .inject_if_absent = true },
                        .{ .name = "height", .value = dim_h, .inject_if_absent = true },
                        .{ .name = "overflow", .value = "visible", .inject_if_absent = true },
                    };
                    try emit_element_start(&out, allocator, reader, &ov);
                } else if (match_shape(ename)) {
                    var ov_buf: [8]Override = undefined;
                    var ov_count: usize = 0;

                    if (fill_str) |fs| {
                        ov_buf[ov_count] = .{ .name = "fill", .value = fs, .inject_if_absent = true };
                        ov_count += 1;
                        ov_buf[ov_count] = .{ .name = "fill-opacity", .value = "", .inject_if_absent = false };
                        ov_count += 1;
                    }
                    if (stroke_str) |ss| {
                        ov_buf[ov_count] = .{ .name = "stroke", .value = ss, .inject_if_absent = true };
                        ov_count += 1;
                        if (stroke_opacity_str) |sos| {
                            ov_buf[ov_count] = .{ .name = "stroke-opacity", .value = sos, .inject_if_absent = true };
                        } else {
                            ov_buf[ov_count] = .{ .name = "stroke-opacity", .value = "", .inject_if_absent = false };
                        }
                        ov_count += 1;
                    }

                    var sw_buf: [32]u8 = undefined;
                    if (perlin_ctx) |ctx| {
                        const px = @as(f64, @floatFromInt(ctx.col)) * ctx.freq;
                        const py = @as(f64, @floatFromInt(ctx.row)) * ctx.freq;
                        const pz = 1.234 + @as(f64, @floatFromInt(shape_index)) * 0.5;
                        const nv = @abs(ctx.perlin.get(px, py, pz));
                        const sw = ctx.base_stroke_width * @as(f32, @floatCast(0.1 + nv * 1.9));

                        const sw_str = std.fmt.bufPrint(&sw_buf, "{d:.4}", .{sw}) catch "1.0";
                        ov_buf[ov_count] = .{ .name = "stroke-width", .value = sw_str, .inject_if_absent = true };
                        ov_count += 1;
                        shape_index += 1;
                    } else if (stroke_width_str) |sws| {
                        ov_buf[ov_count] = .{ .name = "stroke-width", .value = sws, .inject_if_absent = true };
                        ov_count += 1;
                    }

                    try emit_element_start(&out, allocator, reader, ov_buf[0..ov_count]);
                } else {
                    try emit_verbatim(&out, allocator, reader, node);
                }
            } else {
                try emit_verbatim(&out, allocator, reader, node);
            }
        }

        const new = try out.toOwnedSlice(allocator);
        allocator.free(self.raw_svg);
        self.raw_svg = new;
    }
};
