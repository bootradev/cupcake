const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, dir: *std.fs.Dir, path: []const u8) ![]u8 {
    const file = try dir.openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, (try file.stat()).size);
}
