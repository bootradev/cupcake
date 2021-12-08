const bt = @import("bootra");
const cfg = @import("cfg");

pub const app = @import("app");
pub const log = bt.app.log;
pub const log_level = bt.app.log_level;

usingnamespace switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
