const cc = @import("cupcake");
const shaders = @import("shaders");

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
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

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

    var vert_shader = try device.createShader(shaders.triangle_vert);
    defer vert_shader.destroy();
    device.checkShaderCompile(&vert_shader);

    var frag_shader = try device.createShader(shaders.triangle_frag);
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
                .buffers = &.{},
            },
            .fragment = .{
                .entry_point = "fs_main",
                .targets = &.{.{ .format = swapchain_format }},
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

    const swapchain_view = try example.swapchain.getCurrentTextureView();
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
    render_pass.draw(3, 1, 0, 0);

    render_pass.end();

    const command_buffer = command_encoder.finish(.{});
    var queue = example.device.getQueue();
    queue.submit(&.{command_buffer});
    example.swapchain.present();
}

pub fn deinit() !void {
    example.render_pipeline.destroy();
    example.swapchain.destroy();
    example.device.destroy();
    example.adapter.destroy();
    example.surface.destroy();
    example.instance.deinit();
    example.window.deinit();
}
