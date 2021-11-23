pub usingnamespace @import("bootra");
const cfg = @import("cfg");

usingnamespace switch (cfg.platform) {
    .web => @import("main_web.zig"),
};
