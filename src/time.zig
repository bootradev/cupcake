const api = switch (cfg.platform) {
    .web => @import("time_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

pub const Timer = api.Timer;

pub fn readSeconds(timer: Timer) f32 {
    return @floatCast(f32, @intToFloat(f64, timer.read()) / std.time.ns_per_s);
}
