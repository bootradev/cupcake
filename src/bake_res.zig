const bake = @import("bake.zig");
const make = @import("make.zig");
const serde = @import("serde.zig");
const std = @import("std");
const utils = @import("utils.zig");

pub const log_level = .info;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    if (args.skip() == false) return error.InvalidArgs;
    const recipe_path = args.next() orelse return error.InvalidArgs;
    const install_enabled = if (args.next()) |arg| std.mem.eql(u8, arg, "install") else false;

    const recipe_bytes = try utils.readFile(allocator, &std.fs.cwd(), recipe_path);
    defer allocator.free(recipe_bytes);
    const recipe = try serde.deserialize(
        .{ .allocator = allocator },
        make.Recipe,
        recipe_bytes,
    );
    defer serde.deserializeFree(allocator, recipe);

    std.log.info("baking for {s} using recipe: {s}", .{ recipe.name, recipe_path });

    const bake_dir_path = try std.fs.path.join(
        allocator,
        &.{ recipe.build_root_dir, recipe.bake_dir },
    );
    defer allocator.free(bake_dir_path);

    var bake_dir = try std.fs.cwd().openDir(bake_dir_path, .{});
    defer bake_dir.close();

    const recipe_dir_path = std.fs.path.dirname(recipe.pkg_path) orelse
        return error.InvalidManifestPkgPath;

    var recipe_dir: ?std.fs.Dir = try std.fs.cwd().makeOpenPath(recipe_dir_path, .{});
    defer recipe_dir.?.close();

    var install_dir = if (install_enabled)
        try std.fs.cwd().makeOpenPath(recipe.install_dir, .{})
    else
        null;
    defer if (install_dir) |*dir| dir.close();

    var pkg_contents = std.ArrayList(u8).init(allocator);
    defer pkg_contents.deinit();
    const writer = pkg_contents.writer();

    try writer.print("const bake = @import(\"bake\");\n", .{});

    for (recipe.bake_items) |bake_item| {
        const bake_item_bytes = try utils.readFile(allocator, &bake_dir, bake_item.path);
        defer allocator.free(bake_item_bytes);

        const bake_result = try bake.bakeItem(allocator, recipe, bake_item, bake_item_bytes);
        defer bake_result.deinit();

        try writer.print("pub const {s} = .{{ ", .{bake_result.var_name});
        try writer.print(".Type = bake.{s}, ", .{bake_result.type_name});
        if (bake_item.embed) {
            try writer.print(
                ".data = .{{ .embed = @embedFile(\"{s}\") }} ",
                .{bake_result.var_name},
            );
        } else {
            try writer.print(
                ".data = .{{ .file = .{{ .path = \"{s}\", .size = {} }} }}",
                .{ bake_result.var_name, bake_result.data.len },
            );
        }
        try writer.print("}};\n", .{});

        const write_dir = if (bake_item.embed) recipe_dir else install_dir;
        try write_dir.?.writeFile(bake_result.var_name, bake_result.data);

        const bake_item_path = try bake_dir.realpathAlloc(allocator, bake_item.path);
        defer allocator.free(bake_item_path);
        const write_path = try write_dir.?.realpathAlloc(allocator, bake_result.var_name);
        defer allocator.free(write_path);
        std.log.info(
            "{s} -> {s}",
            .{ bake_item_path, write_path },
        );
    }

    try std.fs.cwd().writeFile(
        recipe.pkg_path,
        pkg_contents.items,
    );
    std.log.info("bake package -> {s}", .{recipe.pkg_path});
    std.log.info("done baking recipe", .{});

    if (install_enabled) {
        std.log.info("baking platform files for {s}:", .{@tagName(recipe.platform)});
        try bake.bakePlatform(allocator, recipe);
        std.log.info("done baking platform files", .{});
    }

    std.log.info("bake complete!\n", .{});
}
