const cc_bake = @import("cc_bake");
const res = @import("res.zig");
const std = @import("std");

pub fn loadVertShaderDesc() !cc_bake.ui_vert_shader.Type {
    return try res.load(cc_bake.ui_vert_shader, .{});
}

pub fn loadFragShaderDesc() !cc_bake.ui_frag_shader.Type {
    return try res.load(cc_bake.ui_frag_shader, .{});
}

pub fn loadFontAtlasTextureDesc(
    allocator: std.mem.Allocator,
) !cc_bake.ui_dbg_font_texture.Type {
    return try res.load(
        cc_bake.ui_dbg_font_texture,
        .{ .res_allocator = allocator },
    );
}
