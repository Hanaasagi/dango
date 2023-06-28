const std = @import("std");

pub fn hasFn(comptime T: type, comptime name: []const u8) bool {
    comptime {
        if (!std.meta.trait.isContainer(T))
            return false;
        if (!@hasDecl(T, name))
            return false;
        return true;
    }
}

pub fn hasType(comptime T: type, comptime name: []const u8) bool {
    comptime {
        if (!std.meta.trait.isContainer(T))
            return false;
        if (!@hasDecl(T, name))
            return false;

        const field = @field(T, name);
        if (@typeInfo(@TypeOf(field)) == .Type) {
            return true;
        }
        return false;
    }
}

pub fn isIterator(comptime T: type) bool {
    comptime {
        if (hasType(T, "Self") and hasType(T, "Item") and hasFn(T, "next")) {
            return true;
        }
        return false;
    }
}
