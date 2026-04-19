pub const CommandType = enum { A, C, L };

pub const AssemblerError = error{ NoMoreCommands, InvalidSymbol, ExpectedC, NoCompInC };
