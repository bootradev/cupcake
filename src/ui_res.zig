const cc_bake = @import("cc_bake");
const gfx = @import("gfx.zig");
const res = @import("res.zig");
const serde = @import("serde.zig");
const std = @import("std");

pub fn loadVertShaderDesc(_: std.mem.Allocator) !gfx.ShaderDesc {
    return try res.load(cc_bake.ui_vert_shader, .{});
}

pub fn freeVertShaderDesc(_: std.mem.Allocator, _: gfx.ShaderDesc) void {}

pub fn loadFragShaderDesc(_: std.mem.Allocator) !gfx.ShaderDesc {
    return try res.load(cc_bake.ui_frag_shader, .{});
}

pub fn freeFragShaderDesc(_: std.mem.Allocator, _: gfx.ShaderDesc) void {}

pub fn loadFontAtlasDesc(allocator: std.mem.Allocator) !gfx.TextureDesc {
    return try res.load(
        cc_bake.ui_dbg_font_texture,
        .{ .res_allocator = allocator },
    );
}

pub fn freeFontAtlasDesc(allocator: std.mem.Allocator, desc: gfx.TextureDesc) void {
    serde.deserializeFree(allocator, desc);
}
