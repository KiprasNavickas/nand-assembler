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

    var symbol_table = try nand.SymbolTable.init(init.gpa);
    defer symbol_table.deinit();

    var parser = try nand.Parser.init(contents);
    while (true) {
        parser.advance() catch |err| {
            if (err == nand.AssemblerError.NoMoreCommands) {
                break;
            }

            return err;
        };

        switch (try parser.commandType()) {
            .L => {
                var line_no: u16 = undefined;
                if (parser.line_no == null) {
                    line_no = 0;
                } else {
                    line_no = parser.line_no.? + 1;
                }

                try symbol_table.addEntry(try parser.symbol(), line_no);
            },
            else => continue,
        }
    }

    parser = try nand.Parser.init(contents);
    while (true) {
        parser.advance() catch |err| {
            if (err == nand.AssemblerError.NoMoreCommands) {
                break;
            }

            return err;
        };

        var cmd: u16 = undefined;
        switch (try parser.commandType()) {
            .A => {
                const symbol = try parser.symbol();
                const uint_value: ?u16 = std.fmt.parseUnsigned(u16, symbol, 10) catch null;

                var addr: u16 = undefined;

                if (uint_value == null) {
                    const maybe_addr = symbol_table.getAddress(symbol);
                    if (maybe_addr == null) {
                        addr = try symbol_table.reserveNewAddress(symbol);
                    } else {
                        addr = maybe_addr.?;
                    }
                } else {
                    addr = uint_value.?;
                }

                cmd = addr;
            },
            .C => {
                cmd = try nand.encoding.encodeC(try parser.dest(), try parser.comp(), try parser.jump());
            },
            else => continue,
        }

        var buf: [17]u8 = undefined;
        _ = try std.fmt.bufPrint(&buf, "{b:0>16}\n", .{cmd});

        try assembled_list.appendSlice(init.gpa, &buf);
    }

    try writer.interface.writeAll(assembled_list.items);
    try writer.flush();
}
