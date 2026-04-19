const std = @import("std");
const types = @import("types.zig");

pub fn encodeC(dest: []const u8, comp: []const u8, jump: []const u8) u16 {
    return (0b111 << 13) + (encodeDest(dest) << 10) + (encodeComp(comp) << 3) + encodeJump(jump);
}

fn encodeDest(_: []const u8) u16 {
    return 0b101;
}
fn encodeComp(_: []const u8) u16 {
    return 0b1100111;
}
fn encodeJump(_: []const u8) u16 {
    return 0b011;
}

test "testing" {
    try std.testing.expectEqual(0b1111011100111011, encodeC("", "", ""));
}
