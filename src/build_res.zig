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

        return build_res;
    }

    fn make(step: *std.build.Step) !void {
        const build_res = @fieldParentPtr(BuildResStep, "step", step);

        const shader_dir_path = try std.fs.path.join(
            build_res.builder.allocator,
            &.{ build_res.builder.build_root, build_res.build_options.app.shader_dir },
        );
        defer build_res.builder.allocator.free(shader_dir_path);

        var shader_dir = try std.fs.openDirAbsolute(shader_dir_path, .{});
        defer shader_dir.close();

        const writer = build_res.contents.writer();
        for (build_res.build_options.app.shader_names) |shader_name| {
            const shader_ext = switch (build_res.build_options.gfx_api) {
                .webgpu => ".wgsl",
            };

            const shader_path = try std.mem.concat(
                build_res.builder.allocator,
                u8,
                &.{ shader_name, shader_ext },
            );
            defer build_res.builder.allocator.free(shader_path);

            const shader_file = try shader_dir.openFile(shader_path, .{});
            defer shader_file.close();

            const shader_bytes = try shader_file.readToEndAlloc(
                build_res.builder.allocator,
                (try shader_file.stat()).size,
            );
            defer build_res.builder.allocator.free(shader_bytes);

            const shader_bytes_min = try minify.shader(
                shader_bytes,
                build_res.builder.allocator,
                build_res.build_options.opt_level,
                build_res.build_options.gfx_api,
            );
            defer build_res.builder.allocator.free(shader_bytes_min);

            try writer.print("pub const {s} = \"{s}\";\n", .{ shader_name, shader_bytes_min });
        }

        const build_res_dir_path = try std.fs.path.join(
            build_res.builder.allocator,
            &.{
                build_res.builder.build_root,
                build_res.builder.cache_root,
                "build_res",
            },
        );
        defer build_res.builder.allocator.free(build_res_dir_path);

        try std.fs.cwd().makePath(build_res_dir_path);

        const build_res_src_file_name = try std.mem.concat(
            build_res.builder.allocator,
            u8,
            &.{
                build_res.build_options.app.name,
                "_",
                @tagName(build_res.build_options.gfx_api),
            },
        );
        defer build_res.builder.allocator.free(build_res_src_file_name);

        const build_res_src_file_path = try std.fs.path.join(
            build_res.builder.allocator,
            &.{ build_res_dir_path, build_res_src_file_name },
        );
        defer build_res.builder.allocator.free(build_res_src_file_path);

        try std.fs.cwd().writeFile(build_res_src_file_path, build_res.contents.items);
        build_res.contents.deinit();

        build_res.generated_file.path = try std.mem.Allocator.dupe(
            build_res.builder.allocator,
            u8,
            build_res_src_file_path,
        );
    }

    pub fn getPackage(build_res: BuildResStep, package_name: []const u8) std.build.Pkg {
        return .{
            .name = package_name,
            .path = std.build.FileSource{ .generated = &build_res.generated_file },
        };
    }
};
