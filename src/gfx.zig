const api = switch (cfg.platform) {
    .web => @import("gfx_web.zig"),
};
const app = @import("app.zig");
const cfg = @import("cfg");
const std = @import("std");

pub const whole_size = std.math.maxInt(usize);

pub const PowerPreference = enum {
    low_power,
    high_performance,
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

pub const PresentMode = enum {
    immediate,
    mailbox,
    fifo,
};

pub const ShaderStage = packed struct {
    vertex: bool = false,
    fragment: bool = false,
    compute: bool = false,
};

pub const BufferBindingType = enum {
    uniform,
    storage,
    read_only_storage,
};

pub const SamplerBindingType = enum {
    filtering,
    non_filtering,
    comparison,
};

pub const TextureSampleType = enum {
    float,
    unfilterable_float,
    depth,
    sint,
    uint,
};

pub const TextureViewDimension = enum {
    @"1d",
    @"2d",
    @"2d_array",
    cube,
    cube_array,
    @"3d",
};

pub const StorageTextureAccess = enum {
    write_only,
};

pub const ConstantEntry = struct {
    key: []const u8,
    value: u64,
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

pub const VertexStepMode = enum {
    vertex,
    instance,
};

pub const PrimitiveTopology = enum {
    point_list,
    line_list,
    line_strip,
    triangle_list,
    triangle_strip,
};

pub const IndexFormat = enum {
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

pub const ColorWriteMask = packed struct {
    red: bool = true,
    green: bool = true,
    blue: bool = true,
    alpha: bool = true,
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

pub const RenderPassTimestampLocation = enum {
    beginning,
    end,
};

pub const RenderPassTimestampWrite = struct {
    quert_set: QuerySet,
    query_index: u32,
    location: RenderPassTimestampLocation,
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

pub const TextureUsage = packed struct {
    copy_src: bool = false,
    copy_dst: bool = false,
    texture_binding: bool = false,
    storage_binding: bool = false,
    render_attachment: bool = false,
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

pub const AddressMode = enum {
    clamp_to_edge,
    repeat,
    mirror_repeat,
};

pub const FilterMode = enum {
    nearest,
    linear,
};

pub const TextureAspect = enum {
    all,
    stencil_only,
    depth_only,
};

pub const Extent3d = struct {
    width: u32,
    height: u32,
    depth_or_array_layers: u32 = 1,
};

pub const Origin3d = struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

pub const AdapterDesc = api.AdapterDesc;
pub const LimitsDesc = api.LimitsDesc;
pub const DeviceDesc = api.DeviceDesc;
pub const SwapchainDesc = api.SwapchainDesc;
pub const PipelineLayoutDesc = api.PipelineLayoutDesc;
pub const VertexAttributeDesc = api.VertexAttributeDesc;
pub const VertexBufferLayoutDesc = api.VertexBufferLayoutDesc;
pub const VertexStateDesc = api.VertexStateDesc;
pub const BlendComponentDesc = api.BlendComponentDesc;
pub const BlendStateDesc = api.BlendStateDesc;
pub const ColorTargetStateDesc = api.ColorTargetStateDesc;
pub const FragmentStateDesc = api.FragmentStateDesc;
pub const RenderPipelineDesc = api.RenderPipelineDesc;
pub const ColorAttachmentDesc = api.ColorAttachmentDesc;
pub const DepthStencilAttachmentDesc = api.DepthStencilAttachmentDesc;
pub const RenderPassDesc = api.RenderPassDesc;
pub const BufferDesc = api.BufferDesc;
pub const TextureDesc = api.TextureDesc;
pub const BindGroupLayoutDesc = api.BindGroupLayoutDesc;
pub const BindGroupDesc = api.BindGroupDesc;
pub const SamplerDesc = api.SamplerDesc;
pub const ImageCopyTextureDesc = api.ImageCopyTextureDesc;
pub const ImageDataLayoutDesc = api.ImageDataLayoutDesc;

pub const Instance = api.Instance;
pub const Surface = api.Surface;
pub const Adapter = api.Adapter;
pub const Device = api.Device;
pub const Buffer = api.Buffer;
pub const Texture = api.Texture;
pub const TextureView = api.TextureView;
pub const Sampler = api.Sampler;
pub const Shader = api.Shader;
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

pub const Context = struct {
    window: *const app.Window,
    instance: Instance,
    surface: Surface,
    adapter: Adapter,
    device: Device,
    swapchain_format: TextureFormat,
    swapchain: Swapchain,

    pub fn init(
        window: *const app.Window,
        adapter_desc: AdapterDesc,
        device_desc: DeviceDesc,
    ) !Context {
        var context: Context = undefined;
        context.window = window;
        context.instance = try Instance.init();
        context.surface = try context.instance.createSurface(window.*);
        context.adapter = try context.instance.requestAdapter(adapter_desc);
        context.device = try context.adapter.requestDevice(device_desc);
        context.swapchain_format = context.surface.getPreferredFormat(context.adapter);
        const swapchain_desc = SwapchainDesc.init()
            .size(.{ .width = window.width, .height = window.height })
            .format(context.swapchain_format);
        defer swapchain_desc.deinit();
        context.swapchain = try context.device.createSwapchain(context.surface, swapchain_desc);
        return context;
    }

    pub fn deinit(context: *Context) void {
        context.swapchain.destroy();
        context.device.destroy();
        context.adapter.destroy();
        context.surface.destroy();
        context.instance.deinit();
    }
};
