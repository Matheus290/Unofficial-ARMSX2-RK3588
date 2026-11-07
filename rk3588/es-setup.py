#!/usr/bin/env python3
"""Add or remove ARMSX2 RK3588 as a PS2 emulator in ROCKNIX's EmulationStation.

usage: es-setup.py install|uninstall <install dir>

install:   adds an "armsx2-rk3588" emulator to the ps2 system and points the
           ps2 <command> at <install dir>/es_launch.sh. The program the command used before is saved
           in <install dir>/es_previous_command, and es_launch.sh passes every other emulator to it,
           so the emulators that were already there keep working.
uninstall: puts the previous program back and removes the emulator entry.
Only the ps2 <system> block is touched; the rest of the file is kept byte for byte.
"""
import os
import re
import shutil
import sys

USER_CFG = "/storage/.config/emulationstation/es_systems.cfg"
SYSTEM_CFG = "/usr/config/emulationstation/es_systems.cfg"
BACKUP = USER_CFG + ".bak-armsx2-rk3588"

ENTRY = (
    '\t\t\t<emulator name="armsx2-rk3588">\n'
    "\t\t\t\t<cores>\n"
    '\t\t\t\t\t<core default="true">armsx2-rk3588-sa</core>\n'
    "\t\t\t\t</cores>\n"
    "\t\t\t</emulator>\n"
)
ENTRY_RE = re.compile(r'[ \t]*<emulator name="armsx2-rk3588">.*?</emulator>[ \t]*\n', re.S)


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
        block = ENTRY_RE.sub("", block)  # replace an entry from an older version
        i = block.rfind("</emulators>")
        if i < 0:
            sys.exit("es-setup: the ps2 system has no <emulators> list")
        line_start = block.rfind("\n", 0, i) + 1
        block = block[:line_start] + ENTRY + block[line_start:]
    else:
        if program == launcher:
            prev = "/usr/bin/runemu.sh"
            if os.path.exists(prev_file):
                prev = open(prev_file).read().strip() or prev
            block = block[: cmd.start(1)] + prev + block[cmd.end(1):]
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
