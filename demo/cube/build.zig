const bake = @import("../../src/bake.zig");
const build_cc = @import("../../build.zig");
const std = @import("std");

pub fn build(builder: *std.build.Builder) !void {
    const options = build_cc.Options.init(builder);
    const dest_dir = try build_cc.getDestDir(builder, options, "cube");
    const recipe = build_cc.Recipe{
        .dir = "demo/cube",
        .items = &.{
            .{ .bake_type = bake.Shader, .path = "cube_vert.wgsl", .embed = true },
            .{ .bake_type = bake.Shader, .path = "cube_frag.wgsl", .embed = true },
        },
    };
    const cube_pkg = std.build.Pkg{
        .name = "cube",
        .path = .{ .path = "demo/cube/cube.zig" },
        .dependencies = &.{
            build_cc.getBakePkg(builder, options, "cube", dest_dir, recipe),
            build_cc.getGfxPkg(),
            build_cc.getMathPkg(),
            build_cc.getResPkg(),
            build_cc.getTimePkg(),
            build_cc.getWndPkg(),
            build_cc.getWndGfxPkg(),
        },
    };
    _ = try build_cc.initMainLibExe(builder, options, dest_dir, cube_pkg);
}
