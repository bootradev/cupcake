const build_app = @import("build_app.zig");
const minify = @import("minify.zig");
const std = @import("std");

pub const BuildResStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    build_options: build_app.BuildOptions,
    contents: std.ArrayList(u8),
    generated_file: std.build.GeneratedFile,

    pub fn create(
        builder: *std.build.Builder,
        build_options: build_app.BuildOptions,
    ) !*BuildResStep {
        const build_res = try builder.allocator.create(BuildResStep);
        build_res.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "build resources", builder.allocator, make),
            .build_options = build_options,
            .contents = std.ArrayList(u8).init(builder.allocator),
            .generated_file = undefined,
        };
        build_res.generated_file = .{ .step = &build_res.step };

        for (build_options.app.res) |res| {
            if (!res.embedded) {
                builder.pushInstalledFile(.lib, res.path);
            }
        }

        return build_res;
    }

    fn make(step: *std.build.Step) !void {
        const build_res = @fieldParentPtr(BuildResStep, "step", step);

        const res_dir_path = try std.fs.path.join(
            build_res.builder.allocator,
            &.{ build_res.builder.build_root, build_res.build_options.app.res_dir },
        );
        defer build_res.builder.allocator.free(res_dir_path);

        var res_dir = try std.fs.cwd().openDir(res_dir_path, .{});
        defer res_dir.close();

        const out_dir_path = try std.fs.path.join(
            build_res.builder.allocator,
            &.{
                build_res.builder.build_root,
                build_res.builder.cache_root,
                "res",
            },
        );
        defer build_res.builder.allocator.free(out_dir_path);

        var out_dir = try std.fs.cwd().makeOpenPath(out_dir_path, .{});
        defer out_dir.close();

        var lib_dir = try std.fs.cwd().makeOpenPath(build_res.builder.lib_dir, .{});
        defer lib_dir.close();

        const writer = build_res.contents.writer();
        try writer.print("const cc = @import(\"cupcake\");\n", .{});

        var total_file_id: usize = 0;
        var total_file_size: usize = 0;
        for (build_res.build_options.app.res) |res| {
            const res_bytes = switch (res.kind) {
                .shader => try build_res.buildShader(&res_dir, res),
            };
            defer build_res.builder.allocator.free(res_bytes);

            const res_name = try std.mem.concat(
                build_res.builder.allocator,
                u8,
                &.{ @tagName(res.kind), "_", filenameNoExt(res.path) },
            );
            defer build_res.builder.allocator.free(res_name);

            try writer.print("pub const {s} = cc.res.Resource{{ ", .{res_name});
            try writer.print(".kind = .{s}, ", .{@tagName(res.kind)});
            if (res.embedded) {
                try writer.print(
                    ".data = .{{ .embedded = @embedFile(\"{s}\") }} ",
                    .{res.path},
                );
                try out_dir.writeFile(res.path, res_bytes);
            } else {
                try writer.print(
                    ".data = .{{ .file = .{{ .id = {}, .path = \"{s}\", .size = {} }} }} ",
                    .{ total_file_id, res.path, res_bytes.len },
                );
                try lib_dir.writeFile(res.path, res_bytes);
                total_file_id += 1;
                total_file_size += res_bytes.len;
            }
            try writer.print("}};\n", .{});
        }
        try writer.print("pub const total_file_count = {};\n", .{total_file_id});
        try writer.print("pub const total_file_size = {};\n", .{total_file_size});

        const gen_filename = try std.mem.concat(
            build_res.builder.allocator,
            u8,
            &.{ build_res.build_options.app.name, ".zig" },
        );
        defer build_res.builder.allocator.free(gen_filename);

        try out_dir.writeFile(gen_filename, build_res.contents.items);
        build_res.contents.deinit();

        build_res.generated_file.path = try out_dir.realpathAlloc(
            build_res.builder.allocator,
            gen_filename,
        );
    }

    fn buildShader(
        build_res: *BuildResStep,
        res_dir: *std.fs.Dir,
        res: build_app.BuildResource,
    ) ![]const u8 {
        const shader_file = try res_dir.openFile(res.path, .{});
        defer shader_file.close();

        const shader_bytes = try shader_file.readToEndAlloc(
            build_res.builder.allocator,
            (try shader_file.stat()).size,
        );
        defer build_res.builder.allocator.free(shader_bytes);

        return try minify.shader(
            shader_bytes,
            build_res.builder.allocator,
            build_res.build_options.opt_level,
            build_res.build_options.gfx_api,
        );
    }

    fn filenameNoExt(path: []const u8) []const u8 {
        const filename = std.fs.path.basename(path);
        const index = std.mem.lastIndexOfScalar(u8, filename, '.') orelse return path[0..];
        if (index == 0) return path[path.len..];
        return filename[0..index];
    }
};
