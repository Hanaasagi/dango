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

pub fn Map(comptime Iter: type, comptime F: type) type {
    const N = switch (@typeInfo(F)) {
        .Fn => blk: {
            break :blk comptime (*const fn (Iter.Item) getType(F));
        },
        else => blk: {
            break :blk F;
        },
    };

    return struct {
        pub const Self: type = @This();
        pub const Item = getType(F);

        pub usingnamespace DeriveIterator(@This());

        f: N,
        iter: Iter,

        pub fn init(f: N, iter: Iter) Self {
            return .{ .f = f, .iter = iter };
        }

        pub fn next(self: *Self) ?Item {
            if (self.iter.next()) |item| {
                if (@typeInfo(F) == .Fn) {
                    return self.f(item);
                } else {
                    return self.f.call(.{item});
                }
            } else {
                return null;
            }
        }
    };
}

test "test map function, T -> T" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]).map(struct {
        fn mul2(x: *i32) i32 {
            return x.* * 2;
        }
    }.mul2);

    try testing.expectEqual(@as(?i32, 2), iter.next());
    try testing.expectEqual(@as(?i32, 4), iter.next());
    try testing.expectEqual(@as(?i32, 6), iter.next());
    try testing.expectEqual(@as(?i32, null), iter.next());
}

test "test map function, T -> U" {
    const sliceIter = @import("../iterator.zig").sliceIter;

    var arr = [_][]const u8{ "0", "1", "2" };

    var iter = sliceIter(arr[0..]).map(struct {
        fn parseInt(x: *[]const u8) !i32 {
            return try std.fmt.parseInt(i32, x.*, 10);
        }
    }.parseInt);

    for (0..3) |i| {
        try testing.expect(try (iter.next().?) == i);
    }
    try testing.expect(iter.next() == null);
}

test "test map closure, T -> T" {
    const closure = @import("../closure.zig").closure;
    const sliceIter = @import("../iterator.zig").sliceIter;

    var num: i32 = 2;
    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]).map(
        closure(
            struct {
                x: *i32,
                pub fn call(self: *const @This(), y: *i32) i32 {
                    self.x.* += y.*;
                    return y.* + 2;
                }
            }{ .x = &num },
        ),
    );

    try testing.expectEqual(@as(?i32, 3), iter.next());
    try testing.expectEqual(@as(?i32, 4), iter.next());
    try testing.expectEqual(@as(?i32, 5), iter.next());
    try testing.expectEqual(@as(?i32, null), iter.next());
    try testing.expect(num == 8);
}

test "test map closure, T -> U" {
    const closure = @import("../closure.zig").closure;
    const sliceIter = @import("../iterator.zig").sliceIter;

    var num: i32 = 2;
    var arr = [_][]const u8{ "0", "1", "2" };

    var iter = sliceIter(arr[0..]).map(
        closure(
            struct {
                x: *i32,
                pub fn call(self: *const @This(), y: *[]const u8) !i32 {
                    const new_y = try std.fmt.parseInt(i32, y.*, 10);
                    self.x.* += new_y;
                    return new_y;
                }
            }{ .x = &num },
        ),
    );

    for (0..3) |i| {
        try testing.expect(try (iter.next().?) == i);
    }
    try testing.expect(num == 5);
}
