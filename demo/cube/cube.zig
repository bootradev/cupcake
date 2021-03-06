const cc_bake = @import("cc_bake");
const cc_gfx = @import("cc_gfx");
const cc_math = @import("cc_math");
const cc_res = @import("cc_res");
const cc_time = @import("cc_time");
const cc_wnd = @import("cc_wnd");
const cc_wnd_gfx = @import("cc_wnd_gfx");
const std = @import("std");

const Vertex = struct {
    position: [4]f32,
    color: [4]f32,
};

const Uniforms = struct {
    mvp: [16]f32,
};

const vertices: []const Vertex = &.{
    // front
    .{ .position = [_]f32{ -1, -1, -1, 1 }, .color = [_]f32{ 1.0, 1.0, 1.0, 1 } },
    .{ .position = [_]f32{ 1, -1, -1, 1 }, .color = [_]f32{ 0.71, 1.0, 1.0, 1 } },
    .{ .position = [_]f32{ -1, 1, -1, 1 }, .color = [_]f32{ 1.0, 0.71, 1.0, 1 } },
    .{ .position = [_]f32{ 1, 1, -1, 1 }, .color = [_]f32{ 0.71, 0.71, 1.0, 1 } },
    // back
    .{ .position = [_]f32{ -1, -1, 1, 1 }, .color = [_]f32{ 1.0, 1.0, 0.71, 1 } },
    .{ .position = [_]f32{ 1, -1, 1, 1 }, .color = [_]f32{ 0.71, 1.0, 0.71, 1 } },
    .{ .position = [_]f32{ -1, 1, 1, 1 }, .color = [_]f32{ 1.0, 0.71, 0.71, 1 } },
    .{ .position = [_]f32{ 1, 1, 1, 1 }, .color = [_]f32{ 0.71, 0.71, 0.71, 1 } },
};

const indices: []const u16 = &.{
    0, 1, 2, 2, 1, 3, // front
    2, 3, 6, 6, 3, 7, // top
    1, 5, 3, 3, 5, 7, // right
    4, 5, 0, 0, 5, 1, // bottom
    4, 0, 6, 6, 0, 2, // left
    5, 4, 7, 7, 4, 6, // back
};

const Demo = struct {
    window: cc_wnd.Window,
    gctx: cc_gfx.Context,
    vertex_buffer: cc_gfx.Buffer,
    index_buffer: cc_gfx.Buffer,
    uniform_buffer: cc_gfx.Buffer,
    bind_group: cc_gfx.BindGroup,
    render_pipeline: cc_gfx.RenderPipeline,
    uniforms: Uniforms,
    game_clock: cc_time.Timer,
};

pub fn init() !Demo {
    var window = try cc_wnd.Window.init(.{
        .width = 800,
        .height = 600,
        .title = "cube",
    });
    var gctx = try cc_gfx.Context.init(cc_wnd_gfx.getContextDesc(window));

    const vertex_buffer = try gctx.device.initBufferSlice(
        vertices,
        .{ .vertex = true },
    );
    const index_buffer = try gctx.device.initBufferSlice(
        indices,
        .{ .index = true },
    );
    const uniform_buffer = try gctx.device.initBuffer(.{
        .size = @sizeOf(Uniforms),
        .usage = .{ .uniform = true, .copy_dst = true },
    });

    var bind_group_layout = try gctx.device.initBindGroupLayout(.{
        .entries = &.{.{
            .binding = 0,
            .visibility = .{ .vertex = true },
            .buffer = .{},
        }},
    });
    defer gctx.device.deinitBindGroupLayout(&bind_group_layout);

    const bind_group = try gctx.device.initBindGroup(.{
        .layout = &bind_group_layout,
        // todo: zig #7607
        .entries = &[_]cc_gfx.BindGroupEntry{.{
            .binding = 0,
            .resource = .{ .buffer_binding = .{ .buffer = &uniform_buffer } },
        }},
    });

    var pipeline_layout = try gctx.device.initPipelineLayout(
        .{ .bind_group_layouts = &.{bind_group_layout} },
    );
    defer gctx.device.deinitPipelineLayout(&pipeline_layout);

    const vert_shader_desc = try cc_res.load(cc_bake.cube_vert_shader, .{});
    var vert_shader = try gctx.device.initShader(vert_shader_desc);
    defer gctx.device.deinitShader(&vert_shader);

    const frag_shader_desc = try cc_res.load(cc_bake.cube_frag_shader, .{});
    var frag_shader = try gctx.device.initShader(frag_shader_desc);
    defer gctx.device.deinitShader(&frag_shader);

    var pipeline_desc = cc_gfx.RenderPipelineDesc{};
    pipeline_desc.setPipelineLayout(&pipeline_layout);
    pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
        // todo: zig #7607
        .buffers = &[_]cc_gfx.VertexBufferLayout{
            cc_gfx.getVertexBufferLayoutStruct(Vertex, .vertex, 0),
        },
    });
    pipeline_desc.setPrimitiveState(.{ .cull_mode = .back });
    pipeline_desc.setDepthStencilState(.{
        .format = gctx.depth_texture_format,
        .depth_write_enabled = true,
        .depth_compare = .less,
    });
    pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // todo: zig #7607
        .targets = &[_]cc_gfx.ColorTargetState{
            .{ .format = gctx.swapchain_format },
        },
    });

    const pipeline = try gctx.device.initRenderPipeline(pipeline_desc);

    const game_clock = try cc_time.Timer.start();

    return Demo{
        .window = window,
        .gctx = gctx,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .uniform_buffer = uniform_buffer,
        .bind_group = bind_group,
        .render_pipeline = pipeline,
        .uniforms = .{ .mvp = [_]f32{0} ** 16 },
        .game_clock = game_clock,
    };
}

pub fn loop(demo: *Demo) !void {
    if (!demo.window.isVisible()) {
        return;
    }

    const time = demo.game_clock.readSeconds();
    const model = cc_math.matFromAxisAngle(
        cc_math.f32x4(cc_math.sin(time), cc_math.cos(time), 0.0, 0.0),
        1.0,
    );
    const view = cc_math.lookToLh(
        cc_math.f32x4(0, 0, -4, 0),
        cc_math.f32x4(0, 0, 1, 0),
        cc_math.f32x4(0, 1, 0, 0),
    );
    const proj = cc_math.perspectiveFovLh(
        2.0 * std.math.pi / 5.0,
        demo.window.getAspectRatio(),
        1,
        100,
    );
    const mvp = cc_math.transpose(cc_math.mul(cc_math.mul(model, view), proj));
    cc_math.storeMat(&demo.uniforms.mvp, mvp);

    var queue = demo.gctx.device.getQueue();
    try queue.writeBuffer(
        &demo.uniform_buffer,
        0,
        std.mem.asBytes(&demo.uniforms),
        0,
    );

    const swapchain_view = try demo.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try demo.gctx.device.initCommandEncoder();

    var render_pass_desc = cc_gfx.RenderPassDesc{};
    // todo: zig #7607
    render_pass_desc.setColorAttachments(&[_]cc_gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = demo.gctx.clear_color,
        .store_op = .store,
    }});
    render_pass_desc.setDepthStencilAttachment(.{
        .view = &demo.gctx.depth_texture_view,
        .depth_clear_value = 1.0,
        .depth_load_op = .clear,
        .depth_store_op = .store,
    });

    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try render_pass.setPipeline(&demo.render_pipeline);
    try render_pass.setBindGroup(0, &demo.bind_group, null);
    try render_pass.setVertexBuffer(0, &demo.vertex_buffer, 0, cc_gfx.whole_size);
    try render_pass.setIndexBuffer(
        &demo.index_buffer,
        .uint16,
        0,
        cc_gfx.whole_size,
    );
    try render_pass.drawIndexed(indices.len, 1, 0, 0, 0);
    try render_pass.end();

    try queue.submit(&.{try command_encoder.finish()});
    try demo.gctx.swapchain.present();
}

pub fn deinit(demo: *Demo) !void {
    demo.gctx.device.deinitRenderPipeline(&demo.render_pipeline);
    demo.gctx.device.deinitBindGroup(&demo.bind_group);
    demo.gctx.device.deinitBuffer(&demo.uniform_buffer);
    demo.gctx.device.deinitBuffer(&demo.index_buffer);
    demo.gctx.device.deinitBuffer(&demo.vertex_buffer);
    demo.gctx.deinit();
    demo.window.deinit();
}
