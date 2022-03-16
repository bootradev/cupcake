const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    ctx: cc.gfx.Context,
    render_pipeline: cc.gfx.RenderPipeline,
};

var example: Example = undefined;

pub fn init() !void {
    example.window = try cc.app.Window.init(cc.math.V2u32.make(800, 600), .{});
    example.ctx = try cc.gfx.Context.init(
        example.window,
        cc.gfx.AdapterDesc.default(),
        cc.gfx.DeviceDesc.default(),
    );

    const vert_shader_res = try cc.app.load(res.triangle_vert_shader, .{});
    var vert_shader = try example.ctx.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.app.load(res.triangle_frag_shader, .{});
    var frag_shader = try example.ctx.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    const render_pipeline_desc = cc.gfx.RenderPipelineDesc.init()
        .vertex()
        .module(vert_shader)
        .entryPoint("vs_main")
        .end()
        .fragment()
        .module(frag_shader)
        .entryPoint("fs_main")
        .targets().target().format(example.ctx.swapchain_format).end().end()
        .end();
    defer render_pipeline_desc.deinit();
    example.render_pipeline = try example.ctx.device.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
    var swapchain_view = try example.ctx.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.ctx.device.createCommandEncoder();
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
    render_pass.setPipeline(example.render_pipeline);
    render_pass.draw(3, 1, 0, 0);
    render_pass.end();

    var queue = example.ctx.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});
    example.ctx.swapchain.present();
}

pub fn deinit() !void {
    example.render_pipeline.destroy();
    example.ctx.deinit();
    example.window.deinit();
}
