const cfg = @import("cfg");
const std = @import("std");

pub usingnamespace switch (cfg.platform) {
    .web => @import("app_web.zig"),
};

pub const log_level: std.log.Level = if (cfg.log_enabled) .debug else .alert;
