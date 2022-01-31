const build_app = @import("build_app.zig");
const minify = @import("minify.zig");
const serde = @import("serde.zig");
const stb = @cImport({
    @cInclude("stb_image.h");
});
const std = @import("std");

pub const Res = struct {
    Type: type,
    data: Data,

    pub const Data = union(enum) {
        file: struct {
            path: []const u8,
            size: usize,
        },
        embedded: []const u8,
    };
};

pub const ShaderRes = struct {
    data: []const u8,
};

pub const TextureRes = struct {
    width: u32,
    height: u32,
    data: []const u8,
};

const BuildResult = struct {
    data: []const u8,
    var_name: []const u8,
    file_name: []const u8,
    type_name: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        resource: anytype,
        res: build_app.ManifestRes,
        file_name_suffix: ?[]const u8,
    ) !BuildResult {
        const data = try serde.serialize(allocator, resource);
        const var_name = try getVarName(allocator, res);
        const file_name = if (file_name_suffix) |suffix| block: {
            break :block try std.mem.concat(allocator, u8, &.{ var_name, "_", suffix });
        } else var_name;
        const type_name = @typeName(@TypeOf(resource));

        return BuildResult{
            .data = data,
            .var_name = var_name,
            .file_name = file_name,
            .type_name = type_name,
        };
    }

    pub fn deinit(build_info: BuildResult, allocator: std.mem.Allocator) void {
        if (build_info.var_name.ptr != build_info.file_name.ptr) {
            allocator.free(build_info.file_name);
        }
        allocator.free(build_info.var_name);
        allocator.free(build_info.data);
    }
};

pub const log_level = .info;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = std.process.ArgIterator.init();
    if (args.skip() == false) return error.InvalidArgs;
    const manifest_path = if (args.next(allocator)) |arg| try arg else return error.InvalidArgs;
    defer allocator.free(manifest_path);

    std.log.info("building manifest {s}", .{manifest_path});

    @setEvalBranchQuota(10000);
    const manifest_bytes = try readFile(allocator, &std.fs.cwd(), manifest_path);
    defer allocator.free(manifest_bytes);
    const manifest = try std.json.parse(
        build_app.Manifest,
        &std.json.TokenStream.init(manifest_bytes),
        .{ .allocator = allocator },
    );
    defer std.json.parseFree(build_app.Manifest, manifest, .{ .allocator = allocator });

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

        const build_fn = switch (res.res_type) {
            .shader => buildShader,
            .texture => buildTexture,
        };
        const build_result = try build_fn(allocator, manifest, res, res_bytes);
        defer build_result.deinit(allocator);

        var write_dir: std.fs.Dir = undefined;
        try writer.print("pub const {s} = cc.build_res.Res{{ ", .{build_result.var_name});
        try writer.print(".Type = cc.build_res.{s}, ", .{build_result.type_name});
        switch (res.file_type) {
            .embedded => {
                try writer.print(
                    ".data = .{{ .embedded = @embedFile(\"{s}\") }} ",
                    .{build_result.file_name},
                );
                write_dir = manifest_dir;
            },
            .file => {
                try writer.print(
                    ".data = .{{ .file = .{{ .path = \"{s}\", .size = {} }} }}",
                    .{ build_result.file_name, build_result.data.len },
                );
                write_dir = install_dir;
            },
        }
        try writer.print("}};\n", .{});
        try write_dir.writeFile(build_result.file_name, build_result.data);

        const res_path = try res_dir.realpathAlloc(allocator, res.path);
        defer allocator.free(res_path);
        const write_path = try write_dir.realpathAlloc(allocator, build_result.file_name);
        defer allocator.free(write_path);
        std.log.info(
            "{s} ({s}): {s} -> {s}",
            .{ build_result.var_name, @tagName(res.file_type), res_path, write_path },
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

fn buildShader(
    allocator: std.mem.Allocator,
    manifest: build_app.Manifest,
    res: build_app.ManifestRes,
    res_bytes: []const u8,
) !BuildResult {
    const shader_bytes = try minify.shader(res_bytes, allocator, .debug, manifest.gfx_api);
    defer allocator.free(shader_bytes);

    const shader_resource: ShaderRes = .{ .data = shader_bytes };

    return try BuildResult.init(allocator, shader_resource, res, @tagName(manifest.gfx_api));
}

fn buildTexture(
    allocator: std.mem.Allocator,
    _: build_app.Manifest,
    res: build_app.ManifestRes,
    res_bytes: []const u8,
) !BuildResult {
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

    return try BuildResult.init(allocator, texture_resource, res, null);
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
        "time_web.js",
        "res_web.js",
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

fn getVarName(allocator: std.mem.Allocator, res: build_app.ManifestRes) ![]const u8 {
    const res_path_no_ext = block: {
        const index = std.mem.lastIndexOfScalar(u8, res.path, '.') orelse
            break :block res.path[0..];
        if (index == 0) return error.InvalidResName;
        break :block res.path[0..index];
    };

    var res_path_no_ext_underscore = try allocator.dupe(u8, res_path_no_ext);
    defer allocator.free(res_path_no_ext_underscore);

    std.mem.replaceScalar(u8, res_path_no_ext_underscore, std.fs.path.sep, '_');

    return try std.mem.concat(
        allocator,
        u8,
        &.{ res_path_no_ext_underscore, "_", @tagName(res.res_type) },
    );
}

fn readFile(allocator: std.mem.Allocator, dir: *std.fs.Dir, path: []const u8) ![]u8 {
    const file = try dir.openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, (try file.stat()).size);
}
