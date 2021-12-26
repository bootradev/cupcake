const std = @import("std");

const Example = enum {
    triangle,
    cube,
};

pub const AppOptions = struct {
    app_name: []const u8,
    app_root: []const u8,
    shader_dir: []const u8 = "",
    shader_names: []const []const u8 = &.{},
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .cube;

    var app_options: AppOptions = switch (example) {
        .triangle => .{
            .app_name = "triangle",
            .app_root = "examples/triangle/triangle.zig",
            .shader_names = &.{ "triangle_vert", "triangle_frag" },
            .shader_dir = "examples/triangle",
        },
        .cube => .{
            .app_name = "cube",
            .app_root = "examples/cube/cube.zig",
            .shader_names = &.{ "cube_vert", "cube_frag" },
            .shader_dir = "examples/cube",
        },
    };

    try buildApp(builder, &app_options);
}

const Platform = enum {
    web,
};

const OptLevel = enum {
    debug,
    release,
};

const GfxApi = enum {
    webgpu,
};

const BuildOptions = struct {
    app_name: []const u8,
    app_root: []const u8,
    platform: Platform,
    opt_level: OptLevel,
    gfx_api: GfxApi,
};

const default_platform = .web;
const default_gfx_api = .webgpu;

pub fn buildApp(builder: *std.build.Builder, app_options: *const AppOptions) !void {
    const platform = builder.option(
        Platform,
        "platform",
        "target platform",
    ) orelse default_platform;

    const opt_level = builder.option(
        OptLevel,
        "opt",
        "optimization level",
    ) orelse .debug;

    const gfx_api = builder.option(
        GfxApi,
        "gfx",
        "graphics backend",
    ) orelse default_gfx_api;

    const build_options = BuildOptions{
        .app_name = app_options.app_name,
        .app_root = app_options.app_root,
        .platform = platform,
        .opt_level = opt_level,
        .gfx_api = gfx_api,
    };

    const app_lib_exe = switch (build_options.platform) {
        .web => try buildWeb(builder, &build_options),
    };

    const shader_build = try ShaderBuildStep.create(
        builder,
        app_options.shader_dir,
        app_options.shader_names,
        &build_options,
    );
    app_lib_exe.step.dependOn(&shader_build.step);

    const mode: std.builtin.Mode = switch (build_options.opt_level) {
        .debug => .Debug,
        .release => .ReleaseFast,
    };
    app_lib_exe.setBuildMode(mode);

    const cfg = builder.addOptions();
    cfg.addOption(Platform, "platform", build_options.platform);
    cfg.addOption(GfxApi, "gfx_api", build_options.gfx_api);
    cfg.addOption(bool, "log_enabled", build_options.opt_level != .release);
    app_lib_exe.step.dependOn(&cfg.step);

    const shader_pkg = shader_build.getPackage("shaders");
    const cfg_pkg = cfg.getPackage("cfg");
    const cupcake_pkg = std.build.Pkg{
        .name = "cupcake",
        .path = .{ .path = "src/cupcake.zig" },
        .dependencies = &.{cfg_pkg},
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = build_options.app_root },
        .dependencies = &.{ cfg_pkg, cupcake_pkg, shader_pkg },
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(cupcake_pkg);
    app_lib_exe.addPackage(app_pkg);

    app_lib_exe.install();
}

fn buildWeb(
    builder: *std.build.Builder,
    build_options: *const BuildOptions,
) !*std.build.LibExeObjStep {
    const app_lib_exe = builder.addSharedLibrary(
        build_options.app_name,
        "src/main.zig",
        .unversioned,
    );

    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });
    app_lib_exe.setTarget(target);

    const web_pack = try WebPackStep.create(builder, build_options, "src");
    builder.getInstallStep().dependOn(&web_pack.step);

    return app_lib_exe;
}

const ShaderBuildStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    contents: std.ArrayList(u8),
    dir: []const u8,
    names: []const []const u8,
    app_name: []const u8,
    gfx_api: GfxApi,
    opt_level: OptLevel,
    generated_file: std.build.GeneratedFile,

    pub fn create(
        builder: *std.build.Builder,
        dir: []const u8,
        names: []const []const u8,
        build_options: *const BuildOptions,
    ) !*ShaderBuildStep {
        const shader_build = try builder.allocator.create(ShaderBuildStep);
        shader_build.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "shader build", builder.allocator, make),
            .contents = std.ArrayList(u8).init(builder.allocator),
            .dir = dir,
            .names = names,
            .app_name = build_options.app_name,
            .gfx_api = build_options.gfx_api,
            .opt_level = build_options.opt_level,
            .generated_file = undefined,
        };
        shader_build.generated_file = .{ .step = &shader_build.step };

        return shader_build;
    }

    fn make(step: *std.build.Step) !void {
        const shader_build = @fieldParentPtr(ShaderBuildStep, "step", step);

        const shader_dir_path = try std.fs.path.join(
            shader_build.builder.allocator,
            &.{ shader_build.builder.build_root, shader_build.dir },
        );
        defer shader_build.builder.allocator.free(shader_dir_path);

        var shader_dir = try std.fs.openDirAbsolute(shader_dir_path, .{});
        defer shader_dir.close();

        const writer = shader_build.contents.writer();
        for (shader_build.names) |shader_name| {
            const shader_ext = switch (shader_build.gfx_api) {
                .webgpu => ".wgsl",
            };

            const shader_path = try std.mem.concat(
                shader_build.builder.allocator,
                u8,
                &.{ shader_name, shader_ext },
            );
            defer shader_build.builder.allocator.free(shader_path);

            const shader_file = try shader_dir.openFile(shader_path, .{});
            defer shader_file.close();

            const shader_bytes = try shader_file.readToEndAlloc(
                shader_build.builder.allocator,
                (try shader_file.stat()).size,
            );
            defer shader_build.builder.allocator.free(shader_bytes);

            const shader_bytes_min = try Minify.shader(
                shader_bytes,
                shader_build.builder.allocator,
                shader_build.opt_level,
                shader_build.gfx_api,
            );
            defer shader_build.builder.allocator.free(shader_bytes_min);

            try writer.print("pub const {s} = \"{s}\";\n", .{ shader_name, shader_bytes_min });
        }

        const shader_build_dir_path = try std.fs.path.join(
            shader_build.builder.allocator,
            &.{
                shader_build.builder.build_root,
                shader_build.builder.cache_root,
                "shader_build",
            },
        );
        defer shader_build.builder.allocator.free(shader_build_dir_path);

        try std.fs.cwd().makePath(shader_build_dir_path);

        const shader_build_src_file_name = try std.mem.concat(
            shader_build.builder.allocator,
            u8,
            &.{ shader_build.app_name, "_", @tagName(shader_build.gfx_api) },
        );
        defer shader_build.builder.allocator.free(shader_build_src_file_name);

        const shader_build_src_file_path = try std.fs.path.join(
            shader_build.builder.allocator,
            &.{ shader_build_dir_path, shader_build_src_file_name },
        );
        defer shader_build.builder.allocator.free(shader_build_src_file_path);

        try std.fs.cwd().writeFile(shader_build_src_file_path, shader_build.contents.items);
        shader_build.contents.deinit();

        shader_build.generated_file.path = try std.mem.dupe(
            shader_build.builder.allocator,
            u8,
            shader_build_src_file_path,
        );
    }

    pub fn getPackage(shader_build: ShaderBuildStep, package_name: []const u8) std.build.Pkg {
        return .{
            .name = package_name,
            .path = std.build.FileSource{ .generated = &shader_build.generated_file },
        };
    }
};

const WebPackStep = struct {
    // intentional ordering to prevent dependency issues
    const js_srcs: []const []const u8 = &.{
        "utils.js",
        "main_web.js",
        "app_web.js",
        "gfx_webgpu.js",
    };
    const js_name = "cupcake.js";

    builder: *std.build.Builder,
    step: std.build.Step,
    opt_level: OptLevel,
    gfx_api: GfxApi,
    html_name: []const u8,
    wasm_name: []const u8,
    js_dir: []const u8,

    pub fn create(
        builder: *std.build.Builder,
        build_options: *const BuildOptions,
        js_dir: []const u8,
    ) !*WebPackStep {
        const web_pack = try builder.allocator.create(WebPackStep);
        const name = build_options.app_name;
        web_pack.* = WebPackStep{
            .builder = builder,
            .step = std.build.Step.init(.custom, "web pack", builder.allocator, make),
            .opt_level = build_options.opt_level,
            .gfx_api = build_options.gfx_api,
            .html_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".html" }),
            .wasm_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".wasm" }),
            .js_dir = try builder.allocator.dupe(u8, js_dir),
        };

        builder.pushInstalledFile(.lib, web_pack.html_name);
        builder.pushInstalledFile(.lib, js_name);

        return web_pack;
    }

    fn make(step: *std.build.Step) !void {
        const web_pack = @fieldParentPtr(WebPackStep, "step", step);

        var lib_dir = try std.fs.cwd().makeOpenPath(web_pack.builder.lib_dir, .{});
        defer lib_dir.close();

        const html_file = try lib_dir.createFile(web_pack.html_name, .{ .truncate = true });
        defer html_file.close();

        try std.fmt.format(
            html_file.writer(),
            @embedFile("examples/template.html"),
            .{web_pack.wasm_name},
        );

        const js_file = try lib_dir.createFile(js_name, .{ .truncate = true });
        defer js_file.close();

        const js_src_dir_path = try std.fs.path.join(
            web_pack.builder.allocator,
            &.{ web_pack.builder.build_root, web_pack.js_dir },
        );
        defer web_pack.builder.allocator.free(js_src_dir_path);

        var js_src_dir = try std.fs.openDirAbsolute(js_src_dir_path, .{});
        defer js_src_dir.close();

        var js_file_contents = std.ArrayList(u8).init(web_pack.builder.allocator);
        inline for (js_srcs) |js_src| {
            const src_file = try js_src_dir.openFile(js_src, .{});
            defer src_file.close();

            const src_bytes = try src_file.readToEndAlloc(
                web_pack.builder.allocator,
                (try src_file.stat()).size,
            );
            defer web_pack.builder.allocator.free(src_bytes);

            try js_file_contents.appendSlice(src_bytes[0..]);
            try js_file_contents.appendSlice("\n");
        }

        if (web_pack.opt_level == .release) {
            const src_bytes_min = try Minify.js(
                js_file_contents.items,
                web_pack.builder.allocator,
                .release,
            );
            defer web_pack.builder.allocator.free(src_bytes_min);
            try js_file.writeAll(src_bytes_min);
        } else {
            try js_file.writeAll(js_file_contents.items);
        }
        js_file_contents.deinit();
    }
};

const Minify = struct {
    const Language = enum {
        js,
        wgsl,
    };

    const keywords_js: []const []const u8 = &.{
        "document",
        "window",
        "WebAssembly",
        "navigator",
        "performance",
        "JSON",
        "console",
        "class",
        "this",
        "function",
        "const",
        "let",
        "var",
        "undefined",
        "catch",
        "if",
        "else",
        "switch",
        "case",
        "break",
        "do",
        "while",
        "for",
        "return",
        "new",
        "null",
        "true",
        "false",
        "Objs",
    };

    const keywords_wgsl: []const []const u8 = &.{
        "block",
        "binding",
        "group",
        "uniform",
        "builtin",
        "position",
        "location",
        "stage",
        "vertex",
        "fragment",
        "vertex_index",
        "struct",
        "fn",
        "var",
        "let",
        "return",
        "i32",
        "u32",
        "f32",
        "vec4",
        "mat4x4",
    };

    const ParseChar = enum {
        symbol, // a non-whitespace, non-identifier character. see symbols, below
        ident, // a non-whitespce, non-symbol character (an identifier)
        whitespace, // a whitespace character
    };

    const symbols = "{}()[]=<>;:.,|/-+*!&?";
    const str_symbols = "\"'`";
    const max_ident_size = 2;
    const next_ident_symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

    allocator: *std.mem.Allocator,
    src: []const u8,
    out: std.ArrayList(u8),
    start_index: usize,
    end_index: usize,
    cur_char: ParseChar,
    cur_write_char: ParseChar,
    ident_map: std.StringHashMap([]const u8),
    next_ident: [max_ident_size]u8,
    next_ident_index: [max_ident_size]usize,
    next_ident_size: usize,
    language: Language,
    opt_level: OptLevel,

    fn init(
        src: []const u8,
        allocator: *std.mem.Allocator,
        language: Language,
        opt_level: OptLevel,
    ) Minify {
        var ctx = Minify{
            .allocator = allocator,
            .src = src,
            .out = std.ArrayList(u8).init(allocator),
            .start_index = 0,
            .end_index = 0,
            .cur_char = .whitespace,
            .cur_write_char = .whitespace,
            .ident_map = std.StringHashMap([]const u8).init(allocator),
            .next_ident = [_]u8{'a'} ** max_ident_size,
            .next_ident_index = [_]usize{0} ** max_ident_size,
            .next_ident_size = 1,
            .language = language,
            .opt_level = opt_level,
        };

        return ctx;
    }

    fn deinit(ctx: *Minify) void {
        var it = ctx.ident_map.iterator();
        while (it.next()) |kv| {
            ctx.allocator.free(kv.value_ptr.*);
        }
        ctx.ident_map.deinit();
    }

    pub fn js(src: []const u8, allocator: *std.mem.Allocator, opt_level: OptLevel) ![]const u8 {
        var ctx = Minify.init(src, allocator, .js, opt_level);
        defer ctx.deinit();

        return try ctx.minify();
    }

    pub fn shader(
        src: []const u8,
        allocator: *std.mem.Allocator,
        opt_level: OptLevel,
        gfx_api: GfxApi,
    ) ![]const u8 {
        const lang = switch (gfx_api) {
            .webgpu => .wgsl,
        };

        var ctx = Minify.init(src, allocator, lang, opt_level);
        defer ctx.deinit();

        return try ctx.minify();
    }

    fn minify(ctx: *Minify) ![]const u8 {
        while (ctx.end_index < ctx.src.len) {
            const char = ctx.src[ctx.end_index];
            if (ctx.end_index < ctx.src.len - 1 and
                char == '/' and
                (ctx.src[ctx.end_index + 1] == '/' or ctx.src[ctx.end_index + 1] == '*'))
            {
                try ctx.handleComment();
            } else if (std.mem.indexOfScalar(u8, symbols, char) != null) {
                try ctx.handleChar(.symbol);
            } else if (std.mem.indexOfScalar(u8, str_symbols, char) != null) {
                try ctx.handleString();
            } else if (std.mem.indexOfScalar(u8, &std.ascii.spaces, char) == null) {
                try ctx.handleChar(.ident);
            } else {
                try ctx.handleChar(.whitespace);
            }
        }

        return ctx.out.toOwnedSlice();
    }

    fn handleChar(ctx: *Minify, char: ParseChar) !void {
        if (ctx.cur_char != char) {
            if (ctx.cur_char == .symbol) {
                try ctx.appendSymbol();
            } else if (ctx.cur_char == .ident) {
                try ctx.appendIdent();
            }

            if (char != .whitespace) {
                // append a space between two different identifiers
                if (ctx.cur_write_char == .ident and char == .ident) {
                    try ctx.out.append(' ');
                }

                // chrome wgsl parser is broken, this works around the issue...
                if (ctx.language == .wgsl and ctx.cur_write_char == .symbol and char == .ident) {
                    const wgsl_skip = "{([]<>=:;,.";
                    const last_write_char = ctx.out.items[ctx.out.items.len - 1];
                    if (std.mem.indexOfScalar(u8, wgsl_skip, last_write_char) == null) {
                        try ctx.out.append(' ');
                    }
                }

                ctx.cur_write_char = char;
            }
            ctx.cur_char = char;
            ctx.start_index = ctx.end_index;
        }
        ctx.end_index += 1;
    }

    fn handleString(ctx: *Minify) !void {
        try ctx.handleChar(.whitespace);

        const char = ctx.src[ctx.end_index - 1];
        ctx.start_index = ctx.end_index - 1;
        while (ctx.end_index < ctx.src.len and ctx.src[ctx.end_index] != char) {
            ctx.end_index += 1;
        }
        ctx.end_index += 1;

        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn handleComment(ctx: *Minify) !void {
        try ctx.handleChar(.whitespace);
        const char = ctx.src[ctx.end_index];
        if (char == '/') {
            while (ctx.src[ctx.end_index] != '\n') {
                ctx.end_index += 1;
            }
        } else {
            while (ctx.end_index < ctx.src.len - 1 and
                ctx.src[ctx.end_index] != '*' and
                ctx.src[ctx.end_index + 1] != '/')
            {
                ctx.end_index += 1;
            }
        }
    }

    fn appendSymbol(ctx: *Minify) !void {
        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn appendIdent(ctx: *Minify) !void {
        const ident = ctx.src[ctx.start_index..ctx.end_index];
        if (ctx.opt_level == .debug or
            ctx.isKeyword(ident) or
            std.ascii.isDigit(ident[0]) or
            ctx.src[ctx.end_index] == '(')
        {
            try ctx.out.appendSlice(ident);
        } else if (ctx.ident_map.getEntry(ident)) |entry| {
            try ctx.out.appendSlice(entry.value_ptr.*);
        } else if (ctx.start_index > 0 and
            ctx.src[ctx.start_index - 1] == '.' and
            ctx.start_index > 1 and
            ctx.src[ctx.start_index - 2] != '.')
        {
            try ctx.out.appendSlice(ident);
        } else {
            const next_ident = try ctx.nextIdent();
            try ctx.ident_map.put(ident, next_ident);
            try ctx.out.appendSlice(next_ident);
        }
    }

    fn nextIdent(ctx: *Minify) ![]const u8 {
        const next = ctx.allocator.dupe(u8, ctx.next_ident[0..ctx.next_ident_size]);

        var cur_index = ctx.next_ident_size - 1;
        if (ctx.next_ident_index[cur_index] == next_ident_symbols.len - 1) {
            ctx.setNextIdent(cur_index, 0);
            var out_of_idents = true;
            while (cur_index != 0) {
                cur_index -= 1;
                if (ctx.next_ident_index[cur_index] == next_ident_symbols.len - 1) {
                    ctx.setNextIdent(cur_index, 0);
                } else {
                    ctx.setNextIdent(cur_index, ctx.next_ident_index[cur_index] + 1);
                    out_of_idents = false;
                    break;
                }
            }

            if (out_of_idents) {
                ctx.next_ident_size += 1;
                if (ctx.next_ident_size > max_ident_size) {
                    return error.MaxIdentsExceeded;
                }
            }
        } else {
            ctx.setNextIdent(cur_index, ctx.next_ident_index[cur_index] + 1);
        }

        return next;
    }

    fn setNextIdent(ctx: *Minify, ident_index: usize, symbol_index: usize) void {
        ctx.next_ident_index[ident_index] = symbol_index;
        ctx.next_ident[ident_index] = next_ident_symbols[symbol_index];
    }

    fn isKeyword(ctx: *Minify, slice: []const u8) bool {
        const keywords = switch (ctx.language) {
            .js => keywords_js,
            .wgsl => keywords_wgsl,
        };
        return for (keywords) |keyword| {
            if (std.mem.eql(u8, keyword, slice)) {
                return true;
            }
        } else false;
    }
};
