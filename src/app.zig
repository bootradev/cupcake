const api = switch (cfg.platform) {
    .web => @import("app_web.zig"),
};
const cfg = @import("cfg");

pub const Window = api.Window;

pub const WindowDesc = struct {
    name: []const u8 = "",
};
