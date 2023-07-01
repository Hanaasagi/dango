const std = @import("std");
const DeriveIterator = @import("../derive.zig").DeriveIterator;

const testing = std.testing;

fn getType(comptime function: type) type {
    return switch (@typeInfo(function)) {
        .Fn => |x| x.return_type.?,
        .Struct => |x| blk: {
            const call_fn = x.fields[x.fields.len - 1].type.call;
            const call_info = @typeInfo(@TypeOf(call_fn));
            const return_type = call_info.Fn.return_type.?;
            break :blk return_type;
        },
        else => {
            @compileError("invalid type");
        },
    };
}

pub fn Filter(comptime Iter: type, comptime F: type) type {
    const P = switch (@typeInfo(F)) {
        .Fn => blk: {
            break :blk comptime (*const fn (Iter.Item) getType(F));
        },
        else => blk: {
            break :blk F;
        },
    };

    return struct {
        pub const Self: type = @This();
        pub const Item: type = Iter.Item;
        pub usingnamespace DeriveIterator(@This());

        pred: P,
        iter: Iter,

        pub fn new(pred: P, iter: Iter) Self {
            return .{ .pred = pred, .iter = iter };
        }

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (@typeInfo(F) == .Fn) {
                    if (self.pred(item)) {
                        return item;
                    }
                } else {
                    if (self.pred.call(.{item})) {
                        return item;
                    }
                }
            }
            return null;
        }
    };
}

test "test filter function" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]).filter(struct {
        fn mod2(x: *i32) bool {
            return @mod(x.*, 2) == 0;
        }
    }.mod2);

    try testing.expectEqual(@as(i32, 2), iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());
}

test "test filter closure" {
    const closure = @import("../closure.zig").closure;
    const sliceIter = @import("../iterator.zig").sliceIter;

    var num: i32 = 0;
    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]).filter(
        closure(
            struct {
                x: *i32,
                pub fn call(self: *const @This(), y: *i32) bool {
                    self.x.* += y.*;
                    return @mod(y.*, 2) == 0;
                }
            }{ .x = &num },
        ),
    );

    try testing.expectEqual(@as(i32, 2), iter.next().?.*);
    try testing.expectEqual(@as(?*i32, null), iter.next());

    try testing.expect(num == 6);
}
