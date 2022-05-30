const math = @import("math.zig");
const std = @import("std");

const Instance = struct {
    mvp: math.Mat,
};

pub const ContextDesc = struct {
    allocator: std.mem.Allocator,
    max_instances: usize = 256,
};

pub const Context = struct {
    pub const instance_size = @sizeOf(Instance);

    allocator: std.mem.Allocator,
    instances: []Instance,
    instance_count: usize,

    pub fn init(desc: ContextDesc) !Context {
        return Context{
            .allocator = desc.allocator,
            .instances = try desc.allocator.alloc(Instance, desc.max_instances),
            .instance_count = 0,
        };
    }

    pub fn deinit(ctx: *Context) void {
        ctx.allocator.free(ctx.instances);
    }

    pub fn getInstanceBytes(ctx: *Context) []const u8 {
        return std.mem.sliceAsBytes(ctx.instances[0..ctx.instance_count]);
    }

    pub fn debugText(ctx: *Context, fmt: []const u8, args: anytype) !void {
        _ = fmt;
        _ = args;
        ctx.instances[0].mvp = math.identity();
        ctx.instance_count = 1;
    }
};
