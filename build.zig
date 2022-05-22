const make = @import("src/make.zig");
const std = @import("std");

const Example = enum {
    triangle,
    cube,
    ui,
};

pub fn build(builder: *std.build.Builder) !void {
    const example = builder.option(Example, "example", "example project") orelse .triangle;

    var recipe_desc: make.RecipeDesc = switch (example) {
        .triangle => .{
            .name = "triangle",
            .root = "examples/triangle/triangle.zig",
            .bake_dir = "examples/triangle",
            .bake_items = &.{
                .{ .path = "triangle_vert.wgsl", .embed = true },
                .{ .path = "triangle_frag.wgsl", .embed = true },
            },
        },
        .cube => .{
            .name = "cube",
            .root = "examples/cube/cube.zig",
            .bake_dir = "examples/cube",
            .bake_items = &.{
                .{ .path = "cube_vert.wgsl", .embed = true },
                .{ .path = "cube_frag.wgsl", .embed = true },
            },
        },
        .ui => .{
            .name = "ui",
            .root = "examples/ui/ui.zig",
        },
    };

    try make.build(builder, recipe_desc);
}
