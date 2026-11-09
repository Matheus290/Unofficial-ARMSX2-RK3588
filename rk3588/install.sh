#!/bin/sh
# ARMSX2 RK3588 (experimental) installer.
#
# Run it from an extracted release package:   ./install.sh
# or let it download the latest release:      curl -fsSL https://raw.githubusercontent.com/Matheus290/Unofficial-ARMSX2-RK3588/rk3588/rk3588/install.sh | sh
#
# ROCKNIX:      installs to /storage/armsx2-rk3588, adds "armsx2-rk3588" to the PS2 emulators in EmulationStation
#               and "Start ARMSX2 RK3588" to the Tools menu. This is the only system it has been tested on.
# Other Linux:  installs to ~/.local/share/armsx2-rk3588, with ~/.local/bin/armsx2-rk3588 and a menu entry
#               (untested; Batocera and other systems may need manual setup).
# Running it again updates the emulator and keeps your settings, memory cards and save states.

set -e

REPO="Matheus290/Unofficial-ARMSX2-RK3588"
NAME="armsx2-rk3588"

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

[ "$(uname -m)" = "aarch64" ] || die "this build is for 64-bit ARM Linux (aarch64); this machine is $(uname -m)."

if [ -d /storage/.config ] && [ -d /storage/roms ]; then
  ROCKNIX=1
  DEST=/storage/$NAME
else
  ROCKNIX=0
  DEST="${XDG_DATA_HOME:-$HOME/.local/share}/$NAME"
fi
# Optional: ARMSX2_RK3588_DEST=/some/folder installs there instead, and ARMSX2_RK3588_NO_SHORTCUTS=1
# skips the EmulationStation / menu entries (handy for a second, side-by-side copy).
[ -n "$ARMSX2_RK3588_DEST" ] && DEST="$ARMSX2_RK3588_DEST"

# Find the package: next to this script, or download the latest release.
SRC=""
HERE=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$HERE" ] && [ -f "$HERE/armsx2-sdl" ] && [ -d "$HERE/resources" ]; then
  SRC="$HERE"
else
  command -v curl >/dev/null 2>&1 || die "curl is needed to download the release."
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  say "Looking up the latest release of $REPO..."
  URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
    grep -o '"browser_download_url": *"[^"]*linux-arm64\.tar\.xz"' | head -n 1 | sed 's/.*"\(https[^"]*\)"/\1/')
  [ -n "$URL" ] || die "could not find a release package on GitHub."
  say "Downloading $URL"
  curl -fL --progress-bar -o "$TMP/pkg.tar.xz" "$URL"
  tar -xJf "$TMP/pkg.tar.xz" -C "$TMP"
  SRC=$(dirname "$(find "$TMP" -name armsx2-sdl -type f | head -n 1)")
  [ -f "$SRC/armsx2-sdl" ] || die "the downloaded package has no armsx2-sdl."
fi

say "Installing to $DEST"
mkdir -p "$DEST"
# Program files are replaced; user data (inis, memcards, sstates, covers, ...) is left alone.
rm -rf "$DEST/resources"
cp -R "$SRC/resources" "$DEST/resources"
cp "$SRC/armsx2-sdl" "$DEST/armsx2-sdl.new" && mv -f "$DEST/armsx2-sdl.new" "$DEST/armsx2-sdl"
for f in armsx2-rk3588.sh es_launch.sh es-setup.py uninstall.sh README.md COPYING.GPLv3 SOURCE.txt VERSION; do
  [ -f "$SRC/$f" ] && cp "$SRC/$f" "$DEST/$f"
done
chmod +x "$DEST/armsx2-sdl" "$DEST/armsx2-rk3588.sh" "$DEST/es_launch.sh" "$DEST/es-setup.py" "$DEST/uninstall.sh" 2>/dev/null || true
touch "$DEST/portable.txt"

# Where the frontend keeps BIOS files, games and saves. Memory cards go in the frontend's PS2 save
# folder, so they are shared with the other PS2 emulators there.
if [ "$ROCKNIX" = 1 ]; then
  # ROCKNIX (and other JELOS-based systems)
  BIOS=/storage/roms/bios/PS2
  [ -d "$BIOS" ] || BIOS=/storage/roms/bios
  GAMES=/storage/roms/ps2
  MEMCARDS=/storage/roms/saves/ps2
elif [ -d /userdata/roms ]; then
  # Batocera
  BIOS=/userdata/bios
  GAMES=/userdata/roms/ps2
  MEMCARDS=/userdata/saves/ps2
else
  BIOS="$DEST/bios"
  GAMES="$HOME/Games/PS2"
  MEMCARDS="$DEST/memcards"
fi

# First install: point the folders at the usual places and start from this build's defaults:
# Vulkan at 2x native resolution, smooth bilinear output, widescreen patches, MTVU and IOP thread,
# GS back thread and Mali ordered input attachment. After that the emulator's own settings menu
# decides; nothing is forced at launch.
INI="$DEST/inis/PCSX2.ini"
if [ ! -f "$INI" ]; then
  mkdir -p "$DEST/inis" "$MEMCARDS"
  [ -d "$BIOS" ] || mkdir -p "$BIOS"
  cat > "$INI" <<EOF
[UI]
SettingsVersion = 1
SetupWizardIncomplete = false

[Folders]
Bios = $BIOS
MemoryCards = $MEMCARDS

[GameList]
Paths = $GAMES

[EmuCore]
AutoTune = false
EnableWideScreenPatches = true

[EmuCore/Speedhacks]
vuThread = true
iopThread = true

[EmuCore/GS]
Renderer = 14
upscale_multiplier = 2
linear_present_mode = 1
GSBackThreadMode = 1
MaliOrderedInputAttachment = true
OverrideTextureBarriers = -1
EOF
fi

# Controller: map the first SDL gamepad (positional names, so any Xbox / PlayStation / handheld
# pad works) and the hotkeys, unless the settings already have them.
if ! grep -q '^\[Pad1\]' "$INI"; then
  cat >> "$INI" <<'PAD'

[Pad1]
Type = DualShock2
Up = SDL-0/DPadUp
Right = SDL-0/DPadRight
Down = SDL-0/DPadDown
Left = SDL-0/DPadLeft
Triangle = SDL-0/FaceNorth
Circle = SDL-0/FaceEast
Cross = SDL-0/FaceSouth
Square = SDL-0/FaceWest
Select = SDL-0/Back
Start = SDL-0/Start
L1 = SDL-0/LeftShoulder
L2 = SDL-0/+LeftTrigger
R1 = SDL-0/RightShoulder
R2 = SDL-0/+RightTrigger
L3 = SDL-0/LeftStick
R3 = SDL-0/RightStick
LUp = SDL-0/-LeftY
LRight = SDL-0/+LeftX
LDown = SDL-0/+LeftY
LLeft = SDL-0/-LeftX
RUp = SDL-0/-RightY
RRight = SDL-0/+RightX
RDown = SDL-0/+RightY
RLeft = SDL-0/-RightX
Analog = SDL-0/Guide
LargeMotor = SDL-0/LargeMotor
SmallMotor = SDL-0/SmallMotor
PAD
fi
if ! grep -q '^OpenPauseMenu = ' "$INI"; then
  grep -q '^\[Hotkeys\]' "$INI" || printf '\n[Hotkeys]\n' >> "$INI"
  sed -i '/^\[Hotkeys\]/a\
OpenPauseMenu = SDL-0/LeftStick \& SDL-0/RightStick\
HoldTurbo = SDL-0/+LeftTrigger \& SDL-0/+RightTrigger\
LoadStateFromSlot = SDL-0/Guide \& SDL-0/LeftShoulder\
SaveStateToSlot = SDL-0/Guide \& SDL-0/RightShoulder' "$INI"
fi

if [ -n "$ARMSX2_RK3588_NO_SHORTCUTS" ]; then
  say ""
  say "Done (not registered anywhere). Start it with: $DEST/armsx2-rk3588.sh [game]"
elif [ "$ROCKNIX" = 1 ]; then
  # Register as a PS2 emulator in EmulationStation (next to the ones already installed).
  command -v python3 >/dev/null 2>&1 || die "python3 is needed to edit EmulationStation's systems list."
  python3 "$DEST/es-setup.py" install "$DEST"

  # "Start ARMSX2 RK3588" in ROCKNIX's Tools menu: opens the emulator on its game list, to scan games
  # and change settings without starting one. ROCKNIX rebuilds /storage/.config/modules on every boot,
  # so a boot script in /storage/.config/autostart copies the entry back each time.
  # The entry must not exec the emulator: Tools entries run inside weston-terminal, and the emulator
  # does not start as the terminal's direct child. Keep the file name free of parentheses too:
  # EmulationStation cannot start a Tools entry whose name has them.
  mkdir -p "$DEST/tools"
  cat > "$DEST/tools/Start ARMSX2 RK3588.sh" <<EOF
#!/bin/bash
# Tools menu: ARMSX2 RK3588 on its game list. Not exec: see install.sh.
"$DEST/armsx2-rk3588.sh"
EOF
  chmod +x "$DEST/tools/Start ARMSX2 RK3588.sh"
  mkdir -p /storage/.config/autostart
  cat > /storage/.config/autostart/armsx2-rk3588-tools.sh <<EOF
#!/bin/sh
# ARMSX2 RK3588: put its Tools menu entry back (ROCKNIX resyncs /storage/.config/modules on every boot).
for f in "$DEST"/tools/*.sh; do
  [ -f "\$f" ] && cp -f "\$f" /storage/.config/modules/ && chmod +x "/storage/.config/modules/\$(basename "\$f")"
done
exit 0
EOF
  chmod +x /storage/.config/autostart/armsx2-rk3588-tools.sh
  /storage/.config/autostart/armsx2-rk3588-tools.sh

  say ""
  say "Done. Restart EmulationStation (Menu > Quit > Restart EmulationStation) or reboot."
  say "Then, in the PS2 system, pick the emulator \"armsx2-rk3588\" in the"
  say "system's or a game's advanced settings, and start games from the game list as usual."
  say "PS2 BIOS files go in $BIOS, games in $GAMES."
  say "Tools > \"Start ARMSX2 RK3588\" opens the emulator on its game list (scan games, settings)."
else
  mkdir -p "$HOME/.local/bin"
  ln -sf "$DEST/armsx2-rk3588.sh" "$HOME/.local/bin/$NAME"
  APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$APPS"
  cat > "$APPS/$NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ARMSX2 RK3588 (unofficial)
Comment=Unofficial PlayStation 2 emulator build for RK3588
Exec=$DEST/armsx2-rk3588.sh
Icon=$DEST/resources/icons/AppIconLarge.png
Terminal=false
Categories=Game;Emulator;
EOF
  say ""
  say "Done. Start it from your applications menu, or run: $NAME [game]"
  say "PS2 BIOS files go in $BIOS, games in $GAMES (both can be changed in the settings)."
fi
