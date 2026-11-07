# Tutorial: installing the unofficial ARMSX2 RK3588 build on ROCKNIX

*[Versão em português](TUTORIAL-ROCKNIX.pt-BR.md)*

This guide takes you from nothing to playing PS2 games from ROCKNIX's EmulationStation, with ARMSX2 RK3588 added as one more emulator in the PS2 list. It takes about 10 minutes.

> This is an **experimental, unofficial** build not affiliated with or endorsed by the ARMSX2 project. If something goes wrong, do **not** report it to ARMSX2: open an [issue on this fork](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues).

---

## What you need

- An **RK3588** device running **ROCKNIX** (Orange Pi 5, Orange Pi 5 Plus, Rock 5B, RK3588 handhelds…).
- The device **on your network** (Wi-Fi or cable), the same network as your computer.
- A **computer** (Windows, macOS or Linux) to reach the device over the network.
- A **PS2 BIOS** dumped from your own console (`.bin` files, sometimes with `.mec`/`.nvm`). No BIOS is included.
- Your **PS2 games** (`.iso`, `.chd`, `.cso`…).

---

## Step 1: turn on SSH and find the IP address

SSH lets you type commands on the device from your computer.

1. In EmulationStation, press **Start** to open the main menu.
2. Go to **NETWORK SETTINGS** and turn on **ENABLE SSH**. On some versions it is under **SYSTEM SETTINGS → NETWORK SERVICES**.
3. Note the device's **IP address**, shown in the network settings (or in **INFORMATION**). For example: `192.168.0.50`.

> Tip: many networks also accept the device name instead of the IP, such as `rocknix.local` or `RK3588.local`.

---

## Step 2: copy the BIOS and games

If you already use another PS2 emulator on ROCKNIX, this is probably done: skip to Step 3.

1. In the same network menu, turn on **ENABLE SAMBA** so the device's folders show up on the network.
2. On the computer, open the shared folder:
   - **Windows:** in File Explorer, type `\\192.168.0.50` (your IP) in the address bar.
   - **macOS:** in Finder, *Go → Connect to Server*, then `smb://192.168.0.50`.
   - **Linux:** in your file manager, type `smb://192.168.0.50`.
   - If asked to log in, use user `root` and password `rocknix`.
3. Copy:
   - **PS2 BIOS** → `roms/bios/PS2/` (create the `PS2` folder if it is missing)
   - **PS2 games** → `roms/ps2/`

---

## Step 3: connect over SSH

1. Open a terminal on the computer:
   - **Windows:** open **PowerShell** (search for "PowerShell" in the Start menu).
   - **macOS:** open the **Terminal** app.
   - **Linux:** open your terminal.
2. Type this (with your IP) and press Enter:

   ```sh
   ssh root@192.168.0.50
   ```

3. The first time, it asks whether you trust the device: type `yes` and press Enter.
4. The password is **`rocknix`**. Nothing shows on screen while you type it; that is normal. Press Enter.

When you see something like `RK3588:~ #`, you are in.

---

## Step 4: install

Copy this command, paste it in the terminal and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/Matheus290/Unofficial-ARMSX2-RK3588/rk3588/rk3588/install.sh | sh
```

The installer:

- downloads the latest release and installs it in `/storage/armsx2-rk3588`;
- adds **armsx2-rk3588** to EmulationStation's PS2 emulator list, **without removing** the emulators you already have;
- on a first install, sets everything up:
  - BIOS from `roms/bios/PS2` and games from `roms/ps2`;
  - memory cards in `roms/saves/ps2`, shared with the other PS2 emulators;
  - the controller mapped;
  - Vulkan at 2x resolution, smooth filtering, widescreen patches, and the MTVU and IOP threads on.

It ends with **Done.** You can close the terminal.

> No internet on the device? Download `armsx2-rk3588-*-linux-arm64.tar.xz` from [Releases](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/releases), copy it to the shared folder (for example `roms/`), then over SSH run:
> ```sh
> cd /storage/roms && tar -xJf armsx2-rk3588-*-linux-arm64.tar.xz && ./armsx2-rk3588/install.sh
> ```

---

## Step 5: restart EmulationStation

On the device, press **Start** → **QUIT** → **RESTART EMULATIONSTATION**, or reboot.

---

## Step 6: pick ARMSX2 RK3588 as the PS2 emulator

You can pick it for **all PS2 games** or **only some of them**.

**For all PS2 games:**

1. Press **Start** → **GAME SETTINGS** → **PER SYSTEM ADVANCED CONFIGURATION** → **PlayStation 2**.
2. Set **EMULATOR** to **armsx2-rk3588**.

**For one game only:**

1. In the PS2 game list, highlight the game and open its options (usually with **Select**), then **ADVANCED GAME OPTIONS**.
2. Set **EMULATOR** to **armsx2-rk3588**.

Then start games from the list as usual.

---

## Controls

The first controller is mapped automatically (Xbox, PlayStation or a handheld's built-in pad).

| Action | Buttons |
|---|---|
| Open the emulator menu | **L3 + R3** (press both sticks) |
| Fast forward (hold) | **L2 + R2** |
| Save state | **Guide/Home + R1** |
| Load state | **Guide/Home + L1** |

To **quit a game** and go back to EmulationStation, open the menu (L3 + R3) and choose the option to close the game. ROCKNIX's exit hotkey (usually **Select + Start**) also works.

Everything can be remapped in the emulator's menu under *Settings → Controllers* and *Hotkeys*.

---

## Updating

Run the Step 4 command again. It only replaces the program; your settings, memory cards and save states stay.

## Uninstalling

Over SSH:

```sh
/storage/armsx2-rk3588/uninstall.sh
```

It removes the emulator from EmulationStation's list and puts everything back as it was. It asks before deleting your settings and save states. Memory cards in `roms/saves/ps2` are not touched.

---

## Troubleshooting

**"armsx2-rk3588" is not in the emulator list**
Restart EmulationStation (Step 5). If another PS2 emulator is installed later and replaces the PS2 settings, run the installer again.

**The game does not start, or goes straight back to the list**
Check that the BIOS is in `roms/bios/PS2`. The log is at `/storage/armsx2-rk3588/logs/emulog.txt`; attach it if you open an issue.

**Slow, or the picture looks wrong**
ROCKNIX can use Arm's video driver (*libmali*) or *Panfrost*. This build runs best on **libmali**; some heavy scenes are much slower on Panfrost. Some games also run better at 1x: open the menu (L3 + R3) → *Settings → Graphics* and lower the internal resolution.

**Found a bug?**
Open an [issue here](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues). Include your device, the game, what happened, and the `emulog.txt` file. Please do **not** report it to the original ARMSX2 project.
