const bt = @import("bootra");
const shaders = @import("shaders.zig");
const std = @import("std");

const Example = struct {
    window: bt.Window,
    device: bt.GfxDevice(onDeviceReady, onDeviceError),
    status: Status,
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

    example.status = .ok;
}

fn onDeviceError(err: anyerror) void {
    example.status = Status{ .fail = err };
}
