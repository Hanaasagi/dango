const std = @import("std");
const testing = std.testing;

pub const Error = error{ValueIsNull};

const OptionTag = enum {
    some,
    none,
};

pub fn Option(comptime T: type) type {
    return union(OptionTag) {
        some: T,
        none,

        const Self = @This();

        pub fn init(v: ?T) Self {
            if (v == null) {
                return Self.none;
            }
            return Self{ .some = v.? };
        }

        pub fn and_(self: Self, optb: anytype) @TypeOf(optb) {
            switch (self) {
                OptionTag.some => {
                    var res = @TypeOf(optb).init(null);
                    return res;
                },
                OptionTag.none => return optb,
            }
        }

        pub fn isSome(self: Self) bool {
            switch (self) {
                OptionTag.some => return true,
                OptionTag.none => return false,
            }
        }

        pub fn isNone(self: Self) bool {
            switch (self) {
                OptionTag.some => return false,
                OptionTag.none => return true,
            }
        }

        pub fn unwrap(self: Self) !T {
            switch (self) {
                OptionTag.some => return self.some,
                OptionTag.none => return Error.ValueIsNull,
            }
        }
    };
}

pub fn Some(v: anytype) Option(@TypeOf(v)) {
    return Option(@TypeOf(v)).init(v);
}

pub fn None(comptime T: type) Option(T) {
    return Option(T).init(null);
}

// --------------------------------------------------------------------------------
//                                   Testing
// --------------------------------------------------------------------------------

test "test isSome" {
    var s = "hello";
    const some_str = Some(s);

    try testing.expect(some_str.isSome());
}

test "test isNone" {
    const some_str = None([]const u8);

    try testing.expect(some_str.isNone());
}

test "test and_" {
    const some_str = Some("hello");
    const some_str2 = None([]const u8);

    try testing.expect(some_str.and_(some_str2).isNone());
    try testing.expect(some_str2.and_(some_str).isSome());
}

test "test unwrap" {
    const num: i32 = 2;
    const some_num = Some(num);
    try testing.expect(try some_num.unwrap() == 2);
}
