const api = switch (cfg.platform) {
    .web => @import("res_web.zig"),
};
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const serde = @import("serde.zig");
const std = @import("std");

pub const LoadOptions = struct {
    file_allocator: ?std.mem.Allocator = null,
    res_allocator: ?std.mem.Allocator = null,
};

pub fn load(comptime res: build_res.Res, options: LoadOptions) !res.Type {
    const bytes_are_embedded = comptime std.meta.activeTag(res.data) == .embedded;
    const file_bytes = switch (res.data) {
        .embedded => |e| e,
        .file => |f| block: {
            if (options.file_allocator) |allocator| {
                break :block try readFile(allocator, f.path, f.size);
            } else {
                return error.AllocatorRequired;
            }
        },
    };
    defer if (!bytes_are_embedded) {
        options.file_allocator.?.free(file_bytes);
    };

    return try serde.deserialize(
        res.Type,
        file_bytes,
        .{ .allocator = options.res_allocator, .bytes_are_embedded = bytes_are_embedded },
    );
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8, size: usize) ![]const u8 {
    const data = try allocator.alloc(u8, size);
    try api.readFile(path, data);
    return data;
}
