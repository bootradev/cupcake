const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    gctx: cc.gfx.Context,
    render_pipeline: cc.gfx.RenderPipeline,
};

var ex: Example = undefined;

pub fn init() !void {
    ex.window = try cc.app.Window.init(.{ .width = 800, .height = 600, .title = "triangle" });
    ex.gctx = try cc.gfx.Context.init(.{ .window = &ex.window });

    var vert_shader = try ex.gctx.device.loadShader(res.triangle_vert_shader, .{});
    defer ex.gctx.device.deinitShader(&vert_shader);

    var frag_shader = try ex.gctx.device.loadShader(res.triangle_frag_shader, .{});
    defer ex.gctx.device.deinitShader(&frag_shader);

    var render_pipeline_desc = cc.gfx.RenderPipelineDesc{};
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
    });
    render_pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // todo: zig #7607
        .targets = &[_]cc.gfx.ColorTargetState{.{ .format = ex.gctx.swapchain_format }},
    });
    ex.render_pipeline = try ex.gctx.device.initRenderPipeline(render_pipeline_desc);
}

pub fn loop() !void {
    const swapchain_view = try ex.gctx.swapchain.getCurrentTextureView();
    var command_encoder = try ex.gctx.device.initCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    // todo: zig #7607
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &swapchain_view,
        .load_op = .clear,
        .clear_value = ex.gctx.clear_color,
        .store_op = .store,
    }});

    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try render_pass.setPipeline(&ex.render_pipeline);
    try render_pass.draw(3, 1, 0, 0);
    try render_pass.end();

    try ex.gctx.device.getQueue().submit(&.{try command_encoder.finish()});
    try ex.gctx.swapchain.present();
}

pub fn deinit() !void {
    ex.gctx.device.deinitRenderPipeline(&ex.render_pipeline);
    ex.gctx.deinit();
    ex.window.deinit();
}
