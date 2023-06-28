const std = @import("std");
const Peekable = @import("adapters/peekable.zig").Peekable;
const StepBy = @import("adapters/step.zig").StepBy;
const Skip = @import("adapters/skip.zig").Skip;
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

pub fn DeriveIterator(comptime Iter: type) type {
    comptime {
        return struct {
            pub usingnamespace DerivePeekable(Iter);
            pub usingnamespace DeriveStepBy(Iter);
            pub usingnamespace DeriveNth(Iter);
            pub usingnamespace DeriveSkip(Iter);

            // TODO:
        };
    }
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

pub fn DeriveSkip(comptime Iter: type) type {
    return struct {
        pub fn skip(self: Iter, size: usize) Skip(Iter) {
            return Skip(Iter).init(self, size);
        }
    };
}

test "derive nth" {
    const sliceIter = @import("./iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    try testing.expectEqual(arr[0], sliceIter(arr[0..]).nth(0).?.*);
    try testing.expectEqual(arr[1], sliceIter(arr[0..]).nth(1).?.*);
    try testing.expectEqual(arr[2], sliceIter(arr[0..]).nth(2).?.*);
    try testing.expectEqual(@as(?*i32, null), sliceIter(arr[0..]).nth(3));
}

test {
    _ = @import("adapters/peekable.zig");
    _ = @import("adapters/step.zig");
    _ = @import("adapters/skip.zig");
    std.testing.refAllDecls(@This());
}
