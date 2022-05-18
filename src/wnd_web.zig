const wnd = @import("wnd.zig");
const main = @import("main.zig");

const js = struct {
    const CanvasId = u32;

    extern fn setWindowTitle(wasm_id: main.WasmId, title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(wasm_id: main.WasmId, width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
};

pub const Window = struct {
    id: js.CanvasId,
    width: u32,
    height: u32,

    pub fn init(desc: wnd.WindowDesc) !Window {
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

