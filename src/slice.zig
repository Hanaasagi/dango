const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const allocator = testing.allocator;
const closure = @import("closure.zig").closure;

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

fn map(array: anytype, function: anytype) !ArrayList(getType(@TypeOf(function))) {
    const sub_type = getType(@TypeOf(function));

    const info = @typeInfo(@TypeOf(function));
    var result = ArrayList(sub_type).init(allocator);

    for (array) |item| {
        if (info == .Fn) {
            try result.append(function(item));
        } else {
            try result.append(function.call(.{item}));
        }
    }
    return result;
}

// --------------------------------------------------------------------------------
//                                   Testing
// --------------------------------------------------------------------------------

test "test map a function, T -> T" {
    var arr = [_]i32{ 1, 2, 3 };

    var new_arr = try map(
        arr,
        struct {
            fn addNum(x: i32) i32 {
                return x + 2;
            }
        }.addNum,
    );
    defer new_arr.deinit();

    try testing.expectEqualSlices(i32, &[3]i32{ 3, 4, 5 }, new_arr.items);
}

test "test map a function, T -> U" {
    var arr = [_][]const u8{ "0", "1", "2" };

    var new_arr = try map(
        arr,
        struct {
            fn parseInt(x: []const u8) !i32 {
                return try std.fmt.parseInt(i32, x, 10);
            }
        }.parseInt,
    );
    defer new_arr.deinit();

    for (0..3) |i| {
        try testing.expect(try (new_arr.items[i]) == i);
    }
}

test "test map a closure T -> T" {
    var num: i32 = 2;
    var arr = [_]i32{ 1, 2, 3 };

    var new_arr = try map(
        arr,
        closure(
            struct {
                x: *i32,
                pub fn call(self: *const @This(), y: i32) i32 {
                    self.x.* += y;
                    return y + 2;
                }
            }{ .x = &num },
        ),
    );
    defer new_arr.deinit();

    try testing.expectEqualSlices(i32, &[3]i32{ 3, 4, 5 }, new_arr.items);
    try testing.expect(num == 8);
}

test "test map a closure T -> U" {
    var num: i32 = 2;
    var arr = [_][]const u8{ "0", "1", "2" };

    var new_arr = try map(
        arr,
        closure(
            struct {
                x: *i32,
                pub fn call(self: *const @This(), y: []const u8) !i32 {
                    const new_y = try std.fmt.parseInt(i32, y, 10);
                    self.x.* += new_y;
                    return new_y;
                }
            }{ .x = &num },
        ),
    );
    defer new_arr.deinit();

    for (0..3) |i| {
        try testing.expect(try (new_arr.items[i]) == i);
    }
    try testing.expect(num == 5);
}
