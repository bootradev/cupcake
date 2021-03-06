const std = @import("std");

pub fn alloc(size: usize) ![]u8 {
    const page_size_aligned = std.mem.alignForward(size, std.mem.page_size);
    const num_pages = page_size_aligned / std.mem.page_size;
    const page_idx = @wasmMemorySize(0);
    const result = @wasmMemoryGrow(0, num_pages);
    if (page_idx != result) {
        return error.OutOfMemory;
    }
    return @intToPtr([*]u8, page_idx * std.mem.page_size)[0..size];
}

pub fn free(_: []u8) void {}
