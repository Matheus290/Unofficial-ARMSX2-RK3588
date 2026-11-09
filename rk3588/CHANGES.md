# Changes in rk3588-2026.11.09

New since rk3588-2026.11.07:

- FullscreenUI: open Game Properties for a game the game list does not have
- SDL: load the game list from its cache for a game started from the command line *(SDL)*
- ROCKNIX installer: adds "Start ARMSX2 RK3588" to the Tools menu, kept there by a boot script *(ROCKNIX only)*
- Documentation: tested only on ROCKNIX; Batocera and other Linux systems are untested

# Changes in rk3588-2026.11.07

Commits on top of ARMSX2 (master of 2026-11-06), oldest first.
*(Mali)*: only takes effect on Mali GPUs, or on one Mali driver. *(game)*: only for that game. *(SDL)*: Linux SDL frontend only. Unmarked: affects every device.

- GS/Vulkan: carry the feedback loop on Mali's input-attachment road *(Mali)*
- VMManager: keep the GS back thread's fast core free of the IOP thread (big.LITTLE CPUs)
- SDL: scan the game list once at startup *(SDL)*
- GS/Vulkan: add MaliOrderedInputAttachment *(Mali; off by default in ARMSX2, on in this build's starting settings)*
- SDL: add the --stream-rings-cached measurement flag *(SDL; diagnostics)*
- GS/Vulkan: reuse TFX texture descriptor sets within a command buffer *(drivers without push descriptors: Mali's)*
- GameDB: add iopThreadLag; bind God of War's IOP thread to the tight lag *(game)*
- render-pass diagnostics (ARMSX2_RP_DIAG environment variable) *(diagnostics, off unless set)*
- GS: skip presents above the refresh rate on mailbox too
- Android: build rcheevos from the root 3rdparty copy *(Android build only)*
- Achievements: append the rcheevos clause to the User-Agent
- GameDB: align Burnout Revenge to native with the texture offset (HPO 5) *(game)*
- GS/Vulkan: store a carried pass before a draw that samples its own target *(Mali)*
- FullscreenUI: the pause menu hotkey closes the menu and reopens it where it was
- FullscreenUI: follow EmulationStation's 12/24-hour clock in the menu heading *(only when EmulationStation is installed)*
- GS/Vulkan: don't expand lines in the vertex shader on Arm's Mali driver *(Mali, Arm's driver)*
- GS: add MaliLineExpandFix to force the Mali line workaround on or off *(Mali)*
- GS: reopen a new device with the vsync mode the settings ask for
- GameDB: reword the Burnout Revenge provenance comment *(game)*
- FullscreenUI: keep the scroll and focused item when the pause hotkey reopens the menu
- GIF: wait for the MTGS to free path buffer space, not to drain its queue
- FullscreenUI: put the focus back on the item the pause hotkey left
- ImGuiFullscreen: show the selection on a window that takes the focus
- ImGuiFullscreen: open a choice dialog on the option that is already chosen
- FullscreenUI: refresh the menu clock format wherever the menu pauses the game
- GS/Vulkan: don't use swapchain_maintenance1 on PanVK *(Mali, Panfrost driver)*
- SDL: resize the display when the Wayland window changes size *(SDL, Wayland)*
- SDL: keep a command-line game running while its pause menu is open *(SDL)*
