const app = @import("app.zig");
const main = @import("main.zig");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const CanvasId = u32;
    const DomHighResTimeStamp = f64;

    extern fn setWindowTitle(wasm_id: main.WasmId, title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(wasm_id: main.WasmId, width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
    extern fn now() DomHighResTimeStamp;
    extern fn readFile(
        wasm_id: main.WasmId,
        name_ptr: [*]const u8,
        name_len: usize,
        file_ptr: [*]const u8,
        file_len: usize,
    ) void;
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

pub const Window = struct {
    size: math.V2u32,
    id: js.CanvasId,

    pub fn init(size: math.V2u32, comptime desc: app.WindowDesc) !Window {
        if (desc.name.len > 0) {
            js.setWindowTitle(main.wasm_id, desc.name.ptr, desc.name.len);
        }
        return Window{
            .id = js.createCanvas(main.wasm_id, size.x, size.y),
            .size = size,
        };
    }

    pub fn deinit(window: *Window) void {
        const empty: []const u8 = &.{};
        js.setWindowTitle(main.wasm_id, empty.ptr, empty.len);
        js.destroyCanvas(window.id);
    }
};

var load_file_frame: anyframe = undefined;
var load_file_result: anyerror!void = undefined;

pub fn readFile(name: []const u8, file: []u8) !void {
    try await async readFileAsync(name, file);
}

fn readFileAsync(name: []const u8, file: []u8) !void {
    js.readFile(main.wasm_id, name.ptr, name.len, file.ptr, file.len);
    suspend {
        load_file_frame = @frame();
    }
    try load_file_result;
}

export fn readFileComplete(success: bool) void {
    if (success) {
        load_file_result = {};
    } else {
        load_file_result = error.LoadFileFailed;
    }
    resume load_file_frame;
}
