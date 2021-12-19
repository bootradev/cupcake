const std = @import("std");

const Platform = enum {
    web,
};

const OptLevel = enum {
    debug,
    release,
};

const GfxBackend = enum {
    webgpu,
};

const Example = enum {
    tri,
    cube,
};

const BuildOptions = struct {
    app_name: []const u8,
    app_src_root: []const u8,
    platform: Platform,
    opt_level: OptLevel,
    gfx_backend: GfxBackend,
};

pub const AppOptions = struct {
    app_name: []const u8,
    app_src_root: []const u8,
    shader_dir: []const u8 = "",
    shader_names: []const []const u8 = &.{},
};

const default_platform = .web;
const default_gfx_backend = .webgpu;

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .cube;

    var app_options: AppOptions = switch (example) {
        .tri => .{
            .app_name = "tri",
            .app_src_root = "examples/tri/tri.zig",
            .shader_names = &.{ "tri_vert", "tri_frag" },
            .shader_dir = "examples/tri",
        },
        .cube => .{
            .app_name = "cube",
            .app_src_root = "examples/cube/cube.zig",
            .shader_names = &.{ "cube_vert", "cube_frag" },
            .shader_dir = "examples/cube",
        },
    };

    try buildApp(builder, &app_options);
}

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

    const gfx_backend = builder.option(
        GfxBackend,
        "gfx",
        "graphics backend",
    ) orelse default_gfx_backend;

    const build_options = BuildOptions{
        .app_name = app_options.app_name,
        .app_src_root = app_options.app_src_root,
        .platform = platform,
        .opt_level = opt_level,
        .gfx_backend = gfx_backend,
    };

    const app_lib_exe = switch (build_options.platform) {
        .web => try buildWeb(builder, &build_options),
    };

    const shader_build = try ShaderBuildStep.create(
        builder,
        app_options.shader_dir,
        app_options.shader_names,
        build_options.gfx_backend,
    );
    app_lib_exe.step.dependOn(&shader_build.step);

    const mode: std.builtin.Mode = switch (build_options.opt_level) {
        .debug => .Debug,
        .release => .ReleaseFast,
    };
    app_lib_exe.setBuildMode(mode);

    const cfg = builder.addOptions();
    cfg.addOption(Platform, "platform", build_options.platform);
    cfg.addOption(GfxBackend, "gfx_backend", build_options.gfx_backend);
    cfg.addOption(bool, "log_enabled", build_options.opt_level != .release);
    app_lib_exe.step.dependOn(&cfg.step);

    const shader_pkg = shader_build.getPackage("shaders");
    const cfg_pkg = cfg.getPackage("cfg");
    const bootra_pkg = std.build.Pkg{
        .name = "bootra",
        .path = .{ .path = "src/bootra.zig" },
        .dependencies = &.{cfg_pkg},
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = build_options.app_src_root },
        .dependencies = &.{ cfg_pkg, bootra_pkg, shader_pkg },
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(bootra_pkg);
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

    const js_dir = try std.fs.path.join(builder.allocator, &.{ builder.build_root, "src" });
    defer builder.allocator.free(js_dir);

    const web_pack = try WebPackStep.create(builder, build_options, js_dir);
    builder.getInstallStep().dependOn(&web_pack.step);

    return app_lib_exe;
}

const ShaderBuildStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    contents: std.ArrayList(u8),
    dir: []const u8,
    names: []const []const u8,
    gfx_backend: GfxBackend,
    generated_file: std.build.GeneratedFile,

    pub fn create(
        builder: *std.build.Builder,
        dir: []const u8,
        names: []const []const u8,
        gfx_backend: GfxBackend,
    ) !*ShaderBuildStep {
        const shader_build = try builder.allocator.create(ShaderBuildStep);
        shader_build.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "shader build", builder.allocator, make),
            .contents = std.ArrayList(u8).init(builder.allocator),
            .dir = dir,
            .names = names,
            .gfx_backend = gfx_backend,
            .generated_file = undefined,
        };
        shader_build.generated_file = .{ .step = &shader_build.step };

        return shader_build;
    }

    fn make(step: *std.build.Step) !void {
        const shader_build = @fieldParentPtr(ShaderBuildStep, "step", step);

        var shader_dir = try std.fs.openDirAbsolute(
            shader_build.builder.pathFromRoot(
                try std.fs.path.join(
                    shader_build.builder.allocator,
                    &.{shader_build.dir},
                ),
            ),
            .{},
        );
        defer shader_dir.close();

        const writer = shader_build.contents.writer();
        for (shader_build.names) |name| {
            const shader_name = try std.mem.concat(
                shader_build.builder.allocator,
                u8,
                &.{ name, ".wgsl" },
            );

            const shader_file = try shader_dir.openFile(shader_name, .{});
            defer shader_file.close();

            const shader_stat = try shader_file.stat();
            const shader_bytes = try shader_file.readToEndAlloc(
                shader_build.builder.allocator,
                shader_stat.size,
            );
            const shader_bytes_min = try minifySource(
                shader_bytes,
                shader_build.builder.allocator,
                .single_space,
            );
            try writer.print("pub const {s} = \"{s}\";\n", .{ name, shader_bytes_min });
        }

        const shader_build_dir = shader_build.builder.pathFromRoot(
            try std.fs.path.join(
                shader_build.builder.allocator,
                &.{ shader_build.builder.cache_root, "shader_build" },
            ),
        );

        try std.fs.cwd().makePath(shader_build_dir);

        const shader_build_src_file_name = @tagName(shader_build.gfx_backend);

        const shader_build_src_file = try std.fs.path.join(
            shader_build.builder.allocator,
            &.{ shader_build_dir, shader_build_src_file_name },
        );

        try std.fs.cwd().writeFile(shader_build_src_file, shader_build.contents.items);

        shader_build.generated_file.path = shader_build_src_file;
    }

    pub fn getPackage(shader_build: ShaderBuildStep, package_name: []const u8) std.build.Pkg {
        return .{
            .name = package_name,
            .path = std.build.FileSource{ .generated = &shader_build.generated_file },
        };
    }
};

const WebPackStep = struct {
    const js_srcs: []const []const u8 = &.{
        "main_web.js",
        "utils.js",
        "app_web.js",
        "gfx_webgpu.js",
    };

    builder: *std.build.Builder,
    step: std.build.Step,
    opt_level: OptLevel,
    gfx_backend: GfxBackend,
    html_name: []const u8,
    js_name: []const u8,
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
            .gfx_backend = build_options.gfx_backend,
            .html_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".html" }),
            .js_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".js" }),
            .wasm_name = try std.mem.concat(builder.allocator, u8, &.{ name, ".wasm" }),
            .js_dir = try builder.allocator.dupe(u8, js_dir),
        };

        builder.pushInstalledFile(.lib, web_pack.html_name);
        builder.pushInstalledFile(.lib, web_pack.js_name);

        return web_pack;
    }

    fn make(step: *std.build.Step) !void {
        const web_pack = @fieldParentPtr(WebPackStep, "step", step);

        var root_dir = try std.fs.openDirAbsolute(web_pack.builder.build_root, .{});
        defer root_dir.close();

        var lib_dir = try root_dir.makeOpenPath(web_pack.builder.lib_dir, .{});
        defer lib_dir.close();

        const html_file = try lib_dir.createFile(web_pack.html_name, .{ .truncate = true });
        defer html_file.close();

        const html_fmt = @embedFile("src/template.html");
        try std.fmt.format(html_file.writer(), html_fmt, .{ web_pack.js_name, web_pack.wasm_name });

        const js_file = try lib_dir.createFile(web_pack.js_name, .{ .truncate = true });
        defer js_file.close();

        var js_src_dir = try std.fs.openDirAbsolute(web_pack.js_dir, .{});
        defer js_src_dir.close();

        var js_file_contents = std.ArrayList(u8).init(web_pack.builder.allocator);
        inline for (js_srcs) |js_src| {
            const src_file = try js_src_dir.openFile(js_src, .{});
            defer src_file.close();

            const src_stat = try src_file.stat();
            const src_bytes = try src_file.readToEndAlloc(
                web_pack.builder.allocator,
                src_stat.size,
            );
            defer web_pack.builder.allocator.free(src_bytes);

            try js_file_contents.appendSlice(src_bytes[0..]);
            try js_file_contents.appendSlice("\n");
        }

        if (web_pack.opt_level == .release) {
            const src_bytes_min = try Minify.js(
                js_file_contents.items,
                web_pack.builder.allocator,
            );
            defer web_pack.builder.allocator.free(src_bytes_min);
            try js_file.writeAll(src_bytes_min);
        } else {
            try js_file.writeAll(js_file_contents.items);
        }
    }
};

const MinifyMode = enum {
    single_space,
    no_space,
};

fn minifySource(
    src_bytes: []const u8,
    allocator: *std.mem.Allocator,
    comptime mode: MinifyMode,
) ![]const u8 {
    const src_bytes_min = try allocator.alloc(u8, src_bytes.len);

    const ParseState = union(enum) {
        normal,
        line_comment,
        block_comment,
        string: u8,
    };
    var parse_state: ParseState = .normal;

    var write_index: usize = 0;
    for (src_bytes) |byte, read_index| {
        var write_byte = false;

        switch (parse_state) {
            .line_comment => {
                if (byte == '\n') {
                    parse_state = .normal;
                }
            },
            .block_comment => {
                if (byte == '/' and src_bytes[read_index - 1] == '*') {
                    parse_state = .normal;
                }
            },
            .string => |char| {
                if (byte == char and src_bytes[read_index - 1] != '\\') {
                    parse_state = .normal;
                }
                write_byte = true;
            },
            .normal => {
                if (byte == '/' and
                    read_index < src_bytes.len - 1 and
                    src_bytes[read_index + 1] == '/')
                {
                    parse_state = .line_comment;
                } else if (byte == '/' and
                    read_index < src_bytes.len - 1 and
                    src_bytes[read_index + 1] == '*')
                {
                    parse_state = .block_comment;
                } else if (std.mem.indexOfScalar(u8, "\"'`", byte) != null) {
                    parse_state = ParseState{ .string = byte };
                    write_byte = true;
                } else if (byte == ' ' and write_index > 0 and read_index < src_bytes.len - 1) {
                    const last_byte = src_bytes_min[write_index - 1];
                    const next_byte = src_bytes[read_index + 1];
                    switch (mode) {
                        .single_space => {
                            write_byte = last_byte != ' ' and next_byte != ' ';
                        },
                        .no_space => {
                            const symbols = "{}()[]=<>;,:|/-+*!& ";
                            const write_prev = std.mem.indexOfScalar(u8, symbols, last_byte);
                            const write_next = std.mem.indexOfScalar(u8, symbols, next_byte);
                            write_byte = write_prev == null and write_next == null;
                        },
                    }
                } else {
                    write_byte = std.mem.indexOfScalar(u8, &std.ascii.spaces, byte) == null;
                }
            },
        }

        if (write_byte) {
            src_bytes_min[write_index] = byte;
            write_index += 1;
        }
    }

    return src_bytes_min[0..write_index];
}

const Minify = struct {
    const ParseState = enum {
        sep,
        ident,
        whitespace,
    };

    const sep = "{}()[]=<>;:.,|/-+*!&";
    const string = "\"'`";
    const max_ident_size = 2;

    allocator: *std.mem.Allocator,
    src: []const u8,
    out: std.ArrayList(u8),
    start_index: usize,
    end_index: usize,
    cur_state: ParseState,
    cur_write_state: ParseState,
    ident_map: std.StringHashMap([]const u8),
    next_ident: [max_ident_size]u8,
    next_ident_size: usize,
    keywords: []const []const u8,

    pub fn js(src: []const u8, allocator: *std.mem.Allocator) ![]const u8 {
        const keywords: []const []const u8 = &.{
            "document",
            "window",
            "WebAssembly",
            "navigator",
            "performance",
            "JSON",
            "console",
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
            "true",
            "false",
        };
        var ctx = Minify.init(src, allocator, keywords);
        defer ctx.deinit();

        return try ctx.minify();
    }

    fn minify(ctx: *Minify) ![]const u8 {
        while (ctx.end_index < ctx.src.len) {
            const byte = ctx.src[ctx.end_index];
            if (ctx.end_index < ctx.src.len - 1 and
                byte == '/' and
                (ctx.src[ctx.end_index + 1] == '/' or ctx.src[ctx.end_index + 1] == '*'))
            {
                try ctx.handleComment();
            } else if (std.mem.indexOfScalar(u8, sep, byte)) |_| {
                try ctx.handleByte(.sep);
            } else if (std.mem.indexOfScalar(u8, string, byte) != null) {
                try ctx.handleString();
            } else if (std.mem.indexOfScalar(u8, &std.ascii.spaces, byte) == null) {
                try ctx.handleByte(.ident);
            } else {
                try ctx.handleByte(.whitespace);
            }
        }

        return ctx.out.toOwnedSlice();
    }

    fn init(src: []const u8, allocator: *std.mem.Allocator, keywords: []const []const u8) Minify {
        var ctx = Minify{
            .allocator = allocator,
            .src = src,
            .out = std.ArrayList(u8).init(allocator),
            .start_index = 0,
            .end_index = 0,
            .cur_state = .whitespace,
            .cur_write_state = .whitespace,
            .ident_map = std.StringHashMap([]const u8).init(allocator),
            .next_ident = [_]u8{'a'} ** max_ident_size,
            .next_ident_size = 1,
            .keywords = keywords,
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

    fn handleByte(ctx: *Minify, state: ParseState) !void {
        if (ctx.cur_state != state) {
            if (ctx.cur_state == .sep) {
                try ctx.appendSep();
            } else if (ctx.cur_state == .ident) {
                try ctx.appendIdent();
            }

            if (state != .whitespace) {
                if (ctx.cur_write_state == .ident and state == .ident) {
                    try ctx.out.append(' ');
                }
                ctx.cur_write_state = state;
            }
            ctx.cur_state = state;
            ctx.start_index = ctx.end_index;
        }
        ctx.end_index += 1;
    }

    fn handleString(ctx: *Minify) !void {
        try ctx.handleByte(.whitespace);

        const byte = ctx.src[ctx.end_index - 1];
        ctx.start_index = ctx.end_index - 1;
        while (ctx.end_index < ctx.src.len and ctx.src[ctx.end_index] != byte) {
            ctx.end_index += 1;
        }
        ctx.end_index += 1;

        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn handleComment(ctx: *Minify) !void {
        try ctx.handleByte(.whitespace);
        const byte = ctx.src[ctx.end_index];
        if (byte == '/') {
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

    fn appendSep(ctx: *Minify) !void {
        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn isKeyword(ctx: *Minify, slice: []const u8) bool {
        var is_keyword = false;
        for (ctx.keywords) |keyword| {
            if (std.mem.eql(u8, keyword, slice)) {
                is_keyword = true;
            }
        }
        return is_keyword;
    }

    fn appendIdent(ctx: *Minify) !void {
        const ident = ctx.src[ctx.start_index..ctx.end_index];
        if (ctx.isKeyword(ident) or std.ascii.isDigit(ident[0]) or ctx.src[ctx.end_index] == '(') {
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
            const new_ident = try ctx.nextPlacementIdent();
            try ctx.ident_map.put(ident, new_ident);
            try ctx.out.appendSlice(new_ident);
        }
    }

    fn nextPlacementIdent(ctx: *Minify) ![]const u8 {
        const next = ctx.allocator.dupe(u8, ctx.next_ident[0..ctx.next_ident_size]);
        var cur_index = ctx.next_ident_size - 1;
        if (ctx.next_ident[cur_index] == 'z') {
            ctx.next_ident[cur_index] = 'A';
        } else if (ctx.next_ident[cur_index] == 'Z') {
            var no_idents = true;
            while (true) : (cur_index -= 1) {
                if (ctx.next_ident[cur_index] == 'Z') {
                    ctx.next_ident[cur_index] = 'a';
                } else {
                    if (ctx.next_ident[cur_index] == 'z') {
                        ctx.next_ident[cur_index] = 'A';
                    } else {
                        ctx.next_ident[cur_index] += 1;
                    }
                    while (ctx.isKeyword(ctx.next_ident[0..ctx.next_ident_size])) {
                        ctx.next_ident[cur_index] += 1;
                    }
                    no_idents = false;
                    break;
                }

                if (cur_index == 0) {
                    break;
                }
            }

            if (no_idents) {
                ctx.next_ident_size += 1;
                if (ctx.next_ident_size > max_ident_size) {
                    return error.MaxIdentsExceeded;
                }
            }
        } else {
            ctx.next_ident[cur_index] += 1;
        }
        return next;
    }
};
