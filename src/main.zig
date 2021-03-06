const api = switch (cfg.platform) {
    .web => @import("main_web.zig"),
    .win => @compileError("Not yet implemented!"),
};
const app = @import("app");
const bo = @import("build_options");
const cfg = @import("cfg.zig");
const std = @import("std");

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (log_enabled) {
        api.log(message_level, scope, format, args);
    }
}

const log_enabled = bo.log_enabled;
pub const log_level = @intToEnum(std.log.Level, @enumToInt(bo.log_level));

const AppData = if (@hasDecl(app, "init"))
block: {
    const return_type = @typeInfo(@TypeOf(app.init)).Fn.return_type.?;
    switch (@typeInfo(return_type)) {
        .ErrorUnion => |EU| break :block EU.payload,
        else => @compileError("init return type must be an error union!"),
    }
} else void;

var app_data: AppData = undefined;

pub fn init() !void {
    if (@hasDecl(app, "init")) {
        if (AppData == void) {
            try app.init();
        } else {
            app_data = try app.init();
        }
    }
}

pub fn loop() !void {
    if (@hasDecl(app, "loop")) {
        if (AppData == void) {
            try app.loop();
        } else {
            const app_data_ref = if (@typeInfo(AppData) == .Pointer)
                app_data
            else
                &app_data;
            try app.loop(app_data_ref);
        }
    }
}

pub fn deinit() !void {
    if (@hasDecl(app, "deinit")) {
        if (AppData == void) {
            try app.deinit();
        } else {
            const app_data_ref = if (@typeInfo(AppData) == .Pointer)
                app_data
            else
                &app_data;
            try app.deinit(app_data_ref);
        }
    }
}

usingnamespace api.entry;
