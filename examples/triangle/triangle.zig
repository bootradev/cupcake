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
    ex.gctx = try cc.gfx.Context.init(&ex.window, .{});

    var vert_shader = try ex.gctx.loadShader(res.triangle_vert_shader, .{});
    defer vert_shader.destroy();

    var frag_shader = try ex.gctx.loadShader(res.triangle_frag_shader, .{});
    defer frag_shader.destroy();

    var render_pipeline_desc = cc.gfx.RenderPipelineDesc{};
    render_pipeline_desc.setVertexState(.{
        .module = &vert_shader,
        .entry_point = "vs_main",
    });
    render_pipeline_desc.setFragmentState(.{
        .module = &frag_shader,
        .entry_point = "fs_main",
        // note: zig issue #7607 prevents using an anonymous array here
        .targets = &[_]cc.gfx.ColorTargetState{.{ .format = ex.gctx.swapchain_format }},
    });

    ex.render_pipeline = try ex.gctx.createRenderPipeline(render_pipeline_desc);
}

pub fn loop() !void {
    try ex.gctx.beginFrame();
    var command_encoder = try ex.gctx.createCommandEncoder();

    var render_pass_desc = cc.gfx.RenderPassDesc{};
    // note: zig issue #7607 prevents using an anonymous array here
    render_pass_desc.setColorAttachments(&[_]cc.gfx.ColorAttachment{.{
        .view = &ex.gctx.swapchain_view,
        .load_op = .clear,
        .clear_value = ex.gctx.clear_color,
        .store_op = .store,
    }});

    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    try render_pass.setPipeline(&ex.render_pipeline);
    try render_pass.draw(3, 1, 0, 0);
    try render_pass.end();

    try ex.gctx.submit(&.{try command_encoder.finish()});
    try ex.gctx.endFrame();
}

pub fn deinit() !void {
    ex.render_pipeline.destroy();
    ex.gctx.deinit();
    ex.window.deinit();
}
