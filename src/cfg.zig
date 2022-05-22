const std = @import("std");

pub const Platform = enum(u8) {
    web,
};

pub const LogLevel = enum(u8) {
    debug,
    warn,
    err,
    disabled,
};

pub const OptLevel = enum(u8) {
    debug,
    profile,
    release,

    pub fn getLogLevel(opt_level: OptLevel) LogLevel {
        return switch (opt_level) {
            .debug => .debug,
            .profile => .err,
            .release => .disabled,
        };
    }

    pub fn getBuildMode(opt_level: OptLevel) std.builtin.Mode {
        return switch (opt_level) {
            .debug => .Debug,
            .profile => .ReleaseSafe,
            .release => .ReleaseFast,
        };
    }
};
