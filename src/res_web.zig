const js = struct {
    extern fn readFile(
        name_ptr: [*]const u8,
        name_len: usize,
        file_ptr: [*]const u8,
        file_len: usize,
    ) void;
};

var read_file_frame: anyframe = undefined;
var read_file_result: anyerror!void = undefined;

pub fn readFile(name: []const u8, file: []u8) !void {
    try await async readFileAsync(name, file);
}

fn readFileAsync(name: []const u8, file: []u8) !void {
    js.readFile(name.ptr, name.len, file.ptr, file.len);
    suspend {
        read_file_frame = @frame();
    }
    try read_file_result;
}

export fn readFileComplete(success: bool) void {
    if (success) {
        read_file_result = {};
    } else {
        read_file_result = error.LoadFileFailed;
    }
    resume read_file_frame;
}
