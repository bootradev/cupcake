const api = switch (cfg.platform) {
    .web => @import("gfx_web.zig"),
};
const app = @import("app.zig");
const build_res = @import("build_res.zig");
const cfg = @import("cfg");
const res = @import("res.zig");
const std = @import("std");

pub const whole_size = std.math.maxInt(usize);

pub const ContextDesc = struct {
    adapter_desc: AdapterDesc = .{},
    device_desc: DeviceDesc = .{},
};

pub const Context = struct {
    window: *const app.Window,
    instance: Instance,
    surface: Surface,
    adapter: Adapter,
    device: Device,
    swapchain: Swapchain,
    swapchain_format: TextureFormat,
    swapchain_view: TextureView,
    queue: Queue,
    clear_color: Color,
    depth_texture: Texture,
    depth_texture_format: TextureFormat,
    depth_texture_view: TextureView,

    pub fn init(window: *const app.Window, desc: ContextDesc) !Context {
        var ctx: Context = undefined;

        ctx.window = window;
        ctx.instance = try Instance.init();
        ctx.surface = try ctx.instance.createSurface(window);
        ctx.adapter = try ctx.instance.requestAdapter(desc.adapter_desc);
        ctx.device = try ctx.adapter.requestDevice(desc.device_desc);
        ctx.swapchain_format = try ctx.surface.getPreferredFormat(ctx.adapter);
        ctx.swapchain = try ctx.device.createSwapchain(
            &ctx.surface,
            .{
                .size = .{ .width = window.width, .height = window.height },
                .format = ctx.swapchain_format,
            },
        );
        ctx.clear_color = .{ .r = 0.32, .g = 0.1, .b = 0.18, .a = 1.0 };
        ctx.depth_texture_format = .depth24plus;
        ctx.depth_texture = try ctx.device.createTexture(.{
            .size = .{ .width = ctx.window.width, .height = ctx.window.height },
            .format = ctx.depth_texture_format,
            .usage = .{ .render_attachment = true },
        });
        ctx.depth_texture_view = try ctx.depth_texture.createView();

        return ctx;
    }

    pub fn deinit(ctx: *Context) void {
        ctx.depth_texture_view.destroy();
        ctx.depth_texture.destroy();
        ctx.swapchain.destroy();
        ctx.device.destroy();
        ctx.adapter.destroy();
        ctx.surface.destroy();
        ctx.instance.deinit();
    }

    pub fn beginFrame(ctx: *Context) !void {
        ctx.swapchain_view = try ctx.swapchain.getCurrentTextureView();
        ctx.queue = try ctx.device.getQueue();
    }

    pub fn endFrame(ctx: *Context) !void {
        ctx.swapchain_view.destroy();
        try ctx.swapchain.present();
    }

    pub fn submit(ctx: *Context, buffers: []const CommandBuffer) !void {
        try ctx.queue.submit(buffers);
    }

    pub fn loadShader(ctx: *Context, comptime r: res.Res, desc: res.LoadDesc) !Shader {
        const shader_res = try res.load(r, desc);
        return try ctx.device.createShader(shader_res);
    }

    pub fn createBuffer(ctx: *Context, desc: BufferDesc) !Buffer {
        return try ctx.device.createBuffer(desc);
    }

    pub fn createTexture(ctx: *Context, desc: TextureDesc) !Texture {
        return try ctx.device.createTexture(desc);
    }

    pub fn createBindGroupLayout(ctx: *Context, desc: BindGroupLayoutDesc) !BindGroupLayout {
        return try ctx.device.createBindGroupLayout(desc);
    }

    pub fn createBindGroup(ctx: *Context, desc: BindGroupDesc) !BindGroup {
        return try ctx.device.createBindGroup(desc);
    }

    pub fn createPipelineLayout(ctx: *Context, desc: PipelineLayoutDesc) !PipelineLayout {
        return try ctx.device.createPipelineLayout(desc);
    }

    pub fn createRenderPipeline(ctx: *Context, desc: RenderPipelineDesc) !RenderPipeline {
        return try ctx.device.createRenderPipeline(desc);
    }

    pub fn createCommandEncoder(ctx: *Context) !CommandEncoder {
        return try ctx.device.createCommandEncoder();
    }

    pub fn writeBuffer(
        ctx: *Context,
        buffer: *const Buffer,
        buffer_offset: usize,
        data: []const u8,
        data_offset: usize,
    ) !void {
        return try ctx.queue.writeBuffer(buffer, buffer_offset, data, data_offset);
    }
};

pub const Instance = struct {
    impl: api.Instance,

    pub fn init() !Instance {
        return Instance{ .impl = try api.Instance.init() };
    }

    pub fn deinit(instance: *Instance) void {
        instance.impl.deinit();
    }

    pub fn createSurface(instance: *Instance, window: *const app.Window) !Surface {
        return Surface{ .impl = try instance.impl.createSurface(window) };
    }

    pub fn requestAdapter(instance: *Instance, desc: AdapterDesc) !Adapter {
        return Adapter{ .impl = try instance.impl.requestAdapter(desc) };
    }
};

pub const Surface = struct {
    impl: api.Surface,

    pub fn destroy(surface: *Surface) void {
        surface.impl.destroy();
    }

    pub fn getPreferredFormat(surface: *Surface, adapter: Adapter) !TextureFormat {
        return try surface.impl.getPreferredFormat(adapter.impl);
    }
};

pub const PowerPreference = enum {
    low_power,
    high_performance,
};

pub const AdapterDesc = struct {
    impl: api.AdapterDesc = .{},

    pub fn setPowerPreference(desc: *AdapterDesc, power_preference: PowerPreference) void {
        desc.impl.setPowerPreference(power_preference);
    }

    pub fn setForceFallbackAdapter(desc: *AdapterDesc, force_fallback_adapter: bool) void {
        desc.impl.setForceFallbackAdapter(force_fallback_adapter);
    }
};

pub const Adapter = struct {
    impl: api.Adapter,

    pub fn destroy(adapter: *Adapter) void {
        adapter.impl.destroy();
    }

    pub fn requestDevice(adapter: *Adapter, desc: DeviceDesc) !Device {
        return Device{ .impl = try adapter.impl.requestDevice(desc) };
    }
};

pub const FeatureName = enum {
    depth_clip_control,
    depth24unorm_stencil8,
    depth32float_stencil8,
    timestamp_query,
    pipeline_statistics_query,
    texture_compression_bc,
    texture_compression_etc2,
    texture_compression_astc,
    indirect_first_instance,
};

pub const Limits = struct {
    max_texture_dimension_1d: ?u32 = null,
    max_texture_dimension_2d: ?u32 = null,
    max_texture_dimension_3d: ?u32 = null,
    max_texture_array_layers: ?u32 = null,
    max_bind_groups: ?u32 = null,
    max_dynamic_uniform_buffers_per_pipeline_layout: ?u32 = null,
    max_dynamic_storage_buffers_per_pipeline_layout: ?u32 = null,
    max_sampled_textures_per_shader_stage: ?u32 = null,
    max_samplers_per_shader_stage: ?u32 = null,
    max_storage_buffers_per_shader_stage: ?u32 = null,
    max_storage_textures_per_shader_stage: ?u32 = null,
    max_uniform_buffers_per_shader_stage: ?u32 = null,
    max_uniform_buffer_binding_size: ?u32 = null,
    max_storage_buffer_binding_size: ?u32 = null,
    min_uniform_buffer_offset_alignment: ?u32 = null,
    min_storage_buffer_offset_alignment: ?u32 = null,
    max_vertex_buffers: ?u32 = null,
    max_vertex_attributes: ?u32 = null,
    max_vertex_buffer_array_stride: ?u32 = null,
    max_inter_stage_shader_components: ?u32 = null,
    max_compute_workgroup_storage_size: ?u32 = null,
    max_compute_invocations_per_workgroup: ?u32 = null,
    max_compute_workgroup_size_x: ?u32 = null,
    max_compute_workgroup_size_y: ?u32 = null,
    max_compute_workgroup_size_z: ?u32 = null,
    max_compute_workgroups_per_dimension: ?u32 = null,
};

pub const DeviceDesc = struct {
    impl: api.DeviceDesc = .{},

    pub fn setRequiredFeatures(desc: *DeviceDesc, required_features: []const FeatureName) void {
        desc.impl.setRequiredFeatures(required_features);
    }

    pub fn setRequiredLimits(desc: *DeviceDesc, required_limits: Limits) void {
        desc.impl.setRequiredLimits(required_limits);
    }
};

pub const Device = struct {
    impl: api.Device,

    pub fn destroy(device: *Device) void {
        device.impl.destroy();
    }

    pub fn createSwapchain(device: *Device, surface: *Surface, desc: SwapchainDesc) !Swapchain {
        return Swapchain{ .impl = try device.impl.createSwapchain(&surface.impl, desc) };
    }

    pub fn createShader(device: *Device, shader_res: build_res.ShaderRes) !Shader {
        return Shader{ .impl = try device.impl.createShader(shader_res) };
    }

    pub fn createBuffer(device: *Device, desc: BufferDesc) !Buffer {
        return Buffer{ .impl = try device.impl.createBuffer(desc) };
    }

    pub fn createTexture(device: *Device, desc: TextureDesc) !Texture {
        return Texture{ .impl = try device.impl.createTexture(desc) };
    }

    pub fn createBindGroupLayout(device: *Device, desc: BindGroupLayoutDesc) !BindGroupLayout {
        return BindGroupLayout{ .impl = try device.impl.createBindGroupLayout(desc) };
    }

    pub fn createBindGroup(device: *Device, desc: BindGroupDesc) !BindGroup {
        return BindGroup{ .impl = try device.impl.createBindGroup(desc) };
    }

    pub fn createPipelineLayout(device: *Device, desc: PipelineLayoutDesc) !PipelineLayout {
        return PipelineLayout{ .impl = try device.impl.createPipelineLayout(desc) };
    }

    pub fn createRenderPipeline(device: *Device, desc: RenderPipelineDesc) !RenderPipeline {
        return RenderPipeline{ .impl = try device.impl.createRenderPipeline(desc) };
    }

    pub fn createCommandEncoder(device: *Device) !CommandEncoder {
        return CommandEncoder{ .impl = try device.impl.createCommandEncoder() };
    }

    pub fn getQueue(device: *Device) !Queue {
        return Queue{ .impl = try device.impl.getQueue() };
    }
};

pub const Extent3d = struct {
    width: u32,
    height: u32,
    depth_or_array_layers: u32 = 1,
};

pub const SwapchainDesc = struct {
    size: Extent3d,
    format: TextureFormat,
};

pub const Swapchain = struct {
    impl: api.Swapchain,

    pub fn destroy(swapchain: *Swapchain) void {
        swapchain.impl.destroy();
    }

    pub fn getCurrentTextureView(swapchain: *Swapchain) !TextureView {
        return TextureView{ .impl = try swapchain.impl.getCurrentTextureView() };
    }

    pub fn present(swapchain: *Swapchain) !void {
        try swapchain.impl.present();
    }
};

pub const ShaderStage = packed struct {
    vertex: bool = false,
    fragment: bool = false,
    compute: bool = false,
};

pub const Shader = struct {
    impl: api.Shader,

    pub fn destroy(shader: *Shader) void {
        shader.impl.destroy();
    }
};

pub const BufferUsage = packed struct {
    map_read: bool = false,
    map_write: bool = false,
    copy_src: bool = false,
    copy_dst: bool = false,
    index: bool = false,
    vertex: bool = false,
    uniform: bool = false,
    storage: bool = false,
    indirect: bool = false,
    query_resolve: bool = false,
};

pub const BufferDesc = struct {
    size: usize,
    usage: BufferUsage,
    data: ?[]const u8 = null,
};

pub const Buffer = struct {
    impl: api.Buffer,

    pub fn destroy(buffer: *Buffer) void {
        buffer.impl.destroy();
    }
};

pub const TextureFormat = enum {
    r8unorm,
    r8snorm,
    r8uint,
    r8sint,
    r16uint,
    r16sint,
    r16float,
    rg8unorm,
    rg8snorm,
    rg8uint,
    rg8sint,
    r32float,
    r32uint,
    r32sint,
    rg16uint,
    rg16sint,
    rg16float,
    rgba8unorm,
    rgba8unorm_srgb,
    rgba8snorm,
    rgba8uint,
    rgba8sint,
    bgra8unorm,
    bgra8unorm_srgb,
    rgb10a2unorm,
    rg11b10ufloat,
    rgb9e5ufloat,
    rg32float,
    rg32uint,
    rg32sint,
    rgba16uint,
    rgba16sint,
    rgba16float,
    rgba32float,
    rgba32uint,
    rgba32sint,
    stencil8,
    depth16unorm,
    depth24plus,
    depth24plus_stencil8,
    depth24unorm_stencil8,
    depth32float,
    depth32float_stencil8,
    bc1_rgba_unorm,
    bc1_rgba_unorm_srgb,
    bc2_rgba_unorm,
    bc2_rgba_unorm_srgb,
    bc3_rgba_unorm,
    bc3_rgba_unorm_srgb,
    bc4_r_unorm,
    bc4_r_snorm,
    bc5_rg_unorm,
    bc5_rg_snorm,
    bc6h_rgb_ufloat,
    bc6h_rgb_float,
    bc7_rgba_unorm,
    bc7_rgba_unorm_srgb,
    etc2_rgb8unorm,
    etc2_rgb8unorm_srgb,
    etc2_rgb8a1unorm,
    etc2_rgb8a1unorm_srgb,
    etc2_rgba8unorm,
    etc2_rgba8unorm_srgb,
    eac_r11unorm,
    eac_r11snorm,
    eac_rg11unorm,
    eac_rg11snorm,
    astc_4x4_unorm,
    astc_4x4_unorm_srgb,
    astc_5x4_unorm,
    astc_5x4_unorm_srgb,
    astc_5x5_unorm,
    astc_5x5_unorm_srgb,
    astc_6x5_unorm,
    astc_6x5_unorm_srgb,
    astc_6x6_unorm,
    astc_6x6_unorm_srgb,
    astc_8x5_unorm,
    astc_8x5_unorm_srgb,
    astc_8x6_unorm,
    astc_8x6_unorm_srgb,
    astc_8x8_unorm,
    astc_8x8_unorm_srgb,
    astc_10x5_unorm,
    astc_10x5_unorm_srgb,
    astc_10x6_unorm,
    astc_10x6_unorm_srgb,
    astc_10x8_unorm,
    astc_10x8_unorm_srgb,
    astc_10x10_unorm,
    astc_10x10_unorm_srgb,
    astc_12x10_unorm,
    astc_12x10_unorm_srgb,
    astc_12x12_unorm,
    astc_12x12_unorm_srgb,
};

pub const TextureUsage = packed struct {
    copy_src: bool = false,
    copy_dst: bool = false,
    texture_binding: bool = false,
    storage_binding: bool = false,
    render_attachment: bool = false,
};

pub const TextureViewDimension = enum {
    @"1d",
    @"2d",
    @"2d_array",
    cube,
    cube_array,
    @"3d",
};

pub const TextureDesc = struct {
    size: Extent3d,
    format: TextureFormat,
    usage: TextureUsage,
    dimension: TextureViewDimension = .@"2d",
    mip_level_count: u32 = 1,
    sample_count: u32 = 1,
};

pub const Texture = struct {
    impl: api.Texture,

    pub fn createView(texture: *Texture) !TextureView {
        return TextureView{ .impl = try texture.impl.createView() };
    }

    pub fn destroy(texture: *Texture) void {
        texture.impl.destroy();
    }
};

pub const TextureView = struct {
    impl: api.TextureView,

    pub fn destroy(texture_view: *TextureView) void {
        texture_view.impl.destroy();
    }
};

pub const BufferBindingType = enum {
    uniform,
    storage,
    read_only_storage,
};

pub const BufferBindingLayout = struct {
    binding_type: BufferBindingType = .uniform,
    has_dynamic_offset: bool = false,
    min_binding_size: usize = 0,
};

pub const BindingLayout = union(enum) {
    buffer: BufferBindingLayout,
};

pub const BindGroupLayoutEntry = struct {
    binding: u32,
    visibility: ShaderStage,
    layout: BindingLayout,
};

pub const BindGroupLayoutDesc = struct {
    entries: []const BindGroupLayoutEntry,
};

pub const BindGroupLayout = struct {
    impl: api.BindGroupLayout,

    pub fn destroy(bind_group_layout: *BindGroupLayout) void {
        bind_group_layout.impl.destroy();
    }
};

pub const BufferBinding = struct {
    buffer: *const Buffer,
    offset: usize = 0,
    size: usize = whole_size,
};

pub const BindingResource = union(enum) {
    buffer_binding: BufferBinding,
};

pub const BindGroupEntry = struct {
    binding: u32,
    resource: BindingResource,
};

pub const BindGroupDesc = struct {
    layout: *const BindGroupLayout,
    entries: []const BindGroupEntry,
};

pub const BindGroup = struct {
    impl: api.BindGroup,

    pub fn destroy(bind_group: *BindGroup) void {
        bind_group.impl.destroy();
    }
};

pub const PipelineLayoutDesc = struct {
    bind_group_layouts: []const BindGroupLayout,
};

pub const PipelineLayout = struct {
    impl: api.PipelineLayout,

    pub fn destroy(pipeline_layout: *PipelineLayout) void {
        pipeline_layout.impl.destroy();
    }
};

pub const VertexFormat = enum {
    uint8x2,
    uint8x4,
    sint8x2,
    sint8x4,
    unorm8x2,
    unorm8x4,
    snorm8x2,
    snorm8x4,
    uint16x2,
    uint16x4,
    sint16x2,
    sint16x4,
    unorm16x2,
    unorm16x4,
    snorm16x2,
    snorm16x4,
    float16x2,
    float16x4,
    float32,
    float32x2,
    float32x3,
    float32x4,
    uint32,
    uint32x2,
    uint32x3,
    uint32x4,
    sint32,
    sint32x2,
    sint32x3,
    sint32x4,
};

pub const VertexAttribute = struct {
    format: VertexFormat,
    offset: usize,
    shader_location: u32,
};

pub const VertexStepMode = enum {
    vertex,
    instance,
};

pub const VertexBufferLayout = struct {
    array_stride: usize,
    step_mode: VertexStepMode = .vertex,
    attributes: []const VertexAttribute,
};

pub const VertexState = struct {
    module: *const Shader,
    entry_point: []const u8,
    buffers: []const VertexBufferLayout = &.{},
};

pub const PrimitiveTopology = enum {
    point_list,
    line_list,
    line_strip,
    triangle_list,
    triangle_strip,
};

pub const FrontFace = enum {
    ccw,
    cw,
};

pub const CullMode = enum {
    none,
    front,
    back,
};

pub const IndexFormat = enum {
    uint16,
    uint32,
};

pub const PrimitiveState = struct {
    topology: PrimitiveTopology = .triangle_list,
    front_face: FrontFace = .ccw,
    cull_mode: CullMode = .none,
    strip_index_format: ?IndexFormat = null,
};

pub const CompareFunction = enum {
    never,
    less,
    less_equal,
    greater,
    greater_equal,
    equal,
    not_equal,
    always,
};

pub const DepthState = struct {
    write_enabled: bool = false,
    compare: CompareFunction = .always,
    bias: i32 = 0,
    bias_clamp: f32 = 0.0,
    bias_slope_scale: f32 = 0.0,
};

pub const StencilOperation = enum {
    keep,
    zero,
    replace,
    invert,
    increment_clamp,
    decrement_clamp,
    increment_wrap,
    decrement_wrap,
};

pub const StencilFaceState = struct {
    compare: CompareFunction = .always,
    fail_op: StencilOperation = .keep,
    depth_fail_op: StencilOperation = .keep,
    pass_op: StencilOperation = .keep,
};

pub const StencilState = struct {
    front: StencilFaceState = .{},
    back: StencilFaceState = .{},
    read_mask: u32,
    write_mask: u32,
};

pub const DepthStencilState = struct {
    format: TextureFormat,
    depth: ?DepthState = null,
    stencil: ?StencilState = null,
};

pub const ColorTargetState = struct {
    format: TextureFormat,
};

pub const FragmentState = struct {
    module: *const Shader,
    entry_point: []const u8,
    targets: []const ColorTargetState,
};

pub const RenderPipelineDesc = struct {
    impl: api.RenderPipelineDesc = .{},

    pub fn setPipelineLayout(
        desc: *RenderPipelineDesc,
        pipeline_layout: *const PipelineLayout,
    ) void {
        desc.impl.setPipelineLayout(pipeline_layout);
    }

    pub fn setVertexState(desc: *RenderPipelineDesc, vertex_state: VertexState) void {
        desc.impl.setVertexState(vertex_state);
    }

    pub fn setPrimitiveState(desc: *RenderPipelineDesc, primitive_state: PrimitiveState) void {
        desc.impl.setPrimitiveState(primitive_state);
    }

    pub fn setDepthStencilState(
        desc: *RenderPipelineDesc,
        depth_stencil_state: DepthStencilState,
    ) void {
        desc.impl.setDepthStencilState(depth_stencil_state);
    }

    pub fn setFragmentState(desc: *RenderPipelineDesc, fragment_state: FragmentState) void {
        desc.impl.setFragmentState(fragment_state);
    }
};

pub const RenderPipeline = struct {
    impl: api.RenderPipeline,

    pub fn destroy(render_pipeline: *RenderPipeline) void {
        render_pipeline.impl.destroy();
    }
};

pub const CommandEncoder = struct {
    impl: api.CommandEncoder,

    pub fn beginRenderPass(encoder: *CommandEncoder, desc: RenderPassDesc) !RenderPass {
        return RenderPass{ .impl = try encoder.impl.beginRenderPass(desc) };
    }

    pub fn finish(encoder: *CommandEncoder) !CommandBuffer {
        return CommandBuffer{ .impl = try encoder.impl.finish() };
    }
};

pub const CommandBuffer = struct {
    impl: api.CommandBuffer,
};

pub const LoadOp = enum {
    load,
    clear,
};

pub const StoreOp = enum {
    store,
    discard,
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub const ColorAttachment = struct {
    view: *const TextureView,
    load_op: LoadOp,
    store_op: StoreOp,
    clear_value: Color,
};

pub const DepthAttachment = struct {
    clear_value: f32 = 0.0,
    load_op: LoadOp,
    store_op: StoreOp,
    read_only: bool = false,
};

pub const StencilAttachment = struct {
    clear_value: u32 = 0,
    load_op: LoadOp,
    store_op: StoreOp,
    read_only: bool = false,
};

pub const DepthStencilAttachment = struct {
    view: *const TextureView,
    depth: ?DepthAttachment = null,
    stencil: ?StencilAttachment = null,
};

pub const RenderPassDesc = struct {
    impl: api.RenderPassDesc = .{},

    pub fn setColorAttachments(
        desc: *RenderPassDesc,
        color_attachments: []const ColorAttachment,
    ) void {
        desc.impl.setColorAttachments(color_attachments);
    }

    pub fn setDepthStencilAttachment(
        desc: *RenderPassDesc,
        depth_stencil_attachment: DepthStencilAttachment,
    ) void {
        desc.impl.setDepthStencilAttachment(depth_stencil_attachment);
    }
};

pub const RenderPass = struct {
    impl: api.RenderPass,

    pub fn setPipeline(render_pass: *RenderPass, render_pipeline: *const RenderPipeline) !void {
        try render_pass.impl.setPipeline(&render_pipeline.impl);
    }

    pub fn setBindGroup(
        render_pass: *RenderPass,
        group_index: u32,
        group: *const BindGroup,
        dynamic_offsets: ?[]const u32,
    ) !void {
        try render_pass.impl.setBindGroup(group_index, &group.impl, dynamic_offsets);
    }

    pub fn setVertexBuffer(
        render_pass: *RenderPass,
        slot: u32,
        buffer: *const Buffer,
        offset: u32,
        size: usize,
    ) !void {
        try render_pass.impl.setVertexBuffer(slot, &buffer.impl, offset, size);
    }

    pub fn setIndexBuffer(
        render_pass: *RenderPass,
        buffer: *const Buffer,
        index_format: IndexFormat,
        offset: u32,
        size: usize,
    ) !void {
        try render_pass.impl.setIndexBuffer(&buffer.impl, index_format, offset, size);
    }

    pub fn draw(
        render_pass: *RenderPass,
        vertex_count: usize,
        instance_count: usize,
        first_vertex: usize,
        first_instance: usize,
    ) !void {
        try render_pass.impl.draw(vertex_count, instance_count, first_vertex, first_instance);
    }

    pub fn drawIndexed(
        render_pass: *RenderPass,
        index_count: usize,
        instance_count: usize,
        first_index: usize,
        base_vertex: i32,
        first_instance: usize,
    ) !void {
        try render_pass.impl.drawIndexed(
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub fn end(render_pass: *RenderPass) !void {
        try render_pass.impl.end();
    }
};

pub const Queue = struct {
    impl: api.Queue,

    pub fn writeBuffer(
        queue: *Queue,
        buffer: *const Buffer,
        buffer_offset: usize,
        data: []const u8,
        data_offset: usize,
    ) !void {
        try queue.impl.writeBuffer(&buffer.impl, buffer_offset, data, data_offset);
    }

    pub fn submit(queue: *Queue, buffers: []const CommandBuffer) !void {
        try queue.impl.submit(buffers);
    }
};
