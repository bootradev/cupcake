const cc = @import("cupcake");
const res = @import("res");
const std = @import("std");

const Vertex = struct {
    position: cc.math.F32x4,
    color: cc.math.F32x4,
};

const Uniforms = struct {
    mvp: cc.math.Mat,
};

const vertices: []const Vertex = &.{
    // front
    .{ .position = cc.math.f32x4(-1, -1, -1, 1), .color = cc.math.f32x4(1.0, 1.0, 1.0, 1) },
    .{ .position = cc.math.f32x4(1, -1, -1, 1), .color = cc.math.f32x4(0.71, 1.0, 1.0, 1) },
    .{ .position = cc.math.f32x4(-1, 1, -1, 1), .color = cc.math.f32x4(1.0, 0.71, 1.0, 1) },
    .{ .position = cc.math.f32x4(1, 1, -1, 1), .color = cc.math.f32x4(0.71, 0.71, 1.0, 1) },
    // back
    .{ .position = cc.math.f32x4(-1, -1, 1, 1), .color = cc.math.f32x4(1.0, 1.0, 0.71, 1) },
    .{ .position = cc.math.f32x4(1, -1, 1, 1), .color = cc.math.f32x4(0.71, 1.0, 0.71, 1) },
    .{ .position = cc.math.f32x4(-1, 1, 1, 1), .color = cc.math.f32x4(1.0, 0.71, 0.71, 1) },
    .{ .position = cc.math.f32x4(1, 1, 1, 1), .color = cc.math.f32x4(0.71, 0.71, 0.71, 1) },
};

const indices: []const u16 = &.{
    0, 1, 2, 2, 1, 3, // front
    2, 3, 6, 6, 3, 7, // top
    1, 5, 3, 3, 5, 7, // right
    4, 5, 0, 0, 5, 1, // bottom
    4, 0, 6, 6, 0, 2, // left
    5, 4, 7, 7, 4, 6, // back
};

const Example = struct {
    window: cc.app.Window,
    gctx: cc.gfx.Context,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
    uniform_buffer: cc.gfx.Buffer,
    bind_group: cc.gfx.BindGroup,
    render_pipeline: cc.gfx.RenderPipeline,
    game_clock: cc.app.Timer,
};

var ex: Example = undefined;

pub fn init() !void {
    ex.window = try cc.app.Window.init(.{ .width = 800, .height = 600, .title = "cube" });
    ex.gctx = try cc.gfx.Context.init(.{ .window = &ex.window });

    ex.vertex_buffer = try ex.gctx.device.initBufferWithSlice(vertices, .{ .vertex = true });
    ex.index_buffer = try ex.gctx.device.initBufferWithSlice(indices, .{ .index = true });
    ex.uniform_buffer = try ex.gctx.device.initBuffer(.{
        .size = @sizeOf(Uniforms),
        .usage = .{ .uniform = true, .copy_dst = true },
    });

    var bind_group_layout = try ex.gctx.device.initBindGroupLayout(.{
        .entries = &.{.{
            .binding = 0,
            .visibility = .{ .vertex = true },
            .buffer = .{},
        }},
    });
    defer ex.gctx.device.deinitBindGroupLayout(&bind_group_layout);

    ex.bind_group = try ex.gctx.device.initBindGroup(.{
        .layout = &bind_group_layout,
        .entries = &.{.{
            .binding = 0,
            .resource = .{ .buffer_binding = .{ .buffer = &ex.uniform_buffer } },
        }},
    });

    var pipeline_layout = try ex.gctx.device.initPipelineLayout(
        .{ .bind_group_layouts = &.{bind_group_layout} },
    );
    defer ex.gctx.device.deinitPipelineLayout(&pipeline_layout);

    var vert_shader = try ex.gctx.device.loadShader(res.cube_vert_shader, .{});
    defer ex.gctx.device.deinitShader(&vert_shader);

    var frag_shader = try ex.gctx.device.loadShader(res.cube_frag_shader, .{});
    defer ex.gctx.device.deinitShader(&frag_shader);

    var render_pipeline_desc = cc.gfx.RenderPipelineDesc{};
    render_pipeline_desc.setPipelineLayout(&pipeline_layout);
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
        // todo: zig #7607
        .buffers = &[_]cc.gfx.VertexBufferLayout{
            cc.gfx.getVertexBufferLayout(Vertex, .vertex, 0),
        },
    });
    render_pipeline_desc.setPrimitiveState(.{ .cull_mode = .back });
    render_pipeline_desc.setDepthStencilState(.{
        .format = ex.gctx.depth_texture_format,
        .depth_write_enabled = true,
        .depth_compare = .less,
    });
    render_pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // todo: zig #7607
        .targets = &[_]cc.gfx.ColorTargetState{.{ .format = ex.gctx.swapchain_format }},
    });

    ex.render_pipeline = try ex.gctx.device.initRenderPipeline(render_pipeline_desc);

    ex.game_clock = try cc.app.Timer.start();
}

pub fn loop() !void {
    const time = ex.game_clock.readSeconds();
    const model_matrix = cc.math.matFromAxisAngle(
        cc.math.f32x4(cc.math.sin(time), cc.math.cos(time), 0.0, 0.0),
        1.0,
    );
    const view_matrix = cc.math.lookToLh(
        cc.math.f32x4(0, 0, -4, 0),
        cc.math.f32x4(0, 0, 1, 0),
        cc.math.f32x4(0, 1, 0, 0),
    );
    const proj_matrix = cc.math.perspectiveFovLh(
        2.0 * std.math.pi / 5.0,
        ex.window.getAspectRatio(),
        1,
        100,
    );
    const mvp_matrix = cc.math.mul(cc.math.mul(model_matrix, view_matrix), proj_matrix);
    const uniforms = Uniforms{ .mvp = cc.math.transpose(mvp_matrix) };

    var queue = ex.gctx.device.getQueue();
    try queue.writeBuffer(&ex.uniform_buffer, 0, std.mem.asBytes(&uniforms), 0);

    const swapchain_view = try ex.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try ex.gctx.device.initCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    // todo: zig #7607
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = ex.gctx.clear_color,
        .store_op = .store,
    }});
    render_pass_desc.setDepthStencilAttachment(.{
        .view = &ex.gctx.depth_texture_view,
        .depth_clear_value = 1.0,
        .depth_load_op = .clear,
        .depth_store_op = .store,
    });

    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try render_pass.setPipeline(&ex.render_pipeline);
    try render_pass.setBindGroup(0, &ex.bind_group, null);
    try render_pass.setVertexBuffer(0, &ex.vertex_buffer, 0, cc.gfx.whole_size);
    try render_pass.setIndexBuffer(&ex.index_buffer, .uint16, 0, cc.gfx.whole_size);
    try render_pass.drawIndexed(indices.len, 1, 0, 0, 0);
    try render_pass.end();

    try queue.submit(&.{try command_encoder.finish()});
    try ex.gctx.swapchain.present();
}

pub fn deinit() !void {
    ex.gctx.device.deinitRenderPipeline(&ex.render_pipeline);
    ex.gctx.device.deinitBindGroup(&ex.bind_group);
    ex.gctx.device.deinitBuffer(&ex.uniform_buffer);
    ex.gctx.device.deinitBuffer(&ex.index_buffer);
    ex.gctx.device.deinitBuffer(&ex.vertex_buffer);
    ex.gctx.deinit();
    ex.window.deinit();
}
