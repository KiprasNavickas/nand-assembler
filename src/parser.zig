const std = @import("std");

const types = @import("types.zig");
const AssemblerError = types.AssemblerError;
const CommandType = types.CommandType;

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

    pub fn symbol(self: *Parser) ![]const u8 {
        if (self.commandType() == .A) {
            return self.current_cmd[1..];
        }

        if (self.commandType() == .L) {
            return self.current_cmd[1 .. self.current_cmd.len - 1];
        }

        return AssemblerError.InvalidSymbol;
    }

    pub fn dest(self: *Parser) ![]const u8 {
        if (self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var iter = std.mem.tokenizeScalar(u8, self.current_cmd, '=');
        if (iter.next()) |dst| {
            if (iter.peek() == null) {
                return "";
            }

            return dst;
        }

        return "";
    }

    pub fn comp(self: *Parser) ![]const u8 {
        if (self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var i: usize = 0;
        if (std.mem.findScalar(u8, self.current_cmd, '=')) |found_i| {
            i = found_i + 1;
        }

        const j = std.mem.findScalar(u8, self.current_cmd, ';') orelse self.current_cmd.len;
        if (j - i == 0) {
            return AssemblerError.NoCompInC;
        }

        return self.current_cmd[i..j];
    }

    pub fn jump(self: *Parser) ![]const u8 {
        if (self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var iter = std.mem.tokenizeScalar(u8, self.current_cmd, ';');
        _ = iter.next();
        if (iter.next()) |jmp| {
            return jmp;
        }

        return "";
    }
};

const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

test "parser: advancing" {
    try expectError(AssemblerError.NoMoreCommands, Parser.init(""));

    var p = try Parser.init("D=M");
    try expectEqual(false, p.hasMoreCommands());

    p = try Parser.init("D=M\n@50");
    try expectEqual(true, p.hasMoreCommands());
    try p.advance();
    try expectEqual(false, p.hasMoreCommands());

    p = try Parser.init("D=M\n@50\nM=1");
    try expectEqual(true, p.hasMoreCommands());
    try p.advance();
    try expectEqual(true, p.hasMoreCommands());
    try p.advance();
    try expectEqual(false, p.hasMoreCommands());
}

test "parser: command type" {
    var p = try Parser.init("@100");
    try expectEqual(.A, p.commandType());

    p = try Parser.init("(100)");
    try expectEqual(.L, p.commandType());

    p = try Parser.init("D=1");
    try expectEqual(.C, p.commandType());
}

test "parser: symbol" {
    var p = try Parser.init("@123\n(456)\ndest=comp;jump");
    try expectEqualStrings("123", try p.symbol());

    try p.advance();
    try expectEqualStrings("456", try p.symbol());

    try p.advance();
    try expectError(AssemblerError.InvalidSymbol, p.symbol());
}

test "parser: dest/comp/jump" {
    var p = try Parser.init("M=M+1\nD=0;JMP\n1;JEQ\n@123\n(456)\n;JMP");

    try expectEqualStrings("M", try p.dest());
    try expectEqualStrings("M+1", try p.comp());
    try expectEqualStrings("", try p.jump());

    try p.advance();
    try expectEqualStrings("D", try p.dest());
    try expectEqualStrings("0", try p.comp());
    try expectEqualStrings("JMP", try p.jump());

    try p.advance();
    try expectEqualStrings("", try p.dest());
    try expectEqualStrings("1", try p.comp());
    try expectEqualStrings("JEQ", try p.jump());

    try p.advance();
    try expectError(AssemblerError.ExpectedC, p.dest());
    try expectError(AssemblerError.ExpectedC, p.comp());
    try expectError(AssemblerError.ExpectedC, p.jump());

    try p.advance();
    try expectError(AssemblerError.ExpectedC, p.dest());
    try expectError(AssemblerError.ExpectedC, p.comp());
    try expectError(AssemblerError.ExpectedC, p.jump());

    try p.advance();
    try expectError(AssemblerError.NoCompInC, p.comp());
}
