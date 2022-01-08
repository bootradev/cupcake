const main = @import("main.zig");
const res = @import("res.zig");
const std = @import("std");

const js = struct {
    extern fn requestFile(
        wasm_id: main.WasmId,
        name_ptr: [*]const u8,
        name_len: usize,
        data_ptr: [*]const u8,
        data_len: usize,
        user_data: ?*anyopaque,
    ) void;
};

pub fn requestFile(
    allocator: std.mem.Allocator,
    comptime header: res.FileHeader,
    user_data: ?*anyopaque,
) !void {
    const bytes = try allocator.alloc(u8, header.size);
    js.requestFile(main.wasm_id, header.name.ptr, header.name.len, bytes.ptr, bytes.len, user_data);
}

export fn requestFileComplete(data_ptr: [*]u8, data_len: usize, user_data: ?*anyopaque) void {
    res.file_ready_cb(data_ptr[0..data_len], user_data);
}

export fn fileError(error_code: u32, data_ptr: [*]u8, data_len: usize, user_data: ?*anyopaque) void {
    const err = switch (error_code) {
        0 => error.RequestFileFailed,
        else => error.ResError,
    };
    res.file_error_cb(err, data_ptr[0..data_len], user_data);
}
