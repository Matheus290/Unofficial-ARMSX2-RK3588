#!/bin/bash
# EmulationStation entry point for the PS2 system (ROCKNIX), installed by ARMSX2 RK3588.
# Games set to the "armsx2-rk3588" emulator start here, through runemu.sh's "shell" platform so
# ROCKNIX still applies its CPU/GPU performance settings. Every other PS2 emulator is passed on,
# unchanged, to whatever command the PS2 system used before (saved in es_previous_command).
HERE="$(dirname "$(readlink -f "$0")")"

case "$*" in
  *--emulator=armsx2-rk3588*)
    LAUNCHER="/tmp/armsx2-rk3588-launch.sh"
    printf '#!/bin/bash\nexec %q %q\n' "${HERE}/armsx2-rk3588.sh" "$1" >"${LAUNCHER}"
    chmod +x "${LAUNCHER}"
    shift
    ARGS="$*"
    exec /usr/bin/runemu.sh "${LAUNCHER}" -Pshell --core=armsx2-rk3588-sa --emulator=armsx2-rk3588 \
      --controllers="${ARGS#*--controllers=}"
    ;;
  *)
    PREV="/usr/bin/runemu.sh"
    [ -s "${HERE}/es_previous_command" ] && PREV="$(cat "${HERE}/es_previous_command")"
    [ -x "${PREV}" ] || PREV="/usr/bin/runemu.sh"
    exec "${PREV}" "$@"
    ;;
esac
