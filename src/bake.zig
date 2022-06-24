const bake_list = @import("bake_list");
const serde = @import("serde.zig");
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("bake begin...", .{});
    std.log.info("platform: {s}", .{@tagName(bake_list.platform)});
    std.log.info("optimization level: {s}", .{@tagName(bake_list.opt_level)});

    var in_dir = try std.fs.cwd().openDir(bake_list.in_dir, .{});
    defer in_dir.close();
    var out_dir = try std.fs.cwd().openDir(bake_list.out_dir, .{});
    defer out_dir.close();

    std.log.info("input dir: {s}", .{bake_list.in_dir});
    std.log.info("output dir: {s}", .{bake_list.out_dir});

    var deps = std.ArrayList([]u8).init(allocator);
    defer deps.deinit();

    var pkg_contents = std.ArrayList(u8).init(allocator);
    defer pkg_contents.deinit();
    const writer = pkg_contents.writer();
    inline for (@typeInfo(bake_list.pkgs).Struct.decls) |decl| {
        try writer.print("pub const {s} = @import(\"{s}\");\n", .{ decl.name, decl.name });
    }

    inline for (@typeInfo(bake_list.items).Struct.decls) |decl| {
        const item = @field(bake_list.items, decl.name);

        std.log.info("{s} {s}", .{ item.bake_type, decl.name });

        inline for (item.deps) |dep| {
            const is_id = comptime std.mem.indexOfScalar(u8, dep, '.') == null;
            const dir = if (is_id) out_dir else in_dir;
            const file = try dir.openFile(dep, .{});
            defer file.close();
            const file_stat = try file.stat();
            const file_bytes = try file.readToEndAlloc(allocator, file_stat.size);
            try deps.append(file_bytes);
        }

        const bake_pkg = @field(bake_list.pkgs, item.bake_pkg);
        const bake_fn = @field(bake_pkg, item.bake_type ++ "Bake");
        const BakeType = comptime block: {
            const return_type = @typeInfo(@TypeOf(bake_fn)).Fn.return_type.?;
            switch (@typeInfo(return_type)) {
                .ErrorUnion => |EU| break :block EU.payload,
                else => @compileError("bake fn return type must be an error union!"),
            }
        };
        const bake_result = try bake_fn(
            allocator,
            deps.items,
            bake_list.platform,
            bake_list.opt_level,
        );
        defer if (@hasDecl(bake_pkg, item.bake_type ++ "BakeFree")) {
            const bake_free_fn = @field(bake_pkg, item.bake_type ++ "BakeFree");
            bake_free_fn(allocator, bake_result);
        };
        const bake_bytes = try serde.serialize(allocator, bake_result);
        defer allocator.free(bake_bytes);

        try out_dir.writeFile(decl.name, bake_bytes);

        if (item.output != .cache) {
            try writer.print("pub const {s} = .{{\n", .{decl.name});
            try writer.print("    .Type = {s}.{s},\n", .{ item.bake_pkg, @typeName(BakeType) });
            if (item.output == .pkg_embed) {
                try writer.print(
                    "    .data = .{{ .embed = @embedFile(\"{s}\") }},\n",
                    .{decl.name},
                );
            } else {
                try writer.print(
                    "    .data = .{{ .file = .{{ .path = \"{s}\", .size = {} }} }},\n",
                    .{ decl.name, bake_bytes.len },
                );
            }
            try writer.print("}};\n", .{});
        }

        for (deps.items) |dep| {
            allocator.free(dep);
        }
        deps.clearRetainingCapacity();
    }

    try out_dir.writeFile("bake_pkg.zig", pkg_contents.items);

    std.log.info("bake complete!", .{});
}
