const main = @import("main.zig");

const js = struct {
    extern fn readFile(
        wasm_id: main.WasmId,
        name_ptr: [*]const u8,
        name_len: usize,
        file_ptr: [*]const u8,
        file_len: usize,
    ) void;
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
