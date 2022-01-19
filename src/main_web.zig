const app = @import("app");
const cc = @import("cupcake");
const std = @import("std");

const js = struct {
    extern fn logConsole(wasm_id: main.WasmId, msg_ptr: [*]const u8, msg_len: usize) void;
};

var log_buf: [2048]u8 = undefined;

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const msg = level_txt ++ prefix ++ format;

    const msg_buf = std.fmt.bufPrint(log_buf[0..], msg, args) catch return;
    js.logConsole(main.wasm_id, msg_buf.ptr, msg_buf.len);
}

pub const main = struct {
    pub const WasmId = u32;
    pub var wasm_id: WasmId = undefined;
    var init_in_progress = true;

    pub export fn init(id: WasmId) void {
        wasm_id = id;
        _ = async appInit();
    }

    fn appInit() void {
        app.init() catch |err| handleError(err);
        init_in_progress = false;
    }

    pub export fn update() void {
        _ = async appUpdate();
    }

    fn appUpdate() void {
        if (init_in_progress) {
            return;
        }

        app.update() catch |err| handleError(err);
    }

    pub export fn deinit() void {
        _ = async appDeinit();
    }

    fn appDeinit() void {
        app.deinit() catch |err| handleError(err);
    }

    fn handleError(err: anyerror) noreturn {
        std.log.err("{}", .{err});
        @panic("");
    }
};
