const math = @import("math.zig");
const std = @import("std");

pub const Quad = struct {
    pos_uv: @Vector(4, f32),
};

pub const Instance = struct {
    mvp: [4]@Vector(4, f32),
};

pub const quad_vertices: []const Quad = &.{
    .{ .pos_uv = @Vector(4, f32){ -0.5, -0.5, 0.0, 1.0 } },
    .{ .pos_uv = @Vector(4, f32){ 0.5, -0.5, 1.0, 1.0 } },
    .{ .pos_uv = @Vector(4, f32){ -0.5, 0.5, 0.0, 0.0 } },
    .{ .pos_uv = @Vector(4, f32){ 0.5, 0.5, 1.0, 0.0 } },
};
pub const quad_indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };

pub const ContextDesc = struct {
    max_instances: usize = 256,
};

pub fn Context(
    comptime gfx_impl: anytype,
    comptime res_impl: anytype,
    comptime ctx_desc: ContextDesc,
) type {
    return struct {
        const ContextType = @This();

        gctx: gfx_impl.Context,
        rctx: res_impl.Context,
        instances: [ctx_desc.max_instances]Instance,
        instance_count: usize,

        const ContextTypeDesc = struct {
            gfx_desc: gfx_impl.ContextDesc,
            res_desc: res_impl.ContextDesc,
        };

        pub fn init(desc: ContextTypeDesc) !ContextType {
            var rctx = try res_impl.Context.init(desc.res_desc, ctx_desc);
            const vert_shader_bytes = try rctx.loadVertShaderBytes();
            const frag_shader_bytes = try rctx.loadFragShaderBytes();
            const gctx = try gfx_impl.Context.init(
                desc.gfx_desc,
                ctx_desc,
                vert_shader_bytes,
                frag_shader_bytes,
            );
            return ContextType{
                .gctx = gctx,
                .rctx = rctx,
                .instances = undefined,
                .instance_count = 0,
            };
        }

        pub fn deinit(ctx: *ContextType) void {
            ctx.gctx.deinit();
            ctx.rctx.deinit();
        }

        pub fn render(ctx: *ContextType, render_data: gfx_impl.RenderData) !void {
            const instance_bytes = std.mem.sliceAsBytes(ctx.instances[0..ctx.instance_count]);
            try ctx.gctx.render(render_data, instance_bytes);
            // reset for next render
            ctx.instance_count = 0;
        }

        pub fn debugText(ctx: *ContextType, fmt: []const u8, args: anytype) !void {
            _ = fmt;
            _ = args;
            ctx.instances[0].mvp = math.identity();
            ctx.instance_count = 1;
        }
    };
}
