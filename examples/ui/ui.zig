const cc = @import("cupcake");

const Example = struct {
    ba: cc.mem.BumpAllocator,
    window: cc.wnd.Window,
    gctx: cc.gfx.Context,
    uctx: cc.ui.Context,
    ugctx: cc.ui_gfx.Context,
};

const max_instances = 256;

pub fn init() !Example {
    var ba = try cc.mem.BumpAllocator.init(cc.ui.Context.instance_size * max_instances);
    const window = try cc.wnd.Window.init(.{ .width = 800, .height = 600, .title = "ui" });
    var gctx = try cc.gfx.Context.init(cc.wnd_gfx.getContextDesc(window));
    const uctx = try cc.ui.Context.init(.{
        .allocator = ba.allocator(),
        .max_instances = max_instances,
    });
    const ugctx = try cc.ui_gfx.Context.init(.{
        .device = &gctx.device,
        .format = gctx.swapchain_format,
        .vert_shader_bytes = try cc.ui_res.loadVertShaderBytes(),
        .frag_shader_bytes = try cc.ui_res.loadFragShaderBytes(),
        .instance_size = cc.ui.Context.instance_size,
        .max_instances = max_instances,
    });

    return Example{ .ba = ba, .window = window, .gctx = gctx, .uctx = uctx, .ugctx = ugctx };
}

pub fn loop(ex: *Example) !void {
    try ex.uctx.debugText("Hello, world!", .{});

    const swapchain_view = try ex.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try ex.gctx.device.initCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = ex.gctx.clear_color,
        .store_op = .store,
    }});
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try ex.ugctx.render(&render_pass, ex.uctx.getInstanceBytes());
    try render_pass.end();

    try ex.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try ex.gctx.swapchain.present();
}

pub fn deinit(ex: *Example) !void {
    ex.ugctx.deinit();
    ex.uctx.deinit();
    ex.gctx.deinit();
    ex.window.deinit();
    ex.ba.deinit();
}
