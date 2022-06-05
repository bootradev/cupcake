const wnd = @import("wnd.zig");

const js = struct {
    const CanvasId = u32;

    extern fn setWindowTitle(title_ptr: [*]const u8, title_len: usize) void;
    extern fn createCanvas(width: u32, height: u32) CanvasId;
    extern fn destroyCanvas(canvas_id: CanvasId) void;
    extern fn isVisible(canvas_id: CanvasId) bool;
};

pub const Window = struct {
    const max_window_id_digits = 10; // max 32 bit number is 4294967295
    id: js.CanvasId,
    id_str: [max_window_id_digits]u8,
    id_index: usize,
    width: u32,
    height: u32,

    pub fn init(desc: wnd.WindowDesc) !Window {
        if (desc.title.len > 0) {
            js.setWindowTitle(desc.title.ptr, desc.title.len);
        }
        var window = Window{
            .id = js.createCanvas(desc.width, desc.height),
            .id_str = [_]u8{0} ** max_window_id_digits,
            .id_index = max_window_id_digits,
            .width = desc.width,
            .height = desc.height,
        };

        var value = window.id;
        while (value > 0) : (value /= 10) {
            window.id_index -= 1;
            window.id_str[window.id_index] = @truncate(u8, value % 10) + '0';
        }

        return window;
    }

    pub fn deinit(window: *Window) void {
        const empty: []const u8 = &.{};
        js.setWindowTitle(empty.ptr, empty.len);
        js.destroyCanvas(window.id);
    }

    pub fn getWidth(window: Window) u32 {
        return window.width;
    }

    pub fn getHeight(window: Window) u32 {
        return window.height;
    }

    pub fn getCanvasId(window: Window) []const u8 {
        return window.id_str[window.id_index..];
    }

    pub fn isVisible(window: Window) bool {
        return js.isVisible(window.id);
    }
};
