const build_app = @import("src/build_app.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .triangle;

    var manifest_desc: build_app.ManifestDesc = switch (example) {
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
                .{ .path = "cupcake.png" },
            },
        },
    };

    try build_app.build(builder, manifest_desc);
}
