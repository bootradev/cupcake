const cfg = @import("src/cfg.zig");
const demo_cube = @import("demo/cube/build.zig");
const demo_tri = @import("demo/tri/build.zig");
const demo_ui = @import("demo/ui/build.zig");
const minify = @import("src/minify.zig");
const std = @import("std");
const zmath = @import("ext/zig-gamedev/libs/zmath/build.zig");

const Demo = enum {
    tri,
    cube,
    ui,
};

pub fn build(builder: *std.build.Builder) !void {
    const demo = builder.option(Demo, "demo", "demo project") orelse .tri;
    switch (demo) {
        .tri => try demo_tri.build(builder),
        .cube => try demo_cube.build(builder),
        .ui => try demo_ui.build(builder),
    }
}

// package for "baking" resources into runtime-ready format
pub fn getBakePkg(
    builder: *std.build.Builder,
    options: Options,
    name: []const u8,
    dest_dir: []const u8,
    recipe: Recipe,
) std.build.Pkg {
    const baker = Baker.init(builder, options, name, dest_dir, recipe) catch unreachable;
    return baker.getPkg();
}

// cross platform graphics based on webgpu
pub fn getGfxPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_gfx",
        .path = .{ .path = "src/gfx.zig" },
    };
}

// cross platform math (exports zmath)
pub fn getMathPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_math",
        .path = .{ .path = "src/math.zig" },
        .dependencies = &.{zmath.pkg},
    };
}

// cross platform memory allocation
pub fn getMemPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_mem",
        .path = .{ .path = "src/mem.zig" },
    };
}

// cross platform file system resources
pub fn getResPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_res",
        .path = .{ .path = "src/res.zig" },
    };
}

// cross platform timing and profiling
pub fn getTimePkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_time",
        .path = .{ .path = "src/time.zig" },
    };
}

// user interface
pub fn getUiPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_ui",
        .path = .{ .path = "src/ui.zig" },
        .dependencies = &.{getMathPkg()},
    };
}

// gfx implementation for user interface
pub fn getUiGfxPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_ui_gfx",
        .path = .{ .path = "src/ui_gfx.zig" },
    };
}

// res implementation for user interface
pub fn getUiResPkg(builder: *std.build.Builder, options: Options) std.build.Pkg {
    const recipe = Recipe{
        .dir = "src",
        .items = &.{
            .{
                .id = "ui_vert_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"ui_vert.wgsl"},
            },
            .{
                .id = "ui_frag_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"ui_frag.wgsl"},
            },
        },
    };
    const dependencies = builder.allocator.alloc(std.build.Pkg, 1) catch unreachable;
    dependencies[0] = getBakePkg(builder, options, "cc_ui_res", ".", recipe);

    return std.build.Pkg{
        .name = "cc_ui_res",
        .path = .{ .path = "src/ui_res.zig" },
        .dependencies = dependencies,
    };
}

// cross platform windowing
pub fn getWndPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_wnd",
        .path = .{ .path = "src/wnd.zig" },
    };
}

// helper package for wnd and gfx interop
pub fn getWndGfxPkg() std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_wnd_gfx",
        .path = .{ .path = "src/wnd_gfx.zig" },
    };
}

pub const RecipeItemOutput = enum {
    cache, // item is baked to cache, but not included in the pkg
    pkg_embed, // item gets embedded into the binary
    pkg_install, // item gets installed to dest dir
};

pub const RecipeItem = struct {
    id: []const u8, // needs to be valid zig identifier and unique within the recipe
    output: RecipeItemOutput, // where the baked data gets output to
    bake_pkg: []const u8 = "cc_bake", // override this if you are using a custom bake pkg
    bake_type: []const u8, // which bake function should be used for this item
    deps: []const []const u8, // bake dependencies, can be file path or id of another recipe item
};

pub const BakePkg = struct {
    pkg: std.build.Pkg,
    link_fn: fn (*std.build.Builder, *std.build.LibExeObjStep) anyerror!void,
};

pub const Recipe = struct {
    dir: []const u8, // relative to the build root. all recipe items are relative to this dir
    items: []const RecipeItem, // list of items to bake
    bake_pkgs: []const BakePkg = &.{}, // list of custom bake pkgs
};

pub const Options = struct {
    platform: cfg.Platform = .web,
    opt_level: cfg.OptLevel = .dbg,
    bake_level: ?cfg.OptLevel = null,
    log_level: std.log.Level = .debug,
    log_enabled: bool = true,

    pub fn init(builder: *std.build.Builder) Options {
        const platform = builder.option(
            cfg.Platform,
            "p",
            "platform",
        ) orelse .web;
        const opt_level = builder.option(
            cfg.OptLevel,
            "opt",
            "optimization level",
        ) orelse .dbg;
        const bake_level = builder.option(
            cfg.OptLevel,
            "bake",
            "when specified, resources will be baked before compiling",
        );
        const log_level = builder.option(
            std.log.Level,
            "log",
            "log level",
        ) orelse switch (opt_level) {
            .dbg => std.log.Level.debug,
            .rel => std.log.Level.err,
        };
        const log_enabled = builder.option(
            bool,
            "log_enabled",
            "set to false to disable logging",
        ) orelse true;
        return Options{
            .platform = platform,
            .opt_level = opt_level,
            .bake_level = bake_level,
            .log_level = log_level,
            .log_enabled = log_enabled,
        };
    }
};

pub fn initMainLibExe(
    builder: *std.build.Builder,
    options: Options,
    dest_dir: []const u8,
    pkg: std.build.Pkg,
) !*std.build.LibExeObjStep {
    const app_name = pkg.name;
    var app_pkg = builder.dupePkg(pkg);
    app_pkg.name = "app";

    const build_options = builder.addOptions();
    build_options.addOption(bool, "log_enabled", options.log_enabled);
    build_options.addOption(std.log.Level, "log_level", options.log_level);

    const main_lib_exe = switch (options.platform) {
        .web => try initWebLibExe(builder, app_name),
        .win => return error.NotYetImplemented,
    };
    main_lib_exe.setBuildMode(switch (options.opt_level) {
        .dbg => .Debug,
        .rel => .ReleaseFast,
    });
    main_lib_exe.override_dest_dir = .{ .custom = dest_dir };
    main_lib_exe.addPackage(build_options.getPackage("build_options"));
    main_lib_exe.addPackage(app_pkg);
    main_lib_exe.install();

    try installPlatformFiles(builder, options, app_name, dest_dir);

    return main_lib_exe;
}

fn initWebLibExe(builder: *std.build.Builder, name: []const u8) !*std.build.LibExeObjStep {
    const main_lib_exe = builder.addSharedLibrary(name, "src/main.zig", .unversioned);
    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });
    main_lib_exe.setTarget(target);
    return main_lib_exe;
}

pub fn installPlatformFiles(
    builder: *std.build.Builder,
    options: Options,
    name: []const u8,
    dest_dir: []const u8,
) !void {
    switch (options.platform) {
        .web => try installWebFiles(builder, options, name, dest_dir),
        .win => return error.NotYetImplemented,
    }
}

fn installWebFiles(
    builder: *std.build.Builder,
    options: Options,
    name: []const u8,
    dest_dir: []const u8,
) !void {
    const gen_web_files = try GenerateWebFiles.init(builder, options, name);

    const install_html_path = try std.fs.path.join(
        builder.allocator,
        &.{ dest_dir, "index.html" },
    );
    defer builder.allocator.free(install_html_path);
    const install_js_path = try std.fs.path.join(
        builder.allocator,
        &.{ dest_dir, "cupcake.js" },
    );
    defer builder.allocator.free(install_js_path);

    const install_html = builder.addInstallFile(
        .{ .generated = &gen_web_files.html_file },
        install_html_path,
    );
    const install_js = builder.addInstallFile(
        .{ .generated = &gen_web_files.js_file },
        install_js_path,
    );

    if (options.bake_level != null) {
        install_html.step.dependOn(&gen_web_files.step);
        install_js.step.dependOn(&gen_web_files.step);
    }

    const install_step = builder.getInstallStep();
    install_step.dependOn(&install_html.step);
    install_step.dependOn(&install_js.step);
}

fn getCacheDir(builder: *std.build.Builder) ![]u8 {
    return try std.fs.path.join(
        builder.allocator,
        &.{ builder.build_root, builder.cache_root, "cupcake" },
    );
}

fn getBakeCacheDir(builder: *std.build.Builder, options: Options, name: []const u8) ![]u8 {
    return try std.fs.path.join(
        builder.allocator,
        &.{ try getCacheDir(builder), "bake", name, @tagName(options.platform) },
    );
}

pub fn getDestDir(builder: *std.build.Builder, options: Options, name: []const u8) ![]u8 {
    return try std.fs.path.join(
        builder.allocator,
        &.{ name, @tagName(options.platform) },
    );
}

// takes in a path, returns a valid version of that path for embedding in a source file
fn getPathString(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var path_string = std.ArrayList(u8).init(allocator);
    for (path) |char| {
        if (std.fs.path.isSep(char)) {
            try path_string.appendSlice("/");
        } else {
            try path_string.append(char);
        }
    }
    return path_string.toOwnedSlice();
}

const Baker = struct {
    builder: *std.build.Builder,
    recipe: Recipe,
    platform: cfg.Platform,
    bake_level: ?cfg.OptLevel,
    cache_dir: []const u8,
    install_step: std.build.Step,
    list_step: std.build.Step,
    list_file: std.build.GeneratedFile,
    pkg_file: std.build.GeneratedFile,
    deps: std.ArrayList(std.build.Pkg),

    pub fn init(
        builder: *std.build.Builder,
        options: Options,
        name: []const u8,
        dest_dir: []const u8,
        recipe: Recipe,
    ) !*Baker {
        const cache_dir = try getBakeCacheDir(builder, options, name);

        var baker = try builder.allocator.create(Baker);
        baker.* = .{
            .builder = builder,
            .recipe = recipe,
            .platform = options.platform,
            .bake_level = options.bake_level,
            .cache_dir = cache_dir,
            .install_step = std.build.Step.initNoOp(.custom, "bake install", builder.allocator),
            .list_step = std.build.Step.init(.custom, "bake list", builder.allocator, make),
            .list_file = .{ .step = &baker.list_step },
            .pkg_file = .{
                .step = &baker.install_step,
                .path = try std.fs.path.join(
                    builder.allocator,
                    &.{ cache_dir, "bake_pkg.zig" },
                ),
            },
            .deps = std.ArrayList(std.build.Pkg).init(builder.allocator),
        };

        var bake_exe = builder.addExecutable("bake", "src/bake.zig");
        bake_exe.setBuildMode(.ReleaseSafe);

        const cc_bake_pkg = BakePkg{
            .pkg = .{ .name = "cc_bake", .path = .{ .path = "src/bake_types.zig" } },
            .link_fn = ccLinkBakePkg,
        };
        try baker.addBakePkg(bake_exe, cc_bake_pkg);
        for (recipe.bake_pkgs) |bake_pkg| {
            try baker.addBakePkg(bake_exe, bake_pkg);
        }

        bake_exe.addPackage(.{
            .name = "bake_list",
            .path = .{ .generated = &baker.list_file },
            .dependencies = baker.deps.items,
        });

        if (options.bake_level != null) {
            try std.fs.cwd().makePath(baker.cache_dir);
            baker.install_step.dependOn(&bake_exe.run().step);
        }

        for (recipe.items) |item| {
            if (item.output != .pkg_install) {
                continue;
            }

            const item_path = try std.fs.path.join(
                builder.allocator,
                &.{ baker.cache_dir, item.id },
            );
            defer builder.allocator.free(item_path);

            const install_path = try std.fs.path.join(
                builder.allocator,
                &.{ dest_dir, item.id },
            );
            defer builder.allocator.free(install_path);

            const install_item = builder.addInstallFile(
                .{ .path = item_path },
                install_path,
            );
            install_item.step.dependOn(&baker.install_step);
            builder.getInstallStep().dependOn(&install_item.step);
        }

        return baker;
    }

    fn addBakePkg(baker: *Baker, lib_exe: *std.build.LibExeObjStep, bake_pkg: BakePkg) !void {
        try baker.deps.append(baker.builder.dupePkg(bake_pkg.pkg));
        try bake_pkg.link_fn(baker.builder, lib_exe);
    }

    fn ccLinkBakePkg(builder: *std.build.Builder, lib_exe: *std.build.LibExeObjStep) !void {
        _ = builder;
        _ = lib_exe;
    }

    pub fn getPkg(baker: Baker) std.build.Pkg {
        const pkg_src = if (baker.bake_level == null) block: {
            break :block std.build.FileSource{ .path = baker.pkg_file.getPath() };
        } else block: {
            break :block std.build.FileSource{ .generated = &baker.pkg_file };
        };

        return std.build.Pkg{
            .name = "cc_bake",
            .path = pkg_src,
            .dependencies = baker.deps.items,
        };
    }

    fn make(step: *std.build.Step) !void {
        const baker = @fieldParentPtr(Baker, "list_step", step);

        var list_file_contents = std.ArrayList(u8).init(baker.builder.allocator);
        defer list_file_contents.deinit();

        const root_dir = try std.fs.path.join(
            baker.builder.allocator,
            &.{ baker.builder.build_root, baker.recipe.dir },
        );

        const writer = list_file_contents.writer();

        try writer.print("pub const pkgs = struct {{\n", .{});
        for (baker.deps.items) |dep| {
            try writer.print("    pub const {s} = @import(\"{s}\");\n", .{ dep.name, dep.name });
        }
        try writer.print("}};\n", .{});

        try writer.print(
            "pub const in_dir = \"{s}\";\n",
            .{try getPathString(baker.builder.allocator, root_dir)},
        );
        try writer.print(
            "pub const out_dir = \"{s}\";\n",
            .{try getPathString(baker.builder.allocator, baker.cache_dir)},
        );
        try writer.print("pub const platform = .{s};\n", .{@tagName(baker.platform)});
        try writer.print("pub const opt_level = .{s};\n", .{@tagName(baker.bake_level.?)});
        try writer.print("pub const items = struct {{\n", .{});
        for (baker.recipe.items) |item| {
            try writer.print("    pub const {s} = .{{\n", .{item.id});
            try writer.print("        .bake_pkg = \"{s}\",\n", .{item.bake_pkg});
            try writer.print("        .bake_type = \"{s}\",\n", .{item.bake_type});
            try writer.print("        .output = .{s},\n", .{@tagName(item.output)});
            try writer.print("        .deps = &[_][]const u8{{\n", .{});
            for (item.deps) |dep| {
                try writer.print("            \"{s}\",\n", .{dep});
            }
            try writer.print("        }},\n", .{});
            try writer.print("    }};\n", .{});
        }
        try writer.print("}};\n", .{});

        const list_path = try std.fs.path.join(
            baker.builder.allocator,
            &.{ baker.cache_dir, "bake_list.zig" },
        );
        try std.fs.cwd().writeFile(list_path, list_file_contents.items);
        baker.list_file.path = list_path;
    }
};

const GenerateWebFiles = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    cache_dir: []const u8,
    name: []const u8,
    bake_level: ?cfg.OptLevel,
    html_file: std.build.GeneratedFile,
    js_file: std.build.GeneratedFile,

    pub fn init(
        builder: *std.build.Builder,
        options: Options,
        name: []const u8,
    ) !*GenerateWebFiles {
        const cache_dir = try getBakeCacheDir(builder, options, name);
        try std.fs.cwd().makePath(cache_dir);

        const html_file_path = try std.fs.path.join(
            builder.allocator,
            &.{ cache_dir, "index.html" },
        );
        const js_file_path = try std.fs.path.join(
            builder.allocator,
            &.{ cache_dir, "cupcake.js" },
        );

        var gen_web_files = try builder.allocator.create(GenerateWebFiles);
        gen_web_files.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "gen web files", builder.allocator, make),
            .cache_dir = cache_dir,
            .name = name,
            .bake_level = options.bake_level,
            .html_file = .{ .step = &gen_web_files.step, .path = html_file_path },
            .js_file = .{ .step = &gen_web_files.step, .path = js_file_path },
        };
        return gen_web_files;
    }

    fn make(step: *std.build.Step) !void {
        const gen_web_files = @fieldParentPtr(GenerateWebFiles, "step", step);

        try gen_web_files.makeHtmlFile();
        try gen_web_files.makeJsFile();
    }

    fn makeHtmlFile(gen_web_files: *GenerateWebFiles) !void {
        const html_file = try std.fs.cwd().createFile(
            gen_web_files.html_file.getPath(),
            .{ .truncate = true },
        );
        defer html_file.close();
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
            \\            ccRun("{s}.wasm");
            \\        </script>
            \\    </body>
            \\</html>
        ;
        try std.fmt.format(html_file.writer(), html_fmt, .{gen_web_files.name});
    }

    fn makeJsFile(gen_web_files: *GenerateWebFiles) !void {
        // intentional ordering to prevent dependency issues
        const js_srcs: []const []const u8 = &.{
            "utils.js",
            "main_web.js",
            "time_web.js",
            "res_web.js",
            "wnd_web.js",
            "gfx_webgpu.js",
        };

        const js_src_path = try std.fs.path.join(
            gen_web_files.builder.allocator,
            &.{ gen_web_files.builder.build_root, "src" },
        );
        defer gen_web_files.builder.allocator.free(js_src_path);

        var js_src_dir = try std.fs.cwd().openDir(js_src_path, .{});
        defer js_src_dir.close();

        var js_file_contents = std.ArrayList(u8).init(gen_web_files.builder.allocator);
        defer js_file_contents.deinit();

        for (js_srcs) |js_src| {
            const js_src_file = try js_src_dir.openFile(js_src, .{});
            defer js_src_file.close();
            const js_src_file_stat = try js_src_file.stat();
            const js_src_bytes = try js_src_file.readToEndAlloc(
                gen_web_files.builder.allocator,
                js_src_file_stat.size,
            );
            defer gen_web_files.builder.allocator.free(js_src_bytes);

            try js_file_contents.appendSlice(js_src_bytes[0..]);
            try js_file_contents.appendSlice("\n");
        }

        if (gen_web_files.bake_level.? == .dbg) {
            try std.fs.cwd().writeFile(gen_web_files.js_file.getPath(), js_file_contents.items);
        } else {
            const js_src_bytes_min = try minify.js(
                gen_web_files.builder.allocator,
                js_file_contents.items,
                gen_web_files.bake_level.?,
            );
            defer gen_web_files.builder.allocator.free(js_src_bytes_min);
            try std.fs.cwd().writeFile(gen_web_files.js_file.getPath(), js_src_bytes_min);
        }
    }
};
