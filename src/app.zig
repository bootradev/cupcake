const api = switch (cfg.platform) {
    .web => @import("app_web.zig"),
};
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const serde = @import("serde.zig");
const std = @import("std");

pub const Timer = api.Timer;
pub const Window = api.Window;

pub const LoadDesc = struct {
    file_allocator: ?std.mem.Allocator = null,
    res_allocator: ?std.mem.Allocator = null,
};

pub const WindowDesc = struct {
    name: []const u8 = "",
};

pub fn readSeconds(timer: Timer) f32 {
    return @floatCast(f32, @intToFloat(f64, timer.read()) / std.time.ns_per_s);
}

pub fn load(comptime res: build_res.Res, desc: LoadDesc) !res.Type {
    const bytes_are_embedded = comptime std.meta.activeTag(res.data) == .embedded;
    const file_bytes = switch (res.data) {
        .embedded => |e| e,
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
        res.Type,
        file_bytes,
        .{ .allocator = desc.res_allocator, .bytes_are_embedded = bytes_are_embedded },
    );
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8, size: usize) ![]const u8 {
    const data = try allocator.alloc(u8, size);
    try api.readFile(path, data);
    return data;
}
