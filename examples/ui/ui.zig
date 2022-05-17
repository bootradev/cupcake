const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    gctx: cc.gfx.Context,
    uctx: cc.ui.Context,
};

pub fn init() !Example {
    var window = try cc.app.Window.init(.{ .width = 800, .height = 600, .title = "ui" });
    var gctx = try cc.gfx.Context.init(.{ .window = &window });
    const uctx = try cc.ui.Context.init(.{
        .window = &window,
        .device = &gctx.device,
        .format = gctx.swapchain_format,
    });

    return Example{
        .window = window,
        .gctx = gctx,
        .uctx = uctx,
    };
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
    try ex.uctx.render(&render_pass);
    try render_pass.end();

    try ex.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try ex.gctx.swapchain.present();
}

pub fn deinit(ex: *Example) !void {
    ex.uctx.deinit();
    ex.gctx.deinit();
    ex.window.deinit();
}
