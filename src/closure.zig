const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const allocator = testing.allocator;

pub fn closure(bindings: anytype) ClosureInternal(@TypeOf(bindings)) {
    return ClosureInternal(@TypeOf(bindings)){ .ctx = bindings };
}

fn ClosureInternal(comptime Spec: type) type {
    comptime {
        const spec_tinfo = @typeInfo(Spec);
        std.debug.assert(spec_tinfo == .Struct);

        for (spec_tinfo.Struct.fields) |field| {
            std.debug.assert(field.default_value == null);
        }

        std.debug.assert(spec_tinfo.Struct.decls.len == 1);
        const call_decl = spec_tinfo.Struct.decls[0];
        std.debug.assert(call_decl.is_pub);
        std.debug.assert(std.mem.eql(u8, call_decl.name, "call"));

        const call = Spec.call;
        const call_tinfo = @typeInfo(@TypeOf(call));
        std.debug.assert(call_tinfo == .Fn);
        std.debug.assert(!call_tinfo.Fn.is_generic);
        std.debug.assert(call_tinfo.Fn.params.len >= 1);
        std.debug.assert(call_tinfo.Fn.params[0].type.? == *const Spec);

        var arg_types: [call_tinfo.Fn.params.len - 1]type = undefined;
        for (call_tinfo.Fn.params[1..], 0..) |arg, i| {
            arg_types[i] = arg.type.?;
        }

        const RetType = call_tinfo.Fn.return_type.?;

        return Closure(Spec, arg_types[0..], RetType);
    }
}

fn Closure(comptime Ctx: type, comptime arg_types: []type, comptime RetType: type) type {
    return struct {
        ctx: Ctx,

        pub fn call(self: *const @This(), args: anytype) RetType {
            comptime {
                std.debug.assert(args.len == arg_types.len);
                for (args, 0..) |_, i| {
                    std.debug.assert(@TypeOf(args[i]) == arg_types[i]);
                }
            }
            return @call(.auto, Ctx.call, .{&self.ctx} ++ args);
        }
    };
}
// --------------------------------------------------------------------------------
//                                   Testing
// --------------------------------------------------------------------------------

test "test closure captures values" {
    var x: i32 = 1;

    const f = closure(struct {
        x: *i32,
        pub fn call(self: *const @This(), y: i32) i32 {
            self.x.* += y;
            return 100;
        }
    }{ .x = &x });

    std.debug.assert(f.call(.{@as(i32, 9)}) == 100);
    std.debug.assert(x == 10);
}

test "test closure unary function" {
    const f = closure(struct {
        pub fn call(self: *const @This(), x: i32) i32 {
            _ = self;
            return x;
        }
    }{});

    std.debug.assert(f.call(.{@as(i32, 9)}) == 9);
}

test "test closure binary function" {
    const f = closure(struct {
        pub fn call(self: *const @This(), x: i32, y: i32) i32 {
            _ = self;
            return x + y;
        }
    }{});

    std.debug.assert(f.call(.{ @as(i32, 1), @as(i32, 9) }) == 10);
}

test "test closure, ternary function" {
    const f = closure(struct {
        pub fn call(self: *const @This(), x: i32, y: i32, z: i32) i32 {
            _ = self;
            return x + y + z;
        }
    }{});

    std.debug.assert(f.call(.{ @as(i32, 1), @as(i32, 9), @as(i32, 10) }) == 20);
}

test "test closure, different type" {
    const f = closure(struct {
        pub fn call(self: *const @This(), x: i32, y: []const u8) i32 {
            _ = self;
            const new_y = std.fmt.parseInt(i32, y, 10) catch 0;
            return x + new_y;
        }
    }{});

    std.debug.assert(f.call(.{ @as(i32, 1), @as([]const u8, "9") }) == 10);
}
