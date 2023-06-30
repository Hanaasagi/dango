const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const utils = @import("utils.zig");

pub fn Box(comptime T: type) type {
    return struct {
        ptr: *T,
        allocator: Allocator,

        const Self = @This();
        pub fn init(allocator: Allocator, v: T) !Self {
            var ptr = try allocator.create(T);
            ptr.* = v;
            return Self{
                .allocator = allocator,
                .ptr = ptr,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self.ptr);
        }
    };
}

test "test box" {
    const x: i32 = 1;

    var b = try Box(i32).init(testing.allocator, x);
    defer b.deinit();

    try testing.expect(b.ptr.* == 1);
}

fn testStackSlice() !Box([]u8) {
    var message = [_]u8{ 'z', 'i', 'g', 'b', 'i', 't', 's' };

    return try Box([]u8).init(testing.allocator, &message);
}

test "test box2" {
    var message = try testStackSlice();
    defer message.deinit();
    try testing.expect(std.mem.eql(u8, message.ptr.*, "zigbits"));
}
