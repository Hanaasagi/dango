const std = @import("std");
const DeriveIterator = @import("derive.zig").DeriveIterator;

const testing = std.testing;

pub fn Range(comptime T: type) type {
    return struct {
        pub const Self: type = @This();
        pub const Item: type = T;
        pub usingnamespace DeriveIterator(@This());

        start: T,
        end: ?T,

        cur: T,

        pub fn init(start: T, end: ?T) Self {
            return .{ .start = start, .end = end, .cur = start };
        }

        pub fn contains(self: Self, value: T) bool {
            if (self.start > value) {
                return false;
            }
            if (self.end == null or self.end.? > value) {
                return true;
            }
            return false;
        }

        pub fn lengthHint(self: Self) ?usize {
            if (self.end) |end| {
                return @intCast(end - self.start);
            }
            return null;
        }

        pub fn next(self: *Self) ?Item {
            if (self.end != null and self.cur >= self.end.?) {
                return null;
            }
            const cur = self.cur;
            self.cur += @as(T, 1);
            return cur;
        }
    };
}

pub fn range(start: anytype, end: ?@TypeOf(start)) Range(@TypeOf(start)) {
    return Range(@TypeOf(start)).init(start, end);
}

test "test range" {
    var iter = range(@as(u64, 10), @as(u64, 100));

    for (10..100) |i| {
        try testing.expectEqual(@as(u64, i), iter.next().?);
    }
    try testing.expect(iter.next() == null);
}

test "test range step" {
    var iter = range(@as(u64, 1), @as(u64, 10)).stepBy(2);

    for (&[_]u64{ 1, 3, 5, 7, 9 }) |i| {
        try testing.expectEqual(i, iter.next().?);
    }
    try testing.expect(iter.next() == null);
}

test "test range no end" {
    var iter = range(@as(u64, 1), null).stepBy(2);

    for (&[_]u64{ 1, 3, 5, 7, 9, 11 }) |i| {
        try testing.expectEqual(i, iter.next().?);
    }
    try testing.expect(iter.next() != null);
}

test "test length hint" {
    try testing.expect(range(@as(u64, 1), null).lengthHint() == null);
    try testing.expect(range(@as(u64, 1), @as(u64, 32)).lengthHint() == 31);
}

test "test contains" {
    try testing.expect(range(@as(u64, 1), null).contains(1) == true);
    try testing.expect(range(@as(u64, 1), null).contains(1000) == true);
    try testing.expect(range(@as(u64, 1), null).contains(0) == false);

    try testing.expect(range(@as(u64, 1), @as(u64, 32)).contains(31) == true);
    try testing.expect(range(@as(u64, 1), @as(u64, 32)).contains(32) == false);
}
