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
        bytes_ptr: [*]const u8,
        bytes_len: usize,
    ) void;
    extern fn requestAdapter(wasm_id: main.WasmId, bytes_ptr: [*]const u8, bytes_len: usize) void;
    extern fn destroyAdapter(adapter_id: AdapterId) void;
    extern fn requestDevice(
        wasm_id: main.WasmId,
        adapter_id: AdapterId,
        bytes_ptr: [*]const u8,
        bytes_len: usize,
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
        desc_bytes_ptr: [*]const u8,
        desc_bytes_len: usize,
    ) BindGroupLayoutId;
    extern fn destroyBindGroupLayout(bind_group_layout_id: BindGroupLayoutId) void;
    extern fn createBindGroup(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_ptr: [*]const u8,
        desc_len: usize,
    ) BindGroupId;
    extern fn destroyBindGroup(bind_group_id: BindGroupId) void;
    extern fn createPipelineLayout(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_ptr: [*]const u8,
        desc_len: usize,
    ) PipelineLayoutId;
    extern fn destroyPipelineLayout(pipeline_layout_id: PipelineLayoutId) void;
    extern fn createRenderPipeline(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        bytes_ptr: [*]const u8,
        bytes_len: usize,
    ) RenderPipelineId;
    extern fn destroyRenderPipeline(render_pipeline_id: RenderPipelineId) void;
    extern fn createCommandEncoder(device_id: DeviceId) CommandEncoderId;
    extern fn finishCommandEncoder(command_encoder_id: CommandEncoderId) CommandBufferId;
    extern fn beginRenderPass(
        wasm_id: main.WasmId,
        command_encoder_id: CommandEncoderId,
        bytes_ptr: [*]const u8,
        bytes_len: usize,
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
        texture_id: TextureId,
        mip_level: GPUIntegerCoordinate,
        origin_x: GPUIntegerCoordinate,
        origin_y: GPUIntegerCoordinate,
        origin_z: GPUIntegerCoordinate,
        aspect_ptr: [*]const u8,
        aspect_len: usize,
        data_ptr: [*]const u8,
        data_len: usize,
        layout_offset: GPUSize64,
        layout_bytes_per_row: GPUSize32,
        layout_rows_per_image: GPUSize32,
        size_width: GPUIntegerCoordinate,
        size_height: GPUIntegerCoordinate,
        size_depth_or_array_layers: GPUIntegerCoordinate,
    ) void;
    extern fn createBuffer(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_bytes_ptr: [*]const u8,
        desc_bytes_len: usize,
        init_data_ptr: [*]const u8,
        init_data_len: usize,
    ) BufferId;
    extern fn destroyBuffer(buffer_id: BufferId) void;
    extern fn createTexture(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_bytes_ptr: [*]const u8,
        desc_bytes_len: usize,
    ) TextureId;
    extern fn destroyTexture(texture_id: TextureId) void;
    extern fn createSampler(
        wasm_id: main.WasmId,
        device_id: DeviceId,
        desc_bytes_ptr: [*]const u8,
        desc_bytes_len: usize,
    ) SamplerId;
    extern fn destroySampler(sampler_id: SamplerId) void;
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
        var bytes_buf: [128]u8 = undefined;
        const bytes = try jsSerialize(desc, &bytes_buf);
        js.requestAdapter(main.wasm_id, bytes.ptr, bytes.len);
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
        var bytes_buf: [1024]u8 = undefined;
        const bytes = try jsSerialize(desc, &bytes_buf);
        js.requestDevice(main.wasm_id, adapter.id, bytes.ptr, bytes.len);
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
        var bytes_buf: [128]u8 = undefined;
        const bytes = try jsSerialize(desc, &bytes_buf);
        js.configure(
            main.wasm_id,
            device.id,
            swapchain.id,
            bytes.ptr,
            bytes.len,
        );
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
        var desc_bytes_buf: [128]u8 = undefined;
        var desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        return BindGroupLayout{
            .id = js.createBindGroupLayout(
                main.wasm_id,
                device.id,
                desc_bytes.ptr,
                desc_bytes.len,
            ),
        };
    }

    pub fn createBindGroup(
        device: *Device,
        desc: gfx.BindGroupDesc,
    ) !BindGroup {
        var desc_bytes_buf: [1024]u8 = undefined;
        const desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        return BindGroup{
            .id = js.createBindGroup(
                main.wasm_id,
                device.id,
                desc_bytes.ptr,
                desc_bytes.len,
            ),
        };
    }

    pub fn createPipelineLayout(
        device: *Device,
        desc: gfx.PipelineLayoutDesc,
    ) !PipelineLayout {
        var desc_bytes_buf: [128]u8 = undefined;
        const desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        return PipelineLayout{
            .id = js.createPipelineLayout(
                main.wasm_id,
                device.id,
                desc_bytes.ptr,
                desc_bytes.len,
            ),
        };
    }

    pub fn createRenderPipeline(
        device: *Device,
        desc: gfx.RenderPipelineDesc,
    ) !RenderPipeline {
        var bytes_buf: [1024]u8 = undefined;
        const bytes = try jsSerialize(desc, &bytes_buf);
        return RenderPipeline{
            .id = js.createRenderPipeline(
                main.wasm_id,
                device.id,
                bytes.ptr,
                bytes.len,
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
        var desc_bytes_buf: [128]u8 = undefined;
        const desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        const init_data = data orelse &[_]u8{};
        return Buffer{
            .id = js.createBuffer(
                main.wasm_id,
                device.id,
                desc_bytes.ptr,
                desc_bytes.len,
                init_data.ptr,
                init_data.len,
            ),
        };
    }

    pub fn createTexture(
        device: *Device,
        desc: gfx.TextureDesc,
    ) !Texture {
        var desc_bytes_buf: [128]u8 = undefined;
        const desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        return Texture{
            .id = js.createTexture(
                main.wasm_id,
                device.id,
                desc_bytes.ptr,
                desc_bytes.len,
            ),
        };
    }

    pub fn createSampler(device: *Device, desc: gfx.SamplerDesc) !Sampler {
        var desc_bytes_buf: [128]u8 = undefined;
        const desc_bytes = try jsSerialize(desc, &desc_bytes_buf);
        return Sampler{ .id = js.createSampler(
            main.wasm_id,
            device.id,
            desc_bytes.ptr,
            desc_bytes.len,
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
        var buf: [128]u8 = undefined;
        const index_format_name = jsSerializeEnumName(index_format, &buf) catch unreachable;
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
        var bytes_buf: [2048]u8 = undefined;
        const bytes = try jsSerialize(desc, &bytes_buf);
        return RenderPass{
            .id = js.beginRenderPass(
                main.wasm_id,
                command_encoder.id,
                bytes.ptr,
                bytes.len,
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
        destination: gfx.ImageCopyTexture,
        data: []const u8,
        data_layout: gfx.ImageDataLayout,
        size: gfx.Extent3d,
    ) void {
        var aspect_name_buf: [128]u8 = undefined;
        const aspect_name = jsSerializeEnumName(destination.aspect, &aspect_name_buf) catch unreachable;
        js.queueWriteTexture(
            main.wasm_id,
            queue.id,
            destination.texture.id,
            destination.mip_level,
            destination.origin.x,
            destination.origin.y,
            destination.origin.z,
            aspect_name.ptr,
            aspect_name.len,
            data.ptr,
            data.len,
            data_layout.offset,
            data_layout.bytes_per_row,
            data_layout.rows_per_image,
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

fn jsSerialize(value: anytype, bytes: []u8) ![]u8 {
    const bytes_begin = bytes;
    var bytes_end = bytes;
    try jsSerializeRef(value, &bytes_end);
    return bytes_begin[0..(@ptrToInt(bytes_end.ptr) - @ptrToInt(bytes_begin.ptr))];
}

fn jsSerializeRef(value: anytype, bytes: *[]u8) !void {
    const bool_marker: u8 = 'b';
    const int_marker: u8 = 'i';
    const float_marker: u8 = 'f';
    const string_marker: u8 = 's';
    const slice_marker: u8 = 'a';
    const struct_begin_marker: u8 = 'o';
    const struct_end_marker: u8 = 'e';
    const union_marker: u8 = 'u';
    const max_enum_name_len: usize = 32;
    const max_field_name_len: usize = 32;

    switch (@typeInfo(@TypeOf(value))) {
        .Bool => {
            try jsSerializeBytes(std.mem.asBytes(&bool_marker), bytes);
            try jsSerializeBytes(std.mem.asBytes(&value), bytes);
        },
        .Int => {
            try jsSerializeBytes(std.mem.asBytes(&int_marker), bytes);
            try jsSerializeBytes(std.mem.asBytes(&@intCast(u32, value)), bytes);
        },
        .Float => {
            try jsSerializeBytes(std.mem.asBytes(&float_marker), bytes);
            try jsSerializeBytes(std.mem.asBytes(&@floatCast(f32, value)), bytes);
        },
        .Enum => {
            var buf: [max_enum_name_len]u8 = undefined;
            try jsSerializeRef(try jsSerializeEnumName(value, &buf), bytes);
        },
        .Optional => {
            try jsSerializeRef(value.?, bytes);
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => try jsSerializeRef(value.*, bytes),
                .Slice => {
                    const value_len = @intCast(u32, value.len);
                    if (P.child == u8) {
                        try jsSerializeBytes(std.mem.asBytes(&string_marker), bytes);
                        try jsSerializeBytes(std.mem.asBytes(&value_len), bytes);
                        try jsSerializeBytes(value, bytes);
                    } else {
                        try jsSerializeBytes(std.mem.asBytes(&slice_marker), bytes);
                        try jsSerializeBytes(std.mem.asBytes(&value_len), bytes);
                        for (value) |v| {
                            try jsSerializeRef(v, bytes);
                        }
                    }
                },
                else => return error.InvalidPointerSize,
            }
        },
        .Array => {
            try jsSerializeRef(&value, bytes);
        },
        .Struct => |S| {
            if (S.layout == .Packed) {
                try jsSerializeRef(try jsSerializeFlags(value), bytes);
            } else {
                try jsSerializeBytes(std.mem.asBytes(&struct_begin_marker), bytes);
                inline for (S.fields) |field| {
                    var field_is_defined = if (field.default_value) |def_val_ptr| block: {
                        const def_val = @ptrCast(*const field.field_type, def_val_ptr).*;
                        break :block !std.meta.eql(@field(value, field.name), def_val);
                    } else true;

                    if (field_is_defined) {
                        @setEvalBranchQuota(10000);
                        comptime var buf: [max_field_name_len]u8 = undefined;
                        try jsSerializeRef(
                            comptime try jsSerializeFieldName(field.name, &buf),
                            bytes,
                        );
                        try jsSerializeRef(@field(value, field.name), bytes);
                    }
                }
                try jsSerializeBytes(std.mem.asBytes(&struct_end_marker), bytes);
            }
        },
        .Union => |U| {
            try jsSerializeBytes(std.mem.asBytes(&union_marker), bytes);
            try jsSerializeRef(@enumToInt(std.meta.activeTag(value)), bytes);
            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    try jsSerializeRef(@field(value, field.name), bytes);
                    break;
                }
            }
        },
        else => {
            return error.InvalidType;
        },
    }
}

fn jsSerializeBytes(value_bytes: []const u8, bytes: *[]u8) !void {
    if (bytes.len < value_bytes.len) {
        return error.OutOfMemory;
    }
    std.mem.copy(u8, bytes.*, value_bytes);
    bytes.* = bytes.*[value_bytes.len..];
}

fn jsSerializeEnumName(value: anytype, buf: []u8) ![]const u8 {
    const name = @tagName(value);
    if (buf.len < name.len) {
        return error.InvalidBufLen;
    }
    for (name) |byte, i| {
        buf[i] = if (byte == '_') '-' else byte;
    }
    return buf[0..name.len];
}

fn jsSerializeFieldName(value: []const u8, buf: []u8) ![]const u8 {
    if (buf.len < value.len) {
        return error.InvalidBufLen;
    }
    var i: usize = 0;
    var next_is_upper: bool = false;
    for (value) |byte| {
        if (byte == '_') {
            next_is_upper = true;
        } else {
            buf[i] = if (next_is_upper) std.ascii.toUpper(byte) else byte;
            next_is_upper = false;
            i += 1;
        }
    }
    return buf[0..i];
}

fn jsSerializeFlags(value: anytype) !u32 {
    const Type = @TypeOf(value);
    if (@typeInfo(Type) != .Struct or @typeInfo(Type).Struct.layout != .Packed) {
        return error.InvalidFlagsType;
    }
    const IntType = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = @bitSizeOf(Type) } });
    return @intCast(u32, @bitCast(IntType, value));
}
