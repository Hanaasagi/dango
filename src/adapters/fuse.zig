const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;

const testing = std.testing;

pub fn Fuse(comptime Iter: type) type {
    return struct {
        pub const Self: type = @This();
        pub const Item: type = Iter.Item;
        pub usingnamespace DeriveIterator(@This());

        iter: Iter,
        // 'null' has been occurred
        none: bool,

        pub fn init(iter: Iter) Self {
            return .{ .iter = iter, .none = false };
        }

        pub fn next(self: *Self) ?Item {
            if (self.none)
                return null;
            if (self.iter.next()) |val| {
                return val;
            } else {
                self.none = true;
                return null;
            }
        }
    };
}

test "test fuse" {
    const sliceIter = @import("../iterator.zig").sliceIter;
    _ = sliceIter;

    const Alternate = struct {
        state: i32,

        pub const Self = @This();
        pub const Item = i32;

        pub fn next(self: *Self) ?Item {
            const val: i32 = self.state;
            self.state = self.state + 1;

            if (@mod(val, 2) == 0) {
                return val;
            }
            return null;
        }
    };

    {
        var iter = Alternate{ .state = 0 };
        try testing.expectEqual(@as(i32, 0), iter.next().?);
        try testing.expectEqual(@as(?i32, null), iter.next());
        try testing.expectEqual(@as(i32, 2), iter.next().?);
        try testing.expectEqual(@as(?i32, null), iter.next());
    }

    {
        var iter = Fuse(Alternate).init(Alternate{ .state = 0 });

        try testing.expectEqual(@as(i32, 0), iter.next().?);
        try testing.expectEqual(@as(?i32, null), iter.next());
        try testing.expectEqual(@as(?i32, null), iter.next());
        try testing.expectEqual(@as(?i32, null), iter.next());
    }
}
