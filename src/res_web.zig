const main = @import("main.zig");

const js = struct {
    extern fn loadFile(
        wasm_id: main.WasmId,
        name_ptr: [*]const u8,
        name_len: usize,
        file_ptr: [*]const u8,
        file_len: usize,
    ) void;
};

var load_file_frame: anyframe = undefined;
var load_file_result: anyerror!void = undefined;

pub fn loadFile(name: []const u8, file: []u8) !void {
    try await async loadFileAsync(name, file);
}

fn loadFileAsync(name: []const u8, file: []u8) !void {
    js.loadFile(main.wasm_id, name.ptr, name.len, file.ptr, file.len);
    suspend {
        load_file_frame = @frame();
    }
    try load_file_result;
}

export fn loadFileComplete(success: bool) void {
    if (success) {
        load_file_result = {};
    } else {
        load_file_result = error.LoadFileFailed;
    }
    resume load_file_frame;
}
