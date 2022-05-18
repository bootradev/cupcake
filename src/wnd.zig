const api = switch (cfg.platform) {
    .web => @import("wnd_web.zig"),
};
const cfg = @import("cfg");

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
        return @intToFloat(f32, window.getWidth()) / @intToFloat(f32, window.getHeight());
    }
};

