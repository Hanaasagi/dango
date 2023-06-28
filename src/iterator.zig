const std = @import("std");
const DeriveIterator = @import("derive.zig").DeriveIterator;

const testing = std.testing;

pub fn SliceIter(comptime T: type) type {
    return struct {
        pub const Self: type = @This();
        pub const Item: type = *T;
        pub usingnamespace DeriveIterator(@This());

        slice: []T,
        index: usize,

        pub fn new(slice: []T) Self {
            return Self{ .slice = slice, .index = 0 };
        }

        pub fn next(self: *Self) ?Item {
            if (self.index < self.slice.len) {
                const i = self.index;
                self.index += 1;
                return &self.slice[i];
            } else {
                return null;
            }
        }
    };
}

pub fn sliceIter(slice: anytype) SliceIter(
    if (std.meta.trait.is(.Pointer)(@TypeOf(slice))) blk: {
        break :blk std.meta.Child(std.meta.Child(@TypeOf(slice)));
    } else blk: {
        break :blk std.meta.Child(@TypeOf(slice));
    },
) {
    const T = @TypeOf(slice);
    const Item = comptime if (std.meta.trait.is(.Pointer)(T)) blk: {
        const Container = std.meta.Child(T);
        break :blk std.meta.Child(Container);
    } else blk: {
        break :blk std.meta.Child(T);
    };
    return SliceIter(Item).new(slice);
}

test "test next" {
    var arr = [_]i32{ 1, 2, 3 };

    var iter = sliceIter(arr[0..]);
    try testing.expectEqual(arr[0], iter.next().?.*);
    try testing.expectEqual(arr[1], iter.next().?.*);
    try testing.expectEqual(arr[2], iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());
}

test "test next and mutate" {
    var arr = [_]i32{ 1, 2, 3 };

    var iter = sliceIter(arr[0..]);
    iter.next().?.* = 2;
    iter.next().?.* = 3;
    iter.next().?.* = 4;
    try testing.expectEqual([_]i32{ 2, 3, 4 }, arr);
}
