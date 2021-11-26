const gfx = @import("gfx.zig");
const std = @import("std");

pub const swapchain_format = gfx.TextureFormat.bgra8unorm;

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = u64;
    const GPUIndex32 = u32;
    const GPUSampleMask = u32;
    const GPUColorWriteFlags = u32;
    const GPUStencilValue = u32;
    const GPUDepthBias = i32;
    const GPUFlagsConstant = u32;

    const ObjectId = i32;
    const ShaderId = ObjectId;
    const BindGroupLayoutId = ObjectId;
    const PipelineLayoutId = ObjectId;
    const RenderPipelineId = ObjectId;

    pub const ColorWrite = enum(GPUFlagsConstant) {
        RED = 0x1,
        GREEN = 0x2,
        BLUE = 0x4,
        ALPHA = 0x8,
        ALL = 0xF,
    };

    extern "webgpu" fn requestAdapter() void;
    extern "webgpu" fn requestDevice() void;
    extern "webgpu" fn createShader(code_ptr: [*]const u8, code_len: usize) ShaderId;
    extern "webgpu" fn destroyShader(shader_id: ShaderId) void;
    extern "webgpu" fn checkShaderCompile(shader_id: ShaderId) void;
    extern "webgpu" fn createPipelineLayout(
        bind_group_layout_ids_ptr: [*]const u8,
        bind_group_layout_ids_len: usize,
    ) PipelineLayoutId;
    extern "webgpu" fn createRenderPipeline(
        pipeline_layout_id: PipelineLayoutId,
        vert_shader_id: ShaderId,
        frag_shader_id: ShaderId,
        json_ptr: [*]const u8,
        json_len: usize,
    ) RenderPipelineId;
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

        pub fn initPipelineLayout(
            _: *Self,
            bind_group_layouts: []const BindGroupLayout,
            comptime _: gfx.PipelineLayoutDesc,
        ) !PipelineLayout {
            const bytes = std.mem.sliceAsBytes(bind_group_layouts);
            return PipelineLayout{
                .id = js.createPipelineLayout(bytes.ptr, bytes.len),
            };
        }

        pub fn initRenderPipeline(
            _: *Self,
            pipeline_layout: *const PipelineLayout,
            vert_shader: *const Shader,
            frag_shader: *const Shader,
            comptime desc: gfx.RenderPipelineDesc,
        ) !RenderPipeline {
            const json = comptime stringifyRenderPipelineDescComptime(desc);
            return RenderPipeline{
                .id = js.createRenderPipeline(
                    pipeline_layout.id,
                    vert_shader.id,
                    frag_shader.id,
                    json.ptr,
                    json.len,
                ),
            };
        }
    };
}

pub const Shader = packed struct {
    id: js.ShaderId,
};

pub const BindGroupLayout = packed struct {
    id: js.BindGroupLayoutId,
};

pub const PipelineLayout = packed struct {
    id: js.PipelineLayoutId,
};

pub const RenderPipeline = packed struct {
    id: js.RenderPipelineId,
};

fn stringifyRenderPipelineDescComptime(comptime desc: gfx.RenderPipelineDesc) []const u8 {
    const JsonVertAttr = struct {
        format: []const u8,
        offset: js.GPUSize64,
        shaderLocation: js.GPUIndex32,
    };
    const JsonVertLayout = struct {
        arrayStride: js.GPUSize64,
        stepMode: []const u8,
        attributes: []const JsonVertAttr,
    };
    const JsonVertState = struct {
        entryPoint: []const u8,
        buffers: []const JsonVertLayout,
    };
    const JsonPrimState = struct {
        topology: []const u8,
        stripIndexFormat: ?[]const u8,
        frontFace: []const u8,
        cullMode: []const u8,
        unclippedDepth: bool,
    };
    const JsonStencilFaceState = struct {
        compare: []const u8,
        failOp: []const u8,
        depthFailOp: []const u8,
        passOp: []const u8,
    };
    const JsonDepthStencilState = struct {
        format: []const u8,
        depthWriteEnabled: bool,
        depthCompare: []const u8,
        stencilFront: JsonStencilFaceState,
        stencilBack: JsonStencilFaceState,
        stencilReadMask: js.GPUStencilValue,
        stencilWriteMask: js.GPUStencilValue,
        depthBias: js.GPUDepthBias,
        depthBiasSlopeScale: f32,
        depthBiasClamp: f32,
    };
    const JsonMultiState = struct {
        count: js.GPUSize32,
        mask: js.GPUSampleMask,
        alphaToCoverageEnabled: bool,
    };
    const JsonBlendComp = struct {
        operation: []const u8,
        srcFactor: []const u8,
        dstFactor: []const u8,
    };
    const JsonBlend = struct {
        color: JsonBlendComp,
        alpha: JsonBlendComp,
    };
    const JsonTarget = struct {
        format: []const u8,
        blend: JsonBlend,
        writeMask: js.GPUColorWriteFlags,
    };
    const JsonFragState = struct {
        entryPoint: []const u8,
        targets: []const JsonTarget,
    };
    const JsonDesc = struct {
        vertex: JsonVertState,
        primitive: JsonPrimState,
        depthStencil: ?JsonDepthStencilState,
        multisample: JsonMultiState,
        fragment: ?JsonFragState,
    };

    comptime var json: JsonDesc = undefined;
    json.vertex.entryPoint = desc.vertex.entry_point;
    json.vertex.buffers = &[_]JsonVertLayout{};
    inline for (desc.vertex.buffers) |buffer| {
        comptime var json_buffer: JsonVertLayout = undefined;
        json_buffer.arrayStride = buffer.array_stride;
        json_buffer.stepMode = comptime getStepModeString(buffer.step_mode);
        json_buffer.attributes = &[_]JsonVertAttr{};
        inline for (buffer.attributes) |attr| {
            comptime var json_attr: JsonVertAttr = undefined;
            json_attr.format = comptime getVertexFormatString(attr.format);
            json_attr.offset = attr.offset;
            json_attr.shaderLocation = attr.shader_location;

            json_buffer.attributes = json_buffer.attributes ++ [_]JsonVertAttr{json_attr};
        }

        json.vertex.buffers = json.vertex.buffers ++ [_]JsonVertLayout{json_buffer};
    }

    json.primitive.topology = comptime getPrimitiveTopologyString(desc.primitive.topology);
    if (desc.primitive.strip_index_format == .@"undefined") {
        json.primitive.stripIndexFormat = null;
    } else {
        json.primitive.stripIndexFormat = comptime getIndexFormatString(
            desc.primitive.strip_index_format,
        );
    }
    json.primitive.frontFace = comptime getFrontFaceString(desc.primitive.front_face);
    json.primitive.cullMode = comptime getCullModeString(desc.primitive.cull_mode);
    json.primitive.unclippedDepth = false;

    if (desc.depth_stencil == null) {
        json.depthStencil = null;
    } else {
        json.depthStencil.format = comptime getTextureFormatString(
            desc.depth_stencil.format,
        );
        json.depthStencil.depthWriteEnabled = desc.depth_stencil.depth_write_enabled;
        json.depthStencil.depthCompare = comptime getCompareFunctionString(
            desc.depth_stencil.depthCompare,
        );
        json.depthStencil.stencilFront.compare = comptime getCompareFunctionString(
            desc.depth_stencil.stencil_front.compare,
        );
        json.depthStencil.stencilFront.failOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_front.fail_op,
        );
        json.depthStencil.stencilFront.depthFailOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_front.depth_fail_op,
        );
        json.depthStencil.stencilFront.passOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_front.pass_op,
        );
        json.depthStencil.stencilBack.compare = comptime getCompareFunctionString(
            desc.depth_stencil.stencil_back.compare,
        );
        json.depthStencil.stencilBack.failOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_back.fail_op,
        );
        json.depthStencil.stencilBack.depthFailOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_back.depth_fail_op,
        );
        json.depthStencil.stencilBack.passOp = comptime getStencilOperationString(
            desc.depth_stencil.stencil_back.pass_op,
        );
        json.depthStencil.stencilReadMask = desc.depth_stencil.stencil_read_mask;
        json.depthStencil.stencilWriteMask = desc.depth_stencil.stencil_write_mask;
        json.depthStencil.depthBias = desc.depth_stencil.depth_bias;
        json.depthStencil.depthBiasSlopeScale = desc.depth_stencil.depth_bias_slope_scale;
        json.depthStencil.depthBiasClamp = desc.depth_stencil.depth_bias_clamp;
    }

    json.multisample.count = desc.multisample.count;
    json.multisample.mask = desc.multisample.mask;
    json.multisample.alphaToCoverageEnabled = desc.multisample.alpha_to_coverage_enabled;

    if (desc.fragment == null) {
        json.fragment = null;
    } else {
        comptime var json_fragment: JsonFragState = undefined;
        json_fragment.entryPoint = desc.fragment.?.entry_point;
        json_fragment.targets = &[_]JsonTarget{};
        inline for (desc.fragment.?.targets) |target| {
            comptime var json_target: JsonTarget = undefined;
            json_target.format = comptime getTextureFormatString(target.format);
            json_target.blend.color.operation = comptime getBlendOperationString(
                target.blend.color.operation,
            );
            json_target.blend.color.srcFactor = comptime getBlendFactorString(
                target.blend.color.src_factor,
            );
            json_target.blend.color.dstFactor = comptime getBlendFactorString(
                target.blend.color.dst_factor,
            );
            json_target.blend.alpha.operation = comptime getBlendOperationString(
                target.blend.alpha.operation,
            );
            json_target.blend.alpha.srcFactor = comptime getBlendFactorString(
                target.blend.alpha.src_factor,
            );
            json_target.blend.alpha.dstFactor = comptime getBlendFactorString(
                target.blend.alpha.dst_factor,
            );
            json_target.writeMask = comptime getColorWriteFlags(target.write_mask);

            json_fragment.targets = json_fragment.targets ++ [_]JsonTarget{json_target};
        }
        json.fragment = json_fragment;
    }

    return comptime try stringifyComptime(json);
}

fn stringifyComptime(value: anytype) ![]const u8 {
    const FixedBufferStream = struct {
        const Self = @This();
        pub const Writer = std.io.Writer(*Self, Error, write);
        pub const Error = error{OutOfMemory};

        buffer: []u8,
        write_index: usize,

        pub fn init(buffer: []u8) Self {
            return .{ .buffer = buffer, .write_index = 0 };
        }

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        fn write(self: *Self, bytes: []const u8) Error!usize {
            if (self.write_index + bytes.len > self.buffer.len) {
                return Error.OutOfMemory;
            }

            for (bytes) |byte, i| {
                self.buffer[self.write_index + i] = byte;
            }

            self.write_index += bytes.len;
            return bytes.len;
        }
    };

    @setEvalBranchQuota(100000);
    comptime var json: [2048]u8 = undefined;
    comptime var buffer_stream = FixedBufferStream.init(json[0..]);
    comptime try std.json.stringify(
        value,
        .{
            .whitespace = .{
                .indent = .{ .Space = 0 },
                .separator = false,
            },
        },
        buffer_stream.writer(),
    );
    return &[_]u8{} ++ json[0..buffer_stream.write_index];
}

fn getStepModeString(comptime step_mode: gfx.VertexStepMode) []const u8 {
    return @tagName(step_mode);
}

fn getVertexFormatString(comptime format: gfx.VertexFormat) []const u8 {
    return @tagName(format);
}

fn getPrimitiveTopologyString(comptime primitive_topology: gfx.PrimitiveTopology) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(primitive_topology));
}

fn getIndexFormatString(comptime index_format: gfx.IndexFormat) []const u8 {
    if (index_format == .@"undefined") {
        @compileError("Invalid index format!");
    }

    return @tagName(index_format);
}

fn getFrontFaceString(comptime front_face: gfx.FrontFace) []const u8 {
    return @tagName(front_face);
}

fn getCullModeString(comptime cull_mode: gfx.CullMode) []const u8 {
    return @tagName(cull_mode);
}

fn getTextureFormatString(comptime texture_format: gfx.TextureFormat) []const u8 {
    if (texture_format == .@"undefined") {
        @compileError("Invalid texture format!");
    }

    return comptime replaceUnderscoreWithDash(@tagName(texture_format));
}

fn getCompareFunctionString(comptime compare_function: gfx.CompareFunction) []const u8 {
    if (compare_function == .@"undefined") {
        @compileError("Invalid index format!");
    }

    return comptime replaceUnderscoreWithDash(@tagName(compare_function));
}

fn getStencilOperationString(comptime stencil_operation: gfx.StencilOperation) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(stencil_operation));
}

fn getBlendOperationString(comptime blend_operation: gfx.BlendOperation) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(blend_operation));
}

fn getBlendFactorString(comptime blend_factor: gfx.BlendFactor) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(blend_factor));
}

fn getColorWriteFlags(comptime color_write_mask: gfx.ColorWriteMask) js.GPUColorWriteFlags {
    comptime var flags: js.GPUColorWriteFlags = 0;
    if (color_write_mask.red) flags |= @enumToInt(js.ColorWrite.RED);
    if (color_write_mask.blue) flags |= @enumToInt(js.ColorWrite.BLUE);
    if (color_write_mask.green) flags |= @enumToInt(js.ColorWrite.GREEN);
    if (color_write_mask.alpha) flags |= @enumToInt(js.ColorWrite.ALPHA);
    return flags;
}

fn replaceUnderscoreWithDash(comptime string: []const u8) []const u8 {
    comptime var buf: [string.len]u8 = undefined;
    _ = std.mem.replace(u8, string, "_", "-", buf[0..]);
    return buf[0..];
}
