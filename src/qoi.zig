const std = @import("std");

pub const Format = enum(u8) {
    rgb = 3,
    rgba = 4,
};

pub const Colorspace = enum(u8) {
    srgb = 0,
    linear = 1,
};

pub const Image = struct {
    width: u32,
    height: u32,
    data: []const u8,
    format: Format = .rgba,
    colorspace: Colorspace = .srgb,
};

const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    fn hash(color: Color) u8 {
        return @truncate(
            u8,
            ((@as(u32, color.r) * 3) +
                (@as(u32, color.g) * 5) +
                (@as(u32, color.b) * 7) +
                (@as(u32, color.a) * 11)) % 64,
        );
    }
};

const header_len = 14;
const magic = [4]u8{ 'q', 'o', 'i', 'f' };
const end_marker = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 1 };
const op_index: u8 = 0b00000000;
const op_diff: u8 = 0b01000000;
const op_luma: u8 = 0b10000000;
const op_run: u8 = 0b11000000;
const op_rgb: u8 = 0b11111110;
const op_rgba: u8 = 0b11111111;
const mask_op_code: u8 = 0b11000000;
const mask_index: u8 = 0b00111111;
const mask_diff_r: u8 = 0b00110000;
const mask_diff_g: u8 = 0b00001100;
const mask_diff_b: u8 = 0b00000011;
const mask_luma_r: u8 = 0b11110000;
const mask_luma_g: u8 = 0b00111111;
const mask_luma_b: u8 = 0b00001111;
const mask_run: u8 = 0b00111111;
const max_bytes: usize = 4000000000;

pub fn encode(image: Image, out_encode_len: *usize, allocator: std.mem.Allocator) ![]u8 {
    const max_size = image.width *
        image.height *
        (@enumToInt(image.format) + 1) +
        header_len +
        end_marker.len;
    if (max_size > max_bytes) {
        return error.MaxBytesExceeded;
    }
    const bytes = try allocator.alloc(u8, max_size);
    errdefer allocator.free(bytes);

    // encode header
    std.mem.copy(u8, bytes[0..4], &magic);
    std.mem.writeIntBig(u32, bytes[4..8], image.width);
    std.mem.writeIntBig(u32, bytes[8..12], image.height);
    bytes[12] = @enumToInt(image.format);
    bytes[13] = @enumToInt(image.colorspace);

    // encode each pixel
    var bytes_index: usize = header_len;
    var run: u8 = 0;
    var lut: [64]Color = std.mem.zeroes([64]Color);
    var prev_pixel: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    const pixels = std.mem.bytesAsSlice(Color, image.data);
    for (pixels) |pixel| {
        if (@bitCast(u32, pixel) == @bitCast(u32, prev_pixel)) {
            // if the pixel matches the prev pixel, we are in a run
            run += 1;

            // if we hit the max length of a run, reset the run
            if (run == 62) {
                try writeBytes(bytes, &bytes_index, &[_]u8{op_run | run - 1});
                run = 0;
            }
        } else {
            // otherwise, we have a new pixel
            // end an existing run if necessary
            if (run > 0) {
                try writeBytes(bytes, &bytes_index, &[_]u8{op_run | run - 1});
                run = 0;
            }

            // see if the new pixel is in the lookup table
            const hash = pixel.hash();
            if (@bitCast(u32, pixel) == @bitCast(u32, lut[hash])) {
                // if we are, write the hash
                try writeBytes(bytes, &bytes_index, &[_]u8{op_index | hash});
            } else {
                // otherwise write the pixel to the lookup table
                lut[hash] = pixel;

                // check if we can encode RGB diff or luma
                if (pixel.a == prev_pixel.a) {
                    const diff_r = @as(i16, pixel.r) - @as(i16, prev_pixel.r);
                    const diff_g = @as(i16, pixel.g) - @as(i16, prev_pixel.g);
                    const diff_b = @as(i16, pixel.b) - @as(i16, prev_pixel.b);

                    const diff_rg = diff_r - diff_g;
                    const diff_rb = diff_b - diff_g;

                    if (diff_r >= -2 and diff_r <= 1 and
                        diff_g >= -2 and diff_g <= 1 and
                        diff_b >= -2 and diff_b <= 1)
                    {
                        // we can encode using a diff (only takes 1 byte)
                        try writeBytes(
                            bytes,
                            &bytes_index,
                            &[_]u8{op_diff |
                                (@intCast(u8, diff_r + 2) << 4) |
                                (@intCast(u8, diff_g + 2) << 2) |
                                (@intCast(u8, diff_b + 2) << 0)},
                        );
                    } else if (diff_g >= -32 and diff_g <= 31 and
                        diff_rg >= -8 and diff_rg <= 7 and
                        diff_rb >= -8 and diff_rb <= 7)
                    {
                        // we can encode using luma (only takes 2 bytes)
                        try writeBytes(
                            bytes,
                            &bytes_index,
                            &[_]u8{
                                op_luma | @intCast(u8, diff_g + 32),
                                @intCast(u8, diff_rg + 8) << 4 | @intCast(u8, diff_rb + 8) << 0,
                            },
                        );
                    } else {
                        // otherwise, we encode using rgb (4 bytes)
                        try writeBytes(
                            bytes,
                            &bytes_index,
                            &[_]u8{ op_rgb, pixel.r, pixel.g, pixel.b },
                        );
                    }
                } else {
                    // unique alpha channel requires encoding rgba (5 bytes)
                    try writeBytes(
                        bytes,
                        &bytes_index,
                        &[_]u8{ op_rgba, pixel.r, pixel.g, pixel.b, pixel.a },
                    );
                }
            }
        }

        prev_pixel = pixel;
    }

    if (run > 0) {
        try writeBytes(bytes, &bytes_index, &[_]u8{op_run | run - 1});
        run = 0;
    }

    // encode end marker
    try writeBytes(bytes, &bytes_index, &end_marker);

    out_encode_len.* = bytes_index;
    return bytes;
}

fn writeBytes(bytes: []u8, bytes_index: *usize, data: []const u8) !void {
    if (bytes_index.* + data.len > bytes.len) {
        return error.InvalidData;
    }
    std.mem.copy(u8, bytes[bytes_index.*..], data);
    bytes_index.* += data.len;
}

pub fn decode(data: []const u8, allocator: std.mem.Allocator) !Image {
    if (data.len < header_len) {
        return error.InvalidData;
    }

    // decode header
    if (!std.mem.eql(u8, data[0..4], magic[0..4])) {
        return error.InvalidMagic;
    }
    const width = std.mem.readIntBig(u32, data[4..8]);
    const height = std.mem.readIntBig(u32, data[8..12]);
    const format = data[12];
    const colorspace = data[13];
    _ = colorspace;

    _ = std.meta.intToEnum(Format, format) catch return error.InvalidHeader;
    _ = std.meta.intToEnum(Colorspace, colorspace) catch return error.InvalidHeader;

    if (width * height * format > max_bytes) {
        return error.MaxBytesExceeded;
    }

    const bytes = try allocator.alloc(u8, width * height * format);
    errdefer allocator.free(bytes);

    // decode each pixel of the image
    var lut: [64]Color = std.mem.zeroes([64]Color);
    var pixel: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    var data_index: usize = header_len;
    var bytes_index: usize = 0;
    while (bytes_index < bytes.len) {
        if (data_index + 1 > data.len) {
            return error.InvalidData;
        }
        const op = data[data_index];
        if (op == op_rgb) {
            if (data_index + 4 > data.len) {
                return error.InvalidData;
            }
            pixel.r = data[data_index + 1];
            pixel.g = data[data_index + 2];
            pixel.b = data[data_index + 3];
            data_index += 4;
        } else if (op == op_rgba) {
            if (data_index + 5 > data.len) {
                return error.InvalidData;
            }
            pixel.r = data[data_index + 1];
            pixel.g = data[data_index + 2];
            pixel.b = data[data_index + 3];
            pixel.a = data[data_index + 4];
            data_index += 5;
        } else {
            const op_code = op & mask_op_code;
            if (op_code == op_index) {
                pixel = lut[op & mask_index];
                data_index += 1;
            } else if (op_code == op_diff) {
                // use wrapping adds to match the spec
                // even though the diffs are signed ints, they are still twos complement
                // numbers and the wrapping arithmetic works out the same.
                pixel.r +%= ((op & mask_diff_r) >> 4) -% 2;
                pixel.g +%= ((op & mask_diff_g) >> 2) -% 2;
                pixel.b +%= ((op & mask_diff_b) >> 0) -% 2;
                data_index += 1;
            } else if (op_code == op_luma) {
                if (data_index + 2 > data.len) {
                    return error.InvalidData;
                }
                // use wrapping adds to match the spec
                // even though the diffs are signed ints, they are still twos complement
                // numbers and the wrapping arithmetic works out the same.
                const diff_g = (op & mask_luma_g) -% 32;
                const op_rb = data[data_index + 1];
                pixel.r +%= diff_g +% ((op_rb & mask_luma_r) >> 4) -% 8;
                pixel.g +%= diff_g;
                pixel.b +%= diff_g +% ((op_rb & mask_luma_b) >> 0) -% 8;
                data_index += 2;
            } else if (op_code == op_run) {
                // a run is a continuous stream of the same pixel
                var run = (op & mask_run) + 1;
                if (bytes_index + format * (run - 1) > bytes.len) {
                    return error.InvalidData;
                }
                while (run > 1) : (run -= 1) {
                    std.mem.copy(u8, bytes[bytes_index..], std.mem.asBytes(&pixel)[0..format]);
                    bytes_index += format;
                }
                data_index += 1;
            }
        }

        lut[pixel.hash()] = pixel;

        if (bytes_index + format > bytes.len) {
            return error.InvalidData;
        }
        std.mem.copy(u8, bytes[bytes_index..], std.mem.asBytes(&pixel)[0..format]);
        bytes_index += format;
    }

    // decode end marker
    if (data_index + 8 != data.len or !std.mem.eql(u8, data[data_index..], &end_marker)) {
        return error.InvalidEndMarker;
    }

    return Image{ .width = width, .height = height, .data = bytes };
}
