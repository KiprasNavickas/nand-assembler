const std = @import("std");

pub const CommandType = enum { A, C, L };

pub const AssemblerError = error{NoMoreCommands};

pub const Parser = struct {
    iter: std.mem.TokenIterator(u8, .scalar),
    current_cmd: []const u8,

    pub fn init(input: []const u8) !Parser {
        var iter = std.mem.tokenizeScalar(u8, input, '\n');

        const next = iter.next();
        if (next == null) {
            return AssemblerError.NoMoreCommands;
        }

        return .{ .iter = iter, .current_cmd = next.? };
    }

    pub fn hasMoreCommands(self: *Parser) bool {
        return self.iter.peek() != null;
    }

    pub fn advance(self: *Parser) !void {
        const next = self.iter.next();
        if (next == null) {
            return AssemblerError.NoMoreCommands;
        }

        self.current_cmd = next.?;
    }

    pub fn commandType(self: *Parser) CommandType {
        return switch (self.current_cmd[0]) {
            '@' => .A,
            '(' => .L,
            else => .C,
        };
    }
};

const expectEqual = std.testing.expectEqual;
test "parser: command type" {
    var p = try Parser.init("@100");
    try expectEqual(.A, p.commandType());

    p = try Parser.init("(100)");
    try expectEqual(.L, p.commandType());

    p = try Parser.init("D=1");
    try expectEqual(.C, p.commandType());
}

fn parseCommand(cmd: []const u8) !Parser {
    try Parser.init(cmd);
}
