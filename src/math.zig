pub const V2u32 = struct {
    x: u32,
    y: u32,

    pub fn init(x: u32, y: u32) V2u32 {
        return V2u32{ .x = x, .y = y };
    }
};

pub const V4f64 = struct {
    x: f64,
    y: f64,
    z: f64,
    w: f64,

    pub fn init(x: f64, y: f64, z: f64, w: f64) V4f64 {
        return V4f64{ .x = x, .y = y, .z = z, .w = w };
    }
};
