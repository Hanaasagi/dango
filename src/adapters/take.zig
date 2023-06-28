const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;
const testing = std.testing;

pub fn Take(comptime Iter: type) type {
    return struct {
        pub const Self: type = @This();
        pub const Item: type = Iter.Item;
        pub usingnamespace DeriveIterator(@This());

        iter: Iter,
        take: usize,

        pub fn init(iter: Iter, take: usize) Self {
            return .{ .iter = iter, .take = take };
        }

        pub fn next(self: *Self) ?Item {
            if (0 < self.take) {
                self.take -= 1;
                return self.iter.next();
            }
            return null;
        }
    };
}
test "Take" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3, 4, 5 };

    var iter = sliceIter(arr[0..]).take(3);
    try testing.expectEqual(arr[0], iter.next().?.*);
    try testing.expectEqual(arr[1], iter.next().?.*);
    try testing.expectEqual(arr[2], iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());
}
