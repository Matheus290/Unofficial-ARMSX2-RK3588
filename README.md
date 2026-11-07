# ARMSX2 optimized for RK3588 (unofficial)

> **🇺🇸 Read first:** this is an **unofficial, experimental fork** of [ARMSX2](https://github.com/ARMSX2/ARMSX2), tuned for **RK3588** boards and handhelds (Orange Pi 5 and similar, Mali-G610 GPU). It has **no direct connection to the ARMSX2 project**: its changes have not been reviewed or accepted by the ARMSX2 developers. The intent is to help: improvements that prove themselves here may be proposed to ARMSX2 later, gradually. Meanwhile, anyone can install and test them.
>
> **Found a bug? Report it [here, on this fork](https://github.com/Matheus290/ARMSX2-RK3588/issues), never to the ARMSX2 project.**

> **🇧🇷 Leia antes:** este é um **fork não oficial e experimental** do [ARMSX2](https://github.com/ARMSX2/ARMSX2), otimizado para placas e portáteis **RK3588** (Orange Pi 5 e similares, GPU Mali-G610). Ele **não tem ligação direta com o projeto ARMSX2**: as mudanças não foram revisadas nem aceitas pelos desenvolvedores do ARMSX2. A intenção é ajudar: melhorias que se provarem boas aqui poderão ser propostas ao ARMSX2 mais adiante, aos poucos. Enquanto isso, qualquer pessoa pode instalar e testar.
>
> **Achou um bug? Reporte [aqui, neste fork](https://github.com/Matheus290/ARMSX2-RK3588/issues), nunca ao projeto ARMSX2.**

---

## Install

📖 **Step-by-step tutorial for ROCKNIX:** [English](https://github.com/Matheus290/ARMSX2-RK3588/blob/rk3588/rk3588/TUTORIAL-ROCKNIX.md) · [Português](https://github.com/Matheus290/ARMSX2-RK3588/blob/rk3588/rk3588/TUTORIAL-ROCKNIX.pt-BR.md)

**Requirements:** 64-bit ARM (aarch64) Linux on an RK3588 device, with a Vulkan driver for the Mali-G610 (Arm's libmali, recommended, or Mesa's Panfrost). It runs on a Wayland session (Weston, sway, GNOME, KDE…) or on a bare console (KMS). X11-only desktops are not supported. A PS2 BIOS dumped from your own console is required.

**Tested on:** Orange Pi 5, ROCKNIX 20261001, with libmali and Panfrost.

### One command (over SSH on ROCKNIX: `ssh root@<device-ip>`, password `rocknix`)

```sh
curl -fsSL https://raw.githubusercontent.com/Matheus290/ARMSX2-RK3588/rk3588/rk3588/install.sh | sh
```

### Or from the release package

Download `armsx2-rk3588-*-linux-arm64.tar.xz` from [Releases](https://github.com/Matheus290/ARMSX2-RK3588/releases), then:

```sh
tar -xJf armsx2-rk3588-*-linux-arm64.tar.xz
./armsx2-rk3588/install.sh
```

### What the installer does

| | ROCKNIX | Batocera | Other Linux |
|---|---|---|---|
| Program and settings | `/storage/armsx2-rk3588` | `~/.local/share/armsx2-rk3588` | `~/.local/share/armsx2-rk3588` |
| PS2 BIOS | `/storage/roms/bios/PS2` | `/userdata/bios` | `…/armsx2-rk3588/bios` |
| Games | `/storage/roms/ps2` | `/userdata/roms/ps2` | `~/Games/PS2` |
| Memory cards | `/storage/roms/saves/ps2` | `/userdata/saves/ps2` | `…/armsx2-rk3588/memcards` |
| How to start | EmulationStation: PS2 emulator **armsx2-rk3588** | add it to your frontend (below) | applications menu, or `armsx2-rk3588 [game]` |

- **ROCKNIX:** the installer adds **armsx2-rk3588** to the PS2 system's emulator list, next to the emulators you already have; nothing is removed. Restart EmulationStation, then pick it in *GAME SETTINGS → PER SYSTEM ADVANCED CONFIGURATION → PlayStation 2 → EMULATOR* (or per game in *ADVANCED GAME OPTIONS*). Under the hood, the PS2 launch command points to `es_launch.sh`. That script starts this emulator through ROCKNIX's `runemu.sh`, so the performance profile and exit hotkey still apply, and it passes every other emulator on to the previous command. Your systems file is backed up as `es_systems.cfg.bak-armsx2-rk3588`.
- **Other frontends (Batocera, other EmulationStation builds, Pegasus…):** add an emulator or command that runs `/path/to/armsx2-rk3588/armsx2-rk3588.sh "/path/to/game.chd"`. `ARMSX2_RK3588_DEST=/folder` picks the install folder, and `ARMSX2_RK3588_NO_SHORTCUTS=1` skips registration.
- **First install defaults:** Vulkan at 2x native resolution, smooth bilinear output, widescreen patches, MTVU and IOP thread on, GS back thread on, *MaliOrderedInputAttachment* on, and the first controller mapped. These are only defaults: change anything in the emulator's menu and it stays changed. Updates never touch your settings.
- **Updating:** run the installer again. **Uninstalling:** run `uninstall.sh` in the install folder. It puts the PS2 launch command back and asks before deleting your settings and save states.

### Controls

| Action | Buttons |
|---|---|
| Open the emulator menu | L3 + R3 |
| Fast forward (hold) | L2 + R2 |
| Save state / load state | Guide + R1 / Guide + L1 |

---

## What is different from the official ARMSX2

Every change is a separate commit on the `rk3588` branch. [rk3588/CHANGES.md](https://github.com/Matheus290/ARMSX2-RK3588/blob/rk3588/rk3588/CHANGES.md) lists them and says which ones only act on Mali GPUs.

**Mali GPU (detected automatically; other GPUs are not affected)**
- Faster rendering of effects that read the screen back (feedback loops) on Mali's tile-based GPU: fewer render passes per frame.
- Fewer texture descriptor updates per frame on drivers without push descriptors (Arm's driver).
- Burnout Revenge no longer closes on the first track with Arm's driver: lines are not expanded in the vertex shader there. A "Mali Line Crash Fix" option can force this on or off.
- Burnout Revenge: the sun no longer shows through bridges.
- Panfrost (PanVK): fixed a driver crash when the window is resized.

**Specific games (any device)**
- Burnout Revenge: the sun sprite lines up with the screen (texture offset fix in the game database).
- God of War: IOP thread timing tuned for the game.

**Emulator core and frontend (any device)**
- The EE no longer waits for the whole GS queue to drain when a GIF path buffer fills up. This fixes slowdowns with sparks and particle effects (Burnout Revenge, God of War II).
- On big.LITTLE CPUs, the IOP thread is kept off the fast core that the GS back thread uses.
- Frames that could not be displayed are skipped in mailbox mode too.
- On Wayland, rendering follows the window's real size; on Panfrost it used to render at 1280x720.
- The pause menu works when a game is started by EmulationStation (it used to close the emulator).
- Switching renderer keeps the vsync setting.
- Pause menu: the hotkey toggles it, it reopens on the item you left, it shows the selection cursor, and choice lists open on the current option.
- The menu clock follows EmulationStation's 12/24-hour setting.
- Built with profile-guided optimization (PGO) and LTO for the Cortex-A76/A55.

## Known issues

- **Experimental:** expect bugs that the official build does not have. If a game misbehaves, check whether the official ARMSX2 does the same, and mention it in your report here.
- On Panfrost, some heavy scenes run noticeably slower than on Arm's libmali (Shadow of the Colossus temple: ~68% vs ~94%). That comes from the driver.
- Only tested on RK3588 with a Mali-G610.

## Source code and license

ARMSX2 is based on [PCSX2](https://github.com/PCSX2/pcsx2) and licensed under the **GNU GPL v3** (see `COPYING.GPLv3`). Each release is built from the release's tag in this repository, and GitHub attaches that exact source to every release. [rk3588/BUILDING.md](https://github.com/Matheus290/ARMSX2-RK3588/blob/rk3588/rk3588/BUILDING.md) explains how to build it.

All credit for the emulator goes to the PCSX2 and ARMSX2 developers. This fork only adds an experimental set of changes on top of their work.

PlayStation 2 is a trademark of Sony Interactive Entertainment. This project is not affiliated with Sony. No BIOS or games are included: use dumps of your own console and discs.
