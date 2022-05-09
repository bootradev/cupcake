const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    gctx: cc.gfx.Context,
    uctx: cc.ui.Context,
};

var ex: Example = undefined;

pub fn init() !void {
    ex.window = try cc.app.Window.init(.{ .width = 800, .height = 600, .title = "ui" });
    ex.gctx = try cc.gfx.Context.init(.{ .window = &ex.window });
    ex.uctx = try cc.ui.Context.init(.{
        .window = &ex.window,
        .device = &ex.gctx.device,
        .format = ex.gctx.swapchain_format,
    });
}

pub fn loop() !void {
    try ex.uctx.debugText("Hello, world!", .{});

    try ex.gctx.beginFrame();
    var command_encoder = try ex.gctx.createCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &ex.gctx.swapchain_view,
        .load_op = .clear,
        .clear_value = ex.gctx.clear_color,
        .store_op = .store,
    }});
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try ex.uctx.render(&render_pass);
    try render_pass.end();

    try ex.gctx.submit(&.{try command_encoder.finish()});
    try ex.gctx.endFrame();
}

pub fn deinit() !void {
    ex.uctx.deinit();
    ex.gctx.deinit();
    ex.window.deinit();
}
