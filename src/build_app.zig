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

pub const ManifestRes = struct {
    path: []const u8,
    embed: bool = false,
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
    log_level: LogLevel,
    build_root_dir: []const u8,
    install_dir: []const u8,
    ext_dir: []const u8,
    gen_dir: []const u8,
    gen_lib_dir: []const u8,
    gen_tools_dir: []const u8,
    dest_dir: []const u8,
    out_path: []const u8,
    pkg_path: []const u8,

    fn init(builder: *std.build.Builder, desc: ManifestDesc) !Manifest {
        var manifest: Manifest = undefined;
        try manifest.setOptionFields(builder);
        try manifest.setNonOptionFields(builder, desc);
        return manifest;
    }

    fn initDupe(manifest: Manifest, builder: *std.build.Builder, desc: ManifestDesc) !Manifest {
        var dupe_manifest: Manifest = undefined;
        try dupe_manifest.dupeOptionFields(manifest, builder);
        try dupe_manifest.setNonOptionFields(builder, desc);
        return dupe_manifest;
    }

    fn setOptionFields(manifest: *Manifest, builder: *std.build.Builder) !void {
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
        manifest.log_level = builder.option(
            LogLevel,
            "log_level",
            "threshold for logging to console",
        ) orelse manifest.opt_level.getLogLevel();

        const cache_gen_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.cache_root, "gen" },
        );
        defer builder.allocator.free(cache_gen_dir);

        const cache_ext_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.cache_root, "ext" },
        );
        defer builder.allocator.free(cache_ext_dir);

        const gen_dir_rel = builder.option(
            []const u8,
            "gen_dir",
            "dir for generated files, relative to the build root",
        ) orelse cache_gen_dir;

        const ext_dir_rel = builder.option(
            []const u8,
            "ext_dir",
            "dir for external repositories, relative to the build root",
        ) orelse cache_ext_dir;

        manifest.ext_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.build_root, ext_dir_rel },
        );

        manifest.gen_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.build_root, gen_dir_rel },
        );
        manifest.gen_lib_dir = try std.fs.path.join(
            builder.allocator,
            &.{ manifest.gen_dir, "lib" },
        );
        manifest.gen_tools_dir = try std.fs.path.join(
            builder.allocator,
            &.{ manifest.gen_dir, "tools" },
        );
    }

    fn dupeOptionFields(
        dupe_manifest: *Manifest,
        manifest: Manifest,
        builder: *std.build.Builder,
    ) !void {
        dupe_manifest.platform = manifest.platform;
        dupe_manifest.opt_level = manifest.opt_level;
        dupe_manifest.log_level = manifest.log_level;
        dupe_manifest.ext_dir = try builder.allocator.dupe(u8, manifest.ext_dir);
        dupe_manifest.gen_dir = try builder.allocator.dupe(u8, manifest.gen_dir);
        dupe_manifest.gen_lib_dir = try builder.allocator.dupe(u8, manifest.gen_lib_dir);
        dupe_manifest.gen_tools_dir = try builder.allocator.dupe(u8, manifest.gen_tools_dir);
    }

    fn setNonOptionFields(
        manifest: *Manifest,
        builder: *std.build.Builder,
        desc: ManifestDesc,
    ) !void {
        manifest.name = desc.name;
        manifest.root = desc.root;
        manifest.res_dir = desc.res_dir;
        manifest.res = desc.res;

        manifest.build_root_dir = builder.build_root;
        manifest.dest_dir = try std.fs.path.join(
            builder.allocator,
            &.{ manifest.name, @tagName(manifest.platform) },
        );
        manifest.install_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.install_prefix, manifest.dest_dir },
        );

        const manifest_dir_path = try std.fs.path.join(
            builder.allocator,
            &.{ manifest.gen_dir, "res", manifest.name },
        );
        defer builder.allocator.free(manifest_dir_path);

        const manifest_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{ manifest.name, "_", @tagName(manifest.platform) },
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
            &.{ manifest_name, "_res.zig" },
        );
        defer builder.allocator.free(pkg_name);

        manifest.out_path = try std.fs.path.join(
            builder.allocator,
            &.{ manifest_dir_path, out_name },
        );
        manifest.pkg_path = try std.fs.path.join(
            builder.allocator,
            &.{ manifest_dir_path, pkg_name },
        );
    }
};

const default_platform = .web;
const default_opt_level = .debug;

pub fn build(builder: *std.build.Builder, desc: ManifestDesc) !void {
    var manifest = try Manifest.init(builder, desc);

    const cc_manifest_desc: ManifestDesc = .{
        .name = "cc",
        .root = "",
        .res_dir = ".",
        .res = &.{},
    };
    const cc_manifest = try manifest.initDupe(builder, cc_manifest_desc);

    try buildExt(builder, manifest);
    try buildRes(builder, manifest, cc_manifest);
    try buildApp(builder, manifest, cc_manifest);
}

fn buildExt(builder: *std.build.Builder, manifest: Manifest) !void {
    try std.fs.cwd().makePath(manifest.ext_dir);
    try std.fs.cwd().makePath(manifest.gen_lib_dir);
    try std.fs.cwd().makePath(manifest.gen_tools_dir);

    const ext_repos = [_]ExtRepo{
        .{
            .url = "https://gitlab.freedesktop.org/freetype/freetype.git",
            .commit = "1e2eb65048f75c64b68708efed6ce904c31f3b2f",
        },
        .{
            .url = "https://github.com/Chlumsky/msdf-atlas-gen.git",
            .commit = "50d1a1c275e78ee08afafbead2a2d347aa26f122",
            .clone_recursive = true,
        },
        .{
            .url = "https://github.com/nothings/stb.git",
            .commit = "af1a5bc352164740c1cc1354942b1c6b72eacb8a",
        },
    };
    const clone_ext_repos = try CloneExtReposStep.init(builder, manifest, &ext_repos);

    const header_only_libs = [_]HeaderOnlyLib{
        .{ .path = "stb/stb_image.h", .define = "STB_IMAGE_IMPLEMENTATION" },
    };
    const header_only_step = try HeaderOnlyStep.init(builder, manifest, &header_only_libs);
    header_only_step.step.dependOn(&clone_ext_repos.step);

    const header_only = builder.addStaticLibrary(HeaderOnlyStep.lib_name, null);
    header_only.setBuildMode(.ReleaseFast);
    header_only.linkLibC();
    header_only.addIncludePath(manifest.ext_dir);
    header_only.addCSourceFileSource(header_only_step.getCSourceFile());
    header_only.setOutputDir(manifest.gen_lib_dir);
    header_only.step.dependOn(&header_only_step.step);

    comptime var freetype_srcs: []const []const u8 = &.{
        "freetype/src/autofit/autofit.c",
        "freetype/src/base/ftbase.c",
        "freetype/src/base/ftbbox.c",
        "freetype/src/base/ftbdf.c",
        "freetype/src/base/ftbitmap.c",
        "freetype/src/base/ftcid.c",
        "freetype/src/base/ftfstype.c",
        "freetype/src/base/ftgasp.c",
        "freetype/src/base/ftglyph.c",
        "freetype/src/base/ftgxval.c",
        "freetype/src/base/ftinit.c",
        "freetype/src/base/ftmm.c",
        "freetype/src/base/ftotval.c",
        "freetype/src/base/ftpatent.c",
        "freetype/src/base/ftpfr.c",
        "freetype/src/base/ftstroke.c",
        "freetype/src/base/ftsynth.c",
        "freetype/src/base/fttype1.c",
        "freetype/src/base/ftwinfnt.c",
        "freetype/src/bdf/bdf.c",
        "freetype/src/bzip2/ftbzip2.c",
        "freetype/src/cache/ftcache.c",
        "freetype/src/cff/cff.c",
        "freetype/src/cid/type1cid.c",
        "freetype/src/gzip/ftgzip.c",
        "freetype/src/lzw/ftlzw.c",
        "freetype/src/pcf/pcf.c",
        "freetype/src/pfr/pfr.c",
        "freetype/src/psaux/psaux.c",
        "freetype/src/pshinter/pshinter.c",
        "freetype/src/psnames/psnames.c",
        "freetype/src/raster/raster.c",
        "freetype/src/sdf/sdf.c",
        "freetype/src/sfnt/sfnt.c",
        "freetype/src/smooth/smooth.c",
        "freetype/src/svg/svg.c",
        "freetype/src/truetype/truetype.c",
        "freetype/src/type1/type1.c",
        "freetype/src/type42/type42.c",
        "freetype/src/winfonts/winfnt.c",
    };
    switch (builtin.target.os.tag) {
        .windows => {
            freetype_srcs = freetype_srcs ++ &[_][]const u8{
                "freetype/builds/windows/ftsystem.c",
                "freetype/builds/windows/ftdebug.c",
            };
        },
        else => @compileError("Unsupported platform!"),
    }
    const freetype_flags: []const []const u8 = &.{"-DFT2_BUILD_LIBRARY"};

    const freetype = builder.addStaticLibrary("freetype", null);
    freetype.setBuildMode(.ReleaseFast);
    freetype.linkLibC();
    try addIncludePathExt(builder, manifest, freetype, "freetype/include");
    try addCSourceFilesExt(builder, manifest, freetype, freetype_srcs, freetype_flags);
    freetype.step.dependOn(&clone_ext_repos.step);

    const msdfgen_srcs: []const []const u8 = &.{
        "msdf-atlas-gen/msdfgen/core/Contour.cpp",
        "msdf-atlas-gen/msdfgen/core/contour-combiners.cpp",
        "msdf-atlas-gen/msdfgen/core/edge-coloring.cpp",
        "msdf-atlas-gen/msdfgen/core/EdgeHolder.cpp",
        "msdf-atlas-gen/msdfgen/core/edge-segments.cpp",
        "msdf-atlas-gen/msdfgen/core/edge-selectors.cpp",
        "msdf-atlas-gen/msdfgen/core/equation-solver.cpp",
        "msdf-atlas-gen/msdfgen/core/MSDFErrorCorrection.cpp",
        "msdf-atlas-gen/msdfgen/core/msdf-error-correction.cpp",
        "msdf-atlas-gen/msdfgen/core/msdfgen.cpp",
        "msdf-atlas-gen/msdfgen/core/Projection.cpp",
        "msdf-atlas-gen/msdfgen/core/rasterization.cpp",
        "msdf-atlas-gen/msdfgen/core/render-sdf.cpp",
        "msdf-atlas-gen/msdfgen/core/save-bmp.cpp",
        "msdf-atlas-gen/msdfgen/core/save-tiff.cpp",
        "msdf-atlas-gen/msdfgen/core/Scanline.cpp",
        "msdf-atlas-gen/msdfgen/core/sdf-error-estimation.cpp",
        "msdf-atlas-gen/msdfgen/core/Shape.cpp",
        "msdf-atlas-gen/msdfgen/core/shape-description.cpp",
        "msdf-atlas-gen/msdfgen/core/SignedDistance.cpp",
        "msdf-atlas-gen/msdfgen/core/Vector2.cpp",
        "msdf-atlas-gen/msdfgen/ext/import-font.cpp",
        "msdf-atlas-gen/msdfgen/ext/import-svg.cpp",
        "msdf-atlas-gen/msdfgen/ext/resolve-shape-geometry.cpp",
        "msdf-atlas-gen/msdfgen/ext/save-png.cpp",
        "msdf-atlas-gen/msdfgen/lib/lodepng.cpp",
        "msdf-atlas-gen/msdfgen/lib/tinyxml2.cpp",
    };
    const msdfgen_flags: []const []const u8 = &.{"-std=c++11"};

    const msdfgen = builder.addStaticLibrary("msdfgen", null);
    msdfgen.setBuildMode(.ReleaseFast);
    msdfgen.linkLibCpp();
    try addIncludePathExt(builder, manifest, msdfgen, "freetype/include");
    try addIncludePathExt(builder, manifest, msdfgen, "msdf-atlas-gen/msdfgen/include");
    try addCSourceFilesExt(builder, manifest, msdfgen, msdfgen_srcs, msdfgen_flags);
    msdfgen.step.dependOn(&clone_ext_repos.step);

    const msdf_atlas_gen_srcs: []const []const u8 = &.{
        "msdf-atlas-gen/msdf-atlas-gen/artery-font-export.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/bitmap-blit.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/Charset.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/charset-parser.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/csv-export.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/FontGeometry.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/glyph-generators.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/GlyphGeometry.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/image-encode.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/json-export.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/main.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/RectanglePacker.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/shadron-preview-generator.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/size-selectors.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/TightAtlasPacker.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/utf8.cpp",
        "msdf-atlas-gen/msdf-atlas-gen/Workload.cpp",
    };
    const msdf_atlas_gen_flags: []const []const u8 = &.{"-DMSDF_ATLAS_STANDALONE"};

    const msdf_atlas_gen = builder.addExecutable("msdf-atlas-gen", null);
    msdf_atlas_gen.setBuildMode(.ReleaseFast);
    try addIncludePathExt(builder, manifest, msdf_atlas_gen, "msdf-atlas-gen/msdfgen");
    try addIncludePathExt(builder, manifest, msdf_atlas_gen, "msdf-atlas-gen/msdfgen/include");
    try addIncludePathExt(builder, manifest, msdf_atlas_gen, "msdf-atlas-gen/artery-font-format");
    try addCSourceFilesExt(
        builder,
        manifest,
        msdf_atlas_gen,
        msdf_atlas_gen_srcs,
        msdf_atlas_gen_flags,
    );
    msdf_atlas_gen.linkLibCpp();
    msdf_atlas_gen.linkLibrary(msdfgen);
    msdf_atlas_gen.linkLibrary(freetype);
    msdf_atlas_gen.setOutputDir(manifest.gen_tools_dir);

    const build_ext_step = builder.step("ext", "Build external dependencies");
    build_ext_step.dependOn(&header_only.step);
    build_ext_step.dependOn(&msdf_atlas_gen.step);
}

fn buildRes(builder: *std.build.Builder, manifest: Manifest, cc_manifest: Manifest) !void {
    const build_res_exe = builder.addExecutable("build_res", "src/build_res.zig");
    build_res_exe.setBuildMode(.ReleaseSafe);
    build_res_exe.linkLibC();
    build_res_exe.addIncludePath(manifest.ext_dir);
    build_res_exe.addLibraryPath(manifest.gen_lib_dir);
    build_res_exe.linkSystemLibrary(HeaderOnlyStep.lib_name);

    const write_cc_manifest = try WriteManifestStep.init(builder, cc_manifest);
    var build_cc_res = build_res_exe.run();
    build_cc_res.step.dependOn(&write_cc_manifest.step);
    build_cc_res.addArgs(&.{ cc_manifest.out_path, "false" });

    const write_app_manifest = try WriteManifestStep.init(builder, manifest);
    var build_app_res = build_res_exe.run();
    build_app_res.step.dependOn(&write_app_manifest.step);
    build_app_res.addArgs(&.{ manifest.out_path, "true" });

    const build_res_step = builder.step("res", "Build resources");
    build_res_step.dependOn(&build_cc_res.step);
    build_res_step.dependOn(&build_app_res.step);
}

fn buildApp(builder: *std.build.Builder, manifest: Manifest, cc_manifest: Manifest) !void {
    const app_lib_exe = switch (manifest.platform) {
        .web => try buildWeb(builder, manifest),
    };
    app_lib_exe.setBuildMode(manifest.opt_level.getBuildMode());
    app_lib_exe.override_dest_dir = .{ .custom = manifest.dest_dir };

    const cfg = builder.addOptions();
    cfg.addOption(Platform, "platform", manifest.platform);
    cfg.addOption(OptLevel, "opt_level", manifest.opt_level);
    cfg.addOption(LogLevel, "log_level", manifest.log_level);
    app_lib_exe.step.dependOn(&cfg.step);

    const cfg_pkg = cfg.getPackage("cfg");
    const cc_res_pkg = std.build.Pkg{
        .name = "cc_res",
        .path = .{ .path = cc_manifest.pkg_path },
    };
    const cupcake_pkg = std.build.Pkg{
        .name = "cupcake",
        .path = .{ .path = "src/cupcake.zig" },
        .dependencies = &.{ cfg_pkg, cc_res_pkg },
    };
    const res_pkg = std.build.Pkg{
        .name = "res",
        .path = .{ .path = manifest.pkg_path },
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = manifest.root },
        .dependencies = &.{ cfg_pkg, cupcake_pkg, res_pkg },
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(cupcake_pkg);
    app_lib_exe.addPackage(app_pkg);

    app_lib_exe.install();
}

fn buildWeb(
    builder: *std.build.Builder,
    manifest: Manifest,
) !*std.build.LibExeObjStep {
    const app_lib_exe = builder.addSharedLibrary(
        manifest.name,
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
            write_manifest.builder.allocator,
            write_manifest.manifest,
        );

        if (std.fs.path.dirname(write_manifest.manifest.out_path)) |dir| {
            try std.fs.cwd().makePath(dir);
        }
        try std.fs.cwd().writeFile(write_manifest.manifest.out_path, manifest_bytes);
    }
};

const ExtRepo = struct {
    url: []const u8,
    commit: []const u8,
    clone_recursive: bool = false,
};

const CloneExtReposStep = struct {
    step: std.build.Step,

    fn init(
        builder: *std.build.Builder,
        manifest: Manifest,
        repos: []const ExtRepo,
    ) !*CloneExtReposStep {
        const clone_ext_repos = try builder.allocator.create(CloneExtReposStep);
        clone_ext_repos.* = .{
            .step = std.build.Step.initNoOp(.custom, "clone ext repos", builder.allocator),
        };

        for (repos) |repo| {
            const ext_repo_name = std.fs.path.basename(repo.url);
            if (!std.mem.endsWith(u8, ext_repo_name, ".git")) {
                return error.InvalidRepoName;
            }
            const ext_repo_path = try std.fs.path.join(
                builder.allocator,
                &.{ manifest.ext_dir, ext_repo_name[0 .. ext_repo_name.len - 4] },
            );
            defer builder.allocator.free(ext_repo_path);
            var repo_exists = true;
            var dir: ?std.fs.Dir = std.fs.cwd().openDir(ext_repo_path, .{}) catch |e| block: {
                switch (e) {
                    error.FileNotFound => {
                        repo_exists = false;
                        break :block null;
                    },
                    else => return e,
                }
            };
            if (repo_exists) {
                dir.?.close();
                continue;
            }

            var clone_args = std.ArrayList([]const u8).init(builder.allocator);
            defer clone_args.deinit();

            try clone_args.append("git");
            try clone_args.append("clone");
            if (repo.clone_recursive) {
                try clone_args.append("--recurse-submodules");
                try clone_args.append("-j8");
            }
            try clone_args.append(repo.url);

            const clone = builder.addSystemCommand(clone_args.items);
            clone.cwd = manifest.ext_dir;

            var checkout_args = std.ArrayList([]const u8).init(builder.allocator);
            defer checkout_args.deinit();

            try checkout_args.append("git");
            try checkout_args.append("checkout");
            if (repo.clone_recursive) {
                try checkout_args.append("--recurse-submodules");
            }
            try checkout_args.append(repo.commit);
            try checkout_args.append(".");

            const checkout = builder.addSystemCommand(checkout_args.items);
            checkout.cwd = try builder.allocator.dupe(u8, ext_repo_path);
            checkout.step.dependOn(&clone.step);

            clone_ext_repos.step.dependOn(&checkout.step);
        }

        return clone_ext_repos;
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

fn addIncludePathExt(
    builder: *std.build.Builder,
    manifest: Manifest,
    lib: *std.build.LibExeObjStep,
    path: []const u8,
) !void {
    const ext_path = try std.fs.path.join(builder.allocator, &.{ manifest.ext_dir, path });
    defer builder.allocator.free(ext_path);
    lib.addIncludePath(ext_path);
}

fn addCSourceFilesExt(
    builder: *std.build.Builder,
    manifest: Manifest,
    lib: *std.build.LibExeObjStep,
    files: []const []const u8,
    flags: []const []const u8,
) !void {
    var ext_files = std.ArrayList([]const u8).init(builder.allocator);
    defer ext_files.deinit();
    defer for (ext_files.items) |ext_file| {
        builder.allocator.free(ext_file);
    };
    for (files) |file| {
        const ext_file = try std.fs.path.join(builder.allocator, &.{ manifest.ext_dir, file });
        try ext_files.append(ext_file);
    }
    lib.addCSourceFiles(ext_files.items, flags);
}
