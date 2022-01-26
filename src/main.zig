const api = switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
const cfg = @import("cfg");
const std = @import("std");

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (cfg.log_level != .disabled) {
        api.log(message_level, scope, format, args);
    }
}

pub const log_level = switch (cfg.log_level) {
    .debug => .debug,
    .warn => .warn,
    .err, .disabled => .err,
};

usingnamespace api.main;
