const cc = @import("cupcake");
const res = @import("res");
const std = @import("std");

const quad_data = struct {
    const position_offset = 0;
    const uv_offset = 4 * 2;
    const array_stride = 4 * 2 * 2;

    // position (vec2), uv (vec2)
    const vertices: []const f32 = &.{
        -0.5, -0.5, 0, 1,
        0.5,  -0.5, 1, 1,
        -0.5, 0.5,  0, 0,
        0.5,  0.5,  1, 0,
    };

    const indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };
};

const Example = struct {
    file_allocator: cc.mem.BumpAllocator,
    window: cc.app.Window,
    instance: cc.gfx.Instance,
    adapter: cc.gfx.Adapter,
    device: cc.gfx.Device,
    surface: cc.gfx.Surface,
    swapchain: cc.gfx.Swapchain,
    render_pipeline: cc.gfx.RenderPipeline,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
    texture: cc.gfx.Texture,
    texture_view: cc.gfx.TextureView,
    sampler: cc.gfx.Sampler,
    bind_group: cc.gfx.BindGroup,
};

var example: Example = undefined;

pub fn init() !void {
    example.file_allocator = try cc.mem.BumpAllocator.init(64 * 1024 * 1024);
    example.window = try cc.app.Window.init(cc.math.V2u32.make(800, 600), .{});
    example.instance = try cc.gfx.Instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    example.adapter = try example.instance.requestAdapter(&example.surface, .{});
    example.device = try example.adapter.requestDevice(.{});

    const swapchain_format = comptime cc.gfx.Surface.getPreferredFormat();

    example.swapchain = try example.device.createSwapchain(
        &example.surface,
        .{ .size = .{ .width = example.window.size.x, .height = example.window.size.y }, .format = swapchain_format },
    );

    const quad_vertices_bytes = std.mem.sliceAsBytes(quad_data.vertices);
    example.vertex_buffer = try example.device.createBuffer(
        .{ .size = quad_vertices_bytes.len, .usage = .{ .vertex = true } },
        quad_vertices_bytes,
    );
    const quad_indices_bytes = std.mem.sliceAsBytes(quad_data.indices);
    example.index_buffer = try example.device.createBuffer(
        .{ .size = quad_indices_bytes.len, .usage = .{ .index = true } },
        quad_indices_bytes,
    );

    const texture_res = try cc.res.load(
        res.cupcake_texture,
        .{
            .file_allocator = example.file_allocator.allocator(),
            .res_allocator = example.file_allocator.allocator(),
        },
    );

    example.texture = try example.device.createTexture(
        .{
            .size = .{ .width = texture_res.width, .height = texture_res.height },
            .format = .rgba8unorm,
            .usage = .{ .copy_dst = true, .texture_binding = true, .render_attachment = true },
        },
    );
    example.texture_view = example.texture.createView();

    example.sampler = try example.device.createSampler(.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    var queue = example.device.getQueue();
    queue.writeTexture(
        .{ .texture = &example.texture },
        texture_res.data,
        .{ .bytes_per_row = texture_res.width * 4, .rows_per_image = texture_res.height },
        .{ .width = texture_res.width, .height = texture_res.height },
    );

    var layout = try example.device.createBindGroupLayout(.{
        .entries = &.{
            .{ .binding = 1, .visibility = .{ .fragment = true }, .sampler = .{} },
            .{ .binding = 2, .visibility = .{ .fragment = true }, .texture = .{} },
        },
    });
    defer layout.destroy();

    example.bind_group = try example.device.createBindGroup(.{
        .layout = &layout,
        .entries = &.{
            .{ .binding = 1, .resource = .{ .sampler = &example.sampler } },
            .{ .binding = 2, .resource = .{ .texture_view = &example.texture_view } },
        },
    });

    const vert_shader_res = try cc.res.load(res.texture_vert_shader, .{});
    var vert_shader = try example.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.res.load(res.texture_frag_shader, .{});
    var frag_shader = try example.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    var pipeline_layout = try example.device.createPipelineLayout(.{
        .bind_group_layouts = &.{layout},
    });
    defer pipeline_layout.destroy();

    const vert_attrs = &[_]cc.gfx.VertexAttribute{
        .{
            // position
            .shader_location = 0,
            .offset = quad_data.position_offset,
            .format = .float32x2,
        },
        .{
            // uv
            .shader_location = 1,
            .offset = quad_data.uv_offset,
            .format = .float32x2,
        },
    };
    const vert_buffers = &[_]cc.gfx.VertexBufferLayout{
        .{
            .array_stride = quad_data.array_stride,
            .attributes = vert_attrs,
        },
    };
    const vert_state = cc.gfx.VertexState{
        .module = &vert_shader,
        .entry_point = "vs_main",
        .buffers = vert_buffers,
    };
    const frag_targets = &[_]cc.gfx.ColorTargetState{.{ .format = swapchain_format }};
    const frag_state = cc.gfx.FragmentState{
        .module = &frag_shader,
        .entry_point = "fs_main",
        .targets = frag_targets,
    };
    const prim_state: cc.gfx.PrimitiveState = .{ .cull_mode = .back };
    example.render_pipeline = try example.device.createRenderPipeline(.{
        .layout = &pipeline_layout,
        .vertex = vert_state,
        .fragment = frag_state,
        .primitive = prim_state,
    });
}

pub fn update() !void {
    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
    const color_attachments = &[_]cc.gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = cc.gfx.default_clear_color,
        .store_op = .store,
    }};
    var render_pass = try command_encoder.beginRenderPass(.{
        .color_attachments = color_attachments,
    });
    render_pass.setPipeline(&example.render_pipeline);
    render_pass.setBindGroup(0, &example.bind_group, null);
    render_pass.setVertexBuffer(0, &example.vertex_buffer, 0, cc.gfx.whole_size);
    render_pass.setIndexBuffer(&example.index_buffer, .uint16, 0, cc.gfx.whole_size);
    render_pass.drawIndexed(quad_data.indices.len, 1, 0, 0, 0);
    render_pass.end();

    var queue = example.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});

    example.swapchain.present();
}

pub fn deinit() !void {
    example.bind_group.destroy();
    example.sampler.destroy();
    example.texture_view.destroy();
    example.texture.destroy();
    example.index_buffer.destroy();
    example.vertex_buffer.destroy();
    example.render_pipeline.destroy();
    example.swapchain.destroy();
    example.device.destroy();
    example.adapter.destroy();
    example.surface.destroy();
    example.instance.deinit();
    example.window.deinit();
    example.file_allocator.deinit();
}
