const cc = @import("cupcake");
const res = @import("res");
const std = @import("std");

const cube = struct {
    const position_offset = 0;
    const color_offset = @sizeOf(f32) * 4;
    const array_stride = @sizeOf(f32) * 8;

    // position (vec4), color (vec4),
    const vertices: []const f32 = &.{
        -1, -1, -1, 1, 1.0,  1.0,  1.0,  1,
        1,  -1, -1, 1, 0.71, 1.0,  1.0,  1,
        -1, 1,  -1, 1, 1.0,  0.71, 1.0,  1,
        1,  1,  -1, 1, 0.71, 0.71, 1.0,  1,
        -1, -1, 1,  1, 1.0,  1.0,  0.71, 1,
        1,  -1, 1,  1, 0.71, 1.0,  0.71, 1,
        -1, 1,  1,  1, 1.0,  0.71, 0.71, 1,
        1,  1,  1,  1, 0.71, 0.71, 0.71, 1,
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
    window: cc.app.Window,
    gctx: cc.gfx.Context,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
    uniform_buffer: cc.gfx.Buffer,
    bind_group: cc.gfx.BindGroup,
    render_pipeline: cc.gfx.RenderPipeline,
};

var ex: Example = undefined;

pub fn init() !void {
    ex.game_clock = try cc.app.Timer.start();
    ex.window = try cc.app.Window.init(.{ .width = 800, .height = 600, .title = "cube" });
    ex.gctx = try cc.gfx.Context.init(&ex.window, .{});

    const cube_vertices_bytes = std.mem.sliceAsBytes(cube.vertices);
    ex.vertex_buffer = try ex.gctx.createBuffer(.{
        .size = cube_vertices_bytes.len,
        .usage = .{ .vertex = true },
        .data = cube_vertices_bytes,
    });

    const cube_indices_bytes = std.mem.sliceAsBytes(cube.indices);
    ex.index_buffer = try ex.gctx.createBuffer(.{
        .size = cube_indices_bytes.len,
        .usage = .{ .index = true },
        .data = cube_indices_bytes,
    });

    ex.uniform_buffer = try ex.gctx.createBuffer(.{
        .size = 64,
        .usage = .{ .uniform = true, .copy_dst = true },
    });

    var bind_group_layout = try ex.gctx.createBindGroupLayout(.{
        .entries = &.{.{
            .binding = 0,
            .visibility = .{ .vertex = true },
            .buffer = .{},
        }},
    });
    defer bind_group_layout.destroy();

    ex.bind_group = try ex.gctx.createBindGroup(.{
        .layout = &bind_group_layout,
        .entries = &.{.{
            .binding = 0,
            .resource = .{ .buffer_binding = .{ .buffer = &ex.uniform_buffer } },
        }},
    });

    var pipeline_layout = try ex.gctx.createPipelineLayout(
        .{ .bind_group_layouts = &.{bind_group_layout} },
    );
    defer pipeline_layout.destroy();

    var vert_shader = try ex.gctx.loadShader(res.cube_vert_shader, .{});
    defer vert_shader.destroy();

    var frag_shader = try ex.gctx.loadShader(res.cube_frag_shader, .{});
    defer frag_shader.destroy();

    var render_pipeline_desc = cc.gfx.RenderPipelineDesc{};
    render_pipeline_desc.setPipelineLayout(&pipeline_layout);
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
        // note: zig issue #7607 prevents using an anonymous array here
        .buffers = &[_]cc.gfx.VertexBufferLayout{.{
            .array_stride = cube.array_stride,
            // note: zig issue #7607 prevents using an anonymous array here
            .attributes = &[_]cc.gfx.VertexAttribute{
                .{ .shader_location = 0, .offset = cube.position_offset, .format = .float32x4 },
                .{ .shader_location = 1, .offset = cube.color_offset, .format = .float32x4 },
            },
        }},
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
        // note: zig issue #7607 prevents using an anonymous array here
        .targets = &[_]cc.gfx.ColorTargetState{.{ .format = ex.gctx.swapchain_format }},
    });

    ex.render_pipeline = try ex.gctx.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
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
        @intToFloat(f32, ex.window.getWidth()) / @intToFloat(f32, ex.window.getHeight()),
        1,
        100,
    );
    const mvp_matrix = cc.math.mul(cc.math.mul(model_matrix, view_matrix), proj_matrix);

    try ex.gctx.beginFrame();

    const mvp_matrix_bytes = std.mem.asBytes(&cc.math.transpose(mvp_matrix));
    try ex.gctx.writeBuffer(&ex.uniform_buffer, 0, mvp_matrix_bytes, 0);

    var command_encoder = try ex.gctx.createCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    // note: zig issue #7607 prevents using an anonymous array here
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &ex.gctx.swapchain_view,
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
    try render_pass.drawIndexed(cube.indices.len, 1, 0, 0, 0);
    try render_pass.end();

    try ex.gctx.submit(&.{try command_encoder.finish()});
    try ex.gctx.endFrame();
}

pub fn deinit() !void {
    ex.render_pipeline.destroy();
    ex.bind_group.destroy();
    ex.uniform_buffer.destroy();
    ex.index_buffer.destroy();
    ex.vertex_buffer.destroy();
    ex.gctx.deinit();
    ex.window.deinit();
}
