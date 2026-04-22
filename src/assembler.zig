const std = @import("std");
const parser_mod = @import("parser.zig");
const encoding = @import("encoding.zig");
const types = @import("types.zig");
const symbol_mod = @import("symbol.zig");

const Parser = parser_mod.Parser;
const SymbolTable = symbol_mod.SymbolTable;
const AssemblerError = types.AssemblerError;

pub fn assemble(gpa: std.mem.Allocator, source: []const u8, out: *std.ArrayList(u8)) !void {
    var symbol_table = try SymbolTable.init(gpa);
    defer symbol_table.deinit();

    var parser = try Parser.init(source);
    while (true) {
        parser.advance() catch |err| {
            if (err == AssemblerError.NoMoreCommands) break;
            return err;
        };

        switch (try parser.commandType()) {
            .L => {
                const line_no: u16 = if (parser.line_no) |n| n + 1 else 0;
                try symbol_table.addEntry(try parser.symbol(), line_no);
            },
            else => continue,
        }
    }

    parser = try Parser.init(source);
    while (true) {
        parser.advance() catch |err| {
            if (err == AssemblerError.NoMoreCommands) break;
            return err;
        };

        var cmd: u16 = undefined;
        switch (try parser.commandType()) {
            .A => {
                const symbol = try parser.symbol();
                const uint_value: ?u16 = std.fmt.parseUnsigned(u16, symbol, 10) catch null;

                if (uint_value) |v| {
                    cmd = v;
                } else if (symbol_table.getAddress(symbol)) |addr| {
                    cmd = addr;
                } else {
                    cmd = try symbol_table.reserveNewAddress(symbol);
                }
            },
            .C => {
                cmd = try encoding.encodeC(try parser.dest(), try parser.comp(), try parser.jump());
            },
            else => continue,
        }

        var buf: [17]u8 = undefined;
        _ = try std.fmt.bufPrint(&buf, "{b:0>16}\n", .{cmd});
        try out.appendSlice(gpa, &buf);
    }
}

