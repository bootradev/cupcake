const cfg = @import("cfg");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const CanvasId = i32;
    const DomHighResTimeStamp = f64;

    extern fn logConsole(msg_ptr: [*]const u8, msg_len: usize) void;
    extern fn setWindowTitle(title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
    extern fn now() DomHighResTimeStamp;
};

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const msg = level_txt ++ prefix ++ format;

    var buf: [2048]u8 = undefined;
    const msg_buf = std.fmt.bufPrint(buf[0..], msg, args) catch return;

    js.logConsole(msg_buf.ptr, msg_buf.len);
}

pub const Window = struct {
    size: math.V2u32,
    id: js.CanvasId,

    pub fn init(window: *Window, name: []const u8, size: math.V2u32) !void {
        js.setWindowTitle(name.ptr, name.len);
        window.* = .{
            .id = js.createCanvas(size.x, size.y),
            .size = size,
        };
    }

    pub fn deinit(window: *Window) void {
        const empty: []const u8 = &.{};
        js.setWindowTitle(empty.ptr, empty.len);
        js.destroyCanvas(window.id);
    }
};

// make sure this matches the public api of std.time.Timer
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
