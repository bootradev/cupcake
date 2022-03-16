const cc = @import("cupcake");
const res = @import("res");
const std = @import("std");

const cube_data = struct {
    const position_offset = 0;
    const uv_offset = 4 * 4;
    const array_stride = 4 * 6;

    // position (vec4), uv (vec2),
    const vertices: []const f32 = &.{
        -1, -1, -1, 1, 0, 1,
        1,  -1, -1, 1, 1, 1,
        -1, 1,  -1, 1, 0, 0,
        1,  1,  -1, 1, 1, 0,
        -1, -1, 1,  1, 1, 1,
        1,  -1, 1,  1, 0, 1,
        -1, 1,  1,  1, 1, 0,
        1,  1,  1,  1, 0, 0,
    };

    const indices: []const u16 = &.{
        0, 1, 2, 2, 1, 3, // front
        2, 3, 6, 6, 3, 7, // top
        1, 5, 3, 3, 5, 7, // right
        4, 5, 0, 0, 5, 1, // bottom
        4, 0, 6, 6, 0, 2, // left
        5, 4, 7, 7, 4, 6, // back
    };
};

const Example = struct {
    game_clock: cc.app.Timer,
    file_allocator: cc.mem.BumpAllocator,
    window: cc.app.Window,
    ctx: cc.gfx.Context,
    render_pipeline: cc.gfx.RenderPipeline,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
    uniform_buffer: cc.gfx.Buffer,
    depth_texture: cc.gfx.Texture,
    depth_texture_view: cc.gfx.TextureView,
    cube_texture: cc.gfx.Texture,
    cube_texture_view: cc.gfx.TextureView,
    cube_texture_sampler: cc.gfx.Sampler,
    bind_group: cc.gfx.BindGroup,
};

var example: Example = undefined;

pub fn init() !void {
    example.game_clock = try cc.app.Timer.start();
    example.file_allocator = try cc.mem.BumpAllocator.init(64 * 1024 * 1024);

    example.window = try cc.app.Window.init(cc.math.V2u32.make(800, 600), .{});
    example.ctx = try cc.gfx.Context.init(
        example.window,
        cc.gfx.AdapterDesc.default(),
        cc.gfx.DeviceDesc.default(),
    );

    const cube_vertices_bytes = std.mem.sliceAsBytes(cube_data.vertices);
    const vertex_buffer_desc = cc.gfx.BufferDesc.init()
        .size(cube_vertices_bytes.len)
        .usage(.{ .vertex = true });
    defer vertex_buffer_desc.deinit();
    example.vertex_buffer = try example.ctx.device.createBuffer(
        vertex_buffer_desc,
        cube_vertices_bytes,
    );

    const cube_indices_bytes = std.mem.sliceAsBytes(cube_data.indices);
    const index_buffer_desc = cc.gfx.BufferDesc.init()
        .size(cube_indices_bytes.len)
        .usage(.{ .index = true });
    defer index_buffer_desc.deinit();
    example.index_buffer = try example.ctx.device.createBuffer(
        index_buffer_desc,
        cube_indices_bytes,
    );

    const uniform_buffer_desc = cc.gfx.BufferDesc.init()
        .size(64)
        .usage(.{ .uniform = true, .copy_dst = true });
    defer uniform_buffer_desc.deinit();
    example.uniform_buffer = try example.ctx.device.createBuffer(uniform_buffer_desc, null);

    const depth_texture_desc = cc.gfx.TextureDesc.init()
        .size(.{ .width = example.window.size.x, .height = example.window.size.y })
        .format(.depth24plus)
        .usage(.{ .render_attachment = true });
    defer depth_texture_desc.deinit();
    example.depth_texture = try example.ctx.device.createTexture(depth_texture_desc);
    example.depth_texture_view = example.depth_texture.createView();

    const tex_res = try cc.app.load(
        res.cupcake_texture,
        .{
            .file_allocator = example.file_allocator.allocator(),
            .res_allocator = example.file_allocator.allocator(),
        },
    );
    const cube_tex_desc = cc.gfx.TextureDesc.init()
        .size(.{ .width = tex_res.width, .height = tex_res.height })
        .format(.rgba8unorm)
        .usage(.{ .copy_dst = true, .texture_binding = true, .render_attachment = true });
    defer cube_tex_desc.deinit();
    example.cube_texture = try example.ctx.device.createTexture(cube_tex_desc);
    example.cube_texture_view = example.cube_texture.createView();

    const cube_tex_sampler_desc = cc.gfx.SamplerDesc.init().magFilter(.linear).minFilter(.linear);
    defer cube_tex_sampler_desc.deinit();
    example.cube_texture_sampler = try example.ctx.device.createSampler(cube_tex_sampler_desc);

    const copy_dest_desc = cc.gfx.ImageCopyTextureDesc.init().texture(example.cube_texture);
    defer copy_dest_desc.deinit();
    const copy_layout_desc = cc.gfx.ImageDataLayoutDesc.init()
        .bytesPerRow(tex_res.width * 4)
        .rowsPerImage(tex_res.height);
    defer copy_layout_desc.deinit();
    const copy_size = cc.gfx.Extent3d{ .width = tex_res.width, .height = tex_res.height };
    var queue = example.ctx.device.getQueue();
    queue.writeTexture(copy_dest_desc, tex_res.data, copy_layout_desc, copy_size);

    const bind_group_layout_desc = cc.gfx.BindGroupLayoutDesc.init()
        .entries()
        .entry().binding(0).visibility(.{ .vertex = true }).buffer().end().end()
        .entry().binding(1).visibility(.{ .fragment = true }).sampler().end().end()
        .entry().binding(2).visibility(.{ .fragment = true }).texture().end().end()
        .end();
    defer bind_group_layout_desc.deinit();
    var bind_group_layout = try example.ctx.device.createBindGroupLayout(bind_group_layout_desc);
    defer bind_group_layout.destroy();

    const bind_group_desc = cc.gfx.BindGroupDesc.init()
        .layout(bind_group_layout)
        .entries()
        .entry().binding(0).buffer(example.uniform_buffer).end().end()
        .entry().binding(1).sampler(example.cube_texture_sampler).end()
        .entry().binding(2).textureView(example.cube_texture_view).end()
        .end();
    defer bind_group_desc.deinit();
    example.bind_group = try example.ctx.device.createBindGroup(bind_group_desc);

    const vert_shader_res = try cc.app.load(res.cube_vert_shader, .{});
    var vert_shader = try example.ctx.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.app.load(res.cube_frag_shader, .{});
    var frag_shader = try example.ctx.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    const pipeline_layout_desc = cc.gfx.PipelineLayoutDesc.init()
        .bindGroupLayouts(&.{bind_group_layout});
    defer pipeline_layout_desc.deinit();
    var pipeline_layout = try example.ctx.device.createPipelineLayout(pipeline_layout_desc);
    defer pipeline_layout.destroy();

    const render_pipeline_desc = cc.gfx.RenderPipelineDesc.init()
        .layout(pipeline_layout)
        .vertex()
        .module(vert_shader)
        .entryPoint("vs_main")
        .buffers()
        .buffer()
        .arrayStride(cube_data.array_stride)
        .attributes()
        .attribute().shaderLocation(0).offset(cube_data.position_offset).format(.float32x4).end()
        .attribute().shaderLocation(1).offset(cube_data.uv_offset).format(.float32x2).end()
        .end()
        .end()
        .end()
        .end()
        .primitive().cullMode(.back).end()
        .depthStencil().depthWriteEnabled(true).depthCompare(.less).format(.depth24plus).end()
        .fragment()
        .module(frag_shader)
        .entryPoint("fs_main")
        .targets().target().format(example.ctx.swapchain_format).end().end()
        .end();
    defer render_pipeline_desc.deinit();
    example.render_pipeline = try example.ctx.device.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
    const time = cc.app.readSeconds(example.game_clock);
    const model_matrix = cc.math.M44f32.makeAngleAxis(
        1.0,
        cc.math.V3f32.make(cc.math.sinFast(time), cc.math.cosFast(time), 0.0),
    );
    const view_matrix = cc.math.M44f32.makeView(
        cc.math.V3f32.make(0, 0, -4),
        cc.math.V3f32.forward,
        cc.math.V3f32.up,
    );
    const proj_matrix = cc.math.M44f32.makePerspective(
        2.0 * std.math.pi / 5.0,
        @intToFloat(f32, example.window.size.x) / @intToFloat(f32, example.window.size.y),
        1,
        100,
    );
    const mvp_matrix = model_matrix.mul(view_matrix.mul(proj_matrix));

    var queue = example.ctx.device.getQueue();
    queue.writeBuffer(example.uniform_buffer, 0, mvp_matrix.asBytes(), 0);

    var swapchain_view = try example.ctx.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.ctx.device.createCommandEncoder();

    const render_pass_desc = cc.gfx.RenderPassDesc.init()
        .colorAttachments()
        .colorAttachment()
        .view(swapchain_view)
        .loadOp(.clear)
        .clearValue(cc.gfx.default_clear_color)
        .storeOp(.store)
        .end()
        .end()
        .depthStencilAttachment()
        .view(example.depth_texture_view)
        .depthLoadOp(.clear)
        .depthClearValue(1.0)
        .depthStoreOp(.store)
        .end();
    defer render_pass_desc.deinit();
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    render_pass.setPipeline(example.render_pipeline);
    render_pass.setBindGroup(0, example.bind_group, null);
    render_pass.setVertexBuffer(0, example.vertex_buffer, 0, cc.gfx.whole_size);
    render_pass.setIndexBuffer(example.index_buffer, .uint16, 0, cc.gfx.whole_size);
    render_pass.drawIndexed(cube_data.indices.len, 1, 0, 0, 0);
    render_pass.end();

    queue.submit(&.{command_encoder.finish(.{})});
    example.ctx.swapchain.present();
}

pub fn deinit() !void {
    example.bind_group.destroy();
    example.depth_texture_view.destroy();
    example.depth_texture.destroy();
    example.uniform_buffer.destroy();
    example.index_buffer.destroy();
    example.vertex_buffer.destroy();
    example.render_pipeline.destroy();
    example.ctx.deinit();
    example.window.deinit();
}
