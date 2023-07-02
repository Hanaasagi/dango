const std = @import("std");
const Peekable = @import("adapters/peekable.zig").Peekable;
const StepBy = @import("adapters/step.zig").StepBy;
const Skip = @import("adapters/skip.zig").Skip;
const Take = @import("adapters/take.zig").Take;
const Fuse = @import("adapters/fuse.zig").Fuse;
const Map = @import("adapters/map.zig").Map;
const Filter = @import("adapters/filter.zig").Filter;
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
pub fn DeriveFuse(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn fuse(self: Iter) Fuse(Iter) {
                return Fuse(Iter).init(self);
            }
        };
    }
}

pub fn DeriveMap(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn map(self: Iter, f: anytype) Map(Iter, @TypeOf(f)) {
                return Map(Iter, @TypeOf(f)).init(f, self);
            }
        };
    }
}

pub fn DeriveFilter(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn filter(self: Iter, p: anytype) Filter(Iter, @TypeOf(p)) {
                return Filter(Iter, @TypeOf(p)).new(p, self);
            }
        };
    }
}

pub fn DeriveFold(comptime Iter: type) type {
    comptime {
        return struct {
            pub fn fold(self: Iter, init: anytype, f: anytype) @TypeOf(init) {
                var it = self;
                var acc = init;
                while (it.next()) |value| {
                    if (@typeInfo(@TypeOf(f)) == .Fn) {
                        acc = f(acc, value);
                    } else {
                        acc = f.call(.{ acc, value });
                    }
                }
                return acc;
            }
        };
    }
}

test "test fold function" {
    const sliceIter = @import("iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    const acc = sliceIter(arr[0..]).fold(@as(i32, 0), struct {
        fn acc(sum: i32, val: *i32) i32 {
            return sum + val.*;
        }
    }.acc);

    try testing.expectEqual(@as(i32, 6), acc);
}

test "test fold closure" {
    const closure = @import("closure.zig").closure;
    const sliceIter = @import("iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    const acc = sliceIter(arr[0..]).fold(@as(i32, 0), closure(struct {
        pub fn call(self: *const @This(), sum: i32, val: *i32) i32 {
            _ = self;
            return sum + val.*;
        }
    }{}));

    try testing.expectEqual(@as(i32, 6), acc);
}

pub fn DeriveAll(comptime Iter: type) type {
    return struct {
        pub fn all(self: Iter, f: anytype) bool {
            // FIXME: this will copy iterator
            var it = self;
            while (it.next()) |value| {
                if (@typeInfo(@TypeOf(f)) == .Fn) {
                    if (!f(value)) {
                        return false;
                    }
                } else {
                    if (!f.call(.{value})) {
                        return false;
                    }
                }
            }
            return true;
        }
    };
}

test "test all function" {
    const sliceIter = @import("iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };
    const res = sliceIter(arr[0..]).all(struct {
        fn lessThan10(x: *i32) bool {
            return x.* < 10;
        }
    }.lessThan10);

    try testing.expectEqual(true, res);

    const res2 = sliceIter(arr[0..]).all(struct {
        fn lessThan1(x: *i32) bool {
            return x.* < 1;
        }
    }.lessThan1);

    try testing.expectEqual(false, res2);
}

test "test all closure" {
    const closure = @import("closure.zig").closure;
    const sliceIter = @import("iterator.zig").sliceIter;

    var arr = [_]i32{ 1, 2, 3 };

    const res = sliceIter(arr[0..]).all(closure(struct {
        pub fn call(self: *const @This(), val: *i32) bool {
            _ = self;
            return val.* < 10;
        }
    }{}));

    try testing.expectEqual(true, res);

    const res2 = sliceIter(arr[0..]).all(closure(struct {
        pub fn call(self: *const @This(), val: *i32) bool {
            _ = self;
            return val.* < 1;
        }
    }{}));

    try testing.expectEqual(false, res2);
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
            pub usingnamespace DeriveFuse(Iter);
            pub usingnamespace DeriveMap(Iter);
            pub usingnamespace DeriveFilter(Iter);
            pub usingnamespace DeriveFold(Iter);
            pub usingnamespace DeriveAll(Iter);
        };
    }
}

test {
    _ = @import("adapters/peekable.zig");
    _ = @import("adapters/step.zig");
    _ = @import("adapters/skip.zig");
    _ = @import("adapters/take.zig");
    _ = @import("adapters/fuse.zig");
    _ = @import("adapters/map.zig");
    _ = @import("adapters/filter.zig");
    std.testing.refAllDecls(@This());
}
