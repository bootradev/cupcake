const cc = @import("cupcake");
const res = @import("res");
const std = @import("std");

const Example = struct {
    window: cc.app.Window,
    file_data: []u8,
    instance: cc.gfx.Instance,
    adapter: cc.gfx.Adapter,
    device: cc.gfx.Device,
    surface: cc.gfx.Surface,
    swapchain: cc.gfx.Swapchain,
    render_pipeline: cc.gfx.RenderPipeline,
    vertex_buffer: cc.gfx.Buffer,
    index_buffer: cc.gfx.Buffer,
    update_ready: anyerror!bool,
    ba: cc.mem.BumpAllocator,
};

var example: Example = undefined;

const quad_data = struct {
    const position_offset = 0;
    const uv_offset = 4 * 2;
    const array_stride = 4 * 2 * 2;

    // position (vec2), uv (vec2)
    const vertices: []const f32 = &.{
        -1, -1, 0, 0,
        1,  -1, 1, 0,
        -1, 1,  0, 1,
        1,  1,  1, 1,
    };

    const indices: []const u16 = &.{ 0, 1, 2, 2, 1, 3 };
};

pub fn init() !void {
    example.update_ready = false;
    try example.window.init(cc.math.V2u32.make(800, 600), .{});
    try example.instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter, null);
    //example.ba = try cc.mem.BumpAllocator.init(1024);
    //try cc.res.requestFile(example.ba.allocator(), .{ .name = "test", .size = 1024 }, null);
}

pub fn ccResFileReady(_: []u8, _: ?*anyopaque) void {}

pub fn ccResFileError(err: anyerror, _: []u8, _: ?*anyopaque) void {
    example.update_ready = err;
}

pub fn ccGfxAdapterReady(_: *cc.gfx.Adapter, _: ?*anyopaque) void {
    try example.adapter.requestDevice(.{}, &example.device, null);
}

pub fn ccGfxDeviceReady(_: *cc.gfx.Device, _: ?*anyopaque) void {
    const swapchain_format = comptime cc.gfx.Surface.getPreferredFormat();

    example.swapchain = try example.device.createSwapchain(
        &example.surface,
        example.window.size,
        .{ .format = swapchain_format },
    );

    const quad_vertices_bytes = std.mem.sliceAsBytes(quad_data.vertices);
    example.vertex_buffer = try example.device.createBuffer(
        quad_vertices_bytes,
        quad_vertices_bytes.len,
        .{ .usage = .{ .vertex = true } },
    );
    const quad_indices_bytes = std.mem.sliceAsBytes(quad_data.indices);
    example.index_buffer = try example.device.createBuffer(
        quad_indices_bytes,
        quad_indices_bytes.len,
        .{ .usage = .{ .index = true } },
    );

    var vert_shader = try example.device.createShader(res.@"texture_vert.wgsl");
    defer vert_shader.destroy();
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.createShader(res.@"texture_frag.wgsl");
    defer frag_shader.destroy();
    example.device.checkShaderCompile(&frag_shader);

    var pipeline_layout = try example.device.createPipelineLayout(&.{}, .{});
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

    example.update_ready = true;
}

pub fn ccGfxError(err: anyerror) void {
    example.update_ready = err;
}

pub fn update() !void {
    if ((try example.update_ready) == false) {
        return;
    }

    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
    var render_pass = command_encoder.beginRenderPass(
        .{ .color_views = &.{swapchain_view} },
        .{ .color_attachments = &.{.{ .load_op = .clear, .store_op = .store }} },
    );
    render_pass.setPipeline(&example.render_pipeline);
    render_pass.setVertexBuffer(0, &example.vertex_buffer, 0, cc.gfx.whole_size);
    render_pass.setIndexBuffer(&example.index_buffer, .uint16, 0, cc.gfx.whole_size);
    render_pass.drawIndexed(quad_data.indices.len, 1, 0, 0, 0);
    render_pass.end();

    var queue = example.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});

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
