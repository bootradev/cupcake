const api = switch (cfg.platform) {
    .web => @import("res_web.zig"),
};
const cfg = @import("cfg");
const root = @import("root");

pub const FileHeader = struct {
    name: []const u8,
    size: usize,
};

pub const requestFile = api.requestFile;

pub const ResCbs = struct {
    file_ready_cb: fn (file_data: []u8, user_data: ?*anyopaque) void = fileReadyNoOp,
    res_error_cb: fn (err: anyerror, user_data: ?*anyopaque) void = resErrorNoOp,
};

fn fileReadyNoOp(_: []u8, _: ?*anyopaque) void {}
fn resErrorNoOp(_: anyerror, _: ?*anyopaque) void {}

pub const cbs = if (@hasDecl(root.app, "gfx_cbs")) root.app.res_cbs else .{};
