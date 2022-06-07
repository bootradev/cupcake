const math = @import("cc_math");
const std = @import("std");

const Instance = struct {
    mvp: math.Mat,
};

pub const Viewport = struct {
    width: f32,
    height: f32,
};

pub const TextLayout = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    width: f32 = 100.0,
    height: f32 = 25.0,
    font_size: f32 = 12.0,
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
    vp: math.Mat,

    pub fn init(desc: ContextDesc) !Context {
        return Context{
            .allocator = desc.allocator,
            .instances = try desc.allocator.alloc(Instance, desc.max_instances),
            .instance_count = 0,
            .vp = math.identity(),
        };
    }

    pub fn deinit(ctx: *Context) void {
        ctx.allocator.free(ctx.instances);
    }

    pub fn getInstanceCount(ctx: Context) usize {
        return ctx.instance_count;
    }

    pub fn getInstanceBytes(ctx: Context) []const u8 {
        return std.mem.sliceAsBytes(ctx.instances[0..ctx.instance_count]);
    }

    pub fn clear(ctx: *Context) void {
        ctx.instance_count = 0;
    }

    pub fn setViewport(ctx: *Context, viewport: Viewport) void {
        ctx.vp = math.orthographicLh(viewport.width, viewport.height, 0.0, 1.0);
    }

    pub fn debugText(
        ctx: *Context,
        layout: TextLayout,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var buf: [2048]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, fmt, args);

        const scale = math.scaling(layout.font_size, layout.font_size, 1.0);

        var start_x = layout.x;
        var start_y = layout.y;
        for (msg) |_| {
            const m = math.mul(scale, math.translation(start_x, start_y, 0.0));
            try ctx.addInstance(.{ .mvp = math.transpose(math.mul(m, ctx.vp)) });

            start_x += layout.font_size;
        }
    }

    fn addInstance(ctx: *Context, instance: Instance) !void {
        if (ctx.instance_count >= ctx.instances.len) {
            return error.OutOfInstances;
        }
        ctx.instances[ctx.instance_count] = instance;
        ctx.instance_count += 1;
    }
};
