//! hyprtoolkit's theme. `generate` writes the set options to `file`, which every hyprtoolkit
//! app reads; null options are left to hyprtoolkit's defaults. Field names are hyprtoolkit's.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// The file kosm owns. Default: `~/.config/hypr/hyprtoolkit.conf`.
file: []const u8 = "~/.config/hypr/hyprtoolkit.conf",
/// How values are spelled. Null fields take the adapter's: `rgba(rrggbbaa)`.
format: kosm.Format = .{},
/// Window backgrounds. null: hyprtoolkit's.
background: ?kosm.Color = null,
/// Backgrounds of buttons, inputs and other widgets. null: hyprtoolkit's.
base: ?kosm.Color = null,
/// Text. null: hyprtoolkit's.
text: ?kosm.Color = null,
/// Hovered and alternate widget backgrounds. null: hyprtoolkit's.
alternate_base: ?kosm.Color = null,
/// Text that stands out. null: hyprtoolkit's.
bright_text: ?kosm.Color = null,
/// Links. null: hyprtoolkit's.
link_text: ?kosm.Color = null,
/// The accent: focus and selections. null: hyprtoolkit's.
accent: ?kosm.Color = null,
/// The second accent. null: hyprtoolkit's.
accent_secondary: ?kosm.Color = null,
/// Corner radius of large elements such as windows, in pixels. null: hyprtoolkit's.
rounding_large: ?i64 = null,
/// Corner radius of small elements such as buttons, in pixels. null: hyprtoolkit's.
rounding_small: ?i64 = null,
/// Size of the largest headings, in points. null: hyprtoolkit's.
h1_size: ?i64 = null,
/// Size of second-level headings, in points. null: hyprtoolkit's.
h2_size: ?i64 = null,
/// Size of third-level headings, in points. null: hyprtoolkit's.
h3_size: ?i64 = null,
/// Size of body text, in points. null: hyprtoolkit's.
font_size: ?i64 = null,
/// Size of small text, in points. null: hyprtoolkit's.
small_font_size: ?i64 = null,
/// The icon theme's name. null: hyprtoolkit's.
icon_theme: ?[]const u8 = null,
/// The family text is shown in. null: hyprtoolkit's.
font_family: ?[]const u8 = null,
/// The family monospaced text is shown in. null: hyprtoolkit's.
font_family_monospace: ?[]const u8 = null,
/// Options the app doesn't cover, by name: `.{ .path = "some_option", .value = .{ .integer
/// = 1 } }`. One that repeats a set option or another extra fails the apply. Default: none.
extra: []const kosm.Setting = &.{},

/// Colors from the theme: the background from the background role with the theme's background
/// alpha, widgets from its surface and state steps, text from the foreground role, links from
/// the link role, the accent from the accent role and the second accent a brighter accent. Sizes and fonts are left alone.
pub fn from(theme: kosm.Theme) App {
    const variations = theme.variations;
    const foreground = theme.roles.foreground;
    const background = theme.roles.background;
    return .{
        .background = theme.asBackground(background),
        .base = theme.asBackground(variations.surface.raised.apply(background)),
        .text = foreground,
        .alternate_base = theme.asBackground(variations.state.hovered.apply(background)),
        .bright_text = variations.emphasis.strong.apply(foreground),
        .link_text = theme.roles.link,
        .accent = theme.roles.accent,
        .accent_secondary = variations.lightness.bright.apply(theme.roles.accent),
    };
}

/// Writes every set option to `file`, then the extras.
pub fn apply(self: App, output: *kosm.Output) !void {
    var entries: std.ArrayList(kosm.Value.Entry) = .empty;
    inline for (@typeInfo(App).@"struct".field_names) |name| {
        if (comptime isOption(name)) {
            if (@field(self, name)) |option| try entries.append(output.allocator, .{ .key = name, .value = switch (@TypeOf(option)) {
                kosm.Color => .{ .color = option },
                i64 => .{ .integer = option },
                []const u8 => .{ .string = option },
                else => comptime unreachable,
            } });
        }
    }
    const own = try kosm.Setting.leaves(output.allocator, .{ .table = entries.items });
    const all = try kosm.Setting.withExtras(output, self.file, own, self.extra, .{ .paths = .one_key });
    try output.generate(.{ .file = self.file, .lang = "hyprtoolkit", .format = self.format }, try kosm.Setting.tree(output.allocator, all));
}

fn isOption(comptime name: []const u8) bool {
    for ([_][]const u8{ "file", "format", "extra" }) |own| {
        if (std.mem.eql(u8, own, name)) return false;
    }
    return true;
}

const testing = std.testing;
const adapter = @import("root.zig").adapter;

test "the set options are flat lines with hyprlang colors, extras last, and a clash fails" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    var home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    var plan: kosm.Plan = .init(testing.allocator, testing.io);
    defer plan.deinit();
    var diagnostics: kosm.Diagnostics = .{};
    var warnings: kosm.Warnings = .init(arena.allocator());
    var output: kosm.Output = .{
        .allocator = arena.allocator(),
        .home = home_buffer[0..try tmp.dir.realPath(testing.io, &home_buffer)],
        .adapters = &.{adapter},
        .plan = &plan,
        .diagnostics = &diagnostics,
        .warnings = &warnings,
        .app = "hyprtoolkit",
    };
    var theme = kosm.Theme.from(.{ .palette = .{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc"), .cyan = kosm.hex("2d8699") }, .mode = .dark });
    theme.background_alpha = 0.5;
    var app = from(theme);
    app.h1_size = 25;
    app.icon_theme = "Ricer";
    app.font_family = "Maple Mono Normal NFP";
    app.extra = &.{.{ .path = "future_option", .value = .{ .integer = 1 } }};
    try app.apply(&output);

    const written = plan.files.items[0].new;
    try testing.expect(std.mem.startsWith(u8, written, "background = rgba(041c2680)\nbase = rgba("));
    try testing.expect(std.mem.indexOf(u8, written, "\ntext = rgba(a3c5ccff)\n") != null);
    try testing.expect(std.mem.indexOf(u8, written, "\nlink_text = rgba(2d8699ff)\n") != null);
    try testing.expect(std.mem.endsWith(u8, written, "\nh1_size = 25\nicon_theme = Ricer\nfont_family = Maple Mono Normal NFP\nfuture_option = 1\n"));
    try testing.expect(std.mem.indexOf(u8, written, "h2_size") == null);

    const clash: App = .{ .h2_size = 16, .extra = &.{.{ .path = "h2_size", .value = .{ .integer = 1 } }} };
    try testing.expectError(error.AppFailed, clash.apply(&output));
    try testing.expectEqualStrings("extra 'h2_size' and setting 'h2_size' write the same key, or one inside the other; keep one", diagnostics.message());
}
