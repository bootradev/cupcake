const app = @import("app.zig");
const gfx = @import("gfx.zig");
const math = @import("math.zig");
const std = @import("std");

const js = struct {
    const GPUSize32 = u32;
    const GPUSize64 = u64;
    const GPUIndex32 = u32;
    const GPUSampleMask = u32;
    const GPUColorWriteFlags = u32;
    const GPUTextureUsageFlags = u32;
    const GPUBufferUsageFlags = u32;
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
    const PipelineLayoutId = ObjectId;
    const RenderPipelineId = ObjectId;
    const RenderPassId = ObjectId;
    const CommandEncoderId = ObjectId;
    const CommandBufferId = ObjectId;
    const TextureId = ObjectId;
    const TextureViewId = ObjectId;
    const QuerySetId = ObjectId;
    const BufferId = ObjectId;

    const invalid_id: ObjectId = -1;

    pub const ColorWrite = enum(GPUFlagsConstant) {
        RED = 0x1,
        GREEN = 0x2,
        BLUE = 0x4,
        ALPHA = 0x8,
        ALL = 0xF,
    };

    pub const BufferUsage = enum(GPUFlagsConstant) {
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

    pub const TextureUsage = enum(GPUFlagsConstant) {
        COPY_SRC = 0x01,
        COPY_DST = 0x02,
        TEXTURE_BINDING = 0x04,
        STORAGE_BINDING = 0x08,
        RENDER_ATTACHMENT = 0x10,
    };

    extern "webgpu" fn getContext(canvas_id: ObjectId) ContextId;
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
    extern "webgpu" fn requestDevice(
        adapter_id: AdapterId,
        json_ptr: [*]const u8,
        json_len: usize,
        cb: *c_void,
    ) void;
    extern "webgpu" fn createShader(
        device_id: DeviceId,
        code_ptr: [*]const u8,
        code_len: usize,
    ) ShaderId;
    extern "webgpu" fn destroyShader(shader_id: ShaderId) void;
    extern "webgpu" fn checkShaderCompile(shader_id: ShaderId) void;
    extern "webgpu" fn createPipelineLayout(
        device_id: DeviceId,
        bind_group_layout_ids_ptr: [*]const u8,
        bind_group_layout_ids_len: usize,
    ) PipelineLayoutId;
    extern "webgpu" fn createRenderPipeline(
        device_id: DeviceId,
        pipeline_layout_id: PipelineLayoutId,
        vert_shader_id: ShaderId,
        frag_shader_id: ShaderId,
        json_ptr: [*]const u8,
        json_len: usize,
    ) RenderPipelineId;
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
    extern "webgpu" fn endRenderPass(render_pass_id: RenderPassId) void;

    extern "webgpu" fn queueSubmit(
        device_id: DeviceId,
        command_buffers_ptr: [*]const u8,
        command_buffers_len: usize,
    ) void;
    extern "webgpu" fn createBuffer(
        device_id: DeviceId,
        size: usize,
        usage: GPUBufferUsageFlags,
        data_ptr: [*]const u8,
        data_len: usize,
    ) BufferId;
    extern "webgpu" fn createTextureView(texture_id: TextureId) TextureViewId;
};

pub fn Api(
    comptime adapter_ready_cb: fn () void,
    comptime device_ready_cb: fn () void,
    comptime error_cb: fn (err: anyerror) void,
) type {
    const Surface = packed struct {
        id: js.CanvasId,

        pub fn getPreferredFormat() gfx.TextureFormat {
            return .bgra8unorm;
        }
    };

    const TextureView = packed struct {
        tex_id: js.TextureId,
        view_id: js.TextureViewId,
    };

    const Swapchain = packed struct {
        const Swapchain = @This();

        id: js.ContextId,

        pub fn getCurrentTextureView(swapchain: *Swapchain) !TextureView {
            const tex_id = js.getContextCurrentTexture(swapchain.id);
            const view_id = js.createTextureView(tex_id);
            return TextureView{ .tex_id = tex_id, .view_id = view_id };
        }

        pub fn present(_: *Swapchain) void {}
    };

    const Shader = packed struct {
        id: js.ShaderId,
    };

    const BindGroupLayout = packed struct {
        id: js.BindGroupLayoutId,
    };

    const PipelineLayout = packed struct {
        id: js.PipelineLayoutId,
    };

    const RenderPipeline = packed struct {
        id: js.RenderPipelineId,
    };

    const RenderPass = packed struct {
        const RenderPass = @This();

        id: js.RenderPassId,

        pub fn end(render_pass: *RenderPass) void {
            js.endRenderPass(render_pass.id);
        }
    };

    const Buffer = packed struct {
        id: js.BufferId,
    };

    const CommandBuffer = packed struct {
        id: js.CommandBufferId,
    };

    const QuerySet = packed struct {
        id: js.QuerySetId,
    };

    const CommandEncoder = packed struct {
        const CommandEncoder = @This();

        id: js.CommandEncoderId,

        pub const BeginRenderPassArgs = struct {
            color_views: []const TextureView,
            color_resolve_targets: []const TextureView = &[_]TextureView{},
            depth_stencil_view: ?TextureView = null,
            occlusion_query_set: ?QuerySet = null,
            timestamp_query_sets: []const QuerySet = &[_]QuerySet{},
        };

        pub fn beginRenderPass(
            command_encoder: *CommandEncoder,
            args: BeginRenderPassArgs,
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

    const Queue = packed struct {
        const Queue = @This();

        id: js.DeviceId,

        pub fn submit(queue: *Queue, command_buffers: []const CommandBuffer) void {
            const bytes = std.mem.sliceAsBytes(command_buffers);
            js.queueSubmit(queue.id, bytes.ptr, bytes.len);
        }
    };

    const Device = struct {
        const Device = @This();

        id: js.DeviceId,

        pub fn initSwapchain(
            device: *Device,
            surface: *Surface,
            size: math.V2u32,
            comptime desc: gfx.SwapchainDesc,
        ) !Swapchain {
            const swapchain = Swapchain{ .id = js.getContext(surface.id) };
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

        pub fn initShader(device: *Device, code: []const u8) !Shader {
            return Shader{ .id = js.createShader(device.id, code.ptr, code.len) };
        }

        pub fn deinitShader(_: *Device, shader: *Shader) void {
            js.destroyShader(shader.id);
        }

        pub fn checkShaderCompile(_: *Device, shader: *Shader) void {
            js.checkShaderCompile(shader.id);
        }

        pub fn initPipelineLayout(
            device: *Device,
            bind_group_layouts: []const BindGroupLayout,
            comptime _: gfx.PipelineLayoutDesc,
        ) !PipelineLayout {
            const bytes = std.mem.sliceAsBytes(bind_group_layouts);
            return PipelineLayout{
                .id = js.createPipelineLayout(device.id, bytes.ptr, bytes.len),
            };
        }

        pub fn initRenderPipeline(
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

        pub fn initCommandEncoder(device: *Device) CommandEncoder {
            return CommandEncoder{ .id = js.createCommandEncoder(device.id) };
        }

        pub fn getQueue(device: *Device) Queue {
            return Queue{ .id = device.id };
        }

        pub fn initBuffer(
            device: *Device,
            init_data: ?[]const u8,
            size: usize,
            comptime desc: gfx.BufferDesc,
        ) !Buffer {
            const data = if (init_data) |data| data else &[_]u8{};
            return Buffer{
                .id = js.createBuffer(
                    device.id,
                    size,
                    comptime getBufferUsageFlags(desc.usage),
                    data.ptr,
                    data.len,
                ),
            };
        }
    };

    const Adapter = struct {
        const Adapter = @This();

        id: js.AdapterId,

        pub fn requestDevice(
            adapter: *Adapter,
            comptime desc: gfx.DeviceDesc,
            device: *Device,
        ) !void {
            const json = comptime stringifyDeviceDescComptime(desc);
            js.requestDevice(adapter.id, json.ptr, json.len, device);
        }

        export fn requestDeviceComplete(device_id: js.DeviceId, device_c: *c_void) void {
            var device = @ptrCast(*Device, @alignCast(@alignOf(*Device), device_c));
            device.id = device_id;
            device_ready_cb();
        }
    };

    const Instance = struct {
        const Instance = @This();

        pub fn init(_: *Instance) !void {}

        pub fn initSurface(
            _: *Instance,
            window: *app.Window,
            comptime _: gfx.SurfaceDesc,
        ) !Surface {
            return Surface{ .id = window.id };
        }

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
            adapter_ready_cb();
        }
    };

    return struct {
        pub usingnamespace gfx;

        pub const Instance = Instance;
        pub const Adapter = Adapter;
        pub const Device = Device;
        pub const Surface = Surface;
        pub const Buffer = Buffer;
        pub const TextureView = TextureView;
        pub const Swapchain = Swapchain;
        pub const Shader = Shader;
        pub const BindGroupLayout = BindGroupLayout;
        pub const PipelineLayout = PipelineLayout;
        pub const RenderPipeline = RenderPipeline;
        pub const CommandEncoder = CommandEncoder;
        pub const CommandBuffer = CommandBuffer;
        pub const Queue = Queue;

        export fn runtimeError(error_code: u32) void {
            const err = switch (error_code) {
                0 => error.RequestAdapterFailed,
                1 => error.RequestDeviceFailed,
                2 => error.CreateShaderFailed,
                else => error.UnknownError,
            };

            error_cb(err);
        }
    };
}

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
        maxTextureDimension1D: JsonOptional(u32) = .none,
        maxTextureDimension2D: JsonOptional(u32) = .none,
        maxTextureDimension3D: JsonOptional(u32) = .none,
        maxTextureArrayLayers: JsonOptional(u32) = .none,
        maxBindGroups: JsonOptional(u32) = .none,
        maxDynamicUniformBuffersPerPipelineLayout: JsonOptional(u32) = .none,
        maxDynamicStorageBuffersPerPipelineLayout: JsonOptional(u32) = .none,
        maxSampledTexturesPerShaderStage: JsonOptional(u32) = .none,
        maxSamplersPerShaderStage: JsonOptional(u32) = .none,
        maxStorageBuffersPerShaderStage: JsonOptional(u32) = .none,
        maxStorageTexturesPerShaderStage: JsonOptional(u32) = .none,
        maxUniformBuffersPerShaderStage: JsonOptional(u32) = .none,
        maxUniformBufferBindingSize: JsonOptional(u64) = .none,
        maxStorageBufferBindingSize: JsonOptional(u64) = .none,
        minUniformBufferOffsetAlignment: JsonOptional(u32) = .none,
        minStorageBufferOffsetAlignment: JsonOptional(u32) = .none,
        maxVertexBuffers: JsonOptional(u32) = .none,
        maxVertexAttributes: JsonOptional(u32) = .none,
        maxVertexBufferArrayStride: JsonOptional(u32) = .none,
        maxInterStageShaderComponents: JsonOptional(u32) = .none,
        maxComputeWorkgroupStorageSize: JsonOptional(u32) = .none,
        maxComputeInvocationsPerWorkgroup: JsonOptional(u32) = .none,
        maxComputeWorkgroupSizeX: JsonOptional(u32) = .none,
        maxComputeWorkgroupSizeY: JsonOptional(u32) = .none,
        maxComputeWorkgroupSizeZ: JsonOptional(u32) = .none,
        maxComputeWorkgroupsPerDimension: JsonOptional(u32) = .none,
    };
    const JsonDesc = struct {
        usingnamespace JsonOptionalStruct(@This());
        requiredFeatures: JsonOptional([]const []const u8) = .none,
        requiredLimits: JsonOptional(JsonLimits) = .{ .some = .{} },
    };

    comptime var json: JsonDesc = .{};
    if (desc.required_features.len > 0) {
        comptime var required_features: []const []const u8 = &[_][]const u8{};
        inline for (desc.required_features) |required_feature| {
            required_features = required_features ++ &[_][]const u8{
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
        attributes: []const JsonVertAttr = &[_]JsonVertAttr{},
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
        targets: []const JsonTarget = &[_]JsonTarget{},
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
        comptime var vert_buffers: []const JsonVertLayout = &[_]JsonVertLayout{};
        inline for (desc.vertex.buffers) |buffer| {
            comptime var json_buffer: JsonVertLayout = .{};
            json_buffer.arrayStride = buffer.array_stride;
            comptime json_buffer.stepMode.setIfNotDefault(
                buffer,
                "step_mode",
                getStepModeString(buffer.step_mode),
            );
            comptime var vert_attrs: []const JsonVertAttr = &[_]JsonVertAttr{};
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
        json.primtive = .{ .some = json_primitive };
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
        clearStencil: u32,
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
        colorAttachments: []const JsonColorAttachment = &[_]JsonColorAttachment{},
        depthStencilAttachment: JsonOptional(JsonDepthStencilAttachment) = .none,
        timestampWrites: JsonOptional([]const JsonTimestampWrite) = .none,
    };
    comptime var json: JsonDesc = .{};
    inline for (desc.color_attachments) |color_attachment| {
        json.colorAttachments = json.colorAttachments ++ &[_]JsonColorAttachment{
            .{
                .loadValue = switch (color_attachment.load_op) {
                    .clear => .{
                        .clearColor = &[_]f64{
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
        comptime var json_timestamp_writes: []const JsonTimestampWrite = &[_]JsonTimestampWrite{};
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
    return comptime replaceUnderscoreWithDash(@tagName(power_preference));
}

fn getFeatureNameString(comptime feature_name: gfx.FeatureName) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(feature_name));
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
    return @tagName(index_format);
}

fn getFrontFaceString(comptime front_face: gfx.FrontFace) []const u8 {
    return @tagName(front_face);
}

fn getCullModeString(comptime cull_mode: gfx.CullMode) []const u8 {
    return @tagName(cull_mode);
}

fn getTextureFormatString(comptime texture_format: gfx.TextureFormat) []const u8 {
    return comptime replaceUnderscoreWithDash(@tagName(texture_format));
}

fn getCompareFunctionString(comptime compare_function: gfx.CompareFunction) []const u8 {
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

fn getStoreOpString(comptime store_op: gfx.StoreOp) []const u8 {
    return @tagName(store_op);
}

fn getRenderPassTimestampLocationString(comptime loc: gfx.RenderPassTimestampLocation) []const u8 {
    return @tagName(loc);
}

fn getBufferUsageFlags(comptime buffer_usage: gfx.BufferUsage) js.GPUBufferUsageFlags {
    comptime var flags: js.GPUBufferUsageFlags = 0;
    if (buffer_usage.map_read) flags |= @enumToInt(js.BufferUsage.MAP_READ);
    if (buffer_usage.map_write) flags |= @enumToInt(js.BufferUsage.MAP_WRITE);
    if (buffer_usage.copy_src) flags |= @enumToInt(js.BufferUsage.COPY_SRC);
    if (buffer_usage.copy_dst) flags |= @enumToInt(js.BufferUsage.COPY_DST);
    if (buffer_usage.index) flags |= @enumToInt(js.BufferUsage.INDEX);
    if (buffer_usage.vertex) flags |= @enumToInt(js.BufferUsage.VERTEX);
    if (buffer_usage.uniform) flags |= @enumToInt(js.BufferUsage.UNIFORM);
    if (buffer_usage.storage) flags |= @enumToInt(js.BufferUsage.STORAGE);
    if (buffer_usage.indirect) flags |= @enumToInt(js.BufferUsage.INDIRECT);
    if (buffer_usage.query_resolve) flags |= @enumToInt(js.BufferUsage.QUERY_RESOLVE);
    return flags;
}

fn getTextureUsageFlags(comptime texture_usage: gfx.TextureUsage) js.GPUTextureUsageFlags {
    comptime var flags: js.GPUTextureUsageFlags = 0;
    if (texture_usage.copy_src) flags |= @enumToInt(js.TextureUsage.COPY_SRC);
    if (texture_usage.copy_dst) flags |= @enumToInt(js.TextureUsage.COPY_DST);
    if (texture_usage.texture_binding) flags |= @enumToInt(js.TextureUsage.TEXTURE_BINDING);
    if (texture_usage.storage_binding) flags |= @enumToInt(js.TextureUsage.STORAGE_BINDING);
    if (texture_usage.render_attachment) flags |= @enumToInt(js.TextureUsage.RENDER_ATTACHMENT);
    return flags;
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
