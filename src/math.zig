const std = @import("std");

pub const V2u32 = packed struct {
    x: u32,
    y: u32,

    pub fn make(x: u32, y: u32) V2u32 {
        return V2u32{ .x = x, .y = y };
    }
};

pub const V3f32 = packed struct {
    x: f32,
    y: f32,
    z: f32,

    pub const zero = V3f32.make(0, 0, 0);
    pub const forward = V3f32.make(0, 0, 1);
    pub const up = V3f32.make(0, 1, 0);

    pub fn make(x: f32, y: f32, z: f32) V3f32 {
        return V3f32{ .x = x, .y = y, .z = z };
    }

    pub fn dot(a: V3f32, b: V3f32) f32 {
        var result: f32 = 0;
        inline for (@typeInfo(V3f32).Struct.fields) |field| {
            result += @field(a, field.name) * @field(b, field.name);
        }
        return result;
    }

    pub fn cross(a: V3f32, b: V3f32) V3f32 {
        return V3f32{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn length(v: V3f32) f32 {
        return std.math.sqrt(v.lengthSq());
    }

    pub fn lengthSq(v: V3f32) f32 {
        return V3f32.dot(v, v);
    }

    pub fn scale(v: V3f32, s: f32) V3f32 {
        var result: V3f32 = undefined;
        inline for (@typeInfo(V3f32).Struct.fields) |field| {
            @field(result, field.name) = @field(v, field.name) * s;
        }
        return result;
    }

    pub fn normalize(v: V3f32) V3f32 {
        const len = v.length();
        return if (len == 0) V3f32.zero else v.scale(1.0 / len);
    }
};

pub const V4f64 = packed struct {
    x: f64,
    y: f64,
    z: f64,
    w: f64,

    pub fn make(x: f64, y: f64, z: f64, w: f64) V4f64 {
        return V4f64{ .x = x, .y = y, .z = z, .w = w };
    }
};

pub const M44f32 = packed struct {
    values: [4][4]f32,

    pub const zero = M44f32{
        .values = [4][4]f32{
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
            [4]f32{ 0, 0, 0, 0 },
        },
    };

    pub const identity = M44f32{
        .values = [4][4]f32{
            [4]f32{ 1, 0, 0, 0 },
            [4]f32{ 0, 1, 0, 0 },
            [4]f32{ 0, 0, 1, 0 },
            [4]f32{ 0, 0, 0, 1 },
        },
    };

    pub fn asBytes(m: *const M44f32) []const u8 {
        return @ptrCast([*]const u8, m)[0..64];
    }

    pub fn makeView(center: V3f32, forward: V3f32, up: V3f32) M44f32 {
        const f = forward.normalize();
        const s = V3f32.cross(up, f).normalize();
        const u = V3f32.cross(f, s);

        var result = M44f32.identity;
        result.values[0][0] = s.x;
        result.values[1][0] = s.y;
        result.values[2][0] = s.z;
        result.values[0][1] = u.x;
        result.values[1][1] = u.y;
        result.values[2][1] = u.z;
        result.values[0][2] = f.x;
        result.values[1][2] = f.y;
        result.values[2][2] = f.z;
        result.values[3][0] = -V3f32.dot(s, center);
        result.values[3][1] = -V3f32.dot(u, center);
        result.values[3][2] = -V3f32.dot(f, center);
        return result;
    }

    pub fn makePerspective(fov: f32, aspect: f32, near: f32, far: f32) M44f32 {
        const tanHalfFovy = std.math.tan(fov / 2);

        var result = M44f32.zero;
        result.values[0][0] = 1.0 / (aspect * tanHalfFovy);
        result.values[1][1] = 1.0 / (tanHalfFovy);
        result.values[2][2] = far / (far - near);
        result.values[2][3] = 1;
        result.values[3][2] = -(far * near) / (far - near);
        return result;
    }

    pub fn mul(a: M44f32, b: M44f32) M44f32 {
        var result: M44f32 = undefined;
        inline for ([_]comptime_int{ 0, 1, 2, 3 }) |row| {
            inline for ([_]comptime_int{ 0, 1, 2, 3 }) |col| {
                var sum: f32 = 0.0;
                inline for ([_]comptime_int{ 0, 1, 2, 3 }) |i| {
                    sum += a.values[row][i] * b.values[i][col];
                }
                result.values[row][col] = sum;
            }
        }
        return result;
    }
};
