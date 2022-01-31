const build_app = @import("src/build_app.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
    texture,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .triangle;

    var manifest_desc: build_app.ManifestDesc = switch (example) {
        .triangle => .{
            .name = "triangle",
            .root = "examples/triangle/triangle.zig",
            .res_dir = "examples/triangle",
            .res = &.{
                .{ .res_type = .shader, .file_type = .embedded, .path = "triangle_vert.wgsl" },
                .{ .res_type = .shader, .file_type = .embedded, .path = "triangle_frag.wgsl" },
            },
        },
        .cube => .{
            .name = "cube",
            .root = "examples/cube/cube.zig",
            .res_dir = "examples/cube",
            .res = &.{
                .{ .res_type = .shader, .file_type = .embedded, .path = "cube_vert.wgsl" },
                .{ .res_type = .shader, .file_type = .embedded, .path = "cube_frag.wgsl" },
            },
        },
        .texture => .{
            .name = "texture",
            .root = "examples/texture/texture.zig",
            .res_dir = "examples/texture",
            .res = &.{
                .{ .res_type = .shader, .file_type = .embedded, .path = "texture_vert.wgsl" },
                .{ .res_type = .shader, .file_type = .embedded, .path = "texture_frag.wgsl" },
                .{ .res_type = .texture, .file_type = .file, .path = "cupcake.png" },
            },
        },
    };

    try build_app.build(builder, manifest_desc);
}
