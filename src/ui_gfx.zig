const gfx = @import("gfx.zig");
const std = @import("std");

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

pub const Instance = struct {
    pos_size: [4]f32,
    uv_pos_size: [4]f32,
    color: [4]f32,

    pub fn setPos(instance: *Instance, x: f32, y: f32) void {
        instance.pos_size[0] = x;
        instance.pos_size[1] = y;
    }

    pub fn setSize(instance: *Instance, width: f32, height: f32) void {
        instance.pos_size[2] = width;
        instance.pos_size[3] = height;
    }

    pub fn setUvPos(instance: *Instance, x: f32, y: f32) void {
        instance.uv_pos_size[0] = x;
        instance.uv_pos_size[1] = y;
    }

    pub fn setUvSize(instance: *Instance, width: f32, height: f32) void {
        instance.uv_pos_size[2] = width;
        instance.uv_pos_size[3] = height;
    }

    pub fn setColor(instance: *Instance, r: f32, g: f32, b: f32, a: f32) void {
        instance.color[0] = r;
        instance.color[1] = g;
        instance.color[2] = b;
        instance.color[3] = a;
    }
};

pub const Uniforms = struct {
    viewport: [2]f32,
};

pub const RenderData = *gfx.RenderPass;

pub const ContextDesc = struct {
    device: *gfx.Device,
    format: gfx.TextureFormat,
    max_instances: usize,
    allocator: std.mem.Allocator,
};

pub const Context = struct {
    allocator: std.mem.Allocator,
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
    uniforms: Uniforms,
    instances: []Instance,
    instance_count: usize,

    pub fn init(desc: ContextDesc, res_impl: anytype) !Context {
        const vertex_buffer = try desc.device.initBufferSlice(
            quad_vertices,
            .{ .vertex = true },
        );
        const index_buffer = try desc.device.initBufferSlice(
            quad_indices,
            .{ .index = true },
        );
        const instance_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(Instance) * desc.max_instances,
            .usage = .{ .vertex = true, .copy_dst = true },
        });
        const uniform_buffer = try desc.device.initBuffer(.{
            .size = @sizeOf(Uniforms),
            .usage = .{ .uniform = true, .copy_dst = true },
        });

        const font_atlas_desc = try res_impl.loadFontAtlasDesc(desc.allocator);
        defer res_impl.freeFontAtlasDesc(desc.allocator, font_atlas_desc);
        var font_atlas_texture = try desc.device.initTexture(
            font_atlas_desc,
            .{
                .copy_dst = true,
                .texture_binding = true,
                .render_attachment = true,
            },
        );
        const font_atlas_view = try desc.device.initTextureView(.{
            .texture = &font_atlas_texture,
            .format = font_atlas_desc.format,
        });

        const sampler = try desc.device.initSampler(.{
            .mag_filter = .linear,
            .min_filter = .linear,
        });

        const vert_shader_desc = try res_impl.loadVertShaderDesc(desc.allocator);
        defer res_impl.freeVertShaderDesc(desc.allocator, vert_shader_desc);
        var vert_shader = try desc.device.initShader(vert_shader_desc);
        defer desc.device.deinitShader(&vert_shader);

        const frag_shader_desc = try res_impl.loadFragShaderDesc(desc.allocator);
        defer res_impl.freeFragShaderDesc(desc.allocator, frag_shader_desc);
        var frag_shader = try desc.device.initShader(frag_shader_desc);
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
                    .resource = .{
                        .buffer_binding = .{ .buffer = &uniform_buffer },
                    },
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
                gfx.getVertexBufferLayoutStruct(Instance, .instance, 1),
            },
        });
        render_pipeline_desc.setFragmentState(.{
            .module = &frag_shader,
            .entry_point = "fs_main",
            // todo: zig #7607
            .targets = &[_]gfx.ColorTargetState{.{ .format = desc.format }},
        });

        const render_pipeline = try desc.device.initRenderPipeline(
            render_pipeline_desc,
        );

        const instances = try desc.allocator.alloc(Instance, desc.max_instances);
        const uniforms = Uniforms{ .viewport = [_]f32{ 0.0, 0.0 } };

        return Context{
            .allocator = desc.allocator,
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
            .uniforms = uniforms,
            .instances = instances,
            .instance_count = 0,
        };
    }

    pub fn render(ctx: *Context, pass: *gfx.RenderPass) !void {
        const uniform_bytes = std.mem.asBytes(&ctx.uniforms);
        const instance_slice = ctx.instances[0..ctx.instance_count];
        const instance_bytes = std.mem.sliceAsBytes(instance_slice);
        var queue = ctx.device.getQueue();
        try queue.writeBuffer(&ctx.uniform_buffer, 0, uniform_bytes, 0);
        try queue.writeBuffer(&ctx.instance_buffer, 0, instance_bytes, 0);
        try pass.setPipeline(&ctx.render_pipeline);
        try pass.setBindGroup(0, &ctx.bind_group, null);
        try pass.setVertexBuffer(0, &ctx.vertex_buffer, 0, gfx.whole_size);
        try pass.setVertexBuffer(1, &ctx.instance_buffer, 0, instance_bytes.len);
        try pass.setIndexBuffer(&ctx.index_buffer, .uint16, 0, gfx.whole_size);
        try pass.drawIndexed(quad_indices.len, ctx.instance_count, 0, 0, 0);
    }

    pub fn setViewport(ctx: *Context, width: f32, height: f32) void {
        ctx.uniforms.viewport[0] = width;
        ctx.uniforms.viewport[1] = height;
    }

    pub fn addInstance(ctx: *Context) !*Instance {
        if (ctx.instance_count >= ctx.instances.len) {
            return error.OutOfInstances;
        }

        const instance = &ctx.instances[ctx.instance_count];
        ctx.instance_count += 1;
        return instance;
    }

    pub fn resetInstances(ctx: *Context) void {
        ctx.instance_count = 0;
    }

    pub fn deinit(ctx: *Context) void {
        ctx.allocator.free(ctx.instances);
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
