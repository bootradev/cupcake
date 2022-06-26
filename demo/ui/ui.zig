const cc_gfx = @import("cc_gfx");
const cc_mem = @import("cc_mem");
const cc_ui = @import("cc_ui");
const cc_ui_gfx = @import("cc_ui_gfx");
const cc_ui_res = @import("cc_ui_res");
const cc_wnd = @import("cc_wnd");
const cc_wnd_gfx = @import("cc_wnd_gfx");

const Demo = struct {
    ba: cc_mem.BumpAllocator,
    window: cc_wnd.Window,
    gctx: cc_gfx.Context,
    uictx: cc_ui.Context(cc_ui_gfx),
};

const max_instances = 256;

pub fn init() !Demo {
    var ba = try cc_mem.BumpAllocator.init(256 * 1024);
    const allocator = ba.allocator();
    const window = try cc_wnd.Window.init(.{
        .width = 800,
        .height = 600,
        .title = "ui",
    });
    var gctx = try cc_gfx.Context.init(cc_wnd_gfx.getContextDesc(window));
    const uictx = try cc_ui.Context(cc_ui_gfx).init(
        .{
            .device = &gctx.device,
            .format = gctx.swapchain_format,
            .max_instances = max_instances,
            .allocator = allocator,
        },
        cc_ui_res,
    );

    return Demo{ .ba = ba, .window = window, .gctx = gctx, .uictx = uictx };
}

pub fn loop(demo: *Demo) !void {
    if (!demo.window.isVisible()) {
        return;
    }

    demo.uictx.reset();
    demo.uictx.setViewport(
        @intToFloat(f32, demo.window.getWidth()),
        @intToFloat(f32, demo.window.getHeight()),
    );
    try demo.uictx.debugText(.{}, "Hello, world!", .{});

    const swapchain_view = try demo.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try demo.gctx.device.initCommandEncoder();

    var render_pass_desc = cc_gfx.RenderPassDesc{};
    render_pass_desc.setColorAttachments(&[_]cc_gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = demo.gctx.clear_color,
        .store_op = .store,
    }});
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try demo.uictx.render(&render_pass);
    try render_pass.end();

    try demo.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try demo.gctx.swapchain.present();
}

pub fn deinit(demo: *Demo) !void {
    demo.uictx.deinit();
    demo.gctx.deinit();
    demo.window.deinit();
    demo.ba.deinit();
}
