const cc = @import("cupcake");
const shaders = @import("shaders");
const std = @import("std");

pub const gfx_cbs = .{
    .adapter_ready_cb = onAdapterReady,
    .device_ready_cb = onDeviceReady,
    .error_cb = onGfxError,
};

const Example = struct {
    status: Status,
    window: cc.app.Window,
    instance: cc.gfx.Instance,
    adapter: cc.gfx.Adapter,
    device: cc.gfx.Device,
    surface: cc.gfx.Surface,
    swapchain: cc.gfx.Swapchain,
    render_pipeline: cc.gfx.RenderPipeline,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

const quad_data = struct {
    const position_offset = 0;
    const uv_offset = 4 * 2;
    const array_stride = 4 * 2 * 2;

    // position (vec4), color (vec4),
    const vertices: []const f32 = &.{
        -1, -1, 0, 0,
        1,  -1, 1, 0,
        -1, 1,  0, 1,
        1,  1,  1, 1,
    };

    const indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };
};

pub fn init() !void {
    example.status = .pending;
    try example.window.init(cc.math.V2u32.make(800, 600), .{});
    try example.instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter, null);
}

fn onAdapterReady(adapter: *cc.gfx.Adapter, _: ?*anyopaque) void {
    try adapter.requestDevice(.{}, &example.device, null);
}

fn onDeviceReady(device: *cc.gfx.Device, _: ?*anyopaque) void {
    const swapchain_format = comptime cc.gfx.Surface.getPreferredFormat();

    example.swapchain = try device.createSwapchain(
        &example.surface,
        example.window.size,
        .{ .format = swapchain_format },
    );

    const quad_vertices_bytes = std.mem.sliceAsBytes(quad_data.vertices);
    example.vertex_buffer = try device.createBuffer(
        quad_vertices_bytes,
        quad_vertices_bytes.len,
        .{ .usage = .{ .vertex = true } },
    );
    const quad_indices_bytes = std.mem.sliceAsBytes(quad_data.indices);
    example.index_buffer = try device.createBuffer(
        quad_indices_bytes,
        quad_indices_bytes.len,
        .{ .usage = .{ .index = true } },
    );

    var vert_shader = try device.createShader(shaders.texture_vert);
    defer vert_shader.destroy();
    device.checkShaderCompile(&vert_shader);

    var frag_shader = try device.createShader(shaders.texture_frag);
    defer frag_shader.destroy();
    device.checkShaderCompile(&frag_shader);

    var pipeline_layout = try device.createPipelineLayout(&.{}, .{});
    defer pipeline_layout.destroy();
    example.render_pipeline = try device.createRenderPipeline(
        &pipeline_layout,
        &vert_shader,
        &frag_shader,
        .{
            .vertex = .{
                .entry_point = "vs_main",
                .buffers = &.{
                    .{
                        .array_stride = quad_data.array_stride,
                        .attributes = &.{
                            .{
                                // position
                                .shader_location = 0,
                                .offset = quad_data.position_offset,
                                .format = .float32x2,
                            },
                            .{
                                // color
                                .shader_location = 1,
                                .offset = quad_data.uv_offset,
                                .format = .float32x2,
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

    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
    var render_pass = command_encoder.beginRenderPass(
        .{
            .color_views = &.{swapchain_view},
        },
        .{
            .color_attachments = &.{.{ .load_op = .clear, .store_op = .store }},
        },
    );

    render_pass.setPipeline(&example.render_pipeline);
    render_pass.setVertexBuffer(0, &example.vertex_buffer, 0, cc.gfx.whole_size);
    render_pass.setIndexBuffer(&example.index_buffer, .uint16, 0, cc.gfx.whole_size);
    render_pass.drawIndexed(quad_data.indices.len, 1, 0, 0, 0);

    render_pass.end();

    const command_buffer = command_encoder.finish(.{});
    queue.submit(&.{command_buffer});

    example.swapchain.present();
}

pub fn deinit() !void {
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
