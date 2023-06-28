const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;

const testing = std.testing;

pub fn Skip(comptime Iter: type) type {
    return struct {
        pub const Self = @This();
        pub const Item = Iter.Item;
        pub usingnamespace DeriveIterator(@This());

        iter: Iter,
        skip: usize,

        pub fn init(iter: Iter, skip: usize) Self {
            return .{ .iter = iter, .skip = skip };
        }

        pub fn next(self: *Self) ?Item {
            while (0 < self.skip) : (self.skip -= 1) {
                // TODO: destroy if the aquired value is owned
                _ = self.iter.next();
            }
            return self.iter.next();
        }
    };
}

test "derive skip" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3, 4, 5 };

    var skip = sliceIter(arr[0..]).skip(3);
    try testing.expectEqual(@as(i32, 4), skip.next().?.*);
    try testing.expectEqual(@as(i32, 5), skip.next().?.*);
    try testing.expectEqual(@as(?*i32, null), skip.next());
}
