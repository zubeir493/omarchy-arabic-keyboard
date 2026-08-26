#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -Dm644 "$plugin_dir/hameem.xkb" "$HOME/.config/xkb/hameem.xkb"

printf '%s\n' "Installed Hameem keymap at $HOME/.config/xkb/hameem.xkb"
printf '%s\n' 'Add this input override to ~/.config/hypr/input.lua:'
printf '%s\n' 'hl.config({ input = { kb_file = os.getenv("HOME") .. "/.config/xkb/hameem.xkb", kb_layout = "us,hameem", kb_variant = "," } })'
printf '%s\n' 'The included keymap handles layout switching on Super+Space only; keep Super+Alt+Space available for the Apps menu.'
printf '%s\n' 'Then run: hyprctl reload'
