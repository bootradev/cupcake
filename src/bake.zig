const make = @import("make.zig");
const minify = @import("minify.zig");
const serde = @import("serde.zig");
const stb = @cImport({
    @cInclude("stb/stb_image.h");
});
const std = @import("std");
const qoi = @import("qoi.zig");
const utils = @import("utils.zig");

pub const BakeShader = struct {
    data: []const u8,

    pub fn bake(
        allocator: std.mem.Allocator,
        recipe: make.Recipe,
        bake_item: make.BakeItem,
        bake_item_bytes: []const u8,
    ) anyerror!BakeResult {
        const shader_bytes = try minify.shader(
            bake_item_bytes,
            allocator,
            recipe.platform,
            recipe.opt_level,
        );
        defer allocator.free(shader_bytes);

        const bake_shader = BakeShader{ .data = shader_bytes };

        return try BakeResult.init(allocator, bake_shader, bake_item);
    }
};

pub const BakeTexture = struct {
    width: u32,
    height: u32,
    data: []const u8,

    pub fn serialize(allocator: std.mem.Allocator, value: BakeTexture) ![]const u8 {
        const qoi_image = qoi.Image{
            .width = value.width,
            .height = value.height,
            .data = value.data,
        };

        const result = try qoi.encode(qoi_image, allocator);
        return allocator.resize(result.bytes, result.len) orelse error.ResizeFailed;
    }

    pub fn deserialize(desc: serde.DeserializeDesc, bytes: []const u8) !BakeTexture {
        const allocator = desc.allocator orelse return error.AllocatorRequired;
        const image = try qoi.decode(bytes, allocator);
        return BakeTexture{ .width = image.width, .height = image.height, .data = image.data };
    }

    pub fn bake(
        allocator: std.mem.Allocator,
        _: make.Recipe,
        bake_item: make.BakeItem,
        bake_item_bytes: []const u8,
    ) anyerror!BakeResult {
        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;
        const texture_bytes = stb.stbi_load_from_memory(
            bake_item_bytes.ptr,
            @intCast(c_int, bake_item_bytes.len),
            &width,
            &height,
            &channels,
            0,
        );
        defer stb.stbi_image_free(texture_bytes);

        const bake_texture = BakeTexture{
            .width = @intCast(u32, width),
            .height = @intCast(u32, height),
            .data = texture_bytes[0..@intCast(usize, width * height * channels)],
        };

        return try BakeResult.init(allocator, bake_texture, bake_item);
    }
};

const BakeResult = struct {
    allocator: std.mem.Allocator,
    data: []const u8,
    var_name: []const u8,
    type_name: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        bake_data: anytype,
        bake_item: make.BakeItem,
    ) !BakeResult {
        return BakeResult{
            .allocator = allocator,
            .data = try serde.serialize(allocator, bake_data),
            .var_name = try getVarName(allocator, bake_data, bake_item),
            .type_name = @typeName(@TypeOf(bake_data)),
        };
    }

    pub fn deinit(bake_result: BakeResult) void {
        bake_result.allocator.free(bake_result.var_name);
        bake_result.allocator.free(bake_result.data);
    }
};

pub fn bakeItem(
    allocator: std.mem.Allocator,
    recipe: make.Recipe,
    bake_item: make.BakeItem,
    bake_item_bytes: []const u8,
) !BakeResult {
    const bake_fn = switch (try extensionCode(std.fs.path.extension(bake_item.path))) {
        try extensionCode(".wgsl") => BakeShader.bake,
        try extensionCode(".png") => BakeTexture.bake,
        else => return error.InvalidBakeItemExtension,
    };
    return try bake_fn(allocator, recipe, bake_item, bake_item_bytes);
}

pub fn bakePlatform(allocator: std.mem.Allocator, recipe: make.Recipe) !void {
    const bake_platform_fn = switch (recipe.platform) {
        .web => bakeWeb,
        else => return error.InvalidPlatform,
    };
    try bake_platform_fn(allocator, recipe);
}

pub fn bakeWeb(allocator: std.mem.Allocator, recipe: make.Recipe) !void {
    var install_dir = try std.fs.cwd().makeOpenPath(recipe.install_dir, .{});
    defer install_dir.close();

    const html_name = try std.mem.concat(allocator, u8, &.{ recipe.name, ".html" });
    defer allocator.free(html_name);

    const wasm_name = try std.mem.concat(allocator, u8, &.{ recipe.name, ".wasm" });
    defer allocator.free(wasm_name);

    const html_file = try install_dir.createFile(html_name, .{ .truncate = true });
    const html_fmt =
        \\<!DOCTYPE html>
        \\<html>
        \\    <head>
        \\        <meta charset="utf-8">
        \\        <style>
        \\            canvas {{
        \\                border: 1px solid;
        \\                display: block;
        \\                margin: 0px auto 0px auto;
        \\            }}
        \\        </style>
        \\    </head>
        \\    <body>
        \\        <script src="cupcake.js"></script>
        \\        <script>
        \\            ccRun("{s}");
        \\        </script>
        \\    </body>
        \\</html>
    ;
    try std.fmt.format(html_file.writer(), html_fmt, .{wasm_name});
    html_file.close();

    const html_path = try install_dir.realpathAlloc(allocator, html_name);
    defer allocator.free(html_path);
    std.log.info("html template -> {s}", .{html_path});

    // intentional ordering to prevent dependency issues
    const js_srcs: []const []const u8 = &.{
        "utils.js",
        "main_web.js",
        "time_web.js",
        "res_web.js",
        "wnd_web.js",
        "gfx_webgpu.js",
    };
    const js_name = "cupcake.js";

    const js_src_dir_path = try std.fs.path.join(
        allocator,
        &.{ recipe.build_root_dir, "src" },
    );
    defer allocator.free(js_src_dir_path);

    var js_src_dir = try std.fs.cwd().openDir(js_src_dir_path, .{});
    defer js_src_dir.close();

    var js_file_contents = std.ArrayList(u8).init(allocator);
    defer js_file_contents.deinit();

    for (js_srcs) |js_src| {
        const js_src_bytes = try utils.readFile(allocator, &js_src_dir, js_src);
        defer allocator.free(js_src_bytes);

        try js_file_contents.appendSlice(js_src_bytes[0..]);
        try js_file_contents.appendSlice("\n");
    }

    if (recipe.opt_level == .dbg) {
        try install_dir.writeFile(js_name, js_file_contents.items);
    } else {
        const js_src_bytes_min = try minify.js(
            js_file_contents.items,
            allocator,
            recipe.opt_level,
        );
        defer allocator.free(js_src_bytes_min);
        try install_dir.writeFile(js_name, js_src_bytes_min);
    }

    const js_path = try install_dir.realpathAlloc(allocator, js_name);
    defer allocator.free(js_path);
    std.log.info("js bindings -> {s}", .{js_path});
}

fn getVarName(
    allocator: std.mem.Allocator,
    bake_data: anytype,
    bake_item: make.BakeItem,
) ![]const u8 {
    const bake_item_path_no_ext = block: {
        const index = std.mem.lastIndexOfScalar(u8, bake_item.path, '.') orelse
            break :block bake_item.path;
        if (index == 0) return error.InvalidResPath;
        break :block bake_item.path[0..index];
    };

    const type_name = @typeName(@TypeOf(bake_data));
    const type_name_no_bake = block: {
        const marker = "Bake";
        if (std.mem.startsWith(u8, type_name, marker))
            break :block type_name[marker.len..]
        else
            break :block type_name;
    };

    const var_name = try std.mem.concat(
        allocator,
        u8,
        &.{ bake_item_path_no_ext, "_", type_name_no_bake },
    );
    for (var_name) |*char| {
        if (std.fs.path.isSep(char.*)) {
            char.* = '_';
        } else {
            char.* = std.ascii.toLower(char.*);
        }
    }
    return var_name;
}

fn extensionCode(extension: []const u8) !u32 {
    if (extension.len < 2 or extension.len > 5 or extension[0] != '.') {
        return error.InvalidExtension;
    }

    var code: u32 = 0;
    for (extension[1..]) |char, i| {
        code |= @as(u32, char) << @truncate(u5, i * 8);
    }
    return code;
}
