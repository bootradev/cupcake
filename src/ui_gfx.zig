const gfx = @import("gfx.zig");
const ui = @import("ui.zig");

pub const RenderData = *gfx.RenderPass;

pub const ContextDesc = struct {
    device: *gfx.Device,
    format: gfx.TextureFormat,
};

pub const Context = struct {
    device: *gfx.Device,
    vertex_buffer: gfx.Buffer,
    index_buffer: gfx.Buffer,
    instance_buffer: gfx.Buffer,
    render_pipeline: gfx.RenderPipeline,

    pub fn init(
        desc: ContextDesc,
        comptime ui_desc: ui.ContextDesc,
        vert_shader_bytes: []const u8,
        frag_shader_bytes: []const u8,
    ) !Context {
        const vertex_buffer = try desc.device.initBufferSlice(
            ui.quad_vertices,
            .{ .vertex = true },
        );
        const index_buffer = try desc.device.initBufferSlice(
            ui.quad_indices,
            .{ .index = true },
        );
        const instance_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(ui.Instance) * ui_desc.max_instances,
            .usage = .{ .vertex = true, .copy_dst = true },
        });

        var vert_shader = try desc.device.initShader(vert_shader_bytes);
        defer desc.device.deinitShader(&vert_shader);

        var frag_shader = try desc.device.initShader(frag_shader_bytes);
        defer desc.device.deinitShader(&frag_shader);

        var render_pipeline_desc = gfx.RenderPipelineDesc{};
        render_pipeline_desc.setVertexState(.{
            .module = &vert_shader,
            .entry_point = "vs_main",
            // todo: zig #7607
            .buffers = &[_]gfx.VertexBufferLayout{
                gfx.getVertexBufferLayoutStruct(ui.Quad, .vertex, 0),
                gfx.getVertexBufferLayoutTypes(&[_]type{@Vector(4, f32)} ** 4, .instance, 2),
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
            .device = desc.device,
            .vertex_buffer = vertex_buffer,
            .index_buffer = index_buffer,
            .instance_buffer = instance_buffer,
            .render_pipeline = render_pipeline,
        };
    }

    pub fn render(ctx: *Context, render_pass: *gfx.RenderPass, instance_bytes: []const u8) !void {
        try ctx.device.getQueue().writeBuffer(&ctx.instance_buffer, 0, instance_bytes, 0);
        try render_pass.setPipeline(&ctx.render_pipeline);
        try render_pass.setVertexBuffer(0, &ctx.vertex_buffer, 0, gfx.whole_size);
        try render_pass.setVertexBuffer(1, &ctx.instance_buffer, 0, instance_bytes.len);
        try render_pass.setIndexBuffer(&ctx.index_buffer, .uint16, 0, gfx.whole_size);
        try render_pass.drawIndexed(ui.quad_indices.len, 1, 0, 0, 0);
    }

    pub fn deinit(ctx: *Context) void {
        ctx.device.deinitRenderPipeline(&ctx.render_pipeline);
        ctx.device.deinitBuffer(&ctx.instance_buffer);
        ctx.device.deinitBuffer(&ctx.index_buffer);
        ctx.device.deinitBuffer(&ctx.vertex_buffer);
    }
};
