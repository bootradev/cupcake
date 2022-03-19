const api = switch (cfg.platform) {
    .web => @import("res_web.zig"),
};
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const serde = @import("serde.zig");
const std = @import("std");

pub const Res = struct {
    type_name: []const u8,
    data: Data,

    pub const Data = union(enum) {
        file: struct {
            path: []const u8,
            size: usize,
        },
        embed: []const u8,
    };
};

pub const LoadDesc = struct {
    file_allocator: ?std.mem.Allocator = null,
    res_allocator: ?std.mem.Allocator = null,
};

pub fn load(comptime res: Res, desc: LoadDesc) !@field(build_res, res.type_name) {
    const bytes_are_embedded = comptime std.meta.activeTag(res.data) == .embed;
    const file_bytes = switch (res.data) {
        .embed => |e| e,
        .file => |f| block: {
            if (desc.file_allocator) |allocator| {
                break :block try readFile(allocator, f.path, f.size);
            } else {
                return error.AllocatorRequired;
            }
        },
    };
    defer if (!bytes_are_embedded) {
        desc.file_allocator.?.free(file_bytes);
    };

    return try serde.deserialize(
        .{ .allocator = desc.res_allocator, .bytes_are_embedded = bytes_are_embedded },
        @field(build_res, res.type_name),
        file_bytes,
    );
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8, size: usize) ![]const u8 {
    const data = try allocator.alloc(u8, size);
    try api.readFile(path, data);
    return data;
}
