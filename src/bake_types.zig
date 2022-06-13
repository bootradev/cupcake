const cfg = @import("cfg.zig");
const minify = @import("minify.zig");
const serde = @import("serde.zig");
const stb = @cImport({
    @cInclude("stb/stb_image.h");
});
const std = @import("std");
const qoi = @import("qoi.zig");

pub fn BakeType(comptime type_name: []const u8) type {
    if (comptime std.mem.eql(u8, type_name, "shader")) {
        return Shader;
    } else {
        @compileError("Unsupported bake type!");
    }
}

pub const Shader = struct {
    bytes: []const u8,

    pub fn bake(
        allocator: std.mem.Allocator,
        deps: []const []const u8,
        platform: cfg.Platform,
        opt_level: cfg.OptLevel,
    ) ![]u8 {
        const shader_bytes = try minify.shader(
            allocator,
            deps[0],
            platform,
            opt_level,
        );
        defer allocator.free(shader_bytes);

        return try serde.serialize(allocator, Shader{ .bytes = shader_bytes });
    }
};

pub const Texture = struct {
    width: u32,
    height: u32,
    data: []const u8,

    pub fn serialize(allocator: std.mem.Allocator, value: Texture) ![]const u8 {
        const qoi_image = qoi.Image{
            .width = value.width,
            .height = value.height,
            .data = value.data,
        };

        const result = try qoi.encode(qoi_image, allocator);
        return allocator.resize(result.bytes, result.len) orelse error.ResizeFailed;
    }

    pub fn deserialize(desc: serde.DeserializeDesc, bytes: []const u8) !Texture {
        const allocator = desc.allocator orelse return error.AllocatorRequired;
        const image = try qoi.decode(bytes, allocator);
        return Texture{ .width = image.width, .height = image.height, .data = image.data };
    }

    pub fn bake(
        allocator: std.mem.Allocator,
        deps: []const []const u8,
        _: cfg.Platform,
        _: cfg.OptLevel,
    ) ![]u8 {
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

        return try serde.serialize(allocator, Texture{
            .width = @intCast(u32, width),
            .height = @intCast(u32, height),
            .data = texture_bytes[0..@intCast(usize, width * height * channels)],
        });
    }
};
