# Omarchy Arabic Keyboard

An Omarchy shell bar widget with a macOS-style keyboard-layout menu. It reads
the layouts enabled on the active Hyprland keyboard, shows every one of them,
and switches directly to the selected layout. The widget is not limited to
English and Hameem Arabic: standard XKB layouts and variants are discovered at
runtime with `xkbcli`.

The repository also includes the Hameem Arabic phonetic keymap used by the
author. The keymap is optional; the widget works with any existing
`kb_layout`/`kb_variant` configuration.

## Install

```bash
omarchy plugin add https://github.com/zubeir493/omarchy-arabic-keyboard.git --enable --yes
```

The plugin is enabled in the center section by default. If the built-in
keyboard widget is still present, remove `omarchy.keyboard-layout` from the
center section of `~/.config/omarchy/shell.json`.

Click the bar label to open the menu. `Alt+Space` remains the fast keyboard
shortcut when the configured XKB keymap provides it.

## Hameem keymap

For the included Hameem layout:

```bash
./install-keymap.sh
```

Then add this to `~/.config/hypr/input.lua` and reload Hyprland:

```lua
hl.config({
  input = {
    kb_file = os.getenv("HOME") .. "/.config/xkb/hameem.xkb",
    kb_layout = "us,hameem",
    kb_variant = ",",
  },
})
```

The Hameem mapping follows the keyboard preview and manual published with
Hameem's Arabic phonetic keyboard.
