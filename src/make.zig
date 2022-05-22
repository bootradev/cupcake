const builtin = @import("builtin");
const cfg = @import("cfg.zig");
const serde = @import("serde.zig");
const std = @import("std");

pub const BakeItem = struct {
    path: []const u8,
    embed: bool = false,
};

pub const RecipeDesc = struct {
    name: []const u8,
    root: []const u8,
    bake_dir: []const u8 = "",
    bake_items: []const BakeItem = &.{},
};

pub const Recipe = struct {
    name: []const u8,
    root: []const u8,
    bake_dir: []const u8,
    bake_items: []const BakeItem,
    platform: cfg.Platform,
    opt_level: cfg.OptLevel,
    log_level: cfg.LogLevel,
    build_root_dir: []const u8,
    install_dir: []const u8,
    ext_dir: []const u8,
    gen_dir: []const u8,
    gen_lib_dir: []const u8,
    gen_tools_dir: []const u8,
    dest_dir: []const u8,
    out_path: []const u8,
    pkg_path: []const u8,

    fn init(builder: *std.build.Builder, desc: RecipeDesc) !Recipe {
        var recipe: Recipe = undefined;
        try setOptionFields(&recipe, builder);
        try setNonOptionFields(&recipe, builder, desc);
        return recipe;
    }

    fn dupe(recipe: Recipe, builder: *std.build.Builder, desc: RecipeDesc) !Recipe {
        var dupe_recipe: Recipe = undefined;
        try dupeOptionFields(&dupe_recipe, recipe, builder);
        try setNonOptionFields(&dupe_recipe, builder, desc);
        return dupe_recipe;
    }

    fn setOptionFields(recipe: *Recipe, builder: *std.build.Builder) !void {
        recipe.platform = builder.option(
            cfg.Platform,
            "platform",
            "target platform",
        ) orelse default_platform;
        recipe.opt_level = builder.option(
            cfg.OptLevel,
            "opt",
            "optimization level",
        ) orelse default_opt_level;
        recipe.log_level = builder.option(
            cfg.LogLevel,
            "log_level",
            "threshold for logging to console",
        ) orelse recipe.opt_level.getLogLevel();

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

        recipe.ext_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.build_root, ext_dir_rel },
        );

        recipe.gen_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.build_root, gen_dir_rel },
        );
        recipe.gen_lib_dir = try std.fs.path.join(
            builder.allocator,
            &.{ recipe.gen_dir, "lib" },
        );
        recipe.gen_tools_dir = try std.fs.path.join(
            builder.allocator,
            &.{ recipe.gen_dir, "tools" },
        );
    }

    fn dupeOptionFields(
        dupe_recipe: *Recipe,
        recipe: Recipe,
        builder: *std.build.Builder,
    ) !void {
        dupe_recipe.platform = recipe.platform;
        dupe_recipe.opt_level = recipe.opt_level;
        dupe_recipe.log_level = recipe.log_level;
        dupe_recipe.ext_dir = try builder.allocator.dupe(u8, recipe.ext_dir);
        dupe_recipe.gen_dir = try builder.allocator.dupe(u8, recipe.gen_dir);
        dupe_recipe.gen_lib_dir = try builder.allocator.dupe(u8, recipe.gen_lib_dir);
        dupe_recipe.gen_tools_dir = try builder.allocator.dupe(u8, recipe.gen_tools_dir);
    }

    fn setNonOptionFields(
        recipe: *Recipe,
        builder: *std.build.Builder,
        desc: RecipeDesc,
    ) !void {
        recipe.name = desc.name;
        recipe.root = desc.root;
        recipe.bake_dir = desc.bake_dir;
        recipe.bake_items = desc.bake_items;

        recipe.build_root_dir = builder.build_root;
        recipe.dest_dir = try std.fs.path.join(
            builder.allocator,
            &.{ recipe.name, @tagName(recipe.platform) },
        );
        recipe.install_dir = try std.fs.path.join(
            builder.allocator,
            &.{ builder.install_prefix, recipe.dest_dir },
        );

        const manifest_dir_path = try std.fs.path.join(
            builder.allocator,
            &.{ recipe.gen_dir, "bake", recipe.name },
        );
        defer builder.allocator.free(manifest_dir_path);

        const manifest_name = try std.mem.concat(
            builder.allocator,
            u8,
            &.{ recipe.name, "_", @tagName(recipe.platform) },
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
            &.{ manifest_name, "_bake.zig" },
        );
        defer builder.allocator.free(pkg_name);

        recipe.out_path = try std.fs.path.join(
            builder.allocator,
            &.{ manifest_dir_path, out_name },
        );
        recipe.pkg_path = try std.fs.path.join(
            builder.allocator,
            &.{ manifest_dir_path, pkg_name },
        );
    }
};

const default_platform = .web;
const default_opt_level = .debug;

pub fn build(builder: *std.build.Builder, desc: RecipeDesc) !void {
    var recipe = try Recipe.init(builder, desc);

    const recipe_cc_desc: RecipeDesc = .{
        .name = "cc",
        .root = "",
        .bake_dir = ".",
        .bake_items = &.{
            .{ .path = "src/ui_vert.wgsl", .embed = true },
            .{ .path = "src/ui_frag.wgsl", .embed = true },
        },
    };
    const recipe_cc = try recipe.dupe(builder, recipe_cc_desc);

    try buildExt(builder, recipe);
    try buildBake(builder, recipe, recipe_cc);
    try buildApp(builder, recipe, recipe_cc);
}

fn buildExt(builder: *std.build.Builder, recipe: Recipe) !void {
    try std.fs.cwd().makePath(recipe.ext_dir);
    try std.fs.cwd().makePath(recipe.gen_lib_dir);
    try std.fs.cwd().makePath(recipe.gen_tools_dir);

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
        .{
            .url = "https://github.com/michal-z/zig-gamedev.git",
            .commit = "4ae28cf3e4b822f0dc4fab70557b165d73ec3c97",
        },
    };
    const clone_ext_repos = try CloneExtReposStep.init(builder, recipe, &ext_repos);

    const header_only_libs = [_]HeaderOnlyLib{
        .{ .path = "stb/stb_image.h", .define = "STB_IMAGE_IMPLEMENTATION" },
    };
    const header_only_step = try HeaderOnlyStep.init(builder, recipe, &header_only_libs);
    header_only_step.step.dependOn(&clone_ext_repos.step);

    const header_only = builder.addStaticLibrary(HeaderOnlyStep.lib_name, null);
    header_only.setBuildMode(.ReleaseFast);
    header_only.linkLibC();
    header_only.addIncludePath(recipe.ext_dir);
    header_only.addCSourceFileSource(header_only_step.getCSourceFile());
    header_only.setOutputDir(recipe.gen_lib_dir);
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
    try addIncludePathExt(builder, recipe, freetype, "freetype/include");
    try addCSourceFilesExt(builder, recipe, freetype, freetype_srcs, freetype_flags);
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
    try addIncludePathExt(builder, recipe, msdfgen, "freetype/include");
    try addIncludePathExt(builder, recipe, msdfgen, "msdf-atlas-gen/msdfgen/include");
    try addCSourceFilesExt(builder, recipe, msdfgen, msdfgen_srcs, msdfgen_flags);
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
    try addIncludePathExt(builder, recipe, msdf_atlas_gen, "msdf-atlas-gen/msdfgen");
    try addIncludePathExt(builder, recipe, msdf_atlas_gen, "msdf-atlas-gen/msdfgen/include");
    try addIncludePathExt(builder, recipe, msdf_atlas_gen, "msdf-atlas-gen/artery-font-format");
    try addCSourceFilesExt(
        builder,
        recipe,
        msdf_atlas_gen,
        msdf_atlas_gen_srcs,
        msdf_atlas_gen_flags,
    );
    msdf_atlas_gen.linkLibCpp();
    msdf_atlas_gen.linkLibrary(msdfgen);
    msdf_atlas_gen.linkLibrary(freetype);
    msdf_atlas_gen.setOutputDir(recipe.gen_tools_dir);

    const build_ext_step = builder.step("ext", "Build external dependencies");
    build_ext_step.dependOn(&header_only.step);
    build_ext_step.dependOn(&msdf_atlas_gen.step);
}

fn buildBake(builder: *std.build.Builder, recipe: Recipe, recipe_cc: Recipe) !void {
    const bake_exe = builder.addExecutable("bake", "src/bake_app.zig");
    bake_exe.setBuildMode(.ReleaseSafe);
    bake_exe.linkLibC();
    bake_exe.addIncludePath(recipe.ext_dir);
    bake_exe.addLibraryPath(recipe.gen_lib_dir);
    bake_exe.linkSystemLibrary(HeaderOnlyStep.lib_name);

    const write_cc_recipe = try WriteRecipeStep.init(builder, recipe_cc);
    var bake_cc = bake_exe.run();
    bake_cc.step.dependOn(&write_cc_recipe.step);
    bake_cc.addArgs(&.{recipe_cc.out_path});

    const write_app_recipe = try WriteRecipeStep.init(builder, recipe);
    var bake_app = bake_exe.run();
    bake_app.step.dependOn(&write_app_recipe.step);
    bake_app.addArgs(&.{ recipe.out_path, "install" });

    const bake_step = builder.step("bake", "bake items in the recipe");
    bake_step.dependOn(&bake_cc.step);
    bake_step.dependOn(&bake_app.step);
}

fn buildApp(builder: *std.build.Builder, recipe: Recipe, recipe_cc: Recipe) !void {
    const app_lib_exe = switch (recipe.platform) {
        .web => try buildWeb(builder, recipe),
    };
    app_lib_exe.setBuildMode(recipe.opt_level.getBuildMode());
    app_lib_exe.override_dest_dir = .{ .custom = recipe.dest_dir };

    const cfg_options = builder.addOptions();
    cfg_options.addOption(cfg.Platform, "platform", recipe.platform);
    cfg_options.addOption(cfg.OptLevel, "opt_level", recipe.opt_level);
    cfg_options.addOption(cfg.LogLevel, "log_level", recipe.log_level);
    app_lib_exe.step.dependOn(&cfg_options.step);

    const cfg_pkg = cfg_options.getPackage("cfg");
    const bake_pkg = std.build.Pkg{
        .name = "bake",
        .path = .{ .path = recipe.pkg_path },
    };
    const cc_bake_pkg = std.build.Pkg{
        .name = "cc_bake",
        .path = .{ .path = recipe_cc.pkg_path },
    };
    const zmath_pkg = try getPackageExt(
        builder,
        recipe,
        "zmath",
        "zig-gamedev/libs/zmath/src/zmath.zig",
    );
    const cupcake_pkg = std.build.Pkg{
        .name = "cupcake",
        .path = .{ .path = "src/cupcake.zig" },
        .dependencies = &.{ cfg_pkg, bake_pkg, cc_bake_pkg, zmath_pkg },
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = recipe.root },
        .dependencies = &.{cupcake_pkg},
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(app_pkg);

    app_lib_exe.install();
}

fn buildWeb(
    builder: *std.build.Builder,
    recipe: Recipe,
) !*std.build.LibExeObjStep {
    const app_lib_exe = builder.addSharedLibrary(
        recipe.name,
        "src/main.zig",
        .unversioned,
    );

    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });
    app_lib_exe.setTarget(target);

    return app_lib_exe;
}

const WriteRecipeStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    recipe: Recipe,

    pub fn init(builder: *std.build.Builder, recipe: Recipe) !*WriteRecipeStep {
        const write_recipe = try builder.allocator.create(WriteRecipeStep);
        write_recipe.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "write recipe", builder.allocator, make),
            .recipe = recipe,
        };
        return write_recipe;
    }

    fn make(step: *std.build.Step) !void {
        const write_recipe = @fieldParentPtr(WriteRecipeStep, "step", step);

        const recipe_bytes = try serde.serialize(
            write_recipe.builder.allocator,
            write_recipe.recipe,
        );

        if (std.fs.path.dirname(write_recipe.recipe.out_path)) |dir| {
            try std.fs.cwd().makePath(dir);
        }
        try std.fs.cwd().writeFile(write_recipe.recipe.out_path, recipe_bytes);
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
        recipe: Recipe,
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
                &.{ recipe.ext_dir, ext_repo_name[0 .. ext_repo_name.len - 4] },
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
            clone.cwd = recipe.ext_dir;

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
    recipe: Recipe,
    step: std.build.Step,
    libs: []const HeaderOnlyLib,
    generated_file: std.build.GeneratedFile,

    fn init(
        builder: *std.build.Builder,
        recipe: Recipe,
        libs: []const HeaderOnlyLib,
    ) !*HeaderOnlyStep {
        const header_only_step = try builder.allocator.create(HeaderOnlyStep);
        header_only_step.* = .{
            .builder = builder,
            .recipe = recipe,
            .step = std.build.Step.init(.custom, "header only libs", builder.allocator, make),
            .libs = libs,
            .generated_file = .{ .step = &header_only_step.step },
        };
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
            header.recipe.gen_lib_dir, out_name,
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
    recipe: Recipe,
    lib: *std.build.LibExeObjStep,
    path: []const u8,
) !void {
    const ext_path = try std.fs.path.join(builder.allocator, &.{ recipe.ext_dir, path });
    defer builder.allocator.free(ext_path);
    lib.addIncludePath(ext_path);
}

fn addCSourceFilesExt(
    builder: *std.build.Builder,
    recipe: Recipe,
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
        const ext_file = try std.fs.path.join(builder.allocator, &.{ recipe.ext_dir, file });
        try ext_files.append(ext_file);
    }
    lib.addCSourceFiles(ext_files.items, flags);
}

fn getPackageExt(
    builder: *std.build.Builder,
    recipe: Recipe,
    name: []const u8,
    path: []const u8,
) !std.build.Pkg {
    const pkg_path = try std.fs.path.join(builder.allocator, &.{ recipe.ext_dir, path });
    return std.build.Pkg{ .name = name, .path = .{ .path = pkg_path } };
}
