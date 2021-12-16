const app = @import("app");
const std = @import("std");

pub export fn init() void {
    app.init() catch |err| handleError(err);
}

pub export fn update() void {
    app.update() catch |err| handleError(err);
}

pub export fn deinit() void {
    app.deinit() catch |err| handleError(err);
}

fn handleError(err: anyerror) noreturn {
    std.log.err("{}", .{err});
    @panic("error!");
}
