const cfg = @import("cfg");

pub usingnamespace switch (cfg.gfx_backend) {
    .webgpu => @import("gfx_webgpu.zig"),
};

pub const DeviceReadyCb = fn () void;
pub const DeviceErrorCb = fn (err: anyerror) void;
