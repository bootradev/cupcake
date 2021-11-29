const bt = @import("bootra");
const cfg = @import("cfg");

usingnamespace bt.app;
usingnamespace switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
