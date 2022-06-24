const cc_bake = @import("cc_bake");
const cc_gfx = @import("cc_gfx");
const cc_res = @import("cc_res");
const cc_wnd = @import("cc_wnd");
const cc_wnd_gfx = @import("cc_wnd_gfx");

const Demo = struct {
    window: cc_wnd.Window,
    gctx: cc_gfx.Context,
    render_pipeline: cc_gfx.RenderPipeline,
};

pub fn init() !Demo {
    var window = try cc_wnd.Window.init(.{ .width = 800, .height = 600, .title = "tri" });
    var gctx = try cc_gfx.Context.init(cc_wnd_gfx.getContextDesc(window));

    const vert_shader_desc = try cc_res.load(cc_bake.tri_vert_shader, .{});
    var vert_shader = try gctx.device.initShader(vert_shader_desc);
    defer gctx.device.deinitShader(&vert_shader);

    const frag_shader_desc = try cc_res.load(cc_bake.tri_frag_shader, .{});
    var frag_shader = try gctx.device.initShader(frag_shader_desc);
    defer gctx.device.deinitShader(&frag_shader);

    var render_pipeline_desc = cc_gfx.RenderPipelineDesc{};
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
    });
    render_pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // todo: zig #7607
        .targets = &[_]cc_gfx.ColorTargetState{.{ .format = gctx.swapchain_format }},
    });
    const render_pipeline = try gctx.device.initRenderPipeline(render_pipeline_desc);

    return Demo{ .window = window, .gctx = gctx, .render_pipeline = render_pipeline };
}

pub fn loop(demo: *Demo) !void {
    if (!demo.window.isVisible()) {
        return;
    }

    const swapchain_view = try demo.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try demo.gctx.device.initCommandEncoder();

    var render_pass_desc = cc_gfx.RenderPassDesc{};
    // todo: zig #7607
    render_pass_desc.setColorAttachments(&[_]cc_gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = demo.gctx.clear_color,
        .store_op = .store,
    }});

    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try render_pass.setPipeline(&demo.render_pipeline);
    try render_pass.draw(3, 1, 0, 0);
    try render_pass.end();

    try demo.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try demo.gctx.swapchain.present();
}

pub fn deinit(demo: *Demo) !void {
    demo.gctx.device.deinitRenderPipeline(&demo.render_pipeline);
    demo.gctx.deinit();
    demo.window.deinit();
}
