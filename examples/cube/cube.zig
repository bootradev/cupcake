const app = bt.app;
const bt = @import("bootra");
const cube_data = @import("cube_data.zig");
const gfx = bt.gfx;
const math = bt.math;
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
    uniform_buffer: gfx.Buffer,
    depth_texture: gfx.Texture,
    depth_texture_view: gfx.TextureView,
    uniform_bind_group: gfx.BindGroup,
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

const model_matrix = math.M44f32.identity;
const view_matrix = math.M44f32.makeView(
    math.V3f32.make(0, 0, -4),
    math.V3f32.forward,
    math.V3f32.up,
);
const proj_matrix = math.M44f32.makePerspective(2.0 * std.math.pi / 5.0, 800.0 / 600.0, 1, 100);
const mvp_matrix = model_matrix.mul(view_matrix.mul(proj_matrix));

pub fn init() !void {
    example.status = .pending;
    try example.window.init("cube", math.V2u32.make(800, 600));
    try example.instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter);
}

fn onAdapterReady() void {
    try example.adapter.requestDevice(.{}, &example.device);
}

fn onDeviceReady() void {
    const cube_vertices_bytes = std.mem.sliceAsBytes(cube_data.vertices);
    example.vertex_buffer = try example.device.createBuffer(
        cube_vertices_bytes,
        cube_vertices_bytes.len,
        .{ .usage = .{ .vertex = true } },
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
    defer example.device.destroyBindGroupLayout(&uniform_layout);

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

    const swapchain_format = comptime gfx.Surface.getPreferredFormat();

    example.swapchain = try example.device.createSwapchain(
        &example.surface,
        example.window.size,
        .{ .format = swapchain_format },
    );
    var vert_shader = try example.device.createShader(shaders.cube_vert);
    defer example.device.destroyShader(&vert_shader);
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.createShader(shaders.cube_frag);
    defer example.device.destroyShader(&frag_shader);
    example.device.checkShaderCompile(&frag_shader);

    var pipeline_layout = try example.device.createPipelineLayout(&.{uniform_layout}, .{});
    defer example.device.destroyPipelineLayout(&pipeline_layout);
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
                .cull_mode = .none,
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

    queue.writeBuffer(&example.uniform_buffer, 0, mvp_matrix.asBytes(), 0);

    const swapchain_view = try example.swapchain.getCurrentTextureView();
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
    render_pass.draw(cube_data.vertex_count, 1, 0, 0);

    render_pass.end();

    const command_buffer = command_encoder.finish(.{});
    queue.submit(&.{command_buffer});

    example.swapchain.present();
}
