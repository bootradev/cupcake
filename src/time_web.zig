const js = struct {
    const DomHighResTimeStamp = f64;

    extern fn now() DomHighResTimeStamp;
};

// matches the public api of std.time.Timer
pub const Timer = struct {
    start_time: js.DomHighResTimeStamp,

    pub fn start() !Timer {
        return Timer{ .start_time = js.now() };
    }

    pub fn read(self: Timer) u64 {
        return timeStampToNs(js.now() - self.start_time);
    }

    pub fn reset(self: *Timer) void {
        self.start_time = js.now();
    }

    pub fn lap(self: *Timer) u64 {
        var now = js.now();
        var lap_time = self.timeStampToNs(now - self.start_time);
        self.start_time = now;
        return lap_time;
    }

    fn timeStampToNs(duration: js.DomHighResTimeStamp) u64 {
        return @floatToInt(u64, duration * 1000000.0);
    }
};
