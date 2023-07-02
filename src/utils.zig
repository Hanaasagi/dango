const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn merge(base: anytype, args: anytype) @TypeOf(base) {
    // make a copy
    var new_value = base;

    update(&new_value, args);
    return new_value;
}

pub fn update(base: anytype, args: anytype) void {
    const B = @TypeOf(base);
    const A = @TypeOf(args);

    // base must be a pointer for in-place update
    comptime assert(std.meta.trait.is(.Pointer)(B));

    if (comptime !std.meta.trait.isTuple(A)) {
        const value = args;
        inline for (std.meta.fields(A)) |f| {
            const name = f.name;
            @field(base, name) = @as(@TypeOf(@field(base, name)), @field(value, name));
        }
    } else {
        // handle multi argument structs
        inline for (@typeInfo(A).Struct.fields) |arg| {
            // Maybe could use "0", "1" here
            const value = @field(args, arg.name);
            inline for (std.meta.fields(@TypeOf(value))) |f| {
                const name = f.name;
                @field(base, name) = @as(@TypeOf(@field(base, name)), @field(value, name));
            }
        }
    }
}

test "test update struct" {
    const Point = struct {
        x: u32,
        y: u32,
        label: []const u8,
    };

    var p = Point{ .x = 0, .y = 1, .label = "A" };
    update(&p, .{ .x = 2, .label = "B" });

    try testing.expect(p.x == 2);
    try testing.expect(p.y == 1);
    try testing.expect(std.mem.eql(u8, p.label, "B"));
}

test "test merge struct" {
    const Point = struct {
        x: u32,
        y: u32,
        label: []const u8,
    };

    const p = Point{ .x = 0, .y = 1, .label = "A" };
    const new_p = merge(p, .{ .x = 2, .label = "B" });

    try testing.expect(new_p.x == 2);
    try testing.expect(new_p.y == 1);
    try testing.expect(std.mem.eql(u8, new_p.label, "B"));
}

test "test update multi" {
    const Point = struct {
        x: u32,
        y: u32,
        label: []const u8,
    };

    var p = Point{ .x = 0, .y = 1, .label = "A" };
    update(&p, .{ .{ .x = 2 }, .{ .label = "B" } });

    try testing.expect(p.x == 2);
    try testing.expect(p.y == 1);
    try testing.expect(std.mem.eql(u8, p.label, "B"));
}

test "test merge multi" {
    const Point = struct {
        x: u32,
        y: u32,
        label: []const u8,
    };

    const p = Point{ .x = 0, .y = 1, .label = "A" };
    const new_p = merge(p, .{ .{ .x = 2 }, .{ .label = "B" } });

    try testing.expect(new_p.x == 2);
    try testing.expect(new_p.y == 1);
    try testing.expect(std.mem.eql(u8, new_p.label, "B"));
}
