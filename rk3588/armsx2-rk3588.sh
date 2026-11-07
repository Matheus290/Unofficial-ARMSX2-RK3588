#!/bin/sh
# ARMSX2 RK3588 (experimental) launcher.
# Usage: armsx2-rk3588.sh [game file]   (no game: opens the game list)
# Settings, memory cards and save states live next to this script (portable mode). Renderer and
# everything else are set in the emulator's own settings menu.

DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)

[ -f /etc/profile ] && . /etc/profile >/dev/null 2>&1

export LANG="${LANG:-en_US.UTF-8}"
# ROCKNIX: PulseAudio, and let the "kill" hotkey close the emulator.
if [ -d /storage/.config ]; then
  export SDL_AUDIODRIVER=pulseaudio
  command -v set_kill >/dev/null 2>&1 && set_kill set "-9 armsx2-sdl"
fi
[ -n "$WAYLAND_DISPLAY" ] && export SDL_VIDEO_DRIVER=wayland

cd "$DIR" || exit 1
# stdin comes from /dev/null: EmulationStation starts emulators with descriptor 0 closed, so the
# emulator's first open() got 0, which its file mapping treats as a failure ("Failed to load font").
if [ -n "$1" ]; then
  exec ./armsx2-sdl "$@" < /dev/null > "$DIR/stdout.log" 2>&1
else
  exec ./armsx2-sdl -bigpicture < /dev/null > "$DIR/stdout.log" 2>&1
fi
