const cc = @import("cupcake");
const cfg = @import("cfg");

// not to be confused with cc.app, this re-exports the user app package to
// the root so that cc does not need to depend on the user app package
pub const app = @import("app");

pub const log = cc.app.log;
pub const log_level = cc.app.log_level;

// usingnamespace here since the main loop can differ in structure between platforms
usingnamespace switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
