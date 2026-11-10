//! hyprtoolkit: the theme every hyprtoolkit app (hyprlauncher, hyprpolkitagent, ...) draws with.

const std = @import("std");
const kosm_ini = @import("kosm_ini");

/// hyprtoolkit's theme; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme.
pub const from = App.from;
/// hyprtoolkit.conf: flat `key = value` lines, `#` comments and `rgba(rrggbbaa)` colors.
pub const adapter = kosm_ini.dialect(.{
    .name = "hyprtoolkit",
    .default_format = .{ .color = .init("rgba({})", &.{.hex8}), .boolean = .true_false },
    .comments = &.{"#"},
    .nested_headers = false,
});

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
