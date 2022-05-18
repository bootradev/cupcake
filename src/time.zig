const api = switch (cfg.platform) {
    .web => @import("time_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

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
