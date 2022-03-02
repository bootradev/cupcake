const app = @import("app");
const cc = @import("cupcake");
const std = @import("std");

const js = struct {
    extern fn logConsole(wasm_id: main.WasmId, msg_ptr: [*]const u8, msg_len: usize) void;
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

    var log_buf: [2048]u8 = undefined;
    const msg_buf = std.fmt.bufPrint(&log_buf, msg, args) catch return;
    js.logConsole(main.wasm_id, msg_buf.ptr, msg_buf.len);
}

pub const main = struct {
    pub const WasmId = u32;
    pub var wasm_id: WasmId = undefined;

    var async_complete = false;

    // store the async calls in these variables in order to prevent the stack from
    // reclaiming the frame memory once the export fn completes
    var init_frame: @Frame(appInit) = undefined;
    var update_frame: @Frame(appUpdate) = undefined;
    var deinit_frame: @Frame(appDeinit) = undefined;

    pub export fn init(id: WasmId) void {
        wasm_id = id;
        init_frame = async appInit();
    }

    fn appInit() void {
        app.init() catch |err| handleError(err);
        async_complete = true;
    }

    pub export fn update() void {
        update_frame = async appUpdate();
    }

    fn appUpdate() void {
        if (async_complete) {
            async_complete = false;
            app.update() catch |err| handleError(err);
            async_complete = true;
        }
    }

    pub export fn deinit() void {
        deinit_frame = async appDeinit();
    }

    fn appDeinit() void {
        app.deinit() catch |err| handleError(err);
    }

    fn handleError(err: anyerror) noreturn {
        std.log.err("{}", .{err});
        @panic("");
    }
};
