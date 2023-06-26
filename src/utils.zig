const std = @import("std");
const testing = std.testing;

pub fn update(base: anytype, diff: anytype) @TypeOf(base) {
    var updated = base;
    inline for (std.meta.fields(@TypeOf(diff))) |f| {
        @field(updated, f.name) = @field(diff, f.name);
    }
    return updated;
}

test "test update struct" {
    const Point = struct {
        x: u32,
        y: u32,
    };

    const p = Point{ .x = 0, .y = 1 };
    const new_p = update(p, .{ .x = 2 });

    try testing.expect(new_p.x == 2);
    try testing.expect(new_p.y == 1);
}
