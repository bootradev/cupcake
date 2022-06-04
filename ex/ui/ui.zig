const cc_gfx = @import("cc_gfx");
const cc_mem = @import("cc_mem");
const cc_ui = @import("cc_ui");
const cc_ui_gfx = @import("cc_ui_gfx");
const cc_ui_res = @import("cc_ui_res");
const cc_wnd = @import("cc_wnd");
const cc_wnd_gfx = @import("cc_wnd_gfx");

const Example = struct {
    ba: cc_mem.BumpAllocator,
    window: cc_wnd.Window,
    gctx: cc_gfx.Context,
    uctx: cc_ui.Context,
    ugctx: cc_ui_gfx.Context,
};

const max_instances = 256;

pub fn init() !Example {
    var ba = try cc_mem.BumpAllocator.init(cc_ui.Context.instance_size * max_instances);
    const window = try cc_wnd.Window.init(.{ .width = 800, .height = 600, .title = "ui" });
    var gctx = try cc_gfx.Context.init(cc_wnd_gfx.getContextDesc(window));
    const uctx = try cc_ui.Context.init(.{
        .allocator = ba.allocator(),
        .max_instances = max_instances,
    });
    const ugctx = try cc_ui_gfx.Context.init(.{
        .device = &gctx.device,
        .format = gctx.swapchain_format,
        .vert_shader_bytes = try cc_ui_res.loadVertShaderBytes(),
        .frag_shader_bytes = try cc_ui_res.loadFragShaderBytes(),
        .instance_size = cc_ui.Context.instance_size,
        .max_instances = max_instances,
    });

    return Example{ .ba = ba, .window = window, .gctx = gctx, .uctx = uctx, .ugctx = ugctx };
}

pub fn loop(ex: *Example) !void {
    try ex.uctx.debugText("Hello, world!", .{});

    const swapchain_view = try ex.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try ex.gctx.device.initCommandEncoder();

    var render_pass_desc = cc_gfx.RenderPassDesc{};
    render_pass_desc.setColorAttachments(&[_]cc_gfx.ColorAttachment{.{
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
