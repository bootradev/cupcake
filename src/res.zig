const api = switch (cfg.platform) {
    .web => @import("res_web.zig"),
};
const cfg = @import("cfg");
const root = @import("root");

pub const requestFile = api.requestFile;

pub const file_ready_cb = if (@hasDecl(root.app, "ccResFileReady"))
    root.app.ccResFileReady
else
    fileReadyNoOp;

pub const file_error_cb = if (@hasDecl(root.app, "ccResFileError"))
    root.app.ccResFileError
else
    fileErrorNoOp;

fn fileReadyNoOp(_: []u8, _: ?*anyopaque) void {}
fn fileErrorNoOp(_: anyerror, _: []u8, _: ?*anyopaque) void {}

pub const ResourceType = enum {
    shader,
};

pub const Resource = struct {
    res_type: ResourceType,
    path: []const u8,
    size: usize,
};
