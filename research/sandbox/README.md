# Isolated Windows-game reference desktop

Purpose: run the user-supplied repack for observation, separate from the original Godot implementation. This is a compatibility study using Wine on Linux, not a genuine Windows Sandbox VM and not yet a claim about which original release is inside the repack.

`Dockerfile` builds Debian Bookworm with 32-bit Wine, a virtual X display, Openbox and noVNC. The installer is provided only in the ignored build context as `installer.exe`; it is not committed or included in game assets. `start.sh` initializes a disposable Wine prefix and opens the local desktop service. Starting the installer is a separate explicit step.

Runtime controls:

- Dedicated internal Docker network, with no external route.
- Desktop service published on host loopback only.
- Non-root UID 1000, dropped capabilities and no-new-privileges.
- Read-only image filesystem; disposable writable home and temporary files.
- No host folder mounts, Docker socket or personal-file access.
- Memory, CPU and process limits.

The container network can still reach its own network gateway as described in Docker's internal-network documentation; it is not represented as an air-gapped VM. No host services or directories are intentionally shared except the loopback desktop connection.

Compatibility and observed game-version details will be recorded in the mechanics ledger. Installed third-party assets stay in the reference environment. Do not copy them into the game project.

The isolated target and the browser connection use separate containers. `oregon-reference-study` has only the internal network; `oregon-reference-desktop` bridges a loopback-only host port to one fixed desktop endpoint. The relay has no file mounts and does not offer general HTTP proxying. Its default bridge attachment enables host loopback publishing; the game container itself has no external route.

Build using `build-reference.ps1`, then create a fresh environment with `start-reference.ps1`. The supplied installer must already be available in the ignored local library or passed through `-Installer`. The desktop URL is `http://127.0.0.1:6090/vnc.html?autoconnect=1&resize=off`.

The current installer was successfully run inside Wine. It installs DOSBox 0.74-3 and a Windows 3.11 environment, from which the MECC game was launched. The game shows a 1993 copyright. No numeric application version has been verified. Repack wrapper/emulator settings are separate from the original game's rules.
