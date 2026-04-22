const std = @import("std");
const nand = @import("nand");

fn expectAssembles(source: []const u8, expected: []const u8) !void {
    const gpa = std.testing.allocator;
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(gpa);

    try nand.assemble(gpa, source, &out);
    try std.testing.expectEqualStrings(expected, out.items);
}

test "e2e: Add" {
    try expectAssembles(
        @embedFile("asm/Add.asm"),
        @embedFile("binary/Add_expected"),
    );
}

test "e2e: Max" {
    try expectAssembles(
        @embedFile("asm/Max.asm"),
        @embedFile("binary/Max_expected"),
    );
}

test "e2e: MaxL" {
    try expectAssembles(
        @embedFile("asm/MaxL.asm"),
        @embedFile("binary/MaxL_expected"),
    );
}

test "e2e: Pong" {
    try expectAssembles(
        @embedFile("asm/Pong.asm"),
        @embedFile("binary/Pong_expected"),
    );
}

test "e2e: Rect" {
    try expectAssembles(
        @embedFile("asm/Rect.asm"),
        @embedFile("binary/Rect_expected"),
    );
}
