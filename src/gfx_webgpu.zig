const app = @import("app.zig");
const gfx = @import("gfx.zig");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = usize;
    const GPUIndex32 = u32;
    const GPUSampleMask = u32;
    const GPUColorWriteFlags = u32;
    const GPUTextureUsageFlags = u32;
    const GPUBufferUsageFlags = u32;
    const GPUShaderStageFlags = u32;
    const GPUStencilValue = u32;
    const GPUDepthBias = i32;
    const GPUFlagsConstant = u32;
    const GPUIntegerCoordinate = u32;

    const ObjectId = i32;
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

    const invalid_id: ObjectId = -1;

    pub const GPUColorWrite = enum(GPUFlagsConstant) {
        RED = 0x1,
        GREEN = 0x2,
        BLUE = 0x4,
        ALPHA = 0x8,
        ALL = 0xF,
    };

    pub const GPUBufferUsage = enum(GPUFlagsConstant) {
        MAP_READ = 0x0001,
        MAP_WRITE = 0x0002,
        COPY_SRC = 0x0004,
        COPY_DST = 0x0008,
        INDEX = 0x0010,
        VERTEX = 0x0020,
        UNIFORM = 0x0040,
        STORAGE = 0x0080,
        INDIRECT = 0x0100,
        QUERY_RESOLVE = 0x0200,
    };

    pub const GPUTextureUsage = enum(GPUFlagsConstant) {
        COPY_SRC = 0x01,
        COPY_DST = 0x02,
        TEXTURE_BINDING = 0x04,
        STORAGE_BINDING = 0x08,
        RENDER_ATTACHMENT = 0x10,
    };

    pub const GPUShaderStage = enum(GPUFlagsConstant) {
        VERTEX = 0x01,
        FRAGMENT = 0x02,
        COMPUTE = 0x04,
    };

    extern "webgpu" fn createContext(canvas_id: ObjectId) ContextId;
    extern "webgpu" fn destroyContext(contex_id: ContextId) void;
    extern "webgpu" fn getContextCurrentTexture(context_id: ContextId) TextureId;
    extern "webgpu" fn configure(
        device_id: DeviceId,
        context_id: ContextId,
        format_ptr: [*]const u8,
        format_len: usize,
        usage: GPUTextureUsageFlags,
        width: GPUIntegerCoordinate,
        height: GPUIntegerCoordinate,
    ) void;
    extern "webgpu" fn requestAdapter(
        json_ptr: [*]const u8,
        json_len: usize,
        cb: *c_void,
    ) void;
    extern "webgpu" fn destroyAdapter(adapter_id: AdapterId) void;
    extern "webgpu" fn requestDevice(
        adapter_id: AdapterId,
        json_ptr: [*]const u8,
        json_len: usize,
        cb: *c_void,
    ) void;
    extern "webgpu" fn destroyDevice(device_id: DeviceId) void;
    extern "webgpu" fn createShader(
        device_id: DeviceId,
        code_ptr: [*]const u8,
        code_len: usize,
    ) ShaderId;
    extern "webgpu" fn destroyShader(shader_id: ShaderId) void;
    extern "webgpu" fn checkShaderCompile(shader_id: ShaderId) void;
    extern "webgpu" fn createBindGroupLayout(
        device_id: DeviceId,
        json_ptr: [*]const u8,
        json_len: usize,
    ) BindGroupLayoutId;
    extern "webgpu" fn destroyBindGroupLayout(bind_group_layout_id: BindGroupLayoutId) void;
    extern "webgpu" fn createBindGroup(
        device_id: DeviceId,
        bind_group_layout_id: BindGroupLayoutId,
        resource_types_ptr: [*]const u8,
        resource_types_len: usize,
        resource_ids_ptr: [*]const u8,
        resource_ids_len: usize,
        buffer_offsets_ptr: [*]const u8,
        buffer_offsets_len: usize,
        buffer_sizes_ptr: [*]const u8,
        buffer_sizes_len: usize,
        json_ptr: [*]const u8,
        json_len: usize,
    ) BindGroupId;
    extern "webgpu" fn destroyBindGroup(bind_group_id: BindGroupId) void;
    extern "webgpu" fn createPipelineLayout(
        device_id: DeviceId,
        bind_group_layout_ids_ptr: [*]const u8,
        bind_group_layout_ids_len: usize,
    ) PipelineLayoutId;
    extern "webgpu" fn destroyPipelineLayout(pipeline_layout_id: PipelineLayoutId) void;
    extern "webgpu" fn createRenderPipeline(
        device_id: DeviceId,
        pipeline_layout_id: PipelineLayoutId,
        vert_shader_id: ShaderId,
        frag_shader_id: ShaderId,
        json_ptr: [*]const u8,
        json_len: usize,
    ) RenderPipelineId;
    extern "webgpu" fn destroyRenderPipeline(render_pipeline_id: RenderPipelineId) void;
    extern "webgpu" fn createCommandEncoder(device_id: DeviceId) CommandEncoderId;
    extern "webgpu" fn finishCommandEncoder(command_encoder_id: CommandEncoderId) CommandBufferId;
    extern "webgpu" fn beginRenderPass(
        command_encoder_id: CommandEncoderId,
        color_view_ids_ptr: [*]const u8,
        color_view_ids_len: usize,
        color_resolve_target_ids_ptr: [*]const u8,
        color_resolve_target_ids_len: usize,
        depth_stencil_view_tex_id: TextureId,
        depth_stencil_view_view_id: TextureViewId,
        occlusion_query_set_id: QuerySetId,
        timestamp_query_set_ids_ptr: [*]const u8,
        timestamp_query_set_ids_len: usize,
        json_ptr: [*]const u8,
        json_len: usize,
    ) RenderPassId;
    extern "webgpu" fn setPipeline(
        render_pass_id: RenderPassId,
        render_pipeline_id: RenderPipelineId,
    ) void;
    extern "webgpu" fn setBindGroup(
        render_pass_id: RenderPassId,
        group_index: GPUIndex32,
        bind_group_id: BindGroupId,
        dynamic_offsets_ptr: [*]const u8,
        dynamic_offsets_len: usize,
    ) void;
    extern "webgpu" fn setVertexBuffer(
        render_pass_id: RenderPassId,
        slot: GPUIndex32,
        buffer: BufferId,
        offset: GPUSize64,
        size: GPUSize64,
    ) void;
    extern "webgpu" fn draw(
        render_pass_id: RenderPassId,
        vertex_count: GPUSize32,
        instance_count: GPUSize32,
        first_vertex: GPUSize32,
        first_instance: GPUSize32,
    ) void;
    extern "webgpu" fn endRenderPass(render_pass_id: RenderPassId) void;
    extern "webgpu" fn queueSubmit(
        device_id: DeviceId,
        command_buffers_ptr: [*]const u8,
        command_buffers_len: usize,
    ) void;
    extern "webgpu" fn queueWriteBuffer(
        device_id: DeviceId,
        buffer_id: BufferId,
        buffer_offset: GPUSize64,
        data_ptr: [*]const u8,
        data_len: usize,
        data_offset: GPUSize64,
    ) void;
    extern "webgpu" fn createBuffer(
        device_id: DeviceId,
        size: GPUSize64,
        usage: GPUBufferUsageFlags,
        data_ptr: [*]const u8,
        data_len: usize,
    ) BufferId;
    extern "webgpu" fn destroyBuffer(buffer_id: BufferId) void;
    extern "webgpu" fn createTexture(
        device_id: DeviceId,
        usage: GPUTextureUsageFlags,
        dimension_ptr: [*]const u8,
        dimension_len: usize,
        width: GPUIntegerCoordinate,
        height: GPUIntegerCoordinate,
        depth_or_array_layers: GPUIntegerCoordinate,
        format_ptr: [*]const u8,
        format_len: usize,
        mip_level_count: GPUIntegerCoordinate,
        sample_count: GPUSize32,
    ) TextureId;
    extern "webgpu" fn destroyTexture(texture_id: TextureId) void;
    extern "webgpu" fn createTextureView(texture_id: TextureId) TextureViewId;
};

pub const Instance = struct {
    pub fn init(_: *Instance) !void {}
    pub fn deinit(_: *Instance) void {}

    pub fn createSurface(_: *Instance, window: *app.Window, comptime _: gfx.SurfaceDesc) !Surface {
        return Surface{ .id = window.id };
    }

    pub fn destroySurface(_: *Instance, _: *Surface) void {}

    pub fn requestAdapter(
        _: *Instance,
        _: *const Surface,
        comptime desc: gfx.AdapterDesc,
        adapter: *Adapter,
    ) !void {
        const json = comptime stringifyAdapterDescComptime(desc);
        js.requestAdapter(json.ptr, json.len, adapter);
    }

    export fn requestAdapterComplete(adapter_id: js.AdapterId, adapter_c: *c_void) void {
        var adapter = @ptrCast(*Adapter, @alignCast(@alignOf(*Adapter), adapter_c));
        adapter.id = adapter_id;
        gfx.cbs.adapter_ready_cb();
    }
};

pub const Adapter = struct {
    id: js.AdapterId,

    pub fn destroy(adapter: *Adapter) void {
        js.destroyAdapter(adapter.id);
    }

    pub fn requestDevice(adapter: *Adapter, comptime desc: gfx.DeviceDesc, device: *Device) !void {
        const json = comptime stringifyDeviceDescComptime(desc);
        js.requestDevice(adapter.id, json.ptr, json.len, device);
    }

    export fn requestDeviceComplete(device_id: js.DeviceId, device_c: *c_void) void {
        var device = @ptrCast(*Device, @alignCast(@alignOf(*Device), device_c));
        device.id = device_id;
        gfx.cbs.device_ready_cb();
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
        size: math.V2u32,
        comptime desc: gfx.SwapchainDesc,
    ) !Swapchain {
        const swapchain = Swapchain{ .id = js.createContext(surface.id) };
        const texture_format = comptime getTextureFormatString(desc.format);
        const texture_usage = comptime getTextureUsageFlags(desc.usage);
        js.configure(
            device.id,
            swapchain.id,
            texture_format.ptr,
            texture_format.len,
            texture_usage,
            size.x,
            size.y,
        );
        return swapchain;
    }

    pub fn destroySwapchain(_: *Device, swapchain: *Swapchain) void {
        js.destroyContext(swapchain.id);
    }

    pub fn createShader(device: *Device, code: []const u8) !Shader {
        return Shader{ .id = js.createShader(device.id, code.ptr, code.len) };
    }

    pub fn destroyShader(_: *Device, shader: *Shader) void {
        js.destroyShader(shader.id);
    }

    pub fn checkShaderCompile(_: *Device, shader: *Shader) void {
        js.checkShaderCompile(shader.id);
    }

    pub fn createBindGroupLayout(
        device: *Device,
        comptime desc: gfx.BindGroupLayoutDesc,
    ) !BindGroupLayout {
        const json = comptime stringifyBindGroupLayoutDescComptime(desc);
        return BindGroupLayout{
            .id = js.createBindGroupLayout(device.id, json.ptr, json.len),
        };
    }

    pub fn destroyBindGroupLayout(_: *Device, bind_group_layout: *BindGroupLayout) void {
        js.destroyBindGroupLayout(bind_group_layout.id);
    }

    pub fn createBindGroup(
        device: *Device,
        layout: *const BindGroupLayout,
        resources: []const BindGroupResource,
        comptime desc: gfx.BindGroupDesc,
    ) !BindGroup {
        comptime var resource_id_count = 0;
        inline for (desc.entries) |entry| {
            resource_id_count += if (entry.resource_type == .texture_view) 2 else 1;
        }
        var resource_types: [desc.entries.len]u32 = undefined;
        var resource_ids: [resource_id_count]js.ObjectId = undefined;
        var buffer_offsets: [desc.entries.len]usize = undefined;
        var buffer_sizes: [desc.entries.len]usize = undefined;
        comptime var resource_id_index = 0;
        inline for (desc.entries) |entry, i| {
            resource_types[i] = @enumToInt(entry.resource_type);
            switch (entry.resource_type) {
                .buffer => {
                    resource_ids[resource_id_index] = resources[i].buffer.resource.id;
                    buffer_offsets[i] = resources[i].buffer.offset;
                    buffer_sizes[i] = resources[i].buffer.size;
                    resource_id_index += 1;
                },
                .sampler => {
                    resource_ids[resource_id_index] = resources[i].sampler.id;
                    resource_id_index += 1;
                },
                .texture_view => {
                    resource_ids[resource_id_index] = resources[i].texture_view.tex_id;
                    resource_ids[resource_id_index + 1] = resources[i].texture_view.view_id;
                    resource_id_index += 2;
                },
            }
        }
        const resource_types_bytes = std.mem.sliceAsBytes(&resource_types);
        const resource_ids_bytes = std.mem.sliceAsBytes(&resource_ids);
        const buffer_offsets_bytes = std.mem.sliceAsBytes(&buffer_offsets);
        const buffer_sizes_bytes = std.mem.sliceAsBytes(&buffer_sizes);

        const json = comptime stringifyBindGroupDescComptime(desc);
        return BindGroup{
            .id = js.createBindGroup(
                device.id,
                layout.id,
                resource_types_bytes.ptr,
                resource_types_bytes.len,
                resource_ids_bytes.ptr,
                resource_ids_bytes.len,
                buffer_offsets_bytes.ptr,
                buffer_offsets_bytes.len,
                buffer_sizes_bytes.ptr,
                buffer_sizes_bytes.len,
                json.ptr,
                json.len,
            ),
        };
    }

    pub fn createPipelineLayout(
        device: *Device,
        bind_group_layouts: []const BindGroupLayout,
        comptime _: gfx.PipelineLayoutDesc,
    ) !PipelineLayout {
        const bytes = std.mem.sliceAsBytes(bind_group_layouts);
        return PipelineLayout{
            .id = js.createPipelineLayout(device.id, bytes.ptr, bytes.len),
        };
    }

    pub fn destroyPipelineLayout(_: *Device, pipeline_layout: *PipelineLayout) void {
        js.destroyPipelineLayout(pipeline_layout.id);
    }

    pub fn createRenderPipeline(
        device: *Device,
        pipeline_layout: *const PipelineLayout,
        vert_shader: *const Shader,
        frag_shader: *const Shader,
        comptime desc: gfx.RenderPipelineDesc,
    ) !RenderPipeline {
        const json = comptime stringifyRenderPipelineDescComptime(desc);
        return RenderPipeline{
            .id = js.createRenderPipeline(
                device.id,
                pipeline_layout.id,
                vert_shader.id,
                frag_shader.id,
                json.ptr,
                json.len,
            ),
        };
    }

    pub fn destroyRenderPipeline(_: *Device, render_pipeline: *RenderPipeline) void {
        js.destroyRenderPipeline(render_pipeline.id);
    }

    pub fn createCommandEncoder(device: *Device) CommandEncoder {
        return CommandEncoder{ .id = js.createCommandEncoder(device.id) };
    }

    pub fn getQueue(device: *Device) Queue {
        return Queue{ .id = device.id };
    }

    pub fn createBuffer(
        device: *Device,
        data: ?[]const u8,
        size: usize,
        comptime desc: gfx.BufferDesc,
    ) !Buffer {
        const init_data = if (data) |init_data| init_data else &[_]u8{};
        return Buffer{
            .id = js.createBuffer(
                device.id,
                size,
                comptime getBufferUsageFlags(desc.usage),
                init_data.ptr,
                init_data.len,
            ),
        };
    }

    pub fn createTexture(
        device: *Device,
        size: gfx.Extent3D,
        comptime desc: gfx.TextureDesc,
    ) !Texture {
        const dimension = comptime getTextureDimensionString(desc.dimension);
        const format = comptime getTextureFormatString(desc.format);
        return Texture{
            .id = js.createTexture(
                device.id,
                comptime getTextureUsageFlags(desc.usage),
                dimension.ptr,
                dimension.len,
                size.width,
                size.height,
                size.depth_or_array_layers,
                format.ptr,
                format.len,
                desc.mip_level_count,
                desc.sample_count,
            ),
        };
    }
};

export fn runtimeError(error_code: u32) void {
    const err = switch (error_code) {
        0 => error.RequestAdapterFailed,
        1 => error.RequestDeviceFailed,
        2 => error.CreateShaderFailed,
        else => error.UnknownError,
    };
    gfx.cbs.error_cb(err);
}

pub const Buffer = packed struct {
    id: js.BufferId,
};

pub const Texture = packed struct {
    id: js.TextureId,

    pub fn createView(texture: *Texture) TextureView {
        return TextureView{
            .tex_id = texture.id,
            .view_id = js.createTextureView(texture.id),
        };
    }
};

pub const TextureView = packed struct {
    tex_id: js.TextureId,
    view_id: js.TextureViewId,
};

pub const Sampler = packed struct {
    id: js.SamplerId,
};

pub const Shader = packed struct {
    id: js.ShaderId,
};

pub const Surface = packed struct {
    id: js.CanvasId,

    pub fn getPreferredFormat() gfx.TextureFormat {
        return .bgra8unorm;
    }
};

pub const Swapchain = packed struct {
    id: js.ContextId,

    pub fn getCurrentTextureView(swapchain: *Swapchain) !TextureView {
        const tex_id = js.getContextCurrentTexture(swapchain.id);
        const view_id = js.createTextureView(tex_id);
        return TextureView{ .tex_id = tex_id, .view_id = view_id };
    }

    pub fn present(_: *Swapchain) void {}
};

pub const BindGroupLayout = packed struct {
    id: js.BindGroupLayoutId,
};

pub const BufferBinding = struct {
    resource: *Buffer,
    offset: usize = 0,
    size: usize = gfx.whole_size,
};

pub const BindGroupResource = union(gfx.BindType) {
    buffer: BufferBinding,
    sampler: *Sampler,
    texture_view: *TextureView,
};

pub const BindGroup = packed struct {
    id: js.BindGroupId,
};

pub const PipelineLayout = packed struct {
    id: js.PipelineLayoutId,
};

pub const RenderPipeline = packed struct {
    id: js.RenderPipelineId,
};

pub const RenderPass = packed struct {
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
        const offsets = if (dynamic_offsets) |offsets| std.mem.sliceAsBytes(offsets) else &[_]u8{};
        js.setBindGroup(render_pass.id, group_index, group.id, offsets.ptr, offsets.len);
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

    pub fn draw(
        render_pass: *RenderPass,
        vertex_count: usize,
        instance_count: usize,
        first_vertex: usize,
        first_instance: usize,
    ) void {
        js.draw(render_pass.id, vertex_count, instance_count, first_vertex, first_instance);
    }

    pub fn end(render_pass: *RenderPass) void {
        js.endRenderPass(render_pass.id);
    }
};

pub const CommandEncoder = packed struct {
    id: js.CommandEncoderId,

    pub const RenderPassArgs = struct {
        color_views: []const TextureView,
        color_resolve_targets: []const TextureView = &.{},
        depth_stencil_view: ?*const TextureView = null,
        occlusion_query_set: ?*const QuerySet = null,
        timestamp_query_sets: []const QuerySet = &.{},
    };

    pub fn beginRenderPass(
        command_encoder: *CommandEncoder,
        args: RenderPassArgs,
        comptime desc: gfx.RenderPassDesc,
    ) RenderPass {
        const color_views_bytes = std.mem.sliceAsBytes(args.color_views);
        const color_resolve_targets_bytes = std.mem.sliceAsBytes(args.color_resolve_targets);
        const depth_stencil_view_tex_id = if (args.depth_stencil_view) |depth_stencil_view|
            depth_stencil_view.tex_id
        else
            js.invalid_id;
        const depth_stencil_view_view_id = if (args.depth_stencil_view) |depth_stencil_view|
            depth_stencil_view.view_id
        else
            js.invalid_id;
        const occlusion_query_set_id = if (args.occlusion_query_set) |occlusion_query_set|
            occlusion_query_set.id
        else
            js.invalid_id;
        const timestamp_query_set_ids = std.mem.sliceAsBytes(args.timestamp_query_sets);
        const json = comptime try stringifyRenderPassDescComptime(desc);
        return RenderPass{
            .id = js.beginRenderPass(
                command_encoder.id,
                color_views_bytes.ptr,
                color_views_bytes.len,
                color_resolve_targets_bytes.ptr,
                color_resolve_targets_bytes.len,
                depth_stencil_view_tex_id,
                depth_stencil_view_view_id,
                occlusion_query_set_id,
                timestamp_query_set_ids.ptr,
                timestamp_query_set_ids.len,
                json.ptr,
                json.len,
            ),
        };
    }

    pub fn finish(
        command_encoder: *CommandEncoder,
        comptime _: gfx.CommandBufferDesc,
    ) CommandBuffer {
        return CommandBuffer{ .id = js.finishCommandEncoder(command_encoder.id) };
    }
};

pub const CommandBuffer = packed struct {
    id: js.CommandBufferId,
};

pub const QuerySet = packed struct {
    id: js.QuerySetId,
};

pub const Queue = packed struct {
    id: js.DeviceId,

    pub fn writeBuffer(
        queue: *Queue,
        buffer: *Buffer,
        buffer_offset: usize,
        data: []const u8,
        data_offset: usize,
    ) void {
        js.queueWriteBuffer(queue.id, buffer.id, buffer_offset, data.ptr, data.len, data_offset);
    }

    pub fn submit(queue: *Queue, command_buffers: []const CommandBuffer) void {
        const bytes = std.mem.sliceAsBytes(command_buffers);
        js.queueSubmit(queue.id, bytes.ptr, bytes.len);
    }
};

fn stringifyAdapterDescComptime(comptime desc: gfx.AdapterDesc) []const u8 {
    const JsonDesc = struct {
        usingnamespace JsonOptionalStruct(@This());

        powerPreference: JsonOptional([]const u8) = .none,
        forceFallbackAdapter: JsonOptional(bool) = .none,
    };

    comptime var json: JsonDesc = .{};
    if (desc.power_preference != .@"undefined") {
        json.powerPreference = .{
            .some = comptime getPowerPreferenceString(desc.power_preference),
        };
    }
    if (desc.force_fallback_adapter) {
        json.forceFallbackAdapter = .{ .some = true };
    }

    return comptime try stringifyComptime(json);
}

fn stringifyDeviceDescComptime(comptime desc: gfx.DeviceDesc) []const u8 {
    const JsonLimits = struct {
        usingnamespace JsonOptionalStruct(@This());
        maxTextureDimension1D: JsonOptional(js.GPUSize32) = .none,
        maxTextureDimension2D: JsonOptional(js.GPUSize32) = .none,
        maxTextureDimension3D: JsonOptional(js.GPUSize32) = .none,
        maxTextureArrayLayers: JsonOptional(js.GPUSize32) = .none,
        maxBindGroups: JsonOptional(js.GPUSize32) = .none,
        maxDynamicUniformBuffersPerPipelineLayout: JsonOptional(js.GPUSize32) = .none,
        maxDynamicStorageBuffersPerPipelineLayout: JsonOptional(js.GPUSize32) = .none,
        maxSampledTexturesPerShaderStage: JsonOptional(js.GPUSize32) = .none,
        maxSamplersPerShaderStage: JsonOptional(js.GPUSize32) = .none,
        maxStorageBuffersPerShaderStage: JsonOptional(js.GPUSize32) = .none,
        maxStorageTexturesPerShaderStage: JsonOptional(js.GPUSize32) = .none,
        maxUniformBuffersPerShaderStage: JsonOptional(js.GPUSize32) = .none,
        maxUniformBufferBindingSize: JsonOptional(js.GPUSize64) = .none,
        maxStorageBufferBindingSize: JsonOptional(js.GPUSize64) = .none,
        minUniformBufferOffsetAlignment: JsonOptional(js.GPUSize32) = .none,
        minStorageBufferOffsetAlignment: JsonOptional(js.GPUSize32) = .none,
        maxVertexBuffers: JsonOptional(js.GPUSize32) = .none,
        maxVertexAttributes: JsonOptional(js.GPUSize32) = .none,
        maxVertexBufferArrayStride: JsonOptional(js.GPUSize32) = .none,
        maxInterStageShaderComponents: JsonOptional(js.GPUSize32) = .none,
        maxComputeWorkgroupStorageSize: JsonOptional(js.GPUSize32) = .none,
        maxComputeInvocationsPerWorkgroup: JsonOptional(js.GPUSize32) = .none,
        maxComputeWorkgroupSizeX: JsonOptional(js.GPUSize32) = .none,
        maxComputeWorkgroupSizeY: JsonOptional(js.GPUSize32) = .none,
        maxComputeWorkgroupSizeZ: JsonOptional(js.GPUSize32) = .none,
        maxComputeWorkgroupsPerDimension: JsonOptional(js.GPUSize32) = .none,
    };
    const JsonDesc = struct {
        usingnamespace JsonOptionalStruct(@This());
        requiredFeatures: JsonOptional([]const []const u8) = .none,
        requiredLimits: JsonOptional(JsonLimits) = .{ .some = .{} },
    };

    comptime var json: JsonDesc = .{};
    if (desc.required_features.len > 0) {
        comptime var required_features: []const []const u8 = &.{};
        inline for (desc.required_features) |required_feature| {
            required_features = required_features ++ &.{
                comptime getFeatureNameString(required_feature),
            };
        }
        json.requiredFeatures = .{ .some = required_features };
    }

    const default_limits: gfx.Limits = .{};
    comptime var all_default_limits = true;
    inline for (@typeInfo(gfx.Limits).Struct.fields) |field, i| {
        const limit = @field(desc.required_limits, field.name);
        if (limit != @field(default_limits, field.name)) {
            all_default_limits = false;
            const json_field_name = @typeInfo(JsonLimits).Struct.fields[i].name;
            @field(json.requiredLimits.some, json_field_name) = .{ .some = limit };
        }
    }

    if (all_default_limits) {
        json.requiredLimits = .none;
    }

    return comptime try stringifyComptime(json);
}

fn stringifyBindGroupLayoutDescComptime(comptime desc: gfx.BindGroupLayoutDesc) []const u8 {
    const JsonBufferBindingLayout = struct {
        usingnamespace JsonOptionalStruct(@This());
        @"type": JsonOptional([]const u8) = .none,
        hasDynamicOffset: JsonOptional(bool) = .none,
        minBindingSize: JsonOptional(js.GPUSize64) = .none,
    };
    const JsonSamplerBindingLayout = struct {
        usingnamespace JsonOptionalStruct(@This());
        @"type": JsonOptional([]const u8) = .none,
    };
    const JsonTextureBindingLayout = struct {
        usingnamespace JsonOptionalStruct(@This());
        sampleType: JsonOptional([]const u8) = .none,
        viewDimension: JsonOptional([]const u8) = .none,
        multisampled: JsonOptional(bool) = .none,
    };
    const JsonStorageTextureBindingLayout = struct {
        usingnamespace JsonOptionalStruct(@This());
        format: []const u8 = "",
        access: JsonOptional([]const u8) = .none,
        viewDimension: JsonOptional([]const u8) = .none,
    };
    const JsonEntry = struct {
        usingnamespace JsonOptionalStruct(@This());
        binding: js.GPUIndex32,
        visibility: js.GPUShaderStageFlags,
        buffer: JsonOptional(JsonBufferBindingLayout) = .none,
        sampler: JsonOptional(JsonSamplerBindingLayout) = .none,
        texture: JsonOptional(JsonTextureBindingLayout) = .none,
        storageTexture: JsonOptional(JsonStorageTextureBindingLayout) = .none,
    };
    const JsonDesc = struct {
        entries: []const JsonEntry = &.{},
    };

    comptime var json: JsonDesc = .{};

    inline for (desc.entries) |entry| {
        comptime var json_entry: JsonEntry = .{
            .binding = entry.binding,
            .visibility = comptime getShaderStageFlags(entry.visibility),
        };
        switch (entry.layout) {
            .buffer => |buffer| {
                comptime var json_buffer: JsonBufferBindingLayout = .{};
                comptime json_buffer.@"type".setIfNotDefault(
                    buffer,
                    "type",
                    getBufferBindingTypeString(buffer.@"type"),
                );
                comptime json_buffer.hasDynamicOffset.setIfNotDefault(
                    buffer,
                    "has_dynamic_offset",
                    buffer.has_dynamic_offset,
                );
                comptime json_buffer.minBindingSize.setIfNotDefault(
                    buffer,
                    "min_binding_size",
                    buffer.min_binding_size,
                );
                json_entry.buffer = .{ .some = json_buffer };
            },
            .sampler => |sampler| {
                comptime var json_sampler: JsonSamplerBindingLayout = .{};
                comptime json_sampler.@"type".setIfNotDefault(
                    sampler,
                    "type",
                    getSamplerBindingTypeString(sampler.@"type"),
                );
                json_entry.sampler = .{ .some = json_sampler };
            },
            .texture => |texture| {
                comptime var json_texture: JsonTextureBindingLayout = .{};
                comptime json_texture.sampleType.setIfNotDefault(
                    texture,
                    "sample_type",
                    getTextureSampleTypeString(texture.sample_type),
                );
                comptime json_texture.viewDimension.setIfNotDefault(
                    texture,
                    "view_dimension",
                    getTextureViewDimensionString(texture.view_dimension),
                );
                comptime json_texture.multisampled.setIfNotDefault(
                    texture,
                    "multisampled",
                    texture.multisampled,
                );
                json_entry.texture = .{ .some = json_texture };
            },
            .storage_texture => |storage_texture| {
                comptime var json_storage_texture: JsonStorageTextureBindingLayout = .{
                    .format = comptime getTextureFormatString(storage_texture.format),
                };
                comptime json_storage_texture.access.setIfNotDefault(
                    storage_texture,
                    "access",
                    getStorageTextureAccessString(storage_texture.access),
                );
                comptime json_storage_texture.viewDimension.setIfNotDefault(
                    storage_texture,
                    "view_dimension",
                    getTextureViewDimensionString(storage_texture.view_dimension),
                );
                json_entry.storageTexture = .{ .some = json_storage_texture };
            },
        }
        json.entries = json.entries ++ &[_]JsonEntry{json_entry};
    }

    return comptime try stringifyComptime(json);
}

fn stringifyBindGroupDescComptime(comptime desc: gfx.BindGroupDesc) []const u8 {
    const JsonEntry = struct {
        binding: js.GPUIndex32,
    };
    const JsonDesc = struct {
        entries: []const JsonEntry = &.{},
    };
    comptime var json: JsonDesc = .{};
    inline for (desc.entries) |entry| {
        json.entries = json.entries ++ &[_]JsonEntry{
            .{
                .binding = entry.binding,
            },
        };
    }
    return comptime try stringifyComptime(json);
}

fn stringifyRenderPipelineDescComptime(comptime desc: gfx.RenderPipelineDesc) []const u8 {
    const JsonVertAttr = struct {
        format: []const u8,
        offset: js.GPUSize64,
        shaderLocation: js.GPUIndex32,
    };
    const JsonVertLayout = struct {
        usingnamespace JsonOptionalStruct(@This());
        arrayStride: js.GPUSize64 = 0,
        stepMode: JsonOptional([]const u8) = .none,
        attributes: []const JsonVertAttr = &.{},
    };
    const JsonVertState = struct {
        usingnamespace JsonOptionalStruct(@This());
        entryPoint: []const u8 = "",
        buffers: JsonOptional([]const JsonVertLayout) = .none,
    };
    const JsonPrimState = struct {
        usingnamespace JsonOptionalStruct(@This());
        topology: JsonOptional([]const u8) = .none,
        stripIndexFormat: JsonOptional([]const u8) = .none,
        frontFace: JsonOptional([]const u8) = .none,
        cullMode: JsonOptional([]const u8) = .none,
        unclippedDepth: JsonOptional(bool) = .none,
    };
    const JsonStencilFaceState = struct {
        usingnamespace JsonOptionalStruct(@This());
        compare: JsonOptional([]const u8) = .none,
        failOp: JsonOptional([]const u8) = .none,
        depthFailOp: JsonOptional([]const u8) = .none,
        passOp: JsonOptional([]const u8) = .none,
    };
    const JsonDepthStencilState = struct {
        usingnamespace JsonOptionalStruct(@This());
        format: []const u8 = "",
        depthWriteEnabled: JsonOptional(bool) = .none,
        depthCompare: JsonOptional([]const u8) = .none,
        stencilFront: JsonOptional(JsonStencilFaceState) = .none,
        stencilBack: JsonOptional(JsonStencilFaceState) = .none,
        stencilReadMask: JsonOptional(js.GPUStencilValue) = .none,
        stencilWriteMask: JsonOptional(js.GPUStencilValue) = .none,
        depthBias: JsonOptional(js.GPUDepthBias) = .none,
        depthBiasSlopeScale: JsonOptional(f32) = .none,
        depthBiasClamp: JsonOptional(f32) = .none,
    };
    const JsonMultiState = struct {
        usingnamespace JsonOptionalStruct(@This());
        count: JsonOptional(js.GPUSize32) = .none,
        mask: JsonOptional(js.GPUSampleMask) = .none,
        alphaToCoverageEnabled: JsonOptional(bool) = .none,
    };
    const JsonBlendComp = struct {
        usingnamespace JsonOptionalStruct(@This());
        operation: JsonOptional([]const u8) = .none,
        srcFactor: JsonOptional([]const u8) = .none,
        dstFactor: JsonOptional([]const u8) = .none,
    };
    const JsonBlend = struct {
        color: JsonBlendComp = .{},
        alpha: JsonBlendComp = .{},
    };
    const JsonTarget = struct {
        usingnamespace JsonOptionalStruct(@This());
        format: []const u8 = "",
        blend: JsonOptional(JsonBlend) = .none,
        writeMask: JsonOptional(js.GPUColorWriteFlags) = .none,
    };
    const JsonFragState = struct {
        entryPoint: []const u8 = "",
        targets: []const JsonTarget = &.{},
    };
    const JsonDesc = struct {
        usingnamespace JsonOptionalStruct(@This());
        vertex: JsonVertState = .{},
        primitive: JsonOptional(JsonPrimState) = .none,
        depthStencil: JsonOptional(JsonDepthStencilState) = .none,
        multisample: JsonOptional(JsonMultiState) = .none,
        fragment: JsonOptional(JsonFragState) = .none,
    };

    comptime var json: JsonDesc = .{};
    json.vertex.entryPoint = desc.vertex.entry_point;
    if (desc.vertex.buffers.len > 0) {
        comptime var vert_buffers: []const JsonVertLayout = &.{};
        inline for (desc.vertex.buffers) |buffer| {
            comptime var json_buffer: JsonVertLayout = .{};
            json_buffer.arrayStride = buffer.array_stride;
            comptime json_buffer.stepMode.setIfNotDefault(
                buffer,
                "step_mode",
                getStepModeString(buffer.step_mode),
            );
            comptime var vert_attrs: []const JsonVertAttr = &.{};
            inline for (buffer.attributes) |attr| {
                comptime var json_attr: JsonVertAttr = .{
                    .format = comptime getVertexFormatString(attr.format),
                    .offset = attr.offset,
                    .shaderLocation = attr.shader_location,
                };
                vert_attrs = vert_attrs ++ [_]JsonVertAttr{json_attr};
            }
            json_buffer.attributes = vert_attrs;

            vert_buffers = vert_buffers ++ [_]JsonVertLayout{json_buffer};
        }
        json.vertex.buffers = .{ .some = vert_buffers };
    }

    if (comptime hasNonDefaultFields(desc.primitive)) {
        comptime var json_primitive: JsonPrimState = .{};
        comptime json_primitive.topology.setIfNotDefault(
            desc.primitive,
            "topology",
            getPrimitiveTopologyString(desc.primitive.topology),
        );
        comptime json_primitive.stripIndexFormat.setIfNotDefault(
            desc.primitive,
            "strip_index_format",
            getIndexFormatString(desc.primitive.strip_index_format),
        );
        comptime json_primitive.frontFace.setIfNotDefault(
            desc.primitive,
            "front_face",
            getFrontFaceString(desc.primitive.front_face),
        );
        comptime json_primitive.cullMode.setIfNotDefault(
            desc.primitive,
            "cull_mode",
            getCullModeString(desc.primitive.cull_mode),
        );
        json.primitive = .{ .some = json_primitive };
    }

    if (desc.depth_stencil) |depth_stencil| {
        comptime var json_depth_stencil: JsonDepthStencilState = .{};
        json_depth_stencil.format = comptime getTextureFormatString(depth_stencil.format);
        json_depth_stencil.depthWriteEnabled.setIfNotDefault(
            depth_stencil,
            "depth_write_enabled",
            depth_stencil.depth_write_enabled,
        );
        json_depth_stencil.depthCompare.setIfNotDefault(
            depth_stencil,
            "depth_compare",
            getCompareFunctionString(depth_stencil.depth_compare),
        );

        if (comptime hasNonDefaultFields(depth_stencil.stencil_front)) {
            comptime var json_stencil_front: JsonStencilFaceState = .{};
            comptime json_stencil_front.compare.setIfNotDefault(
                depth_stencil.stencil_front,
                "compare",
                getCompareFunctionString(depth_stencil.stencil_front.compare),
            );
            comptime json_stencil_front.failOp.setIfNotDefault(
                depth_stencil.stencil_front,
                "fail_op",
                getStencilOperationString(depth_stencil.stencil_front.fail_op),
            );
            comptime json_stencil_front.depthFailOp.setIfNotDefault(
                depth_stencil.stencil_front,
                "depth_fail_op",
                getStencilOperationString(depth_stencil.stencil_front.depth_fail_op),
            );
            comptime json_stencil_front.passOp.setIfNotDefault(
                depth_stencil.stencil_front,
                "pass_op",
                getStencilOperationString(depth_stencil.stencil_front.pass_op),
            );
            json_depth_stencil.stencilFront = .{ .some = json_stencil_front };
        }

        if (comptime hasNonDefaultFields(depth_stencil.stencil_back)) {
            comptime var json_stencil_back: JsonStencilFaceState = .{};
            comptime json_stencil_back.compare.setIfNotDefault(
                depth_stencil.stencil_back,
                "compare",
                getCompareFunctionString(depth_stencil.stencil_back.compare),
            );
            comptime json_stencil_back.failOp.setIfNotDefault(
                depth_stencil.stencil_back,
                "fail_op",
                getStencilOperationString(depth_stencil.stencil_back.fail_op),
            );
            comptime json_stencil_back.depthFailOp.setIfNotDefault(
                depth_stencil.stencil_back,
                "depth_fail_op",
                getStencilOperationString(depth_stencil.stencil_back.depth_fail_op),
            );
            comptime json_stencil_back.passOp.setIfNotDefault(
                depth_stencil.stencil_back,
                "pass_op",
                getStencilOperationString(depth_stencil.stencil_back.pass_op),
            );
            json_depth_stencil.stencilBack = .{ .some = json_stencil_back };
        }

        json_depth_stencil.stencilReadMask.setIfNotDefault(
            depth_stencil,
            "stencil_read_mask",
            depth_stencil.stencil_read_mask,
        );

        json_depth_stencil.stencilWriteMask.setIfNotDefault(
            depth_stencil,
            "stencil_write_mask",
            depth_stencil.stencil_write_mask,
        );

        json_depth_stencil.depthBias.setIfNotDefault(
            depth_stencil,
            "depth_bias",
            depth_stencil.depth_bias,
        );

        json_depth_stencil.depthBiasSlopeScale.setIfNotDefault(
            depth_stencil,
            "depth_bias_slope_scale",
            depth_stencil.depth_bias_slope_scale,
        );

        json_depth_stencil.depthBiasClamp.setIfNotDefault(
            depth_stencil,
            "depth_bias_clamp",
            depth_stencil.depth_bias_clamp,
        );

        json.depthStencil = .{ .some = json_depth_stencil };
    }

    if (comptime hasNonDefaultFields(desc.multisample)) {
        comptime var json_multisample: JsonMultiState = .{};

        comptime json_multisample.count.setIfNotDefault(
            desc.multisample,
            "count",
            desc.multisample.count,
        );

        comptime json_multisample.mask.setIfNotDefault(
            desc.multisample,
            "mask",
            desc.multisample.mask,
        );

        comptime json_multisample.alphaToCoverageEnabled.setIfNotDefault(
            desc.multisample,
            "alpha_to_coverage_enabled",
            desc.multisample.alpha_to_coverage_enabled,
        );

        json.multisample = .{ .some = json_multisample };
    }

    if (desc.fragment) |fragment| {
        comptime var json_fragment: JsonFragState = .{};
        json_fragment.entryPoint = fragment.entry_point;
        inline for (fragment.targets) |target| {
            comptime var json_target: JsonTarget = .{};
            json_target.format = comptime getTextureFormatString(target.format);
            if (target.blend) |blend| {
                comptime var json_blend: JsonBlend = .{};
                comptime json_blend.color.operation.setIfNotDefault(
                    blend.color,
                    "operation",
                    getBlendOperationString(blend.color.operation),
                );
                comptime json_blend.color.srcFactor.setIfNotDefault(
                    blend.color,
                    "src_factor",
                    getBlendFactorString(blend.color.src_factor),
                );
                comptime json_blend.color.dstFactor.setIfNotDefault(
                    blend.color,
                    "dst_factor",
                    getBlendFactorString(blend.color.dst_factor),
                );
                comptime json_blend.alpha.operation.setIfNotDefault(
                    blend.alpha,
                    "operation",
                    getBlendOperationString(blend.alpha.operation),
                );
                comptime json_blend.alpha.srcFactor.setIfNotDefault(
                    blend.alpha,
                    "src_factor",
                    getBlendFactorString(blend.alpha.src_factor),
                );
                comptime json_blend.alpha.dstFactor.setIfNotDefault(
                    blend.alpha,
                    "dst_factor",
                    getBlendFactorString(blend.alpha.dst_factor),
                );
                json_target.blend = .{ .some = json_blend };
            }
            comptime json_target.writeMask.setIfNotDefault(
                target,
                "write_mask",
                getColorWriteFlags(target.write_mask),
            );
            json_fragment.targets = json_fragment.targets ++ &[_]JsonTarget{json_target};
        }
        json.fragment = .{ .some = json_fragment };
    }

    return comptime try stringifyComptime(json);
}

fn stringifyRenderPassDescComptime(comptime desc: gfx.RenderPassDesc) ![]const u8 {
    const JsonColorLoadValue = union(enum) {
        loadOp: []const u8,
        clearColor: []const f64,
    };
    const JsonDepthLoadValue = union(enum) {
        loadOp: []const u8,
        clearDepth: f32,
    };
    const JsonStencilLoadValue = union(enum) {
        loadOp: []const u8,
        clearStencil: js.GPUStencilValue,
    };
    const JsonColorAttachment = struct {
        loadValue: JsonColorLoadValue,
        storeOp: []const u8,
    };
    const JsonDepthStencilAttachment = struct {
        usingnamespace JsonOptionalStruct(@This());
        depthLoadValue: JsonDepthLoadValue,
        depthStoreOp: []const u8,
        depthReadOnly: JsonOptional(bool) = .none,
        stencilLoadValue: JsonStencilLoadValue,
        stencilStoreOp: []const u8,
        stencilReadOnly: JsonOptional(bool) = .none,
    };
    const JsonTimestampWrite = struct {
        queryIndex: js.GPUSize32,
        location: []const u8,
    };
    const JsonDesc = struct {
        usingnamespace JsonOptionalStruct(@This());
        colorAttachments: []const JsonColorAttachment = &.{},
        depthStencilAttachment: JsonOptional(JsonDepthStencilAttachment) = .none,
        timestampWrites: JsonOptional([]const JsonTimestampWrite) = .none,
    };
    comptime var json: JsonDesc = .{};
    inline for (desc.color_attachments) |color_attachment| {
        json.colorAttachments = json.colorAttachments ++ &[_]JsonColorAttachment{
            .{
                .loadValue = switch (color_attachment.load_op) {
                    .clear => .{
                        .clearColor = &.{
                            color_attachment.clear_color.x,
                            color_attachment.clear_color.y,
                            color_attachment.clear_color.z,
                            color_attachment.clear_color.w,
                        },
                    },
                    .load => .{ .loadOp = "load" },
                },
                .storeOp = comptime getStoreOpString(color_attachment.store_op),
            },
        };
    }
    if (desc.depth_stencil_attachment) |depth_stencil_attachment| {
        json.depthStencilAttachment = .{
            .some = .{
                .depthLoadValue = switch (depth_stencil_attachment.depth_load_op) {
                    .clear => .{
                        .clearDepth = depth_stencil_attachment.clear_depth,
                    },
                    .load => .{ .loadOp = "load" },
                },
                .depthStoreOp = comptime getStoreOpString(
                    depth_stencil_attachment.depth_store_op,
                ),
                .stencilLoadValue = switch (depth_stencil_attachment.stencil_load_op) {
                    .clear => .{
                        .clearStencil = depth_stencil_attachment.clear_stencil,
                    },
                    .load => .{ .loadOp = "load" },
                },
                .stencilStoreOp = comptime getStoreOpString(
                    depth_stencil_attachment.stencil_store_op,
                ),
            },
        };

        comptime json.depthStencilAttachment.some.depthReadOnly.setIfNotDefault(
            depth_stencil_attachment,
            "depth_read_only",
            depth_stencil_attachment.depth_read_only,
        );
        comptime json.depthStencilAttachment.some.stencilReadOnly.setIfNotDefault(
            depth_stencil_attachment,
            "stencil_read_only",
            depth_stencil_attachment.stencil_read_only,
        );
    }

    if (desc.timestamp_writes.len > 0) {
        comptime var json_timestamp_writes: []const JsonTimestampWrite = &.{};
        inline for (desc.timestamp_writes) |timestamp_write| {
            json_timestamp_writes = json_timestamp_writes ++ &[_]JsonTimestampWrite{
                .{
                    .queryIndex = timestamp_write.query_index,
                    .location = comptime getRenderPassTimestampLocationString(
                        timestamp_write.location,
                    ),
                },
            };
        }
        json.timestampWrites = .{ .some = json_timestamp_writes };
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
    comptime try std.json.stringify(value, .{}, buffer_stream.writer());
    return &[_]u8{} ++ json[0..buffer_stream.write_index];
}

const JsonOptionalTag = enum {
    none,
    some,
};

fn JsonOptional(comptime Type: type) type {
    return union(JsonOptionalTag) {
        const Self = @This();

        none,
        some: Type,

        pub fn jsonStringify(
            optional: *const Self,
            options: std.json.StringifyOptions,
            out_stream: anytype,
        ) @TypeOf(out_stream).Error!void {
            return switch (optional.*) {
                .none => {},
                .some => |value| std.json.stringify(value, options, out_stream),
            };
        }

        pub fn setIfNotDefault(
            optional: *Self,
            check: anytype,
            comptime check_field_name: []const u8,
            value: Type,
        ) void {
            inline for (@typeInfo(@TypeOf(check)).Struct.fields) |field| {
                if (std.mem.eql(u8, field.name, check_field_name) and
                    !std.meta.eql(field.default_value.?, @field(check, check_field_name)))
                {
                    optional.* = .{ .some = value };
                }
            }
        }
    };
}

fn JsonOptionalStruct(comptime Type: type) type {
    return struct {
        // most of this code is lifted from std.json,
        // except for the code checking for the optional tag
        pub fn jsonStringify(
            value: *const Type,
            options: std.json.StringifyOptions,
            out_stream: anytype,
        ) @TypeOf(out_stream).Error!void {
            try out_stream.writeByte('{');
            comptime var field_output = false;
            var child_options = options;
            if (child_options.whitespace) |*child_whitespace| {
                child_whitespace.indent_level += 1;
            }
            inline for (@typeInfo(Type).Struct.fields) |Field| {
                // don't include void fields
                if (Field.field_type == void) continue;

                const field_info = @typeInfo(Field.field_type);
                if (field_info == .Union and
                    field_info.Union.tag_type == JsonOptionalTag and
                    @field(value, Field.name) == .none)
                {
                    continue;
                }

                if (!field_output) {
                    field_output = true;
                } else {
                    try out_stream.writeByte(',');
                }
                if (child_options.whitespace) |child_whitespace| {
                    try out_stream.writeByte('\n');
                    try child_whitespace.outputIndent(out_stream);
                }
                try std.json.stringify(Field.name, options, out_stream);
                try out_stream.writeByte(':');
                if (child_options.whitespace) |child_whitespace| {
                    if (child_whitespace.separator) {
                        try out_stream.writeByte(' ');
                    }
                }
                try std.json.stringify(@field(value, Field.name), child_options, out_stream);
            }
            if (field_output) {
                if (options.whitespace) |whitespace| {
                    try out_stream.writeByte('\n');
                    try whitespace.outputIndent(out_stream);
                }
            }
            try out_stream.writeByte('}');
        }
    };
}

fn hasNonDefaultFields(value: anytype) bool {
    inline for (@typeInfo(@TypeOf(value)).Struct.fields) |field| {
        if (!std.meta.eql(field.default_value.?, @field(value, field.name))) {
            return true;
        }
    }
    return false;
}

fn getPowerPreferenceString(comptime power_preference: gfx.PowerPreference) []const u8 {
    return replaceUnderscoreWithDash(@tagName(power_preference));
}

fn getFeatureNameString(comptime feature_name: gfx.FeatureName) []const u8 {
    return replaceUnderscoreWithDash(@tagName(feature_name));
}

fn getStepModeString(comptime step_mode: gfx.VertexStepMode) []const u8 {
    return @tagName(step_mode);
}

fn getVertexFormatString(comptime format: gfx.VertexFormat) []const u8 {
    return @tagName(format);
}

fn getPrimitiveTopologyString(comptime primitive_topology: gfx.PrimitiveTopology) []const u8 {
    return replaceUnderscoreWithDash(@tagName(primitive_topology));
}

fn getIndexFormatString(comptime index_format: gfx.IndexFormat) []const u8 {
    return @tagName(index_format);
}

fn getFrontFaceString(comptime front_face: gfx.FrontFace) []const u8 {
    return @tagName(front_face);
}

fn getCullModeString(comptime cull_mode: gfx.CullMode) []const u8 {
    return @tagName(cull_mode);
}

fn getTextureFormatString(comptime texture_format: gfx.TextureFormat) []const u8 {
    return replaceUnderscoreWithDash(@tagName(texture_format));
}

fn getCompareFunctionString(comptime compare_function: gfx.CompareFunction) []const u8 {
    return replaceUnderscoreWithDash(@tagName(compare_function));
}

fn getStencilOperationString(comptime stencil_operation: gfx.StencilOperation) []const u8 {
    return replaceUnderscoreWithDash(@tagName(stencil_operation));
}

fn getBlendOperationString(comptime blend_operation: gfx.BlendOperation) []const u8 {
    return replaceUnderscoreWithDash(@tagName(blend_operation));
}

fn getBlendFactorString(comptime blend_factor: gfx.BlendFactor) []const u8 {
    return replaceUnderscoreWithDash(@tagName(blend_factor));
}

fn getStoreOpString(comptime store_op: gfx.StoreOp) []const u8 {
    return @tagName(store_op);
}

fn getRenderPassTimestampLocationString(comptime loc: gfx.RenderPassTimestampLocation) []const u8 {
    return @tagName(loc);
}

fn getTextureDimensionString(comptime texture_dimension: gfx.TextureDimension) []const u8 {
    return @tagName(texture_dimension);
}

fn getBufferBindingTypeString(comptime buffer_binding_type: gfx.BufferBindingType) []const u8 {
    return replaceUnderscoreWithDash(@tagName(buffer_binding_type));
}

fn getSamplerBindingTypeString(comptime sampler_binding_type: gfx.SamplerBindingType) []const u8 {
    return replaceUnderscoreWithDash(@tagName(sampler_binding_type));
}

fn getTextureSampleTypeString(comptime texture_sample_type: gfx.TextureSampleType) []const u8 {
    return replaceUnderscoreWithDash(@tagName(texture_sample_type));
}

fn getTextureViewDimensionString(comptime view_dimension: gfx.TextureViewDimension) []const u8 {
    return replaceUnderscoreWithDash(@tagName(view_dimension));
}

fn getStorageTextureAccessString(comptime access: gfx.StorageTextureAccess) []const u8 {
    return replaceUnderscoreWithDash(@tagName(access));
}

fn replaceUnderscoreWithDash(comptime string: []const u8) []const u8 {
    comptime var buf: [string.len]u8 = undefined;
    _ = std.mem.replace(u8, string, "_", "-", buf[0..]);
    return buf[0..];
}

fn getBufferUsageFlags(comptime buffer_usage: gfx.BufferUsage) js.GPUBufferUsageFlags {
    return getJsEnumFlags(buffer_usage, js.GPUBufferUsage, js.GPUBufferUsageFlags);
}

fn getTextureUsageFlags(comptime texture_usage: gfx.TextureUsage) js.GPUTextureUsageFlags {
    return getJsEnumFlags(texture_usage, js.GPUTextureUsage, js.GPUTextureUsageFlags);
}

fn getColorWriteFlags(comptime color_write_mask: gfx.ColorWriteMask) js.GPUColorWriteFlags {
    return getJsEnumFlags(color_write_mask, js.GPUColorWrite, js.GPUColorWriteFlags);
}

fn getShaderStageFlags(comptime shader_stage: gfx.ShaderStage) js.GPUShaderStageFlags {
    return getJsEnumFlags(shader_stage, js.GPUShaderStage, js.GPUShaderStageFlags);
}

fn getJsEnumFlags(
    comptime value: anytype,
    comptime EnumType: type,
    comptime FlagType: type,
) FlagType {
    comptime var flags: FlagType = 0;
    inline for (std.meta.fields(@TypeOf(value))) |field| {
        comptime var js_enum_name_buf: [field.name.len]u8 = undefined;
        const js_enum_name = comptime std.ascii.upperString(&js_enum_name_buf, field.name);
        if (@field(value, field.name)) flags |= @enumToInt(@field(EnumType, js_enum_name));
    }
    return flags;
}
