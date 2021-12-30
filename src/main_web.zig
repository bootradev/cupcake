const app = @import("app");
const cc = @import("cupcake");
const std = @import("std");

const js = struct {
    const WasmId = u32;
};

pub const WasmId = js.WasmId;
pub var wasm_id: WasmId = undefined;

pub export fn init(id: u32) void {
    wasm_id = id;
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
    @panic("");
}
