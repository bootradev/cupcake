const cc = @import("cupcake");
const shaders = @import("shaders");

const Example = struct {
    window: cc.app.Window,
    instance: cc.gfx.Instance,
    adapter: cc.gfx.Adapter,
    device: cc.gfx.Device,
    surface: cc.gfx.Surface,
    swapchain: cc.gfx.Swapchain,
    render_pipeline: cc.gfx.RenderPipeline,
    update_ready: anyerror!bool,
};

var example: Example = undefined;

pub fn init() !void {
    example.update_ready = false;
    try example.window.init(cc.math.V2u32.make(800, 600), .{});
    try example.instance.init();
    example.surface = try example.instance.createSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter, null);
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

    var vert_shader = try example.device.createShader(shaders.triangle_vert);
    defer vert_shader.destroy();
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.createShader(shaders.triangle_frag);
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
                .buffers = &.{},
            },
            .fragment = .{
                .entry_point = "fs_main",
                .targets = &.{.{ .format = swapchain_format }},
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
    render_pass.draw(3, 1, 0, 0);
    render_pass.end();

    var queue = example.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});
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
