const api = switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
const app = @import("app");
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
            try app.loop(if (@typeInfo(AppData) == .Pointer) app_data else &app_data);
        }
    }
}

pub fn deinit() !void {
    if (@hasDecl(app, "deinit")) {
        if (AppData == void) {
            try app.deinit();
        } else {
            try app.deinit(if (@typeInfo(AppData) == .Pointer) app_data else &app_data);
        }
    }
}

usingnamespace api.entry;
