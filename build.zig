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
};

const BuildOptions = struct {
    app_name: []const u8,
    app_src_root: []const u8,
    platform: Platform,
    opt_level: OptLevel,
    gfx_backend: GfxBackend,
};

const default_platform = .web;
const default_gfx_backend = .webgpu;

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .tri;

    const app_name = switch (example) {
        .tri => "tri",
    };

    const app_src_root = switch (example) {
        .tri => "src/examples/tri.zig",
    };

    try buildApp(builder, app_name, app_src_root);
}

pub fn buildApp(builder: *std.build.Builder, app_name: []const u8, app_src_root: []const u8) !void {
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
        .app_name = app_name,
        .app_src_root = app_src_root,
        .platform = platform,
        .opt_level = opt_level,
        .gfx_backend = gfx_backend,
    };

    const app_lib_exe = switch (build_options.platform) {
        .web => try buildWeb(builder, &build_options),
    };

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

    const cfg_pkg = cfg.getPackage("cfg");
    const bootra_pkg = std.build.Pkg{
        .name = "bootra",
        .path = .{ .path = "src/bootra.zig" },
        .dependencies = &[_]std.build.Pkg{cfg_pkg},
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = build_options.app_src_root },
        .dependencies = &[_]std.build.Pkg{ cfg_pkg, bootra_pkg },
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

    const js_dir = try std.fs.path.join(builder.allocator, &.{ builder.build_root, "src/web" });
    defer builder.allocator.free(js_dir);

    const web_pack = try WebPackStep.create(builder, build_options, js_dir);
    builder.getInstallStep().dependOn(&web_pack.step);

    return app_lib_exe;
}

const WebPackStep = struct {
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

        const html_fmt = @embedFile("src/web/template.html");
        try std.fmt.format(html_file.writer(), html_fmt, .{ web_pack.js_name, web_pack.wasm_name });

        const js_file = try lib_dir.createFile(web_pack.js_name, .{ .truncate = true });
        defer js_file.close();

        var js_src_dir = try std.fs.openDirAbsolute(web_pack.js_dir, .{ .iterate = true });
        defer js_src_dir.close();

        var js_src_iterator = js_src_dir.iterate();
        while (try js_src_iterator.next()) |src_file_entry| {
            if (!std.mem.endsWith(u8, src_file_entry.name, ".js")) {
                continue;
            }

            const src_file = try js_src_dir.openFile(src_file_entry.name, .{});
            defer src_file.close();

            const src_stat = try src_file.stat();
            const src_bytes = try src_file.readToEndAlloc(web_pack.builder.allocator, src_stat.size);
            defer web_pack.builder.allocator.free(src_bytes);

            if (web_pack.opt_level == .release) {
                const src_bytes_min = try minifyJS(src_bytes, web_pack.builder.allocator);
                defer web_pack.builder.allocator.free(src_bytes_min);
                try js_file.writeAll(src_bytes_min);
            } else {
                try js_file.writeAll(src_bytes[0..]);
                try js_file.writeAll("\n");
            }
        }
    }

    fn minifyJS(src_bytes: []const u8, allocator: *std.mem.Allocator) ![]const u8 {
        const src_bytes_min = try allocator.alloc(u8, src_bytes.len);

        var write_index: usize = 0;
        for (src_bytes) |byte, read_index| {
            var write_byte = false;
            if (byte == ' ' and write_index > 0 and read_index < src_bytes.len - 1) {
                const symbols = "{}()[]=<>;,:|/-+* ";
                const last_byte = src_bytes_min[write_index - 1];
                const next_byte = src_bytes[read_index + 1];
                const prev_write = std.mem.indexOfScalar(u8, symbols, last_byte) == null;
                const next_write = std.mem.indexOfScalar(u8, symbols, next_byte) == null;
                write_byte = prev_write and next_write;
            } else {
                write_byte = std.mem.indexOfScalar(u8, &std.ascii.spaces, byte) == null;
            }

            if (write_byte) {
                src_bytes_min[write_index] = byte;
                write_index += 1;
            }
        }

        return src_bytes_min[0..write_index];
    }
};
