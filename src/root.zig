const typ = @import("typ");
const std = @import("std");
const xml = @import("xml");
const Grid = @import("Grid.zig").Grid;
const Direction = @import("Grid.zig").Direction;
const Color = @import("Color.zig").Color;
const zbor = @import("zbor");

const allocator = std.heap.page_allocator;

var prng: std.Random.DefaultPrng = undefined;
var initialized: bool = false;

///   #let rng = p.init(bytes("my-seed-2024"))
export fn init(len: usize) i32 {
    const buf = typ.alloc(u8, len) catch return typ.err("init: alloc failed");
    defer typ.free(buf);
    typ.write(buf.ptr);
    const seed = std.hash.XxHash64.hash(0, buf);
    prng = std.Random.DefaultPrng.init(seed);
    initialized = true;
    return typ.str("ok");
}

export fn tiler(
    cols_len: usize,
    rows_len: usize,
    tile_strings_len: usize,
    color_hexes_len: usize,
    bg_color_hexes_len: usize,
    stroke_width_len: usize,
    fill_coef_len: usize,
    fill_len: usize,
    stroke_len: usize,
    perlin_colors_len: usize,
    perlin_stroke_width_len: usize,
    perlin_colors_scale_len: usize,
    perlin_stroke_width_scale_len: usize,

    stroke_opacity_len: usize,
    fade_dir_str_len: usize,
    fade_start_len: usize,
    fade_width_len: usize,
    tile_scale_len: usize,
    seed_len: usize,
) i32 {
    const total = cols_len
        + rows_len
        + tile_strings_len
        + color_hexes_len
        + bg_color_hexes_len
        + stroke_width_len
        + fill_coef_len
        + fill_len
        + stroke_len
        + perlin_colors_len
        + perlin_stroke_width_len
        + perlin_colors_scale_len
        + perlin_stroke_width_scale_len

        + stroke_opacity_len
        + fade_dir_str_len
        + fade_start_len
        + fade_width_len
        + tile_scale_len
        + seed_len;

    const param_buffer = typ.alloc(u8, total) catch return typ.err("tiler: alloc failed");
    defer typ.free(param_buffer);
    typ.write(param_buffer.ptr);

    var off: usize = 0;
    const cols_bytes = param_buffer[off..][0..cols_len];
    off += cols_len;
    const rows_bytes = param_buffer[off..][0..rows_len];
    off += rows_len;
    const tile_strings_bytes = param_buffer[off..][0..tile_strings_len];
    off += tile_strings_len;
    const color_hexes_bytes = param_buffer[off..][0..color_hexes_len];
    off += color_hexes_len;
    const bg_color_hexes_bytes = param_buffer[off..][0..bg_color_hexes_len];
    off += bg_color_hexes_len;
    const stroke_width_bytes = param_buffer[off..][0..stroke_width_len];
    off += stroke_width_len;
    const fill_coef_bytes = param_buffer[off..][0..fill_coef_len];
    off += fill_coef_len;
    const fill_bytes = param_buffer[off..][0..fill_len];
    off += fill_len;
    const stroke_bytes = param_buffer[off..][0..stroke_len];
    off += stroke_len;
    const perlin_colors_bytes = param_buffer[off..][0..perlin_colors_len];
    off += perlin_colors_len;
    const perlin_stroke_width_bytes = param_buffer[off..][0..perlin_stroke_width_len];
    off += perlin_stroke_width_len;
    const perlin_colors_scale_bytes = param_buffer[off..][0..perlin_colors_scale_len];
    off += perlin_colors_scale_len;
    const perlin_stroke_width_scale_bytes = param_buffer[off..][0..perlin_stroke_width_scale_len];
    off += perlin_stroke_width_scale_len;

    const stroke_opacity_bytes = param_buffer[off..][0..stroke_opacity_len];
    off += stroke_opacity_len;
    const fade_dir_str_bytes = param_buffer[off..][0..fade_dir_str_len];
    off += fade_dir_str_len;
    const fade_start_bytes = param_buffer[off..][0..fade_start_len];
    off += fade_start_len;
    const fade_width_bytes = param_buffer[off..][0..fade_width_len];
    off += fade_width_len;
    const tile_scale_bytes = param_buffer[off..][0..tile_scale_len];
    off += tile_scale_len;
    const seed_bytes = param_buffer[off..][0..seed_len];

    const cols_di = zbor.DataItem.new(cols_bytes) catch |e| return typ.errf("[ZBOR] failed to parse cols: {s}", .{@errorName(e)});
    const rows_di = zbor.DataItem.new(rows_bytes) catch |e| return typ.errf("[ZBOR] failed to parse rows: {s}", .{@errorName(e)});
    const tile_strings_di = zbor.DataItem.new(tile_strings_bytes) catch |e| return typ.errf("[ZBOR] failed to parse tile_strings: {s}", .{@errorName(e)});
    const color_hexes_di = zbor.DataItem.new(color_hexes_bytes) catch |e| return typ.errf("[ZBOR] failed to parse color_hexes: {s}", .{@errorName(e)});
    const bg_color_hexes_di = zbor.DataItem.new(bg_color_hexes_bytes) catch |e| return typ.errf("[ZBOR] failed to parse bg_color_hexes: {s}", .{@errorName(e)});
    const stroke_width_di = zbor.DataItem.new(stroke_width_bytes) catch |e| return typ.errf("[ZBOR] failed to parse stroke_width: {s}", .{@errorName(e)});
    const fill_coef_di = zbor.DataItem.new(fill_coef_bytes) catch |e| return typ.errf("[ZBOR] failed to parse fill_coef: {s}", .{@errorName(e)});
    const fill_di = zbor.DataItem.new(fill_bytes) catch |e| return typ.errf("[ZBOR] failed to parse fill: {s}", .{@errorName(e)});
    const stroke_di = zbor.DataItem.new(stroke_bytes) catch |e| return typ.errf("[ZBOR] failed to parse stroke: {s}", .{@errorName(e)});
    const perlin_colors_di = zbor.DataItem.new(perlin_colors_bytes) catch |e| return typ.errf("[ZBOR] failed to parse perlin_colors: {s}", .{@errorName(e)});
    const perlin_stroke_width_di = zbor.DataItem.new(perlin_stroke_width_bytes) catch |e| return typ.errf("[ZBOR] failed to parse perlin_stroke_width: {s}", .{@errorName(e)});
    const perlin_colors_scale_di = zbor.DataItem.new(perlin_colors_scale_bytes) catch |e| return typ.errf("[ZBOR] failed to parse perlin_colors_scale: {s}", .{@errorName(e)});
    const perlin_stroke_width_scale_di = zbor.DataItem.new(perlin_stroke_width_scale_bytes) catch |e| return typ.errf("[ZBOR] failed to parse perlin_stroke_width_scale: {s}", .{@errorName(e)});

    const stroke_opacity_di = zbor.DataItem.new(stroke_opacity_bytes) catch |e| return typ.errf("[ZBOR] failed to parse stroke_opacity: {s}", .{@errorName(e)});
    const fade_dir_str_di = zbor.DataItem.new(fade_dir_str_bytes) catch |e| return typ.errf("[ZBOR] failed to parse fade_dir_str: {s}", .{@errorName(e)});
    const fade_start_di = zbor.DataItem.new(fade_start_bytes) catch |e| return typ.errf("[ZBOR] failed to parse fade_start: {s}", .{@errorName(e)});
    const fade_width_di = zbor.DataItem.new(fade_width_bytes) catch |e| return typ.errf("[ZBOR] failed to parse fade_width: {s}", .{@errorName(e)});
    const tile_scale_di = zbor.DataItem.new(tile_scale_bytes) catch |e| return typ.errf("[ZBOR] failed to parse tile_scale: {s}", .{@errorName(e)});
    const seed_di = zbor.DataItem.new(seed_bytes) catch |e| return typ.errf("[ZBOR] failed to parse final_seed: {s}", .{@errorName(e)});

    const cols = zbor.parse(usize, cols_di, .{ .allocator = allocator }) catch |e| return typ.errf("cols parse failed: {s}", .{@errorName(e)});
    const rows = zbor.parse(usize, rows_di, .{ .allocator = allocator }) catch |e| return typ.errf("rows parse failed: {s}", .{@errorName(e)});
    const tile_strings = zbor.parse([][]u8, tile_strings_di, .{ .allocator = allocator }) catch |e| return typ.errf("tile_strings parse failed: {s}", .{@errorName(e)});
    const color_hexes = zbor.parse([][]u8, color_hexes_di, .{ .allocator = allocator }) catch |e| return typ.errf("color_hexes parse failed: {s}", .{@errorName(e)});
    const bg_color_hexes = zbor.parse([][]u8, bg_color_hexes_di, .{ .allocator = allocator }) catch |e| return typ.errf("bg_color_hexes parse failed: {s}", .{@errorName(e)});
    const stroke_width = zbor.parse(f32, stroke_width_di, .{ .allocator = allocator }) catch |e| return typ.errf("stroke_width parse failed: {s}", .{@errorName(e)});
    const fill_coef = zbor.parse(f32, fill_coef_di, .{ .allocator = allocator }) catch |e| return typ.errf("fill_coef parse failed: {s}", .{@errorName(e)});
    const fill = zbor.parse(bool, fill_di, .{ .allocator = allocator }) catch |e| return typ.errf("fill parse failed: {s}", .{@errorName(e)});
    const stroke = zbor.parse(bool, stroke_di, .{ .allocator = allocator }) catch |e| return typ.errf("stroke parse failed: {s}", .{@errorName(e)});
    const perlin_colors = zbor.parse(bool, perlin_colors_di, .{ .allocator = allocator }) catch |e| return typ.errf("perlin_colors parse failed: {s}", .{@errorName(e)});
    const perlin_stroke_width = zbor.parse(bool, perlin_stroke_width_di, .{ .allocator = allocator }) catch |e| return typ.errf("perlin_stroke_width parse failed: {s}", .{@errorName(e)});
    const perlin_colors_scale = zbor.parse(f32, perlin_colors_scale_di, .{ .allocator = allocator }) catch |e| return typ.errf("perlin_colors_scale parse failed: {s}", .{@errorName(e)});
    const perlin_stroke_width_scale = zbor.parse(f32, perlin_stroke_width_scale_di, .{ .allocator = allocator }) catch |e| return typ.errf("perlin_stroke_width_scale parse failed: {s}", .{@errorName(e)});

    const stroke_opacity = zbor.parse(f32, stroke_opacity_di, .{ .allocator = allocator }) catch |e| return typ.errf("stroke_opacity parse failed: {s}", .{@errorName(e)});
    const fade_dir_str = zbor.parse([]u8, fade_dir_str_di, .{ .allocator = allocator }) catch |e| return typ.errf("fade_dir_str parse failed: {s}", .{@errorName(e)});
    const fade_start = zbor.parse(f32, fade_start_di, .{ .allocator = allocator }) catch |e| return typ.errf("fade_start parse failed: {s}", .{@errorName(e)});
    const fade_width = zbor.parse(f32, fade_width_di, .{ .allocator = allocator }) catch |e| return typ.errf("fade_width parse failed: {s}", .{@errorName(e)});
    const tile_scale = zbor.parse(f32, tile_scale_di, .{ .allocator = allocator }) catch |e| return typ.errf("tile_scale parse failed: {s}", .{@errorName(e)});
    const seed = zbor.parse([]u8, seed_di, .{ .allocator = allocator }) catch |e| return typ.errf("final_seed parse failed: {s}", .{@errorName(e)}); 

    var color_array = allocator.alloc(Color, color_hexes.len) catch |e| return typ.errf("OOM: {s}", .{@errorName(e)});
    errdefer allocator.free(color_array);
    for (color_hexes, 0..) |hex, i| {
        color_array[i] = Color.from_hex(hex) catch |e| return typ.errf("Color parse: {s}", .{@errorName(e)});
    }

    var background_color_array = allocator.alloc(Color, bg_color_hexes.len) catch |e| return typ.errf("OOM: {s}", .{@errorName(e)});
    errdefer allocator.free(background_color_array);
    for (bg_color_hexes, 0..) |hex, i| {
        background_color_array[i] = Color.from_hex(hex) catch |e| return typ.errf("Color parse: {s}", .{@errorName(e)});
    }

    var h: u64 = 2166136261;
    for (seed) |b| {
        h ^= b;
        h *%= 16777619;
    }
    const parsed_seed = h;

    const fade_direction: ?Direction = if (fade_dir_str.len == 3) switch (fade_dir_str[0]) {
        'l' => .EAST,
        'r' => .WEST,
        't' => .SOUTH,
        'b' => .NORTH,
        else => null,
    } else null;

    var grid = Grid{
        .cols = cols,
        .rows = rows,
        .tiles_svgs = tile_strings,
        .colors = color_array,
        .background_colors = background_color_array,
        .stroke_width = stroke_width,
        .tile_scale = tile_scale,
        .seed = parsed_seed,
        .fill = fill,
        .stroke = stroke,

        .stroke_opacity = stroke_opacity,
        .fill_coef = fill_coef,
        .fade_direction = fade_direction,
        .fade_start = fade_start,
        .fade_end = fade_start + fade_width,
        .perlin_colors = perlin_colors,
        .perlin_stroke_width = perlin_stroke_width,
        .perlin_colors_scale = perlin_colors_scale,
        .perlin_stroke_width_scale = perlin_stroke_width_scale,
    };

    defer grid.deinit(allocator);

    const svg = grid.generate(allocator) catch |e| {
        return typ.errf("tiler: generate failed: {s}", .{@errorName(e)});
    };
    defer allocator.free(svg);

    return typ.send(svg, 0);
}

export fn parse_xml(len: usize) i32 {
    const buf = typ.alloc(u8, len) catch return typ.err("parse_xml: alloc failed");
    defer typ.free(buf);
    typ.write(buf.ptr);

    var static_reader: xml.Reader.Static = .init(allocator, buf, .{});
    defer static_reader.deinit();
    const reader = &static_reader.interface;

    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(allocator);

    var depth: usize = 0;
    while (true) {
        const node = reader.read() catch |read_err| {
            switch (read_err) {
                error.MalformedXml => {
                    const code = reader.errorCode();
                    const loc = reader.errorLocation();
                    return typ.errf("parse_xml: malformed XML at {}:{} — {s}", .{ loc.line, loc.column, @tagName(code) });
                },
                error.ReadFailed => return typ.err("parse_xml: read failed"),
                else => return typ.err("parse_xml: unexpected error"),
            }
        };
        switch (node) {
            .eof => break,
            .element_start => {
                out.appendNTimes(allocator, ' ', depth) catch return typ.err("OOM");
                out.append(allocator, '<') catch return typ.err("OOM");
                out.appendSlice(allocator, reader.elementName()) catch return typ.err("OOM");
                const n = reader.attributeCount();
                for (0..n) |i| {
                    const av = reader.attributeValue(i) catch return typ.err("OOM");
                    out.append(allocator, ' ') catch return typ.err("OOM");
                    out.appendSlice(allocator, reader.attributeName(i)) catch return typ.err("OOM");
                    out.appendSlice(allocator, "=\"") catch return typ.err("OOM");
                    out.appendSlice(allocator, av) catch return typ.err("OOM");
                    out.append(allocator, '"') catch return typ.err("OOM");
                }
                out.appendSlice(allocator, ">\n") catch return typ.err("OOM");
                depth += 1;
            },
            .element_end => {
                if (depth > 0) depth -= 1;
                out.appendNTimes(allocator, ' ', depth) catch return typ.err("OOM");
                out.appendSlice(allocator, "</") catch return typ.err("OOM");
                out.appendSlice(allocator, reader.elementName()) catch return typ.err("OOM");
                out.appendSlice(allocator, ">\n") catch return typ.err("OOM");
            },
            else => {},
        }
    }
    return typ.send(out.items, 0);
}
