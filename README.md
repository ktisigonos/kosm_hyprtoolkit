# kosm_hyprtoolkit

hyprtoolkit for kosm: the theme every hyprtoolkit app (hyprlauncher, hyprpolkitagent, the
Hyprland dialogs) draws with, and the `hyprtoolkit` adapter for its flat `key = value` file
with `rgba(rrggbbaa)` colors.

The app writes only the options that are set to `~/.config/hypr/hyprtoolkit.conf`, whole;
the file holds nothing but the theme, so kosm owns it. hyprtoolkit apps read it when they
start.

`from(theme)` sets the colors: the background from the theme's background role with its
`background_alpha`, widgets from its surface and state steps, text from the foreground role,
links from the link role, the accent from the accent role and the second accent a brighter
accent. Sizes, roundings, the icon theme and fonts are left alone.

## Fields

| Field | Default |
|---|---|
| `file` | `~/.config/hypr/hyprtoolkit.conf` |
| `format` | the adapter's: `rgba(rrggbbaa)` |
| `background`, `base`, `text`, `alternate_base`, `bright_text`, `link_text`, `accent`, `accent_secondary` | null: hyprtoolkit's |
| `rounding_large`, `rounding_small` | null; pixels |
| `h1_size`, `h2_size`, `h3_size`, `font_size`, `small_font_size` | null; points |
| `icon_theme`, `font_family`, `font_family_monospace` | null |
| `extra` | none; other options by name |
