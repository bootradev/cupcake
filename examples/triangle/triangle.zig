const cc = @import("cupcake");
const res = @import("res");

const Example = struct {
    window: cc.app.Window,
    instance: cc.gfx.Instance,
    adapter: cc.gfx.Adapter,
    device: cc.gfx.Device,
    surface: cc.gfx.Surface,
    swapchain: cc.gfx.Swapchain,
    render_pipeline: cc.gfx.RenderPipeline,
};

var example: Example = undefined;

pub fn init() !void {
    example.window = try cc.app.Window.init(
        cc.math.V2u32.make(800, 600),
        .{ .name = "cupcake triangle example" },
    );
    example.instance = try cc.gfx.Instance.init();
    example.surface = try example.instance.createSurface(
        &example.window,
        cc.gfx.SurfaceDesc.default(),
    );
    example.adapter = try example.instance.requestAdapter(
        &example.surface,
        cc.gfx.AdapterDesc.default(),
    );
    example.device = try example.adapter.requestDevice(cc.gfx.DeviceDesc.default());

    const swapchain_format = example.surface.getPreferredFormat(example.adapter);
    const swapchain_desc = cc.gfx.SwapchainDesc.init()
        .size(.{ .width = example.window.size.x, .height = example.window.size.y })
        .format(swapchain_format);
    defer swapchain_desc.deinit();
    example.swapchain = try example.device.createSwapchain(&example.surface, swapchain_desc);

    const vert_shader_res = try cc.app.load(res.triangle_vert_shader, .{});
    var vert_shader = try example.device.createShader(vert_shader_res);
    defer vert_shader.destroy();

    const frag_shader_res = try cc.app.load(res.triangle_frag_shader, .{});
    var frag_shader = try example.device.createShader(frag_shader_res);
    defer frag_shader.destroy();

    const render_pipeline_desc = cc.gfx.RenderPipelineDesc.init()
        .vertex()
        .module(vert_shader)
        .entryPoint("vs_main")
        .end()
        .fragment()
        .module(frag_shader)
        .entryPoint("fs_main")
        .targets().target().format(swapchain_format).end().end()
        .end();
    defer render_pipeline_desc.deinit();
    example.render_pipeline = try example.device.createRenderPipeline(render_pipeline_desc);
}

pub fn update() !void {
    var swapchain_view = try example.swapchain.getCurrentTextureView();
    defer swapchain_view.destroy();

    var command_encoder = example.device.createCommandEncoder();
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
    render_pass.setPipeline(&example.render_pipeline);
    render_pass.draw(3, 1, 0, 0);
    render_pass.end();

    var queue = example.device.getQueue();
    queue.submit(&.{command_encoder.finish(.{})});
    example.swapchain.present();
}

pub fn deinit() !void {
    example.render_pipeline.destroy();
    example.swapchain.destroy();
    example.device.destroy();
    example.adapter.destroy();
    example.surface.destroy();
    example.instance.deinit();
    example.window.deinit();
}
