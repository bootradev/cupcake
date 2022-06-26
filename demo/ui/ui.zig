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
    uctx: cc_ui.Context,
    ugctx: cc_ui_gfx.Context,
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
    const uctx = try cc_ui.Context.init(.{
        .allocator = allocator,
        .max_instances = max_instances,
    });
    const ugctx = try cc_ui_gfx.Context.init(.{
        .device = &gctx.device,
        .format = gctx.swapchain_format,
        .vert_shader_desc = try cc_ui_res.loadVertShaderDesc(),
        .frag_shader_desc = try cc_ui_res.loadFragShaderDesc(),
        .font_atlas_desc = try cc_ui_res.loadFontAtlasTextureDesc(allocator),
        .max_instances = max_instances,
    });

    return Demo{
        .ba = ba,
        .window = window,
        .gctx = gctx,
        .uctx = uctx,
        .ugctx = ugctx,
    };
}

pub fn loop(demo: *Demo) !void {
    if (!demo.window.isVisible()) {
        return;
    }

    demo.uctx.clear();
    demo.uctx.setViewport(.{
        .width = @intToFloat(f32, demo.window.getWidth()),
        .height = @intToFloat(f32, demo.window.getHeight()),
    });
    try demo.uctx.debugText(.{}, "Hello, world!", .{});

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
    try demo.ugctx.render(
        &render_pass,
        demo.uctx.getInstanceCount(),
        demo.uctx.getInstanceBytes(),
        demo.uctx.getUniformBytes(),
    );
    try render_pass.end();

    try demo.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try demo.gctx.swapchain.present();
}

pub fn deinit(demo: *Demo) !void {
    demo.ugctx.deinit();
    demo.uctx.deinit();
    demo.gctx.deinit();
    demo.window.deinit();
    demo.ba.deinit();
}
