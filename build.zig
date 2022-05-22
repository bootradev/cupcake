const make = @import("src/make.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
    ui,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .triangle;

    var manifest_desc: make.ManifestDesc = switch (example) {
        .triangle => .{
            .name = "triangle",
            .root = "examples/triangle/triangle.zig",
            .res_dir = "examples/triangle",
            .res = &.{
                .{ .path = "triangle_vert.wgsl", .embed = true },
                .{ .path = "triangle_frag.wgsl", .embed = true },
            },
        },
        .cube => .{
            .name = "cube",
            .root = "examples/cube/cube.zig",
            .res_dir = "examples/cube",
            .res = &.{
                .{ .path = "cube_vert.wgsl", .embed = true },
                .{ .path = "cube_frag.wgsl", .embed = true },
            },
        },
        .ui => .{
            .name = "ui",
            .root = "examples/ui/ui.zig",
        },
    };

    try make.build(builder, manifest_desc);
}
