const std = @import("std");
const Io = std.Io;

const nand = @import("nand");

pub fn main() !void {
    var parser = try nand.Parser.init("@100\nD=A\nD=D+A");
    try parser.advance();
    try parser.advance();
    std.debug.print("Hello: {any}\n", .{parser.hasMoreCommands()});

    const c = nand.encoding.encodeC("", "", "");
    std.debug.print("C: {b}\n", .{c});
}
