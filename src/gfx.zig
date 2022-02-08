const api = switch (cfg.gfx_api) {
    .webgpu => @import("gfx_webgpu.zig"),
};
const cfg = @import("cfg");
const math = @import("math.zig");
const std = @import("std");

pub const whole_size = std.math.maxInt(usize);

pub const Instance = api.Instance;
pub const Adapter = api.Adapter;
pub const Device = api.Device;
pub const Buffer = api.Buffer;
pub const Texture = api.Texture;
pub const TextureView = api.TextureView;
pub const Sampler = api.Sampler;
pub const Shader = api.Shader;
pub const Surface = api.Surface;
pub const Swapchain = api.Swapchain;
pub const BindGroupLayout = api.BindGroupLayout;
pub const BindGroup = api.BindGroup;
pub const PipelineLayout = api.PipelineLayout;
pub const RenderPipeline = api.RenderPipeline;
pub const RenderPass = api.RenderPass;
pub const CommandEncoder = api.CommandEncoder;
pub const CommandBuffer = api.CommandBuffer;
pub const QuerySet = api.QuerySet;
pub const Queue = api.Queue;

pub const SurfaceDesc = struct {
    label: []const u8 = "",
};

pub const PowerPreference = enum {
    @"undefined",
    low_power,
    high_performance,
};

pub const AdapterDesc = struct {
    power_preference: PowerPreference = .@"undefined",
    force_fallback_adapter: bool = false,
};

pub const FeatureName = enum {
    @"undefined",
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
    max_texture_dimension_1d: u32 = 8192,
    max_texture_dimension_2d: u32 = 8192,
    max_texture_dimension_3d: u32 = 2048,
    max_texture_array_layers: u32 = 256,
    max_bind_groups: u32 = 4,
    max_dynamic_uniform_buffers_per_pipeline_layout: u32 = 8,
    max_dynamic_storage_buffers_per_pipeline_layout: u32 = 4,
    max_sampled_textures_per_shader_stage: u32 = 16,
    max_samplers_per_shader_stage: u32 = 16,
    max_storage_buffers_per_shader_stage: u32 = 8,
    max_storage_textures_per_shader_stage: u32 = 4,
    max_uniform_buffers_per_shader_stage: u32 = 12,
    max_uniform_buffer_binding_size: u64 = 16384,
    max_storage_buffer_binding_size: u64 = 134217728,
    min_uniform_buffer_offset_alignment: u32 = 256,
    min_storage_buffer_offset_alignment: u32 = 256,
    max_vertex_buffers: u32 = 8,
    max_vertex_attributes: u32 = 16,
    max_vertex_buffer_array_stride: u32 = 2048,
    max_inter_stage_shader_components: u32 = 60,
    max_compute_workgroup_storage_size: u32 = 16352,
    max_compute_invocations_per_workgroup: u32 = 256,
    max_compute_workgroup_size_x: u32 = 256,
    max_compute_workgroup_size_y: u32 = 256,
    max_compute_workgroup_size_z: u32 = 64,
    max_compute_workgroups_per_dimension: u32 = 65535,
};

pub const DeviceDesc = struct {
    label: []const u8 = "",
    required_features: []const FeatureName = &.{},
    required_limits: Limits = .{},
};

pub const PresentMode = enum {
    immediate,
    mailbox,
    fifo,
};

pub const SwapchainDesc = struct {
    label: []const u8 = "",
    size: Extent3d,
    format: TextureFormat,
    usage: TextureUsage = .{ .render_attachment = true },
    present_mode: PresentMode = .fifo,
};

pub const ShaderStage = packed struct {
    vertex: bool = false,
    fragment: bool = false,
    compute: bool = false,
};

pub const BufferBindingType = enum {
    @"undefined",
    uniform,
    storage,
    read_only_storage,
};

pub const BufferBindingLayout = struct {
    @"type": BufferBindingType = .uniform,
    has_dynamic_offset: bool = false,
    min_binding_size: u64 = 0,
};

pub const SamplerBindingType = enum {
    @"undefined",
    filtering,
    non_filtering,
    comparison,
};

pub const SamplerBindingLayout = struct {
    @"type": SamplerBindingType = .filtering,
};

pub const TextureSampleType = enum {
    float,
    unfilterable_float,
    depth,
    sint,
    uint,
};

pub const TextureViewDimension = enum {
    @"undefined",
    @"1d",
    @"2d",
    @"2d_array",
    cube,
    cube_array,
    @"3d",
};

pub const TextureBindingLayout = struct {
    sample_type: TextureSampleType = .float,
    view_dimension: TextureViewDimension = .@"2d",
    multisampled: bool = false,
};

pub const StorageTextureAccess = enum {
    @"undefined",
    write_only,
};

pub const StorageTextureBindingLayout = struct {
    access: StorageTextureAccess = .write_only,
    format: TextureFormat,
    view_dimension: TextureViewDimension = .@"2d",
};

pub const BindingLayout = union(enum) {
    buffer: BufferBindingLayout,
    sampler: SamplerBindingLayout,
    texture: TextureBindingLayout,
    storage_texture: StorageTextureBindingLayout,
};

pub const BindGroupLayoutEntry = struct {
    binding: u32,
    visibility: ShaderStage,
    buffer: ?BufferBindingLayout = null,
    sampler: ?SamplerBindingLayout = null,
    texture: ?TextureBindingLayout = null,
    storage_texture: ?StorageTextureBindingLayout = null,
};

pub const BindGroupLayoutDesc = struct {
    label: []const u8 = "",
    entries: []const BindGroupLayoutEntry,
};

pub const BindType = enum {
    buffer,
    sampler,
    texture_view,
};

pub const BufferBinding = struct {
    buffer: *Buffer,
    offset: usize = 0,
    size: usize = whole_size,
};

pub const BindGroupResource = union(BindType) {
    buffer: BufferBinding,
    sampler: *Sampler,
    texture_view: *TextureView,
};

pub const BindGroupEntry = struct {
    binding: u32,
    resource: BindGroupResource,
};

pub const BindGroupDesc = struct {
    label: []const u8 = "",
    layout: *BindGroupLayout,
    entries: []const BindGroupEntry,
};

pub const PipelineLayoutDesc = struct {
    label: []const u8 = "",
    bind_group_layouts: []const BindGroupLayout = &.{},
};

pub const ConstantEntry = struct {
    key: []const u8,
    value: u64,
};

pub const VertexFormat = enum {
    @"undefined",
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

pub const VertexStepMode = enum {
    vertex,
    instance,
};

pub const VertexAttribute = struct {
    format: VertexFormat,
    offset: u64,
    shader_location: u32,
};

pub const VertexBufferLayout = struct {
    array_stride: u64,
    step_mode: VertexStepMode = .vertex,
    attributes: []const VertexAttribute,
};

pub const VertexState = struct {
    module: *Shader,
    entry_point: []const u8,
    constants: []const ConstantEntry = &.{},
    buffers: []const VertexBufferLayout,
};

pub const PrimitiveTopology = enum {
    point_list,
    line_list,
    line_strip,
    triangle_list,
    triangle_strip,
};

pub const IndexFormat = enum {
    @"undefined",
    uint16,
    uint32,
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

pub const PrimitiveState = struct {
    topology: PrimitiveTopology = .triangle_list,
    strip_index_format: IndexFormat = .@"undefined",
    front_face: FrontFace = .ccw,
    cull_mode: CullMode = .none,
};

pub const CompareFunction = enum {
    @"undefined",
    never,
    less,
    less_equal,
    greater,
    greater_equal,
    equal,
    not_equal,
    always,
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

pub const DepthStencilState = struct {
    format: TextureFormat,
    depth_write_enabled: bool = false,
    depth_compare: CompareFunction = .always,
    stencil_front: StencilFaceState = .{},
    stencil_back: StencilFaceState = .{},
    stencil_read_mask: u32 = 0xFFFFFFFF,
    stencil_write_mask: u32 = 0xFFFFFFFF,
    depth_bias: i32 = 0,
    depth_bias_slope_scale: f32 = 0,
    depth_bias_clamp: f32 = 0,
};

pub const MultisampleState = struct {
    count: u32 = 1,
    mask: u32 = std.math.boolMask(u32, true),
    alpha_to_coverage_enabled: bool = false,
};

pub const BlendOperation = enum {
    add,
    subtract,
    reverse_subtract,
    min,
    max,
};

pub const BlendFactor = enum {
    zero,
    one,
    src,
    one_minus_src,
    src_alpha,
    one_minus_src_alpha,
    dst,
    one_minus_dst,
    dst_alpha,
    one_minus_dst_alpha,
    src_alpha_saturated,
    constant,
    one_minus_constant,
};

pub const BlendComponent = struct {
    operation: BlendOperation = .add,
    src_factor: BlendFactor = .one,
    dst_factor: BlendFactor = .zero,
};

pub const BlendState = struct {
    color: BlendComponent = .{},
    alpha: BlendComponent = .{},
};

pub const ColorWriteMask = packed struct {
    red: bool = true,
    green: bool = true,
    blue: bool = true,
    alpha: bool = true,
};

pub const ColorTargetState = struct {
    format: TextureFormat,
    blend: ?BlendState = null,
    write_mask: ColorWriteMask = .{},
};

pub const FragmentState = struct {
    module: *const Shader,
    entry_point: []const u8,
    constants: ?[]const ConstantEntry = null,
    targets: []const ColorTargetState,
};

pub const RenderPipelineDesc = struct {
    label: []const u8 = "",
    layout: *PipelineLayout,
    vertex: VertexState,
    primitive: PrimitiveState = .{},
    depth_stencil: ?DepthStencilState = null,
    multisample: MultisampleState = .{},
    fragment: ?FragmentState = null,
};

pub const CommandBufferDesc = struct {
    label: []const u8 = "",
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub const default_clear_color: Color = .{ .r = 0.32, .g = 0.1, .b = 0.18, .a = 1.0 };

pub const LoadOp = enum {
    load,
    clear,
};

pub const StoreOp = enum {
    store,
    discard,
};

pub const ColorAttachment = struct {
    view: *TextureView,
    resolve_target: ?*TextureView = null,
    load_op: LoadOp,
    clear_value: Color = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 },
    store_op: StoreOp,
};

pub const DepthStencilAttachment = struct {
    view: *TextureView,
    depth_load_op: LoadOp,
    depth_clear_value: f32 = 0,
    depth_store_op: StoreOp,
    depth_read_only: bool = false,
    stencil_load_op: LoadOp,
    stencil_clear_value: u32 = 0,
    stencil_store_op: StoreOp,
    stencil_read_only: bool = false,
};

pub const RenderPassTimestampLocation = enum {
    beginning,
    end,
};

pub const RenderPassTimestampWrite = struct {
    quert_set: QuerySet,
    query_index: u32,
    location: RenderPassTimestampLocation,
};

pub const RenderPassDesc = struct {
    label: []const u8 = "",
    color_attachments: []ColorAttachment,
    depth_stencil_attachment: ?DepthStencilAttachment = null,
    occlusion_query_set: ?*QuerySet = null,
    timestamp_writes: ?[]RenderPassTimestampWrite = null,
};

pub const BufferDesc = struct {
    label: []const u8 = "",
    size: usize,
    usage: BufferUsage,
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

pub const TextureDimension = enum {
    @"1d",
    @"2d",
    @"3d",
};

pub const Extent3d = struct {
    width: u32,
    height: u32,
    depth_or_array_layers: u32 = 1,
};

pub const TextureDesc = struct {
    label: []const u8 = "",
    size: Extent3d,
    usage: TextureUsage,
    dimension: TextureDimension = .@"2d",
    format: TextureFormat,
    mip_level_count: u32 = 1,
    sample_count: u32 = 1,
};

pub const TextureUsage = packed struct {
    copy_src: bool = false,
    copy_dst: bool = false,
    texture_binding: bool = false,
    storage_binding: bool = false,
    render_attachment: bool = false,
};

pub const TextureFormat = enum {
    @"undefined",
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

pub const AddressMode = enum {
    clamp_to_edge,
    repeat,
    mirror_repeat,
};

pub const FilterMode = enum {
    nearest,
    linear,
};

pub const SamplerDesc = struct {
    address_mode_u: AddressMode = .clamp_to_edge,
    address_mode_v: AddressMode = .clamp_to_edge,
    address_mode_w: AddressMode = .clamp_to_edge,
    mag_filter: FilterMode = .nearest,
    min_filter: FilterMode = .nearest,
    mipmap_filter: FilterMode = .nearest,
    lod_min_clamp: f32 = 0,
    lod_max_clamp: f32 = 0,
    compare: CompareFunction = .@"undefined",
    max_anisotropy: u32 = 1,
};

pub const TextureAspect = enum {
    all,
    stencil_only,
    depth_only,
};

pub const Origin3d = struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

pub const ImageCopyTexture = struct {
    texture: *Texture,
    mip_level: u32 = 0,
    origin: Origin3d = .{},
    aspect: TextureAspect = .all,
};

pub const ImageDataLayout = struct {
    offset: usize = 0,
    bytes_per_row: u32,
    rows_per_image: u32,
};
