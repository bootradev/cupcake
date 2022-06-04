const cc_bake = @import("cc_bake");
const cc_gfx = @import("cc_gfx");
const cc_math = @import("cc_math");
const cc_res = @import("cc_res");
const cc_time = @import("cc_time");
const cc_wnd = @import("cc_wnd");
const cc_wnd_gfx = @import("cc_wnd_gfx");
const std = @import("std");

const Vertex = struct {
    position: cc_math.F32x4,
    color: cc_math.F32x4,
};

const Uniforms = struct {
    mvp: cc_math.Mat,
};

const vertices: []const Vertex = &.{
    // front
    .{ .position = cc_math.f32x4(-1, -1, -1, 1), .color = cc_math.f32x4(1.0, 1.0, 1.0, 1) },
    .{ .position = cc_math.f32x4(1, -1, -1, 1), .color = cc_math.f32x4(0.71, 1.0, 1.0, 1) },
    .{ .position = cc_math.f32x4(-1, 1, -1, 1), .color = cc_math.f32x4(1.0, 0.71, 1.0, 1) },
    .{ .position = cc_math.f32x4(1, 1, -1, 1), .color = cc_math.f32x4(0.71, 0.71, 1.0, 1) },
    // back
    .{ .position = cc_math.f32x4(-1, -1, 1, 1), .color = cc_math.f32x4(1.0, 1.0, 0.71, 1) },
    .{ .position = cc_math.f32x4(1, -1, 1, 1), .color = cc_math.f32x4(0.71, 1.0, 0.71, 1) },
    .{ .position = cc_math.f32x4(-1, 1, 1, 1), .color = cc_math.f32x4(1.0, 0.71, 0.71, 1) },
    .{ .position = cc_math.f32x4(1, 1, 1, 1), .color = cc_math.f32x4(0.71, 0.71, 0.71, 1) },
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
    window: cc_wnd.Window,
    gctx: cc_gfx.Context,
    vertex_buffer: cc_gfx.Buffer,
    index_buffer: cc_gfx.Buffer,
    uniform_buffer: cc_gfx.Buffer,
    bind_group: cc_gfx.BindGroup,
    render_pipeline: cc_gfx.RenderPipeline,
    game_clock: cc_time.Timer,
};

pub fn init() !Example {
    var window = try cc_wnd.Window.init(.{ .width = 800, .height = 600, .title = "cube" });
    var gctx = try cc_gfx.Context.init(cc_wnd_gfx.getContextDesc(window));

    const vertex_buffer = try gctx.device.initBufferSlice(vertices, .{ .vertex = true });
    const index_buffer = try gctx.device.initBufferSlice(indices, .{ .index = true });
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

    const vert_shader_bake = try cc_res.load(cc_bake.cube_vert_shader, .{});
    var vert_shader = try gctx.device.initShader(vert_shader_bake.bytes);
    defer gctx.device.deinitShader(&vert_shader);

    const frag_shader_bake = try cc_res.load(cc_bake.cube_frag_shader, .{});
    var frag_shader = try gctx.device.initShader(frag_shader_bake.bytes);
    defer gctx.device.deinitShader(&frag_shader);

    var render_pipeline_desc = cc_gfx.RenderPipelineDesc{};
    render_pipeline_desc.setPipelineLayout(&pipeline_layout);
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
        // todo: zig #7607
        .buffers = &[_]cc_gfx.VertexBufferLayout{
            cc_gfx.getVertexBufferLayoutStruct(Vertex, .vertex, 0),
        },
    });
    render_pipeline_desc.setPrimitiveState(.{ .cull_mode = .back });
    render_pipeline_desc.setDepthStencilState(.{
        .format = gctx.depth_texture_format,
        .depth_write_enabled = true,
        .depth_compare = .less,
    });
    render_pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // todo: zig #7607
        .targets = &[_]cc_gfx.ColorTargetState{.{ .format = gctx.swapchain_format }},
    });

    const render_pipeline = try gctx.device.initRenderPipeline(render_pipeline_desc);

    const game_clock = try cc_time.Timer.start();

    return Example{
        .window = window,
        .gctx = gctx,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .uniform_buffer = uniform_buffer,
        .bind_group = bind_group,
        .render_pipeline = render_pipeline,
        .game_clock = game_clock,
    };
}

pub fn loop(ex: *Example) !void {
    const time = ex.game_clock.readSeconds();
    const model_matrix = cc_math.matFromAxisAngle(
        cc_math.f32x4(cc_math.sin(time), cc_math.cos(time), 0.0, 0.0),
        1.0,
    );
    const view_matrix = cc_math.lookToLh(
        cc_math.f32x4(0, 0, -4, 0),
        cc_math.f32x4(0, 0, 1, 0),
        cc_math.f32x4(0, 1, 0, 0),
    );
    const proj_matrix = cc_math.perspectiveFovLh(
        2.0 * std.math.pi / 5.0,
        ex.window.getAspectRatio(),
        1,
        100,
    );
    const mvp_matrix = cc_math.mul(cc_math.mul(model_matrix, view_matrix), proj_matrix);
    const uniforms = Uniforms{ .mvp = cc_math.transpose(mvp_matrix) };

    var queue = ex.gctx.device.getQueue();
    try queue.writeBuffer(&ex.uniform_buffer, 0, std.mem.asBytes(&uniforms), 0);

    const swapchain_view = try ex.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try ex.gctx.device.initCommandEncoder();

    var render_pass_desc = cc_gfx.RenderPassDesc{};
    // todo: zig #7607
    render_pass_desc.setColorAttachments(&[_]cc_gfx.ColorAttachment{.{
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
    try render_pass.setVertexBuffer(0, &ex.vertex_buffer, 0, cc_gfx.whole_size);
    try render_pass.setIndexBuffer(&ex.index_buffer, .uint16, 0, cc_gfx.whole_size);
    try render_pass.drawIndexed(indices.len, 1, 0, 0, 0);
    try render_pass.end();

    try queue.submit(&.{try command_encoder.finish()});
    try ex.gctx.swapchain.present();
}

pub fn deinit(ex: *Example) !void {
    ex.gctx.device.deinitRenderPipeline(&ex.render_pipeline);
    ex.gctx.device.deinitBindGroup(&ex.bind_group);
    ex.gctx.device.deinitBuffer(&ex.uniform_buffer);
    ex.gctx.device.deinitBuffer(&ex.index_buffer);
    ex.gctx.device.deinitBuffer(&ex.vertex_buffer);
    ex.gctx.deinit();
    ex.window.deinit();
}
