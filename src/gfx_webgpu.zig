const gfx = @import("gfx.zig");

const js = struct {
    const ObjectId = i32;
    const ShaderId = ObjectId;

    extern "webgpu" fn requestAdapter() void;
    extern "webgpu" fn requestDevice() void;
    extern "webgpu" fn createShader(code_ptr: [*]const u8, code_len: usize) ShaderId;
    extern "webgpu" fn destroyShader(shader_id: ShaderId) void;
    extern "webgpu" fn checkShaderCompile(shader_id: ShaderId) void;
};

pub fn GfxDevice(
    comptime device_ready_cb: gfx.DeviceReadyCb,
    comptime device_error_cb: gfx.DeviceErrorCb,
) type {
    return struct {
        const Self = @This();

        const device_ready_cb = device_ready_cb;
        const device_error_cb = device_error_cb;

        pub fn init(_: *Self) !void {
            js.requestAdapter();
        }

        export fn requestAdapterComplete() void {
            js.requestDevice();
        }

        export fn requestDeviceComplete() void {
            device_ready_cb();
        }

        export fn runtimeError(error_code: u32) void {
            const err = switch (error_code) {
                0 => error.RequestAdapterFailed,
                1 => error.RequestDeviceFailed,
                2 => error.CreateShaderFailed,
                else => error.UnknownError,
            };
            device_error_cb(err);
        }

        pub fn initShader(_: *Self, code: []const u8) !Shader {
            return Shader{ .id = js.createShader(code.ptr, code.len) };
        }

        pub fn deinitShader(_: *Self, shader: *Shader) void {
            js.destroyShader(shader.id);
        }

        pub fn checkShaderCompile(_: *Self, shader: *Shader) void {
            js.checkShaderCompile(shader.id);
        }
    };
}

pub const Shader = struct {
    id: js.ShaderId,
};
