const build_app = @import("build_app.zig");
const minify = @import("minify.zig");
const std = @import("std");

pub const BuildWebStep = struct {
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

    builder: *std.build.Builder,
    step: std.build.Step,
    build_options: build_app.BuildOptions,
    html_name: []const u8,
    wasm_name: []const u8,
    js_dir: []const u8,

    pub fn create(
        builder: *std.build.Builder,
        build_options: build_app.BuildOptions,
        js_dir: []const u8,
    ) !*BuildWebStep {
        const build_web = try builder.allocator.create(BuildWebStep);
        const name = build_options.app.name;
        build_web.* = BuildWebStep{
            .builder = builder,
            .step = std.build.Step.init(.custom, "web pack", builder.allocator, make),
            .build_options = build_options,
            .html_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".html" }),
            .wasm_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".wasm" }),
            .js_dir = try builder.allocator.dupe(u8, js_dir),
        };

        builder.pushInstalledFile(.lib, build_web.html_name);
        builder.pushInstalledFile(.lib, js_name);

        return build_web;
    }

    fn make(step: *std.build.Step) !void {
        const build_web = @fieldParentPtr(BuildWebStep, "step", step);

        var lib_dir = try std.fs.cwd().makeOpenPath(build_web.builder.lib_dir, .{});
        defer lib_dir.close();

        const html_file = try lib_dir.createFile(build_web.html_name, .{ .truncate = true });
        defer html_file.close();

        try std.fmt.format(
            html_file.writer(),
            @embedFile("../examples/template.html"),
            .{build_web.wasm_name},
        );

        const js_file = try lib_dir.createFile(js_name, .{ .truncate = true });
        defer js_file.close();

        const js_src_dir_path = try std.fs.path.join(
            build_web.builder.allocator,
            &.{ build_web.builder.build_root, build_web.js_dir },
        );
        defer build_web.builder.allocator.free(js_src_dir_path);

        var js_src_dir = try std.fs.cwd().openDir(js_src_dir_path, .{});
        defer js_src_dir.close();

        var js_file_contents = std.ArrayList(u8).init(build_web.builder.allocator);
        inline for (js_srcs) |js_src| {
            const src_file = try js_src_dir.openFile(js_src, .{});
            defer src_file.close();

            const src_bytes = try src_file.readToEndAlloc(
                build_web.builder.allocator,
                (try src_file.stat()).size,
            );
            defer build_web.builder.allocator.free(src_bytes);

            try js_file_contents.appendSlice(src_bytes[0..]);
            try js_file_contents.appendSlice("\n");
        }

        if (build_web.build_options.opt_level == .release) {
            const src_bytes_min = try minify.js(
                js_file_contents.items,
                build_web.builder.allocator,
                build_web.build_options.opt_level,
            );
            defer build_web.builder.allocator.free(src_bytes_min);
            try js_file.writeAll(src_bytes_min);
        } else {
            try js_file.writeAll(js_file_contents.items);
        }
        js_file_contents.deinit();
    }
};
