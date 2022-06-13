const build_cc = @import("../../build.zig");
const std = @import("std");

pub fn build(builder: *std.build.Builder) !void {
    const options = build_cc.Options.init(builder);
    const dest_dir = try build_cc.getDestDir(builder, options, "tri");
    const recipe = build_cc.Recipe{
        .dir = "demo/tri",
        .items = &.{
            .{
                .id = "tri_vert_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"tri_vert.wgsl"},
            },
            .{
                .id = "tri_frag_shader",
                .output = .pkg_embed,
                .bake_type = "shader",
                .deps = &.{"tri_frag.wgsl"},
            },
        },
    };
    const tri_pkg = std.build.Pkg{
        .name = "tri",
        .path = .{ .path = "demo/tri/tri.zig" },
        .dependencies = &.{
            build_cc.getBakePkg(builder, options, "tri", dest_dir, recipe),
            build_cc.getGfxPkg(),
            build_cc.getResPkg(),
            build_cc.getWndPkg(),
            build_cc.getWndGfxPkg(),
        },
    };
    _ = try build_cc.initMainLibExe(builder, options, dest_dir, tri_pkg);
}
