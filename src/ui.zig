const math = @import("cc_math");
const std = @import("std");

pub const Instance = struct {
    pos_size: math.F32x4,
    uv_pos_size: math.F32x4,
    color: math.F32x4,
};

pub const Uniforms = struct {
    viewport: Viewport,
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
    allocator: std.mem.Allocator,
    uniforms: Uniforms,
    instances: []Instance,
    instance_count: usize,

    pub fn init(desc: ContextDesc) !Context {
        return Context{
            .allocator = desc.allocator,
            .instances = try desc.allocator.alloc(Instance, desc.max_instances),
            .instance_count = 0,
            .uniforms = .{ .viewport = .{ .width = 0.0, .height = 0.0 } },
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

    pub fn getUniformBytes(ctx: Context) []const u8 {
        return std.mem.asBytes(&ctx.uniforms);
    }

    pub fn clear(ctx: *Context) void {
        ctx.instance_count = 0;
    }

    pub fn setViewport(ctx: *Context, viewport: Viewport) void {
        ctx.uniforms.viewport = viewport;
    }

    pub fn debugText(
        ctx: *Context,
        layout: TextLayout,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        _ = layout;
        _ = fmt;
        _ = args;
        try ctx.addInstance(.{
            .pos_size = math.f32x4(300.0, 300.0, 600.0, 600.0),
            .uv_pos_size = math.f32x4(0.0, 0.0, 1.0, 1.0),
            .color = math.f32x4(1.0, 1.0, 1.0, 1.0),
        });
        // var buf: [2048]u8 = undefined;
        // const msg = try std.fmt.bufPrint(&buf, fmt, args);

        // const scale = math.scaling(layout.font_size, layout.font_size, 1.0);

        // var start_x = layout.x;
        // var start_y = layout.y;
        // for (msg) |_| {
        //     const m = math.mul(scale, math.translation(start_x, start_y, 0.0));
        //     try ctx.addInstance(.{ .mvp = math.transpose(math.mul(m, ctx.vp)) });

        //     start_x += layout.font_size;
        // }
    }

    fn addInstance(ctx: *Context, instance: Instance) !void {
        if (ctx.instance_count >= ctx.instances.len) {
            return error.OutOfInstances;
        }
        ctx.instances[ctx.instance_count] = instance;
        ctx.instance_count += 1;
    }
};
