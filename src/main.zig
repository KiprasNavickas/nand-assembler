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

    var parser = try nand.Parser.init(contents);
    var cmd: u16 = undefined;
    switch (parser.commandType()) {
        .A => {
            cmd = try nand.encoding.encodeA(try parser.symbol());
        },
        .C => {
            cmd = try nand.encoding.encodeC(try parser.dest(), try parser.comp(), try parser.jump());
        },
        else => @panic("only C and A commands supported currently"),
    }

    var buf: [17]u8 = undefined;
    _ = try std.fmt.bufPrint(&buf, "{b:0>16}\n", .{cmd});

    try assembled_list.appendSlice(init.gpa, &buf);

    try writer.interface.writeAll(assembled_list.items);
    try writer.flush();
}
