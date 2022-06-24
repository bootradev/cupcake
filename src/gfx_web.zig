const gfx = @import("gfx.zig");
const std = @import("std");

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = usize;
    const GPUIndex32 = u32;
    const GPUSignedOffset32 = i32;
    const GPUIntegerCoordinate = u32;

    const ObjectId = u32;
    const DescId = ObjectId;
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

    extern fn initDesc() DescId;
    extern fn deinitDesc(desc_id: DescId) void;
    extern fn setDescField(desc_id: DescId, field_ptr: [*]const u8, field_len: usize) void;
    extern fn setDescString(desc_id: DescId, value_ptr: [*]const u8, value_len: usize) void;
    extern fn setDescBool(desc_id: DescId, value: bool) void;
    extern fn setDescU32(desc_id: DescId, value: u32) void;
    extern fn setDescI32(desc_id: DescId, value: i32) void;
    extern fn setDescF32(desc_id: DescId, value: f32) void;
    extern fn beginDescArray(desc_id: DescId) void;
    extern fn endDescArray(desc_id: DescId) void;
    extern fn beginDescChild(desc_id: DescId) void;
    extern fn endDescChild(desc_id: DescId) void;

    extern fn createContext(canvas_id_ptr: [*]const u8, canvas_id_len: usize) ContextId;
    extern fn destroyContext(context_id: ContextId) void;
    extern fn getContextCurrentTexture(context_id: ContextId) TextureId;
    extern fn configure(device_id: DeviceId, context_id: ContextId, desc_id: DescId) void;
    extern fn getPreferredFormat() usize;

    extern fn requestAdapter(desc_id: DescId) void;
    extern fn destroyAdapter(adapter_id: AdapterId) void;

    extern fn requestDevice(adapter_id: AdapterId, desc_id: DescId) void;
    extern fn destroyDevice(device_id: DeviceId) void;

    extern fn createShader(device_id: DeviceId, code_ptr: [*]const u8, code_len: usize) ShaderId;
    extern fn destroyShader(shader_id: ShaderId) void;
    extern fn checkShaderCompile(shader_id: ShaderId) void;

    extern fn createBuffer(
        device_id: DeviceId,
        desc_id: DescId,
        init_data_ptr: [*]const u8,
        init_data_len: usize,
    ) BufferId;
    extern fn destroyBuffer(buffer_id: BufferId) void;

    extern fn createTexture(device_id: DeviceId, desc_id: DescId) TextureId;
    extern fn destroyTexture(texture_id: TextureId) void;
    extern fn createTextureView(desc_id: DescId) TextureViewId;
    extern fn destroyTextureView(texture_view_id: TextureViewId) void;

    extern fn createSampler(device_id: DeviceId, desc_id: DescId) SamplerId;
    extern fn destroySampler(sampler_id: SamplerId) void;

    extern fn createBindGroupLayout(device_id: DeviceId, desc_id: DescId) BindGroupLayoutId;
    extern fn destroyBindGroupLayout(bind_group_layout_id: BindGroupLayoutId) void;
    extern fn createBindGroup(device_id: DeviceId, desc_id: DescId) BindGroupId;
    extern fn destroyBindGroup(bind_group_id: BindGroupId) void;

    extern fn createPipelineLayout(device_id: DeviceId, desc_id: DescId) PipelineLayoutId;
    extern fn destroyPipelineLayout(pipeline_layout_id: PipelineLayoutId) void;
    extern fn createRenderPipeline(device_id: DeviceId, desc_id: DescId) RenderPipelineId;
    extern fn destroyRenderPipeline(render_pipeline_id: RenderPipelineId) void;

    extern fn createCommandEncoder(device_id: DeviceId) CommandEncoderId;
    extern fn finishCommandEncoder(command_encoder_id: CommandEncoderId) CommandBufferId;

    extern fn beginRenderPass(command_encoder_id: CommandEncoderId, desc_id: DescId) RenderPassId;
    extern fn setPipeline(render_pass_id: RenderPassId, render_pipeline_id: RenderPipelineId) void;
    extern fn setBindGroup(
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

    extern fn queueSubmit(device_id: DeviceId, command_buffer_id: CommandBufferId) void;
    extern fn queueWriteBuffer(
        device_id: DeviceId,
        buffer_id: BufferId,
        buffer_offset: GPUSize64,
        data_ptr: [*]const u8,
        data_len: usize,
        data_offset: GPUSize64,
    ) void;
    extern fn queueWriteTexture(
        device_id: DeviceId,
        destination_id: DescId,
        data_ptr: [*]const u8,
        data_len: usize,
        data_layout_id: DescId,
        size_width: GPUIntegerCoordinate,
        size_height: GPUIntegerCoordinate,
        size_depth_or_array_layers: GPUIntegerCoordinate,
    ) void;
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

fn getFieldName(comptime name: []const u8) []const u8 {
    comptime var field_name: []const u8 = &.{};
    comptime var next_upper = false;
    inline for (name) |char| {
        if (char == '_') {
            next_upper = true;
            continue;
        }
        field_name = field_name ++ &[_]u8{if (next_upper) std.ascii.toUpper(char) else char};
        next_upper = false;
    }
    return field_name;
}

fn setDescField(desc_id: js.DescId, field: []const u8) void {
    js.setDescField(desc_id, field.ptr, field.len);
}

fn setDescValue(desc_id: js.DescId, value: anytype) void {
    switch (@typeInfo(@TypeOf(value))) {
        .Bool => js.setDescBool(desc_id, value),
        .Int => |I| {
            if (I.bits != 32) {
                @compileError("Desc ints must be 32 bits!");
            }
            switch (I.signedness) {
                .signed => js.setDescI32(desc_id, value),
                .unsigned => js.setDescU32(desc_id, value),
            }
        },
        .Float => |F| {
            if (F.bits != 32) {
                @compileError("Desc floats must be 32 bits!");
            }
            js.setDescF32(desc_id, value);
        },
        .Enum => {
            const enum_name = getEnumName(value);
            js.setDescString(desc_id, enum_name.ptr, enum_name.len);
        },
        .Optional => {
            if (value) |v| {
                setDescValue(desc_id, v);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    setDescValue(desc_id, value.*);
                },
                .Slice => {
                    if (P.child == u8) {
                        js.setDescString(desc_id, value.ptr, value.len);
                    } else {
                        js.beginDescArray(desc_id);
                        for (value) |v| {
                            setDescValue(desc_id, v);
                        }
                        js.endDescArray(desc_id);
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
                js.setDescU32(desc_id, @intCast(u32, @bitCast(BitType, value)));
            } else if (typeIsArrayDesc(@TypeOf(value))) {
                js.beginDescArray(desc_id);
                inline for (S.fields) |field| {
                    setDescValue(desc_id, @field(value, field.name));
                }
                js.endDescArray(desc_id);
            } else if (S.fields.len == 1 and @hasField(@TypeOf(value), "impl")) {
                setDescValue(desc_id, value.impl.id);
            } else {
                js.beginDescChild(desc_id);
                inline for (S.fields) |field| {
                    const field_name = comptime getFieldName(field.name);
                    setDescFieldValue(desc_id, field_name, @field(value, field.name));
                }
                js.endDescChild(desc_id);
            }
        },
        .Union => |U| {
            inline for (U.fields) |field, i| {
                const Tag = U.tag_type orelse @compileError("Desc union must be tagged!");
                const tag = std.meta.activeTag(value);
                const type_name = @typeName(@TypeOf(value)) ++ "Type";
                if (@field(Tag, field.name) == tag) {
                    setDescValue(desc_id, @field(value, field.name));
                    setDescFieldValue(desc_id, type_name, @as(u32, i));
                    break;
                }
            }
        },
        else => @compileError("Invalid desc type!"),
    }
}

fn typeIsArrayDesc(comptime Type: type) bool {
    return Type == gfx.Extent3d or Type == gfx.Origin3d or Type == gfx.Color;
}

fn setDescFieldValue(desc_id: js.DescId, field: []const u8, value: anytype) void {
    setDescField(desc_id, field);
    setDescValue(desc_id, value);
}

fn setDesc(desc_id: js.DescId, desc: anytype) void {
    inline for (@typeInfo(@TypeOf(desc)).Struct.fields) |field| {
        const field_name = comptime getFieldName(field.name);
        setDescFieldValue(desc_id, field_name, @field(desc, field.name));
    }
}

pub const Instance = struct {
    pub fn init() !Instance {
        return Instance{};
    }

    pub fn deinit(_: *Instance) void {}

    pub fn initSurface(_: *Instance, desc: gfx.SurfaceDesc) !Surface {
        return Surface{
            .context_id = js.createContext(
                desc.window_info.canvas_id.ptr,
                desc.window_info.canvas_id.len,
            ),
        };
    }

    pub fn deinitSurface(_: *Instance, _: *Surface) void {}

    pub fn initAdapter(_: *Instance, desc: gfx.AdapterDesc) !Adapter {
        return try await async requestAdapterAsync(desc);
    }

    pub fn deinitAdapter(_: *Instance, adapter: *Adapter) void {
        js.destroyAdapter(adapter.id);
    }

    var request_adapter_frame: anyframe = undefined;
    var request_adapter_id: anyerror!js.AdapterId = undefined;

    fn requestAdapterAsync(desc: gfx.AdapterDesc) !Adapter {
        defer js.deinitDesc(desc.impl.id);
        js.requestAdapter(desc.impl.id);
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

pub const Surface = struct {
    context_id: js.ContextId,

    pub fn getPreferredFormat(_: Surface) !gfx.TextureFormat {
        const format = js.getPreferredFormat();
        return @intToEnum(gfx.TextureFormat, format);
    }
};

pub const AdapterDesc = struct {
    id: js.DescId = js.default_desc_id,

    pub fn setPowerPreference(desc: *AdapterDesc, power_preference: gfx.PowerPreference) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "powerPreference", power_preference);
    }

    pub fn setForceFallbackAdapter(desc: *AdapterDesc, force_fallback_adapter: bool) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "forceFallbackAdapter", force_fallback_adapter);
    }
};

pub const Adapter = struct {
    id: js.AdapterId,

    pub fn initDevice(adapter: *Adapter, desc: gfx.DeviceDesc) !Device {
        return try await async adapter.requestDeviceAsync(desc);
    }

    pub fn deinitDevice(_: *Adapter, device: *Device) void {
        js.destroyDevice(device.id);
    }

    var request_device_frame: anyframe = undefined;
    var request_device_id: anyerror!js.DeviceId = undefined;

    fn requestDeviceAsync(adapter: *Adapter, desc: gfx.DeviceDesc) !Device {
        defer js.deinitDesc(desc.impl.id);
        js.requestDevice(adapter.id, desc.impl.id);
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

pub const DeviceDesc = struct {
    id: js.DescId = js.default_desc_id,

    pub fn setRequiredFeatures(
        desc: *DeviceDesc,
        required_features: []const gfx.FeatureName,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "requiredFeatures", required_features);
    }

    pub fn setRequiredLimits(desc: *DeviceDesc, required_limits: gfx.Limits) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "requiredLimits", required_limits);
    }
};

pub const Device = struct {
    id: js.AdapterId,

    pub fn initSwapchain(
        device: *Device,
        surface: *Surface,
        desc: gfx.SwapchainDesc,
    ) !Swapchain {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);
        setDescFieldValue(js_desc, "compositingAlphaMode", @as([]const u8, "opaque"));

        const swapchain = Swapchain{ .id = surface.context_id, .view_desc = js.initDesc() };
        js.configure(device.id, swapchain.id, js_desc);
        return swapchain;
    }

    pub fn deinitSwapchain(_: *Device, swapchain: *Swapchain) void {
        js.deinitDesc(swapchain.view_desc);
        js.destroyContext(swapchain.id);
    }

    pub fn initShader(device: *Device, desc: gfx.ShaderDesc) !Shader {
        const shader = Shader{
            .id = js.createShader(device.id, desc.bytes.ptr, desc.bytes.len),
        };
        return shader;
    }

    pub fn deinitShader(_: *Device, shader: *Shader) void {
        js.destroyShader(shader.id);
    }

    pub fn initBuffer(device: *Device, desc: gfx.BufferDesc) !Buffer {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        const data = desc.data orelse &[_]u8{};
        return Buffer{
            .id = js.createBuffer(device.id, js_desc, data.ptr, data.len),
        };
    }

    pub fn deinitBuffer(_: *Device, buffer: *Buffer) void {
        js.destroyBuffer(buffer.id);
    }

    pub fn initTexture(device: *Device, desc: gfx.TextureDesc, usage: gfx.TextureUsage) !Texture {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);
        setDescFieldValue(js_desc, "usage", usage);

        return Texture{ .id = js.createTexture(device.id, js_desc) };
    }

    pub fn deinitTexture(_: *Device, texture: *Texture) void {
        js.destroyTexture(texture.id);
    }

    pub fn initTextureView(_: *Device, desc: gfx.TextureViewDesc) !TextureView {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        return TextureView{ .id = js.createTextureView(js_desc) };
    }

    pub fn deinitTextureView(_: *Device, texture_view: *TextureView) void {
        js.destroyTextureView(texture_view.id);
    }

    pub fn initSampler(device: *Device, desc: gfx.SamplerDesc) !Sampler {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        return Sampler{ .id = js.createSampler(device.id, js_desc) };
    }

    pub fn deinitSampler(_: *Device, sampler: *Sampler) void {
        js.destroySampler(sampler.id);
    }

    pub fn initBindGroupLayout(
        device: *Device,
        desc: gfx.BindGroupLayoutDesc,
    ) !BindGroupLayout {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        return BindGroupLayout{
            .id = js.createBindGroupLayout(device.id, js_desc),
        };
    }

    pub fn deinitBindGroupLayout(_: *Device, bind_group_layout: *BindGroupLayout) void {
        js.destroyBindGroupLayout(bind_group_layout.id);
    }

    pub fn initBindGroup(device: *Device, desc: gfx.BindGroupDesc) !BindGroup {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        return BindGroup{ .id = js.createBindGroup(device.id, js_desc) };
    }

    pub fn deinitBindGroup(_: *Device, bind_group: *BindGroup) void {
        js.destroyBindGroup(bind_group.id);
    }

    pub fn initPipelineLayout(device: *Device, desc: gfx.PipelineLayoutDesc) !PipelineLayout {
        var js_desc = js.initDesc();
        defer js.deinitDesc(js_desc);
        setDesc(js_desc, desc);

        return PipelineLayout{ .id = js.createPipelineLayout(device.id, js_desc) };
    }

    pub fn deinitPipelineLayout(_: *Device, pipeline_layout: *PipelineLayout) void {
        js.destroyPipelineLayout(pipeline_layout.id);
    }

    pub fn initRenderPipeline(device: *Device, desc: gfx.RenderPipelineDesc) !RenderPipeline {
        defer js.deinitDesc(desc.impl.id);
        return RenderPipeline{
            .id = js.createRenderPipeline(device.id, desc.impl.id),
        };
    }

    pub fn deinitRenderPipeline(_: *Device, render_pipeline: *RenderPipeline) void {
        js.destroyRenderPipeline(render_pipeline.id);
    }

    pub fn initCommandEncoder(device: *Device) !CommandEncoder {
        return CommandEncoder{ .id = js.createCommandEncoder(device.id) };
    }

    pub fn getQueue(device: *Device) Queue {
        return Queue{ .id = device.id };
    }
};

pub const Swapchain = struct {
    id: js.ContextId,
    view_desc: js.DescId,

    pub fn getCurrentTextureView(swapchain: *Swapchain) !TextureView {
        const tex_id = js.getContextCurrentTexture(swapchain.id);
        setDescFieldValue(swapchain.view_desc, "texture", tex_id);
        return TextureView{ .id = js.createTextureView(swapchain.view_desc) };
    }

    pub fn present(_: *Swapchain) !void {}
};

pub const Shader = struct {
    id: js.ShaderId,
};

pub const Buffer = struct {
    id: js.BufferId,
};

pub const Texture = struct {
    id: js.TextureId,

    pub fn createView(texture: *Texture) !TextureView {
        return TextureView{ .id = js.createTextureView(texture.id) };
    }

    pub fn destroy(texture: *Texture) void {
        js.destroyTexture(texture.id);
    }
};

pub const TextureView = struct {
    id: js.TextureViewId,
};

pub const Sampler = struct {
    id: js.SamplerId,

    pub fn destroy(sampler: *Sampler) void {
        js.destroySampler(sampler.id);
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

pub const RenderPipelineDesc = struct {
    id: js.DescId = js.default_desc_id,

    pub fn setPipelineLayout(
        desc: *RenderPipelineDesc,
        pipeline_layout: *const gfx.PipelineLayout,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "layout", pipeline_layout);
    }

    pub fn setVertexState(desc: *RenderPipelineDesc, vertex_state: gfx.VertexState) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "vertex", vertex_state);
    }

    pub fn setPrimitiveState(
        desc: *RenderPipelineDesc,
        primitive_state: gfx.PrimitiveState,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "primitive", primitive_state);
    }

    pub fn setDepthStencilState(
        desc: *RenderPipelineDesc,
        depth_stencil_state: gfx.DepthStencilState,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "depthStencil", depth_stencil_state);
    }

    pub fn setMultisampleState(
        desc: *RenderPipelineDesc,
        multisample_state: gfx.MultisampleState,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "multisample", multisample_state);
    }

    pub fn setFragmentState(desc: *RenderPipelineDesc, fragment_state: gfx.FragmentState) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "fragment", fragment_state);
    }
};

pub const RenderPipeline = struct {
    id: js.RenderPipelineId,

    pub fn destroy(render_pipeline: *RenderPipeline) void {
        js.destroyRenderPipeline(render_pipeline.id);
    }
};

pub const CommandEncoder = struct {
    id: js.CommandEncoderId,

    pub fn beginRenderPass(encoder: *CommandEncoder, desc: gfx.RenderPassDesc) !RenderPass {
        defer js.deinitDesc(desc.impl.id);
        return RenderPass{ .id = js.beginRenderPass(encoder.id, desc.impl.id) };
    }

    pub fn finish(encoder: *CommandEncoder) !CommandBuffer {
        return CommandBuffer{ .id = js.finishCommandEncoder(encoder.id) };
    }
};

pub const CommandBuffer = struct {
    id: js.CommandBufferId,
};

pub const RenderPassDesc = struct {
    id: js.DescId = js.default_desc_id,

    pub fn setColorAttachments(
        desc: *RenderPassDesc,
        color_attachments: []const gfx.ColorAttachment,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "colorAttachments", color_attachments);
    }

    pub fn setDepthStencilAttachment(
        desc: *RenderPassDesc,
        depth_stencil_attachment: gfx.DepthStencilAttachment,
    ) void {
        if (desc.id == js.default_desc_id) {
            desc.id = js.initDesc();
        }
        setDescFieldValue(desc.id, "depthStencilAttachment", depth_stencil_attachment);
    }
};

pub const RenderPass = struct {
    id: js.RenderPassId,

    pub fn setPipeline(render_pass: *RenderPass, render_pipeline: *const RenderPipeline) !void {
        js.setPipeline(render_pass.id, render_pipeline.id);
    }

    pub fn setBindGroup(
        render_pass: *RenderPass,
        group_index: u32,
        group: *const BindGroup,
        dynamic_offsets: ?[]const u32,
    ) !void {
        const offsets = if (dynamic_offsets) |offsets|
            std.mem.sliceAsBytes(offsets)
        else
            &[_]u8{};

        js.setBindGroup(render_pass.id, group_index, group.id, offsets.ptr, offsets.len);
    }

    pub fn setVertexBuffer(
        render_pass: *RenderPass,
        slot: u32,
        buffer: *const Buffer,
        offset: u32,
        size: usize,
    ) !void {
        js.setVertexBuffer(render_pass.id, slot, buffer.id, offset, size);
    }

    pub fn setIndexBuffer(
        render_pass: *RenderPass,
        buffer: *const Buffer,
        index_format: gfx.IndexFormat,
        offset: u32,
        size: usize,
    ) !void {
        const fmt_name = getEnumName(index_format);
        js.setIndexBuffer(render_pass.id, buffer.id, fmt_name.ptr, fmt_name.len, offset, size);
    }

    pub fn draw(
        render_pass: *RenderPass,
        vertex_count: usize,
        instance_count: usize,
        first_vertex: usize,
        first_instance: usize,
    ) !void {
        js.draw(render_pass.id, vertex_count, instance_count, first_vertex, first_instance);
    }

    pub fn drawIndexed(
        render_pass: *RenderPass,
        index_count: usize,
        instance_count: usize,
        first_index: usize,
        base_vertex: i32,
        first_instance: usize,
    ) !void {
        js.drawIndexed(
            render_pass.id,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub fn end(render_pass: *RenderPass) !void {
        js.endRenderPass(render_pass.id);
    }
};

pub const Queue = struct {
    id: js.DeviceId,

    pub fn writeBuffer(
        queue: *Queue,
        buffer: *const Buffer,
        buffer_offset: usize,
        data: []const u8,
        data_offset: usize,
    ) !void {
        js.queueWriteBuffer(queue.id, buffer.id, buffer_offset, data.ptr, data.len, data_offset);
    }

    pub fn writeTexture(
        queue: *Queue,
        destination: gfx.ImageCopyTexture,
        data: []const u8,
        data_layout: gfx.ImageDataLayout,
        size: gfx.Extent3d,
    ) !void {
        var destination_desc = js.initDesc();
        defer js.deinitDesc(destination_desc);
        setDesc(destination_desc, destination);

        var data_layout_desc = js.initDesc();
        defer js.deinitDesc(data_layout_desc);
        setDesc(data_layout_desc, data_layout);

        js.queueWriteTexture(
            queue.id,
            destination_desc,
            data.ptr,
            data.len,
            data_layout_desc,
            size.width,
            size.height,
            size.depth_or_array_layers,
        );
    }

    pub fn submit(queue: *Queue, command_buffers: []const gfx.CommandBuffer) !void {
        for (command_buffers) |command_buffer| {
            js.queueSubmit(queue.id, command_buffer.impl.id);
        }
    }
};
