#!/bin/sh
# ARMSX2 Nightly installer for ROCKNIX (unofficial helper script).
# https://github.com/Matheus290/Unofficial-ARMSX2-RK3588 (folder nightly/)
#
# Installs the official ARMSX2 nightly (the Linux arm64 Qt AppImage from github.com/ARMSX2/ARMSX2)
# into /storage/armsx2-nightly-qt and, on Mali GPUs driven by Arm's kernel driver (ROCKNIX's
# "libmali" mode), the malisx2 Vulkan driver from github.com/bmdhacks/malisx2 as ARMSX2's own
# driver pack, selected in its settings.
# It adds "armsx2-nightly" to the PS2 emulators in EmulationStation and "Start ARMSX2 Nightly"
# to the Tools menu. Running it again updates the emulator and malisx2 and keeps your settings.
#
#   sh install.sh             install or update
#   sh install.sh uninstall   remove it (same as sh /storage/armsx2-nightly-qt/uninstall.sh;
#                             asks before deleting settings and save states)
#
# Tested only on an RK3588 (Mali-G610) with ROCKNIX in libmali mode.

set -e

NAME="armsx2-nightly"
DEST=/storage/armsx2-nightly-qt
EMU_REPO="ARMSX2/ARMSX2"
MSX2_REPO="bmdhacks/malisx2"
TOOLS_ENTRY="Start ARMSX2 Nightly.sh"
HOOK=/storage/.config/autostart/armsx2-nightly-tools.sh

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

[ "$(uname -m)" = "aarch64" ] || die "this is for 64-bit ARM (aarch64); this machine is $(uname -m)."
[ -d /storage/.config ] && [ -d /storage/roms ] || die "this script is for ROCKNIX (no /storage/.config or /storage/roms here)."
for c in curl python3 sha256sum; do
  command -v "$c" >/dev/null 2>&1 || die "$c is needed."
done

# ---------------------------------------------------------------------------------------------
# Helper files kept in the install folder (also used by "uninstall" and by EmulationStation).
# ---------------------------------------------------------------------------------------------
write_helpers() {
  mkdir -p "$DEST/tools"

  # Starts the emulator. With a game: plays it; without: opens the game list (Big Picture).
  cat > "$DEST/$NAME.sh" <<'EOF'
#!/bin/sh
# ARMSX2 Nightly launcher. Usage: armsx2-nightly.sh [game file]
DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
[ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1
# Settings, shader cache and driver packs live in $DIR/ARMSX2 (app/usr/bin/portable.txt).
export LD_LIBRARY_PATH="$DIR/app/usr/lib" QT_QPA_PLATFORM=wayland
export LANG="${LANG:-en_US.UTF-8}" SDL_AUDIODRIVER=pulseaudio
command -v set_kill >/dev/null 2>&1 && set_kill set "-9 armsx2-qt"
# The Vulkan driver is chosen in ARMSX2 (Settings > GPU Drivers). ARMSX2 ignores that choice
# when the environment already names a driver, so don't pass one on.
unset VK_DRIVER_FILES VK_ICD_FILENAMES
cd "$DIR" || exit 1
# stdin from /dev/null: EmulationStation starts programs with descriptor 0 closed.
exec "$DIR/app/usr/bin/armsx2-qt" -bigpicture -fullscreen "$@" < /dev/null > "$DIR/stdout.log" 2>&1
EOF

  # EmulationStation's PS2 command. Games set to the "armsx2-nightly" emulator start here,
  # through runemu.sh's "shell" platform so ROCKNIX still applies its performance settings.
  # Every other PS2 emulator goes, unchanged, to the command the PS2 system had before.
  cat > "$DEST/es_launch.sh" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
case "$*" in
  *--emulator=armsx2-nightly\ *|*--emulator=armsx2-nightly)
    LAUNCHER="/tmp/armsx2-nightly-launch.sh"
    printf '#!/bin/bash\nexec %q %q\n' "${HERE}/armsx2-nightly.sh" "$1" >"${LAUNCHER}"
    chmod +x "${LAUNCHER}"
    shift
    ARGS="$*"
    exec /usr/bin/runemu.sh "${LAUNCHER}" -Pshell --core=armsx2-nightly-sa --emulator=armsx2-nightly \
      --controllers="${ARGS#*--controllers=}"
    ;;
  *)
    PREV="/usr/bin/runemu.sh"
    [ -s "${HERE}/es_previous_command" ] && PREV="$(cat "${HERE}/es_previous_command")"
    # Another installer that chains the same way may have saved this script as its previous
    # command: never pass the same game through here twice.
    case ":${ARMSX2_ES_CHAIN}:" in *":${HERE}:"*) PREV="/usr/bin/runemu.sh" ;; esac
    export ARMSX2_ES_CHAIN="${ARMSX2_ES_CHAIN}:${HERE}"
    [ -x "${PREV}" ] || PREV="/usr/bin/runemu.sh"
    exec "${PREV}" "$@"
    ;;
esac
EOF

  cat > "$DEST/es-setup.py" <<'EOF'
#!/usr/bin/env python3
"""Add or remove ARMSX2 Nightly as a PS2 emulator in ROCKNIX's EmulationStation.

usage: es-setup.py install|uninstall <install dir>
Only the ps2 <system> block of /storage/.config/emulationstation/es_systems.cfg is touched.
"""
import glob
import os
import re
import shutil
import sys

USER_CFG = "/storage/.config/emulationstation/es_systems.cfg"
SYSTEM_CFG = "/usr/config/emulationstation/es_systems.cfg"
BACKUP = USER_CFG + ".bak-armsx2-nightly"
ENTRY = (
    '\t\t\t<emulator name="armsx2-nightly">\n'
    "\t\t\t\t<cores>\n"
    '\t\t\t\t\t<core default="true">armsx2-nightly-sa</core>\n'
    "\t\t\t\t</cores>\n"
    "\t\t\t</emulator>\n"
)
ENTRY_RE = re.compile(r'[ \t]*<emulator name="armsx2-nightly">.*?</emulator>[ \t]*\n', re.S)


def ps2_block(text):
    for m in re.finditer(r"<system>.*?</system>", text, re.S):
        if re.search(r"<name>\s*ps2\s*</name>", m.group(0)):
            return m.start(), m.end()
    sys.exit("es-setup: no ps2 system in " + USER_CFG)


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ("install", "uninstall"):
        sys.exit(__doc__)
    action, dest = sys.argv[1], os.path.abspath(sys.argv[2])
    launcher = os.path.join(dest, "es_launch.sh")
    prev_file = os.path.join(dest, "es_previous_command")

    if not os.path.exists(USER_CFG):
        if action == "uninstall":
            return
        os.makedirs(os.path.dirname(USER_CFG), exist_ok=True)
        shutil.copy(SYSTEM_CFG, USER_CFG)
    text = open(USER_CFG, encoding="utf-8").read()
    if action == "install" and not os.path.exists(BACKUP):
        shutil.copy(USER_CFG, BACKUP)

    start, end = ps2_block(text)
    block = text[start:end]
    cmd = re.search(r"<command>\s*(\S+)(.*?)</command>", block, re.S)
    if not cmd:
        sys.exit("es-setup: the ps2 system has no <command>")
    program = cmd.group(1)

    if action == "install":
        if program != launcher:
            with open(prev_file, "w") as f:
                f.write(program + "\n")
            block = block[: cmd.start(1)] + launcher + block[cmd.end(1):]
        block = ENTRY_RE.sub("", block)
        i = block.rfind("</emulators>")
        if i < 0:
            sys.exit("es-setup: the ps2 system has no <emulators> list")
        line_start = block.rfind("\n", 0, i) + 1
        block = block[:line_start] + ENTRY + block[line_start:]
    else:
        prev = "/usr/bin/runemu.sh"
        if os.path.exists(prev_file):
            prev = open(prev_file).read().strip() or prev
        if program == launcher:
            block = block[: cmd.start(1)] + prev + block[cmd.end(1):]
        else:
            # Something installed after us chains to our launcher: point it at our previous command.
            for other in glob.glob("/storage/*/es_previous_command"):
                try:
                    if open(other).read().strip() == launcher:
                        with open(other, "w") as f:
                            f.write(prev + "\n")
                except OSError:
                    pass
        block = ENTRY_RE.sub("", block)

    new = text[:start] + block + text[end:]
    if new != text:
        tmp = USER_CFG + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(new)
        os.replace(tmp, USER_CFG)
    print("es-setup: %s done" % action)


if __name__ == "__main__":
    main()
EOF

  # Tools menu entry. It must not exec the emulator (Tools entries run inside weston-terminal, and
  # the emulator does not start as the terminal's direct child), and its file name must not have
  # parentheses (EmulationStation cannot start those).
  cat > "$DEST/tools/$TOOLS_ENTRY" <<EOF
#!/bin/bash
# Tools menu: ARMSX2 Nightly on its game list.
"$DEST/$NAME.sh"
EOF
  chmod +x "$DEST/$NAME.sh" "$DEST/es_launch.sh" "$DEST/es-setup.py" "$DEST/tools/$TOOLS_ENTRY"
  cat > "$DEST/uninstall.sh" <<EOF
#!/bin/sh
# Removes ARMSX2 Nightly. Asks before deleting its settings and save states.
DEST="$DEST"
[ -f "\$DEST/es-setup.py" ] && python3 "\$DEST/es-setup.py" uninstall "\$DEST"
rm -f "/storage/.config/modules/$TOOLS_ENTRY" "$HOOK"
printf 'Delete %s, including its settings and save states? [y/N] ' "\$DEST"
answer=""
read -r answer < /dev/tty || true
case "\$answer" in
  y|Y|yes|s|S|sim) rm -rf "\$DEST"; echo "Removed." ;;
  *) rm -rf "\$DEST/app"; echo "Program removed; your data stays in \$DEST/ARMSX2." ;;
esac
echo "Restart EmulationStation to update the emulator list."
EOF
  chmod +x "$DEST/uninstall.sh"
}

# ---------------------------------------------------------------------------------------------
uninstall() {
  [ -f "$DEST/uninstall.sh" ] || { say "Nothing installed in $DEST."; exit 0; }
  exec sh "$DEST/uninstall.sh"
}
[ "$1" = "uninstall" ] && uninstall

# A JSON field from a GitHub API answer, with python3 (no jq on ROCKNIX).
gh_json() { # gh_json <url> <python expression on "r">
  curl -fsSL -H "Accept: application/vnd.github+json" "$1" | python3 -c "
import json, sys
r = json.load(sys.stdin)
print($2)"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$DEST"

# ---------------------------------------------------------------------------------------------
# 1. The emulator: the newest nightly that has the Linux arm64 (4K pages) AppImage.
# ---------------------------------------------------------------------------------------------
say "Looking up the latest ARMSX2 nightly..."
INFO=$(gh_json "https://api.github.com/repos/$EMU_REPO/releases?per_page=20" "next(
  (rel['tag_name'] + ' ' + a['browser_download_url'])
  for rel in r if rel['tag_name'].startswith('nightly-') and not rel.get('draft')
  for a in rel['assets'] if a['name'].endswith('-Linux-arm64-4K-pages.AppImage'))") ||
  die "could not find a nightly on GitHub (no internet?)."
TAG=${INFO%% *}
URL=${INFO#* }
CUR=$(cat "$DEST/VERSION" 2>/dev/null || true)
if [ "$CUR" = "$TAG" ] && [ -x "$DEST/app/usr/bin/armsx2-qt" ]; then
  say "ARMSX2 $TAG is already installed."
else
  say "Downloading ARMSX2 $TAG"
  curl -fL --progress-bar -o "$TMP/armsx2.AppImage" "$URL"
  chmod +x "$TMP/armsx2.AppImage"
  # The AppImage unpacks itself (no FUSE needed). Unpack next to the install, then swap.
  rm -rf "$DEST/app.new" "$DEST/squashfs-root"
  (cd "$DEST" && "$TMP/armsx2.AppImage" --appimage-extract >/dev/null) || die "could not unpack the AppImage."
  [ -x "$DEST/squashfs-root/usr/bin/armsx2-qt" ] || die "the AppImage has no armsx2-qt."
  rm -f "$TMP/armsx2.AppImage"
  # Portable mode: ARMSX2 keeps its data in $DEST/ARMSX2, a path relative to the program folder.
  echo "../../../ARMSX2" > "$DEST/squashfs-root/usr/bin/portable.txt"
  mv "$DEST/squashfs-root" "$DEST/app.new"
  rm -rf "$DEST/app"
  mv "$DEST/app.new" "$DEST/app"
  echo "$TAG" > "$DEST/VERSION"
fi

# ---------------------------------------------------------------------------------------------
# 2. Settings on first install: ROCKNIX's folders, Vulkan at 2x, widescreen patches, MTVU,
#    the first gamepad and hotkeys. After that only ARMSX2's own menus change them.
# ---------------------------------------------------------------------------------------------
DATA="$DEST/ARMSX2"
INI="$DATA/inis/PCSX2.ini"
BIOS=/storage/roms/bios/PS2
[ -d "$BIOS" ] || BIOS=/storage/roms/bios
FIRST=0
if [ ! -f "$INI" ]; then
  FIRST=1
  mkdir -p "$DATA/inis" /storage/roms/saves/ps2
  cat > "$INI" <<EOF
[UI]
SettingsVersion = 1
SetupWizardIncomplete = false

[Folders]
Bios = $BIOS
MemoryCards = /storage/roms/saves/ps2

[GameList]
Paths = /storage/roms/ps2

[EmuCore]
EnableWideScreenPatches = true

[EmuCore/Speedhacks]
vuThread = true

[EmuCore/GS]
Renderer = 14
upscale_multiplier = 2

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

[Hotkeys]
OpenPauseMenu = SDL-0/LeftStick & SDL-0/RightStick
HoldTurbo = SDL-0/+LeftTrigger & SDL-0/+RightTrigger
LoadStateFromSlot = SDL-0/Guide & SDL-0/LeftShoulder
SaveStateToSlot = SDL-0/Guide & SDL-0/RightShoulder
EOF
fi

# Sets "key = value" in [section] of the ini (adds the section if needed).
ini_set() { # ini_set <section> <key> <value>
  python3 - "$INI" "$1" "$2" "$3" <<'EOF'
import sys
path, section, key, value = sys.argv[1:]
lines = open(path, encoding="utf-8").read().split("\n")
out, in_sec, done, seen = [], False, False, False
for line in lines:
    s = line.strip()
    if s.startswith("[") and s.endswith("]"):
        if in_sec and not done:
            out.append("%s = %s" % (key, value)); done = True
        in_sec = (s == "[%s]" % section); seen = seen or in_sec
        out.append(line); continue
    if in_sec and not done and s.split("=")[0].strip() == key:
        out.append("%s = %s" % (key, value)); done = True; continue
    out.append(line)
if in_sec and not done:
    out.append("%s = %s" % (key, value)); done = True
if not seen:
    out += ["", "[%s]" % section, "%s = %s" % (key, value)]
open(path, "w", encoding="utf-8").write("\n".join(out))
EOF
}
ini_get() { # ini_get <section> <key>
  python3 - "$INI" "$1" "$2" <<'EOF'
import sys
path, section, key = sys.argv[1:]
sec = None
for line in open(path, encoding="utf-8"):
    s = line.strip()
    if s.startswith("[") and s.endswith("]"):
        sec = s[1:-1]
    elif sec == section and "=" in s and s.split("=")[0].strip() == key:
        print(s.split("=", 1)[1].strip()); break
EOF
}

# ---------------------------------------------------------------------------------------------
# 3. malisx2, on a Mali GPU running Arm's kernel driver (ROCKNIX libmali mode) with Arm's
#    window-system layer (needed to show a picture under ROCKNIX's compositor). Installed the
#    way ARMSX2's own GPU Drivers page installs it, and selected there. ARMSX2 checks the GPU
#    itself and falls back to the system driver on a GPU malisx2 does not support.
#    Updated on every run unless you picked another driver in ARMSX2.
# ---------------------------------------------------------------------------------------------
WSI=""
for d in /usr/share/vulkan/implicit_layer.d /etc/vulkan/implicit_layer.d; do
  [ -f "$d/VkLayer_window_system_integration.json" ] && WSI=1
done
SELECTED=$(ini_get EmuCore/GS LinuxDriverPack)
if [ ! -e /dev/mali0 ]; then
  say "No Arm Mali kernel driver (/dev/mali0): malisx2 not installed, ARMSX2 uses the system Vulkan driver."
  say "(On ROCKNIX, malisx2 needs the libmali GPU driver mode, not panfrost.)"
elif [ -z "$WSI" ]; then
  say "Arm's Vulkan window-system layer is missing: malisx2 not installed, ARMSX2 uses the system Vulkan driver."
elif [ "$FIRST" = 0 ] && [ -n "$SELECTED" ] && [ "${SELECTED#malisx2-}" = "$SELECTED" ]; then
  say "You chose the driver pack '$SELECTED' in ARMSX2; malisx2 left alone."
elif [ "$FIRST" = 0 ] && [ -z "$SELECTED" ] && [ -f "$DEST/.msx2-installed" ]; then
  say "You chose the system Vulkan driver in ARMSX2; malisx2 left alone."
else
  say "Looking up the latest malisx2..."
  # One line each: tag, release name, archive URL, checksum URL.
  M=$(gh_json "https://api.github.com/repos/$MSX2_REPO/releases/latest" "'\n'.join([r['tag_name'], r['name'] or r['tag_name'],
    next(a['browser_download_url'] for a in r['assets'] if a['name'].endswith('-aarch64.tar.gz')),
    next(a['browser_download_url'] for a in r['assets'] if a['name'].endswith('-aarch64.tar.gz.sha256'))])") ||
    die "could not find a malisx2 release on GitHub."
  MTAG=$(echo "$M" | sed -n 1p)
  MNAME=$(echo "$M" | sed -n 2p)
  MURL=$(echo "$M" | sed -n 3p)
  MSUM_URL=$(echo "$M" | sed -n 4p)
  ID=$(echo "malisx2-$MTAG" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9._\n-' '_')
  PACK="$DATA/drivers/$ID"
  if [ "$SELECTED" = "$ID" ] && [ -f "$PACK/meta.json" ]; then
    say "malisx2 $MTAG is already installed and selected."
  else
    say "Downloading malisx2 $MTAG"
    curl -fL --progress-bar -o "$TMP/msx2.tar.gz" "$MURL"
    curl -fsSL -o "$TMP/msx2.sha256" "$MSUM_URL"
    WANT=$(cut -d' ' -f1 "$TMP/msx2.sha256")
    GOT=$(sha256sum "$TMP/msx2.tar.gz" | cut -d' ' -f1)
    [ -n "$WANT" ] && [ "$WANT" = "$GOT" ] || die "malisx2 download is damaged (checksum mismatch)."
    mkdir -p "$TMP/msx2"
    tar -xzf "$TMP/msx2.tar.gz" -C "$TMP/msx2"
    ICD=$(find "$TMP/msx2" -name 'malisx2_icd*.json' | head -n 1)
    [ -n "$ICD" ] && [ -f "$(dirname "$ICD")/libvulkan_malisx2.so" ] || die "the malisx2 package has no driver."
    rm -rf "$PACK.new"
    mkdir -p "$DATA/drivers"
    cp -R "$(dirname "$ICD")" "$PACK.new"
    python3 - "$PACK" "$PACK.new" "$(basename "$ICD")" "$ID" "$MNAME" "$MTAG" "$MURL" "$GOT" <<'EOF'
import json, os, sys, time
final, staged, icd_name, pack_id, name, tag, url, sha = sys.argv[1:]
icd_path = os.path.join(staged, icd_name)
icd = json.load(open(icd_path))
icd["ICD"]["library_path"] = os.path.join(final, "libvulkan_malisx2.so")
json.dump(icd, open(icd_path, "w"), indent=4)
about = {}
try:
    about = json.load(open(os.path.join(staged, "MANIFEST.json")))
except Exception:
    pass
meta = {
    "schemaVersion": 1, "id": pack_id, "name": name, "version": tag, "feed": "malisx2",
    "sourceUrl": url, "archiveSha256": sha, "installedAt": int(time.time()),
    "manifest": icd_name, "library": "libvulkan_malisx2.so",
    "buildTag": about.get("build_tag", ""), "driverInfoToken": about.get("driver_info_token", ""),
    "mesaVersion": about.get("mesa_version", ""), "platforms": about.get("platforms", ""),
    "gpu": "mali-kbase",
}
json.dump(meta, open(os.path.join(staged, "meta.json"), "w"), indent=2)
EOF
    rm -rf "$PACK"
    mv "$PACK.new" "$PACK"
    ini_set EmuCore/GS LinuxDriverPack "$ID"
    touch "$DEST/.msx2-installed"
    # Older malisx2 packs this script installed are no longer selected.
    for old in "$DATA"/drivers/malisx2-*; do
      [ -d "$old" ] && [ "$old" != "$PACK" ] && rm -rf "$old"
    done
    say "malisx2 $MTAG installed and selected (ARMSX2 > Settings > GPU Drivers)."
  fi
fi

# ---------------------------------------------------------------------------------------------
# 4. EmulationStation emulator entry and Tools menu entry.
# ---------------------------------------------------------------------------------------------
write_helpers
python3 "$DEST/es-setup.py" install "$DEST"
# ROCKNIX rebuilds /storage/.config/modules on every boot: a boot script puts the entry back.
mkdir -p /storage/.config/autostart
cat > "$HOOK" <<EOF
#!/bin/sh
# ARMSX2 Nightly: put its Tools menu entry back (ROCKNIX resyncs /storage/.config/modules on boot).
[ -f "$DEST/tools/$TOOLS_ENTRY" ] && cp -f "$DEST/tools/$TOOLS_ENTRY" /storage/.config/modules/ &&
  chmod +x "/storage/.config/modules/$TOOLS_ENTRY"
exit 0
EOF
chmod +x "$HOOK"
"$HOOK"

say ""
say "Done: ARMSX2 $TAG in $DEST."
say "Restart EmulationStation (or reboot), then pick the emulator \"armsx2-nightly\" in the PS2"
say "system's or a game's advanced settings. Tools > \"Start ARMSX2 Nightly\" opens its game list."
say "PS2 BIOS files go in $BIOS, games in /storage/roms/ps2."
say "Run this installer again to update; \"sh $DEST/uninstall.sh\" removes it."
