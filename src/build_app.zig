const builtin = @import("builtin");
const serde = @import("serde.zig");
const std = @import("std");

pub const Platform = enum(u8) {
    web,
};

pub const LogLevel = enum(u8) {
    debug,
    warn,
    err,
    disabled,
};

pub const OptLevel = enum(u8) {
    debug,
    profile,
    release,

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

pub const GfxApi = enum(u8) {
    webgpu,
};

pub const ManifestRes = struct {
    res_type: ResType,
    file_type: FileType,
    path: []const u8,

    pub const ResType = enum(u8) {
        shader,
        texture,
    };

    pub const FileType = enum(u8) {
        embedded,
        file,
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
    gen_lib_dir: []const u8,
    gen_tools_dir: []const u8,
    dest_dir: []const u8,
    out_path: []const u8,
    pkg_path: []const u8,

    fn init(builder: *std.build.Builder, desc: ManifestDesc) !Manifest {
        var manifest: Manifest = undefined;
        manifest.name = desc.name;
        manifest.root = desc.root;
        manifest.res_dir = desc.res_dir;
        manifest.res = desc.res;
        manifest.platform = builder.option(
            Platform,
            "platform",
            "target platform",
        ) orelse default_platform;
        manifest.opt_level = builder.option(
            OptLevel,
            "opt",
            "optimization level",
        ) orelse default_opt_level;
        manifest.gfx_api = builder.option(
            GfxApi,
            "gfx",
            "graphics backend",
        ) orelse default_gfx_api;
        manifest.log_level = builder.option(
            LogLevel,
            "log_level",
            "log level",
        ) orelse manifest.opt_level.getLogLevel();

        manifest.build_root_path = builder.build_root;
        manifest.install_prefix = builder.install_prefix;

        const gen_dir = try std.fs.path.join(builder.allocator, &.{ builder.build_root, "gen" });
        defer builder.allocator.free(gen_dir);

        manifest.gen_lib_dir = try std.fs.path.join(builder.allocator, &.{ gen_dir, "lib" });
        manifest.gen_tools_dir = try std.fs.path.join(builder.allocator, &.{ gen_dir, "tools" });

        manifest.dest_dir = try std.fs.path.join(
            builder.allocator,
            &.{ manifest.name, @tagName(manifest.platform) },
        );

        const manifest_dir_path = try std.fs.path.join(
            builder.allocator,
            &.{
                builder.build_root,
                "gen",
                "res",
                manifest.name,
            },
        );
        defer builder.allocator.free(manifest_dir_path);

        const manifest_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{
                manifest.name,
                "_",
                @tagName(manifest.platform),
                "_",
                @tagName(manifest.gfx_api),
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

        manifest.out_path = try std.fs.path.join(
            builder.allocator,
            &.{
                manifest_dir_path,
                out_name,
            },
        );
        manifest.pkg_path = try std.fs.path.join(
            builder.allocator,
            &.{
                manifest_dir_path,
                pkg_name,
            },
        );

        return manifest;
    }
};

const default_platform = .web;
const default_opt_level = .debug;
const default_gfx_api = .webgpu;

pub fn build(builder: *std.build.Builder, desc: ManifestDesc) !void {
    var manifest = try Manifest.init(builder, desc);

    try buildExt(builder, manifest);
    try buildRes(builder, manifest);
    try buildApp(builder, manifest);
}

fn buildExt(builder: *std.build.Builder, manifest: Manifest) !void {
    try std.fs.cwd().makePath(manifest.gen_lib_dir);
    try std.fs.cwd().makePath(manifest.gen_tools_dir);

    const header_only_libs = [_]HeaderOnlyLib{
        .{ .path = "ext/stb/stb_image.h", .define = "STB_IMAGE_IMPLEMENTATION" },
    };
    const header_only_step = try HeaderOnlyStep.init(builder, manifest, &header_only_libs);
    const header_only = builder.addStaticLibrary(HeaderOnlyStep.lib_name, null);
    header_only.setBuildMode(.ReleaseFast);
    header_only.linkLibC();
    header_only.addIncludePath(builder.build_root);
    header_only.addCSourceFileSource(header_only_step.getCSourceFile());
    header_only.setOutputDir(manifest.gen_lib_dir);
    header_only.step.dependOn(&header_only_step.step);

    comptime var freetype_srcs: []const []const u8 = &.{
        "ext/freetype/src/autofit/autofit.c",
        "ext/freetype/src/base/ftbase.c",
        "ext/freetype/src/base/ftbbox.c",
        "ext/freetype/src/base/ftbdf.c",
        "ext/freetype/src/base/ftbitmap.c",
        "ext/freetype/src/base/ftcid.c",
        "ext/freetype/src/base/ftfstype.c",
        "ext/freetype/src/base/ftgasp.c",
        "ext/freetype/src/base/ftglyph.c",
        "ext/freetype/src/base/ftgxval.c",
        "ext/freetype/src/base/ftinit.c",
        "ext/freetype/src/base/ftmm.c",
        "ext/freetype/src/base/ftotval.c",
        "ext/freetype/src/base/ftpatent.c",
        "ext/freetype/src/base/ftpfr.c",
        "ext/freetype/src/base/ftstroke.c",
        "ext/freetype/src/base/ftsynth.c",
        "ext/freetype/src/base/fttype1.c",
        "ext/freetype/src/base/ftwinfnt.c",
        "ext/freetype/src/bdf/bdf.c",
        "ext/freetype/src/bzip2/ftbzip2.c",
        "ext/freetype/src/cache/ftcache.c",
        "ext/freetype/src/cff/cff.c",
        "ext/freetype/src/cid/type1cid.c",
        "ext/freetype/src/gzip/ftgzip.c",
        "ext/freetype/src/lzw/ftlzw.c",
        "ext/freetype/src/pcf/pcf.c",
        "ext/freetype/src/pfr/pfr.c",
        "ext/freetype/src/psaux/psaux.c",
        "ext/freetype/src/pshinter/pshinter.c",
        "ext/freetype/src/psnames/psnames.c",
        "ext/freetype/src/raster/raster.c",
        "ext/freetype/src/sdf/sdf.c",
        "ext/freetype/src/sfnt/sfnt.c",
        "ext/freetype/src/smooth/smooth.c",
        "ext/freetype/src/svg/svg.c",
        "ext/freetype/src/truetype/truetype.c",
        "ext/freetype/src/type1/type1.c",
        "ext/freetype/src/type42/type42.c",
        "ext/freetype/src/winfonts/winfnt.c",
    };
    comptime var freetype_flags: []const []const u8 = &.{"-DFT2_BUILD_LIBRARY"};
    switch (builtin.target.os.tag) {
        .windows => {
            freetype_srcs = freetype_srcs ++ &[_][]const u8{
                "ext/freetype/builds/windows/ftsystem.c",
                "ext/freetype/builds/windows/ftdebug.c",
            };
        },
        else => @compileError("Unsupported platform!"),
    }

    const freetype = builder.addStaticLibrary("freetype", null);
    freetype.setBuildMode(.ReleaseFast);
    freetype.linkLibC();
    freetype.addIncludePath("ext/freetype/include");
    freetype.addCSourceFiles(freetype_srcs, freetype_flags);

    const msdfgen_srcs: []const []const u8 = &.{
        "ext/msdf-atlas-gen/msdfgen/core/Contour.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/contour-combiners.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/edge-coloring.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/EdgeHolder.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/edge-segments.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/edge-selectors.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/equation-solver.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/MSDFErrorCorrection.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/msdf-error-correction.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/msdfgen.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/Projection.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/rasterization.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/render-sdf.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/save-bmp.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/save-tiff.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/Scanline.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/sdf-error-estimation.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/Shape.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/shape-description.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/SignedDistance.cpp",
        "ext/msdf-atlas-gen/msdfgen/core/Vector2.cpp",
        "ext/msdf-atlas-gen/msdfgen/ext/import-font.cpp",
        "ext/msdf-atlas-gen/msdfgen/ext/import-svg.cpp",
        "ext/msdf-atlas-gen/msdfgen/ext/resolve-shape-geometry.cpp",
        "ext/msdf-atlas-gen/msdfgen/ext/save-png.cpp",
        "ext/msdf-atlas-gen/msdfgen/lib/lodepng.cpp",
        "ext/msdf-atlas-gen/msdfgen/lib/tinyxml2.cpp",
    };
    const msdfgen_flags: []const []const u8 = &.{"-std=c++11"};

    const msdfgen = builder.addStaticLibrary("msdfgen", null);
    msdfgen.setBuildMode(.ReleaseFast);
    msdfgen.linkLibCpp();
    msdfgen.addIncludePath("ext/freetype/include");
    msdfgen.addIncludePath("ext/msdf-atlas-gen/msdfgen/include");
    msdfgen.addCSourceFiles(msdfgen_srcs, msdfgen_flags);

    const msdf_atlas_gen_srcs: []const []const u8 = &.{
        "ext/msdf-atlas-gen/msdf-atlas-gen/artery-font-export.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/bitmap-blit.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/Charset.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/charset-parser.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/csv-export.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/FontGeometry.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/glyph-generators.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/GlyphGeometry.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/image-encode.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/json-export.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/main.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/RectanglePacker.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/shadron-preview-generator.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/size-selectors.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/TightAtlasPacker.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/utf8.cpp",
        "ext/msdf-atlas-gen/msdf-atlas-gen/Workload.cpp",
    };
    const msdf_atlas_gen_flags: []const []const u8 = &.{"-DMSDF_ATLAS_STANDALONE"};

    const msdf_atlas_gen = builder.addExecutable("msdf-atlas-gen", null);
    msdf_atlas_gen.setBuildMode(.ReleaseFast);
    msdf_atlas_gen.addIncludePath("ext/msdf-atlas-gen/msdfgen");
    msdf_atlas_gen.addIncludePath("ext/msdf-atlas-gen/msdfgen/include");
    msdf_atlas_gen.addIncludePath("ext/msdf-atlas-gen/artery-font-format");
    msdf_atlas_gen.linkLibCpp();
    msdf_atlas_gen.linkLibrary(msdfgen);
    msdf_atlas_gen.linkLibrary(freetype);
    msdf_atlas_gen.addCSourceFiles(msdf_atlas_gen_srcs, msdf_atlas_gen_flags);
    msdf_atlas_gen.setOutputDir(manifest.gen_tools_dir);

    const build_ext_step = builder.step("ext", "Build external dependencies");
    build_ext_step.dependOn(&header_only.step);
    build_ext_step.dependOn(&msdf_atlas_gen.step);
}

fn buildRes(builder: *std.build.Builder, manifest: Manifest) !void {
    const build_res_exe = builder.addExecutable("build_res", "src/build_res.zig");
    build_res_exe.setBuildMode(.ReleaseSafe);
    build_res_exe.setTarget(std.zig.CrossTarget.fromTarget(builtin.target));
    build_res_exe.linkLibC();
    build_res_exe.addIncludePath("ext/stb");
    build_res_exe.addLibraryPath(manifest.gen_lib_dir);
    build_res_exe.linkSystemLibrary(HeaderOnlyStep.lib_name);

    var build_res_run = build_res_exe.run();
    const write_manifest_step = try WriteManifestStep.init(builder, manifest);
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

        const manifest_bytes = try serde.serialize(
            write_manifest.manifest,
            write_manifest.builder.allocator,
        );

        if (std.fs.path.dirname(write_manifest.manifest.out_path)) |dir| {
            try std.fs.cwd().makePath(dir);
        }
        try std.fs.cwd().writeFile(write_manifest.manifest.out_path, manifest_bytes);
    }
};

const HeaderOnlyLib = struct {
    path: []const u8,
    define: []const u8,
};

const HeaderOnlyStep = struct {
    const lib_name = "header_only";

    builder: *std.build.Builder,
    manifest: Manifest,
    step: std.build.Step,
    libs: []const HeaderOnlyLib,
    generated_file: std.build.GeneratedFile,

    fn init(
        builder: *std.build.Builder,
        manifest: Manifest,
        libs: []const HeaderOnlyLib,
    ) !*HeaderOnlyStep {
        const header_only_step = try builder.allocator.create(HeaderOnlyStep);
        header_only_step.* = .{
            .builder = builder,
            .manifest = manifest,
            .step = std.build.Step.init(.custom, "header only libs", builder.allocator, make),
            .libs = libs,
            .generated_file = undefined,
        };
        header_only_step.generated_file = .{ .step = &header_only_step.step };
        return header_only_step;
    }

    fn make(step: *std.build.Step) !void {
        const header = @fieldParentPtr(HeaderOnlyStep, "step", step);

        var impl_contents = std.ArrayList(u8).init(header.builder.allocator);
        defer impl_contents.deinit();

        const writer = impl_contents.writer();
        for (header.libs) |lib| {
            try writer.print("#define {s}\n", .{lib.define});
            try writer.print("#include \"{s}\"\n", .{lib.path});
        }

        const out_name = try std.mem.concat(header.builder.allocator, u8, &.{ lib_name, ".c" });
        defer header.builder.allocator.free(out_name);
        const out_path = try std.fs.path.join(header.builder.allocator, &.{
            header.manifest.gen_lib_dir, out_name,
        });
        defer header.builder.allocator.free(out_path);

        try std.fs.cwd().writeFile(out_path, impl_contents.items);
        header.generated_file.path = try header.builder.allocator.dupe(u8, out_path);
    }

    fn getCSourceFile(header: HeaderOnlyStep) std.build.CSourceFile {
        return std.build.CSourceFile{
            .source = .{ .generated = &header.generated_file },
            .args = &.{},
        };
    }
};
