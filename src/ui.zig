const app = @import("app.zig");
const cc_res = @import("cc_res");
const gfx = @import("gfx.zig");
const math = @import("math.zig");
const std = @import("std");

pub const Quad = struct {
    pos_uv: math.F32x4,
};

const Instance = struct {
    mvp: math.Mat,
};

pub const quad_vertices: []const Quad = &.{
    .{ .pos_uv = math.f32x4(-0.5, -0.5, 0.0, 1.0) },
    .{ .pos_uv = math.f32x4(0.5, -0.5, 1.0, 1.0) },
    .{ .pos_uv = math.f32x4(-0.5, 0.5, 0.0, 0.0) },
    .{ .pos_uv = math.f32x4(0.5, 0.5, 1.0, 0.0) },
};
pub const quad_indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };

pub const ContextDesc = struct {
    window: *const app.Window,
    device: *gfx.Device,
    format: gfx.TextureFormat,
};

pub const Context = struct {
    const max_instances: usize = 256;

    window: *const app.Window,
    device: *gfx.Device,
    vertex_buffer: gfx.Buffer,
    index_buffer: gfx.Buffer,
    instance_buffer: gfx.Buffer,
    render_pipeline: gfx.RenderPipeline,
    instances: [max_instances]Instance,
    instance_count: usize,

    pub fn init(desc: ContextDesc) !Context {
        const vertex_buffer = try desc.device.createBufferFromSlice(quad_vertices, .{ .vertex = true });
        const index_buffer = try desc.device.createBufferFromSlice(
            quad_indices,
            .{ .index = true },
        );
        const instance_buffer = try desc.device.createBuffer(.{
            .size = @sizeOf(Instance) * max_instances,
            .usage = .{ .vertex = true, .copy_dst = true },
        });

        var vert_shader = try desc.device.loadShader(cc_res.src_ui_vert_shader, .{});
        defer vert_shader.destroy();

        var frag_shader = try desc.device.loadShader(cc_res.src_ui_frag_shader, .{});
        defer frag_shader.destroy();

        var render_pipeline_desc = gfx.RenderPipelineDesc{};
        render_pipeline_desc.setVertexState(.{ .module = &vert_shader, .entry_point = "vs_main", .buffers = &[_]gfx.VertexBufferLayout{
            gfx.getVertexBufferLayout(Quad, .vertex, 0),
            gfx.getVertexBufferLayout(Instance, .instance, 2),
        } });
        render_pipeline_desc.setFragmentState(.{
            .module = &frag_shader,
            .entry_point = "fs_main",
            .targets = &[_]gfx.ColorTargetState{.{ .format = desc.format }},
        });

        const render_pipeline = try desc.device.createRenderPipeline(render_pipeline_desc);

        return Context{
            .window = desc.window,
            .device = desc.device,
            .vertex_buffer = vertex_buffer,
            .index_buffer = index_buffer,
            .instance_buffer = instance_buffer,
            .render_pipeline = render_pipeline,
            .instances = undefined,
            .instance_count = 0,
        };
    }

    pub fn deinit(ctx: *Context) void {
        ctx.render_pipeline.destroy();
        ctx.instance_buffer.destroy();
        ctx.index_buffer.destroy();
        ctx.vertex_buffer.destroy();
    }

    pub fn render(ctx: *Context, render_pass: *gfx.RenderPass) !void {
        const instance_bytes = std.mem.sliceAsBytes(ctx.instances[0..ctx.instance_count]);
        var queue = try ctx.device.getQueue();
        try queue.writeBuffer(&ctx.instance_buffer, 0, instance_bytes, 0);

        try render_pass.setPipeline(&ctx.render_pipeline);
        try render_pass.setVertexBuffer(0, &ctx.vertex_buffer, 0, gfx.whole_size);
        try render_pass.setVertexBuffer(1, &ctx.instance_buffer, 0, instance_bytes.len);
        try render_pass.setIndexBuffer(&ctx.index_buffer, .uint16, 0, gfx.whole_size);
        try render_pass.drawIndexed(quad_indices.len, 1, 0, 0, 0);

        // reset for next render
        ctx.instance_count = 0;
    }

    pub fn debugText(ctx: *Context, fmt: []const u8, args: anytype) !void {
        _ = fmt;
        _ = args;
        ctx.instances[0].mvp = math.identity();
        ctx.instance_count = 1;
    }
};
