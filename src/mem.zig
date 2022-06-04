const api = switch (cfg.platform) {
    .web => @import("mem_web.zig"),
    .win => @compileError("Not yet implemented!"),
};
const cfg = @import("cfg.zig");
const std = @import("std");

pub const BumpAllocator = struct {
    buffer: []u8,
    index: usize,

    pub fn init(size: usize) !BumpAllocator {
        const buffer = try api.alloc(size);
        return BumpAllocator{
            .buffer = buffer,
            .index = buffer.len,
        };
    }

    pub fn deinit(ba: *BumpAllocator) void {
        api.free(ba.buffer);
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
