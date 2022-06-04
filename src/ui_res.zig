const cc_bake = @import("cc_bake");
const res = @import("res.zig");

pub fn loadVertShaderBytes() ![]const u8 {
    const vert_shader_bake = try res.load(cc_bake.ui_vert_shader, .{});
    return vert_shader_bake.bytes;
}
pub fn loadFragShaderBytes() ![]const u8 {
    const frag_shader_bake = try res.load(cc_bake.ui_frag_shader, .{});
    return frag_shader_bake.bytes;
}
