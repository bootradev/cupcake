const cfg = @import("cfg.zig");
const gfx = @import("gfx.zig");
const minify = @import("minify.zig");
const stb = @cImport({
    @cInclude("stb/stb_image.h");
});
const std = @import("std");

pub const ShaderDesc = gfx.ShaderDesc;

pub fn shaderBake(
    allocator: std.mem.Allocator,
    deps: []const []const u8,
    platform: cfg.Platform,
    opt_level: cfg.OptLevel,
) !ShaderDesc {
    const shader_bytes = try minify.shader(
        allocator,
        deps[0],
        platform,
        opt_level,
    );
    return ShaderDesc{ .bytes = shader_bytes };
}

pub fn shaderBakeFree(allocator: std.mem.Allocator, shader: ShaderDesc) void {
    allocator.free(shader.bytes);
}

pub const TextureDesc = gfx.TextureDesc;

pub fn textureBake(
    allocator: std.mem.Allocator,
    deps: []const []const u8,
    _: cfg.Platform,
    _: cfg.OptLevel,
) !TextureDesc {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;
    const texture_bytes = stb.stbi_load_from_memory(
        deps[0].ptr,
        @intCast(c_int, deps[0].len),
        &width,
        &height,
        &channels,
        0,
    );
    defer stb.stbi_image_free(texture_bytes);
    const texture_bytes_slice = texture_bytes[0..@intCast(usize, width * height * channels)];

    return TextureDesc{
        .size = .{ .width = @intCast(u32, width), .height = @intCast(u32, height) },
        .format = .rgba8unorm,
        .bytes = try allocator.dupe(u8, texture_bytes_slice),
    };
}

pub fn textureBakeFree(allocator: std.mem.Allocator, texture: TextureDesc) void {
    allocator.free(texture.bytes.?);
}
