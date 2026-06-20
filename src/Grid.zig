const std = @import("std");
const Color = @import("Color.zig").Color;
const Svg = @import("Svg.zig").Svg;
const PerlinGenerator = @import("perlin").PerlinGenerator;
const config = @import("config");


const CELL_SIZE = 100;
const BASE_PERLIN_FREQUENCY: f64 = 0.03;


pub const Direction = enum { NORTH, SOUTH, EAST, WEST };

pub const Grid = struct {
    cols: usize,
    rows: usize,
    /// Raw SVG bytes for each tile variant.
    tiles_svgs: [][]u8,
    colors: []Color,
    background_colors: []Color,
    seed: u64,
    tile_scale: f32,
    stroke_width: f32,
    stroke_opacity: f32,
    fill: bool,
    stroke: bool,
    fill_coef: f32,

    fade_direction: ?Direction,
    fade_start: ?f32,
    fade_end: ?f32,
    perlin_colors: bool,
    perlin_stroke_width: bool,
    perlin_colors_scale: f32,
    perlin_stroke_width_scale: f32,

    pub fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
        for (self.tiles_svgs) |s| allocator.free(s);

        allocator.free(self.tiles_svgs);
        allocator.free(self.colors);
        allocator.free(self.background_colors);
    }

    pub fn generate(self: *const Grid, allocator: std.mem.Allocator) ![]u8 {
        if (self.tiles_svgs.len == 0) return error.NoTiles;

        const grid_width = @as(f32, @floatFromInt(self.cols)) * CELL_SIZE;
        const grid_height = @as(f32, @floatFromInt(self.rows)) * CELL_SIZE;

        var pseudo_rng = std.Random.DefaultPrng.init(self.seed);
        const rng = pseudo_rng.random();

        var perlin: ?PerlinGenerator = null;
        if (self.perlin_colors or self.perlin_stroke_width) {
            perlin = try PerlinGenerator.init(&allocator, self.seed);
        }
        defer if (perlin) |*perlin_gen| perlin_gen.deinit();

        var color_noises: ?[]f64 = null;
        var stroke_noises: ?[]f64 = null;

        if (perlin != null) {
            if (self.perlin_colors) color_noises = try allocator.alloc(f64, self.cols * self.rows);
            if (self.perlin_stroke_width) stroke_noises = try allocator.alloc(f64, self.cols * self.rows);

            var color_min: f64 = std.math.inf(f64);
            var color_max: f64 = -std.math.inf(f64);
            var stroke_min: f64 = std.math.inf(f64);
            var stroke_max: f64 = -std.math.inf(f64);

            const color_freq = BASE_PERLIN_FREQUENCY * @as(f64, @floatCast(self.perlin_colors_scale));
            const stroke_freq = BASE_PERLIN_FREQUENCY * @as(f64, @floatCast(self.perlin_stroke_width_scale));

            for (0..self.cols) |col| {
                for (0..self.rows) |row| {
                    const noise_idx = col * self.rows + row;
                    if (color_noises) |color_noise_arr| {
                        const noise_val = @abs(perlin.?.get(@as(f64, @floatFromInt(col)) * color_freq, @as(f64, @floatFromInt(row)) * color_freq, 0.0));
                        color_noise_arr[noise_idx] = noise_val;
                        if (noise_val < color_min) color_min = noise_val;
                        if (noise_val > color_max) color_max = noise_val;
                    }
                    if (stroke_noises) |stroke_noise_arr| {
                        const noise_val = @abs(perlin.?.get(@as(f64, @floatFromInt(col)) * stroke_freq, @as(f64, @floatFromInt(row)) * stroke_freq, 1.234));
                        stroke_noise_arr[noise_idx] = noise_val;
                        if (noise_val < stroke_min) stroke_min = noise_val;
                        if (noise_val > stroke_max) stroke_max = noise_val;
                    }
                }
            }

            if (color_noises) |color_noise_arr| {
                const range = @max(color_max - color_min, 1e-10);
                for (0..color_noise_arr.len) |i| color_noise_arr[i] = (color_noise_arr[i] - color_min) / range;
            }
            if (stroke_noises) |stroke_noise_arr| {
                const range = @max(stroke_max - stroke_min, 1e-10);
                for (0..stroke_noise_arr.len) |i| stroke_noise_arr[i] = (stroke_noise_arr[i] - stroke_min) / range;
            }
        }
        defer if (color_noises) |color_noise_arr| allocator.free(color_noise_arr);
        defer if (stroke_noises) |stroke_noise_arr| allocator.free(stroke_noise_arr);

        var out: std.ArrayList(u8) = .empty;
        defer out.deinit(allocator);

        try appendFmt(&out, allocator,
            \\<svg xmlns="http://www.w3.org/2000/svg" width="{d:.2}" height="{d:.2}" viewBox="0 0 {d:.2} {d:.2}">
        , .{ grid_width, grid_height, grid_width, grid_height });

        const is_global_fading = try self.append_global_fade_defs(&out, allocator);
        const use_global_bg = try self.append_global_background(&out, allocator, grid_width, grid_height);

        for (0..self.rows) |row| {
            for (0..self.cols) |col| {
                const perlin_ptr = if (perlin) |*perlin_gen| perlin_gen else null;
                try self.emit_cell(&out, allocator, rng, perlin_ptr, color_noises, stroke_noises, row, col, use_global_bg);
            }
        }

        if (is_global_fading) {
            try out.appendSlice(allocator, "</g>");
        }

        try out.appendSlice(allocator, "</svg>");
        return out.toOwnedSlice(allocator);
    }

    fn append_global_fade_defs(self: *const Grid, out: *std.ArrayList(u8), allocator: std.mem.Allocator) !bool {
        const is_global_fading = config.global_fade and self.fade_direction != null;
        if (!is_global_fading) return false;

        const direction = self.fade_direction.?;
        var gradient_x1: f32 = 0.0; var gradient_y1: f32 = 0.0;
        var gradient_x2: f32 = 0.0; var gradient_y2: f32 = 0.0;

        switch (direction) {
            .SOUTH => { gradient_y2 = 1.0; },
            .NORTH => { gradient_y1 = 1.0; },
            .EAST  => { gradient_x2 = 1.0; },
            .WEST  => { gradient_x1 = 1.0; },
        }

        const start_percentage = (self.fade_start orelse 0.0) * 100.0;
        const end_percentage = (self.fade_end orelse 1.0) * 100.0;

        try appendFmt(out, allocator,
            \\<defs>
            \\  <linearGradient id="globalFadeGradient" x1="{d}" y1="{d}" x2="{d}" y2="{d}">
            \\    <stop offset="{d}%" stop-color="white" />
            \\    <stop offset="{d}%" stop-color="black" />
            \\  </linearGradient>
            \\  <mask id="globalFadeMask">
            \\    <rect x="0" y="0" width="100%" height="100%" fill="url(#globalFadeGradient)" />
            \\  </mask>
            \\</defs>
            \\<g mask="url(#globalFadeMask)">
        , .{ gradient_x1, gradient_y1, gradient_x2, gradient_y2, start_percentage, end_percentage });

        return true;
    }

    fn append_global_background(self: *const Grid, out: *std.ArrayList(u8), allocator: std.mem.Allocator, grid_width: f32, grid_height: f32) !bool {
        const use_global_bg = self.background_colors.len == 1 and (self.fade_direction == null or config.global_fade);

        if (use_global_bg) {
            var background_color_buf: [64]u8 = undefined;
            const background_str = try self.background_colors[0].format_rgba(&background_color_buf);
            try appendFmt(out, allocator,
                \\<rect x="0" y="0" width="{d:.2}" height="{d:.2}" fill="{s}" shape-rendering="crispEdges"/>
            , .{ grid_width, grid_height, background_str });
        }
        return use_global_bg;
    }

    fn emit_cell(
        self: *const Grid,
        out: *std.ArrayList(u8),
        allocator: std.mem.Allocator,
        rng: std.Random,
        perlin: ?*PerlinGenerator,
        color_noises: ?[]const f64,
        stroke_noises: ?[]const f64,
        row: usize,
        col: usize,
        use_global_bg: bool,
    ) !void {
        const n_tiles = self.tiles_svgs.len;
        const n_colors = self.colors.len;
        const n_bg_colors = self.background_colors.len;

        const tile_idx: usize = rng.uintLessThan(usize, n_tiles);

        const rot_steps: usize = rng.uintLessThan(usize, 4);
        const rotation = @as(f32, @floatFromInt(rot_steps)) * 90.0;

        const is_filled: bool = rng.float(f32) < self.fill_coef;

        const palette_color: ?Color = if (n_colors > 0) blk: {
            if (color_noises) |noises| {
                const nv = noises[col * self.rows + row];
                const last = @as(f64, @floatFromInt(n_colors - 1));
                const idx = @min(n_colors - 1, @as(usize, @intFromFloat(@round(nv * last))));
                break :blk self.colors[idx];
            } else {
                const ci: usize = rng.uintLessThan(usize, n_colors);
                break :blk self.colors[ci];
            }
        } else null;

        const bg_color: ?Color = if (n_bg_colors > 0) blk: {
            const ci: usize = rng.uintLessThan(usize, n_bg_colors);
            break :blk self.background_colors[ci];
        } else null;

        const cell_opacity = self.fade_factor(row, col);
        if (cell_opacity <= 0.0) return;

        const raw_copy = try allocator.dupe(u8, self.tiles_svgs[tile_idx]);
        var svg = Svg{ .raw_svg = raw_copy };
        defer svg.deinit(allocator);

        var fill_color_buf: [64]u8 = undefined;
        var stroke_color_buf: [64]u8 = undefined;
        var fill_str: ?[]const u8 = null;
        var stroke_str: ?[]const u8 = null;

        if (!self.fill) {
            fill_str = "none";
        } else if (is_filled and palette_color != null) {
            fill_str = try palette_color.?.format_rgba(&fill_color_buf);
        } else {
            fill_str = "none";
        }

        if (!self.stroke) {
            stroke_str = "none";
        } else if (palette_color != null) {
            stroke_str = try palette_color.?.format_rgb(&stroke_color_buf);
        }

        const rendered_size = CELL_SIZE * self.tile_scale;
        const offset = (CELL_SIZE - rendered_size) / 2.0;

        var dimension_x_buf: [32]u8 = undefined;
        const dimension_x = std.fmt.bufPrint(&dimension_x_buf, "{d:.4}", .{offset}) catch "0";
        var dimension_y_buf: [32]u8 = undefined;
        const dimension_y = std.fmt.bufPrint(&dimension_y_buf, "{d:.4}", .{offset}) catch "0";
        var dimension_width_buf: [32]u8 = undefined;
        const dimension_width = std.fmt.bufPrint(&dimension_width_buf, "{d:.4}", .{rendered_size}) catch "0";
        var dimension_height_buf: [32]u8 = undefined;
        const dimension_height = std.fmt.bufPrint(&dimension_height_buf, "{d:.4}", .{rendered_size}) catch "0";

        var stroke_width_buf: [32]u8 = undefined;
        var stroke_width_str: ?[]const u8 = null;
        var perlin_ctx: ?@import("Svg.zig").PerlinContext = null;

        if (self.perlin_stroke_width and perlin != null) {
            perlin_ctx = .{
                .perlin = perlin.?,
                .col = col,
                .row = row,
                .freq = BASE_PERLIN_FREQUENCY * @as(f64, @floatCast(self.perlin_stroke_width_scale)),
                .base_stroke_width = self.stroke_width,
            };
        } else {
            var cell_stroke_width = self.stroke_width;
            if (stroke_noises) |noises| {
                const nv = noises[col * self.rows + row];
                cell_stroke_width = self.stroke_width * @as(f32, @floatCast(0.1 + nv * 1.9));
            }
            stroke_width_str = std.fmt.bufPrint(&stroke_width_buf, "{d:.4}", .{cell_stroke_width}) catch "1.0";
        }

        const translate_x = @as(f32, @floatFromInt(col)) * CELL_SIZE;
        const translate_y = @as(f32, @floatFromInt(row)) * CELL_SIZE;

        const center_x = CELL_SIZE / 2.0;
        const center_y = CELL_SIZE / 2.0;

        try appendFmt(out, allocator,
            \\<g transform="translate({d:.2},{d:.2}) rotate({d:.2},{d:.2},{d:.2})" opacity="{d:.4}">
        , .{ translate_x, translate_y, rotation, center_x, center_y, cell_opacity });

        if (bg_color) |bg| {
            if (!use_global_bg) {
                var background_color_buf: [64]u8 = undefined;
                const background_str = try bg.format_rgba(&background_color_buf);
                try appendFmt(out, allocator,
                    \\<rect x="0" y="0" width="{d:.2}" height="{d:.2}" fill="{s}" shape-rendering="crispEdges"/>
                , .{ CELL_SIZE, CELL_SIZE, background_str });
            }
        }

        var stroke_opacity_buf: [32]u8 = undefined;
        var stroke_opacity_str: ?[]const u8 = null;
        if (self.stroke_opacity < 1.0) {
            stroke_opacity_str = std.fmt.bufPrint(&stroke_opacity_buf, "{d:.4}", .{self.stroke_opacity}) catch "1.0";
        }

        try svg.apply_cell_attributes(allocator, fill_str, stroke_str, stroke_width_str, stroke_opacity_str, perlin_ctx, dimension_x, dimension_y, dimension_width, dimension_height);

        try out.appendSlice(allocator, svg.raw_svg);
        try out.appendSlice(allocator, "</g>");
    }

    fn fade_factor(self: *const Grid, row: usize, col: usize) f32 {
        if (config.global_fade) return 1.0;

        const direction = self.fade_direction orelse return 1.0;
        const fade_start_val = self.fade_start orelse return 1.0;
        const fade_end_val = self.fade_end orelse return 1.0;
        if (fade_start_val >= fade_end_val) return 1.0;

        const position: f32 = switch (direction) {
            .NORTH => 1.0 - @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(self.rows)),
            .SOUTH => @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(self.rows)),
            .WEST => 1.0 - @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(self.cols)),
            .EAST => @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(self.cols)),
        };

        if (position <= fade_start_val) return 1.0;
        if (position >= fade_end_val) return 0.0;
        return 1.0 - (position - fade_start_val) / (fade_end_val - fade_start_val);
    }
};

fn appendFmt(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    var buf: [256]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, fmt, args) catch {
        const hs = try std.fmt.allocPrint(allocator, fmt, args);
        defer allocator.free(hs);
        try out.appendSlice(allocator, hs);
        return;
    };
    try out.appendSlice(allocator, s);
}
