const build_web = @import("build_web.zig");
const build_res = @import("build_res.zig");
const std = @import("std");

pub const Platform = enum {
    web,
};

pub const OptLevel = enum {
    debug,
    profile,
    release,
};

pub const GfxApi = enum {
    webgpu,
};

pub const AppOptions = struct {
    name: []const u8,
    root: []const u8,
    res_dir: []const u8 = "",
    res: []const build_res.BuildResource = &.{},
};

pub const BuildOptions = struct {
    app: AppOptions,
    platform: Platform,
    opt_level: OptLevel,
    gfx_api: GfxApi,
    log_enabled: bool,
    log_level: std.log.Level,

    pub fn init(builder: *std.build.Builder, app_options: AppOptions) BuildOptions {
        var build_options: BuildOptions = undefined;
        build_options.app = app_options;
        build_options.platform = builder.option(
            Platform,
            "platform",
            "target platform",
        ) orelse default_platform;
        build_options.opt_level = builder.option(
            OptLevel,
            "opt",
            "optimization level",
        ) orelse .debug;
        build_options.gfx_api = builder.option(
            GfxApi,
            "gfx",
            "graphics backend",
        ) orelse default_gfx_api;
        build_options.log_enabled = builder.option(
            bool,
            "log_enabled",
            "logging enabled",
        ) orelse (build_options.opt_level == .debug);
        build_options.log_level = builder.option(
            std.log.Level,
            "log_level",
            "log level",
        ) orelse switch (build_options.opt_level) {
            .debug, .profile => std.log.Level.debug,
            .release => std.log.Level.err,
        };
        return build_options;
    }
};

const default_platform = .web;
const default_gfx_api = .webgpu;

pub fn build(builder: *std.build.Builder, build_options: BuildOptions) !void {
    const app_lib_exe = switch (build_options.platform) {
        .web => try buildWeb(builder, build_options),
    };

    const build_res_step = try build_res.BuildResStep.create(builder, build_options);
    app_lib_exe.step.dependOn(&build_res_step.step);

    const mode: std.builtin.Mode = switch (build_options.opt_level) {
        .debug => .Debug,
        .profile => .ReleaseSafe,
        .release => .ReleaseFast,
    };
    app_lib_exe.setBuildMode(mode);

    const cfg = builder.addOptions();
    cfg.addOption(Platform, "platform", build_options.platform);
    cfg.addOption(GfxApi, "gfx_api", build_options.gfx_api);
    cfg.addOption(OptLevel, "opt_level", build_options.opt_level);
    cfg.addOption(std.log.Level, "log_level", build_options.log_level);
    cfg.addOption(bool, "log_enabled", build_options.log_enabled);
    app_lib_exe.step.dependOn(&cfg.step);

    const cfg_pkg = cfg.getPackage("cfg");
    const cupcake_pkg = std.build.Pkg{
        .name = "cupcake",
        .path = .{ .path = "src/cupcake.zig" },
        .dependencies = &.{cfg_pkg},
    };
    const res_pkg = std.build.Pkg{
        .name = "res",
        .path = std.build.FileSource{ .generated = &build_res_step.generated_file },
        .dependencies = &.{cupcake_pkg},
    };
    const app_pkg = std.build.Pkg{
        .name = "app",
        .path = .{ .path = build_options.app.root },
        .dependencies = &.{ cfg_pkg, res_pkg, cupcake_pkg },
    };

    app_lib_exe.addPackage(cfg_pkg);
    app_lib_exe.addPackage(cupcake_pkg);
    app_lib_exe.addPackage(app_pkg);

    app_lib_exe.install();
}

fn buildWeb(
    builder: *std.build.Builder,
    build_options: BuildOptions,
) !*std.build.LibExeObjStep {
    const app_lib_exe = builder.addSharedLibrary(
        build_options.app.name,
        "src/main.zig",
        .unversioned,
    );

    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });
    app_lib_exe.setTarget(target);

    const build_web_step = try build_web.BuildWebStep.create(builder, build_options, "src");
    builder.getInstallStep().dependOn(&build_web_step.step);

    return app_lib_exe;
}
