const bt = @import("bootra");
const cfg = @import("cfg");
const shaders = @import("shaders.zig");

const Example = struct {
    status: Status,
    window: bt.Window,
    device: bt.GfxDevice(onDeviceReady, onDeviceError),
    render_pipeline: bt.RenderPipeline,
};

const Status = union(enum) {
    pending,
    fail: anyerror,
    ok,
};

var example: Example = undefined;

pub fn init() !void {
    example.status = .pending;
    try example.window.init("tri", 800, 600);
    try example.device.init();
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

fn onDeviceReady() void {
    var vert_shader = try example.device.initShader(shaders.tri_vert);
    defer example.device.deinitShader(&vert_shader);
    example.device.checkShaderCompile(&vert_shader);

    var frag_shader = try example.device.initShader(shaders.tri_frag);
    defer example.device.deinitShader(&frag_shader);
    example.device.checkShaderCompile(&frag_shader);

    const pipeline_layout = try example.device.initPipelineLayout(&[_]bt.BindGroupLayout{}, .{});
    example.render_pipeline = try example.device.initRenderPipeline(
        &pipeline_layout,
        &vert_shader,
        &frag_shader,
        .{
            .vertex = .{
                .entry_point = "vertex_main",
                .buffers = &[_]bt.VertexBufferLayout{
                    .{
                        .array_stride = 2 * 4 * 4,
                        .step_mode = .vertex,
                        .attributes = &[_]bt.VertexAttribute{
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
                .targets = &[_]bt.ColorTargetState{
                    .{
                        .format = bt.swapchain_format,
                    },
                },
            },
        },
    );

    example.status = .ok;
}

fn onDeviceError(err: anyerror) void {
    example.status = Status{ .fail = err };
}
