const make = @import("make.zig");
const std = @import("std");

/// minifier that removes whitespace and replaces any words starting with _
/// with smaller allocated identifiers
const Minify = struct {
    const Language = enum {
        js,
        wgsl,
    };

    const CharType = enum {
        whitespace, // any whitespace character
        symbol, // any character in the symbols string, see below
        ident, // any non-whitespace, non-symbol character
    };

    const symbols = "{}()[]=<>;:.,|/-+*!&?";
    const str_symbols = "\"'`";
    const max_ident_size = 2;
    const next_ident_symbols = "abcdfghjklmnpqrstvwxzABCDEFGHIJKLMNOPQRSTUVWXYZ";

    allocator: std.mem.Allocator,
    src: []const u8,
    out: std.ArrayList(u8),
    start_index: usize,
    end_index: usize,
    prev_char_type: CharType,
    prev_char_type_write: CharType,
    ident_map: std.StringHashMap([]const u8),
    next_ident: [max_ident_size]u8,
    next_ident_index: [max_ident_size]usize,
    next_ident_size: usize,
    language: Language,
    opt_level: make.OptLevel,

    fn init(
        src: []const u8,
        allocator: std.mem.Allocator,
        language: Language,
        opt_level: make.OptLevel,
    ) Minify {
        var ctx = Minify{
            .allocator = allocator,
            .src = src,
            .out = std.ArrayList(u8).init(allocator),
            .start_index = 0,
            .end_index = 0,
            .prev_char_type = .whitespace,
            .prev_char_type_write = .whitespace,
            .ident_map = std.StringHashMap([]const u8).init(allocator),
            .next_ident = [_]u8{next_ident_symbols[0]} ** max_ident_size,
            .next_ident_index = [_]usize{0} ** max_ident_size,
            .next_ident_size = 1,
            .language = language,
            .opt_level = opt_level,
        };

        return ctx;
    }

    fn deinit(ctx: *Minify) void {
        var it = ctx.ident_map.iterator();
        while (it.next()) |kv| {
            ctx.allocator.free(kv.value_ptr.*);
        }
        ctx.ident_map.deinit();
    }

    fn minify(ctx: *Minify) ![]const u8 {
        while (ctx.end_index < ctx.src.len) {
            const char = ctx.src[ctx.end_index];
            if (ctx.end_index < ctx.src.len - 1 and
                char == '/' and
                (ctx.src[ctx.end_index + 1] == '/' or ctx.src[ctx.end_index + 1] == '*'))
            {
                try ctx.handleComment();
            } else if (std.mem.indexOfScalar(u8, symbols, char) != null) {
                try ctx.handleCharType(.symbol);
            } else if (std.mem.indexOfScalar(u8, str_symbols, char) != null) {
                try ctx.handleString();
            } else if (std.mem.indexOfScalar(u8, &std.ascii.spaces, char) != null) {
                try ctx.handleCharType(.whitespace);
            } else {
                try ctx.handleCharType(.ident);
            }
        }

        try ctx.flush();

        return ctx.out.toOwnedSlice();
    }

    fn flush(ctx: *Minify) !void {
        try ctx.handleCharType(.whitespace);
    }

    fn handleCharType(ctx: *Minify, char_type: CharType) !void {
        // check for the end of a char type run
        if (char_type != ctx.prev_char_type) {
            if (ctx.prev_char_type == .symbol) {
                try ctx.appendSymbol();
            } else if (ctx.prev_char_type == .ident) {
                try ctx.appendIdent();
            }

            if (char_type != .whitespace) {
                // append a space between two different identifiers
                if (ctx.prev_char_type_write == .ident and char_type == .ident) {
                    try ctx.out.append(' ');
                }

                // chrome wgsl parser is broken, this works around the issue...
                if (ctx.language == .wgsl and
                    ctx.prev_char_type_write == .symbol and
                    char_type == .ident)
                {
                    const wgsl_skip = "{([]<>=:;,.";
                    const last_write_char = ctx.out.items[ctx.out.items.len - 1];
                    if (std.mem.indexOfScalar(u8, wgsl_skip, last_write_char) == null) {
                        try ctx.out.append(' ');
                    }
                }

                // keep track of the last char type written
                ctx.prev_char_type_write = char_type;
            }
            ctx.prev_char_type = char_type;
            ctx.start_index = ctx.end_index;
        }
        ctx.end_index += 1;
    }

    fn handleString(ctx: *Minify) !void {
        try ctx.flush();

        const str_marker = ctx.src[ctx.end_index - 1];
        ctx.start_index = ctx.end_index - 1;
        while (ctx.end_index < ctx.src.len and
            (ctx.src[ctx.end_index] != str_marker or ctx.src[ctx.end_index - 1] == '\\'))
        {
            ctx.end_index += 1;
        }
        ctx.end_index += 1;

        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn handleComment(ctx: *Minify) !void {
        try ctx.flush();
        const char = ctx.src[ctx.end_index];
        if (char == '/') {
            // line comment
            while (ctx.src[ctx.end_index] != '\n') {
                ctx.end_index += 1;
            }
        } else {
            // block comment
            while (ctx.end_index < ctx.src.len - 1 and
                ctx.src[ctx.end_index] != '*' and
                ctx.src[ctx.end_index + 1] != '/')
            {
                ctx.end_index += 1;
            }
        }
    }

    fn appendSymbol(ctx: *Minify) !void {
        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn appendIdent(ctx: *Minify) !void {
        const ident = ctx.src[ctx.start_index..ctx.end_index];
        // append the identifier as-is if in debug mode or if the identifier starts with _
        // digits also cannot be converted into a different identifier
        if (ctx.opt_level == .debug or
            ctx.src[ctx.start_index] != '_' or
            std.ascii.isDigit(ident[0]))
        {
            try ctx.out.appendSlice(ident);
        } else if (ctx.ident_map.getEntry(ident)) |entry| {
            // check if the identifier has already been parsed.
            // reuse the replacement identifier in that case
            try ctx.out.appendSlice(entry.value_ptr.*);
        } else {
            // otherwise, get a new replacement identifier
            const next_ident = try ctx.nextIdent();
            try ctx.ident_map.put(ident, next_ident);
            try ctx.out.appendSlice(next_ident);
        }
    }

    fn nextIdent(ctx: *Minify) ![]const u8 {
        // identifiers are allocated from a string of characters.
        // they start off as single character identifiers
        const next = ctx.allocator.dupe(u8, ctx.next_ident[0..ctx.next_ident_size]);

        var cur_index = ctx.next_ident_size - 1;
        if (ctx.next_ident_index[cur_index] != next_ident_symbols.len - 1) {
            // each time an identifier is allocated, the character in the string is set to
            // the next one in next_ident_symbols...
            ctx.setNextIdent(cur_index, ctx.next_ident_index[cur_index] + 1);
        } else {
            // if the size is greater than 1, try to increment
            // the identifier in a previous string index
            ctx.setNextIdent(cur_index, 0);
            var out_of_idents = true;
            while (cur_index != 0) {
                cur_index -= 1;
                if (ctx.next_ident_index[cur_index] == next_ident_symbols.len - 1) {
                    ctx.setNextIdent(cur_index, 0);
                } else {
                    ctx.setNextIdent(cur_index, ctx.next_ident_index[cur_index] + 1);
                    out_of_idents = false;
                    break;
                }
            }

            // if that didn't work, we need to increase the size of the string
            if (out_of_idents) {
                ctx.next_ident_size += 1;
                if (ctx.next_ident_size > max_ident_size) {
                    return error.MaxIdentsExceeded;
                }
            }
        }

        return next;
    }

    fn setNextIdent(ctx: *Minify, ident_index: usize, symbol_index: usize) void {
        ctx.next_ident_index[ident_index] = symbol_index;
        ctx.next_ident[ident_index] = next_ident_symbols[symbol_index];
    }
};

pub fn js(
    src: []const u8,
    allocator: std.mem.Allocator,
    opt_level: make.OptLevel,
) ![]const u8 {
    var ctx = Minify.init(src, allocator, .js, opt_level);
    defer ctx.deinit();

    return try ctx.minify();
}

pub fn shader(
    src: []const u8,
    allocator: std.mem.Allocator,
    platform: make.Platform,
    opt_level: make.OptLevel,
) ![]const u8 {
    const lang = switch (platform) {
        .web => .wgsl,
    };

    var ctx = Minify.init(src, allocator, lang, opt_level);
    defer ctx.deinit();

    return try ctx.minify();
}
