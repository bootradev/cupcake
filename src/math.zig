pub const V2u32 = struct {
    x: u32,
    y: u32,

    pub fn init(x: u32, y: u32) V2u32 {
        return V2u32{ .x = x, .y = y };
    }
};
