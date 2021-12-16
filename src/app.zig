const api = switch (cfg.platform) {
    .web => @import("app_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

pub const Window = api.Window;
pub const Timer = api.Timer;

pub fn readSeconds(timer: Timer) f32 {
    return @floatCast(f32, @intToFloat(f64, timer.read()) / std.time.ns_per_s);
}

pub const log = api.log;
pub const log_level: std.log.Level = if (cfg.log_enabled) .debug else .alert;
