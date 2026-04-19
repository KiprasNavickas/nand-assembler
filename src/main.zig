const std = @import("std");

const nand = @import("nand");

pub fn main(init: std.process.Init) !void {
    const stdin = std.Io.File.stdin();

    var file_buffer: [4096]u8 = undefined;
    var reader = stdin.reader(init.io, &file_buffer);

    const contents = try reader.interface.allocRemaining(init.gpa, std.Io.Limit.unlimited);
    defer init.gpa.free(contents);

    var parser = try nand.Parser.init(contents);
    std.debug.print("Hello: {any}\n", .{parser.hasMoreCommands()});
}
