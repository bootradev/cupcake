const std = @import("std");

const serde_usize = u64;

const SerdeError = error{
    OutOfMemory,
    AllocatorRequired,
};

pub fn serialize(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    const Type = @TypeOf(value);
    if (@hasDecl(Type, "serialize")) {
        return try Type.serialize(allocator, value);
    } else {
        const bytes = allocator.alloc(u8, serializeSize(value)) catch return error.OutOfMemory;
        _ = serializeBytes(value, bytes);
        return bytes;
    }
}

fn serializeBytes(value: anytype, bytes: []u8) []u8 {
    var out_bytes = bytes;
    switch (@typeInfo(@TypeOf(value))) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => {
            const value_bytes = std.mem.toBytes(value);
            std.mem.copy(u8, out_bytes, &value_bytes);
            out_bytes = out_bytes[value_bytes.len..];
        },
        .Optional => {
            if (value) |v| {
                out_bytes = serializeBytes(true, out_bytes);
                out_bytes = serializeBytes(v, out_bytes);
            } else {
                out_bytes = serializeBytes(false, out_bytes);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => out_bytes = serializeBytes(value.*, out_bytes),
                .Slice => {
                    out_bytes = serializeBytes(@intCast(serde_usize, value.len), out_bytes);
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => {
                            const value_bytes = std.mem.sliceAsBytes(value);
                            std.mem.copy(u8, out_bytes, value_bytes);
                            out_bytes = out_bytes[value_bytes.len..];
                        },
                        else => {
                            for (value) |v| {
                                out_bytes = serializeBytes(v, out_bytes);
                            }
                        },
                    }
                    if (P.sentinel) |s| {
                        out_bytes = serializeBytes(s, out_bytes);
                    }
                },
                else => |E| {
                    @compileError("Cannot serialize pointer size " ++ @tagName(E) ++ "!");
                },
            }
        },
        .Array => |A| {
            switch (@typeInfo(A.child)) {
                .Bool, .Int, .Float, .Enum => {
                    const value_bytes = std.mem.sliceAsBytes(value[0..]);
                    std.mem.copy(u8, out_bytes, value_bytes);
                    out_bytes = out_bytes[value_bytes.len..];
                },
                else => {
                    for (value) |v| {
                        out_bytes = serializeBytes(v, out_bytes);
                    }
                },
            }
            if (A.sentinel) |s| {
                out_bytes = serializeBytes(s, out_bytes);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                out_bytes = serializeBytes(@field(value, field.name), out_bytes);
            }
        },
        .Union => |U| {
            const UnionTagType = U.tag_type orelse
                @compileError("Cannot serialize a union without a tag type!");
            const tag = std.meta.activeTag(value);
            out_bytes = serializeBytes(tag, out_bytes);
            inline for (U.fields) |field| {
                if (@field(UnionTagType, field.name) == tag) {
                    out_bytes = serializeBytes(@field(value, field.name), out_bytes);
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot serialize type " ++ @tagName(E) ++ "!"),
    }
    return out_bytes;
}

pub fn serializeSize(value: anytype) usize {
    var size: usize = 0;
    switch (@typeInfo(@TypeOf(value))) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => size += @sizeOf(@TypeOf(value)),
        .Optional => {
            size += @sizeOf(bool); // null flag
            if (value) |v| {
                size += serializeSize(v);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => size += serializeSize(value.*),
                .Slice => {
                    size += @sizeOf(serde_usize); // len
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => size += @sizeOf(P.child) * value.len,
                        else => {
                            for (value) |v| {
                                size += serializeSize(v);
                            }
                        },
                    }
                    if (P.sentinel) |s| {
                        size += serializeSize(s);
                    }
                },
                else => |E| {
                    @compileError("Cannot serialize pointer size " ++ @tagName(E) ++ "!");
                },
            }
        },
        .Array => |A| {
            switch (@typeInfo(A.child)) {
                .Bool, .Int, .Float, .Enum => size += @sizeOf(A.child) * value.len,
                else => {
                    for (value) |v| {
                        size += serializeSize(v);
                    }
                },
            }
            if (A.sentinel) |s| {
                size += serializeSize(s);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                size += serializeSize(@field(value, field.name));
            }
        },
        .Union => |U| {
            const UnionTagType = U.tag_type orelse
                @compileError("Cannot serialize a union without a tag type!");
            const tag = std.meta.activeTag(value);
            size += @sizeOf(UnionTagType);
            inline for (U.fields) |field| {
                if (@field(UnionTagType, field.name) == tag) {
                    size += serializeSize(@field(value, field.name));
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot serialize type " ++ @tagName(E) ++ "!"),
    }

    return size;
}

pub const DeserializeDesc = struct {
    allocator: ?std.mem.Allocator = null,
    bytes_are_embedded: bool = false,
};

pub fn deserialize(desc: DeserializeDesc, comptime Type: type, bytes: []const u8) !Type {
    if (@hasDecl(Type, "deserialize")) {
        return try Type.deserialize(desc, bytes);
    } else {
        var value: Type = undefined;
        _ = try deserializeBytes(desc, &value, bytes);
        return value;
    }
}

pub fn deserializeBytes(
    desc: DeserializeDesc,
    value: anytype,
    bytes: []const u8,
) SerdeError![]const u8 {
    var in_bytes = bytes;

    const Type = @typeInfo(@TypeOf(value)).Pointer.child;
    switch (@typeInfo(Type)) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => {
            value.* = std.mem.bytesAsSlice(Type, in_bytes[0..@sizeOf(Type)])[0];
            in_bytes = in_bytes[@sizeOf(Type)..];
        },
        .Optional => {
            var exists: bool = undefined;
            in_bytes = try deserializeBytes(desc, &exists, in_bytes);
            if (exists) {
                in_bytes = try deserializeBytes(desc, &value.*.?, in_bytes);
            } else {
                value.* = null;
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    if (desc.allocator) |a| {
                        var ptr = a.create(P.child) catch return error.OutOfMemory;
                        in_bytes = try deserializeBytes(desc, ptr, in_bytes);
                        value.* = ptr;
                    } else {
                        return error.AllocatorRequired;
                    }
                },
                .Slice => {
                    var serde_len: serde_usize = undefined;
                    in_bytes = try deserializeBytes(desc, &serde_len, in_bytes);

                    const len = @intCast(usize, serde_len);
                    if (desc.allocator) |a| {
                        var slice = a.alloc(P.child, len) catch return error.OutOfMemory;
                        switch (@typeInfo(P.child)) {
                            .Bool, .Int, .Float, .Enum => {
                                std.mem.copy(
                                    P.child,
                                    slice,
                                    std.mem.bytesAsSlice(
                                        P.child,
                                        in_bytes[0 .. len * @sizeOf(P.child)],
                                    ),
                                );
                                in_bytes = in_bytes[len * @sizeOf(P.child) ..];
                            },
                            else => {
                                for (slice) |*s| {
                                    in_bytes = try deserializeBytes(desc, s, in_bytes);
                                }
                            },
                        }
                        if (P.sentinel) |_| {
                            in_bytes = try deserializeBytes(desc, &slice[P.len], in_bytes);
                        }
                        value.* = slice;
                    } else if (P.is_const and desc.bytes_are_embedded) {
                        switch (@typeInfo(P.child)) {
                            .Bool, .Int, .Float, .Enum => {
                                value.* = std.mem.bytesAsSlice(
                                    P.child,
                                    in_bytes[0 .. len * @sizeOf(P.child)],
                                );
                                in_bytes = in_bytes[len * @sizeOf(P.child) ..];
                            },
                            else => return error.AllocatorRequired,
                        }
                    } else {
                        return error.AllocatorRequired;
                    }
                },
                else => |E| {
                    @compileError("Cannot deserialize pointer size " ++ @tagName(E));
                },
            }
        },
        .Array => |A| {
            switch (@typeInfo(A.child)) {
                .Bool, .Int, .Float, .Enum => {
                    std.mem.copy(
                        A.child,
                        value.*[0..],
                        std.mem.bytesAsSlice(
                            A.child,
                            bytes[0 .. A.len * @sizeOf(A.child)],
                        ),
                    );
                    in_bytes = in_bytes[A.len * @sizeOf(A.child) ..];
                },
                else => {
                    for (value.*) |*v| {
                        in_bytes = try deserializeBytes(desc, v, in_bytes);
                    }
                },
            }
            if (A.sentinel) |_| {
                in_bytes = try deserializeBytes(desc, &value.*[A.len], in_bytes);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                in_bytes = try deserializeBytes(desc, &@field(value.*, field.name), in_bytes);
            }
        },
        .Union => |U| {
            const UnionTagType = U.tag_type orelse
                @compileError("Cannot deserialize a union without a tag!");
            var tag: UnionTagType = undefined;
            in_bytes = try deserializeBytes(desc, &tag, in_bytes);
            inline for (U.fields) |field| {
                if (@field(UnionTagType, field.name) == tag) {
                    const UnionType = @TypeOf(@field(value.*, field.name));
                    var u: UnionType = undefined;
                    in_bytes = try deserializeBytes(desc, &u, in_bytes);
                    value.* = @unionInit(Type, field.name, u);
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot deserializeBytes desc, type " ++ @tagName(E)),
    }

    return in_bytes;
}

pub fn deserializeFree(allocator: std.mem.Allocator, value: anytype) void {
    switch (@typeInfo(@TypeOf(value))) {
        .Void, .Bool, .Int, .Float, .Enum => {},
        .Optional => {
            if (value) |v| {
                deserializeFree(allocator, v);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    deserializeFree(allocator, value.*);
                    allocator.destroy(value);
                },
                .Slice => {
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => {},
                        else => {
                            for (value) |v| {
                                deserializeFree(allocator, v);
                            }
                        },
                    }
                    allocator.free(value);
                },
                else => |E| {
                    @compileError("Cannot deserialize pointer size " ++ @tagName(E) ++ "!");
                },
            }
        },
        .Array => |A| {
            switch (@typeInfo(A.child)) {
                .Bool, .Int, .Float, .Enum => {},
                else => {
                    for (value) |v| {
                        deserializeFree(allocator, v);
                    }
                },
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                deserializeFree(allocator, @field(value, field.name));
            }
        },
        .Union => |U| {
            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    deserializeFree(allocator, @field(value, field.name));
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot deserialize type " ++ @tagName(E) ++ "!"),
    }
}

test "serde" {
    const TestEnum = enum {
        a_field,
        b_field,
        c_field,
    };

    const TestInnerStruct = struct {
        i32_field: i32 = -12,
        u64_field: u64 = 16,
    };

    const TestInnerUnion = union(enum) {
        f32_field: f32,
        void_field,
    };

    const TestStruct = struct {
        bool_field: bool = false,
        u32_field: u32 = 0,
        u64_field: u64 = 8,
        f32_field: f32 = 1.0,
        enum_field: TestEnum = .b_field,
        optional_field: ?f32 = null,
        ptr_field: *const f32,
        slice_field: []const u8,
        array_field: [2]u8 = [_]u8{ 1, 2 },
        struct_field: TestInnerStruct = .{},
        union_field: TestInnerUnion = .void_field,
    };

    const test_ptr = try std.testing.allocator.create(f32);
    defer std.testing.allocator.destroy(test_ptr);

    const test_slice = try std.testing.allocator.alloc(u8, 5);
    defer std.testing.allocator.free(test_slice);
    std.mem.copy(u8, test_slice, "hello");

    const value: TestStruct = .{
        .ptr_field = test_ptr,
        .slice_field = test_slice,
    };

    const bytes = try serialize(std.testing.allocator, value);
    defer std.testing.allocator.free(bytes);

    var deserialized_value = try deserialize(
        .{ .allocator = std.testing.allocator },
        TestStruct,
        bytes,
    );
    defer deserializeFree(std.testing.allocator, deserialized_value);

    try std.testing.expectEqual(value.bool_field, deserialized_value.bool_field);
    try std.testing.expectEqual(value.u32_field, deserialized_value.u32_field);
    try std.testing.expectEqual(value.u64_field, deserialized_value.u64_field);
    try std.testing.expectEqual(value.f32_field, deserialized_value.f32_field);
    try std.testing.expectEqual(value.enum_field, deserialized_value.enum_field);
    try std.testing.expectEqual(value.optional_field, deserialized_value.optional_field);
    try std.testing.expectEqual(value.ptr_field.*, deserialized_value.ptr_field.*);
    try std.testing.expectEqualSlices(u8, value.slice_field, deserialized_value.slice_field);
    try std.testing.expectEqualSlices(u8, &value.array_field, &deserialized_value.array_field);
    try std.testing.expectEqual(value.struct_field, deserialized_value.struct_field);
    try std.testing.expectEqual(value.union_field, deserialized_value.union_field);
}
