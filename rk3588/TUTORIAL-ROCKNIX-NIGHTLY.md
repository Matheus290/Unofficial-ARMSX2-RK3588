# Tutorial: official ARMSX2 Nightly + malisx2 on ROCKNIX

*[Versão em português](TUTORIAL-ROCKNIX-NIGHTLY.pt-BR.md)*

This guide installs the **official ARMSX2 nightly** together with the **malisx2** Vulkan driver. When you finish, it shows up as one more PS2 emulator in ROCKNIX's EmulationStation. It takes about 10 minutes.

ROCKNIX still ships an older ARMSX2 that has no malisx2 support. Use this installer to run the new version until ROCKNIX includes it.

> The **installer** is an unofficial script from this repository. The **emulator** and **malisx2** are downloaded, unmodified, from their official repositories: [ARMSX2/ARMSX2](https://github.com/ARMSX2/ARMSX2/releases) and [bmdhacks/malisx2](https://github.com/bmdhacks/malisx2/releases).
>
> Tested **only** on ROCKNIX 20261001, on an Orange Pi 5 (RK3588, Mali-G610), with the **libmali** GPU driver.

---

## What you need

- A device with a **Mali** GPU running **ROCKNIX**. Only the RK3588 has been tested. On other chips the installer works, but malisx2 may not support them.
- ROCKNIX set to the **libmali** GPU driver, not Panfrost (see Step 1). malisx2 runs on Arm's kernel driver, which only exists in libmali mode.
- The device **online**, on the same network as your computer.
- A **computer** (Windows, macOS or Linux) to reach the device over the network.
- The **PS2 BIOS**, dumped from your own console. No BIOS is included.
- Your **PS2 games** (`.iso`, `.chd`, `.cso`…).

---

## Step 1: check ROCKNIX's GPU driver

1. In EmulationStation, press **Start** → **SYSTEM SETTINGS**.
2. Find the **GPU DRIVER** option and set it to **libmali**.
3. If you had to change it, the change takes effect after a reboot: **Start** → **QUIT** → **REBOOT**.

To check over SSH (Step 4), `/dev/mali0` must exist: `ls /dev/mali0`.

---

## Step 2: turn on SSH and find the IP address

1. In EmulationStation, press **Start** → **NETWORK SETTINGS** and turn on **ENABLE SSH**. Some versions have it under **SYSTEM SETTINGS → NETWORK SERVICES**.
2. Write down the device's **IP address**, for example `192.168.0.50`. It is shown in the network settings or under **INFORMATION**.

> Tip: many networks also accept the device's name instead of the IP, such as `rocknix.local` or `RK3588.local`.

---

## Step 3: copy the BIOS and the games

If you already use another PS2 emulator on ROCKNIX, this is probably done: skip to Step 4.

1. In the network menu, turn on **ENABLE SAMBA**.
2. On the computer, open the shared folder:
   - **Windows:** in File Explorer, type `\\192.168.0.50` (use your IP) in the address bar.
   - **macOS:** in Finder, *Go → Connect to Server*, and type `smb://192.168.0.50`.
   - **Linux:** in your file manager, type `smb://192.168.0.50`.
   - If asked to log in, use user `root` and password `rocknix`.
3. Copy the files:
   - **PS2 BIOS** → `roms/bios/PS2/` (create the `PS2` folder if it does not exist)
   - **PS2 games** → `roms/ps2/`

---

## Step 4: log in to the device over SSH

1. Open a terminal on the computer:
   - **Windows:** **PowerShell** (search for "PowerShell" in the Start menu).
   - **macOS:** the **Terminal** app.
   - **Linux:** your distribution's terminal.
2. Type this, with your IP, and press Enter:

   ```sh
   ssh root@192.168.0.50
   ```

3. The first time, it asks whether you trust the device: type `yes` and press Enter.
4. The password is **`rocknix`**. Nothing appears on screen while you type it; that is normal. Press Enter.

When you see something like `RK3588:~ #`, you are in.

---

## Step 5: download the installer and install

1. On the computer, open the [Releases page](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/releases/latest) and, under **Assets**, click **`install-armsx2-nightly-malisx2.sh`** to download it.
2. Copy the file to the device, either:
   - through the **shared folder** from Step 3: put the file inside `roms/`;
   - or with **FileZilla** (SFTP protocol, host `sftp://192.168.0.50`, user `root`, password `rocknix`): drag the file into the starting folder, `/storage`.
3. In the terminal from Step 4, run the command that matches where you put the file:

   ```sh
   sh /storage/roms/install-armsx2-nightly-malisx2.sh
   ```

   or, if you used FileZilla:

   ```sh
   sh /storage/install-armsx2-nightly-malisx2.sh
   ```

> If the browser saves the file under another name (for example with `(1)` at the end), rename it to `install-armsx2-nightly-malisx2.sh` before copying.
>
> Shortcut if you are used to the terminal: this command downloads and runs the installer in one go.
> ```sh
> curl -fsSL https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/releases/latest/download/install-armsx2-nightly-malisx2.sh | sh
> ```

The installer:

- downloads the **latest ARMSX2 nightly** (the Linux arm64 Qt build) and installs it to `/storage/armsx2-nightly-qt`;
- downloads the **latest malisx2**, checks its checksum and **selects** it in ARMSX2. The driver shows up under *Settings → GPU Drivers*;
- adds **armsx2-nightly** to the PS2 emulator list in EmulationStation, **without removing** the emulators you already have;
- adds **Start ARMSX2 Nightly** to the **Tools** menu;
- on the first install, sets everything up:
  - BIOS in `roms/bios/PS2` and games in `roms/ps2`;
  - memory cards in `roms/saves/ps2`, shared with the other PS2 emulators;
  - the first controller mapped;
  - Vulkan at 2x resolution, widescreen patches and MTVU on.

At the end it prints **Done**. You can close the terminal.

---

## Step 6: restart EmulationStation

On the device, press **Start** → **QUIT** → **RESTART EMULATIONSTATION**. Rebooting also works.

---

## Step 7: pick ARMSX2 Nightly as the PS2 emulator

**For every PS2 game:**

1. Press **Start** → **GAME SETTINGS** → **PER SYSTEM ADVANCED CONFIGURATION** → **PlayStation 2**.
2. Under **EMULATOR**, choose **armsx2-nightly**.

**For a single game:**

1. In the PS2 game list, select the game and open its options (usually with **Select**). Go to **ADVANCED GAME OPTIONS**.
2. Under **EMULATOR**, choose **armsx2-nightly**.

Now start the game from the list as usual.

---

## Step 8 (recommended): scan your games from the Tools menu

1. Open **Tools → Start ARMSX2 Nightly**. The emulator opens on its own game list, without starting a game.
2. Under **Settings → Game List**, choose **Scan For New Games**. Do this again whenever you add games. You can download covers there too.
3. To check the driver, open **Settings → GPU Drivers**: **malisx2** should be selected.
4. Close the emulator.

---

## Controls

The first controller is already mapped.

| Action | Buttons |
|---|---|
| Open the emulator menu | **L3 + R3** (press both sticks) |
| Fast forward (hold) | **L2 + R2** |
| Save state | **Guide/Home + R1** |
| Load state | **Guide/Home + L1** |

To **quit a game**, open the menu (L3 + R3) and choose the option to close the game. ROCKNIX's exit hotkey (usually **Select + Start**) also works.

---

## Updating

Run the installer again as in Step 5 (the same file works). It downloads the newest nightly and malisx2 when there are new versions. Your settings, memory cards and save states stay as they are. If you picked another driver under *GPU Drivers*, the installer keeps your choice.

## Uninstalling

Over SSH:

```sh
sh /storage/armsx2-nightly-qt/uninstall.sh
```

It removes the emulator from EmulationStation's list and the Tools entry. It asks before deleting your settings and save states. The memory cards in `roms/saves/ps2` are not touched.

---

## Common problems

**The installer says "malisx2 not installed"**
ROCKNIX is in Panfrost mode. Go back to Step 1, switch to **libmali** and run the installer again. Without malisx2, ARMSX2 uses the system's video driver. That combination (nightly without malisx2) has not been tested.

**"armsx2-nightly" is not in the emulator list**
Restart EmulationStation (Step 6). If another PS2 emulator is installed later and changes the PS2 settings, run the installer again.

**The game does not start, or goes straight back to the list**
Check that the BIOS is in `roms/bios/PS2`. The logs are `/storage/armsx2-nightly-qt/stdout.log` and `/storage/armsx2-nightly-qt/ARMSX2/logs/emulog.txt`.

**"Start ARMSX2 Nightly" is not in Tools**
Restart EmulationStation. ROCKNIX rebuilds the Tools folder on every boot, and a boot script (`/storage/.config/autostart/armsx2-nightly-tools.sh`) puts the entry back. If that file is gone, run the installer again.

**Found a bug?**
- Problems with the **installer** or the EmulationStation/Tools entries: open an [issue here](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues).
- The **emulator** and **malisx2** are the official builds, unmodified. Their bugs belong to their own projects. Follow each project's guidelines, and say you installed with this script.
