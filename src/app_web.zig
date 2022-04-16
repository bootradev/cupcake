const app = @import("app.zig");
const main = @import("main.zig");
const std = @import("std");

const js = struct {
    const CanvasId = u32;
    const DomHighResTimeStamp = f64;

    extern fn setWindowTitle(wasm_id: main.WasmId, title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(wasm_id: main.WasmId, width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
    extern fn now() DomHighResTimeStamp;
};

pub const Window = struct {
    id: js.CanvasId,
    width: u32,
    height: u32,

    pub fn init(desc: app.WindowDesc) !Window {
        if (desc.title.len > 0) {
            js.setWindowTitle(main.wasm_id, desc.title.ptr, desc.title.len);
        }
        return Window{
            .id = js.createCanvas(main.wasm_id, desc.width, desc.height),
            .width = desc.width,
            .height = desc.height,
        };
    }

    pub fn deinit(window: *Window) void {
        const empty: []const u8 = &.{};
        js.setWindowTitle(main.wasm_id, empty.ptr, empty.len);
        js.destroyCanvas(window.id);
    }

    pub fn getWidth(window: Window) u32 {
        return window.width;
    }

    pub fn getHeight(window: Window) u32 {
        return window.height;
    }
};

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
