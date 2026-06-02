# Steam Deck — Claude Code Environment

## System

- **OS:** SteamOS 3.7.25 (holo) — Arch-based, read-only root filesystem
- **Arch:** x86_64
- **User:** deck (`/home/deck`)
- **Shell:** bash
- **Python:** 3.13.1 (`/usr/bin/python3`)

The root filesystem is immutable. Persistent package installs go through:
- `flatpak` (system/user scope)
- `pip3 --user` (Python packages into `~/.local`)
- Homebrew at `/home/deck/homebrew/` (Decky Loader plugins/services)
- Direct installs into `/home/deck/` subdirectories

## Key Tools Available

| Tool | How to run |
|---|---|
| **Lutris** | `flatpak run net.lutris.Lutris` |
| **ProtonUp-Qt** | `flatpak run net.davidotek.pupgui2` |
| **Heroic Launcher** | `flatpak run com.heroicgameslauncher.hgl` |
| **Protontricks** | `flatpak run com.github.Matoking.protontricks` |
| **Flatpak** | `/usr/bin/flatpak` |
| **Steam** | `/usr/bin/steam` |

### Playwright

Not yet installed. To install:
```bash
pip3 install --user playwright
python3 -m playwright install chromium
```

Then run scripts with:
```bash
python3 script.py
# or
python3 -m playwright codegen
```

For headed browser use on Desktop Mode, `DISPLAY` must be set (it is when running in KDE).

## Directory Layout

```
/home/deck/
├── Applications/       # AppImages and standalone app binaries (DuckStation, PCSX2, ES-DE, etc.)
├── Desktop/
├── Documents/
├── Downloads/          # Original ROM archives kept here as source
├── Emulation/          # EmuDeck game library
│   ├── roms/           # ROMs by system (psx/, ps2/, gamecube/, etc.)
│   ├── bios/           # PS1 and other system BIOS files
│   ├── saves/          # Save files and save states (internal storage)
│   └── storage/        # Emulator cache, covers, textures
├── ES-DE/              # EmulationStation frontend config
├── Games/              # Non-Steam game installs
├── emudeck/            # EmuDeck configuration/scripts
├── homebrew/           # Decky Loader (plugins/, services/, settings/)
├── stl/                # Steam Tinker Launch
└── projects/           # Code projects
```

### Storage

- **Internal SSD** (`/dev/nvme0n1p8`): 224 GB total, mounted at `/home`
- **SD card** (`/dev/mmcblk0p1`, label `SN01T`): mounted at `/run/media/deck/SN01T`
- All emulator saves and ROMs are on internal storage

## Emulation Stack

The standalone emulator AppImages are in `~/Applications/` — EmuDeck installs them there, not as flatpaks.

| Emulator | Binary / Command | System |
|---|---|---|
| DuckStation | `~/Applications/DuckStation.AppImage` | PS1 |
| PCSX2 | `~/Applications/pcsx2-Qt.AppImage` | PS2 |
| RPCS3 | `~/Applications/rpcs3.AppImage` | PS3 |
| Vita3K | `~/Applications/Vita3K` | PS Vita |
| Cemu | `~/Applications/Cemu.AppImage` | Wii U |
| Dolphin | `flatpak run org.DolphinEmu.dolphin-emu` | GC/Wii |
| PrimeHack | `flatpak run io.github.shiiion.primehack` | Metroid Prime |
| PPSSPP | `flatpak run org.ppsspp.PPSSPP` | PSP |
| melonDS | `flatpak run net.kuribo64.melonDS` | DS |
| xemu | `flatpak run app.xemu.xemu` | Xbox |
| Supermodel | `flatpak run com.supermodel3.Supermodel` | Model 3 |
| ScummVM | `flatpak run org.scummvm.ScummVM` | ScummVM |
| RetroArch | `flatpak run org.libretro.RetroArch` | Multi |
| ES-DE | `~/Applications/ES-DE.AppImage` | Frontend |

### ROM directories (`~/Emulation/roms/`)

- **PS1** (`psx/`) — `.bin`+`.cue` for standard discs, `.pbp` for EBOOT format
- **PS2** (`ps2/`) — `.iso`

### BIOS

- **PS1** BIOS — `~/Emulation/bios/` (scph5500/5501/5502.bin already present)
- **PS2** BIOS — `~/.config/PCSX2/bios/` (scph10000, scph39001, SCPH-70004 PAL installed)

### Save / state paths (all on internal storage)

- **DuckStation** saves: `~/Emulation/saves/duckstation/saves/`
- **DuckStation** states: `~/Emulation/saves/duckstation/states/`
- **PCSX2** memory cards: `~/Emulation/saves/pcsx2/saves/`
- **PCSX2** save states: `~/Emulation/saves/pcsx2/states/`

> Both emulators were previously misconfigured pointing at a dead SD card UUID path. They have been corrected to internal storage paths above.

### PCSX2 cheats / patches

`.pnach` files go in `~/.config/PCSX2/cheats/`. PCSX2 matches them by game CRC.

### Installed games

**PS1** (`~/Emulation/roms/psx/`):
- Alone in the Dark: The New Nightmare (USA) — Disc 1 & 2
- BH2 (RE1.5 MZD prototype) — `BH2.bin/cue`
- Biohazard 1.5 (MZD Mod) Update 25-01-2025 — xdelta variant patches kept in `~/Downloads/`
- Destrega (Europe)
- Evil Zone (USA) — Uncensored
- Galerians (USA) — Disc 1, 2 & 3
- Ghost in the Shell (USA)
- Gran Turismo 2 Deluxe (v0.1a) — fan-made patch
- Granstream Saga, The (USA)
- Klonoa: Door to Phantomile (USA)
- Koudelka (USA) — Disc 1, 2, 3 & 4
- Monkey Magic (NTSC-U) — EBOOT.PBP format
- Parasite Eve Font Hack v1.0 (USA) — Disc 1 & 2
- RE Unicorn CUT (Update Fix 11-17-2024) — .BIN only; .cue created manually (MODE2/2352)
- Silent Hill (Europe)
- Tekken 3 (USA)
- Tomba! 2: The Evil Swine Return (USA)
- Vagrant Story (USA)

**PS2** (`~/Emulation/roms/ps2/`):
- Klonoa 2: Lunatea's Veil (USA)
- Nana (Japan)
- Radiata Stories (UNDUB) + pnach cheat file in `~/.config/PCSX2/cheats/`
- Silent Hill 2 (USA)

### Extraction notes

- PS1 multi-track games extract as separate `.bin` files per track + one `.cue`
- 7z solid archives: do **not** use `-i!*.iso` filter on them — it causes truncated output; extract all files then delete unwanted ones
- Monkey Magic was in `.rar` as a nested EBOOT.PBP; extracted and renamed to `.pbp` directly in `psx/`
- Granstream Saga existed as both `.rar` (EBOOT.PBP) and `.7z` (bin/cue) — used the `.7z`

## Proton / Wine

ProtonUp-Qt manages Proton-GE and other compatibility layers:
```bash
flatpak run net.davidotek.pupgui2
```

Installed Proton versions:
- `~/.local/share/Steam/steamapps/common/` — Proton 10.0, Proton 9.0 (Beta), Proton Experimental, Proton Hotfix
- `~/.local/share/Steam/compatibilitytools.d/` — GE-Proton10-28, GE-Proton10-34, ULWGL-Proton-8.0-5-3

Protontricks for per-game Winetricks verbs:
```bash
DISPLAY=:0 flatpak run com.github.Matoking.protontricks <STEAM_APP_ID> <verb>
```

Wine prefixes per game live at:
```
~/.local/share/Steam/steamapps/compatdata/<APP_ID>/pfx/
```

### Installing a Windows patch or mod (.exe installer)

**Always use Protontricks** — do not run .exe installers directly via `proton run`. Protontricks sets up the correct Wine environment (registry, DLL overrides) for the specific game.

1. **Check ProtonDB first** for game-specific Proton version, launch options, known issues
2. **Launch the game through Steam at least once** so the Wine prefix is initialized
3. **Grant Protontricks SD card access** (if game is on SD card — one-time):
   ```bash
   flatpak override --user --filesystem=/run/media/deck/SN01T com.github.Matoking.protontricks
   ```
4. **Run the installer using Proton 10.0's wine directly** (avoids stack overflow issues with GE-Proton):
   ```bash
   # If game dir has spaces, symlink it first
   ln -sf "/path/to/Game Dir With Spaces" ~/gamedir

   DISPLAY=:0 \
   WINEPREFIX=~/.local/share/Steam/steamapps/compatdata/<APP_ID>/pfx \
   ~/.local/share/Steam/steamapps/common/Proton\ 10.0/files/bin/wine \
   "/path/to/patch.exe" /SILENT /DIR=Z:\\home\\deck\\gamedir

   rm ~/gamedir  # clean up symlink after
   ```
   - Use `/SILENT` (shows progress) or `/VERYSILENT` (headless)
   - Use the symlink trick to avoid spaces in the game path breaking `/DIR=`
   - **Do NOT use GE-Proton's wine** — NTSync changes memory layout and causes a 32-bit stack overflow with InnoSetup installers
   - **Do NOT use `proton run`** — it skips Steam initialization and the installer runs but does nothing
5. **After install**, fix permissions set read-only by InnoSetup:
   ```bash
   chmod -R u+w "/path/to/game/"
   ```
7. **Check if a subdirectory was created in the game folder:**
   - If yes (e.g. `Unofficial_Patch/`) → add `-game Unofficial_Patch` to Steam launch options
   - If no → files installed directly; no launch option needed
8. **Test the game** — if it crashes or the mod isn't active, redo via Protontricks interactively

### VTMB (Vampire: The Masquerade – Bloodlines) — App ID 2600

- Installed on SD card: `/run/media/deck/SN01T/steamapps/common/Vampire The Masquerade - Bloodlines/`
- Unofficial patch v1.15.73 installed and confirmed working:
  - `Vampire/dlls/vampire.dll` — patched (Feb 2009, fixes 15MB memory error)
  - `Bin/engine.dll` — patched (Dec 2004)
  - `Vampire/pack100–103.vpk` — patch content VPKs
  - `Vampire/sound/` — patch audio files
- Wine prefix: `~/.local/share/Steam/steamapps/compatdata/2600/pfx/`
- No `-game` launch option required (patch installed directly into game dir, no subdirectory)
- 15MB memory error: fixed by the patched `vampire.dll` — if it reappears, Steam verified and overwrote the file; re-run the patch installer

## Flatpak Notes

- System-wide flatpaks live in `/var/lib/flatpak/`
- User flatpaks live in `~/.local/share/flatpak/`
- To run a GUI flatpak from the terminal in Desktop Mode, no extra setup needed
- To run from a script, ensure `DISPLAY` and `WAYLAND_DISPLAY` env vars are set

## SteamOS Constraints

- `pacman` / `yay` will work after `sudo steamos-readonly disable`, but changes are wiped on OS update — avoid unless necessary
- Prefer flatpak or `pip3 --user` for persistent installs
- `/usr/bin/python3` is the system Python; use `pip3 install --user` or a venv under `~/.local/` or `~/projects/`

## Other Apps

- **bob** — `~/Applications/bob` (Linux native game binary, `chmod +x` already set)
- **Vampire: The Masquerade – Bloodlines** — see Proton/Wine section above for patch details

## Claude Code Settings

- `~/.claude/settings.json` — dark theme, dangerous mode prompts skipped
