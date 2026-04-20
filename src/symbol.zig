const std = @import("std");

pub const SymbolTable = struct {
    _map: std.StringHashMap(u16),

    pub fn init(gpa: std.mem.Allocator) !SymbolTable {
        var map: std.StringHashMap(u16) = .init(gpa);

        _ = try map.put("SP", 0);
        _ = try map.put("LCL", 1);
        _ = try map.put("ARG", 2);
        _ = try map.put("THIS", 3);
        _ = try map.put("THAT", 4);
        _ = try map.put("R0", 0);
        _ = try map.put("R1", 1);
        _ = try map.put("R2", 2);
        _ = try map.put("R3", 3);
        _ = try map.put("R4", 4);
        _ = try map.put("R5", 5);
        _ = try map.put("R6", 6);
        _ = try map.put("R7", 7);
        _ = try map.put("R8", 8);
        _ = try map.put("R9", 9);
        _ = try map.put("R10", 10);
        _ = try map.put("R11", 11);
        _ = try map.put("R12", 12);
        _ = try map.put("R13", 13);
        _ = try map.put("R14", 14);
        _ = try map.put("R15", 15);
        _ = try map.put("SCREEN", 16384);
        _ = try map.put("KBD", 24576);

        return .{ ._map = map };
    }

    pub fn addEntry(self: *SymbolTable, symbol: []const u8, address: u16) !void {
        _ = try self._map.put(symbol, address);
    }

    pub fn getAddress(self: *SymbolTable, symbol: []const u8) ?u16 {
        return self._map.get(symbol);
    }

    pub fn deinit(self: *SymbolTable) void {
        self._map.deinit();
    }
};
