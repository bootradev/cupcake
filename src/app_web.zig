const app = @import("app.zig");
const main = @import("main.zig");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const CanvasId = u32;

    extern fn setWindowTitle(wasm_id: main.WasmId, title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(wasm_id: main.WasmId, width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
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
