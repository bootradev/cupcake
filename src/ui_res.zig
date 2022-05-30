const cc_bake = @import("cc_bake");
const res = @import("res.zig");
const ui = @import("ui.zig");

pub const ContextDesc = struct {};

pub const Context = struct {
    pub fn init(_: ContextDesc, comptime _: ui.ContextDesc) !Context {
        return Context{};
    }

    pub fn deinit(_: *Context) void {}

    pub fn loadVertShaderBytes(_: *Context) ![]const u8 {
        const vert_shader_bake = try res.load(cc_bake.src_ui_vert_shader, .{});
        return vert_shader_bake.bytes;
    }
    pub fn loadFragShaderBytes(_: *Context) ![]const u8 {
        const frag_shader_bake = try res.load(cc_bake.src_ui_frag_shader, .{});
        return frag_shader_bake.bytes;
    }
};
