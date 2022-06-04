const cfg = @import("cfg.zig");
const minify = @import("minify.zig");
const serde = @import("serde.zig");
const stb = @cImport({
    @cInclude("stb/stb_image.h");
});
const std = @import("std");
const qoi = @import("qoi.zig");

pub const Shader = struct {
    bytes: []const u8,

    pub fn bake(
        allocator: std.mem.Allocator,
        bytes: []const u8,
        platform: cfg.Platform,
        opt_level: cfg.OptLevel,
    ) ![]u8 {
        const shader_bytes = try minify.shader(
            bytes,
            allocator,
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
        bytes: []const u8,
        _: cfg.Platform,
        _: cfg.OptLevel,
    ) ![]u8 {
        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;
        const texture_bytes = stb.stbi_load_from_memory(
            bytes.ptr,
            @intCast(c_int, bytes.len),
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

const bake_list = @import("bake_list");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("bake begin...", .{});
    std.log.info("platform: {s}", .{@tagName(bake_list.platform)});
    std.log.info("optimization level: {s}", .{@tagName(bake_list.opt_level)});

    var in_dir = try std.fs.cwd().openDir(bake_list.in_dir, .{});
    defer in_dir.close();
    var out_dir = try std.fs.cwd().openDir(bake_list.out_dir, .{});
    defer out_dir.close();

    std.log.info("input dir: {s}", .{bake_list.in_dir});
    std.log.info("output dir: {s}", .{bake_list.out_dir});

    inline for (@typeInfo(bake_list).Struct.decls) |decl| {
        const Type = @field(bake_list, decl.name);
        if (@TypeOf(Type) == type and @hasDecl(Type, "bake")) {
            const var_name = comptime getVarName(decl.name, Type);
            std.log.info("{s} {s} -> {s}", .{ Type, decl.name, var_name });

            const file = try in_dir.openFile(decl.name, .{});
            defer file.close();
            const file_stat = try file.stat();
            const file_bytes = try file.readToEndAlloc(allocator, file_stat.size);
            defer allocator.free(file_bytes);

            const bake_bytes = try Type.bake(
                allocator,
                file_bytes,
                bake_list.platform,
                bake_list.opt_level,
            );
            defer allocator.free(bake_bytes);
            try out_dir.writeFile(var_name, bake_bytes);
        }
    }

    std.log.info("bake complete!", .{});
}

pub fn getVarName(comptime path: []const u8, comptime bake_type: type) []const u8 {
    comptime var var_name: []const u8 = &[_]u8{};
    inline for (path) |char| {
        if (char == '.') {
            break;
        }

        if (std.fs.path.isSep(char)) {
            var_name = var_name ++ &[_]u8{'_'};
        } else {
            var_name = var_name ++ &[_]u8{std.ascii.toLower(char)};
        }
    }
    var_name = var_name ++ &[_]u8{'_'};
    inline for (@typeName(bake_type)) |char| {
        var_name = var_name ++ &[_]u8{std.ascii.toLower(char)};
    }
    return var_name;
}
