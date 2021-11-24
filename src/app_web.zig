const cfg = @import("cfg");
const std = @import("std");

const js = struct {
    extern "app" fn logConsole(msg_ptr: [*]const u8, msg_len: usize) void;
    extern "app" fn setWindowTitle(title_ptr: [*]const u8, title_len: usize) void;
    extern "app" fn createCanvas(width: u32, height: u32) void;
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
    width: u32,
    height: u32,

    pub fn init(window: *Window, name: []const u8, width: u32, height: u32) !void {
        js.setWindowTitle(name.ptr, name.len);
        js.createCanvas(width, height);
        window.* = .{
            .width = width,
            .height = height,
        };
    }
};
