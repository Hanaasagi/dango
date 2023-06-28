const std = @import("std");
const Peekable = @import("adapters/peekable.zig").Peekable;
const StepBy = @import("adapters/step.zig").StepBy;
const Skip = @import("adapters/skip.zig").Skip;
const Take = @import("adapters/take.zig").Take;
const meta = @import("meta.zig");

const testing = std.testing;

pub fn DerivePeekable(comptime Iter: type) type {
    comptime {
        std.debug.assert(meta.isIterator(Iter));

        // if (meta.hasFn(Iter, "peekable")) {
        //     return struct {};
        // } else {
        return struct {
            pub fn peekable(self: Iter) Peekable(Iter) {
                return Peekable(Iter).init(self);
            }
        };
        // }
    }
}

pub fn DeriveStepBy(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn stepBy(self: Iter, skip: usize) StepBy(Iter) {
                return StepBy(Iter).init(self, skip);
            }
        };
    }
}

pub fn DeriveSkip(comptime Iter: type) type {
    return struct {
        pub fn skip(self: Iter, size: usize) Skip(Iter) {
            return Skip(Iter).init(self, size);
        }
    };
}

pub fn DeriveNth(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn nth(self: Iter, n: usize) ?Iter.Item {
                var it = self;
                var i = @as(usize, 0);
                while (i < n) : (i += 1) {
                    _ = it.next();
                }
                return it.next();
            }
        };
    }
}

test "derive nth" {
    const sliceIter = @import("./iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    try testing.expectEqual(arr[0], sliceIter(arr[0..]).nth(0).?.*);
    try testing.expectEqual(arr[1], sliceIter(arr[0..]).nth(1).?.*);
    try testing.expectEqual(arr[2], sliceIter(arr[0..]).nth(2).?.*);
    try testing.expectEqual(@as(?*i32, null), sliceIter(arr[0..]).nth(3));
}

pub fn DeriveLast(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn last(self: *Iter) ?Iter.Item {
                var ls: ?Iter.Item = null;
                while (self.next()) |val| {
                    ls = val;
                }
                return ls;
            }
        };
    }
}
test "derive last" {
    const sliceIter = @import("./iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]);
    try testing.expectEqual(@as(i32, 3), iter.last().?.*);
}

pub fn DeriveCount(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn count(self: *Iter) usize {
                var i: usize = 0;
                while (self.next()) |_| {
                    i += 1;
                }
                return i;
            }
        };
    }
}

test "derive count" {
    const sliceIter = @import("./iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    var iter = sliceIter(arr[0..]);
    try testing.expectEqual(@as(usize, 3), iter.count());
}

pub fn DeriveTake(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn take(self: Iter, size: usize) Take(Iter) {
                return Take(Iter).init(self, size);
            }
        };
    }
}

pub fn DeriveIterator(comptime Iter: type) type {
    comptime {
        return struct {
            pub usingnamespace DerivePeekable(Iter);
            pub usingnamespace DeriveStepBy(Iter);
            pub usingnamespace DeriveNth(Iter);
            pub usingnamespace DeriveSkip(Iter);
            pub usingnamespace DeriveLast(Iter);
            pub usingnamespace DeriveCount(Iter);
            pub usingnamespace DeriveTake(Iter);
        };
    }
}

test {
    _ = @import("adapters/peekable.zig");
    _ = @import("adapters/step.zig");
    _ = @import("adapters/skip.zig");
    _ = @import("adapters/take.zig");
    std.testing.refAllDecls(@This());
}
