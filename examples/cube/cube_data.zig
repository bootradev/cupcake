pub const array_stride = 4 * 4 * 2;
pub const position_offset = 0;
pub const color_offset = 4 * 4;
pub const vertex_count = 36;

// position (vec4), color (vec4),
pub const vertices: []const f32 = &.{
    1,  -1, 1,  1, 1, 0, 1, 1,
    -1, -1, 1,  1, 0, 0, 1, 1,
    -1, -1, -1, 1, 0, 0, 0, 1,
    1,  -1, -1, 1, 1, 0, 0, 1,
    1,  -1, 1,  1, 1, 0, 1, 1,
    -1, -1, -1, 1, 0, 0, 0, 1,

    1,  1,  1,  1, 1, 1, 1, 1,
    1,  -1, 1,  1, 1, 0, 1, 1,
    1,  -1, -1, 1, 1, 0, 0, 1,
    1,  1,  -1, 1, 1, 1, 0, 1,
    1,  1,  1,  1, 1, 1, 1, 1,
    1,  -1, -1, 1, 1, 0, 0, 1,

    -1, 1,  1,  1, 0, 1, 1, 1,
    1,  1,  1,  1, 1, 1, 1, 1,
    1,  1,  -1, 1, 1, 1, 0, 1,
    -1, 1,  -1, 1, 0, 1, 0, 1,
    -1, 1,  1,  1, 0, 1, 1, 1,
    1,  1,  -1, 1, 1, 1, 0, 1,

    -1, -1, 1,  1, 0, 0, 1, 1,
    -1, 1,  1,  1, 0, 1, 1, 1,
    -1, 1,  -1, 1, 0, 1, 0, 1,
    -1, -1, -1, 1, 0, 0, 0, 1,
    -1, -1, 1,  1, 0, 0, 1, 1,
    -1, 1,  -1, 1, 0, 1, 0, 1,

    1,  1,  1,  1, 1, 1, 1, 1,
    -1, 1,  1,  1, 0, 1, 1, 1,
    -1, -1, 1,  1, 0, 0, 1, 1,
    -1, -1, 1,  1, 0, 0, 1, 1,
    1,  -1, 1,  1, 1, 0, 1, 1,
    1,  1,  1,  1, 1, 1, 1, 1,

    1,  -1, -1, 1, 1, 0, 0, 1,
    -1, -1, -1, 1, 0, 0, 0, 1,
    -1, 1,  -1, 1, 0, 1, 0, 1,
    1,  1,  -1, 1, 1, 1, 0, 1,
    1,  -1, -1, 1, 1, 0, 0, 1,
    -1, 1,  -1, 1, 0, 1, 0, 1,
};
