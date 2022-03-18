const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    gfx_ctx: cc.gfx.Context,
    render_pipeline: cc.gfx.RenderPipeline,
};

var ex: Example = undefined;

pub fn init() !void {
    ex.window = try cc.app.Window.init(cc.math.V2u32.make(800, 600), .{});
    ex.gfx_ctx = try cc.gfx.Context.init(
        &ex.window,
        cc.gfx.AdapterDesc.default(),
        cc.gfx.DeviceDesc.default(),
    );

    const vert_shader_res = try cc.app.load(res.triangle_vert_shader, .{});
    var vert_shader = try ex.gfx_ctx.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.app.load(res.triangle_frag_shader, .{});
    var frag_shader = try ex.gfx_ctx.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    const render_pipeline_desc = cc.gfx.RenderPipelineDesc.init()
        .vertex()
        .module(vert_shader)
        .entryPoint("vs_main")
        .end()
        .fragment()
        .module(frag_shader)
        .entryPoint("fs_main")
        .targets().target().format(ex.gfx_ctx.swapchain_format).end().end()
        .end();
    defer render_pipeline_desc.deinit();
    ex.render_pipeline = try ex.gfx_ctx.device.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
    var swapchain_view = try ex.gfx_ctx.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = ex.gfx_ctx.device.createCommandEncoder();
    const render_pass_desc = cc.gfx.RenderPassDesc.init()
        .colorAttachments()
        .colorAttachment()
        .view(swapchain_view)
        .loadOp(.clear)
        .clearValue(cc.gfx.default_clear_color)
        .storeOp(.store)
        .end()
        .end();
    defer render_pass_desc.deinit();
    var render_pass = try command_encoder.beginRenderPass(render_pass_desc);
    render_pass.setPipeline(ex.render_pipeline);
    render_pass.draw(3, 1, 0, 0);
    render_pass.end();

    var queue = ex.gfx_ctx.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});
    ex.gfx_ctx.swapchain.present();
}

pub fn deinit() !void {
    ex.render_pipeline.destroy();
    ex.gfx_ctx.deinit();
    ex.window.deinit();
}
