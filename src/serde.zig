const std = @import("std");

const serde_usize = u64;

const SerdeError = error{
    OutOfMemory,
    AllocatorRequired,
};

pub fn serialize(
    allocator: std.mem.Allocator,
    value: anytype,
) SerdeError![]const u8 {
    const Type = @TypeOf(value);
    const bytes = allocator.alloc(u8, serializeSize(Type, value)) catch return error.OutOfMemory;
    var index: usize = 0;
    serializeBytes(Type, value, bytes, &index);
    return bytes;
}

fn serializeBytes(comptime Type: type, value: Type, bytes: []u8, index: *usize) void {
    switch (@typeInfo(Type)) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => {
            const value_bytes = std.mem.toBytes(value);
            std.mem.copy(u8, bytes[index.*..], &value_bytes);
            index.* += value_bytes.len;
        },
        .Optional => |O| {
            if (value) |v| {
                serializeBytes(bool, true, bytes, index);
                serializeBytes(O.child, v, bytes, index);
            } else {
                serializeBytes(bool, false, bytes, index);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => serializeBytes(P.child, value.*, bytes, index),
                .Slice => {
                    serializeBytes(
                        serde_usize,
                        @intCast(serde_usize, value.len),
                        bytes,
                        index,
                    );
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => {
                            const value_bytes = std.mem.sliceAsBytes(value);
                            std.mem.copy(u8, bytes[index.*..], value_bytes);
                            index.* += value_bytes.len;
                        },
                        else => {
                            for (value) |v| {
                                serializeBytes(P.child, v, bytes, index);
                            }
                        },
                    }
                    if (P.sentinel) |s| {
                        serializeBytes(P.child, s, bytes, index);
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
                    std.mem.copy(u8, bytes[index.*..], value_bytes);
                    index.* += value_bytes.len;
                },
                else => {
                    for (value) |v| {
                        serializeBytes(A.child, v, bytes, index);
                    }
                },
            }
            if (A.sentinel) |s| {
                serializeBytes(A.child, s, bytes, index);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                serializeBytes(field.field_type, @field(value, field.name), bytes, index);
            }
        },
        .Union => |U| {
            if (U.tag_type) |T| {
                serializeBytes(T, std.meta.activeTag(value), bytes, index);
            } else {
                @compileError("Cannot serialize a union without a tag type!");
            }
            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    serializeBytes(field.field_type, @field(value, field.name), bytes, index);
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot serialize type " ++ @tagName(E) ++ "!"),
    }
}

pub fn serializeSize(comptime Type: type, value: Type) usize {
    var size: usize = 0;
    switch (@typeInfo(Type)) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => size += @sizeOf(Type),
        .Optional => |O| {
            size += @sizeOf(bool); // null flag
            if (value) |v| {
                size += serializeSize(O.child, v);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => size += serializeSize(P.child, value.*),
                .Slice => {
                    size += @sizeOf(serde_usize); // len
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => size += @sizeOf(P.child) * value.len,
                        else => {
                            for (value) |v| {
                                size += serializeSize(P.child, v);
                            }
                        },
                    }
                    if (P.sentinel) |s| {
                        size += serializeSize(P.child, s);
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
                        size += serializeSize(A.child, v);
                    }
                },
            }
            if (A.sentinel) |s| {
                size += serializeSize(A.child, s);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                size += serializeSize(field.field_type, @field(value, field.name));
            }
        },
        .Union => |U| {
            if (U.tag_type) |T| {
                size += @sizeOf(T);
            } else {
                @compileError("Cannot serialize a union without a tag type!");
            }
            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    size += serializeSize(field.field_type, @field(value, field.name));
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

pub fn deserialize(
    comptime Type: type,
    bytes: []const u8,
    desc: DeserializeDesc,
) SerdeError!Type {
    var value: Type = undefined;
    var index: usize = 0;
    try deserializeBytes(Type, &value, bytes, &index, desc);
    return value;
}

fn deserializeBytes(
    comptime Type: type,
    value: *Type,
    bytes: []const u8,
    index: *usize,
    desc: DeserializeDesc,
) SerdeError!void {
    switch (@typeInfo(Type)) {
        .Void => {},
        .Bool, .Int, .Float, .Enum => {
            value.* = std.mem.bytesAsSlice(Type, bytes[index.* .. index.* + @sizeOf(Type)])[0];
            index.* += @sizeOf(Type);
        },
        .Optional => |O| {
            var exists: bool = undefined;
            try deserializeBytes(bool, &exists, bytes, index, desc);
            if (exists) {
                try deserializeBytes(O.child, &value.*.?, bytes, index, desc);
            } else {
                value.* = null;
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    if (desc.allocator) |a| {
                        var ptr = a.create(P.child) catch return error.OutOfMemory;
                        try deserializeBytes(P.child, ptr, bytes, index, desc);
                        value.* = ptr;
                    } else {
                        return error.AllocatorRequired;
                    }
                },
                .Slice => {
                    var serde_len: serde_usize = undefined;
                    try deserializeBytes(serde_usize, &serde_len, bytes, index, desc);

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
                                        bytes[index.* .. index.* + len * @sizeOf(P.child)],
                                    ),
                                );
                                index.* += len * @sizeOf(P.child);
                            },
                            else => {
                                for (slice) |*s| {
                                    try deserializeBytes(P.child, s, bytes, index, desc);
                                }
                            },
                        }
                        if (P.sentinel) |_| {
                            try deserializeBytes(P.child, &slice[P.len], bytes, index, desc);
                        }
                        value.* = slice;
                    } else if (P.is_const and desc.bytes_are_embedded) {
                        switch (@typeInfo(P.child)) {
                            .Bool, .Int, .Float, .Enum => {
                                value.* = std.mem.bytesAsSlice(
                                    P.child,
                                    bytes[index.* .. index.* + len * @sizeOf(P.child)],
                                );
                                index.* += len * @sizeOf(P.child);
                            },
                            else => return error.AllocatorRequired,
                        }
                    } else {
                        return error.AllocatorRequired;
                    }
                },
                else => |E| {
                    @compileError("Cannot deserialize pointer size " ++ @tagName(E) ++ "!");
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
                            bytes[index.* .. index.* + A.len * @sizeOf(A.child)],
                        ),
                    );
                    index.* += A.len * @sizeOf(A.child);
                },
                else => {
                    for (value.*) |*v| {
                        try deserializeBytes(A.child, v, bytes, index, desc);
                    }
                },
            }
            if (A.sentinel) |_| {
                try deserializeBytes(A.child, &value.*[A.len], bytes, index, desc);
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                try deserializeBytes(
                    field.field_type,
                    &@field(value.*, field.name),
                    bytes,
                    index,
                    desc,
                );
            }
        },
        .Union => |U| {
            const UnionTagType = U.tag_type orelse
                @compileError("Cannot deserialize a union without a tag type!");
            var tag: UnionTagType = undefined;
            try deserializeBytes(UnionTagType, &tag, bytes, index, desc);

            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(tag))) {
                    const UnionType = @TypeOf(@field(value.*, field.name));
                    var u: UnionType = undefined;
                    try deserializeBytes(
                        UnionType,
                        &u,
                        bytes,
                        index,
                        desc,
                    );
                    value.* = @unionInit(Type, field.name, u);
                    break;
                }
            }
        },
        else => |E| @compileError("Cannot deserialize type " ++ @tagName(E) ++ "!"),
    }
}

pub fn deserializeFree(allocator: std.mem.Allocator, comptime Type: type, value: Type) void {
    switch (@typeInfo(Type)) {
        .Void, .Bool, .Int, .Float, .Enum => {},
        .Optional => |O| {
            if (value) |v| {
                deserializeFree(allocator, O.child, v);
            }
        },
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    deserializeFree(allocator, P.child, value.*);
                    allocator.destroy(value);
                },
                .Slice => {
                    switch (@typeInfo(P.child)) {
                        .Bool, .Int, .Float, .Enum => {},
                        else => {
                            for (value) |v| {
                                deserializeFree(allocator, P.child, v);
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
                        deserializeFree(allocator, A.child, v);
                    }
                },
            }
        },
        .Struct => |S| {
            inline for (S.fields) |field| {
                deserializeFree(allocator, field.field_type, @field(value, field.name));
            }
        },
        .Union => |U| {
            inline for (U.fields) |field| {
                if (std.mem.eql(u8, field.name, @tagName(value))) {
                    deserializeFree(allocator, field.field_type, @field(value, field.name));
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

    const deserialized_value = try deserialize(
        TestStruct,
        bytes,
        .{ .allocator = std.testing.allocator },
    );
    defer deserializeFree(std.testing.allocator, TestStruct, deserialized_value);

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
