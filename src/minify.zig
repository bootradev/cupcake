const build_app = @import("build_app.zig");
const std = @import("std");

const Minify = struct {
    const Language = enum {
        js,
        wgsl,
    };

    const keywords_js: []const []const u8 = &.{
        "document",
        "window",
        "WebAssembly",
        "navigator",
        "performance",
        "JSON",
        "console",
        "class",
        "this",
        "function",
        "const",
        "let",
        "var",
        "undefined",
        "catch",
        "if",
        "else",
        "switch",
        "case",
        "break",
        "do",
        "while",
        "for",
        "return",
        "new",
        "null",
        "true",
        "false",
        "Objs",
    };

    const keywords_wgsl: []const []const u8 = &.{
        "block",
        "binding",
        "group",
        "uniform",
        "builtin",
        "position",
        "location",
        "stage",
        "vertex",
        "fragment",
        "vertex_index",
        "struct",
        "fn",
        "var",
        "let",
        "return",
        "i32",
        "u32",
        "f32",
        "vec4",
        "mat4x4",
    };

    const ParseChar = enum {
        symbol, // a non-whitespace, non-identifier character. see symbols, below
        ident, // a non-whitespce, non-symbol character (an identifier)
        whitespace, // a whitespace character
    };

    const symbols = "{}()[]=<>;:.,|/-+*!&?";
    const str_symbols = "\"'`";
    const max_ident_size = 2;
    const next_ident_symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

    allocator: std.mem.Allocator,
    src: []const u8,
    out: std.ArrayList(u8),
    start_index: usize,
    end_index: usize,
    cur_char: ParseChar,
    cur_write_char: ParseChar,
    ident_map: std.StringHashMap([]const u8),
    next_ident: [max_ident_size]u8,
    next_ident_index: [max_ident_size]usize,
    next_ident_size: usize,
    language: Language,
    opt_level: build_app.OptLevel,

    fn init(
        src: []const u8,
        allocator: std.mem.Allocator,
        language: Language,
        opt_level: build_app.OptLevel,
    ) Minify {
        var ctx = Minify{
            .allocator = allocator,
            .src = src,
            .out = std.ArrayList(u8).init(allocator),
            .start_index = 0,
            .end_index = 0,
            .cur_char = .whitespace,
            .cur_write_char = .whitespace,
            .ident_map = std.StringHashMap([]const u8).init(allocator),
            .next_ident = [_]u8{'a'} ** max_ident_size,
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
                try ctx.handleChar(.symbol);
            } else if (std.mem.indexOfScalar(u8, str_symbols, char) != null) {
                try ctx.handleString();
            } else if (std.mem.indexOfScalar(u8, &std.ascii.spaces, char) == null) {
                try ctx.handleChar(.ident);
            } else {
                try ctx.handleChar(.whitespace);
            }
        }

        return ctx.out.toOwnedSlice();
    }

    fn handleChar(ctx: *Minify, char: ParseChar) !void {
        if (ctx.cur_char != char) {
            if (ctx.cur_char == .symbol) {
                try ctx.appendSymbol();
            } else if (ctx.cur_char == .ident) {
                try ctx.appendIdent();
            }

            if (char != .whitespace) {
                // append a space between two different identifiers
                if (ctx.cur_write_char == .ident and char == .ident) {
                    try ctx.out.append(' ');
                }

                // chrome wgsl parser is broken, this works around the issue...
                if (ctx.language == .wgsl and ctx.cur_write_char == .symbol and char == .ident) {
                    const wgsl_skip = "{([]<>=:;,.";
                    const last_write_char = ctx.out.items[ctx.out.items.len - 1];
                    if (std.mem.indexOfScalar(u8, wgsl_skip, last_write_char) == null) {
                        try ctx.out.append(' ');
                    }
                }

                ctx.cur_write_char = char;
            }
            ctx.cur_char = char;
            ctx.start_index = ctx.end_index;
        }
        ctx.end_index += 1;
    }

    fn handleString(ctx: *Minify) !void {
        try ctx.handleChar(.whitespace);

        const char = ctx.src[ctx.end_index - 1];
        ctx.start_index = ctx.end_index - 1;
        while (ctx.end_index < ctx.src.len and ctx.src[ctx.end_index] != char) {
            ctx.end_index += 1;
        }
        ctx.end_index += 1;

        try ctx.out.appendSlice(ctx.src[ctx.start_index..ctx.end_index]);
    }

    fn handleComment(ctx: *Minify) !void {
        try ctx.handleChar(.whitespace);
        const char = ctx.src[ctx.end_index];
        if (char == '/') {
            while (ctx.src[ctx.end_index] != '\n') {
                ctx.end_index += 1;
            }
        } else {
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
        if (ctx.opt_level == .debug or
            ctx.isKeyword(ident) or
            std.ascii.isDigit(ident[0]) or
            ctx.src[ctx.end_index] == '(')
        {
            try ctx.out.appendSlice(ident);
        } else if (ctx.ident_map.getEntry(ident)) |entry| {
            try ctx.out.appendSlice(entry.value_ptr.*);
        } else if (ctx.start_index > 0 and
            ctx.src[ctx.start_index - 1] == '.' and
            ctx.start_index > 1 and
            ctx.src[ctx.start_index - 2] != '.')
        {
            try ctx.out.appendSlice(ident);
        } else {
            const next_ident = try ctx.nextIdent();
            try ctx.ident_map.put(ident, next_ident);
            try ctx.out.appendSlice(next_ident);
        }
    }

    fn nextIdent(ctx: *Minify) ![]const u8 {
        const next = ctx.allocator.dupe(u8, ctx.next_ident[0..ctx.next_ident_size]);

        var cur_index = ctx.next_ident_size - 1;
        if (ctx.next_ident_index[cur_index] == next_ident_symbols.len - 1) {
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

            if (out_of_idents) {
                ctx.next_ident_size += 1;
                if (ctx.next_ident_size > max_ident_size) {
                    return error.MaxIdentsExceeded;
                }
            }
        } else {
            ctx.setNextIdent(cur_index, ctx.next_ident_index[cur_index] + 1);
        }

        return next;
    }

    fn setNextIdent(ctx: *Minify, ident_index: usize, symbol_index: usize) void {
        ctx.next_ident_index[ident_index] = symbol_index;
        ctx.next_ident[ident_index] = next_ident_symbols[symbol_index];
    }

    fn isKeyword(ctx: *Minify, slice: []const u8) bool {
        const keywords = switch (ctx.language) {
            .js => keywords_js,
            .wgsl => keywords_wgsl,
        };
        return for (keywords) |keyword| {
            if (std.mem.eql(u8, keyword, slice)) {
                return true;
            }
        } else false;
    }
};

pub fn js(
    src: []const u8,
    allocator: std.mem.Allocator,
    opt_level: build_app.OptLevel,
) ![]const u8 {
    var ctx = Minify.init(src, allocator, .js, opt_level);
    defer ctx.deinit();

    return try ctx.minify();
}

pub fn shader(
    src: []const u8,
    allocator: std.mem.Allocator,
    opt_level: build_app.OptLevel,
    gfx_api: build_app.GfxApi,
) ![]const u8 {
    const lang = switch (gfx_api) {
        .webgpu => .wgsl,
    };

    var ctx = Minify.init(src, allocator, lang, opt_level);
    defer ctx.deinit();

    return try ctx.minify();
}
