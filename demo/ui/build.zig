const bake = @import("../../src/bake.zig");
const build_cc = @import("../../build.zig");
const std = @import("std");

pub fn build(builder: *std.build.Builder) !void {
    const options = build_cc.Options.init(builder);
    const dest_dir = try build_cc.getDestDir(builder, options, "ui");
    const ui_pkg = std.build.Pkg{
        .name = "ui",
        .path = .{ .path = "demo/ui/ui.zig" },
        .dependencies = &.{
            build_cc.getGfxPkg(),
            build_cc.getMemPkg(),
            build_cc.getUiPkg(),
            build_cc.getUiGfxPkg(),
            build_cc.getUiResPkg(builder, options),
            build_cc.getWndPkg(),
            build_cc.getWndGfxPkg(),
        },
    };
    _ = try build_cc.initMainLibExe(builder, options, dest_dir, ui_pkg);
}
