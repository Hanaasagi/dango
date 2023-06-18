const std = @import("std");
const testing = std.testing;

fn map(comptime Src: type, comptime Dst: type, comptime len: usize, array: [len]Src, function: fn (Src) Dst) [len]Dst {
    var result: [len]Dst = undefined;
    var index: usize = 0;
    while (index < len) {
        result[index] = function(array[index]);
        index += 1;
    }
    return result;
}

test "test map" {
    var array_thing = map(
        f64,
        f64,
        3,
        .{ 1.0, 2.0, 3.0 },
        struct {
            fn add(a: f64) f64 {
                return a + 1.0;
            }
        }.add,
    );
    try testing.expectEqualSlices(f64, &[3]f64{ 2.0, 3.0, 4.0 }, &array_thing);
}
