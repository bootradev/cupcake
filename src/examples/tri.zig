const bt = @import("bootra");

const Example = struct {
    window: bt.Window,
};

var ex: Example = undefined;

pub fn init() !void {
    try ex.window.init("tri", 800, 600);
}
