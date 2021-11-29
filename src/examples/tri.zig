const app = bt.app;
const bt = @import("bootra");
const cfg = @import("cfg");
const gfx = bt.gfx.Api(onAdapterReady, onDeviceReady, onGfxError);
const math = bt.math;
const shaders = @import("shaders.zig");

const Example = struct {
    status: Status,
    window: app.Window,
    instance: gfx.Instance,
    adapter: gfx.Adapter,
    device: gfx.Device,
    surface: gfx.Surface,
    swapchain: gfx.Swapchain,
    render_pipeline: gfx.RenderPipeline,
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

pub fn init() !void {
    example.status = .pending;
    try example.window.init("tri", math.V2u32.init(800, 600));
    try example.instance.init();
    example.surface = try example.instance.initSurface(&example.window, .{});
    try example.instance.requestAdapter(&example.surface, .{}, &example.adapter);
}

fn onAdapterReady() void {
    try example.adapter.requestDevice(
        .{},
        &example.device,
    );
}

fn onDeviceReady() void {
    const swapchain_format = comptime gfx.Surface.getPreferredFormat();

    example.swapchain = try example.device.initSwapchain(
        &example.surface,
        example.window.size,
        .{
            .format = swapchain_format,
        },
    );

    var vert_shader = try example.device.initShader(shaders.tri_vert);
    defer example.device.deinitShader(&vert_shader);
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.initShader(shaders.tri_frag);
    defer example.device.deinitShader(&frag_shader);
    example.device.checkShaderCompile(&frag_shader);

    const pipeline_layout = try example.device.initPipelineLayout(&[_]gfx.BindGroupLayout{}, .{});
    example.render_pipeline = try example.device.initRenderPipeline(
        &pipeline_layout,
        &vert_shader,
        &frag_shader,
        .{
            .vertex = .{
                .entry_point = "vertex_main",
                .buffers = &[_]gfx.VertexBufferLayout{
                    .{
                        .array_stride = 2 * 4 * 4,
                        .step_mode = .vertex,
                        .attributes = &[_]gfx.VertexAttribute{
                            .{
                                .format = .float32x4,
                                .offset = 0,
                                .shader_location = 0,
                            },
                            .{
                                .format = .float32x4,
                                .offset = 4 * 4,
                                .shader_location = 1,
                            },
                        },
                    },
                },
            },
            .fragment = .{
                .entry_point = "fragment_main",
                .targets = &[_]gfx.ColorTargetState{
                    .{
                        .format = swapchain_format,
                    },
                },
            },
        },
    );

    example.status = .ok;
}

fn onGfxError(err: anyerror) void {
    example.status = Status{ .fail = err };
}

pub fn update() !void {
    // todo: see if this is a compiler error - shouldn't need to copy status here
    const status = example.status;
    switch (status) {
        .pending => return,
        .fail => |err| return err,
        .ok => {},
    }
}
