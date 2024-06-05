const std = @import("std");

const io = std.io;
const testing = std.testing;
const builtin = @import("builtin");

pub const Header = packed struct(u96) {
    ID: u16,

    QR: bool,
    OPCODE: OPCode,
    AA: bool,
    TC: bool,
    RD: bool,

    RA: bool,
    Z: u3 = {},
    RCODE: RCode,

    QDCOUNT: u16,
    ANCOUNT: u16,
    NSCOUNT: u16,
    ARCOUNT: u16,

    const Self = @This();

    pub const OPCode = enum(u4) {
        Query = 0,
        InverseQuery = 1,
        ServerStatusRequest = 2,
    };

    pub const RCode = enum(u4) {
        NoError = 0,
        FormatError = 1,
        ServerFailure = 2,
        NameError = 3,
        NotImplemented = 4,
        Refused = 5,
    };

    pub fn from_reader(byte_reader: anytype) !Self {
        var self = Self{};

        var reader = std.io.bitReader(.big, byte_reader);

        const fields = @typeInfo(Self).Struct.fields;
        inline for (fields) |field| {
            var out_bits: usize = undefined;
            @field(self, field.name) = switch (field.type) {
                bool => (try reader.readBits(u1, 1, &out_bits)) > 0,
                u3 => try reader.readBits(u3, 3, &out_bits),
                u4 => try reader.readBits(u4, 4, &out_bits),
                OPCode, RCode => blk: {
                    const tag_int = try reader.readBits(u4, 4, &out_bits);
                    break :blk try std.meta.intToEnum(field.type, tag_int);
                },
                u16 => try byte_reader.readInt(field.type, .big),
                else => @compileError(
                    "unsupported type on header " ++ @typeName(field.type),
                ),
            };
        }
        return self;
    }
};
