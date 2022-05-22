const api = switch (cfg.platform) {
    .web => @import("gfx_web.zig"),
};
const bake = @import("bake.zig");
const cfg = @import("cfg");
const res = @import("res.zig");
const std = @import("std");
const wnd = @import("wnd.zig");

pub const ContextDesc = struct {
    window: *const wnd.Window,
    adapter_desc: AdapterDesc = .{},
    device_desc: DeviceDesc = .{},
};

pub const Context = struct {
    window: *const wnd.Window,
    instance: Instance,
    surface: Surface,
    adapter: Adapter,
    device: Device,
    swapchain: Swapchain,
    swapchain_format: TextureFormat,
    clear_color: Color,
    depth_texture: Texture,
    depth_texture_format: TextureFormat,
    depth_texture_view: TextureView,

    pub fn init(desc: ContextDesc) !Context {
        var instance = try Instance.init();
        var surface = try instance.initSurface(desc.window);
        var adapter = try instance.initAdapter(desc.adapter_desc);
        var device = try adapter.initDevice(desc.device_desc);
        const swapchain_format = try surface.getPreferredFormat();
        const swapchain = try device.initSwapchain(&surface, .{
            .size = .{ .width = desc.window.getWidth(), .height = desc.window.getHeight() },
            .format = swapchain_format,
        });
        const clear_color = .{ .r = 0.32, .g = 0.1, .b = 0.18, .a = 1.0 };
        const depth_texture_format = .depth24plus;
        var depth_texture = try device.initTexture(.{
            .size = .{ .width = desc.window.getWidth(), .height = desc.window.getHeight() },
            .format = depth_texture_format,
            .usage = .{ .render_attachment = true },
        });
        const depth_texture_view = try device.initTextureView(.{
            .texture = &depth_texture,
            .format = depth_texture_format,
        });

        return Context{
            .window = desc.window,
            .instance = instance,
            .surface = surface,
            .adapter = adapter,
            .device = device,
            .swapchain = swapchain,
            .swapchain_format = swapchain_format,
            .clear_color = clear_color,
            .depth_texture = depth_texture,
            .depth_texture_format = depth_texture_format,
            .depth_texture_view = depth_texture_view,
        };
    }

    pub fn deinit(ctx: *Context) void {
        ctx.device.deinitTextureView(&ctx.depth_texture_view);
        ctx.device.deinitTexture(&ctx.depth_texture);
        ctx.device.deinitSwapchain(&ctx.swapchain);
        ctx.adapter.deinitDevice(&ctx.device);
        ctx.instance.deinitAdapter(&ctx.adapter);
        ctx.instance.deinitSurface(&ctx.surface);
        ctx.instance.deinit();
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

    pub fn initSurface(instance: *Instance, window: *const wnd.Window) !Surface {
        return Surface{ .impl = try instance.impl.initSurface(window) };
    }

    pub fn deinitSurface(instance: *Instance, surface: *Surface) void {
        instance.impl.deinitSurface(&surface.impl);
    }

    pub fn initAdapter(instance: *Instance, desc: AdapterDesc) !Adapter {
        return Adapter{ .impl = try instance.impl.initAdapter(desc) };
    }

    pub fn deinitAdapter(instance: *Instance, adapter: *Adapter) void {
        instance.impl.deinitAdapter(&adapter.impl);
    }
};

pub const Surface = struct {
    impl: api.Surface,

    pub fn getPreferredFormat(surface: *Surface) !TextureFormat {
        return try surface.impl.getPreferredFormat();
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

    pub fn initDevice(adapter: *Adapter, desc: DeviceDesc) !Device {
        return Device{ .impl = try adapter.impl.initDevice(desc) };
    }

    pub fn deinitDevice(adapter: *Adapter, device: *Device) void {
        adapter.impl.deinitDevice(&device.impl);
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

    pub fn initSwapchain(device: *Device, surface: *Surface, desc: SwapchainDesc) !Swapchain {
        return Swapchain{ .impl = try device.impl.initSwapchain(&surface.impl, desc) };
    }

    pub fn deinitSwapchain(device: *Device, swapchain: *Swapchain) void {
        device.impl.deinitSwapchain(&swapchain.impl);
    }

    pub fn initShader(device: *Device, shader_res: bake.ShaderRes) !Shader {
        return Shader{ .impl = try device.impl.initShader(shader_res) };
    }

    pub fn loadShader(device: *Device, comptime r: res.Res, desc: res.LoadDesc) !Shader {
        const shader_res = try res.load(r, desc);
        return try device.initShader(shader_res);
    }

    pub fn deinitShader(device: *Device, shader: *Shader) void {
        device.impl.deinitShader(&shader.impl);
    }

    pub fn initBuffer(device: *Device, desc: BufferDesc) !Buffer {
        return Buffer{ .impl = try device.impl.initBuffer(desc) };
    }

    pub fn initBufferSlice(device: *Device, slice: anytype, usage: BufferUsage) !Buffer {
        const bytes = std.mem.sliceAsBytes(slice);
        return try device.initBuffer(.{ .size = bytes.len, .usage = usage, .data = bytes });
    }

    pub fn deinitBuffer(device: *Device, buffer: *Buffer) void {
        device.impl.deinitBuffer(&buffer.impl);
    }

    pub fn initTexture(device: *Device, desc: TextureDesc) !Texture {
        return Texture{ .impl = try device.impl.initTexture(desc) };
    }

    pub fn deinitTexture(device: *Device, texture: *Texture) void {
        device.impl.deinitTexture(&texture.impl);
    }

    pub fn initTextureView(device: *Device, desc: TextureViewDesc) !TextureView {
        return TextureView{ .impl = try device.impl.initTextureView(desc) };
    }

    pub fn deinitTextureView(device: *Device, texture_view: *TextureView) void {
        device.impl.deinitTextureView(&texture_view.impl);
    }

    pub fn initSampler(device: *Device, desc: SamplerDesc) !Sampler {
        return Sampler{ .impl = try device.impl.initSampler(desc) };
    }

    pub fn deinitSampler(device: *Device, sampler: *Sampler) void {
        device.impl.deinitSampler(&sampler.impl);
    }

    pub fn initBindGroupLayout(device: *Device, desc: BindGroupLayoutDesc) !BindGroupLayout {
        return BindGroupLayout{ .impl = try device.impl.initBindGroupLayout(desc) };
    }

    pub fn deinitBindGroupLayout(device: *Device, bind_group_layout: *BindGroupLayout) void {
        device.impl.deinitBindGroupLayout(&bind_group_layout.impl);
    }

    pub fn initBindGroup(device: *Device, desc: BindGroupDesc) !BindGroup {
        return BindGroup{ .impl = try device.impl.initBindGroup(desc) };
    }

    pub fn deinitBindGroup(device: *Device, bind_group: *BindGroup) void {
        device.impl.deinitBindGroup(&bind_group.impl);
    }

    pub fn initPipelineLayout(device: *Device, desc: PipelineLayoutDesc) !PipelineLayout {
        return PipelineLayout{ .impl = try device.impl.initPipelineLayout(desc) };
    }

    pub fn deinitPipelineLayout(device: *Device, pipeline_layout: *PipelineLayout) void {
        device.impl.deinitPipelineLayout(&pipeline_layout.impl);
    }

    pub fn initRenderPipeline(device: *Device, desc: RenderPipelineDesc) !RenderPipeline {
        return RenderPipeline{ .impl = try device.impl.initRenderPipeline(desc) };
    }

    pub fn deinitRenderPipeline(device: *Device, render_pipeline: *RenderPipeline) void {
        device.impl.deinitRenderPipeline(&render_pipeline.impl);
    }

    pub fn initCommandEncoder(device: *Device) !CommandEncoder {
        return CommandEncoder{ .impl = try device.impl.initCommandEncoder() };
    }

    pub fn getQueue(device: *Device) Queue {
        return Queue{ .impl = device.impl.getQueue() };
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

pub const whole_size = std.math.maxInt(usize);

pub const BufferDesc = struct {
    size: usize,
    usage: BufferUsage,
    data: ?[]const u8 = null,
};

pub const Buffer = struct {
    impl: api.Buffer,
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
};

pub const TextureAspect = enum {
    all,
    stencil_only,
    depth_only,
};

pub const TextureViewDesc = struct {
    texture: *Texture,
    format: TextureFormat,
    dimension: TextureViewDimension = .@"2d",
    aspect: TextureAspect = .all,
    base_mip_level: u32 = 0,
    mip_level_count: u32 = 1,
    base_array_layer: u32 = 0,
    array_layer_count: u32 = 1,
};

pub const TextureView = struct {
    impl: api.TextureView,
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
    lod_min_clamp: f32 = 0.0,
    lod_max_clamp: f32 = 32.0,
    max_anisotropy: u16 = 1,
    compare: ?CompareFunction = null,
};

pub const Sampler = struct {
    impl: api.Sampler,
};

pub const BufferBindingType = enum {
    uniform,
    storage,
    read_only_storage,
};

pub const BufferBindingLayout = struct {
    @"type": BufferBindingType = .uniform,
    has_dynamic_offset: bool = false,
    min_binding_size: usize = 0,
};

pub const TextureSampleType = enum {
    float,
    unfilterable_float,
    depth,
    sint,
    uint,
};

pub const TextureBindingLayout = struct {
    sample_type: TextureSampleType = .float,
    view_dimension: TextureViewDimension = .@"2d",
    multisampled: bool = false,
};

pub const StorageTextureAccess = enum {
    write_only,
};

pub const StorageTextureBindingLayout = struct {
    format: TextureFormat,
    access: StorageTextureAccess = .write_only,
    view_dimension: TextureViewDimension = .@"2d",
};

pub const SamplerBindingType = enum {
    filtering,
    non_filtering,
    comparison,
};

pub const SamplerBindingLayout = struct {
    @"type": SamplerBindingType = .filtering,
};

pub const BindGroupLayoutEntry = struct {
    binding: u32,
    visibility: ShaderStage,
    buffer: ?BufferBindingLayout = null,
    texture: ?TextureBindingLayout = null,
    storage_texture: ?StorageTextureBindingLayout = null,
    sampler: ?SamplerBindingLayout = null,
};

pub const BindGroupLayoutDesc = struct {
    entries: []const BindGroupLayoutEntry,
};

pub const BindGroupLayout = struct {
    impl: api.BindGroupLayout,
};

pub const BufferBinding = struct {
    buffer: *const Buffer,
    offset: usize = 0,
    size: usize = whole_size,
};

pub const BindingResource = union(enum) {
    buffer_binding: BufferBinding,
    texture_view: *const TextureView,
    sampler: *const Sampler,
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
};

pub const PipelineLayoutDesc = struct {
    bind_group_layouts: []const BindGroupLayout,
};

pub const PipelineLayout = struct {
    impl: api.PipelineLayout,
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

pub fn getVertexBufferLayoutStruct(
    comptime Type: type,
    comptime step_mode: VertexStepMode,
    comptime base_location: u32,
) VertexBufferLayout {
    comptime var types: []const type = &.{};
    inline for (@typeInfo(Type).Struct.fields) |field| {
        types = types ++ &[_]type{field.field_type};
    }
    return getVertexBufferLayoutTypes(types, step_mode, base_location);
}

pub fn getVertexBufferLayoutTypes(
    comptime types: []const type,
    comptime step_mode: VertexStepMode,
    comptime base_location: u32,
) VertexBufferLayout {
    comptime var attributes: []const VertexAttribute = &.{};
    comptime var offset: usize = 0;
    comptime var location: u32 = base_location;

    inline for (types) |Type| {
        attributes = attributes ++ &[_]VertexAttribute{
            .{ .format = getVertexFormat(Type), .offset = offset, .shader_location = location },
        };

        if (offset % @sizeOf(Type) != 0) {
            @compileError("Invalid alignment for vertex buffer layout!");
        }

        offset += @sizeOf(Type);
        location += 1;
    }

    return VertexBufferLayout{
        .array_stride = offset,
        .step_mode = step_mode,
        .attributes = attributes,
    };
}

fn getVertexFormat(comptime Type: type) VertexFormat {
    return switch (@typeInfo(Type)) {
        .Int, .ComptimeInt, .Float, .ComptimeFloat => getVertexFormatWithLen(Type, 1),
        .Array => |A| getVertexFormatWithLen(A.child, A.len),
        .Vector => |V| getVertexFormatWithLen(V.child, V.len),
        .Struct => |S| block: {
            if (S.fields.len == 0 or S.fields.len > 4) {
                @compileError("Invalid number of fields for vertex attribute!");
            }
            const field_type = S.fields[0].field_type;
            if (@typeInfo(field_type) != .Int and @typeInfo(field_type) != .Float) {
                @compileError("Vertex attribute structs must be composed of ints or floats!");
            }
            inline for (S.fields) |field| {
                if (field.field_type != field_type) {
                    @compileError("Vertex attribute fields must be homogenous!");
                }
            }
            break :block getVertexFormatWithLen(field_type, S.fields.len);
        },
        else => @compileError("Invalid vertex attribute type " ++ @typeName(Type) ++ "!"),
    };
}

fn getVertexFormatWithLen(comptime Type: type, len: comptime_int) VertexFormat {
    return switch (@typeInfo(Type)) {
        .Int => |I| switch (I.signedness) {
            .signed => switch (I.bits) {
                8 => switch (len) {
                    2 => .sint8x2,
                    4 => .sint8x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                16 => switch (len) {
                    2 => .sint16x2,
                    4 => .sint16x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                32 => switch (len) {
                    1 => .sint32,
                    2 => .sint32x2,
                    3 => .sint32x3,
                    4 => .sint32x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                else => @compileError("Invalid bit size for vertex attribute!"),
            },
            .unsigned => switch (I.bits) {
                8 => switch (len) {
                    2 => .uint8x2,
                    4 => .uint8x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                16 => switch (len) {
                    2 => .uint16x2,
                    4 => .uint16x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                32 => switch (len) {
                    1 => .uint32,
                    2 => .uint32x2,
                    3 => .uint32x3,
                    4 => .uint32x4,
                    else => @compileError("Invalid len for vertex attribute!"),
                },
                else => @compileError("Invalid bit size for vertex attribute!"),
            },
        },
        .Float => |F| switch (F.bits) {
            16 => switch (len) {
                2 => .float16x2,
                4 => .float16x4,
                else => @compileError("Invalid len for vertex attribute"),
            },
            32 => switch (len) {
                1 => .float32,
                2 => .float32x2,
                3 => .float32x3,
                4 => .float32x4,
                else => @compileError("Invalid len for vertex attribute"),
            },
            else => @compileError("Invalid bit size for vertex attribute!"),
        },
        else => @compileError("Invalid vertex attribute type " ++ @typeName(Type) ++ "!"),
    };
}

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
    depth_bias: i32 = 0,
    depth_bias_clamp: f32 = 0.0,
    depth_bias_slope_scale: f32 = 0.0,
    stencil_front: StencilFaceState = .{},
    stencil_back: StencilFaceState = .{},
    stencil_read_mask: u32 = 0xFFFFFFFF,
    stencil_write_mask: u32 = 0xFFFFFFFF,
};

pub const MultisampleState = struct {
    count: u32 = 1,
    mask: u32 = 0xFFFFFFFF,
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

pub const ColorWrite = packed struct {
    red: bool = false,
    green: bool = false,
    blue: bool = false,
    alpha: bool = false,

    pub const all = ColorWrite{ .red = true, .green = true, .blue = true, .alpha = true };
};

pub const ColorTargetState = struct {
    format: TextureFormat,
    blend: BlendState = .{},
    write_mask: ColorWrite = ColorWrite.all,
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

    pub fn setMultisampleState(
        desc: *RenderPipelineDesc,
        multisample_state: MultisampleState,
    ) void {
        desc.impl.setMultisampleState(multisample_state);
    }

    pub fn setFragmentState(desc: *RenderPipelineDesc, fragment_state: FragmentState) void {
        desc.impl.setFragmentState(fragment_state);
    }
};

pub const RenderPipeline = struct {
    impl: api.RenderPipeline,
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
    resolve_target: ?*const TextureView = null,
    load_op: LoadOp,
    store_op: StoreOp,
    clear_value: Color = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
};

pub const DepthStencilAttachment = struct {
    view: *const TextureView,
    depth_clear_value: f32 = 0.0,
    depth_load_op: ?LoadOp = null,
    depth_store_op: ?StoreOp = null,
    depth_read_only: bool = false,
    stencil_clear_value: u32 = 0,
    stencil_load_op: ?LoadOp = null,
    stencil_store_op: ?StoreOp = null,
    stencil_read_only: bool = false,
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
