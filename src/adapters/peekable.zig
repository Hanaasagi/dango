const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;

const testing = std.testing;

pub fn Peekable(comptime Iter: type) type {
    comptime {
        return struct {
            pub const Self = @This();
            pub const Item = Iter.Item;
            pub usingnamespace DeriveIterator(@This());

            iter: Iter,
            peeked: ?Iter.Item,

            pub fn init(iter: Iter) Self {
                var it = iter;
                const peeked = it.next();
                return .{ .iter = it, .peeked = peeked };
            }

            pub fn peek(self: *Self) ?*const Item {
                if (self.peeked) |*val|
                    return val;
                return null;
            }

            pub fn next(self: *Self) ?Item {
                const peeked = self.peeked;
                self.peeked = self.iter.next();
                return peeked;
            }
        };
    }
}

test "test peekable" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };

    var iter = sliceIter(arr[0..]).peekable();

    try testing.expectEqual(arr[0], iter.peek().?.*.*);
    try testing.expectEqual(arr[0], iter.peek().?.*.*);

    try testing.expectEqual(arr[0], iter.next().?.*);
    try testing.expectEqual(arr[1], iter.next().?.*);

    try testing.expectEqual(arr[2], iter.peek().?.*.*);

    try testing.expectEqual(arr[2], iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());
}
