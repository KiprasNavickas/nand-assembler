const std = @import("std");
const types = @import("types.zig");

const AssemblerError = types.AssemblerError;

pub fn encodeC(dest: []const u8, comp: []const u8, jump: []const u8) !u16 {
    return (0b111 << 13) | (try encodeComp(comp) << 6) | (encodeDest(dest) << 3) | encodeJump(jump);
}

fn encodeDest(dest: []const u8) u16 {
    const a: u16 = if (std.mem.findScalar(u8, dest, 'A') != null) 0b100 else 0;
    const d: u16 = if (std.mem.findScalar(u8, dest, 'D') != null) 0b010 else 0;
    const m: u16 = if (std.mem.findScalar(u8, dest, 'M') != null) 0b001 else 0;

    return a | d | m;
}

fn encodeComp(comp: []const u8) !u16 {
    const eql = std.mem.eql;

    if (eql(u8, comp, "0")) {
        return 0b0101010;
    }

    if (eql(u8, comp, "1")) {
        return 0b0111111;
    }

    if (eql(u8, comp, "-1")) {
        return 0b0111010;
    }

    if (eql(u8, comp, "D")) {
        return 0b0001100;
    }

    if (eql(u8, comp, "A")) {
        return 0b0110000;
    }

    if (eql(u8, comp, "!D")) {
        return 0b0001101;
    }

    if (eql(u8, comp, "!A")) {
        return 0b0110001;
    }

    if (eql(u8, comp, "-D")) {
        return 0b0001111;
    }

    if (eql(u8, comp, "-A")) {
        return 0b0110011;
    }

    if (eql(u8, comp, "D+1")) {
        return 0b0011111;
    }

    if (eql(u8, comp, "A+1")) {
        return 0b0110111;
    }

    if (eql(u8, comp, "D-1")) {
        return 0b0011100;
    }

    if (eql(u8, comp, "A-1")) {
        return 0b0110010;
    }

    if (eql(u8, comp, "D+A")) {
        return 0b0000010;
    }

    if (eql(u8, comp, "D-A")) {
        return 0b0010011;
    }

    if (eql(u8, comp, "A-D")) {
        return 0b0000111;
    }

    if (eql(u8, comp, "D&A")) {
        return 0b0000000;
    }

    if (eql(u8, comp, "D|A")) {
        return 0b0010101;
    }

    if (eql(u8, comp, "M")) {
        return 0b1110000;
    }

    if (eql(u8, comp, "!M")) {
        return 0b1110001;
    }

    if (eql(u8, comp, "-M")) {
        return 0b1110011;
    }

    if (eql(u8, comp, "M+1")) {
        return 0b1110111;
    }

    if (eql(u8, comp, "M-1")) {
        return 0b1110010;
    }

    if (eql(u8, comp, "D+M")) {
        return 0b1000010;
    }

    if (eql(u8, comp, "D-M")) {
        return 0b1010011;
    }

    if (eql(u8, comp, "M-D")) {
        return 0b1000111;
    }

    if (eql(u8, comp, "D&M")) {
        return 0b1000000;
    }

    if (eql(u8, comp, "D|M")) {
        return 0b1010101;
    }

    return AssemblerError.InvalidC;
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

test encodeC {
    try expectEqual(0b1110110000010000, encodeC("D", "A", ""));
    try expectEqual(0b1110000010010000, encodeC("D", "D+A", ""));
    try expectEqual(0b1110001100001000, encodeC("M", "D", ""));
    try expectEqual(0b1110001100111111, encodeC("ADM", "D", "JMP"));
}
