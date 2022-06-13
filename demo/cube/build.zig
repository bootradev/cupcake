const build_cc = @import("../../build.zig");
const std = @import("std");

pub fn build(builder: *std.build.Builder) !void {
    const options = build_cc.Options.init(builder);
    const dest_dir = try build_cc.getDestDir(builder, options, "cube");
    const recipe = build_cc.Recipe{
        .dir = "demo/cube",
        .items = &.{
            .{
                .id = "cube_vert_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"cube_vert.wgsl"},
            },
            .{
                .id = "cube_frag_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"cube_frag.wgsl"},
            },
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
