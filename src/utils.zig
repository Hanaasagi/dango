const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

pub fn merge(base: anytype, diff: anytype) @TypeOf(base) {
    // make a copy
    var new_value = base;

    update(&new_value, diff);
    return new_value;
}

pub fn update(base: anytype, diff: anytype) void {
    const T = @TypeOf(base);
    comptime assert(std.meta.trait.is(.Pointer)(T));

    inline for (std.meta.fields(@TypeOf(diff))) |f| {
        const name = f.name;
        @field(base, name) = @as(@TypeOf(@field(base, name)), @field(diff, name));
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
