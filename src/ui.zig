const cc_bake = @import("cc_bake");
const gfx = @import("gfx.zig");
const math = @import("math.zig");
const res = @import("res.zig");
const std = @import("std");
const wnd = @import("wnd.zig");

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
    window: *const wnd.Window,
    device: *gfx.Device,
    format: gfx.TextureFormat,
};

pub const Context = struct {
    const max_instances: usize = 256;

    window: *const wnd.Window,
    device: *gfx.Device,
    vertex_buffer: gfx.Buffer,
    index_buffer: gfx.Buffer,
    instance_buffer: gfx.Buffer,
    render_pipeline: gfx.RenderPipeline,
    instances: [max_instances]Instance,
    instance_count: usize,

    pub fn init(desc: ContextDesc) !Context {
        const vertex_buffer = try desc.device.initBufferSlice(quad_vertices, .{ .vertex = true });
        const index_buffer = try desc.device.initBufferSlice(quad_indices, .{ .index = true });
        const instance_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(Instance) * max_instances,
            .usage = .{ .vertex = true, .copy_dst = true },
        });

        const vert_shader_res = try res.load(cc_bake.src_ui_vert_shader, .{});
        var vert_shader = try desc.device.initShader(vert_shader_res.data);
        defer desc.device.deinitShader(&vert_shader);

        const frag_shader_res = try res.load(cc_bake.src_ui_frag_shader, .{});
        var frag_shader = try desc.device.initShader(frag_shader_res.data);
        defer desc.device.deinitShader(&frag_shader);

        var render_pipeline_desc = gfx.RenderPipelineDesc{};
        render_pipeline_desc.setVertexState(.{
            .module = &vert_shader,
            .entry_point = "vs_main",
            // todo: zig #7607
            .buffers = &[_]gfx.VertexBufferLayout{
                gfx.getVertexBufferLayoutStruct(Quad, .vertex, 0),
                gfx.getVertexBufferLayoutTypes(&[_]type{math.F32x4} ** 4, .instance, 2),
            },
        });
        render_pipeline_desc.setFragmentState(.{
            .module = &frag_shader,
            .entry_point = "fs_main",
            // todo: zig #7607
            .targets = &[_]gfx.ColorTargetState{.{ .format = desc.format }},
        });

        const render_pipeline = try desc.device.initRenderPipeline(render_pipeline_desc);

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
        ctx.device.deinitRenderPipeline(&ctx.render_pipeline);
        ctx.device.deinitBuffer(&ctx.instance_buffer);
        ctx.device.deinitBuffer(&ctx.index_buffer);
        ctx.device.deinitBuffer(&ctx.vertex_buffer);
    }

    pub fn render(ctx: *Context, render_pass: *gfx.RenderPass) !void {
        const instance_bytes = std.mem.sliceAsBytes(ctx.instances[0..ctx.instance_count]);
        try ctx.device.getQueue().writeBuffer(&ctx.instance_buffer, 0, instance_bytes, 0);

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
