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

    var assembled_list: std.ArrayList(u8) = .empty;
    defer assembled_list.deinit(init.gpa);
    try assembled_list.appendSlice(init.gpa, "hello from list\nagain new line");

    _ = try nand.Parser.init(contents);

    try writer.interface.writeAll(assembled_list.items);
    try writer.flush();
}
