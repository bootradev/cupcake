const build_app = @import("src/build_app.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
    texture,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .triangle;

    var app_options: build_app.AppOptions = switch (example) {
        .triangle => .{
            .name = "triangle",
            .root = "examples/triangle/triangle.zig",
            .res_dir = "examples/triangle",
            .res = &.{
                .{ .res_type = .shader, .path = "triangle_vert.wgsl", .embedded = true },
                .{ .res_type = .shader, .path = "triangle_frag.wgsl", .embedded = true },
            },
        },
        .cube => .{
            .name = "cube",
            .root = "examples/cube/cube.zig",
            .res_dir = "examples/cube",
            .res = &.{
                .{ .res_type = .shader, .path = "cube_vert.wgsl", .embedded = true },
                .{ .res_type = .shader, .path = "cube_frag.wgsl", .embedded = true },
            },
        },
        .texture => .{
            .name = "texture",
            .root = "examples/texture/texture.zig",
            .res_dir = "examples/texture",
            .res = &.{
                .{ .res_type = .shader, .path = "texture_vert.wgsl", .embedded = true },
                .{ .res_type = .shader, .path = "texture_frag.wgsl", .embedded = true },
            },
        },
    };

    try build_app.build(builder, build_app.BuildOptions.init(builder, app_options));
}
