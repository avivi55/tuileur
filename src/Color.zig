const std = @import("std");

pub const ColorError = error{
    InvalidLength,
    MissingHash,
    InvalidCharacter,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: f32, // [0.0; 1.0]

    /// Parse a hex color string of the form `#RRGGBB` or `#RRGGBBAA`.
    pub fn from_hex(color_hex: []const u8) ColorError!Color {
        if (color_hex.len == 0 or color_hex[0] != '#')
            return ColorError.MissingHash;

        const hex = color_hex[1..]; // strip leading '#'

        if (hex.len != 6 and hex.len != 8)
            return ColorError.InvalidLength;

        const r = std.fmt.parseInt(u8, hex[0..2], 16) catch return ColorError.InvalidCharacter;
        const g = std.fmt.parseInt(u8, hex[2..4], 16) catch return ColorError.InvalidCharacter;
        const b = std.fmt.parseInt(u8, hex[4..6], 16) catch return ColorError.InvalidCharacter;

        const a: f32 = if (hex.len == 8) blk: {
            const alpha_byte = std.fmt.parseInt(u8, hex[6..8], 16) catch return ColorError.InvalidCharacter;
            break :blk @as(f32, @floatFromInt(alpha_byte)) / 255.0;
        } else 1.0;

        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn format_rgba(self: Color, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(
            buf,
            "rgba({d},{d},{d},{d:.6})",
            .{ self.r, self.g, self.b, self.a },
        );
    }

    pub fn format_rgb(self: Color, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(
            buf,
            "rgb({d},{d},{d})",
            .{ self.r, self.g, self.b },
        );
    }
};

test "from_hex: #RRGGBB, fully opaque" {
    const c = try Color.from_hex("#ff8800");
    try std.testing.expectEqual(@as(u8, 0xff), c.r);
    try std.testing.expectEqual(@as(u8, 0x88), c.g);
    try std.testing.expectEqual(@as(u8, 0x00), c.b);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), c.a, 1e-6);
}

test "from_hex: #RRGGBBAA with 50% alpha" {
    const c = try Color.from_hex("#ff000080");
    try std.testing.expectEqual(@as(u8, 0xff), c.r);
    try std.testing.expectEqual(@as(u8, 0x00), c.g);
    try std.testing.expectEqual(@as(u8, 0x00), c.b);
    // 0x80 = 128, 128/255 ≈ 0.502
    try std.testing.expectApproxEqAbs(@as(f32, 128.0 / 255.0), c.a, 1e-4);
}

test "from_hex: missing hash" {
    try std.testing.expectError(ColorError.MissingHash, Color.from_hex("ff0000"));
}

test "from_hex: invalid length" {
    try std.testing.expectError(ColorError.InvalidLength, Color.from_hex("#fff"));
}

test "from_hex: invalid character" {
    try std.testing.expectError(ColorError.InvalidCharacter, Color.from_hex("#zz0000"));
}
