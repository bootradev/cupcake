const cfg = @import("cfg");

const shaders_wgsl = struct {
    pub const tri_vert = @embedFile("shaders/tri_vert.wgsl");
    pub const tri_frag = @embedFile("shaders/tri_frag.wgsl");
};

pub usingnamespace switch (cfg.gfx_backend) {
    .webgpu => shaders_wgsl,
};
