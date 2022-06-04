const bake = @import("src/bake.zig");
const cfg = @import("src/cfg.zig");
const minify = @import("src/minify.zig");
const std = @import("std");

// package for "baking" resources into runtime-ready format
pub fn getBakePkg(
    builder: *std.build.Builder,
    options: Options,
    name: []const u8,
    dest_dir: []const u8,
    comptime recipe: Recipe,
) std.build.Pkg {
    const baker = Baker(recipe).init(builder, options, name, dest_dir) catch unreachable;
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
pub fn getMathPkg(builder: *std.build.Builder) std.build.Pkg {
    const ext_dir = getExtDir(builder) catch unreachable;
    const zmath_clone = GitClone.init(
        builder,
        ext_dir,
        "https://github.com/michal-z/zig-gamedev.git",
        "6e0a0ba9a9d4d087215928345208094ae9806ab3",
        false,
    ) catch unreachable;

    const zmath_path = std.fs.path.join(
        builder.allocator,
        &.{ ext_dir, "zig-gamedev", "libs", "zmath", "src", "zmath.zig" },
    ) catch unreachable;

    const zmath_gen = builder.allocator.create(std.build.GeneratedFile) catch unreachable;
    zmath_gen.* = .{
        .step = &zmath_clone.step,
        .path = zmath_path,
    };

    const dependencies = builder.allocator.alloc(std.build.Pkg, 1) catch unreachable;
    dependencies[0] = .{
        .name = "zmath",
        .path = .{ .generated = zmath_gen },
    };

    return std.build.Pkg{
        .name = "cc_math",
        .path = .{ .path = "src/math.zig" },
        .dependencies = dependencies,
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
pub fn getUiPkg(builder: *std.build.Builder) std.build.Pkg {
    return std.build.Pkg{
        .name = "cc_ui",
        .path = .{ .path = "src/ui.zig" },
        .dependencies = &.{getMathPkg(builder)},
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
            .{ .bake_type = bake.Shader, .path = "ui_vert.wgsl", .embed = true },
            .{ .bake_type = bake.Shader, .path = "ui_frag.wgsl", .embed = true },
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

pub const RecipeItem = struct {
    bake_type: type,
    path: []const u8,
    embed: bool,
};

pub const Recipe = struct {
    dir: []const u8,
    items: []const RecipeItem,
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

const Example = enum {
    tri,
    cube,
    ui,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "ex", "example project") orelse .tri;
    switch (example) {
        .tri => try buildTriangle(builder),
        .cube => try buildCube(builder),
        .ui => try buildUi(builder),
    }
}

fn buildTriangle(builder: *std.build.Builder) !void {
    const options = Options.init(builder);
    const dest_dir = try getDestDir(builder, options, "triangle");
    const recipe = Recipe{
        .dir = "examples/triangle",
        .items = &.{
            .{ .bake_type = bake.Shader, .path = "triangle_vert.wgsl", .embed = true },
            .{ .bake_type = bake.Shader, .path = "triangle_frag.wgsl", .embed = true },
        },
    };
    const triangle_pkg = std.build.Pkg{
        .name = "triangle",
        .path = .{ .path = "examples/triangle/triangle.zig" },
        .dependencies = &.{
            getBakePkg(builder, options, "triangle", dest_dir, recipe),
            getGfxPkg(),
            getResPkg(),
            getWndPkg(),
            getWndGfxPkg(),
        },
    };
    _ = try initMainLibExe(builder, options, triangle_pkg);
}

fn buildCube(builder: *std.build.Builder) !void {
    const options = Options.init(builder);
    const dest_dir = try getDestDir(builder, options, "cube");
    const recipe = Recipe{
        .dir = "examples/cube",
        .items = &.{
            .{ .bake_type = bake.Shader, .path = "cube_vert.wgsl", .embed = true },
            .{ .bake_type = bake.Shader, .path = "cube_frag.wgsl", .embed = true },
        },
    };
    const cube_pkg = std.build.Pkg{
        .name = "cube",
        .path = .{ .path = "examples/cube/cube.zig" },
        .dependencies = &.{
            getBakePkg(builder, options, "cube", dest_dir, recipe),
            getGfxPkg(),
            getMathPkg(builder),
            getResPkg(),
            getTimePkg(),
            getWndPkg(),
            getWndGfxPkg(),
        },
    };
    _ = try initMainLibExe(builder, options, cube_pkg);
}

fn buildUi(builder: *std.build.Builder) !void {
    const options = Options.init(builder);
    const ui_pkg = std.build.Pkg{
        .name = "ui",
        .path = .{ .path = "examples/ui/ui.zig" },
        .dependencies = &.{
            getGfxPkg(),
            getMemPkg(),
            getUiPkg(builder),
            getUiGfxPkg(),
            getUiResPkg(builder, options),
            getWndPkg(),
            getWndGfxPkg(),
        },
    };
    _ = try initMainLibExe(builder, options, ui_pkg);
}

pub fn initMainLibExe(
    builder: *std.build.Builder,
    options: Options,
    pkg: std.build.Pkg,
) !*std.build.LibExeObjStep {
    const app_name = pkg.name;
    var app_pkg = builder.dupePkg(pkg);
    app_pkg.name = "app";

    const build_options = builder.addOptions();
    build_options.addOption(bool, "log_enabled", options.log_enabled);
    build_options.addOption(std.log.Level, "log_level", options.log_level);

    const dest_dir = try getDestDir(builder, options, app_name);

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

fn getDestDir(builder: *std.build.Builder, options: Options, name: []const u8) ![]u8 {
    return try std.fs.path.join(
        builder.allocator,
        &.{ name, @tagName(options.platform) },
    );
}

fn getExtDir(builder: *std.build.Builder) ![]u8 {
    return try std.fs.path.join(
        builder.allocator,
        &.{ try getCacheDir(builder), "ext" },
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

// todo: add mechanism for user to add bake types
pub fn Baker(comptime recipe: Recipe) type {
    return struct {
        const Self = @This();
        const bake_dependencies = [_]std.build.Pkg{.{
            .name = "bake",
            .path = .{ .path = "src/bake.zig" },
        }};

        builder: *std.build.Builder,
        platform: cfg.Platform,
        bake_level: ?cfg.OptLevel,
        cache_dir: []const u8,
        install_step: std.build.Step,
        list_step: std.build.Step,
        list_file: std.build.GeneratedFile,
        pkg_step: std.build.Step,
        pkg_file: std.build.GeneratedFile,

        pub fn init(
            builder: *std.build.Builder,
            options: Options,
            name: []const u8,
            dest_dir: []const u8,
        ) !*Self {
            const cache_dir = try getBakeCacheDir(builder, options, name);

            var self = try builder.allocator.create(Self);
            self.* = .{
                .builder = builder,
                .platform = options.platform,
                .bake_level = options.bake_level,
                .cache_dir = cache_dir,
                .install_step = std.build.Step.initNoOp(.custom, "install", builder.allocator),
                .list_step = std.build.Step.init(.custom, "list", builder.allocator, makeList),
                .list_file = .{ .step = &self.list_step },
                .pkg_step = std.build.Step.init(.custom, "pkg", builder.allocator, makePkg),
                .pkg_file = .{
                    .step = &self.pkg_step,
                    .path = try std.fs.path.join(
                        builder.allocator,
                        &.{ cache_dir, "bake_pkg.zig" },
                    ),
                },
            };

            if (options.bake_level != null) {
                try std.fs.cwd().makePath(self.cache_dir);

                const bake_exe = builder.addExecutable("bake", "src/bake.zig");
                bake_exe.setBuildMode(.ReleaseSafe);
                bake_exe.addPackage(.{
                    .name = "bake_list",
                    .path = .{ .generated = &self.list_file },
                    .dependencies = &bake_dependencies,
                });
                self.pkg_step.dependOn(&bake_exe.run().step);
                self.install_step.dependOn(&self.pkg_step);
            }

            inline for (recipe.items) |item| {
                if (item.embed) {
                    continue;
                }

                const var_name = comptime bake.getVarName(item.path, item.bake_type);

                const item_path = try std.fs.path.join(
                    builder.allocator,
                    &.{ self.cache_dir, var_name },
                );
                defer builder.allocator.free(item_path);

                const install_path = try std.fs.path.join(
                    builder.allocator,
                    &.{ dest_dir, var_name },
                );
                defer builder.allocator.free(install_path);

                const install_gen = try builder.allocator.create(std.build.GeneratedFile);
                install_gen.* = .{
                    .step = &self.pkg_step,
                    .path = try builder.allocator.dupe(u8, item_path),
                };
                const install_item = builder.addInstallFile(
                    .{ .generated = install_gen },
                    install_path,
                );
                install_item.step.dependOn(&self.install_step);
                builder.getInstallStep().dependOn(&install_item.step);
            }

            return self;
        }

        pub fn getPkg(self: Self) std.build.Pkg {
            const pkg_src = if (self.bake_level == null) block: {
                break :block std.build.FileSource{ .path = self.pkg_file.getPath() };
            } else block: {
                break :block std.build.FileSource{ .generated = &self.pkg_file };
            };

            return std.build.Pkg{
                .name = "cc_bake",
                .path = pkg_src,
                .dependencies = &bake_dependencies,
            };
        }

        fn makeList(step: *std.build.Step) !void {
            const self = @fieldParentPtr(Self, "list_step", step);

            var list_file_contents = std.ArrayList(u8).init(self.builder.allocator);
            defer list_file_contents.deinit();

            const root_dir = try std.fs.path.join(
                self.builder.allocator,
                &.{ self.builder.build_root, recipe.dir },
            );

            const writer = list_file_contents.writer();
            try writer.print("pub const bake = @import(\"bake\");\n", .{});
            try writer.print(
                "pub const in_dir = \"{s}\";\n",
                .{try getPathString(self.builder.allocator, root_dir)},
            );
            try writer.print(
                "pub const out_dir = \"{s}\";\n",
                .{try getPathString(self.builder.allocator, self.cache_dir)},
            );
            try writer.print("pub const platform = .{s};\n", .{@tagName(self.platform)});
            try writer.print("pub const opt_level = .{s};\n", .{@tagName(self.bake_level.?)});
            inline for (recipe.items) |item| {
                try writer.print(
                    "pub const @\"{s}\": type = bake.{s};\n",
                    .{ try getPathString(self.builder.allocator, item.path), item.bake_type },
                );
            }

            const list_path = try std.fs.path.join(
                self.builder.allocator,
                &.{ self.cache_dir, "bake_list.zig" },
            );
            try std.fs.cwd().writeFile(list_path, list_file_contents.items);
            self.list_file.path = list_path;
        }

        fn makePkg(step: *std.build.Step) !void {
            const self = @fieldParentPtr(Self, "pkg_step", step);

            var pkg_file_contents = std.ArrayList(u8).init(self.builder.allocator);
            defer pkg_file_contents.deinit();

            var cache_dir = try std.fs.cwd().openDir(self.cache_dir, .{});
            defer cache_dir.close();

            const writer = pkg_file_contents.writer();
            try writer.print("pub const bake = @import(\"bake\");\n", .{});
            inline for (recipe.items) |item| {
                const var_name = comptime bake.getVarName(item.path, item.bake_type);
                try writer.print("pub const {s} = .{{ ", .{var_name});
                try writer.print(".Type = bake.{s}, ", .{item.bake_type});
                if (item.embed) {
                    try writer.print(".data = .{{ .embed = @embedFile(\"{s}\") }}", .{var_name});
                } else {
                    const item_file = try cache_dir.openFile(var_name, .{});
                    defer item_file.close();
                    const item_file_stat = try item_file.stat();
                    try writer.print(
                        ".data = .{{ .file = .{{ .path = \"{s}\", .size = {} }} }}",
                        .{ var_name, item_file_stat.size },
                    );
                }
                try writer.print("}};\n", .{});
            }

            try std.fs.cwd().writeFile(self.pkg_file.getPath(), pkg_file_contents.items);
        }
    };
}

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
                js_file_contents.items,
                gen_web_files.builder.allocator,
                gen_web_files.bake_level.?,
            );
            defer gen_web_files.builder.allocator.free(js_src_bytes_min);
            try std.fs.cwd().writeFile(gen_web_files.js_file.getPath(), js_src_bytes_min);
        }
    }
};

const GitClone = struct {
    step: std.build.Step,

    pub fn init(
        builder: *std.build.Builder,
        dir: []const u8,
        repo: []const u8,
        commit: []const u8,
        recursive: bool,
    ) !*GitClone {
        const git_clone = try builder.allocator.create(GitClone);
        git_clone.* = .{
            .step = std.build.Step.initNoOp(.custom, "git pull", builder.allocator),
        };
        const repo_name = std.fs.path.basename(repo);
        if (!std.mem.endsWith(u8, repo_name, ".git")) {
            return error.InvalidRepoName;
        }
        const repo_path = try std.fs.path.join(
            builder.allocator,
            &.{ dir, repo_name[0 .. repo_name.len - 4] },
        );
        defer builder.allocator.free(repo_path);
        var repo_exists = true;
        var repo_dir: ?std.fs.Dir = std.fs.cwd().openDir(repo_path, .{}) catch |e| block: {
            switch (e) {
                error.FileNotFound => {
                    repo_exists = false;
                    break :block null;
                },
                else => return e,
            }
        };
        // todo: check if commit is same as well
        if (repo_exists) {
            repo_dir.?.close();
            return git_clone;
        }

        try std.fs.cwd().makePath(dir);

        var clone_args = std.ArrayList([]const u8).init(builder.allocator);
        defer clone_args.deinit();

        try clone_args.append("git");
        try clone_args.append("clone");
        if (recursive) {
            try clone_args.append("--recurse-submodules");
            try clone_args.append("-j8");
        }
        try clone_args.append(try builder.allocator.dupe(u8, repo));

        const clone = builder.addSystemCommand(clone_args.items);
        clone.cwd = try builder.allocator.dupe(u8, dir);

        var checkout_args = std.ArrayList([]const u8).init(builder.allocator);
        defer checkout_args.deinit();

        try checkout_args.append("git");
        try checkout_args.append("checkout");
        if (recursive) {
            try checkout_args.append("--recurse-submodules");
        }
        try checkout_args.append(try builder.allocator.dupe(u8, commit));
        try checkout_args.append(".");

        const checkout = builder.addSystemCommand(checkout_args.items);
        checkout.cwd = try builder.allocator.dupe(u8, repo_path);
        checkout.step.dependOn(&clone.step);

        git_clone.step.dependOn(&checkout.step);
        return git_clone;
    }
};
