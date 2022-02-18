const app = @import("app.zig");
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const gfx = @import("gfx.zig");
const main = @import("main.zig");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = usize;
    const GPUIndex32 = u32;
    const GPUSignedOffset32 = i32;
    const GPUSampleMask = u32;
    const GPUColorWriteFlags = u32;
    const GPUTextureUsageFlags = u32;
    const GPUBufferUsageFlags = u32;
    const GPUShaderStageFlags = u32;
    const GPUStencilValue = u32;
    const GPUDepthBias = i32;
    const GPUFlagsConstant = u32;
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
    const BindType = enum {
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

fn setDescField(id: js.DescId, field: []const u8) void {
    js.setDescField(main.wasm_id, id, field.ptr, field.len);
}

fn setDescString(id: js.DescId, value: []const u8) void {
    js.setDescString(main.wasm_id, id, value.ptr, value.len);
}

fn setDescBool(id: js.DescId, value: bool) void {
    js.setDescBool(id, value);
}

fn setDescU32(id: js.DescId, value: u32) void {
    js.setDescU32(id, value);
}

fn setDescI32(id: js.DescId, value: i32) void {
    js.setDescI32(id, value);
}

fn setDescF32(id: js.DescId, value: f32) void {
    js.setDescF32(id, value);
}

fn setDescEnum(id: js.DescId, value: anytype) void {
    setDescString(id, getEnumName(value));
}

fn setDescFlags(id: js.DescId, value: anytype) void {
    const BitType = @Type(.{
        .Int = .{ .signedness = .unsigned, .bits = @bitSizeOf(@TypeOf(value)) },
    });
    setDescU32(id, @intCast(u32, @bitCast(BitType, value)));
}

fn beginDescArray(id: js.DescId) void {
    js.beginDescArray(id);
}

fn endDescArray(id: js.DescId) void {
    js.endDescArray(id);
}

fn beginDescChild(id: js.DescId) void {
    js.beginDescChild(id);
}

fn endDescChild(id: js.DescId) void {
    js.endDescChild(id);
}

pub const SurfaceDesc = struct {
    id: js.DescId,

    pub fn init() SurfaceDesc {
        return SurfaceDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: SurfaceDesc) void {
        js.destroyDesc(desc.id);
    }
};

pub const AdapterDesc = struct {
    id: js.DescId,

    pub fn init() AdapterDesc {
        return AdapterDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: AdapterDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn powerPreference(desc: AdapterDesc, value: gfx.PowerPreference) AdapterDesc {
        setDescField(desc.id, "powerPreference");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn forceFallbackAdapter(desc: AdapterDesc, value: bool) AdapterDesc {
        setDescField(desc.id, "forceFallbackAdapter");
        setDescBool(desc.id, value);
        return desc;
    }
};

pub const DeviceDesc = struct {
    id: js.DescId,

    pub fn init() DeviceDesc {
        return DeviceDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: DeviceDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn requiredFeatures(desc: DeviceDesc, values: []const gfx.FeatureName) DeviceDesc {
        setDescField(desc.id, "requiredFeatures");
        beginDescArray(desc.id);
        for (values) |value| {
            setDescEnum(desc.id, value);
        }
        endDescArray(desc.id);
        return desc;
    }

    pub fn requiredLimits(desc: DeviceDesc) LimitsDesc {
        setDescField(desc.id, "requiredLimits");
        beginDescChild(desc.id);
        return LimitsDesc{ .parent = desc, .id = desc.id };
    }
};

pub const LimitsDesc = struct {
    parent: DeviceDesc,
    id: js.DescId,

    pub fn maxTextureDimension1D(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxTextureDimension1D");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxTextureDimension2D(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxTextureDimension2D");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxTextureDimension3D(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxTextureDimension3D");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxTextureArrayLayers(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxTextureArrayLayers");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxBindGroups(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxBindGroups");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxDynamicUniformBuffersPerPipelineLayout(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxDynamicUniformBuffersPerPipelineLayout");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxDynamicStorageBuffersPerPipelineLayout(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxDynamicStorageBuffersPerPipelineLayout");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxSampledTexturesPerShaderStage(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxSampledTexturesPerShaderStage");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxSamplersPerShaderStage(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxSamplersPerShaderStage");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxStorageBuffersPerShaderStage(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxStorageBuffersPerShaderStage");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxStorageTexturesPerShaderStage(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxStorageTexturesPerShaderStage");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxUniformBuffersPerShaderStage(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxUniformBuffersPerShaderStage");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxUniformBufferBindingSize(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxUniformBufferBindingSize");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxStorageBufferBindingSize(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxStorageBufferBindingSize");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn minUniformBufferOffsetAlignment(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "minUniformBufferOffsetAlignment");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn minStorageBufferOffsetAlignment(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "minStorageBufferOffsetAlignment");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxVertexBuffers(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxVertexBuffers");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxVertexAttributes(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxVertexAttributes");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxVertexBufferArrayStride(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxVertexBufferArrayStride");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxInterStageShaderComponents(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxInterStageShaderComponents");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeWorkgroupStorageSize(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeWorkgroupStorageSize");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeInvocationsPerWorkgroup(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeInvocationsPerWorkgroup");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeWorkgroupSizeX(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeWorkgroupSizeX");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeWorkgroupSizeY(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeWorkgroupSizeY");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeWorkgroupSizeZ(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeWorkgroupSizeZ");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn maxComputeWorkgroupsPerDimension(desc: LimitsDesc, value: u32) LimitsDesc {
        setDescField(desc.id, "maxComputeWorkgroupsPerDimension");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn end(desc: LimitsDesc) DeviceDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const SwapchainDesc = struct {
    id: js.DescId,

    pub fn init() SwapchainDesc {
        return SwapchainDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: SwapchainDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn size(desc: SwapchainDesc, value: gfx.Extent3d) SwapchainDesc {
        setDescField(desc.id, "size");
        beginDescArray(desc.id);
        setDescU32(desc.id, value.width);
        setDescU32(desc.id, value.height);
        setDescU32(desc.id, value.depth_or_array_layers);
        endDescArray(desc.id);
        return desc;
    }

    pub fn format(desc: SwapchainDesc, value: gfx.TextureFormat) SwapchainDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn usage(desc: SwapchainDesc, value: gfx.TextureUsage) SwapchainDesc {
        setDescField(desc.id, "usage");
        setDescFlags(desc.id, value);
        return desc;
    }

    pub fn presentMode(desc: SwapchainDesc, value: gfx.PresentMode) SwapchainDesc {
        setDescField(desc.id, "presentMode");
        setDescEnum(desc.id, value);
        return desc;
    }
};

pub const BindGroupLayoutDesc = struct {
    id: js.DescId,

    pub fn init() BindGroupLayoutDesc {
        return BindGroupLayoutDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: BindGroupLayoutDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn entries(desc: BindGroupLayoutDesc) BindGroupLayoutEntryDescArray {
        setDescField(desc.id, "entries");
        beginDescArray(desc.id);
        return BindGroupLayoutEntryDescArray{ .parent = desc, .id = desc.id };
    }
};

pub const BindGroupLayoutEntryDescArray = struct {
    parent: BindGroupLayoutDesc,
    id: js.DescId,

    pub fn entry(desc: BindGroupLayoutEntryDescArray) BindGroupLayoutEntryDesc {
        beginDescChild(desc.id);
        return BindGroupLayoutEntryDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: BindGroupLayoutEntryDescArray) BindGroupLayoutDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const BindGroupLayoutEntryDesc = struct {
    parent: BindGroupLayoutEntryDescArray,
    id: js.DescId,

    pub fn binding(desc: BindGroupLayoutEntryDesc, value: u32) BindGroupLayoutEntryDesc {
        setDescField(desc.id, "binding");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn visibility(
        desc: BindGroupLayoutEntryDesc,
        value: gfx.ShaderStage,
    ) BindGroupLayoutEntryDesc {
        setDescField(desc.id, "visibility");
        setDescFlags(desc.id, value);
        return desc;
    }

    pub fn buffer(desc: BindGroupLayoutEntryDesc) BufferBindingLayoutDesc {
        setDescField(desc.id, "buffer");
        beginDescChild(desc.id);
        return BufferBindingLayoutDesc{ .parent = desc, .id = desc.id };
    }

    pub fn sampler(desc: BindGroupLayoutEntryDesc) SamplerBindingLayoutDesc {
        setDescField(desc.id, "sampler");
        beginDescChild(desc.id);
        return SamplerBindingLayoutDesc{ .parent = desc, .id = desc.id };
    }

    pub fn texture(desc: BindGroupLayoutEntryDesc) TextureBindingLayoutDesc {
        setDescField(desc.id, "texture");
        beginDescChild(desc.id);
        return TextureBindingLayoutDesc{ .parent = desc, .id = desc.id };
    }

    pub fn storageTexture(desc: BindGroupLayoutEntryDesc) StorageTextureBindingLayoutDesc {
        setDescField(desc.id, "storageTexture");
        beginDescChild(desc.id);
        return StorageTextureBindingLayoutDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: BindGroupLayoutEntryDesc) BindGroupLayoutEntryDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BufferBindingLayoutDesc = struct {
    parent: BindGroupLayoutEntryDesc,
    id: js.DescId,

    pub fn @"type"(
        desc: BufferBindingLayoutDesc,
        value: gfx.BufferBindingType,
    ) BufferBindingLayoutDesc {
        setDescField(desc.id, "type");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn hasDynamicOffset(
        desc: BufferBindingLayoutDesc,
        value: bool,
    ) BufferBindingLayoutDesc {
        setDescField(desc.id, "hasDynamicOffset");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn minBindingSize(desc: BufferBindingLayoutDesc, value: u32) BufferBindingLayoutDesc {
        setDescField(desc.id, "minBindingSize");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn end(desc: BufferBindingLayoutDesc) BindGroupLayoutEntryDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const SamplerBindingLayoutDesc = struct {
    parent: BindGroupLayoutEntryDesc,
    id: js.DescId,

    pub fn @"type"(
        desc: SamplerBindingLayoutDesc,
        value: gfx.SamplerBindingType,
    ) SamplerBindingLayoutDesc {
        setDescField(desc.id, "type");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn end(desc: SamplerBindingLayoutDesc) BindGroupLayoutEntryDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const TextureBindingLayoutDesc = struct {
    parent: BindGroupLayoutEntryDesc,
    id: js.DescId,

    pub fn sampleType(
        desc: TextureBindingLayoutDesc,
        value: gfx.TextureSampleType,
    ) TextureBindingLayoutDesc {
        setDescField(desc.id, "sampleType");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn viewDimension(
        desc: TextureBindingLayoutDesc,
        value: gfx.TextureViewDimension,
    ) TextureBindingLayoutDesc {
        setDescField(desc.id, "viewDimension");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn multisampled(desc: TextureBindingLayoutDesc, value: bool) TextureBindingLayoutDesc {
        setDescField(desc.id, "multisampled");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn end(desc: TextureBindingLayoutDesc) BindGroupLayoutEntryDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const StorageTextureBindingLayoutDesc = struct {
    parent: BindGroupLayoutEntryDesc,
    id: js.DescId,

    pub fn access(
        desc: StorageTextureBindingLayoutDesc,
        value: gfx.StorageTextureAccess,
    ) StorageTextureBindingLayoutDesc {
        setDescField(desc.id, "access");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn format(
        desc: StorageTextureBindingLayoutDesc,
        value: gfx.TextureFormat,
    ) StorageTextureBindingLayoutDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn viewDimension(
        desc: StorageTextureBindingLayoutDesc,
        value: gfx.TextureViewDimension,
    ) StorageTextureBindingLayoutDesc {
        setDescField(desc.id, "viewDimension");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn end(desc: StorageTextureBindingLayoutDesc) BindGroupLayoutEntryDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BindGroupDesc = struct {
    id: js.DescId,

    pub fn init() BindGroupDesc {
        return BindGroupDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: BindGroupDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn layout(desc: BindGroupDesc, value: BindGroupLayout) BindGroupDesc {
        setDescField(desc.id, "layout");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn entries(desc: BindGroupDesc) BindGroupEntryDescArray {
        setDescField(desc.id, "entries");
        beginDescArray(desc.id);
        return BindGroupEntryDescArray{ .parent = desc, .id = desc.id };
    }
};

pub const BindGroupEntryDescArray = struct {
    parent: BindGroupDesc,
    id: js.DescId,

    pub fn entry(desc: BindGroupEntryDescArray) BindGroupEntryDesc {
        beginDescChild(desc.id);
        return BindGroupEntryDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: BindGroupEntryDescArray) BindGroupDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const BindGroupEntryDesc = struct {
    parent: BindGroupEntryDescArray,
    id: js.DescId,

    pub fn binding(desc: BindGroupEntryDesc, value: u32) BindGroupEntryDesc {
        setDescField(desc.id, "binding");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn resource(desc: BindGroupEntryDesc) BindingResourceDesc {
        return BindingResourceDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: BindGroupEntryDesc) BindGroupEntryDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BindingResourceDesc = struct {
    parent: BindGroupEntryDesc,
    id: js.DescId,

    pub fn buffer(desc: BindingResourceDesc) BufferBindingResourceDesc {
        setDescField(desc.id, "resourceType");
        setDescU32(desc.id, @enumToInt(js.BindType.buffer));
        setDescField(desc.id, "resource");
        beginDescChild(desc.id);
        return BufferBindingResourceDesc{ .parent = desc, .id = desc.id };
    }

    pub fn sampler(desc: BindingResourceDesc, value: Sampler) BindingResourceDesc {
        setDescField(desc.id, "resourceType");
        setDescU32(desc.id, @enumToInt(js.BindType.sampler));
        setDescField(desc.id, "resource");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn textureView(desc: BindingResourceDesc, value: TextureView) BindingResourceDesc {
        setDescField(desc.id, "resourceType");
        setDescU32(desc.id, @enumToInt(js.BindType.texture_view));
        setDescField(desc.id, "resource");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn end(desc: BindingResourceDesc) BindGroupEntryDesc {
        return desc.parent;
    }
};

pub const BufferBindingResourceDesc = struct {
    parent: BindingResourceDesc,
    id: js.DescId,

    pub fn buffer(desc: BufferBindingResourceDesc, value: Buffer) BufferBindingResourceDesc {
        setDescField(desc.id, "buffer");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn offset(desc: BufferBindingResourceDesc, value: u32) BufferBindingResourceDesc {
        setDescField(desc.id, "offset");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn size(desc: BufferBindingResourceDesc, value: u32) BufferBindingResourceDesc {
        setDescField(desc.id, "size");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn end(desc: BufferBindingResourceDesc) BindingResourceDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const PipelineLayoutDesc = struct {
    id: js.DescId,

    pub fn init() PipelineLayoutDesc {
        return PipelineLayoutDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: PipelineLayoutDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn bindGroupLayouts(
        desc: PipelineLayoutDesc,
        values: []const BindGroupLayout,
    ) PipelineLayoutDesc {
        setDescField(desc.id, "bindGroupLayouts");
        beginDescArray(desc.id);
        for (values) |value| {
            setDescU32(desc.id, value.id);
        }
        endDescArray(desc.id);
        return desc;
    }
};

pub const RenderPipelineDesc = struct {
    id: js.DescId,

    pub fn init() RenderPipelineDesc {
        return RenderPipelineDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: RenderPipelineDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn layout(desc: RenderPipelineDesc, value: PipelineLayout) RenderPipelineDesc {
        setDescField(desc.id, "layout");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn vertex(desc: RenderPipelineDesc) VertexStateDesc {
        setDescField(desc.id, "vertex");
        beginDescChild(desc.id);
        return VertexStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn primitive(desc: RenderPipelineDesc) PrimitiveStateDesc {
        setDescField(desc.id, "primitive");
        beginDescChild(desc.id);
        return PrimitiveStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn depthStencil(desc: RenderPipelineDesc) DepthStencilStateDesc {
        setDescField(desc.id, "depthStencil");
        beginDescChild(desc.id);
        return DepthStencilStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn multisample(desc: RenderPipelineDesc) MultisampleStateDesc {
        setDescField(desc.id, "multisample");
        beginDescChild(desc.id);
        return MultisampleStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn fragment(desc: RenderPipelineDesc) FragmentStateDesc {
        setDescField(desc.id, "fragment");
        beginDescChild(desc.id);
        return FragmentStateDesc{ .parent = desc, .id = desc.id };
    }
};

pub const VertexStateDesc = struct {
    parent: RenderPipelineDesc,
    id: js.DescId,

    pub fn module(desc: VertexStateDesc, value: Shader) VertexStateDesc {
        setDescField(desc.id, "module");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn entryPoint(desc: VertexStateDesc, value: []const u8) VertexStateDesc {
        setDescField(desc.id, "entryPoint");
        setDescString(desc.id, value);
        return desc;
    }

    pub fn buffers(desc: VertexStateDesc) VertexBufferLayoutDescArray {
        setDescField(desc.id, "buffers");
        beginDescArray(desc.id);
        return VertexBufferLayoutDescArray{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: VertexStateDesc) RenderPipelineDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const VertexBufferLayoutDescArray = struct {
    parent: VertexStateDesc,
    id: js.DescId,

    pub fn buffer(desc: VertexBufferLayoutDescArray) VertexBufferLayoutDesc {
        beginDescChild(desc.id);
        return VertexBufferLayoutDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: VertexBufferLayoutDescArray) VertexStateDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const VertexBufferLayoutDesc = struct {
    parent: VertexBufferLayoutDescArray,
    id: js.DescId,

    pub fn arrayStride(desc: VertexBufferLayoutDesc, value: u32) VertexBufferLayoutDesc {
        setDescField(desc.id, "arrayStride");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn stepMode(
        desc: VertexBufferLayoutDesc,
        value: gfx.VertexStepMode,
    ) VertexBufferLayoutDesc {
        setDescField(desc.id, "stepMode");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn attributes(desc: VertexBufferLayoutDesc) VertexAttributeDescArray {
        setDescField(desc.id, "attributes");
        beginDescArray(desc.id);
        return VertexAttributeDescArray{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: VertexBufferLayoutDesc) VertexBufferLayoutDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const VertexAttributeDescArray = struct {
    parent: VertexBufferLayoutDesc,
    id: js.DescId,

    pub fn attribute(desc: VertexAttributeDescArray) VertexAttributeDesc {
        beginDescChild(desc.id);
        return VertexAttributeDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: VertexAttributeDescArray) VertexBufferLayoutDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const VertexAttributeDesc = struct {
    parent: VertexAttributeDescArray,
    id: js.DescId,

    pub fn format(desc: VertexAttributeDesc, value: gfx.VertexFormat) VertexAttributeDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn offset(desc: VertexAttributeDesc, value: u32) VertexAttributeDesc {
        setDescField(desc.id, "offset");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn shaderLocation(desc: VertexAttributeDesc, value: u32) VertexAttributeDesc {
        setDescField(desc.id, "shaderLocation");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn end(desc: VertexAttributeDesc) VertexAttributeDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const PrimitiveStateDesc = struct {
    parent: RenderPipelineDesc,
    id: js.DescId,

    pub fn topology(desc: PrimitiveStateDesc, value: gfx.PrimitiveTopology) PrimitiveStateDesc {
        setDescField(desc.id, "topology");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn stripIndexFormat(
        desc: PrimitiveStateDesc,
        value: gfx.IndexFormat,
    ) PrimitiveStateDesc {
        setDescField(desc.id, "stripIndexFormat");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn frontFace(desc: PrimitiveStateDesc, value: gfx.FrontFace) PrimitiveStateDesc {
        setDescField(desc.id, "frontFace");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn cullMode(desc: PrimitiveStateDesc, value: gfx.CullMode) PrimitiveStateDesc {
        setDescField(desc.id, "cullMode");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn end(desc: PrimitiveStateDesc) RenderPipelineDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const DepthStencilStateDesc = struct {
    parent: RenderPipelineDesc,
    id: js.DescId,

    pub fn format(desc: DepthStencilStateDesc, value: gfx.TextureFormat) DepthStencilStateDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn depthWriteEnabled(desc: DepthStencilStateDesc, value: bool) DepthStencilStateDesc {
        setDescField(desc.id, "depthWriteEnabled");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn depthCompare(
        desc: DepthStencilStateDesc,
        value: gfx.CompareFunction,
    ) DepthStencilStateDesc {
        setDescField(desc.id, "depthCompare");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn stencilFront(desc: DepthStencilStateDesc) StencilFaceStateDesc {
        setDescField(desc.id, "stencilFront");
        beginDescChild(desc.id);
        return StencilFaceStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn stencilBack(desc: DepthStencilStateDesc) StencilFaceStateDesc {
        setDescField(desc.id, "stencilBack");
        beginDescChild(desc.id);
        return StencilFaceStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn stencilReadMask(desc: DepthStencilStateDesc, value: u32) DepthStencilStateDesc {
        setDescField(desc.id, "stencilReadMask");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn stencilWriteMask(desc: DepthStencilStateDesc, value: u32) DepthStencilStateDesc {
        setDescField(desc.id, "stencilWriteMask");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn depthBias(desc: DepthStencilStateDesc, value: i32) DepthStencilStateDesc {
        setDescField(desc.id, "depthBias");
        setDescI32(desc.id, value);
        return desc;
    }

    pub fn depthBiasSlopeScale(desc: DepthStencilStateDesc, value: f32) DepthStencilStateDesc {
        setDescField(desc.id, "depthBiasSlopeScale");
        setDescF32(desc.id, value);
        return desc;
    }

    pub fn depthBiasClamp(desc: DepthStencilStateDesc, value: f32) DepthStencilStateDesc {
        setDescField(desc.id, "depthBiasClamp");
        setDescF32(desc.id, value);
        return desc;
    }

    pub fn end(desc: DepthStencilStateDesc) RenderPipelineDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const StencilFaceStateDesc = struct {
    parent: DepthStencilStateDesc,
    id: js.DescId,

    pub fn compare(desc: StencilFaceStateDesc, value: gfx.CompareFunction) StencilFaceStateDesc {
        setDescField(desc.id, "compare");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn failOp(desc: StencilFaceStateDesc, value: gfx.StencilOperation) StencilFaceStateDesc {
        setDescField(desc.id, "failOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn depthFailOp(
        desc: StencilFaceStateDesc,
        value: gfx.StencilOperation,
    ) StencilFaceStateDesc {
        setDescField(desc.id, "depthFailOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn passOp(desc: StencilFaceStateDesc, value: gfx.StencilOperation) StencilFaceStateDesc {
        setDescField(desc.id, "passOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn end(desc: StencilFaceStateDesc) DepthStencilStateDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const MultisampleStateDesc = struct {
    parent: RenderPipelineDesc,
    id: js.DescId,

    pub fn count(desc: MultisampleStateDesc, value: u32) MultisampleStateDesc {
        setDescField(desc.id, "count");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn mask(desc: MultisampleStateDesc, value: u32) MultisampleStateDesc {
        setDescField(desc.id, "mask");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn alphaToCoverageEnabled(desc: MultisampleStateDesc, value: bool) MultisampleStateDesc {
        setDescField(desc.id, "alphaToCoverageEnabled");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn end(desc: MultisampleStateDesc) RenderPipelineDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const FragmentStateDesc = struct {
    parent: RenderPipelineDesc,
    id: js.DescId,

    pub fn module(desc: FragmentStateDesc, value: Shader) FragmentStateDesc {
        setDescField(desc.id, "module");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn entryPoint(desc: FragmentStateDesc, value: []const u8) FragmentStateDesc {
        setDescField(desc.id, "entryPoint");
        setDescString(desc.id, value);
        return desc;
    }

    pub fn targets(desc: FragmentStateDesc) ColorTargetStateDescArray {
        setDescField(desc.id, "targets");
        beginDescArray(desc.id);
        return ColorTargetStateDescArray{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: FragmentStateDesc) RenderPipelineDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const ColorTargetStateDescArray = struct {
    parent: FragmentStateDesc,
    id: js.DescId,

    pub fn target(desc: ColorTargetStateDescArray) ColorTargetStateDesc {
        beginDescChild(desc.id);
        return ColorTargetStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: ColorTargetStateDescArray) FragmentStateDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const ColorTargetStateDesc = struct {
    parent: ColorTargetStateDescArray,
    id: js.DescId,

    pub fn format(desc: ColorTargetStateDesc, value: gfx.TextureFormat) ColorTargetStateDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn blend(desc: ColorTargetStateDesc) BlendStateDesc {
        setDescField(desc.id, "blend");
        beginDescChild(desc.id);
        return BlendStateDesc{ .parent = desc, .id = desc.id };
    }

    pub fn writeMask(
        desc: ColorTargetStateDesc,
        value: gfx.ColorWriteMask,
    ) ColorTargetStateDesc {
        setDescField(desc.id, "writeMask");
        setDescFlags(desc.id, value);
    }

    pub fn end(desc: ColorTargetStateDesc) ColorTargetStateDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BlendStateDesc = struct {
    parent: ColorTargetStateDesc,
    id: js.DescId,

    pub fn color(desc: BlendStateDesc) BlendComponentDesc {
        setDescField(desc.id, "color");
        beginDescChild(desc.id);
        return BlendComponentDesc{ .parent = desc, .id = desc.id };
    }

    pub fn alpha(desc: BlendStateDesc) BlendComponentDesc {
        setDescField(desc.id, "alpha");
        beginDescChild(desc.id);
        return BlendComponentDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: BlendStateDesc) ColorTargetStateDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BlendComponentDesc = struct {
    parent: BlendStateDesc,
    id: js.DescId,

    pub fn operation(desc: BlendComponentDesc, value: gfx.BlendOperation) BlendComponentDesc {
        setDescField(desc.id, "operation");
        setDescEnum(desc.id, value);
    }

    pub fn srcFactor(desc: BlendComponentDesc, value: gfx.BlendFactor) BlendComponentDesc {
        setDescField(desc.id, "srcFactor");
        setDescEnum(desc.id, value);
    }

    pub fn dstFactor(desc: BlendComponentDesc, value: gfx.BlendFactor) BlendComponentDesc {
        setDescField(desc.id, "dstFactor");
        setDescEnum(desc.id, value);
    }
};

pub const RenderPassDesc = struct {
    id: js.DescId,

    pub fn init() RenderPassDesc {
        return RenderPassDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: RenderPassDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn colorAttachments(desc: RenderPassDesc) ColorAttachmentDescArray {
        setDescField(desc.id, "colorAttachments");
        beginDescArray(desc.id);
        return ColorAttachmentDescArray{ .parent = desc, .id = desc.id };
    }

    pub fn depthStencilAttachment(desc: RenderPassDesc) DepthStencilAttachmentDesc {
        setDescField(desc.id, "depthStencilAttachment");
        beginDescChild(desc.id);
        return DepthStencilAttachmentDesc{ .parent = desc, .id = desc.id };
    }
};

pub const ColorAttachmentDescArray = struct {
    parent: RenderPassDesc,
    id: js.DescId,

    pub fn colorAttachment(desc: ColorAttachmentDescArray) ColorAttachmentDesc {
        beginDescChild(desc.id);
        return ColorAttachmentDesc{ .parent = desc, .id = desc.id };
    }

    pub fn end(desc: ColorAttachmentDescArray) RenderPassDesc {
        endDescArray(desc.id);
        return desc.parent;
    }
};

pub const ColorAttachmentDesc = struct {
    parent: ColorAttachmentDescArray,
    id: js.DescId,

    pub fn view(desc: ColorAttachmentDesc, value: TextureView) ColorAttachmentDesc {
        setDescField(desc.id, "view");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn resolveTarget(desc: ColorAttachmentDesc, value: TextureView) ColorAttachmentDesc {
        setDescField(desc.id, "resolveTarget");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn loadOp(desc: ColorAttachmentDesc, value: gfx.LoadOp) ColorAttachmentDesc {
        setDescField(desc.id, "loadOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn clearValue(desc: ColorAttachmentDesc, value: gfx.Color) ColorAttachmentDesc {
        setDescField(desc.id, "clearValue");
        beginDescArray(desc.id);
        setDescF32(desc.id, value.r);
        setDescF32(desc.id, value.g);
        setDescF32(desc.id, value.b);
        setDescF32(desc.id, value.a);
        endDescArray(desc.id);
        return desc;
    }

    pub fn storeOp(desc: ColorAttachmentDesc, value: gfx.StoreOp) ColorAttachmentDesc {
        setDescField(desc.id, "storeOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn end(desc: ColorAttachmentDesc) ColorAttachmentDescArray {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const DepthStencilAttachmentDesc = struct {
    parent: RenderPassDesc,
    id: js.DescId,

    pub fn view(
        desc: DepthStencilAttachmentDesc,
        value: TextureView,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "view");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn depthLoadOp(
        desc: DepthStencilAttachmentDesc,
        value: gfx.LoadOp,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "depthLoadOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn depthClearValue(
        desc: DepthStencilAttachmentDesc,
        value: f32,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "depthClearValue");
        setDescF32(desc.id, value);
        return desc;
    }

    pub fn depthStoreOp(
        desc: DepthStencilAttachmentDesc,
        value: gfx.StoreOp,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "depthStoreOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn depthReadOnly(
        desc: DepthStencilAttachmentDesc,
        value: bool,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "depthReadOnly");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn stencilLoadOp(
        desc: DepthStencilAttachmentDesc,
        value: gfx.LoadOp,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "stencilLoadOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn stencilClearValue(
        desc: DepthStencilAttachmentDesc,
        value: u32,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "stencilClearValue");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn stencilStoreOp(
        desc: DepthStencilAttachmentDesc,
        value: gfx.StoreOp,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "stencilStoreOp");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn stencilReadOnly(
        desc: DepthStencilAttachmentDesc,
        value: bool,
    ) DepthStencilAttachmentDesc {
        setDescField(desc.id, "stencilReadOnly");
        setDescBool(desc.id, value);
        return desc;
    }

    pub fn end(desc: DepthStencilAttachmentDesc) RenderPassDesc {
        endDescChild(desc.id);
        return desc.parent;
    }
};

pub const BufferDesc = struct {
    id: js.DescId,

    pub fn init() BufferDesc {
        return BufferDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: BufferDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn size(desc: BufferDesc, value: u32) BufferDesc {
        setDescField(desc.id, "size");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn usage(desc: BufferDesc, value: gfx.BufferUsage) BufferDesc {
        setDescField(desc.id, "usage");
        setDescFlags(desc.id, value);
        return desc;
    }
};

pub const TextureDesc = struct {
    id: js.DescId,

    pub fn init() TextureDesc {
        return TextureDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: TextureDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn size(desc: TextureDesc, value: gfx.Extent3d) TextureDesc {
        setDescField(desc.id, "size");
        beginDescArray(desc.id);
        setDescU32(desc.id, value.width);
        setDescU32(desc.id, value.height);
        setDescU32(desc.id, value.depth_or_array_layers);
        endDescArray(desc.id);
        return desc;
    }

    pub fn usage(desc: TextureDesc, value: gfx.TextureUsage) TextureDesc {
        setDescField(desc.id, "usage");
        setDescFlags(desc.id, value);
        return desc;
    }

    pub fn dimension(desc: TextureDesc, value: gfx.TextureDimension) TextureDesc {
        setDescField(desc.id, "dimension");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn format(desc: TextureDesc, value: gfx.TextureFormat) TextureDesc {
        setDescField(desc.id, "format");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn mipLevelCount(desc: TextureDesc, value: u32) TextureDesc {
        setDescField(desc.id, "mipLevelCount");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn sampleCount(desc: TextureDesc, value: u32) TextureDesc {
        setDescField(desc.id, "sampleCount");
        setDescU32(desc.id, value);
        return desc;
    }
};

pub const SamplerDesc = struct {
    id: js.DescId,

    pub fn init() SamplerDesc {
        return SamplerDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: SamplerDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn addressModeU(desc: SamplerDesc, value: gfx.AddressMode) SamplerDesc {
        setDescField(desc.id, "addressModeU");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn addressModeV(desc: SamplerDesc, value: gfx.AddressMode) SamplerDesc {
        setDescField(desc.id, "addressModeV");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn addressModeW(desc: SamplerDesc, value: gfx.AddressMode) SamplerDesc {
        setDescField(desc.id, "addressModeW");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn magFilter(desc: SamplerDesc, value: gfx.FilterMode) SamplerDesc {
        setDescField(desc.id, "magFilter");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn minFilter(desc: SamplerDesc, value: gfx.FilterMode) SamplerDesc {
        setDescField(desc.id, "minFilter");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn mipmapFilter(desc: SamplerDesc, value: gfx.FilterMode) SamplerDesc {
        setDescField(desc.id, "mipmapFilter");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn lodMinClamp(desc: SamplerDesc, value: f32) SamplerDesc {
        setDescField(desc.id, "lodMinClamp");
        setDescF32(desc.id, value);
        return desc;
    }

    pub fn lodMaxClamp(desc: SamplerDesc, value: f32) SamplerDesc {
        setDescField(desc.id, "lodMaxClamp");
        setDescF32(desc.id, value);
        return desc;
    }

    pub fn compare(desc: SamplerDesc, value: gfx.CompareFunction) SamplerDesc {
        setDescField(desc.id, "compare");
        setDescEnum(desc.id, value);
        return desc;
    }

    pub fn maxAnisotropy(desc: SamplerDesc, value: u32) SamplerDesc {
        setDescField(desc.id, "maxAnisotropy");
        setDescU32(desc.id, value);
        return desc;
    }
};

pub const ImageCopyTextureDesc = struct {
    id: js.DescId,

    pub fn init() ImageCopyTextureDesc {
        return ImageCopyTextureDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: ImageCopyTextureDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn texture(desc: ImageCopyTextureDesc, value: Texture) ImageCopyTextureDesc {
        setDescField(desc.id, "texture");
        setDescU32(desc.id, value.id);
        return desc;
    }

    pub fn mipLevel(desc: ImageCopyTextureDesc, value: u32) ImageCopyTextureDesc {
        setDescField(desc.id, "mipLevel");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn origin(desc: ImageCopyTextureDesc, value: gfx.Origin3d) ImageCopyTextureDesc {
        setDescField(desc.id, "origin");
        beginDescArray(desc.id);
        setDescU32(desc.id, value.x);
        setDescU32(desc.id, value.y);
        setDescU32(desc.id, value.z);
        endDescArray(desc.id);
        return desc;
    }

    pub fn aspect(desc: ImageCopyTextureDesc, value: gfx.TextureAspect) ImageCopyTextureDesc {
        setDescField(desc.id, "aspect");
        setDescEnum(desc.id, value);
        return desc;
    }
};

pub const ImageDataLayoutDesc = struct {
    id: js.DescId,

    pub fn init() ImageDataLayoutDesc {
        return ImageDataLayoutDesc{ .id = js.createDesc() };
    }

    pub fn deinit(desc: ImageDataLayoutDesc) void {
        js.destroyDesc(desc.id);
    }

    pub fn offset(desc: ImageDataLayoutDesc, value: u32) ImageDataLayoutDesc {
        setDescField(desc.id, "offset");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn bytesPerRow(desc: ImageDataLayoutDesc, value: u32) ImageDataLayoutDesc {
        setDescField(desc.id, "bytesPerRow");
        setDescU32(desc.id, value);
        return desc;
    }

    pub fn rowsPerImage(desc: ImageDataLayoutDesc, value: u32) ImageDataLayoutDesc {
        setDescField(desc.id, "rowsPerImage");
        setDescU32(desc.id, value);
        return desc;
    }
};

pub const Instance = struct {
    pub fn init() !Instance {
        return Instance{};
    }
    pub fn deinit(_: *Instance) void {}

    pub fn createSurface(
        _: *Instance,
        window: *app.Window,
        _: gfx.SurfaceDesc,
    ) !Surface {
        return Surface{ .id = window.id };
    }

    var request_adapter_frame: anyframe = undefined;
    var request_adapter_id: anyerror!js.AdapterId = undefined;

    pub fn requestAdapter(
        _: *Instance,
        surface: *Surface,
        desc: gfx.AdapterDesc,
    ) !Adapter {
        _ = surface;
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

    pub fn requestDevice(
        adapter: *Adapter,
        desc: gfx.DeviceDesc,
    ) !Device {
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
        surface: *Surface,
        desc: gfx.SwapchainDesc,
    ) !Swapchain {
        const swapchain = Swapchain{ .id = js.createContext(surface.id) };
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
            try device.checkShaderCompile(&shader);
        }
        return shader;
    }

    var shader_compile_frame: anyframe = undefined;
    var shader_compile_result: anyerror!void = undefined;

    fn checkShaderCompile(_: *Device, shader: *const Shader) !void {
        try await async checkShaderCompileAsync(shader);
    }

    fn checkShaderCompileAsync(shader: *const Shader) !void {
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
            .id = js.createBindGroupLayout(
                main.wasm_id,
                device.id,
                desc.id,
            ),
        };
    }

    pub fn createBindGroup(
        device: *Device,
        desc: gfx.BindGroupDesc,
    ) !BindGroup {
        return BindGroup{
            .id = js.createBindGroup(
                main.wasm_id,
                device.id,
                desc.id,
            ),
        };
    }

    pub fn createPipelineLayout(device: *Device, desc: gfx.PipelineLayoutDesc) !PipelineLayout {
        return PipelineLayout{ .id = js.createPipelineLayout(main.wasm_id, device.id, desc.id) };
    }

    pub fn createRenderPipeline(
        device: *Device,
        desc: gfx.RenderPipelineDesc,
    ) !RenderPipeline {
        return RenderPipeline{
            .id = js.createRenderPipeline(
                main.wasm_id,
                device.id,
                desc.id,
            ),
        };
    }

    pub fn createCommandEncoder(device: *Device) CommandEncoder {
        return CommandEncoder{ .id = js.createCommandEncoder(device.id) };
    }

    pub fn getQueue(device: *Device) Queue {
        return Queue{ .id = device.id };
    }

    pub fn createBuffer(
        device: *Device,
        desc: gfx.BufferDesc,
        data: ?[]const u8,
    ) !Buffer {
        // std.mem.alignForward(desc.size, 4),
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

    pub fn createTexture(
        device: *Device,
        desc: gfx.TextureDesc,
    ) !Texture {
        return Texture{
            .id = js.createTexture(
                main.wasm_id,
                device.id,
                desc.id,
            ),
        };
    }

    pub fn createSampler(device: *Device, desc: gfx.SamplerDesc) !Sampler {
        return Sampler{ .id = js.createSampler(
            main.wasm_id,
            device.id,
            desc.id,
        ) };
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
    id: js.CanvasId,

    pub fn getPreferredFormat() gfx.TextureFormat {
        return .bgra8unorm;
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

    pub fn setPipeline(render_pass: *RenderPass, render_pipeline: *RenderPipeline) void {
        js.setPipeline(render_pass.id, render_pipeline.id);
    }

    pub fn setBindGroup(
        render_pass: *RenderPass,
        group_index: u32,
        group: *BindGroup,
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
        buffer: *Buffer,
        offset: u32,
        size: usize,
    ) void {
        js.setVertexBuffer(render_pass.id, slot, buffer.id, offset, size);
    }

    pub fn setIndexBuffer(
        render_pass: *RenderPass,
        buffer: *Buffer,
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
            .id = js.beginRenderPass(
                main.wasm_id,
                command_encoder.id,
                desc.id,
            ),
        };
    }

    pub fn finish(
        command_encoder: *CommandEncoder,
        _: gfx.CommandBufferDesc,
    ) CommandBuffer {
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
        buffer: *Buffer,
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
