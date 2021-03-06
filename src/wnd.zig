const api = switch (cfg.platform) {
    .web => @import("wnd_web.zig"),
    .win => @compileError("Not yet implemented!"),
};
const cfg = @import("cfg.zig");

pub const WindowDesc = struct {
    title: []const u8 = "",
    width: u32,
    height: u32,
};

pub const Window = struct {
    impl: api.Window,

    pub fn init(desc: WindowDesc) !Window {
        return Window{ .impl = try api.Window.init(desc) };
    }

    pub fn deinit(window: *Window) void {
        window.impl.deinit();
    }

    pub fn getWidth(window: Window) u32 {
        return window.impl.getWidth();
    }

    pub fn getHeight(window: Window) u32 {
        return window.impl.getHeight();
    }

    pub fn getAspectRatio(window: Window) f32 {
        const widthf = @intToFloat(f32, window.getWidth());
        const heightf = @intToFloat(f32, window.getHeight());
        return widthf / heightf;
    }

    pub fn isVisible(window: Window) bool {
        return window.impl.isVisible();
    }
};
