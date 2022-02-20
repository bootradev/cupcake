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
    example.window = try cc.app.Window.init(
        cc.math.V2u32.make(800, 600),
        .{ .name = "cupcake texture example" },
    );
    example.instance = try cc.gfx.Instance.init();
    example.surface = try example.instance.createSurface(
        &example.window,
        cc.gfx.SurfaceDesc.default(),
    );
    example.adapter = try example.instance.requestAdapter(
        &example.surface,
        cc.gfx.AdapterDesc.default(),
    );
    example.device = try example.adapter.requestDevice(cc.gfx.DeviceDesc.default());

    const swapchain_format = comptime cc.gfx.Surface.getPreferredFormat();
    const swapchain_desc = cc.gfx.SwapchainDesc.init()
        .size(.{ .width = example.window.size.x, .height = example.window.size.y })
        .format(swapchain_format);
    defer swapchain_desc.deinit();
    example.swapchain = try example.device.createSwapchain(&example.surface, swapchain_desc);

    const quad_vertices_bytes = std.mem.sliceAsBytes(quad_data.vertices);
    const vertex_buffer_desc = cc.gfx.BufferDesc.init()
        .size(quad_vertices_bytes.len)
        .usage(.{ .vertex = true });
    defer vertex_buffer_desc.deinit();
    example.vertex_buffer = try example.device.createBuffer(
        vertex_buffer_desc,
        quad_vertices_bytes,
    );

    const quad_indices_bytes = std.mem.sliceAsBytes(quad_data.indices);
    const index_buffer_desc = cc.gfx.BufferDesc.init()
        .size(quad_indices_bytes.len)
        .usage(.{ .index = true });
    defer index_buffer_desc.deinit();
    example.index_buffer = try example.device.createBuffer(
        index_buffer_desc,
        quad_indices_bytes,
    );

    const texture_res = try cc.res.load(
        res.cupcake_texture,
        .{
            .file_allocator = example.file_allocator.allocator(),
            .res_allocator = example.file_allocator.allocator(),
        },
    );

    const texture_desc = cc.gfx.TextureDesc.init()
        .size(.{ .width = texture_res.width, .height = texture_res.height })
        .format(.rgba8unorm)
        .usage(.{ .copy_dst = true, .texture_binding = true, .render_attachment = true });
    defer texture_desc.deinit();
    example.texture = try example.device.createTexture(texture_desc);
    example.texture_view = example.texture.createView();

    const sampler_desc = cc.gfx.SamplerDesc.init().magFilter(.linear).minFilter(.linear);
    defer sampler_desc.deinit();
    example.sampler = try example.device.createSampler(sampler_desc);

    const copy_dest_desc = cc.gfx.ImageCopyTextureDesc.init().texture(example.texture);
    defer copy_dest_desc.deinit();
    const copy_layout_desc = cc.gfx.ImageDataLayoutDesc.init()
        .bytesPerRow(texture_res.width * 4)
        .rowsPerImage(texture_res.height);
    defer copy_layout_desc.deinit();
    const copy_size = cc.gfx.Extent3d{ .width = texture_res.width, .height = texture_res.height };
    var queue = example.device.getQueue();
    queue.writeTexture(copy_dest_desc, texture_res.data, copy_layout_desc, copy_size);

    const bind_group_layout_desc = cc.gfx.BindGroupLayoutDesc.init()
        .entries()
        .entry().binding(1).visibility(.{ .fragment = true }).sampler().end().end()
        .entry().binding(2).visibility(.{ .fragment = true }).texture().end().end()
        .end();
    defer bind_group_layout_desc.deinit();
    var layout = try example.device.createBindGroupLayout(bind_group_layout_desc);
    defer layout.destroy();

    const bind_group_desc = cc.gfx.BindGroupDesc.init()
        .layout(layout)
        .entries()
        .entry().binding(1).sampler(example.sampler).end()
        .entry().binding(2).textureView(example.texture_view).end()
        .end();
    defer bind_group_desc.deinit();
    example.bind_group = try example.device.createBindGroup(bind_group_desc);

    const vert_shader_res = try cc.res.load(res.texture_vert_shader, .{});
    var vert_shader = try example.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.res.load(res.texture_frag_shader, .{});
    var frag_shader = try example.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    const pipeline_layout_desc = cc.gfx.PipelineLayoutDesc.init()
        .bindGroupLayouts(&.{layout});
    defer pipeline_layout_desc.deinit();
    var pipeline_layout = try example.device.createPipelineLayout(pipeline_layout_desc);
    defer pipeline_layout.destroy();

    const render_pipeline_desc = cc.gfx.RenderPipelineDesc.init()
        .layout(pipeline_layout)
        .vertex()
        .module(vert_shader)
        .entryPoint("vs_main")
        .buffers()
        .buffer()
        .arrayStride(quad_data.array_stride)
        .attributes()
        .attribute().shaderLocation(0).offset(quad_data.position_offset).format(.float32x2).end()
        .attribute().shaderLocation(1).offset(quad_data.uv_offset).format(.float32x2).end()
        .end()
        .end()
        .end()
        .end()
        .primitive().cullMode(.back).end()
        .fragment()
        .module(frag_shader)
        .entryPoint("fs_main")
        .targets().target().format(swapchain_format).end().end()
        .end();
    defer render_pipeline_desc.deinit();
    example.render_pipeline = try example.device.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
    const render_pass_desc = cc.gfx.RenderPassDesc.init()
        .colorAttachments()
        .colorAttachment()
        .view(swapchain_view)
        .loadOp(.clear)
        .clearValue(cc.gfx.default_clear_color)
        .storeOp(.store)
        .end()
        .end();
    defer render_pass_desc.deinit();
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
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
