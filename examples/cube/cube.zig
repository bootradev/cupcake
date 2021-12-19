const app = cc.app;
const cc = @import("cupcake");
const gfx = cc.gfx;
const math = cc.math;
const shaders = @import("shaders");
const std = @import("std");

pub const gfx_cbs = .{
    .adapter_ready_cb = onAdapterReady,
    .device_ready_cb = onDeviceReady,
    .error_cb = onGfxError,
};

const Example = struct {
    status: Status,
    window: app.Window,
    instance: gfx.Instance,
    adapter: gfx.Adapter,
    device: gfx.Device,
    surface: gfx.Surface,
    swapchain: gfx.Swapchain,
    render_pipeline: gfx.RenderPipeline,
    vertex_buffer: gfx.Buffer,
    index_buffer: gfx.Buffer,
    uniform_buffer: gfx.Buffer,
    depth_texture: gfx.Texture,
    depth_texture_view: gfx.TextureView,
    uniform_bind_group: gfx.BindGroup,
    game_clock: app.Timer,
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

const cube_data = struct {
    const position_offset = 0;
    const color_offset = 4 * 4;
    const array_stride = 4 * 4 * 2;

    // position (vec4), color (vec4),
    const vertices: []const f32 = &.{
        -1, -1, -1, 1, 1, 0, 0, 1,
        1,  -1, -1, 1, 0, 0, 1, 1,
        -1, 1,  -1, 1, 0, 1, 0, 1,
        1,  1,  -1, 1, 1, 1, 1, 1,
        -1, -1, 1,  1, 1, 0, 0, 1,
        1,  -1, 1,  1, 0, 0, 1, 1,
        -1, 1,  1,  1, 0, 1, 0, 1,
        1,  1,  1,  1, 1, 1, 1, 1,
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

pub fn init() !void {
    example.status = .pending;
    example.game_clock = try app.Timer.start();
    try example.window.init("cube", math.V2u32.make(800, 600));
    try example.instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter);
}

fn onAdapterReady() void {
    try example.adapter.requestDevice(.{}, &example.device);
}

fn onDeviceReady() void {
    const swapchain_format = comptime gfx.Surface.getPreferredFormat();

    example.swapchain = try example.device.createSwapchain(
        &example.surface,
        example.window.size,
        .{ .format = swapchain_format },
    );

    const cube_vertices_bytes = std.mem.sliceAsBytes(cube_data.vertices);
    example.vertex_buffer = try example.device.createBuffer(
        cube_vertices_bytes,
        cube_vertices_bytes.len,
        .{ .usage = .{ .vertex = true } },
    );
    const cube_indices_bytes = std.mem.sliceAsBytes(cube_data.indices);
    example.index_buffer = try example.device.createBuffer(
        cube_indices_bytes,
        cube_indices_bytes.len,
        .{ .usage = .{ .index = true } },
    );
    example.depth_texture = try example.device.createTexture(
        .{ .width = example.window.size.x, .height = example.window.size.y },
        .{ .format = .depth24plus, .usage = .{ .render_attachment = true } },
    );
    example.depth_texture_view = example.depth_texture.createView();
    example.uniform_buffer = try example.device.createBuffer(
        null,
        64, // mat4x4 float = 4x4x4 bytes
        .{ .usage = .{ .uniform = true, .copy_dst = true } },
    );

    var uniform_layout = try example.device.createBindGroupLayout(.{
        .entries = &.{
            .{
                .binding = 0,
                .visibility = .{ .vertex = true },
                .layout = .{ .buffer = .{} },
            },
        },
    });
    defer uniform_layout.destroy();

    example.uniform_bind_group = try example.device.createBindGroup(
        &uniform_layout,
        &.{
            .{ .buffer = .{ .resource = &example.uniform_buffer } },
        },
        .{
            .entries = &.{
                .{ .binding = 0, .resource_type = .buffer },
            },
        },
    );

    var vert_shader = try example.device.createShader(shaders.cube_vert);
    defer vert_shader.destroy();
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.createShader(shaders.cube_frag);
    defer frag_shader.destroy();
    example.device.checkShaderCompile(&frag_shader);

    var pipeline_layout = try example.device.createPipelineLayout(&.{uniform_layout}, .{});
    defer pipeline_layout.destroy();
    example.render_pipeline = try example.device.createRenderPipeline(
        &pipeline_layout,
        &vert_shader,
        &frag_shader,
        .{
            .vertex = .{
                .entry_point = "vs_main",
                .buffers = &.{
                    .{
                        .array_stride = cube_data.array_stride,
                        .attributes = &.{
                            .{
                                // position
                                .shader_location = 0,
                                .offset = cube_data.position_offset,
                                .format = .float32x4,
                            },
                            .{
                                // color
                                .shader_location = 1,
                                .offset = cube_data.color_offset,
                                .format = .float32x4,
                            },
                        },
                    },
                },
            },
            .fragment = .{
                .entry_point = "fs_main",
                .targets = &.{.{ .format = swapchain_format }},
            },
            .primitive = .{
                .cull_mode = .back,
            },
            .depth_stencil = .{
                .depth_write_enabled = true,
                .depth_compare = .less,
                .format = .depth24plus,
            },
        },
    );

    example.status = .ok;
}

fn onGfxError(err: anyerror) void {
    example.status = Status{ .fail = err };
}

pub fn update() !void {
    // todo: see if this is a compiler error - shouldn't need to copy status here
    const status = example.status;
    switch (status) {
        .pending => return,
        .fail => |err| return err,
        .ok => {},
    }

    var queue = example.device.getQueue();

    const time = app.readSeconds(example.game_clock);
    const model_matrix = math.M44f32.makeAngleAxis(
        1.0,
        math.V3f32.make(std.math.sin(time), std.math.cos(time), 0.0),
    );
    const view_matrix = math.M44f32.makeView(
        math.V3f32.make(0, 0, -4),
        math.V3f32.forward,
        math.V3f32.up,
    );
    const proj_matrix = math.M44f32.makePerspective(
        2.0 * std.math.pi / 5.0,
        @intToFloat(f32, example.window.size.x) / @intToFloat(f32, example.window.size.y),
        1,
        100,
    );
    const mvp_matrix = model_matrix.mul(view_matrix.mul(proj_matrix));

    queue.writeBuffer(&example.uniform_buffer, 0, mvp_matrix.asBytes(), 0);

    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
    var render_pass = command_encoder.beginRenderPass(
        .{
            .color_views = &.{swapchain_view},
            .depth_stencil_view = &example.depth_texture_view,
        },
        .{
            .color_attachments = &.{.{ .load_op = .clear, .store_op = .store }},
            .depth_stencil_attachment = .{
                .depth_load_op = .clear,
                .depth_store_op = .store,
                .stencil_load_op = .clear,
                .stencil_store_op = .store,
            },
        },
    );

    render_pass.setPipeline(&example.render_pipeline);
    render_pass.setBindGroup(0, &example.uniform_bind_group, null);
    render_pass.setVertexBuffer(0, &example.vertex_buffer, 0, gfx.whole_size);
    render_pass.setIndexBuffer(&example.index_buffer, .uint16, 0, gfx.whole_size);
    render_pass.drawIndexed(cube_data.indices.len, 1, 0, 0, 0);

    render_pass.end();

    const command_buffer = command_encoder.finish(.{});
    queue.submit(&.{command_buffer});

    example.swapchain.present();
}

pub fn deinit() !void {
    example.uniform_bind_group.destroy();
    example.depth_texture_view.destroy();
    example.depth_texture.destroy();
    example.uniform_buffer.destroy();
    example.index_buffer.destroy();
    example.vertex_buffer.destroy();
    example.render_pipeline.destroy();
    example.swapchain.destroy();
    example.device.destroy();
    example.adapter.destroy();
    example.surface.destroy();
    example.instance.deinit();
    example.window.deinit();
}
