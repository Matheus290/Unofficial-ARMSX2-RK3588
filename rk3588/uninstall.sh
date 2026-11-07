#!/bin/sh
# Removes ARMSX2 RK3588. Your settings, memory cards and save states are inside the install
# folder: the script asks before deleting them.
NAME="armsx2-rk3588"
if [ -d /storage/.config ] && [ -d /storage/roms ]; then
  DEST=/storage/$NAME
  # Give the PS2 system its previous command back and drop the emulator entry.
  [ -f "$DEST/es-setup.py" ] && python3 "$DEST/es-setup.py" uninstall "$DEST"
else
  DEST="${XDG_DATA_HOME:-$HOME/.local/share}/$NAME"
  rm -f "$HOME/.local/bin/$NAME" "${XDG_DATA_HOME:-$HOME/.local/share}/applications/$NAME.desktop"
fi
[ -d "$DEST" ] || { echo "Nothing installed in $DEST."; exit 0; }
printf 'Delete %s, including settings, memory cards and save states? [y/N] ' "$DEST"
read -r answer < /dev/tty
case "$answer" in
  y|Y|yes|s|S|sim) rm -rf "$DEST"; echo "Removed." ;;
  *) rm -rf "$DEST/armsx2-sdl" "$DEST/resources"; echo "Program removed; your data stays in $DEST." ;;
esac
