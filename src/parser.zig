const std = @import("std");

const types = @import("types.zig");
const AssemblerError = types.AssemblerError;
const CommandType = types.CommandType;

pub const Parser = struct {
    iter: std.mem.TokenIterator(u8, .scalar),
    current_cmd: ?[]const u8,
    line_no: ?u16,

    pub fn init(input: []const u8) !Parser {
        const iter = std.mem.tokenizeScalar(u8, input, '\n');

        return .{ .iter = iter, .current_cmd = null, .line_no = null };
    }

    pub fn advance(self: *Parser) !void {
        while (self.iter.next()) |next| {
            const trimmed = std.mem.trim(u8, next, " ");

            if (trimmed.len == 0) {
                continue;
            }

            if (trimmed[0] == '/') {
                if (trimmed[1] == '/') {
                    continue;
                }

                return AssemblerError.InvalidCommand;
            }

            if (self.line_no == null) {
                self.line_no = 0;
            } else {
                self.line_no = self.line_no.? + 1;
            }

            self.current_cmd = trimmed;
            return;
        }

        return AssemblerError.NoMoreCommands;
    }

    pub fn commandType(self: *Parser) !CommandType {
        if (self.current_cmd == null) {
            return AssemblerError.NoCommand;
        }

        return switch (self.current_cmd.?[0]) {
            '@' => .A,
            '(' => .L,
            else => .C,
        };
    }

    pub fn symbol(self: *Parser) ![]const u8 {
        if (try self.commandType() == .A) {
            return self.current_cmd.?[1..];
        }

        if (try self.commandType() == .L) {
            return self.current_cmd.?[1 .. self.current_cmd.?.len - 1];
        }

        return AssemblerError.InvalidSymbol;
    }

    pub fn dest(self: *Parser) ![]const u8 {
        if (try self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var iter = std.mem.tokenizeScalar(u8, self.current_cmd.?, '=');
        if (iter.next()) |dst| {
            if (iter.peek() == null) {
                return "";
            }

            return dst;
        }

        return "";
    }

    pub fn comp(self: *Parser) ![]const u8 {
        if (try self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var i: usize = 0;
        if (std.mem.findScalar(u8, self.current_cmd.?, '=')) |found_i| {
            i = found_i + 1;
        }

        const j = std.mem.findScalar(u8, self.current_cmd.?, ';') orelse self.current_cmd.?.len;
        if (j - i == 0) {
            return AssemblerError.NoCompInC;
        }

        return self.current_cmd.?[i..j];
    }

    pub fn jump(self: *Parser) ![]const u8 {
        if (try self.commandType() != .C) {
            return AssemblerError.ExpectedC;
        }

        var iter = std.mem.tokenizeScalar(u8, self.current_cmd.?, ';');
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
    var p = try Parser.init("");
    try expectEqual(null, p.line_no);
    try expectError(AssemblerError.NoMoreCommands, p.advance());
    try expectEqual(null, p.line_no);

    p = try Parser.init("D=M");
    try p.advance();
    try expectEqual(0, p.line_no);
    try expectError(AssemblerError.NoMoreCommands, p.advance());
    try expectEqual(0, p.line_no);

    p = try Parser.init("D=M\n@50");
    try p.advance();
    try expectEqual(0, p.line_no);
    try p.advance();
    try expectEqual(1, p.line_no);
    try expectError(AssemblerError.NoMoreCommands, p.advance());
    try expectEqual(1, p.line_no);

    p = try Parser.init("D=M\n@50\nM=1");
    try p.advance();
    try expectEqual(0, p.line_no);
    try p.advance();
    try expectEqual(1, p.line_no);
    try p.advance();
    try expectEqual(2, p.line_no);
    try expectError(AssemblerError.NoMoreCommands, p.advance());
    try expectEqual(2, p.line_no);
}

test "parser: advancing w/ comments and whitespace" {
    var p = try Parser.init("// comment\n\n\n   \n    D=M\n   0;JMP   ");

    try expectEqual(null, p.line_no);

    try p.advance();
    try expectEqualStrings("D=M", p.current_cmd.?);
    try expectEqual(0, p.line_no);

    try p.advance();
    try expectEqualStrings("0;JMP", p.current_cmd.?);
    try expectEqual(1, p.line_no);

    try expectError(AssemblerError.NoMoreCommands, p.advance());
    try expectEqual(1, p.line_no);
}
test "parser: command type" {
    var p = try Parser.init("@100");
    try p.advance();
    try expectEqual(.A, try p.commandType());

    p = try Parser.init("(100)");
    try p.advance();
    try expectEqual(.L, try p.commandType());

    p = try Parser.init("D=1");
    try p.advance();
    try expectEqual(.C, try p.commandType());
}

test "parser: symbol" {
    var p = try Parser.init("@123\n(456)\ndest=comp;jump");
    try p.advance();
    try expectEqualStrings("123", try p.symbol());

    try p.advance();
    try expectEqualStrings("456", try p.symbol());

    try p.advance();
    try expectError(AssemblerError.InvalidSymbol, p.symbol());
}

test "parser: dest/comp/jump" {
    var p = try Parser.init("M=M+1\nD=0;JMP\n1;JEQ\n@123\n(456)\n;JMP");
    try p.advance();

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
