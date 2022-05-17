const main = @import("main.zig");
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

pub const entry = struct {
    pub const WasmId = u32;
    pub var wasm_id: WasmId = undefined;

    var async_complete = false;

    // store the async calls in these variables in order to prevent the stack from
    // reclaiming the frame memory once the export fn completes
    var init_frame: @Frame(initAppAsync) = undefined;
    var loop_frame: @Frame(loopAppAsync) = undefined;
    var deinit_frame: @Frame(deinitAppAsync) = undefined;

    pub export fn initApp(id: WasmId) void {
        wasm_id = id;
        init_frame = async initAppAsync();
    }

    fn initAppAsync() void {
        main.init() catch |err| handleError(err);
        async_complete = true;
    }

    pub export fn loopApp() void {
        if (async_complete) {
            loop_frame = async loopAppAsync();
        }
    }

    fn loopAppAsync() void {
        async_complete = false;
        main.loop() catch |err| handleError(err);
        async_complete = true;
    }

    pub export fn deinitApp() void {
        deinit_frame = async deinitAppAsync();
    }

    fn deinitAppAsync() void {
        main.deinit() catch |err| handleError(err);
    }

    fn handleError(err: anyerror) noreturn {
        std.log.err("{}", .{err});
        @panic("");
    }
};
