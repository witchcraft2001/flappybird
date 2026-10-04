# Repository Guidelines

## Project Structure & Module Organization

This repository contains a Sprinter/Z80 FlappyBird prototype. Main game code lives in `src/`, with `src/fbird.asm` as the entry point and helpers such as `grx_utils.asm`, `sys_utils.asm`, and `pt3play.asm`. Shared constants are under `src/include/`. Runtime binary assets are in `src/assets/`; editable artwork and generated resources are under `assets/`. Screenshots, images, and video captures live in `screenshots/`, `images/`, and `video/`. Utility scripts are in `tools/`.

## Build, Test, and Development Commands

Run build scripts from their owning directories:

- `make` builds the monoblock `src/FBIRD.EXE` (all resources from `src/assets/` are included into the EXE), creates `build/FBIRD.img`, and copies the EXE into the image with `mtools`.
- `make resources` regenerates cut PNGs and binary assets using the Python tools in `tools/`.
- `make test-emulator` builds the `AUTOTEST` variant into `build/autotest/`, plays it in MAME `sprinter` and checks every frame (`tools/run_mame.sh`, `tools/mame_fbird.lua`). Report, screenshots and mismatch pictures land in `build/autotest/`.
- `make run` opens the normal image in a MAME window. `MAME_DIR`, `MAME`, `DSS_IMAGE` are Makefile variables.
- `cd src && make.bat` assembles `fbird.asm` with bundled `tools\sjasmplus\sjasmplus.exe` and writes `fbird.exe` plus `fbird.lst`.
- `cd src && make_image.bat` builds `FBIRD.EXE`, creates `build/FBIRD.img`, mounts it with OSFMount, and copies the EXE (no separate asset files).
- `cd assets && prepare_res.bat` regenerates binary resources with the legacy tool.

## Monoblock EXE

`FBIRD.EXE` uses the DSS loader mode: the header field at offset 8 holds the size of the resident part (`resident_end-#8100`, a multiple of 512), so DSS loads only that part and starts it with the EXE file still open (handle at `(IX-3)`). Behind the resident part sjasmplus (`OUTPUT`) writes one record per resource, `dw length` + data, in the order of the `LoadResourceList` calls in `main`; `LoadResourceList` reads them sequentially into the `GetMem` pages and `CloseExeFile` closes the file. To add or reorder a resource, change the `RESOURCE` list at the end of `src/fbird.asm` and the calls in `main` together. The source files must exist in `src/assets/` at assembly time (`make resources`).

## Coding Style & Naming Conventions

Follow the existing assembly layout: labels at the left, opcodes and operands aligned in columns, and local labels prefixed with a dot, for example `.loadLoop` or `.error`. Keep include paths consistent with the current backslash style in assembly files. Use descriptive PascalCase for routines and data labels already following that pattern, such as `LoadResourceList`, `ReadExe`, and `FileReadErrorMessage`. Keep generated binaries out of hand edits; update their source images or resource lists instead.

## Testing Guidelines

Run `make test-emulator` after gameplay or rendering changes; it must end with `RESULT: PASS`. The test types `B:\FBIRD\FBIRD.EXE` in the DSS File Manager and plays to score 90 with an autopilot. It compares the playfield and road (rows 0..230) of every displayed frame with a reference rendered from the game state, and checks tube geometry and motion, scoring, the day/night theme by score, the palette fade of the switch, pause/continue, death and restart, and the return to DSS. The HUD rows and the game over panel are not compared, and sound is not checked. On a picture mismatch, `build/autotest/mismatch-NNNNN.png` shows actual | expected | difference.

The `AUTOTEST` build (`-DAUTOTEST=1`, all code under `IFDEF AUTOTEST`) has an immortal bird and stores the state each video page was drawn with (`DbgPage0`/`DbgPage1`, layout `DBG_*` in `src/cache_render.asm`); keep that record and `build_expected` in `tools/mame_fbird.lua` in step with the renderer. It is never shipped: `make` builds the normal `src/FBIRD.EXE`.

Without MAME, validate assembly changes with `cd src && make.bat` and confirm no assembler errors are reported. MAME does not time the accelerator, so frame-budget, sound and hardware behavior still need `build/FBIRD.img` in ZXMAK2 or on Sprinter-compatible hardware. Include screenshots or notes when visual behavior changes.

## Commit & Pull Request Guidelines

Recent commits use short, direct messages such as `fixed filename` and `added repo info`; keep messages concise and action-oriented. Pull requests should describe the gameplay, build, or asset change, list the commands run, and mention emulator or hardware used for verification. Attach screenshots or short captures for visible changes, and link related issues when applicable.

## Agent-Specific Instructions

Do not overwrite unrelated generated files or local build outputs unless the task requires regeneration. Preserve existing `.bat` workflows and bundled tools unless replacing them is explicitly requested.

## External reference sources
- You may consult the following local sibling repositories/directories for answers, platform details, and implementation ideas:
  - `/Users/dmitry/dev/zx/sprinter/sprinter_bios`
  - `/Users/dmitry/dev/zx/sprinter/sprinter_dss`
  - `/Users/dmitry/dev/zx/sprinter/sprinter_ai_doc/manual`
  - `/Users/dmitry/dev/zx/sprinter/sources/tasm_071/TASM`
  - `/Users/dmitry/dev/zx/sprinter/sources/fformat/src/fformat_v113`
  - `/Users/dmitry/dev/zx/sprinter/sources/fm/FM-SRC/FM`
  - `/Users/dmitry/dev/zx/sprinter/gfxview`
  - `/Users/dmitry/dev/zx/sprinter/gifview`
  - `/Users/dmitry/dev/zx/sprinter/flexnavigator`
  - `/Users/dmitry/dev/zx/sprinter/sources/nupogodi`
  - `/Users/dmitry/dev/zx/sprinter/sources/2DSTUDIO`
  - `/Users/dmitry/dev/zx/sprinter/sources/DOOM2`
  - `/Users/dmitry/dev/zx/sprinter/sdcc-sprinter-sdk`
  - `/Users/dmitry/dev/zx/sprinter/zx-sprinter-sdk`
  - `/Users/dmitry/dev/zx/sprinter/sources/DOOM2`
  - `/Users/dmitry/dev/zx/sprinter/games/titd/src`
  - `/Users/dmitry/dev/zx/sprinter/sources/sprinter-unzip`
  - `/Users/dmitry/dev/zx/sprinter/sega-joy`