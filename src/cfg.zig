const builtin = @import("builtin");
const std = @import("std");

pub const Platform = enum(u8) {
    web,
    win,
};

pub const platform: Platform = block: {
    if (builtin.target.cpu.arch.isWasm()) {
        break :block .web;
    } else {
        switch (builtin.target.os.tag) {
            .windows => break :block .win,
            else => @compileError("Invalid platform!"),
        }
    }
};

// todo: add support for profile mode enabled by root
pub const OptLevel = enum(u8) {
    dbg,
    rel,
};

pub const opt_level: OptLevel = switch (builtin.mode) {
    .Debug => .dbg,
    else => .rel,
};
