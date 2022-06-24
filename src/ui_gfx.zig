const gfx = @import("gfx.zig");
const ui = @import("ui.zig");

pub const Quad = struct {
    pos_uv: [4]f32,
};

pub const quad_vertices: []const Quad = &.{
    .{ .pos_uv = [_]f32{ -0.5, -0.5, 0.0, 1.0 } },
    .{ .pos_uv = [_]f32{ 0.5, -0.5, 1.0, 1.0 } },
    .{ .pos_uv = [_]f32{ -0.5, 0.5, 0.0, 0.0 } },
    .{ .pos_uv = [_]f32{ 0.5, 0.5, 1.0, 0.0 } },
};
pub const quad_indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };

pub const ContextDesc = struct {
    device: *gfx.Device,
    format: gfx.TextureFormat,
    vert_shader_desc: gfx.ShaderDesc,
    frag_shader_desc: gfx.ShaderDesc,
    font_atlas_texture_desc: gfx.TextureDesc,
    max_instances: usize,
};

pub const Context = struct {
    device: *gfx.Device,
    vertex_buffer: gfx.Buffer,
    index_buffer: gfx.Buffer,
    instance_buffer: gfx.Buffer,
    uniform_buffer: gfx.Buffer,
    font_atlas_texture: gfx.Texture,
    font_atlas_view: gfx.TextureView,
    sampler: gfx.Sampler,
    bind_group: gfx.BindGroup,
    render_pipeline: gfx.RenderPipeline,

    pub fn init(desc: ContextDesc) !Context {
        const vertex_buffer = try desc.device.initBufferSlice(
            quad_vertices,
            .{ .vertex = true },
        );
        const index_buffer = try desc.device.initBufferSlice(
            quad_indices,
            .{ .index = true },
        );
        const instance_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(ui.Instance) * desc.max_instances,
            .usage = .{ .vertex = true, .copy_dst = true },
        });
        const uniform_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(ui.Uniforms),
            .usage = .{ .uniform = true, .copy_dst = true },
        });

        var font_atlas_texture = try desc.device.initTexture(
            desc.font_atlas_texture_desc,
            .{ .copy_dst = true, .texture_binding = true, .render_attachment = true },
        );
        const font_atlas_view = try desc.device.initTextureView(.{
            .texture = &font_atlas_texture,
            .format = desc.font_atlas_texture_desc.format,
        });

        const sampler = try desc.device.initSampler(.{
            .mag_filter = .linear,
            .min_filter = .linear,
        });

        var vert_shader = try desc.device.initShader(desc.vert_shader_desc);
        defer desc.device.deinitShader(&vert_shader);

        var frag_shader = try desc.device.initShader(desc.frag_shader_desc);
        defer desc.device.deinitShader(&frag_shader);

        var bind_group_layout = try desc.device.initBindGroupLayout(.{
            // todo: zig #7607
            .entries = &[_]gfx.BindGroupLayoutEntry{
                .{
                    .binding = 0,
                    .visibility = .{ .vertex = true },
                    .buffer = .{},
                },
                .{
                    .binding = 1,
                    .visibility = .{ .fragment = true },
                    .sampler = .{},
                },
                .{
                    .binding = 2,
                    .visibility = .{ .fragment = true },
                    .texture = .{},
                },
            },
        });
        defer desc.device.deinitBindGroupLayout(&bind_group_layout);

        const bind_group = try desc.device.initBindGroup(.{
            .layout = &bind_group_layout,
            .entries = &[_]gfx.BindGroupEntry{
                .{
                    .binding = 0,
                    .resource = .{ .buffer_binding = .{ .buffer = &uniform_buffer } },
                },
                .{
                    .binding = 1,
                    .resource = .{ .sampler = &sampler },
                },
                .{
                    .binding = 2,
                    .resource = .{ .texture_view = &font_atlas_view },
                },
            },
        });

        var pipeline_layout = try desc.device.initPipelineLayout(.{
            .bind_group_layouts = &[_]gfx.BindGroupLayout{bind_group_layout},
        });
        defer desc.device.deinitPipelineLayout(&pipeline_layout);

        var render_pipeline_desc = gfx.RenderPipelineDesc{};
        render_pipeline_desc.setPipelineLayout(&pipeline_layout);
        render_pipeline_desc.setVertexState(.{
            .module = &vert_shader,
            .entry_point = "vs_main",
            // todo: zig #7607
            .buffers = &[_]gfx.VertexBufferLayout{
                gfx.getVertexBufferLayoutStruct(Quad, .vertex, 0),
                gfx.getVertexBufferLayoutStruct(ui.Instance, .instance, 1),
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
            .uniform_buffer = uniform_buffer,
            .font_atlas_texture = font_atlas_texture,
            .font_atlas_view = font_atlas_view,
            .sampler = sampler,
            .bind_group = bind_group,
            .render_pipeline = render_pipeline,
        };
    }

    pub fn render(
        ctx: *Context,
        render_pass: *gfx.RenderPass,
        instance_count: usize,
        instance_bytes: []const u8,
        uniform_bytes: []const u8,
    ) !void {
        var queue = ctx.device.getQueue();
        try queue.writeBuffer(&ctx.uniform_buffer, 0, uniform_bytes, 0);
        try queue.writeBuffer(&ctx.instance_buffer, 0, instance_bytes, 0);
        try render_pass.setPipeline(&ctx.render_pipeline);
        try render_pass.setBindGroup(0, &ctx.bind_group, null);
        try render_pass.setVertexBuffer(0, &ctx.vertex_buffer, 0, gfx.whole_size);
        try render_pass.setVertexBuffer(1, &ctx.instance_buffer, 0, instance_bytes.len);
        try render_pass.setIndexBuffer(&ctx.index_buffer, .uint16, 0, gfx.whole_size);
        try render_pass.drawIndexed(quad_indices.len, instance_count, 0, 0, 0);
    }

    pub fn deinit(ctx: *Context) void {
        ctx.device.deinitRenderPipeline(&ctx.render_pipeline);
        ctx.device.deinitBindGroup(&ctx.bind_group);
        ctx.device.deinitSampler(&ctx.sampler);
        ctx.device.deinitTextureView(&ctx.font_atlas_view);
        ctx.device.deinitTexture(&ctx.font_atlas_texture);
        ctx.device.deinitBuffer(&ctx.uniform_buffer);
        ctx.device.deinitBuffer(&ctx.instance_buffer);
        ctx.device.deinitBuffer(&ctx.index_buffer);
        ctx.device.deinitBuffer(&ctx.vertex_buffer);
    }
};
