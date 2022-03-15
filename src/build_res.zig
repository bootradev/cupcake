const build_app = @import("build_app.zig");
const minify = @import("minify.zig");
const serde = @import("serde.zig");
const stb = @cImport({
    @cInclude("stb_image.h");
});
const std = @import("std");
const qoi = @import("qoi.zig");

pub const BuildRes = struct {
    Type: type,
    data: Data,

    pub const Data = union(enum) {
        file: struct {
            path: []const u8,
            size: usize,
        },
        embed: []const u8,
    };
};

pub const ShaderRes = struct {
    data: []const u8,
};

pub const TextureRes = struct {
    width: u32,
    height: u32,
    data: []const u8,

    pub fn serialize(value: TextureRes, allocator: std.mem.Allocator) ![]const u8 {
        const qoi_image = qoi.Image{
            .width = value.width,
            .height = value.height,
            .data = value.data,
        };

        var qoi_encode_len: usize = undefined;
        const qoi_bytes = try qoi.encode(qoi_image, &qoi_encode_len, allocator);
        return allocator.resize(qoi_bytes, qoi_encode_len) orelse error.ResizeFailed;
    }

    pub fn deserialize(bytes: []const u8, desc: serde.DeserializeDesc) !TextureRes {
        const allocator = desc.allocator orelse return error.AllocatorRequired;
        const image = try qoi.decode(bytes, allocator);
        return TextureRes{ .width = image.width, .height = image.height, .data = image.data };
    }
};

const BuildData = struct {
    data: []const u8,
    var_name: []const u8,
    type_name: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        build_res: anytype,
        manifest_res: build_app.ManifestRes,
    ) !BuildData {
        return BuildData{
            .data = try serde.serialize(build_res, allocator),
            .var_name = try getVarName(allocator, build_res, manifest_res),
            .type_name = @typeName(@TypeOf(build_res)),
        };
    }

    pub fn deinit(build_data: BuildData, allocator: std.mem.Allocator) void {
        allocator.free(build_data.var_name);
        allocator.free(build_data.data);
    }
};

pub const log_level = .info;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    if (args.skip() == false) return error.InvalidArgs;
    const manifest_path = if (args.next()) |arg| arg else return error.InvalidArgs;

    std.log.info("building manifest {s}", .{manifest_path});

    const manifest_bytes = try readFile(allocator, &std.fs.cwd(), manifest_path);
    defer allocator.free(manifest_bytes);
    const manifest = try serde.deserialize(
        build_app.Manifest,
        manifest_bytes,
        .{ .allocator = allocator },
    );
    defer serde.deserializeFree(manifest, allocator);

    const res_dir_path = try std.fs.path.join(
        allocator,
        &.{ manifest.build_root_path, manifest.res_dir },
    );
    defer allocator.free(res_dir_path);

    var res_dir = try std.fs.cwd().openDir(res_dir_path, .{});
    defer res_dir.close();

    const manifest_dir_path = std.fs.path.dirname(manifest.pkg_path) orelse
        return error.InvalidManifestPkgPath;

    var manifest_dir = try std.fs.cwd().makeOpenPath(manifest_dir_path, .{});
    defer manifest_dir.close();

    const install_dir_path = try std.fs.path.join(
        allocator,
        &.{ manifest.install_prefix, manifest.dest_dir },
    );
    defer allocator.free(install_dir_path);

    var install_dir = try std.fs.cwd().makeOpenPath(install_dir_path, .{});
    defer install_dir.close();

    var pkg_contents = std.ArrayList(u8).init(allocator);
    defer pkg_contents.deinit();
    const writer = pkg_contents.writer();

    try writer.print("const cc = @import(\"cupcake\");\n", .{});

    for (manifest.res) |res| {
        const res_bytes = try readFile(allocator, &res_dir, res.path);
        defer allocator.free(res_bytes);

        const build_fn = switch (try toCC(std.fs.path.extension(res.path))) {
            try toCC(".wgsl") => buildShader,
            try toCC(".png") => buildTexture,
            else => return error.InvalidResPathExtension,
        };
        const build_data = try build_fn(allocator, manifest, res, res_bytes);
        defer build_data.deinit(allocator);

        try writer.print("pub const {s} = cc.build_res.BuildRes{{ ", .{build_data.var_name});
        try writer.print(".Type = cc.build_res.{s}, ", .{build_data.type_name});
        if (res.embed) {
            try writer.print(
                ".data = .{{ .embed = @embedFile(\"{s}\") }} ",
                .{build_data.var_name},
            );
        } else {
            try writer.print(
                ".data = .{{ .file = .{{ .path = \"{s}\", .size = {} }} }}",
                .{ build_data.var_name, build_data.data.len },
            );
        }
        try writer.print("}};\n", .{});

        const write_dir = if (res.embed) manifest_dir else install_dir;
        try write_dir.writeFile(build_data.var_name, build_data.data);

        const res_path = try res_dir.realpathAlloc(allocator, res.path);
        defer allocator.free(res_path);
        const write_path = try write_dir.realpathAlloc(allocator, build_data.var_name);
        defer allocator.free(write_path);
        std.log.info(
            "{s} -> {s}",
            .{ res_path, write_path },
        );
    }

    std.log.info("writing package {s}", .{manifest.pkg_path});

    try std.fs.cwd().writeFile(
        manifest.pkg_path,
        pkg_contents.items,
    );

    switch (manifest.platform) {
        .web => try buildWeb(allocator, manifest, &install_dir),
    }

    std.log.info("done", .{});
}

const BuildFn = fn (
    std.mem.Allocator,
    build_app.Manifest,
    build_app.ManifestRes,
    []const u8,
) anyerror!BuildData;

fn buildShader(
    allocator: std.mem.Allocator,
    manifest: build_app.Manifest,
    res: build_app.ManifestRes,
    res_bytes: []const u8,
) anyerror!BuildData {
    const shader_bytes = try minify.shader(
        res_bytes,
        allocator,
        manifest.platform,
        manifest.opt_level,
    );
    defer allocator.free(shader_bytes);

    const shader_resource: ShaderRes = .{ .data = shader_bytes };

    return try BuildData.init(allocator, shader_resource, res);
}

fn buildTexture(
    allocator: std.mem.Allocator,
    _: build_app.Manifest,
    res: build_app.ManifestRes,
    res_bytes: []const u8,
) anyerror!BuildData {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;
    const texture_bytes = stb.stbi_load_from_memory(
        res_bytes.ptr,
        @intCast(c_int, res_bytes.len),
        &width,
        &height,
        &channels,
        0,
    );
    defer stb.stbi_image_free(texture_bytes);

    const texture_resource: TextureRes = .{
        .width = @intCast(u32, width),
        .height = @intCast(u32, height),
        .data = texture_bytes[0..@intCast(usize, width * height * channels)],
    };

    return try BuildData.init(allocator, texture_resource, res);
}

fn buildWeb(
    allocator: std.mem.Allocator,
    manifest: build_app.Manifest,
    install_dir: *std.fs.Dir,
) !void {
    std.log.info("building web files", .{});

    const html_name = try std.mem.concat(allocator, u8, &.{ manifest.name, ".html" });
    defer allocator.free(html_name);

    const wasm_name = try std.mem.concat(allocator, u8, &.{ manifest.name, ".wasm" });
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
        \\            run("{s}", null);
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
        "app_web.js",
        "gfx_webgpu.js",
    };
    const js_name = "cupcake.js";

    const js_src_dir_path = try std.fs.path.join(
        allocator,
        &.{ manifest.build_root_path, "src" },
    );
    defer allocator.free(js_src_dir_path);

    var js_src_dir = try std.fs.cwd().openDir(js_src_dir_path, .{});
    defer js_src_dir.close();

    var js_file_contents = std.ArrayList(u8).init(allocator);
    defer js_file_contents.deinit();

    for (js_srcs) |js_src| {
        const js_src_bytes = try readFile(allocator, &js_src_dir, js_src);
        defer allocator.free(js_src_bytes);

        try js_file_contents.appendSlice(js_src_bytes[0..]);
        try js_file_contents.appendSlice("\n");
    }

    if (manifest.opt_level == .release) {
        const js_src_bytes_min = try minify.js(
            js_file_contents.items,
            allocator,
            manifest.opt_level,
        );
        defer allocator.free(js_src_bytes_min);
        try install_dir.writeFile(js_name, js_src_bytes_min);
    } else {
        try install_dir.writeFile(js_name, js_file_contents.items);
    }

    const js_path = try install_dir.realpathAlloc(allocator, js_name);
    defer allocator.free(js_path);
    std.log.info("js bindings -> {s}", .{js_path});
}

fn getVarName(
    allocator: std.mem.Allocator,
    build_res: anytype,
    manifest_res: build_app.ManifestRes,
) ![]const u8 {
    const res_path_no_ext = block: {
        const index = std.mem.lastIndexOfScalar(u8, manifest_res.path, '.') orelse
            break :block manifest_res.path;
        if (index == 0) return error.InvalidResPath;
        break :block manifest_res.path[0..index];
    };

    const type_name = @typeName(@TypeOf(build_res));
    const type_name_no_res = block: {
        const index = std.mem.lastIndexOf(u8, type_name, "Res") orelse
            break :block type_name;
        break :block type_name[0..index];
    };

    const var_name = try std.mem.concat(
        allocator,
        u8,
        &.{ res_path_no_ext, "_", type_name_no_res },
    );
    for (var_name) |*char| {
        if (char.* == std.fs.path.sep) {
            char.* = '_';
        } else {
            char.* = std.ascii.toLower(char.*);
        }
    }
    return var_name;
}

fn toCC(extension: []const u8) !u32 {
    if (extension.len < 2 or extension.len > 5 or extension[0] != '.') {
        return error.InvalidExtension;
    }

    var cc: u32 = 0;
    for (extension[1..]) |char, i| {
        cc |= @as(u32, char) << @truncate(u5, i * 8);
    }
    return cc;
}

fn readFile(allocator: std.mem.Allocator, dir: *std.fs.Dir, path: []const u8) ![]u8 {
    const file = try dir.openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, (try file.stat()).size);
}
