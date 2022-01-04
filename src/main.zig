const api = switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
const cc = @import("cupcake");
const cfg = @import("cfg");
const std = @import("std");

// not to be confused with cc.app, this re-exports the user app package to
// the root so that cc does not need to depend on the user app package
pub const app = @import("app");

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (cfg.log_enabled) {
        api.log(message_level, scope, format, args);
    }
}

pub const log_level = @intToEnum(std.log.Level, @enumToInt(cfg.log_level));

usingnamespace api.main;
