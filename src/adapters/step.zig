const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;

const testing = std.testing;

pub fn StepBy(comptime Iter: type) type {
    comptime {
        return struct {
            pub const Self: type = @This();
            pub const Item: type = Iter.Item;
            pub usingnamespace DeriveIterator(@This());

            iter: Iter,
            step_by: usize,

            pub fn init(iter: Iter, step_by: usize) Self {
                return .{ .iter = iter, .step_by = step_by };
            }

            pub fn next(self: *Self) ?Item {
                var step = self.step_by - 1;
                var item = self.iter.next();
                while (0 < step) : (step -= 1) {
                    // TODO: destroy if the acquired value is owned
                    _ = self.iter.next();
                }
                return item;
            }
        };
    }
}

test "test stepBy" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3, 4, 5 };

    var iter = sliceIter(arr[0..]).stepBy(2);

    try testing.expectEqual(arr[0], iter.next().?.*);
    try testing.expectEqual(arr[2], iter.next().?.*);
    try testing.expectEqual(arr[4], iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());
}
