const app = @import("app.zig");
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

    extern fn createContext(canvas_id: ObjectId) ContextId;
    extern fn destroyContext(contex_id: ContextId) void;
    extern fn getContextCurrentTexture(context_id: ContextId) TextureId;
    extern fn configure(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        context_id: ContextId,
        format_ptr: [*]const u8,
        format_len: usize,
        usage: GPUTextureUsageFlags,
        width: GPUIntegerCoordinate,
        height: GPUIntegerCoordinate,
    ) void;
    extern fn requestAdapter(
        wasm_id: main.WasmId,
        json_ptr: [*]const u8,
        json_len: usize,
        adapter: *Adapter,
        user_data: ?*anyopaque,
    ) void;
    extern fn destroyAdapter(adapter_id: AdapterId) void;
    extern fn requestDevice(
        wasm_id: main.WasmId,
        adapter_id: AdapterId,
        json_ptr: [*]const u8,
        json_len: usize,
        device: *Device,
        user_data: ?*anyopaque,
    ) void;
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
        json_ptr: [*]const u8,
        json_len: usize,
    ) BindGroupLayoutId;
    extern fn destroyBindGroupLayout(bind_group_layout_id: BindGroupLayoutId) void;
    extern fn createBindGroup(
        wasm_id: main.WasmId,
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
    extern fn destroyBindGroup(bind_group_id: BindGroupId) void;
    extern fn createPipelineLayout(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        bind_group_layout_ids_ptr: [*]const u8,
        bind_group_layout_ids_len: usize,
    ) PipelineLayoutId;
    extern fn destroyPipelineLayout(pipeline_layout_id: PipelineLayoutId) void;
    extern fn createRenderPipeline(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        pipeline_layout_id: PipelineLayoutId,
        vert_shader_id: ShaderId,
        frag_shader_id: ShaderId,
        json_ptr: [*]const u8,
        json_len: usize,
    ) RenderPipelineId;
    extern fn destroyRenderPipeline(render_pipeline_id: RenderPipelineId) void;
    extern fn createCommandEncoder(device_id: DeviceId) CommandEncoderId;
    extern fn finishCommandEncoder(command_encoder_id: CommandEncoderId) CommandBufferId;
    extern fn beginRenderPass(
        hash: u32,
        wasm_id: main.WasmId,
        command_encoder_id: CommandEncoderId,
        color_view_ids_ptr: [*]const u8,
        color_view_ids_len: usize,
        color_resolve_target_ids_ptr: [*]const u8,
        color_resolve_target_ids_len: usize,
        depth_stencil_view_id: TextureViewId,
        occlusion_query_set_id: QuerySetId,
        timestamp_query_set_ids_ptr: [*]const u8,
        timestamp_query_set_ids_len: usize,
        json_ptr: [*]const u8,
        json_len: usize,
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
        index_format_id: u32,
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
    extern fn createBuffer(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        size: GPUSize64,
        usage: GPUBufferUsageFlags,
        data_ptr: [*]const u8,
        data_len: usize,
    ) BufferId;
    extern fn destroyBuffer(buffer_id: BufferId) void;
    extern fn createTexture(
        wasm_id: main.WasmId,
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
    extern fn destroyTexture(texture_id: TextureId) void;
    extern fn createTextureView(texture_id: TextureId) TextureViewId;
    extern fn destroyTextureView(texture_view_id: TextureViewId) void;
};

pub const Instance = struct {
    pub fn init(_: *Instance) !void {}
    pub fn deinit(_: *Instance) void {}

    pub fn createSurface(_: *Instance, window: *app.Window, comptime _: gfx.SurfaceDesc) !Surface {
        return Surface{ .id = window.id };
    }

    pub fn requestAdapter(
        _: *Instance,
        _: *const Surface,
        comptime desc: gfx.AdapterDesc,
        adapter: *Adapter,
        user_data: ?*anyopaque,
    ) !void {
        const json = comptime stringifyAdapterDescComptime(desc);
        js.requestAdapter(main.wasm_id, json.ptr, json.len, adapter, user_data);
    }

    export fn requestAdapterComplete(
        adapter_id: js.AdapterId,
        adapter: *Adapter,
        user_data: ?*anyopaque,
    ) void {
        adapter.id = adapter_id;
        gfx.cbs.adapter_ready_cb(adapter, user_data);
    }
};

pub const Adapter = struct {
    id: js.AdapterId,

    pub fn destroy(adapter: *Adapter) void {
        js.destroyAdapter(adapter.id);
    }

    pub fn requestDevice(
        adapter: *Adapter,
        comptime desc: gfx.DeviceDesc,
        device: *Device,
        user_data: ?*anyopaque,
    ) !void {
        const json = comptime stringifyDeviceDescComptime(desc);
        js.requestDevice(main.wasm_id, adapter.id, json.ptr, json.len, device, user_data);
    }

    export fn requestDeviceComplete(
        device_id: js.DeviceId,
        device: *Device,
        user_data: ?*anyopaque,
    ) void {
        device.id = device_id;
        gfx.cbs.device_ready_cb(device, user_data);
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
            main.wasm_id,
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

    pub fn createShader(device: *Device, code: []const u8) !Shader {
        return Shader{ .id = js.createShader(main.wasm_id, device.id, code.ptr, code.len) };
    }

    pub fn checkShaderCompile(_: *Device, shader: *Shader) void {
        js.checkShaderCompile(main.wasm_id, shader.id);
    }

    pub fn createBindGroupLayout(
        device: *Device,
        comptime desc: gfx.BindGroupLayoutDesc,
    ) !BindGroupLayout {
        const json = comptime stringifyBindGroupLayoutDescComptime(desc);
        return BindGroupLayout{
            .id = js.createBindGroupLayout(main.wasm_id, device.id, json.ptr, json.len),
        };
    }

    pub fn createBindGroup(
        device: *Device,
        layout: *const BindGroupLayout,
        resources: []const gfx.BindGroupResource,
        comptime desc: gfx.BindGroupDesc,
    ) !BindGroup {
        var resource_types: [desc.entries.len]u32 = undefined;
        var resource_ids: [desc.entries.len]js.ObjectId = undefined;
        var buffer_offsets: [desc.entries.len]usize = undefined;
        var buffer_sizes: [desc.entries.len]usize = undefined;
        inline for (desc.entries) |entry, i| {
            resource_types[i] = @enumToInt(entry.resource_type);
            switch (entry.resource_type) {
                .buffer => {
                    resource_ids[i] = resources[i].buffer.resource.id;
                    buffer_offsets[i] = resources[i].buffer.offset;
                    buffer_sizes[i] = resources[i].buffer.size;
                },
                .sampler => {
                    resource_ids[i] = resources[i].sampler.id;
                },
                .texture_view => {
                    resource_ids[i] = resources[i].texture_view.id;
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
                main.wasm_id,
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
            .id = js.createPipelineLayout(main.wasm_id, device.id, bytes.ptr, bytes.len),
        };
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
                main.wasm_id,
                device.id,
                pipeline_layout.id,
                vert_shader.id,
                frag_shader.id,
                json.ptr,
                json.len,
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
        data: ?[]const u8,
        size: usize,
        comptime desc: gfx.BufferDesc,
    ) !Buffer {
        const init_data = if (data) |init_data| init_data else &[_]u8{};
        return Buffer{
            .id = js.createBuffer(
                main.wasm_id,
                device.id,
                std.mem.alignForward(size, 4),
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
                main.wasm_id,
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

export fn gfxError(error_code: u32) void {
    const err = switch (error_code) {
        0 => error.RequestAdapterFailed,
        1 => error.RequestDeviceFailed,
        2 => error.CreateShaderFailed,
        else => error.GfxError,
    };
    gfx.cbs.gfx_error_cb(err);
}

pub const Buffer = packed struct {
    id: js.BufferId,

    pub fn destroy(buffer: *Buffer) void {
        js.destroyBuffer(buffer.id);
    }
};

pub const Texture = packed struct {
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

pub const TextureView = packed struct {
    id: js.TextureViewId,

    pub fn destroy(view: *TextureView) void {
        js.destroyTextureView(view.id);
    }
};

pub const Sampler = packed struct {
    id: js.SamplerId,
};

pub const Shader = packed struct {
    id: js.ShaderId,

    pub fn destroy(shader: *Shader) void {
        js.destroyShader(shader.id);
    }
};

pub const Surface = packed struct {
    id: js.CanvasId,

    pub fn getPreferredFormat() gfx.TextureFormat {
        return .bgra8unorm;
    }

    pub fn destroy(_: *Surface) void {}
};

pub const Swapchain = packed struct {
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

pub const BindGroupLayout = packed struct {
    id: js.BindGroupLayoutId,

    pub fn destroy(bind_group_layout: *BindGroupLayout) void {
        js.destroyBindGroupLayout(bind_group_layout.id);
    }
};

pub const BindGroup = packed struct {
    id: js.BindGroupId,

    pub fn destroy(bind_group: *BindGroup) void {
        js.destroyBindGroup(bind_group.id);
    }
};

pub const PipelineLayout = packed struct {
    id: js.PipelineLayoutId,

    pub fn destroy(pipeline_layout: *PipelineLayout) void {
        js.destroyPipelineLayout(pipeline_layout.id);
    }
};

pub const RenderPipeline = packed struct {
    id: js.RenderPipelineId,

    pub fn destroy(render_pipeline: *RenderPipeline) void {
        js.destroyRenderPipeline(render_pipeline.id);
    }
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
        comptime index_format: gfx.IndexFormat,
        offset: usize,
        size: usize,
    ) void {
        js.setIndexBuffer(
            main.wasm_id,
            render_pass.id,
            buffer.id,
            @enumToInt(index_format),
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

pub const CommandEncoder = packed struct {
    id: js.CommandEncoderId,

    pub fn beginRenderPass(
        command_encoder: *CommandEncoder,
        args: gfx.RenderPassArgs,
        comptime desc: gfx.RenderPassDesc,
    ) RenderPass {
        const color_views_bytes = std.mem.sliceAsBytes(args.color_views);
        const color_resolve_targets_bytes = std.mem.sliceAsBytes(args.color_resolve_targets);
        const depth_stencil_view_id = if (args.depth_stencil_view) |depth_stencil_view|
            depth_stencil_view.id
        else
            js.invalid_id;
        const occlusion_query_set_id = if (args.occlusion_query_set) |occlusion_query_set|
            occlusion_query_set.id
        else
            js.invalid_id;
        const timestamp_query_set_ids = std.mem.sliceAsBytes(args.timestamp_query_sets);
        const json = comptime try stringifyRenderPassDescComptime(desc);

        var crc = std.hash.Fnv1a_32.init();
        crc.update(color_views_bytes);
        crc.update(color_resolve_targets_bytes);
        crc.update(std.mem.asBytes(&depth_stencil_view_id));
        crc.update(std.mem.asBytes(&occlusion_query_set_id));
        crc.update(timestamp_query_set_ids);
        crc.update(json);

        return RenderPass{
            .id = js.beginRenderPass(
                crc.final(),
                main.wasm_id,
                command_encoder.id,
                color_views_bytes.ptr,
                color_views_bytes.len,
                color_resolve_targets_bytes.ptr,
                color_resolve_targets_bytes.len,
                depth_stencil_view_id,
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

    pub fn submit(queue: *Queue, command_buffers: []const CommandBuffer) void {
        for (command_buffers) |command_buffer| {
            js.queueSubmit(main.wasm_id, queue.id, command_buffer.id);
        }
    }
};

fn stringifyAdapterDescComptime(comptime desc: gfx.AdapterDesc) []const u8 {
    const JsonDesc = struct {
        powerPreference: ?[]const u8 = null,
        forceFallbackAdapter: ?bool = null,
    };

    comptime var json: JsonDesc = .{};
    if (desc.power_preference != .@"undefined") {
        json.powerPreference = comptime getPowerPreferenceString(desc.power_preference);
    }
    if (desc.force_fallback_adapter) {
        json.forceFallbackAdapter = true;
    }

    return comptime try stringifyComptime(json);
}

fn stringifyDeviceDescComptime(comptime desc: gfx.DeviceDesc) []const u8 {
    const JsonLimits = struct {
        maxTextureDimension1D: ?js.GPUSize32 = null,
        maxTextureDimension2D: ?js.GPUSize32 = null,
        maxTextureDimension3D: ?js.GPUSize32 = null,
        maxTextureArrayLayers: ?js.GPUSize32 = null,
        maxBindGroups: ?js.GPUSize32 = null,
        maxDynamicUniformBuffersPerPipelineLayout: ?js.GPUSize32 = null,
        maxDynamicStorageBuffersPerPipelineLayout: ?js.GPUSize32 = null,
        maxSampledTexturesPerShaderStage: ?js.GPUSize32 = null,
        maxSamplersPerShaderStage: ?js.GPUSize32 = null,
        maxStorageBuffersPerShaderStage: ?js.GPUSize32 = null,
        maxStorageTexturesPerShaderStage: ?js.GPUSize32 = null,
        maxUniformBuffersPerShaderStage: ?js.GPUSize32 = null,
        maxUniformBufferBindingSize: ?js.GPUSize64 = null,
        maxStorageBufferBindingSize: ?js.GPUSize64 = null,
        minUniformBufferOffsetAlignment: ?js.GPUSize32 = null,
        minStorageBufferOffsetAlignment: ?js.GPUSize32 = null,
        maxVertexBuffers: ?js.GPUSize32 = null,
        maxVertexAttributes: ?js.GPUSize32 = null,
        maxVertexBufferArrayStride: ?js.GPUSize32 = null,
        maxInterStageShaderComponents: ?js.GPUSize32 = null,
        maxComputeWorkgroupStorageSize: ?js.GPUSize32 = null,
        maxComputeInvocationsPerWorkgroup: ?js.GPUSize32 = null,
        maxComputeWorkgroupSizeX: ?js.GPUSize32 = null,
        maxComputeWorkgroupSizeY: ?js.GPUSize32 = null,
        maxComputeWorkgroupSizeZ: ?js.GPUSize32 = null,
        maxComputeWorkgroupsPerDimension: ?js.GPUSize32 = null,
    };
    const JsonDesc = struct {
        requiredFeatures: ?[]const []const u8 = null,
        requiredLimits: ?JsonLimits = .{},
    };

    comptime var json: JsonDesc = .{};
    if (desc.required_features.len > 0) {
        comptime var required_features: []const []const u8 = &.{};
        inline for (desc.required_features) |required_feature| {
            required_features = required_features ++ &.{
                comptime getFeatureNameString(required_feature),
            };
        }
        json.requiredFeatures = required_features;
    }

    const default_limits: gfx.Limits = .{};
    comptime var all_default_limits = true;
    inline for (@typeInfo(gfx.Limits).Struct.fields) |field, i| {
        const limit = @field(desc.required_limits, field.name);
        if (limit != @field(default_limits, field.name)) {
            all_default_limits = false;
            const json_field_name = @typeInfo(JsonLimits).Struct.fields[i].name;
            @field(json.requiredLimits, json_field_name) = limit;
        }
    }

    if (all_default_limits) {
        json.requiredLimits = null;
    }

    return comptime try stringifyComptime(json);
}

fn stringifyBindGroupLayoutDescComptime(comptime desc: gfx.BindGroupLayoutDesc) []const u8 {
    const JsonBufferBindingLayout = struct {
        @"type": ?[]const u8 = null,
        hasDynamicOffset: ?bool = null,
        minBindingSize: ?js.GPUSize64 = null,
    };
    const JsonSamplerBindingLayout = struct {
        @"type": ?[]const u8 = null,
    };
    const JsonTextureBindingLayout = struct {
        sampleType: ?[]const u8 = null,
        viewDimension: ?[]const u8 = null,
        multisampled: ?bool = null,
    };
    const JsonStorageTextureBindingLayout = struct {
        format: []const u8 = "",
        access: ?[]const u8 = null,
        viewDimension: ?[]const u8 = null,
    };
    const JsonEntry = struct {
        binding: js.GPUIndex32,
        visibility: js.GPUShaderStageFlags,
        buffer: ?JsonBufferBindingLayout = null,
        sampler: ?JsonSamplerBindingLayout = null,
        texture: ?JsonTextureBindingLayout = null,
        storageTexture: ?JsonStorageTextureBindingLayout = null,
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
                comptime setIfNotDefault(
                    &json_buffer.@"type",
                    buffer,
                    "type",
                    getBufferBindingTypeString(buffer.@"type"),
                );
                comptime setIfNotDefault(
                    &json_buffer.hasDynamicOffset,
                    buffer,
                    "has_dynamic_offset",
                    buffer.has_dynamic_offset,
                );
                comptime setIfNotDefault(
                    &json_buffer.minBindingSize,
                    buffer,
                    "min_binding_size",
                    buffer.min_binding_size,
                );
                json_entry.buffer = json_buffer;
            },
            .sampler => |sampler| {
                comptime var json_sampler: JsonSamplerBindingLayout = .{};
                comptime setIfNotDefault(
                    &json_sampler.@"type",
                    sampler,
                    "type",
                    getSamplerBindingTypeString(sampler.@"type"),
                );
                json_entry.sampler = json_sampler;
            },
            .texture => |texture| {
                comptime var json_texture: JsonTextureBindingLayout = .{};
                comptime setIfNotDefault(
                    &json_texture.sampleType,
                    texture,
                    "sample_type",
                    getTextureSampleTypeString(texture.sample_type),
                );
                comptime setIfNotDefault(
                    &json_texture.viewDimension,
                    texture,
                    "view_dimension",
                    getTextureViewDimensionString(texture.view_dimension),
                );
                comptime setIfNotDefault(
                    &json_texture.multisampled,
                    texture,
                    "multisampled",
                    texture.multisampled,
                );
                json_entry.texture = json_texture;
            },
            .storage_texture => |storage_texture| {
                comptime var json_storage_texture: JsonStorageTextureBindingLayout = .{
                    .format = comptime getTextureFormatString(storage_texture.format),
                };
                comptime setIfNotDefault(
                    &json_storage_texture.access,
                    storage_texture,
                    "access",
                    getStorageTextureAccessString(storage_texture.access),
                );
                comptime setIfNotDefault(
                    &json_storage_texture.viewDimension,
                    storage_texture,
                    "view_dimension",
                    getTextureViewDimensionString(storage_texture.view_dimension),
                );
                json_entry.storageTexture = json_storage_texture;
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
        arrayStride: js.GPUSize64 = 0,
        stepMode: ?[]const u8 = null,
        attributes: []const JsonVertAttr = &.{},
    };
    const JsonVertState = struct {
        entryPoint: []const u8 = "",
        buffers: ?[]const JsonVertLayout = null,
    };
    const JsonPrimState = struct {
        topology: ?[]const u8 = null,
        stripIndexFormat: ?[]const u8 = null,
        frontFace: ?[]const u8 = null,
        cullMode: ?[]const u8 = null,
        unclippedDepth: ?bool = null,
    };
    const JsonStencilFaceState = struct {
        compare: ?[]const u8 = null,
        failOp: ?[]const u8 = null,
        depthFailOp: ?[]const u8 = null,
        passOp: ?[]const u8 = null,
    };
    const JsonDepthStencilState = struct {
        format: []const u8 = "",
        depthWriteEnabled: ?bool = null,
        depthCompare: ?[]const u8 = null,
        stencilFront: ?JsonStencilFaceState = null,
        stencilBack: ?JsonStencilFaceState = null,
        stencilReadMask: ?js.GPUStencilValue = null,
        stencilWriteMask: ?js.GPUStencilValue = null,
        depthBias: ?js.GPUDepthBias = null,
        depthBiasSlopeScale: ?f32 = null,
        depthBiasClamp: ?f32 = null,
    };
    const JsonMultiState = struct {
        count: ?js.GPUSize32 = null,
        mask: ?js.GPUSampleMask = null,
        alphaToCoverageEnabled: ?bool = null,
    };
    const JsonBlendComp = struct {
        operation: ?[]const u8 = null,
        srcFactor: ?[]const u8 = null,
        dstFactor: ?[]const u8 = null,
    };
    const JsonBlend = struct {
        color: JsonBlendComp = .{},
        alpha: JsonBlendComp = .{},
    };
    const JsonTarget = struct {
        format: []const u8 = "",
        blend: ?JsonBlend = null,
        writeMask: ?js.GPUColorWriteFlags = null,
    };
    const JsonFragState = struct {
        entryPoint: []const u8 = "",
        targets: []const JsonTarget = &.{},
    };
    const JsonDesc = struct {
        vertex: JsonVertState = .{},
        primitive: ?JsonPrimState = null,
        depthStencil: ?JsonDepthStencilState = null,
        multisample: ?JsonMultiState = null,
        fragment: ?JsonFragState = null,
    };

    comptime var json: JsonDesc = .{};
    json.vertex.entryPoint = desc.vertex.entry_point;
    if (desc.vertex.buffers.len > 0) {
        comptime var vert_buffers: []const JsonVertLayout = &.{};
        inline for (desc.vertex.buffers) |buffer| {
            comptime var json_buffer: JsonVertLayout = .{};
            json_buffer.arrayStride = buffer.array_stride;
            comptime setIfNotDefault(
                &json_buffer.stepMode,
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
        json.vertex.buffers = vert_buffers;
    }

    if (comptime hasNonDefaultFields(desc.primitive)) {
        comptime var json_primitive: JsonPrimState = .{};
        comptime setIfNotDefault(
            &json_primitive.topology,
            desc.primitive,
            "topology",
            getPrimitiveTopologyString(desc.primitive.topology),
        );
        comptime setIfNotDefault(
            &json_primitive.stripIndexFormat,
            desc.primitive,
            "strip_index_format",
            getIndexFormatString(desc.primitive.strip_index_format),
        );
        comptime setIfNotDefault(
            &json_primitive.frontFace,
            desc.primitive,
            "front_face",
            getFrontFaceString(desc.primitive.front_face),
        );
        comptime setIfNotDefault(
            &json_primitive.cullMode,
            desc.primitive,
            "cull_mode",
            getCullModeString(desc.primitive.cull_mode),
        );
        json.primitive = json_primitive;
    }

    if (desc.depth_stencil) |depth_stencil| {
        comptime var json_depth_stencil: JsonDepthStencilState = .{};
        json_depth_stencil.format = comptime getTextureFormatString(depth_stencil.format);
        comptime setIfNotDefault(
            &json_depth_stencil.depthWriteEnabled,
            depth_stencil,
            "depth_write_enabled",
            depth_stencil.depth_write_enabled,
        );
        comptime setIfNotDefault(
            &json_depth_stencil.depthCompare,
            depth_stencil,
            "depth_compare",
            getCompareFunctionString(depth_stencil.depth_compare),
        );

        if (comptime hasNonDefaultFields(depth_stencil.stencil_front)) {
            comptime var json_stencil_front: JsonStencilFaceState = .{};
            comptime setIfNotDefault(
                &json_stencil_front.compare,
                depth_stencil.stencil_front,
                "compare",
                getCompareFunctionString(depth_stencil.stencil_front.compare),
            );
            comptime setIfNotDefault(
                &json_stencil_front.failOp,
                depth_stencil.stencil_front,
                "fail_op",
                getStencilOperationString(depth_stencil.stencil_front.fail_op),
            );
            comptime setIfNotDefault(
                &json_stencil_front.depthFailOp,
                depth_stencil.stencil_front,
                "depth_fail_op",
                getStencilOperationString(depth_stencil.stencil_front.depth_fail_op),
            );
            comptime setIfNotDefault(
                &json_stencil_front.passOp,
                depth_stencil.stencil_front,
                "pass_op",
                getStencilOperationString(depth_stencil.stencil_front.pass_op),
            );
            json_depth_stencil.stencilFront = json_stencil_front;
        }

        if (comptime hasNonDefaultFields(depth_stencil.stencil_back)) {
            comptime var json_stencil_back: JsonStencilFaceState = .{};
            comptime setIfNotDefault(
                &json_stencil_back.compare,
                depth_stencil.stencil_back,
                "compare",
                getCompareFunctionString(depth_stencil.stencil_back.compare),
            );
            comptime setIfNotDefault(
                &json_stencil_back.failOp,
                depth_stencil.stencil_back,
                "fail_op",
                getStencilOperationString(depth_stencil.stencil_back.fail_op),
            );
            comptime setIfNotDefault(
                &json_stencil_back.depthFailOp,
                depth_stencil.stencil_back,
                "depth_fail_op",
                getStencilOperationString(depth_stencil.stencil_back.depth_fail_op),
            );
            comptime setIfNotDefault(
                &json_stencil_back.passOp,
                depth_stencil.stencil_back,
                "pass_op",
                getStencilOperationString(depth_stencil.stencil_back.pass_op),
            );
            json_depth_stencil.stencilBack = json_stencil_back;
        }

        comptime setIfNotDefault(
            &json_depth_stencil.stencilReadMask,
            depth_stencil,
            "stencil_read_mask",
            depth_stencil.stencil_read_mask,
        );

        comptime setIfNotDefault(
            &json_depth_stencil.stencilWriteMask,
            depth_stencil,
            "stencil_write_mask",
            depth_stencil.stencil_write_mask,
        );

        comptime setIfNotDefault(
            &json_depth_stencil.depthBias,
            depth_stencil,
            "depth_bias",
            depth_stencil.depth_bias,
        );

        comptime setIfNotDefault(
            &json_depth_stencil.depthBiasSlopeScale,
            depth_stencil,
            "depth_bias_slope_scale",
            depth_stencil.depth_bias_slope_scale,
        );

        comptime setIfNotDefault(
            &json_depth_stencil.depthBiasClamp,
            depth_stencil,
            "depth_bias_clamp",
            depth_stencil.depth_bias_clamp,
        );

        json.depthStencil = json_depth_stencil;
    }

    if (comptime hasNonDefaultFields(desc.multisample)) {
        comptime var json_multisample: JsonMultiState = .{};

        comptime setIfNotDefault(
            &json_multisample.count,
            desc.multisample,
            "count",
            desc.multisample.count,
        );

        comptime setIfNotDefault(
            &json_multisample.mask,
            desc.multisample,
            "mask",
            desc.multisample.mask,
        );

        comptime setIfNotDefault(
            &json_multisample.alphaToCoverageEnabled,
            desc.multisample,
            "alpha_to_coverage_enabled",
            desc.multisample.alpha_to_coverage_enabled,
        );

        json.multisample = json_multisample;
    }

    if (desc.fragment) |fragment| {
        comptime var json_fragment: JsonFragState = .{};
        json_fragment.entryPoint = fragment.entry_point;
        inline for (fragment.targets) |target| {
            comptime var json_target: JsonTarget = .{};
            json_target.format = comptime getTextureFormatString(target.format);
            if (target.blend) |blend| {
                comptime var json_blend: JsonBlend = .{};
                comptime setIfNotDefault(
                    &json_blend.color.operation,
                    blend.color,
                    "operation",
                    getBlendOperationString(blend.color.operation),
                );
                comptime setIfNotDefault(
                    &json_blend.color.srcFactor,
                    blend.color,
                    "src_factor",
                    getBlendFactorString(blend.color.src_factor),
                );
                comptime setIfNotDefault(
                    &json_blend.color.dstFactor,
                    blend.color,
                    "dst_factor",
                    getBlendFactorString(blend.color.dst_factor),
                );
                comptime setIfNotDefault(
                    &json_blend.alpha.operation,
                    blend.alpha,
                    "operation",
                    getBlendOperationString(blend.alpha.operation),
                );
                comptime setIfNotDefault(
                    &json_blend.alpha.srcFactor,
                    blend.alpha,
                    "src_factor",
                    getBlendFactorString(blend.alpha.src_factor),
                );
                comptime setIfNotDefault(
                    &json_blend.alpha.dstFactor,
                    blend.alpha,
                    "dst_factor",
                    getBlendFactorString(blend.alpha.dst_factor),
                );
                json_target.blend = json_blend;
            }
            comptime setIfNotDefault(
                &json_target.writeMask,
                target,
                "write_mask",
                getColorWriteFlags(target.write_mask),
            );
            json_fragment.targets = json_fragment.targets ++ &[_]JsonTarget{json_target};
        }
        json.fragment = json_fragment;
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
        depthLoadValue: JsonDepthLoadValue,
        depthStoreOp: []const u8,
        depthReadOnly: ?bool = null,
        stencilLoadValue: JsonStencilLoadValue,
        stencilStoreOp: []const u8,
        stencilReadOnly: ?bool = null,
    };
    const JsonTimestampWrite = struct {
        queryIndex: js.GPUSize32,
        location: []const u8,
    };
    const JsonDesc = struct {
        colorAttachments: []const JsonColorAttachment = &.{},
        depthStencilAttachment: ?JsonDepthStencilAttachment = null,
        timestampWrites: ?[]const JsonTimestampWrite = null,
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
        };

        comptime setIfNotDefault(
            &json.depthStencilAttachment.?.depthReadOnly,
            depth_stencil_attachment,
            "depth_read_only",
            depth_stencil_attachment.depth_read_only,
        );
        comptime setIfNotDefault(
            &json.depthStencilAttachment.?.stencilReadOnly,
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
        json.timestampWrites = json_timestamp_writes;
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
            .emit_null_optional_fields = false,
        },
        buffer_stream.writer(),
    );
    return &[_]u8{} ++ json[0..buffer_stream.write_index];
}

fn setIfNotDefault(
    optional: anytype,
    check: anytype,
    comptime check_field_name: []const u8,
    value: anytype,
) void {
    inline for (@typeInfo(@TypeOf(check)).Struct.fields) |field| {
        if (std.mem.eql(u8, field.name, check_field_name) and
            !std.meta.eql(field.default_value.?, @field(check, check_field_name)))
        {
            optional.* = value;
            break;
        }
    }
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
