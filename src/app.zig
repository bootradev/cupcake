const api = switch (cfg.platform) {
    .web => @import("app_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

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
};

pub const Timer = struct {
    impl: api.Timer,

    pub fn start() !Timer {
        return Timer{ .impl = try api.Timer.start() };
    }

    pub fn read(timer: Timer) u64 {
        return timer.impl.read();
    }

    pub fn readSeconds(timer: Timer) f32 {
        return @floatCast(f32, @intToFloat(f64, timer.read()) / std.time.ns_per_s);
    }

    pub fn reset(timer: *Timer) void {
        timer.impl.reset();
    }

    pub fn lap(timer: *Timer) u64 {
        return timer.impl.lap();
    }
};
