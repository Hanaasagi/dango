const std = @import("std");
pub const option = @import("option.zig");
pub const closure = @import("closure.zig");
pub const slice = @import("slice.zig");

test {
    std.testing.refAllDecls(@This());
}
