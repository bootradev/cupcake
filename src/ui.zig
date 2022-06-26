const std = @import("std");

pub const TextLayout = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    width: f32 = 100.0,
    height: f32 = 25.0,
    font_size: f32 = 12.0,
};

pub fn Context(comptime gfx_impl: anytype) type {
    return struct {
        const Self = @This();

        gfx: gfx_impl.Context,

        pub fn init(gfx_desc: gfx_impl.ContextDesc, res_impl: anytype) !Self {
            const gfx = try gfx_impl.Context.init(gfx_desc, res_impl);
            return Self{ .gfx = gfx };
        }

        pub fn deinit(self: *Self) void {
            self.gfx.deinit();
        }

        pub fn render(self: *Self, render_data: gfx_impl.RenderData) !void {
            try self.gfx.render(render_data);
        }

        pub fn setViewport(self: *Self, width: f32, height: f32) void {
            self.gfx.setViewport(width, height);
        }

        pub fn debugText(
            self: *Self,
            layout: TextLayout,
            comptime fmt: []const u8,
            args: anytype,
        ) !void {
            _ = layout;
            _ = fmt;
            _ = args;

            var instance = try self.gfx.addInstance();
            instance.setPos(300.0, 300.0);
            instance.setSize(600.0, 600.0);
            instance.setUvPos(0.0, 0.0);
            instance.setUvSize(1.0, 1.0);
            instance.setColor(1.0, 1.0, 1.0, 1.0);
            // var buf: [2048]u8 = undefined;
            // const msg = try std.fmt.bufPrint(&buf, fmt, args);

            // const scale = math.scaling(layout.font_size, layout.font_size, 1.0);

            // var start_x = layout.x;
            // var start_y = layout.y;
            // for (msg) |_| {
            //     const m = math.mul(scale, math.translation(start_x, start_y, 0.0));
            //     try ctx.addInstance(.{ .mvp = math.transpose(math.mul(m, ctx.vp)) });

            //     start_x += layout.font_size;
            // }
        }

        pub fn reset(self: *Self) void {
            self.gfx.resetInstances();
        }
    };
}
