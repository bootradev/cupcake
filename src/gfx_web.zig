const app = @import("app.zig");
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const gfx = @import("gfx.zig");
const main = @import("main.zig");
const std = @import("std");

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = usize;
    const GPUIndex32 = u32;
    const GPUSignedOffset32 = i32;
    const GPUIntegerCoordinate = u32;

    const ObjectId = u32;
    const DescId = ObjectId;
    const CanvasId = ObjectId;
    const ContextId = ObjectId;
    const AdapterId = ObjectId;
    const DeviceId = ObjectId;
    const ShaderId = ObjectId;
    const BindGroupLayoutId = ObjectId;
    const BindGroupId = ObjectId;
    const PipelineLayoutId = ObjectId;
    const RenderPipelineId = ObjectId;
    const RenderPassId = ObjectId;
    const CommandEncoderId = ObjectId;
    const CommandBufferId = ObjectId;
    const TextureId = ObjectId;
    const TextureViewId = ObjectId;
    const SamplerId = ObjectId;
    const QuerySetId = ObjectId;
    const BufferId = ObjectId;

    const invalid_id: ObjectId = 0;
    const default_desc_id: DescId = 0;

    const BindType = enum(u32) {
        buffer,
        sampler,
        texture_view,
    };

    extern fn createDesc() DescId;
    extern fn destroyDesc(desc_id: DescId) void;
    extern fn destoryDesc(desc_id: DescId) void;
    extern fn setDescField(
        wasm_id: main.WasmId,
        desc_id: DescId,
        field_ptr: [*]const u8,
        field_len: usize,
    ) void;
    extern fn setDescString(
        wasm_id: main.WasmId,
        desc_id: DescId,
        value_ptr: [*]const u8,
        value_len: usize,
    ) void;
    extern fn setDescBool(desc_id: DescId, value: bool) void;
    extern fn setDescU32(desc_id: DescId, value: u32) void;
    extern fn setDescI32(desc_id: DescId, value: i32) void;
    extern fn setDescF32(desc_id: DescId, value: f32) void;
    extern fn beginDescArray(desc_id: DescId) void;
    extern fn endDescArray(desc_id: DescId) void;
    extern fn beginDescChild(desc_id: DescId) void;
    extern fn endDescChild(desc_id: DescId) void;

    extern fn createContext(canvas_id: ObjectId) ContextId;
    extern fn destroyContext(contex_id: ContextId) void;
    extern fn getContextCurrentTexture(context_id: ContextId) TextureId;
    extern fn configure(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        context_id: ContextId,
        desc_id: DescId,
    ) void;
    extern fn getPreferredFormat(
        wasm_id: main.WasmId,
        context_id: ContextId,
        adapter_id: AdapterId,
    ) usize;

    extern fn requestAdapter(wasm_id: main.WasmId, desc_id: DescId) void;
    extern fn destroyAdapter(adapter_id: AdapterId) void;

    extern fn requestDevice(wasm_id: main.WasmId, adapter_id: AdapterId, desc_id: DescId) void;
    extern fn destroyDevice(device_id: DeviceId) void;

    extern fn createShader(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        code_ptr: [*]const u8,
        code_len: usize,
    ) ShaderId;
    extern fn destroyShader(shader_id: ShaderId) void;
    extern fn checkShaderCompile(wasm_id: main.WasmId, shader_id: ShaderId) void;

    extern fn createBindGroupLayout(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) BindGroupLayoutId;
    extern fn destroyBindGroupLayout(bind_group_layout_id: BindGroupLayoutId) void;
    extern fn createBindGroup(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) BindGroupId;
    extern fn destroyBindGroup(bind_group_id: BindGroupId) void;

    extern fn createPipelineLayout(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) PipelineLayoutId;
    extern fn destroyPipelineLayout(pipeline_layout_id: PipelineLayoutId) void;
    extern fn createRenderPipeline(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) RenderPipelineId;
    extern fn destroyRenderPipeline(render_pipeline_id: RenderPipelineId) void;

    extern fn createCommandEncoder(device_id: DeviceId) CommandEncoderId;
    extern fn finishCommandEncoder(command_encoder_id: CommandEncoderId) CommandBufferId;

    extern fn beginRenderPass(
        wasm_id: main.WasmId,
        command_encoder_id: CommandEncoderId,
        desc_id: DescId,
    ) RenderPassId;
    extern fn setPipeline(
        render_pass_id: RenderPassId,
        render_pipeline_id: RenderPipelineId,
    ) void;
    extern fn setBindGroup(
        wasm_id: main.WasmId,
        render_pass_id: RenderPassId,
        group_index: GPUIndex32,
        bind_group_id: BindGroupId,
        dynamic_offsets_ptr: [*]const u8,
        dynamic_offsets_len: usize,
    ) void;
    extern fn setVertexBuffer(
        render_pass_id: RenderPassId,
        slot: GPUIndex32,
        buffer: BufferId,
        offset: GPUSize64,
        size: GPUSize64,
    ) void;
    extern fn setIndexBuffer(
        wasm_id: main.WasmId,
        render_pass_id: RenderPassId,
        buffer_id: BufferId,
        index_format_ptr: [*]const u8,
        index_format_len: usize,
        offset: usize,
        size: usize,
    ) void;
    extern fn draw(
        render_pass_id: RenderPassId,
        vertex_count: GPUSize32,
        instance_count: GPUSize32,
        first_vertex: GPUSize32,
        first_instance: GPUSize32,
    ) void;
    extern fn drawIndexed(
        render_pass_id: RenderPassId,
        index_count: GPUSize32,
        instance_count: GPUSize32,
        first_index: GPUSize32,
        base_vertex: GPUSignedOffset32,
        first_instance: GPUSize32,
    ) void;
    extern fn endRenderPass(render_pass_id: RenderPassId) void;

    extern fn queueSubmit(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        command_buffer_id: CommandBufferId,
    ) void;
    extern fn queueWriteBuffer(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        buffer_id: BufferId,
        buffer_offset: GPUSize64,
        data_ptr: [*]const u8,
        data_len: usize,
        data_offset: GPUSize64,
    ) void;
    extern fn queueWriteTexture(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        destination_id: DescId,
        data_ptr: [*]const u8,
        data_len: usize,
        data_layout_id: DescId,
        size_width: GPUIntegerCoordinate,
        size_height: GPUIntegerCoordinate,
        size_depth_or_array_layers: GPUIntegerCoordinate,
    ) void;

    extern fn createBuffer(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
        init_data_ptr: [*]const u8,
        init_data_len: usize,
    ) BufferId;
    extern fn destroyBuffer(buffer_id: BufferId) void;

    extern fn createTexture(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) TextureId;
    extern fn destroyTexture(texture_id: TextureId) void;
    extern fn createTextureView(texture_id: TextureId) TextureViewId;
    extern fn destroyTextureView(texture_view_id: TextureViewId) void;

    extern fn createSampler(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_id: DescId,
    ) SamplerId;
    extern fn destroySampler(sampler_id: SamplerId) void;
};

fn getEnumName(value: anytype) []const u8 {
    @setEvalBranchQuota(10000);
    comptime var enum_names: []const []const u8 = &.{};
    inline for (@typeInfo(@TypeOf(value)).Enum.fields) |field| {
        comptime var enum_name: []const u8 = &.{};
        inline for (field.name) |char| {
            enum_name = enum_name ++ &[_]u8{if (char == '_') '-' else char};
        }
        enum_names = enum_names ++ &[_][]const u8{enum_name};
    }
    return enum_names[@enumToInt(value)];
}

fn setDescFieldValue(desc: anytype, field: []const u8, value: anytype) @TypeOf(desc) {
    js.setDescField(main.wasm_id, desc.id, field.ptr, field.len);
    setDescValue(desc, value);
    return desc;
}

fn setDescValue(desc: anytype, value: anytype) void {
    switch (@typeInfo(@TypeOf(value))) {
        .Bool => js.setDescBool(desc.id, value),
        .Int => |I| {
            if (I.bits != 32) {
                @compileError("Desc ints must be 32 bits!");
            }
            switch (I.signedness) {
                .signed => js.setDescI32(desc.id, value),
                .unsigned => js.setDescU32(desc.id, value),
            }
        },
        .Float => |F| {
            if (F.bits != 32) {
                @compileError("Desc floats must be 32 bits!");
            }
            js.setDescF32(desc.id, value);
        },
        .Enum => {
            const enum_name = getEnumName(value);
            js.setDescString(main.wasm_id, desc.id, enum_name.ptr, enum_name.len);
        },
        .Pointer => |P| {
            switch (P.size) {
                .Slice => {
                    if (P.child == u8) {
                        js.setDescString(main.wasm_id, desc.id, value.ptr, value.len);
                    } else {
                        js.beginDescArray(desc.id);
                        for (value) |v| {
                            setDescValue(desc, v);
                        }
                        js.endDescArray(desc.id);
                    }
                },
                else => @compileError("Invalid desc pointer size!"),
            }
        },
        .Struct => |S| {
            if (S.layout == .Packed) {
                const BitType = @Type(.{
                    .Int = .{ .signedness = .unsigned, .bits = @bitSizeOf(@TypeOf(value)) },
                });
                js.setDescU32(desc.id, @intCast(u32, @bitCast(BitType, value)));
            } else if (S.fields.len == 1 and comptime std.mem.eql(u8, S.fields[0].name, "id")) {
                js.setDescU32(desc.id, value.id);
            } else {
                js.beginDescArray(desc.id);
                inline for (S.fields) |field| {
                    setDescValue(desc, @field(value, field.name));
                }
                js.endDescArray(desc.id);
            }
        },
        else => @compileError("Invalid desc type!"),
    }
}

fn setDescFieldChild(desc: anytype, field: []const u8, comptime Child: type) Child {
    js.setDescField(main.wasm_id, desc.id, field.ptr, field.len);
    return setDescChild(desc, Child);
}

fn setDescChild(desc: anytype, comptime Child: type) Child {
    if (Child.is_array) {
        js.beginDescArray(desc.id);
    } else {
        js.beginDescChild(desc.id);
    }
    return Child{ .id = desc.id, .parent = desc };
}

const DescApiFn = fn (type) type;

fn Desc(comptime DescApi: DescApiFn, comptime ParentType: ?type, is_array: bool) type {
    if (ParentType) |Parent| {
        return struct {
            const Self = @This();
            const is_array = is_array;
            pub usingnamespace DescApi(Self);

            parent: Parent,
            id: js.DescId,

            pub fn end(desc: Self) Parent {
                if (is_array) {
                    js.endDescArray(desc.id);
                } else {
                    js.endDescChild(desc.id);
                }
                return desc.parent;
            }
        };
    } else {
        return struct {
            const Self = @This();
            const is_array = is_array;
            pub usingnamespace DescApi(Self);

            id: js.DescId,

            pub fn init() Self {
                return Self{ .id = js.createDesc() };
            }

            pub fn deinit(self: Self) void {
                return js.destroyDesc(self.id);
            }

            pub fn default() Self {
                return Self{ .id = js.default_desc_id };
            }
        };
    }
}

fn AdapterDescApi(comptime Self: type) type {
    return struct {
        pub fn compatibleSurface(self: Self, value: gfx.Surface) Self {
            return setDescFieldValue(self, "compatibleSurface", value);
        }
        pub fn powerPreference(self: Self, value: gfx.PowerPreference) Self {
            return setDescFieldValue(self, "powerPreference", value);
        }
        pub fn forceFallbackAdapter(self: Self, value: bool) Self {
            return setDescFieldValue(self, "forceFallbackAdapter", value);
        }
    };
}
pub const AdapterDesc = Desc(AdapterDescApi, null, false);

fn DeviceDescApi(comptime Self: type) type {
    return struct {
        pub fn requiredFeatures(self: Self, value: []const gfx.FeatureName) Self {
            return setDescFieldValue(self, "requiredFeatures", value);
        }
        pub fn requiredLimits(self: Self) LimitsDesc {
            return setDescFieldChild(self, "requiredLimits", LimitsDesc);
        }
    };
}
pub const DeviceDesc = Desc(DeviceDescApi, null, false);

fn LimitsDescApi(comptime Self: type) type {
    return struct {
        pub fn maxTextureDimension1D(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxTextureDimension1D", value);
        }
        pub fn maxTextureDimension2D(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxTextureDimension2D", value);
        }
        pub fn maxTextureDimension3D(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxTextureDimension3D", value);
        }
        pub fn maxTextureArrayLayers(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxTextureArrayLayers", value);
        }
        pub fn maxBindGroups(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxBindGroups", value);
        }
        pub fn maxDynamicUniformBuffersPerPipelineLayout(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxDynamicUniformBuffersPerPipelineLayout", value);
        }
        pub fn maxDynamicStorageBuffersPerPipelineLayout(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxDynamicStorageBuffersPerPipelineLayout", value);
        }
        pub fn maxSampledTexturesPerShaderStage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxSampledTexturesPerShaderStage", value);
        }
        pub fn maxSamplersPerShaderStage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxSamplersPerShaderStage", value);
        }
        pub fn maxStorageBuffersPerShaderStage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxStorageBuffersPerShaderStage", value);
        }
        pub fn maxStorageTexturesPerShaderStage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxStorageTexturesPerShaderStage", value);
        }
        pub fn maxUniformBuffersPerShaderStage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxUniformBuffersPerShaderStage", value);
        }
        pub fn maxUniformBufferBindingSize(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxUniformBufferBindingSize", value);
        }
        pub fn maxStorageBufferBindingSize(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxStorageBufferBindingSize", value);
        }
        pub fn minUniformBufferOffsetAlignment(self: Self, value: u32) Self {
            return setDescFieldValue(self, "minUniformBufferOffsetAlignment", value);
        }
        pub fn minStorageBufferOffsetAlignment(self: Self, value: u32) Self {
            return setDescFieldValue(self, "minStorageBufferOffsetAlignment", value);
        }
        pub fn maxVertexBuffers(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxVertexBuffers", value);
        }
        pub fn maxVertexAttributes(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxVertexAttributes", value);
        }
        pub fn maxVertexBufferArrayStride(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxVertexBufferArrayStride", value);
        }
        pub fn maxInterStageShaderComponents(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxInterStageShaderComponents", value);
        }
        pub fn maxComputeWorkgroupStorageSize(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeWorkgroupStorageSize", value);
        }
        pub fn maxComputeInvocationsPerWorkgroup(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeInvocationsPerWorkgroup", value);
        }
        pub fn maxComputeWorkgroupSizeX(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeWorkgroupSizeX", value);
        }
        pub fn maxComputeWorkgroupSizeY(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeWorkgroupSizeY", value);
        }
        pub fn maxComputeWorkgroupSizeZ(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeWorkgroupSizeZ", value);
        }
        pub fn maxComputeWorkgroupsPerDimension(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxComputeWorkgroupsPerDimension", value);
        }
    };
}
pub const LimitsDesc = Desc(LimitsDescApi, DeviceDesc, false);

fn SwapchainDescApi(comptime Self: type) type {
    return struct {
        pub fn size(self: Self, value: gfx.Extent3d) Self {
            return setDescFieldValue(self, "size", value);
        }
        pub fn format(self: Self, value: gfx.TextureFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn usage(self: Self, value: gfx.TextureUsage) Self {
            return setDescFieldValue(self, "usage", value);
        }
        pub fn presentMode(self: Self, value: gfx.PresentMode) Self {
            return setDescFieldValue(self, "presentMode", value);
        }
    };
}
pub const SwapchainDesc = Desc(SwapchainDescApi, null, false);

fn BindGroupLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn entries(self: Self) BindGroupLayoutEntryDescArray {
            return setDescFieldChild(self, "entries", BindGroupLayoutEntryDescArray);
        }
    };
}
pub const BindGroupLayoutDesc = Desc(BindGroupLayoutDescApi, null, false);

fn BindGroupLayoutEntryDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn entry(self: Self) BindGroupLayoutEntryDesc {
            return setDescChild(self, BindGroupLayoutEntryDesc);
        }
    };
}
pub const BindGroupLayoutEntryDescArray = Desc(
    BindGroupLayoutEntryDescArrayApi,
    BindGroupLayoutDesc,
    true,
);

fn BindGroupLayoutEntryDescApi(comptime Self: type) type {
    return struct {
        pub fn binding(self: Self, value: u32) Self {
            return setDescFieldValue(self, "binding", value);
        }
        pub fn visibility(self: Self, value: gfx.ShaderStage) Self {
            return setDescFieldValue(self, "visibility", value);
        }
        pub fn buffer(self: Self) BufferBindingLayoutDesc {
            return setDescFieldChild(self, "buffer", BufferBindingLayoutDesc);
        }
        pub fn sampler(self: Self) SamplerBindingLayoutDesc {
            return setDescFieldChild(self, "sampler", SamplerBindingLayoutDesc);
        }
        pub fn texture(self: Self) TextureBindingLayoutDesc {
            return setDescFieldChild(self, "texture", TextureBindingLayoutDesc);
        }
        pub fn storageTexture(self: Self) StorageTextureBindingLayoutDesc {
            return setDescFieldChild(self, "storageTexture", StorageTextureBindingLayoutDesc);
        }
    };
}
pub const BindGroupLayoutEntryDesc = Desc(
    BindGroupLayoutEntryDescApi,
    BindGroupLayoutEntryDescArray,
    false,
);

fn BufferBindingLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn @"type"(self: Self, value: gfx.BufferBindingType) Self {
            return setDescFieldValue(self, "type", value);
        }
        pub fn hasDynamicOffset(self: Self, value: bool) Self {
            return setDescFieldValue(self, "hasDynamicOffset", value);
        }
        pub fn minBindingSize(self: Self, value: u32) Self {
            return setDescFieldValue(self, "minBindingSize", value);
        }
    };
}
pub const BufferBindingLayoutDesc = Desc(
    BufferBindingLayoutDescApi,
    BindGroupLayoutEntryDesc,
    false,
);

fn SamplerBindingLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn @"type"(self: Self, value: gfx.SamplerBindingType) Self {
            return setDescFieldValue(self, "type", value);
        }
    };
}
pub const SamplerBindingLayoutDesc = Desc(
    SamplerBindingLayoutDescApi,
    BindGroupLayoutEntryDesc,
    false,
);

fn TextureBindingLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn sampleType(self: Self, value: gfx.TextureSampleType) Self {
            return setDescFieldValue(self, "sampleType", value);
        }
        pub fn viewDimension(self: Self, value: gfx.TextureViewDimension) Self {
            return setDescFieldValue(self, "viewDimension", value);
        }
        pub fn multisampled(self: Self, value: bool) Self {
            return setDescFieldValue(self, "multisampled", value);
        }
    };
}
pub const TextureBindingLayoutDesc = Desc(
    TextureBindingLayoutDescApi,
    BindGroupLayoutEntryDesc,
    false,
);

fn StorageTextureBindingLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn access(self: Self, value: gfx.StorageTextureAccess) Self {
            return setDescFieldValue(self, "access", value);
        }
        pub fn format(self: Self, value: gfx.TextureFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn viewDimension(self: Self, value: gfx.TextureViewDimension) Self {
            return setDescFieldValue(self, "viewDimension", value);
        }
    };
}
pub const StorageTextureBindingLayoutDesc = Desc(
    StorageTextureBindingLayoutDescApi,
    BindGroupLayoutEntryDesc,
    false,
);

fn BindGroupDescApi(comptime Self: type) type {
    return struct {
        pub fn layout(self: Self, value: BindGroupLayout) Self {
            return setDescFieldValue(self, "layout", value);
        }
        pub fn entries(self: Self) BindGroupEntryDescArray {
            return setDescFieldChild(self, "entries", BindGroupEntryDescArray);
        }
    };
}
pub const BindGroupDesc = Desc(BindGroupDescApi, null, false);

fn BindGroupEntryDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn entry(self: Self) BindGroupEntryDesc {
            return setDescChild(self, BindGroupEntryDesc);
        }
    };
}
pub const BindGroupEntryDescArray = Desc(BindGroupEntryDescArrayApi, BindGroupDesc, true);

fn BindGroupEntryDescApi(comptime Self: type) type {
    return struct {
        pub fn binding(self: Self, value: u32) Self {
            return setDescFieldValue(self, "binding", value);
        }
        pub fn buffer(self: Self, value: Buffer) BufferBindingResourceDesc {
            _ = setDescFieldValue(self, "resourceType", @enumToInt(js.BindType.buffer));
            const buf = setDescFieldChild(self, "resource", BufferBindingResourceDesc);
            return setDescFieldValue(buf, "buffer", value);
        }
        pub fn sampler(self: Self, value: Sampler) Self {
            _ = setDescFieldValue(self, "resourceType", @enumToInt(js.BindType.sampler));
            return setDescFieldValue(self, "resource", value);
        }
        pub fn textureView(self: Self, value: TextureView) Self {
            _ = setDescFieldValue(self, "resourceType", @enumToInt(js.BindType.texture_view));
            return setDescFieldValue(self, "resource", value);
        }
    };
}
pub const BindGroupEntryDesc = Desc(BindGroupEntryDescApi, BindGroupEntryDescArray, false);

fn BufferBindingResourceDescApi(comptime Self: type) type {
    return struct {
        pub fn offset(self: Self, value: u32) Self {
            return setDescFieldValue(self, "offset", value);
        }
        pub fn size(self: Self, value: u32) Self {
            return setDescFieldValue(self, "size", value);
        }
    };
}
pub const BufferBindingResourceDesc = Desc(
    BufferBindingResourceDescApi,
    BindGroupEntryDesc,
    false,
);

fn PipelineLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn bindGroupLayouts(self: Self, value: []const BindGroupLayout) Self {
            return setDescFieldValue(self, "bindGroupLayouts", value);
        }
    };
}
pub const PipelineLayoutDesc = Desc(PipelineLayoutDescApi, null, false);

fn RenderPipelineDescApi(comptime Self: type) type {
    return struct {
        pub fn layout(self: Self, value: PipelineLayout) Self {
            return setDescFieldValue(self, "layout", value);
        }
        pub fn vertex(self: Self) VertexStateDesc {
            return setDescFieldChild(self, "vertex", VertexStateDesc);
        }
        pub fn primitive(self: Self) PrimitiveStateDesc {
            return setDescFieldChild(self, "primitive", PrimitiveStateDesc);
        }
        pub fn depthStencil(self: Self) DepthStencilStateDesc {
            return setDescFieldChild(self, "depthStencil", DepthStencilStateDesc);
        }
        pub fn multisample(self: Self) MultisampleStateDesc {
            return setDescFieldChild(self, "multisample", MultisampleStateDesc);
        }
        pub fn fragment(self: Self) FragmentStateDesc {
            return setDescFieldChild(self, "fragment", FragmentStateDesc);
        }
    };
}
pub const RenderPipelineDesc = Desc(RenderPipelineDescApi, null, false);

fn VertexStateDescApi(comptime Self: type) type {
    return struct {
        pub fn module(self: Self, value: Shader) Self {
            return setDescFieldValue(self, "module", value);
        }
        pub fn entryPoint(self: Self, value: []const u8) Self {
            return setDescFieldValue(self, "entryPoint", value);
        }
        pub fn buffers(self: Self) VertexBufferLayoutDescArray {
            return setDescFieldChild(self, "buffers", VertexBufferLayoutDescArray);
        }
    };
}
pub const VertexStateDesc = Desc(VertexStateDescApi, RenderPipelineDesc, false);

fn VertexBufferLayoutDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn buffer(self: Self) VertexBufferLayoutDesc {
            return setDescChild(self, VertexBufferLayoutDesc);
        }
    };
}
pub const VertexBufferLayoutDescArray = Desc(
    VertexBufferLayoutDescArrayApi,
    VertexStateDesc,
    true,
);

fn VertexBufferLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn arrayStride(self: Self, value: u32) Self {
            return setDescFieldValue(self, "arrayStride", value);
        }
        pub fn stepMode(self: Self, value: gfx.VertexStepMode) Self {
            return setDescFieldValue(self, "stepMode", value);
        }
        pub fn attributes(self: Self) VertexAttributeDescArray {
            return setDescFieldChild(self, "attributes", VertexAttributeDescArray);
        }
    };
}
pub const VertexBufferLayoutDesc = Desc(
    VertexBufferLayoutDescApi,
    VertexBufferLayoutDescArray,
    false,
);

fn VertexAttributeDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn attribute(self: Self) VertexAttributeDesc {
            return setDescChild(self, VertexAttributeDesc);
        }
    };
}
pub const VertexAttributeDescArray = Desc(
    VertexAttributeDescArrayApi,
    VertexBufferLayoutDesc,
    true,
);

fn VertexAttributeDescApi(comptime Self: type) type {
    return struct {
        pub fn format(self: Self, value: gfx.VertexFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn offset(self: Self, value: u32) Self {
            return setDescFieldValue(self, "offset", value);
        }
        pub fn shaderLocation(self: Self, value: u32) Self {
            return setDescFieldValue(self, "shaderLocation", value);
        }
    };
}
pub const VertexAttributeDesc = Desc(VertexAttributeDescApi, VertexAttributeDescArray, false);

fn PrimitiveStateDescApi(comptime Self: type) type {
    return struct {
        pub fn topology(self: Self, value: gfx.PrimitiveTopology) Self {
            return setDescFieldValue(self, "topology", value);
        }
        pub fn stripIndexFormat(self: Self, value: gfx.IndexFormat) Self {
            return setDescFieldValue(self, "stripIndexFormat", value);
        }
        pub fn frontFace(self: Self, value: gfx.FrontFace) Self {
            return setDescFieldValue(self, "frontFace", value);
        }
        pub fn cullMode(self: Self, value: gfx.CullMode) Self {
            return setDescFieldValue(self, "cullMode", value);
        }
    };
}
pub const PrimitiveStateDesc = Desc(PrimitiveStateDescApi, RenderPipelineDesc, false);

fn DepthStencilStateDescApi(comptime Self: type) type {
    return struct {
        pub fn format(self: Self, value: gfx.TextureFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn depthWriteEnabled(self: Self, value: bool) Self {
            return setDescFieldValue(self, "depthWriteEnabled", value);
        }
        pub fn depthCompare(self: Self, value: gfx.CompareFunction) Self {
            return setDescFieldValue(self, "depthCompare", value);
        }
        pub fn stencilFront(self: Self) StencilFaceStateDesc {
            return setDescFieldChild(self, "stencilFront", StencilFaceStateDesc);
        }
        pub fn stencilBack(self: Self) StencilFaceStateDesc {
            return setDescFieldChild(self, "stencilBack", StencilFaceStateDesc);
        }
        pub fn stencilReadMask(self: Self, value: u32) Self {
            return setDescFieldValue(self, "stencilReadMask", value);
        }
        pub fn stencilWriteMask(self: Self, value: u32) Self {
            return setDescFieldValue(self, "stencilWriteMask", value);
        }
        pub fn depthBias(self: Self, value: i32) Self {
            return setDescFieldValue(self, "depthBias", value);
        }
        pub fn depthBiasSlopeScale(self: Self, value: f32) Self {
            return setDescFieldValue(self, "depthBiasSlopeScale", value);
        }
        pub fn depthBiasClamp(self: Self, value: f32) Self {
            return setDescFieldValue(self, "depthBiasClamp", value);
        }
    };
}
pub const DepthStencilStateDesc = Desc(DepthStencilStateDescApi, RenderPipelineDesc, false);

fn StencilFaceStateDescApi(comptime Self: type) type {
    return struct {
        pub fn compare(self: Self, value: gfx.CompareFunction) Self {
            return setDescFieldValue(self, "compare", value);
        }
        pub fn failOp(self: Self, value: gfx.StencilOperation) Self {
            return setDescFieldValue(self, "failOp", value);
        }
        pub fn depthFailOp(self: Self, value: gfx.StencilOperation) Self {
            return setDescFieldValue(self, "depthFailOp", value);
        }
        pub fn passOp(self: Self, value: gfx.StencilOperation) Self {
            return setDescFieldValue(self, "passOp", value);
        }
    };
}
pub const StencilFaceStateDesc = Desc(StencilFaceStateDescApi, DepthStencilStateDesc, false);

fn MultisampleStateDescApi(comptime Self: type) type {
    return struct {
        pub fn count(self: Self, value: u32) Self {
            return setDescFieldValue(self, "count", value);
        }
        pub fn mask(self: Self, value: u32) Self {
            return setDescFieldValue(self, "mask", value);
        }
        pub fn alphaToCoverageEnabled(self: Self, value: bool) Self {
            return setDescFieldValue(self, "alphaToCoverageEnabled", value);
        }
    };
}
pub const MultisampleStateDesc = Desc(MultisampleStateDescApi, RenderPipelineDesc, false);

fn FragmentStateDescApi(comptime Self: type) type {
    return struct {
        pub fn module(self: Self, value: Shader) Self {
            return setDescFieldValue(self, "module", value);
        }
        pub fn entryPoint(self: Self, value: []const u8) Self {
            return setDescFieldValue(self, "entryPoint", value);
        }
        pub fn targets(self: Self) ColorTargetStateDescArray {
            return setDescFieldChild(self, "targets", ColorTargetStateDescArray);
        }
    };
}
pub const FragmentStateDesc = Desc(FragmentStateDescApi, RenderPipelineDesc, false);

fn ColorTargetStateDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn target(self: Self) ColorTargetStateDesc {
            return setDescChild(self, ColorTargetStateDesc);
        }
    };
}
pub const ColorTargetStateDescArray = Desc(
    ColorTargetStateDescArrayApi,
    FragmentStateDesc,
    true,
);

fn ColorTargetStateDescApi(comptime Self: type) type {
    return struct {
        pub fn format(self: Self, value: gfx.TextureFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn blend(self: Self) BlendStateDesc {
            return setDescFieldChild(self, "blend", BlendStateDesc);
        }
        pub fn writeMask(self: Self, value: gfx.ColorWriteMask) Self {
            return setDescFieldValue(self, "writeMask", value);
        }
    };
}
pub const ColorTargetStateDesc = Desc(ColorTargetStateDescApi, ColorTargetStateDescArray, false);

fn BlendStateDescApi(comptime Self: type) type {
    return struct {
        pub fn color(self: Self) BlendComponentDesc {
            return setDescFieldChild(self, "color", BlendComponentDesc);
        }
        pub fn alpha(self: Self) BlendComponentDesc {
            return setDescFieldChild(self, "alpha", BlendComponentDesc);
        }
    };
}
pub const BlendStateDesc = Desc(BlendStateDescApi, ColorTargetStateDesc, false);

fn BlendComponentDescApi(comptime Self: type) type {
    return struct {
        pub fn operation(self: Self, value: gfx.BlendOperation) Self {
            return setDescFieldValue(self, "operation", value);
        }
        pub fn srcFactor(self: Self, value: gfx.BlendFactor) Self {
            return setDescFieldValue(self, "srcFactor", value);
        }
        pub fn dstFactor(self: Self, value: gfx.BlendFactor) Self {
            return setDescFieldValue(self, "dstFactor", value);
        }
    };
}
pub const BlendComponentDesc = Desc(BlendComponentDescApi, BlendStateDesc, false);

fn RenderPassDescApi(comptime Self: type) type {
    return struct {
        pub fn colorAttachments(self: Self) ColorAttachmentDescArray {
            return setDescFieldChild(self, "colorAttachments", ColorAttachmentDescArray);
        }
        pub fn depthStencilAttachment(self: Self) DepthStencilAttachmentDesc {
            return setDescFieldChild(self, "depthStencilAttachment", DepthStencilAttachmentDesc);
        }
    };
}
pub const RenderPassDesc = Desc(RenderPassDescApi, null, false);

fn ColorAttachmentDescArrayApi(comptime Self: type) type {
    return struct {
        pub fn colorAttachment(self: Self) ColorAttachmentDesc {
            return setDescChild(self, ColorAttachmentDesc);
        }
    };
}
pub const ColorAttachmentDescArray = Desc(ColorAttachmentDescArrayApi, RenderPassDesc, true);

fn ColorAttachmentDescApi(comptime Self: type) type {
    return struct {
        pub fn view(self: Self, value: TextureView) Self {
            return setDescFieldValue(self, "view", value);
        }
        pub fn resolveTarget(self: Self, value: TextureView) Self {
            return setDescFieldValue(self, "resolveTarget", value);
        }
        pub fn loadOp(self: Self, value: gfx.LoadOp) Self {
            return setDescFieldValue(self, "loadOp", value);
        }
        pub fn clearValue(self: Self, value: gfx.Color) Self {
            return setDescFieldValue(self, "clearValue", value);
        }
        pub fn storeOp(self: Self, value: gfx.StoreOp) Self {
            return setDescFieldValue(self, "storeOp", value);
        }
    };
}
pub const ColorAttachmentDesc = Desc(ColorAttachmentDescApi, ColorAttachmentDescArray, false);

fn DepthStencilAttachmentDescApi(comptime Self: type) type {
    return struct {
        pub fn view(self: Self, value: TextureView) Self {
            return setDescFieldValue(self, "view", value);
        }
        pub fn depthLoadOp(self: Self, value: gfx.LoadOp) Self {
            return setDescFieldValue(self, "depthLoadOp", value);
        }
        pub fn depthClearValue(self: Self, value: f32) Self {
            return setDescFieldValue(self, "depthClearValue", value);
        }
        pub fn depthStoreOp(self: Self, value: gfx.StoreOp) Self {
            return setDescFieldValue(self, "depthStoreOp", value);
        }
        pub fn depthReadOnly(self: Self, value: bool) Self {
            return setDescFieldValue(self, "depthReadOnly", value);
        }
        pub fn stencilLoadOp(self: Self, value: gfx.LoadOp) Self {
            return setDescFieldValue(self, "stencilLoadOp", value);
        }
        pub fn stencilClearValue(self: Self, value: u32) Self {
            return setDescFieldValue(self, "stencilClearValue", value);
        }
        pub fn stencilStoreOp(self: Self, value: gfx.StoreOp) Self {
            return setDescFieldValue(self, "stencilStoreOp", value);
        }
        pub fn stencilReadOnly(self: Self, value: bool) Self {
            return setDescFieldValue(self, "stencilReadOnly", value);
        }
    };
}
pub const DepthStencilAttachmentDesc = Desc(
    DepthStencilAttachmentDescApi,
    RenderPassDesc,
    false,
);

fn BufferDescApi(comptime Self: type) type {
    return struct {
        pub fn size(self: Self, value: u32) Self {
            return setDescFieldValue(self, "size", value);
        }
        pub fn usage(self: Self, value: gfx.BufferUsage) Self {
            return setDescFieldValue(self, "usage", value);
        }
    };
}
pub const BufferDesc = Desc(BufferDescApi, null, false);

fn TextureDescApi(comptime Self: type) type {
    return struct {
        pub fn size(self: Self, value: gfx.Extent3d) Self {
            return setDescFieldValue(self, "size", value);
        }
        pub fn usage(self: Self, value: gfx.TextureUsage) Self {
            return setDescFieldValue(self, "usage", value);
        }
        pub fn dimension(self: Self, value: gfx.TextureDimension) Self {
            return setDescFieldValue(self, "dimension", value);
        }
        pub fn format(self: Self, value: gfx.TextureFormat) Self {
            return setDescFieldValue(self, "format", value);
        }
        pub fn mipLevelCount(self: Self, value: u32) Self {
            return setDescFieldValue(self, "mipLevelCount", value);
        }
        pub fn sampleCount(self: Self, value: u32) Self {
            return setDescFieldValue(self, "sampleCount", value);
        }
    };
}
pub const TextureDesc = Desc(TextureDescApi, null, false);

fn SamplerDescApi(comptime Self: type) type {
    return struct {
        pub fn addressModeU(self: Self, value: gfx.AddressMode) Self {
            return setDescFieldValue(self, "addressModeU", value);
        }
        pub fn addressModeV(self: Self, value: gfx.AddressMode) Self {
            return setDescFieldValue(self, "addressModeV", value);
        }
        pub fn addressModeW(self: Self, value: gfx.AddressMode) Self {
            return setDescFieldValue(self, "addressModeW", value);
        }
        pub fn magFilter(self: Self, value: gfx.FilterMode) Self {
            return setDescFieldValue(self, "magFilter", value);
        }
        pub fn minFilter(self: Self, value: gfx.FilterMode) Self {
            return setDescFieldValue(self, "minFilter", value);
        }
        pub fn mipmapFilter(self: Self, value: gfx.FilterMode) Self {
            return setDescFieldValue(self, "mipmapFilter", value);
        }
        pub fn lodMinClamp(self: Self, value: f32) Self {
            return setDescFieldValue(self, "lodMinClamp", value);
        }
        pub fn lodMaxClamp(self: Self, value: f32) Self {
            return setDescFieldValue(self, "lodMaxClamp", value);
        }
        pub fn compare(self: Self, value: gfx.CompareFunction) Self {
            return setDescFieldValue(self, "compare", value);
        }
        pub fn maxAnisotropy(self: Self, value: u32) Self {
            return setDescFieldValue(self, "maxAnisotropy", value);
        }
    };
}
pub const SamplerDesc = Desc(SamplerDescApi, null, false);

fn ImageCopyTextureDescApi(comptime Self: type) type {
    return struct {
        pub fn texture(self: Self, value: Texture) Self {
            return setDescFieldValue(self, "texture", value);
        }
        pub fn mipLevel(self: Self, value: u32) Self {
            return setDescFieldValue(self, "mipLevel", value);
        }
        pub fn origin(self: Self, value: gfx.Origin3d) Self {
            return setDescFieldValue(self, "origin", value);
        }
        pub fn aspect(self: Self, value: gfx.TextureAspect) Self {
            return setDescFieldValue(self, "aspect", value);
        }
    };
}
pub const ImageCopyTextureDesc = Desc(ImageCopyTextureDescApi, null, false);

fn ImageDataLayoutDescApi(comptime Self: type) type {
    return struct {
        pub fn offset(self: Self, value: u32) Self {
            return setDescFieldValue(self, "offset", value);
        }
        pub fn bytesPerRow(self: Self, value: u32) Self {
            return setDescFieldValue(self, "bytesPerRow", value);
        }
        pub fn rowsPerImage(self: Self, value: u32) Self {
            return setDescFieldValue(self, "rowsPerImage", value);
        }
    };
}
pub const ImageDataLayoutDesc = Desc(ImageDataLayoutDescApi, null, false);

pub const Instance = struct {
    pub fn init() !Instance {
        return Instance{};
    }
    pub fn deinit(_: *Instance) void {}

    pub fn createSurface(_: *Instance, window: app.Window) !Surface {
        return Surface{
            .canvas_id = window.id,
            .context_id = js.createContext(window.id),
        };
    }

    var request_adapter_frame: anyframe = undefined;
    var request_adapter_id: anyerror!js.AdapterId = undefined;

    pub fn requestAdapter(_: *Instance, desc: gfx.AdapterDesc) !Adapter {
        return try await async requestAdapterAsync(desc);
    }

    fn requestAdapterAsync(desc: gfx.AdapterDesc) !Adapter {
        js.requestAdapter(main.wasm_id, desc.id);
        suspend {
            request_adapter_frame = @frame();
        }
        return Adapter{ .id = try request_adapter_id };
    }

    export fn requestAdapterComplete(adapter_id: js.AdapterId) void {
        request_adapter_id = if (adapter_id == js.invalid_id)
            error.RequestAdapterFailed
        else
            adapter_id;
        resume request_adapter_frame;
    }
};

pub const Adapter = struct {
    id: js.AdapterId,

    pub fn destroy(adapter: *Adapter) void {
        js.destroyAdapter(adapter.id);
    }

    var request_device_frame: anyframe = undefined;
    var request_device_id: anyerror!js.DeviceId = undefined;

    pub fn requestDevice(adapter: *Adapter, desc: gfx.DeviceDesc) !Device {
        return try await async requestDeviceAsync(adapter, desc);
    }

    fn requestDeviceAsync(adapter: *Adapter, desc: gfx.DeviceDesc) !Device {
        js.requestDevice(main.wasm_id, adapter.id, desc.id);
        suspend {
            request_device_frame = @frame();
        }
        return Device{ .id = try request_device_id };
    }

    export fn requestDeviceComplete(device_id: js.DeviceId) void {
        request_device_id = if (device_id == js.invalid_id)
            error.RequestDeviceFailed
        else
            device_id;
        resume request_device_frame;
    }
};

pub const Device = struct {
    id: js.DeviceId,

    pub fn destroy(device: *Device) void {
        js.destroyDevice(device.id);
    }

    pub fn createSwapchain(
        device: *Device,
        surface: Surface,
        desc: gfx.SwapchainDesc,
    ) !Swapchain {
        const swapchain = Swapchain{ .id = surface.context_id };
        js.configure(main.wasm_id, device.id, swapchain.id, desc.id);
        return swapchain;
    }

    pub fn createShader(device: *Device, shader_res: build_res.ShaderRes) !Shader {
        const shader = Shader{
            .id = js.createShader(
                main.wasm_id,
                device.id,
                shader_res.data.ptr,
                shader_res.data.len,
            ),
        };
        if (cfg.opt_level != .release) {
            try device.checkShaderCompile(shader);
        }
        return shader;
    }

    var shader_compile_frame: anyframe = undefined;
    var shader_compile_result: anyerror!void = undefined;

    fn checkShaderCompile(_: *Device, shader: Shader) !void {
        try await async checkShaderCompileAsync(shader);
    }

    fn checkShaderCompileAsync(shader: Shader) !void {
        js.checkShaderCompile(main.wasm_id, shader.id);
        suspend {
            shader_compile_frame = @frame();
        }
        try shader_compile_result;
    }

    export fn checkShaderCompileComplete(err: bool) void {
        shader_compile_result = if (err) error.ShaderCompileFailed else {};
        resume shader_compile_frame;
    }

    pub fn createBindGroupLayout(
        device: *Device,
        desc: gfx.BindGroupLayoutDesc,
    ) !BindGroupLayout {
        return BindGroupLayout{
            .id = js.createBindGroupLayout(main.wasm_id, device.id, desc.id),
        };
    }

    pub fn createBindGroup(device: *Device, desc: gfx.BindGroupDesc) !BindGroup {
        return BindGroup{
            .id = js.createBindGroup(main.wasm_id, device.id, desc.id),
        };
    }

    pub fn createPipelineLayout(device: *Device, desc: gfx.PipelineLayoutDesc) !PipelineLayout {
        return PipelineLayout{ .id = js.createPipelineLayout(main.wasm_id, device.id, desc.id) };
    }

    pub fn createRenderPipeline(device: *Device, desc: gfx.RenderPipelineDesc) !RenderPipeline {
        return RenderPipeline{
            .id = js.createRenderPipeline(main.wasm_id, device.id, desc.id),
        };
    }

    pub fn createCommandEncoder(device: *Device) CommandEncoder {
        return CommandEncoder{ .id = js.createCommandEncoder(device.id) };
    }

    pub fn getQueue(device: *Device) Queue {
        return Queue{ .id = device.id };
    }

    pub fn createBuffer(device: *Device, desc: gfx.BufferDesc, data: ?[]const u8) !Buffer {
        const init_data = data orelse &[_]u8{};
        return Buffer{
            .id = js.createBuffer(
                main.wasm_id,
                device.id,
                desc.id,
                init_data.ptr,
                init_data.len,
            ),
        };
    }

    pub fn createTexture(device: *Device, desc: gfx.TextureDesc) !Texture {
        return Texture{ .id = js.createTexture(main.wasm_id, device.id, desc.id) };
    }

    pub fn createSampler(device: *Device, desc: gfx.SamplerDesc) !Sampler {
        return Sampler{ .id = js.createSampler(main.wasm_id, device.id, desc.id) };
    }
};

pub const Buffer = struct {
    id: js.BufferId,

    pub fn destroy(buffer: *Buffer) void {
        js.destroyBuffer(buffer.id);
    }
};

pub const Texture = struct {
    id: js.TextureId,

    pub fn createView(texture: *Texture) TextureView {
        return TextureView{
            .id = js.createTextureView(texture.id),
        };
    }

    pub fn destroy(texture: *Texture) void {
        js.destroyTexture(texture.id);
    }
};

pub const TextureView = struct {
    id: js.TextureViewId,

    pub fn destroy(view: *TextureView) void {
        js.destroyTextureView(view.id);
    }
};

pub const Sampler = struct {
    id: js.SamplerId,

    pub fn destroy(sampler: *Sampler) void {
        js.destroySampler(sampler.id);
    }
};

pub const Shader = struct {
    id: js.ShaderId,

    pub fn destroy(shader: *Shader) void {
        js.destroyShader(shader.id);
    }
};

pub const Surface = struct {
    canvas_id: js.CanvasId,
    context_id: js.ContextId,

    pub fn getPreferredFormat(surface: Surface, adapter: Adapter) gfx.TextureFormat {
        const format = js.getPreferredFormat(main.wasm_id, surface.context_id, adapter.id);
        return @intToEnum(gfx.TextureFormat, format);
    }

    pub fn destroy(_: *Surface) void {}
};

pub const Swapchain = struct {
    id: js.ContextId,

    pub fn getCurrentTextureView(swapchain: *Swapchain) !TextureView {
        const tex_id = js.getContextCurrentTexture(swapchain.id);
        const view_id = js.createTextureView(tex_id);
        return TextureView{ .id = view_id };
    }

    pub fn present(_: *Swapchain) void {}

    pub fn destroy(swapchain: *Swapchain) void {
        js.destroyContext(swapchain.id);
    }
};

pub const BindGroupLayout = struct {
    id: js.BindGroupLayoutId,

    pub fn destroy(bind_group_layout: *BindGroupLayout) void {
        js.destroyBindGroupLayout(bind_group_layout.id);
    }
};

pub const BindGroup = struct {
    id: js.BindGroupId,

    pub fn destroy(bind_group: *BindGroup) void {
        js.destroyBindGroup(bind_group.id);
    }
};

pub const PipelineLayout = struct {
    id: js.PipelineLayoutId,

    pub fn destroy(pipeline_layout: *PipelineLayout) void {
        js.destroyPipelineLayout(pipeline_layout.id);
    }
};

pub const RenderPipeline = struct {
    id: js.RenderPipelineId,

    pub fn destroy(render_pipeline: *RenderPipeline) void {
        js.destroyRenderPipeline(render_pipeline.id);
    }
};

pub const RenderPass = struct {
    id: js.RenderPassId,

    pub fn setPipeline(render_pass: *RenderPass, render_pipeline: RenderPipeline) void {
        js.setPipeline(render_pass.id, render_pipeline.id);
    }

    pub fn setBindGroup(
        render_pass: *RenderPass,
        group_index: u32,
        group: BindGroup,
        dynamic_offsets: ?[]const u32,
    ) void {
        const offsets = if (dynamic_offsets) |offsets|
            std.mem.sliceAsBytes(offsets)
        else
            &[_]u8{};

        js.setBindGroup(
            main.wasm_id,
            render_pass.id,
            group_index,
            group.id,
            offsets.ptr,
            offsets.len,
        );
    }

    pub fn setVertexBuffer(
        render_pass: *RenderPass,
        slot: u32,
        buffer: Buffer,
        offset: u32,
        size: usize,
    ) void {
        js.setVertexBuffer(render_pass.id, slot, buffer.id, offset, size);
    }

    pub fn setIndexBuffer(
        render_pass: *RenderPass,
        buffer: Buffer,
        index_format: gfx.IndexFormat,
        offset: usize,
        size: usize,
    ) void {
        const index_format_name = getEnumName(index_format);
        js.setIndexBuffer(
            main.wasm_id,
            render_pass.id,
            buffer.id,
            index_format_name.ptr,
            index_format_name.len,
            offset,
            size,
        );
    }

    pub fn draw(
        render_pass: *RenderPass,
        vertex_count: usize,
        instance_count: usize,
        first_vertex: usize,
        first_instance: usize,
    ) void {
        js.draw(render_pass.id, vertex_count, instance_count, first_vertex, first_instance);
    }

    pub fn drawIndexed(
        render_pass: *RenderPass,
        index_count: usize,
        instance_count: usize,
        first_index: usize,
        base_vertex: i32,
        first_instance: usize,
    ) void {
        js.drawIndexed(
            render_pass.id,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub fn end(render_pass: *RenderPass) void {
        js.endRenderPass(render_pass.id);
    }
};

pub const CommandEncoder = struct {
    id: js.CommandEncoderId,

    pub fn beginRenderPass(
        command_encoder: *CommandEncoder,
        desc: gfx.RenderPassDesc,
    ) !RenderPass {
        return RenderPass{
            .id = js.beginRenderPass(main.wasm_id, command_encoder.id, desc.id),
        };
    }

    pub fn finish(command_encoder: *CommandEncoder, _: gfx.CommandBufferDesc) CommandBuffer {
        return CommandBuffer{ .id = js.finishCommandEncoder(command_encoder.id) };
    }
};

pub const CommandBuffer = struct {
    id: js.CommandBufferId,
};

pub const QuerySet = struct {
    id: js.QuerySetId,
};

pub const Queue = struct {
    id: js.DeviceId,

    pub fn writeBuffer(
        queue: *Queue,
        buffer: Buffer,
        buffer_offset: usize,
        data: []const u8,
        data_offset: usize,
    ) void {
        js.queueWriteBuffer(
            main.wasm_id,
            queue.id,
            buffer.id,
            buffer_offset,
            data.ptr,
            data.len,
            data_offset,
        );
    }

    pub fn writeTexture(
        queue: *Queue,
        destination: gfx.ImageCopyTextureDesc,
        data: []const u8,
        data_layout: gfx.ImageDataLayoutDesc,
        size: gfx.Extent3d,
    ) void {
        js.queueWriteTexture(
            main.wasm_id,
            queue.id,
            destination.id,
            data.ptr,
            data.len,
            data_layout.id,
            size.width,
            size.height,
            size.depth_or_array_layers,
        );
    }

    pub fn submit(queue: *Queue, command_buffers: []const CommandBuffer) void {
        for (command_buffers) |command_buffer| {
            js.queueSubmit(main.wasm_id, queue.id, command_buffer.id);
        }
    }
};
