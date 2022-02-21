const builtin = @import("builtin");
const std = @import("std");

pub const Platform = enum {
    web,

    pub usingnamespace JsonEnumString(@This());
};

pub const LogLevel = enum {
    debug,
    warn,
    err,
    disabled,

    pub usingnamespace JsonEnumString(@This());
};

pub const OptLevel = enum {
    debug,
    profile,
    release,

    pub usingnamespace JsonEnumString(@This());

    pub fn getLogLevel(opt_level: OptLevel) LogLevel {
        return switch (opt_level) {
            .debug => .debug,
            .profile => .err,
            .release => .disabled,
        };
    }

    pub fn getBuildMode(opt_level: OptLevel) std.builtin.Mode {
        return switch (opt_level) {
            .debug => .Debug,
            .profile => .ReleaseSafe,
            .release => .ReleaseFast,
        };
    }
};

pub const GfxApi = enum {
    webgpu,

    pub usingnamespace JsonEnumString(GfxApi);
};

pub const ManifestRes = struct {
    res_type: ResType,
    file_type: FileType,
    path: []const u8,

    pub const ResType = enum {
        shader,
        texture,

        pub usingnamespace JsonEnumString(@This());
    };

    pub const FileType = enum {
        embedded,
        file,

        pub usingnamespace JsonEnumString(@This());
    };
};

pub const ManifestDesc = struct {
    name: []const u8,
    root: []const u8,
    res_dir: []const u8 = "",
    res: []const ManifestRes = &.{},
};

pub const Manifest = struct {
    name: []const u8,
    root: []const u8,
    res_dir: []const u8,
    res: []const ManifestRes,
    platform: Platform,
    opt_level: OptLevel,
    gfx_api: GfxApi,
    log_level: LogLevel,
    build_root_path: []const u8,
    install_prefix: []const u8,
    dest_dir: []const u8,
    out_path: []const u8,
    pkg_path: []const u8,

    fn init(builder: *std.build.Builder, desc: ManifestDesc) !Manifest {
        var build_manifest: Manifest = undefined;
        build_manifest.name = desc.name;
        build_manifest.root = desc.root;
        build_manifest.res_dir = desc.res_dir;
        build_manifest.res = desc.res;
        build_manifest.platform = builder.option(
            Platform,
            "platform",
            "target platform",
        ) orelse default_platform;
        build_manifest.opt_level = builder.option(
            OptLevel,
            "opt",
            "optimization level",
        ) orelse default_opt_level;
        build_manifest.gfx_api = builder.option(
            GfxApi,
            "gfx",
            "graphics backend",
        ) orelse default_gfx_api;
        build_manifest.log_level = builder.option(
            LogLevel,
            "log_level",
            "log level",
        ) orelse build_manifest.opt_level.getLogLevel();

        build_manifest.build_root_path = builder.build_root;
        build_manifest.install_prefix = builder.install_prefix;
        build_manifest.dest_dir = try std.fs.path.join(
            builder.allocator,
            &.{ build_manifest.name, @tagName(build_manifest.platform) },
        );

        const manifest_dir_path = try std.fs.path.join(
            builder.allocator,
            &.{
                builder.build_root,
                builder.cache_root,
                "res",
                build_manifest.name,
            },
        );
        defer builder.allocator.free(manifest_dir_path);

        const manifest_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{
                build_manifest.name,
                "_",
                @tagName(build_manifest.platform),
                "_",
                @tagName(build_manifest.gfx_api),
            },
        );
        defer builder.allocator.free(manifest_name);

        const out_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{ manifest_name, ".manifest" },
        );
        defer builder.allocator.free(out_name);

        const pkg_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{ manifest_name, ".zig" },
        );
        defer builder.allocator.free(pkg_name);

        build_manifest.out_path = try std.fs.path.join(
            builder.allocator,
            &.{
                manifest_dir_path,
                out_name,
            },
        );
        build_manifest.pkg_path = try std.fs.path.join(
            builder.allocator,
            &.{
                manifest_dir_path,
                pkg_name,
            },
        );

        return build_manifest;
    }
};

const default_platform = .web;
const default_opt_level = .debug;
const default_gfx_api = .webgpu;

pub fn build(builder: *std.build.Builder, desc: ManifestDesc) !void {
    var build_manifest = try Manifest.init(builder, desc);

    try buildRes(builder, build_manifest);
    try buildApp(builder, build_manifest);
}

fn buildRes(builder: *std.build.Builder, manifest: Manifest) !void {
    const write_manifest_step = try WriteManifestStep.init(builder, manifest);
    const header_only_libs = [_]HeaderOnlyLib{
        .{ .define = "STB_IMAGE_IMPLEMENTATION", .path = "stb_image.h" },
    };
    const header_only_libs_step = try HeaderOnlyLibStep.init(builder, &header_only_libs);

    const build_res_exe = builder.addExecutable("build_res", "src/build_res.zig");
    build_res_exe.setBuildMode(.ReleaseSafe);
    build_res_exe.setTarget(std.zig.CrossTarget.fromTarget(builtin.target));
    build_res_exe.linkLibC();
    build_res_exe.addIncludeDir("ext/stb");
    build_res_exe.addCSourceFileSource(header_only_libs_step.getCSourceFile());
    build_res_exe.step.dependOn(&header_only_libs_step.step);

    var build_res_run = build_res_exe.run();
    build_res_run.step.dependOn(&write_manifest_step.step);
    build_res_run.addArg(manifest.out_path);

    const build_res_step = builder.step("res", "Build resources");
    build_res_step.dependOn(&build_res_run.step);
}

fn buildApp(builder: *std.build.Builder, manifest: Manifest) !void {
    const app_lib_exe = switch (manifest.platform) {
        .web => try buildWeb(builder, manifest),
    };
    app_lib_exe.setBuildMode(manifest.opt_level.getBuildMode());
    app_lib_exe.override_dest_dir = .{ .custom = manifest.dest_dir };

    const cfg = builder.addOptions();
    cfg.addOption(Platform, "platform", manifest.platform);
    cfg.addOption(GfxApi, "gfx_api", manifest.gfx_api);
    cfg.addOption(OptLevel, "opt_level", manifest.opt_level);
    cfg.addOption(LogLevel, "log_level", manifest.log_level);
    app_lib_exe.step.dependOn(&cfg.step);

    const cfg_pkg = cfg.getPackage("cfg");
    const cupcake_pkg = std.build.Pkg{
        .name = "cupcake",
        .path = .{ .path = "src/cupcake.zig" },
        .dependencies = &.{cfg_pkg},
    };
    const res_pkg = std.build.Pkg{
        .name = "res",
        .path = .{ .path = manifest.pkg_path },
        .dependencies = &.{cupcake_pkg},
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = manifest.root },
        .dependencies = &.{ cfg_pkg, res_pkg, cupcake_pkg },
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(cupcake_pkg);
    app_lib_exe.addPackage(app_pkg);

    app_lib_exe.install();
}

fn buildWeb(
    builder: *std.build.Builder,
    build_manifest: Manifest,
) !*std.build.LibExeObjStep {
    const app_lib_exe = builder.addSharedLibrary(
        build_manifest.name,
        "src/main.zig",
        .unversioned,
    );

    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });
    app_lib_exe.setTarget(target);

    return app_lib_exe;
}

const WriteManifestStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    manifest: Manifest,

    pub fn init(builder: *std.build.Builder, manifest: Manifest) !*WriteManifestStep {
        const write_manifest = try builder.allocator.create(WriteManifestStep);
        write_manifest.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "write manifest", builder.allocator, make),
            .manifest = manifest,
        };
        return write_manifest;
    }

    fn make(step: *std.build.Step) !void {
        const write_manifest = @fieldParentPtr(WriteManifestStep, "step", step);

        var manifest_contents = std.ArrayList(u8).init(write_manifest.builder.allocator);
        defer manifest_contents.deinit();

        try std.json.stringify(write_manifest.manifest, .{}, manifest_contents.writer());

        if (std.fs.path.dirname(write_manifest.manifest.out_path)) |dir| {
            try std.fs.cwd().makePath(dir);
        }
        try std.fs.cwd().writeFile(
            write_manifest.manifest.out_path,
            manifest_contents.items,
        );
    }
};

const HeaderOnlyLib = struct {
    define: []const u8,
    path: []const u8,
};

const HeaderOnlyLibStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    libs: []const HeaderOnlyLib,
    generated_file: std.build.GeneratedFile,

    pub fn init(builder: *std.build.Builder, libs: []const HeaderOnlyLib) !*HeaderOnlyLibStep {
        const header = try builder.allocator.create(HeaderOnlyLibStep);
        header.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "build c header libs", builder.allocator, make),
            .libs = libs,
            .generated_file = undefined,
        };
        header.generated_file = .{ .step = &header.step };
        return header;
    }

    fn make(step: *std.build.Step) !void {
        const header = @fieldParentPtr(HeaderOnlyLibStep, "step", step);

        var impl_contents = std.ArrayList(u8).init(header.builder.allocator);
        defer impl_contents.deinit();

        const writer = impl_contents.writer();
        for (header.libs) |lib| {
            try writer.print("#define {s}\n", .{lib.define});
            try writer.print("#include \"{s}\"\n", .{lib.path});
        }

        const out_path = try std.fs.path.join(
            header.builder.allocator,
            &.{ header.builder.build_root, header.builder.cache_root, "header_only_libs.c" },
        );
        defer header.builder.allocator.free(out_path);

        try std.fs.cwd().writeFile(out_path, impl_contents.items);
        header.generated_file.path = try header.builder.allocator.dupe(u8, out_path);
    }

    pub fn getCSourceFile(header: HeaderOnlyLibStep) std.build.CSourceFile {
        return .{ .source = .{ .generated = &header.generated_file }, .args = &.{} };
    }
};

fn JsonEnumString(comptime Enum: type) type {
    return struct {
        pub fn jsonStringify(
            e: Enum,
            options: std.json.StringifyOptions,
            out_stream: anytype,
        ) !void {
            return std.json.stringify(@tagName(e), options, out_stream);
        }
    };
}
