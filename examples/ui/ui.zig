const cc = @import("cupcake");

const Example = struct {
    window: cc.wnd.Window,
    gctx: cc.gfx.Context,
    uctx: cc.ui.Context(cc.ui_gfx, cc.ui_res, .{}),
};

pub fn init() !Example {
    const window = try cc.wnd.Window.init(.{ .width = 800, .height = 600, .title = "ui" });
    var gctx = try cc.gfx.Context.init(cc.wnd_gfx.getContextDesc(window));
    const uctx = try cc.ui.Context(cc.ui_gfx, cc.ui_res, .{}).init(.{
        .gfx_desc = .{ .device = &gctx.device, .format = gctx.swapchain_format },
        .res_desc = .{},
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
