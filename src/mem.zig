const cfg = @import("cfg");
const std = @import("std");

pub const BumpAllocator = struct {
    buffer: []u8,
    index: usize,

    pub fn init(size: usize) !BumpAllocator {
        const size_aligned = std.mem.alignForward(size, std.mem.page_size);
        const buffer = switch (cfg.platform) {
            .web => block: {
                const page_idx = @wasmMemorySize(0);
                const result = @wasmMemoryGrow(0, size_aligned / std.mem.page_size);
                if (page_idx != result) {
                    return error.OutOfMemory;
                }
                break :block @intToPtr([*]u8, page_idx * std.mem.page_size)[0..size];
            },
        };

        return BumpAllocator{
            .buffer = buffer,
            .index = buffer.len,
        };
    }

    pub fn deinit(_: *BumpAllocator) void {
        switch (cfg.platform) {
            .web => {},
        }
    }

    pub fn reset(ba: *BumpAllocator) void {
        ba.index = ba.buffer.len;
    }

    pub fn allocator(ba: *BumpAllocator) std.mem.Allocator {
        return std.mem.Allocator.init(
            ba,
            alloc,
            std.mem.Allocator.NoResize(BumpAllocator).noResize,
            std.mem.Allocator.NoOpFree(BumpAllocator).noOpFree,
        );
    }

    fn alloc(ba: *BumpAllocator, n: usize, ptr_align: u29, _: u29, _: usize) ![]u8 {
        ba.index = std.math.sub(usize, ba.index, n) catch return error.OutOfMemory;
        ba.index &= ~(ptr_align - 1);
        return ba.buffer[ba.index .. ba.index + n];
    }
};
