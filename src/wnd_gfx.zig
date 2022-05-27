const cfg = @import("cfg.zig");
const gfx = @import("gfx.zig");
const wnd = @import("wnd.zig");

pub fn getWindowSurfaceDesc(window: wnd.Window) gfx.SurfaceDesc {
    const window_info = switch (cfg.platform) {
        .web => .{ .canvas_id = window.impl.getCanvasId() },
        else => @compileError("Unsupported platform!"),
    };
    return gfx.SurfaceDesc{ .window_info = window_info };
}

pub fn getWindowExtent(window: wnd.Window) gfx.Extent3d {
    return gfx.Extent3d{ .width = window.getWidth(), .height = window.getHeight() };
}

pub fn getContextDesc(window: wnd.Window) gfx.ContextDesc {
    return gfx.ContextDesc{
        .surface_desc = getWindowSurfaceDesc(window),
        .swapchain_size = getWindowExtent(window),
    };
}
