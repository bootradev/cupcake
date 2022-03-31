const api = switch (cfg.platform) {
    .web => @import("app_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

pub const Timer = api.Timer;
pub const Window = api.Window;

pub const WindowDesc = struct {
    title: []const u8 = "",
    width: u32,
    height: u32,
};

pub fn readSeconds(timer: Timer) f32 {
    return @floatCast(f32, @intToFloat(f64, timer.read()) / std.time.ns_per_s);
}
