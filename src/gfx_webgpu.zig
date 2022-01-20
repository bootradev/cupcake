const app = @import("app.zig");
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
    ) void;
    extern fn destroyAdapter(adapter_id: AdapterId) void;
    extern fn requestDevice(
        wasm_id: main.WasmId,
        adapter_id: AdapterId,
        json_ptr: [*]const u8,
        json_len: usize,
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
    pub fn init() !Instance {
        return Instance{};
    }
    pub fn deinit(_: *Instance) void {}

    pub fn createSurface(
        _: *Instance,
        window: *app.Window,
        comptime _: gfx.SurfaceDesc,
    ) !Surface {
        return Surface{ .id = window.id };
    }

    var request_adapter_frame: anyframe = undefined;
    var request_adapter_id: anyerror!js.AdapterId = undefined;

    pub fn requestAdapter(
        _: *Instance,
        surface: *const Surface,
        comptime desc: gfx.AdapterDesc,
    ) !Adapter {
        _ = surface;
        const json = try stringifyDescComptime(desc);
        return try await async requestAdapterAsync(json);
    }

    fn requestAdapterAsync(json: []const u8) !Adapter {
        js.requestAdapter(main.wasm_id, json.ptr, json.len);
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
        comptime desc: gfx.DeviceDesc,
    ) !Device {
        const json = try stringifyDescComptime(desc);
        return try await async requestDeviceAsync(adapter, json);
    }

    fn requestDeviceAsync(adapter: *Adapter, json: []const u8) !Device {
        js.requestDevice(main.wasm_id, adapter.id, json.ptr, json.len);
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
        size: math.V2u32,
        comptime desc: gfx.SwapchainDesc,
    ) !Swapchain {
        const swapchain = Swapchain{ .id = js.createContext(surface.id) };
        const texture_format = comptime getEnumNameJs(desc.format);
        const texture_usage = comptime getEnumFlagsJs(desc.usage);
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
        const shader = Shader{
            .id = js.createShader(main.wasm_id, device.id, code.ptr, code.len),
        };
        if (cfg.opt_level != .release) {
            try device.checkShaderCompile(&shader);
        }
        return shader;
    }

    var shader_compile_frame: anyframe = undefined;
    var shader_compile_result: anyerror!void = undefined;

    pub fn checkShaderCompile(_: *Device, shader: *const Shader) !void {
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
        comptime desc: gfx.BindGroupLayoutDesc,
    ) !BindGroupLayout {
        const json = try stringifyDescComptime(desc);
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

        const json = try stringifyDescComptime(desc);
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
        const json = try stringifyDescComptime(desc);
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
                comptime getEnumFlagsJs(desc.usage),
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
        const dimension = comptime getEnumNameJs(desc.dimension);
        const format = comptime getEnumNameJs(desc.format);
        return Texture{
            .id = js.createTexture(
                main.wasm_id,
                device.id,
                comptime getEnumFlagsJs(desc.usage),
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
        const index_format_name = comptime getEnumNameJs(index_format);
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
        const json = try stringifyDescComptime(desc);

        return RenderPass{
            .id = js.beginRenderPass(
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

fn stringifyDescComptime(comptime desc: anytype) ![]const u8 {
    @setEvalBranchQuota(100000);
    const JsonDescType = comptime initJsonDescType(@TypeOf(desc));
    const json = comptime initJsonDesc(JsonDescType, desc);
    return comptime try stringifyComptime(json);
}

fn initJsonDescType(comptime DescType: type) type {
    comptime var json_info = @typeInfo(DescType);
    switch (json_info) {
        .Int, .Float, .Bool => {},
        .Enum => {
            json_info = @typeInfo([]const u8);
        },
        .Pointer => |P| {
            json_info.Pointer.child = initJsonDescType(P.child);
        },
        .Array => |A| {
            json_info.Array.child = initJsonDescType(A.child);
        },
        .Optional => |O| {
            json_info.Optional.child = initJsonDescType(O.child);
        },
        .Union => |U| {
            comptime var json_fields: []const std.builtin.TypeInfo.UnionField = &.{};
            inline for (U.fields) |desc_field| {
                comptime var json_field = desc_field;
                json_field.field_type = initJsonDescType(desc_field.field_type);
                json_fields = json_fields ++ [_]std.builtin.TypeInfo.UnionField{json_field};
            }

            json_info.Union.fields = json_fields;
        },
        .Struct => |S| {
            if (S.layout == .Packed) {
                json_info = @typeInfo(u32);
            } else {
                comptime var json_fields: []const std.builtin.TypeInfo.StructField = &.{};
                inline for (S.fields) |desc_field| {
                    comptime var json_field = desc_field;
                    json_field.name = snakeCaseToCamelCase(desc_field.name);
                    json_field.field_type = initJsonDescType(desc_field.field_type);
                    const json_field_tag = std.meta.activeTag(@typeInfo(json_field.field_type));
                    if (json_field_tag != .Optional and desc_field.default_value != null) {
                        json_field.field_type = @Type(std.builtin.TypeInfo{
                            .Optional = .{ .child = json_field.field_type },
                        });
                    }
                    json_field.default_value = null;
                    json_fields = json_fields ++ [_]std.builtin.TypeInfo.StructField{json_field};
                }
                json_info.Struct.fields = json_fields;
            }
        },
        else => |T| {
            const name = @tagName(std.meta.activeTag(T));
            @compileError("Unsupported field type (" ++ name ++ ") for JSON desc type!");
        },
    }

    return @Type(json_info);
}

fn initJsonDesc(comptime JsonType: type, comptime desc: anytype) JsonType {
    comptime var json_desc: JsonType = undefined;
    inline for (@typeInfo(@TypeOf(desc)).Struct.fields) |desc_field, i| {
        comptime var json_field = @typeInfo(JsonType).Struct.fields[i];
        if (std.meta.activeTag(@typeInfo(json_field.field_type)) == .Optional and
            std.meta.eql(desc_field.default_value.?, @field(desc, desc_field.name)))
        {
            @field(json_desc, json_field.name) = null;
        } else {
            @field(json_desc, json_field.name) = initJsonDescField(
                json_field.field_type,
                @field(desc, desc_field.name),
            );
        }
    }

    return json_desc;
}

fn initJsonDescField(comptime JsonFieldType: type, comptime desc_field: anytype) JsonFieldType {
    const json_field_info = @typeInfo(JsonFieldType);
    const JsonFieldOptionalType = if (std.meta.activeTag(json_field_info) == .Optional)
        json_field_info.Optional.child
    else
        JsonFieldType;

    return switch (@typeInfo(@TypeOf(desc_field))) {
        .Int, .Float, .Bool => desc_field,
        .Enum => comptime getEnumNameJs(desc_field),
        .Pointer => |P| block: {
            const JsonFieldOptionalTypeChild = @typeInfo(JsonFieldOptionalType).Pointer.child;
            comptime var json_desc_field: JsonFieldOptionalType = undefined;
            switch (P.size) {
                .Slice => {
                    json_desc_field = &.{};
                    for (desc_field) |desc_field_elem| {
                        json_desc_field = json_desc_field ++ &[_]JsonFieldOptionalTypeChild{
                            initJsonDescField(JsonFieldOptionalTypeChild, desc_field_elem),
                        };
                    }
                },
                else => @compileError("Unsupported pointer size for JSON desc!"),
            }
            break :block json_desc_field;
        },
        .Array => block: {
            const JsonFieldOptionalTypeChild = @typeInfo(JsonFieldOptionalType).Array.child;
            comptime var json_desc_field: JsonFieldOptionalType = undefined;
            for (desc_field) |desc_field_elem, i| {
                json_desc_field[i] = initJsonDescField(JsonFieldOptionalTypeChild, desc_field_elem);
            }
            break :block json_desc_field;
        },
        .Optional => initJsonDescField(JsonFieldOptionalType, desc_field.?),
        .Union => block: {
            const field_name = @tagName(std.meta.activeTag(desc_field));
            inline for (json_field_info.Union.fields) |field| {
                if (std.mem.eql(u8, field.name, field_name)) {
                    break :block @unionInit(
                        JsonFieldOptionalType,
                        field_name,
                        initJsonDescField(field.field_type, @field(desc_field, field_name)),
                    );
                }
            }
        },
        .Struct => |S| block: {
            if (S.layout == .Packed) {
                break :block comptime getEnumFlagsJs(desc_field);
            } else {
                break :block initJsonDesc(JsonFieldOptionalType, desc_field);
            }
        },
        else => |T| {
            const name = @tagName(std.meta.activeTag(T));
            @compileError("Unsupported field type (" ++ name ++ ") for JSON desc!");
        },
    };
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
    try std.json.stringify(
        value,
        .{
            .emit_null_optional_fields = false,
        },
        buffer_stream.writer(),
    );
    return &[_]u8{} ++ json[0..buffer_stream.write_index];
}

fn testStringifyDescComptime(comptime desc: anytype, comptime expected: []const u8) !void {
    try std.testing.expectEqualStrings(
        "{" ++ expected ++ "}",
        try stringifyDescComptime(desc),
    );
}

test "stringifyAdapterDescComptime" {
    comptime var str: []const u8 = "";
    comptime var adapter_desc = gfx.AdapterDesc{};
    try testStringifyDescComptime(adapter_desc, str);

    adapter_desc.power_preference = .low_power;
    str = str ++ "\"powerPreference\":\"low-power\"";
    try testStringifyDescComptime(adapter_desc, str);

    adapter_desc.force_fallback_adapter = true;
    str = str ++ ",\"forceFallbackAdapter\":true";
    try testStringifyDescComptime(adapter_desc, str);
}

test "stringifyDeviceDescComptime" {
    comptime var str: []const u8 = "";
    comptime var device_desc = gfx.DeviceDesc{};
    try testStringifyDescComptime(device_desc, str);

    device_desc.label = "hello";
    str = str ++ "\"label\":\"hello\"";
    try testStringifyDescComptime(device_desc, str);

    device_desc.required_features = &.{.timestamp_query};
    str = str ++ ",\"requiredFeatures\":[\"timestamp-query\"]";
    try testStringifyDescComptime(device_desc, str);

    device_desc.required_limits = .{ .max_vertex_buffers = 4 };
    str = str ++ ",\"requiredLimits\":{\"maxVertexBuffers\":4}";
    try testStringifyDescComptime(device_desc, str);
}

test "stringifyBindGroupLayoutDescComptime" {
    const entries: []const gfx.BindGroupLayoutEntry = &.{
        .{ .binding = 0, .visibility = .{ .vertex = true }, .sampler = .{} },
    };
    const str = "\"entries\":[{\"binding\":0,\"visibility\":1,\"sampler\":{}}]";

    const bind_group_layout_desc = gfx.BindGroupLayoutDesc{ .entries = entries };
    try testStringifyDescComptime(bind_group_layout_desc, str);
}

test "stringifyBindGroupDescComptime" {
    const entries: []const gfx.BindGroupEntry = &.{
        .{ .binding = 2, .resource_type = .texture_view },
    };
    const str = "\"entries\":[{\"binding\":2,\"resourceType\":\"texture-view\"}]";

    const bind_group_desc = gfx.BindGroupDesc{ .entries = entries };
    try testStringifyDescComptime(bind_group_desc, str);
}

test "stringifyRenderPipelineDescComptime" {
    const render_pipeline_desc: gfx.RenderPipelineDesc = .{
        .vertex = .{
            .entry_point = "main",
            .buffers = &.{
                .{
                    .array_stride = 8,
                    .attributes = &.{.{ .format = .uint8x4, .offset = 2, .shader_location = 1 }},
                },
            },
        },
        .primitive = .{
            .topology = .line_list,
            .strip_index_format = .uint16,
            .front_face = .cw,
            .cull_mode = .back,
        },
        .depth_stencil = .{
            .format = .r8unorm,
            .depth_write_enabled = true,
            .depth_compare = .never,
            .stencil_front = .{
                .compare = .greater,
                .fail_op = .zero,
                .depth_fail_op = .increment_wrap,
                .pass_op = .invert,
            },
            .stencil_read_mask = 0,
        },
        .multisample = .{
            .count = 2,
            .mask = 0,
            .alpha_to_coverage_enabled = true,
        },
        .fragment = .{
            .entry_point = "main",
            .targets = &.{
                .{
                    .format = .rg8unorm,
                    .blend = .{
                        .color = .{
                            .operation = .min,
                            .src_factor = .dst,
                            .dst_factor = .dst_alpha,
                        },
                    },
                    .write_mask = .{
                        .red = true,
                        .green = true,
                        .blue = false,
                        .alpha = false,
                    },
                },
            },
        },
    };

    comptime var str: []const u8 = &.{};
    str = str ++ "\"vertex\":{\"entryPoint\":\"main\",\"buffers\":[{\"arrayStride\":8";
    str = str ++ ",\"attributes\":[{\"format\":\"uint8x4\",\"offset\":2,\"shaderLocation\":1}]}]}";
    str = str ++ ",\"primitive\":{\"topology\":\"line-list\",\"stripIndexFormat\":\"uint16\"";
    str = str ++ ",\"frontFace\":\"cw\",\"cullMode\":\"back\"}";
    str = str ++ ",\"depthStencil\":{\"format\":\"r8unorm\",\"depthWriteEnabled\":true";
    str = str ++ ",\"depthCompare\":\"never\",\"stencilFront\":{\"compare\":\"greater\"";
    str = str ++ ",\"failOp\":\"zero\",\"depthFailOp\":\"increment-wrap\",\"passOp\":\"invert\"}";
    str = str ++ ",\"stencilReadMask\":0}";
    str = str ++ ",\"multisample\":{\"count\":2,\"mask\":0,\"alphaToCoverageEnabled\":true}";
    str = str ++ ",\"fragment\":{\"entryPoint\":\"main\",\"targets\":[{\"format\":\"rg8unorm\"";
    str = str ++ ",\"blend\":{\"color\":{\"operation\":\"min\",\"srcFactor\":\"dst\"";
    str = str ++ ",\"dstFactor\":\"dst-alpha\"}},\"writeMask\":3}]}";
    try testStringifyDescComptime(render_pipeline_desc, str);
}

test "stringifyRenderPassDescComptime" {
    const render_pass_desc: gfx.RenderPassDesc = .{
        .color_attachments = &.{
            .{
                .load_value = .{ .load = .load },
                .store_op = .store,
            },
        },
        .depth_stencil_attachment = .{
            .depth_load_value = .{ .clear = 0.0 },
            .depth_store_op = .discard,
            .depth_read_only = true,
            .stencil_load_value = .{ .clear = 1 },
            .stencil_store_op = .store,
        },
        .timestamp_writes = &.{
            .{
                .query_index = 2,
                .location = .end,
            },
        },
    };

    comptime var str: []const u8 = "";
    str = str ++ "\"colorAttachments\":[{\"loadValue\":\"load\",\"storeOp\":\"store\"}]";
    str = str ++ ",\"depthStencilAttachment\":{\"depthLoadValue\":0.0e+00";
    str = str ++ ",\"depthStoreOp\":\"discard\",\"depthReadOnly\":true";
    str = str ++ ",\"stencilLoadValue\":1,\"stencilStoreOp\":\"store\"}";
    str = str ++ ",\"timestampWrites\":[{\"queryIndex\":2,\"location\":\"end\"}]";
    try testStringifyDescComptime(render_pass_desc, str);
}

fn getEnumNameJs(comptime value: anytype) []const u8 {
    const string = @tagName(value);
    comptime var buf: [string.len]u8 = undefined;
    _ = std.mem.replace(u8, string, "_", "-", buf[0..]);
    return buf[0..];
}

test "getEnumNameJs" {
    const EnumTest = enum {
        nounderscore,
        has_underscore,
    };
    try std.testing.expectEqualStrings(
        "nounderscore",
        comptime getEnumNameJs(EnumTest.nounderscore),
    );
    try std.testing.expectEqualStrings(
        "has-underscore",
        comptime getEnumNameJs(EnumTest.has_underscore),
    );
}

fn getEnumFlagsJs(comptime value: anytype) js.GPUFlagsConstant {
    comptime var flags: js.GPUFlagsConstant = 0;
    inline for (@typeInfo(@TypeOf(value)).Struct.fields) |field, i| {
        if (@field(value, field.name)) {
            flags |= 1 << i;
        }
    }
    return flags;
}

test "getEnumFlagsJs" {
    const EnumTest = packed struct {
        a: bool,
        b: bool,
        c: bool,
    };
    try std.testing.expectEqual(
        0,
        comptime getEnumFlagsJs(EnumTest{ .a = false, .b = false, .c = false }),
    );
    try std.testing.expectEqual(
        1,
        comptime getEnumFlagsJs(EnumTest{ .a = true, .b = false, .c = false }),
    );
    try std.testing.expectEqual(
        6,
        comptime getEnumFlagsJs(EnumTest{ .a = false, .b = true, .c = true }),
    );
}

fn snakeCaseToCamelCase(comptime string: []const u8) []const u8 {
    comptime var buf: [string.len]u8 = undefined;
    comptime var write_index = 0;
    comptime var write_upper = false;
    inline for (string) |byte| {
        if (byte == '_') {
            write_upper = true;
        } else {
            if (write_upper) {
                buf[write_index] = std.ascii.toUpper(byte);
                write_upper = false;
            } else {
                buf[write_index] = byte;
            }
            write_index += 1;
        }
    }
    return &[_]u8{} ++ buf[0..write_index];
}

test "snakeCaseToCamelCase" {
    try std.testing.expectEqualStrings(
        "nounderscore",
        comptime snakeCaseToCamelCase("nounderscore"),
    );
    try std.testing.expectEqualStrings(
        "hasUnderscore",
        comptime snakeCaseToCamelCase("has_underscore"),
    );
}
