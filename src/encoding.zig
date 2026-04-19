const std = @import("std");
const types = @import("types.zig");

pub fn encodeC(dest: []const u8, comp: []const u8, jump: []const u8) u16 {
    return (0b111 << 13) + (encodeDest(dest) << 10) + (encodeComp(comp) << 3) + encodeJump(jump);
}

fn encodeDest(dest: []const u8) u16 {
    const a: u16 = if (std.mem.findScalar(u8, dest, 'A') != null) 0b100 else 0;
    const d: u16 = if (std.mem.findScalar(u8, dest, 'D') != null) 0b010 else 0;
    const m: u16 = if (std.mem.findScalar(u8, dest, 'M') != null) 0b001 else 0;

    return a | d | m;
}

fn encodeComp(_: []const u8) u16 {
    return 0b1100111;
}

fn encodeJump(jump: []const u8) u16 {
    const eql = std.mem.eql;

    if (eql(u8, jump, "JGT")) {
        return 0b001;
    }

    if (eql(u8, jump, "JEQ")) {
        return 0b010;
    }

    if (eql(u8, jump, "JGE")) {
        return 0b011;
    }

    if (eql(u8, jump, "JLT")) {
        return 0b100;
    }

    if (eql(u8, jump, "JNE")) {
        return 0b101;
    }

    if (eql(u8, jump, "JLE")) {
        return 0b110;
    }

    if (eql(u8, jump, "JMP")) {
        return 0b111;
    }

    return 0b000;
}

const expectEqual = std.testing.expectEqual;
test encodeDest {
    try expectEqual(0b100, encodeDest("A"));
    try expectEqual(0b010, encodeDest("D"));
    try expectEqual(0b001, encodeDest("M"));
    try expectEqual(0b110, encodeDest("AD"));
    try expectEqual(0b101, encodeDest("AM"));
    try expectEqual(0b011, encodeDest("DM"));
    try expectEqual(0b111, encodeDest("ADM"));
    try expectEqual(0b000, encodeDest(""));
}
