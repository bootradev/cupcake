const app = @import("app");
const std = @import("std");

pub export fn mainInit() void {
    app.init() catch |err| handleError(err);
}

fn handleError(err: anyerror) void {
    std.log.err("{}", .{err});
    unreachable;
}
