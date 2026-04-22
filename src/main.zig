const std = @import("std");

const nand = @import("nand");

pub fn main(init: std.process.Init) !void {
    const stdin = std.Io.File.stdin();
    const stdout = std.Io.File.stdout();

    var file_buffer: [4096]u8 = undefined;
    var reader = stdin.reader(init.io, &file_buffer);
    var writer = stdout.writer(init.io, &file_buffer);

    const contents = try reader.interface.allocRemaining(init.gpa, std.Io.Limit.unlimited);
    defer init.gpa.free(contents);

    var assembled: std.ArrayList(u8) = .empty;
    defer assembled.deinit(init.gpa);

    try nand.assemble(init.gpa, contents, &assembled);

    try writer.interface.writeAll(assembled.items);
    try writer.flush();
}
