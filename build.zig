const build_app = @import("src/build_app.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
    texture,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .cube;

    var app_options: build_app.AppOptions = switch (example) {
        .triangle => .{
            .name = "triangle",
            .root = "examples/triangle/triangle.zig",
            .shader_names = &.{ "triangle_vert", "triangle_frag" },
            .shader_dir = "examples/triangle",
        },
        .cube => .{
            .name = "cube",
            .root = "examples/cube/cube.zig",
            .shader_names = &.{ "cube_vert", "cube_frag" },
            .shader_dir = "examples/cube",
        },
        .texture => .{
            .name = "texture",
            .root = "examples/texture/texture.zig",
            .shader_names = &.{ "texture_vert", "texture_frag" },
            .shader_dir = "examples/texture",
        },
    };

    try build_app.build(builder, build_app.BuildOptions.initOptions(builder, app_options));
}
