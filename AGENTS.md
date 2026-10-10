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

`FBIRD.EXE` uses the DSS loader mode: the header field at offset 8 holds the size of the resident part (`resident_end-#8100`, a multiple of 512), so DSS loads only that part and starts it with the EXE file still open (handle at `(IX-3)`). Behind the resident part sjasmplus (`OUTPUT`) writes one record per resource, `dw length` + data, in the order of the `LoadResourceList` calls in `main`; `LoadResourceList` reads them sequentially into the `GetMem` pages and `CloseExeFile` closes the file. To add or reorder a resource, change the `RESOURCE` list at the end of `src/fbird.asm` and the calls in `main` together. The Sprinter logo comes first: it is read into the title pages (`memTitle0..3`), drawn, and the title is then read into the same pages while the logo is on screen, so the logo costs no extra memory. The source files must exist in `src/assets/` at assembly time (`make resources`).

## Interrupts, Keyboard & Sound

IM2 has three vectors: `#06` (CTC ch3, the ~50 Hz frame tick, synchronized to VSync in
`set_im2`) runs `Im2Handler` (music + `vsyncFlag`), `#FF` (shared by the FPGA's VSync,
keyboard and CBL signals) runs `SfxCblIrqHandler`, and every other vector falls through
to `Im2OtherHandler`. All three serve the CBL (see below) and, like `set_im2`'s own sync
loop and `WaitVsync`, call `KeysHandler`, so a PS/2 byte is never left in the SIO FIFO
(`#18`/`#19`) across a frame. None of them write `Y_PORT`, `WIN1` or VRAM, nor
execute accelerator opcodes. `set_im2` puts `SfxCblIrqHandler` on `#FF` only after its
VSync sync loop (as the SDK does): during the sync a pending SIO byte is what tells a
keyboard wake-up from VSync, so nothing may drain it from inside the interrupt.

Keyboard input is read from the PS/2 scan-code stream (`KeysHandler` in `sys_utils.asm`),
not the ZX matrix (`#FE`, deprecated in Sprinter mode): `KeyState` tracks Space/Esc as a
live level (set/cleared on make/break), `KeyLatch` latches a press for at least one frame
even if it is released before the next sample, and `WaitVsync` folds both into `KeyFrame`
once per frame. `CheckControlKey`/`CacheCheckSpace` read `KeyFrame`, not `#FE`. As in the
SDK's `KeyHandler`, an `#E0`-prefixed key is its own code (`#80|code`) and other bytes
with bit 7 set (`#AA`, `#FA`, `#E1`...) are keyboard status, not keys.

Accelerator sequences (`ld d,d`/`ld a,N`/`ld l,l`/`ld c,c`/`ld b,b`) must not sit under a
`di` any longer than the one hardware transaction they bracket: `di` goes immediately
before the sequence and `ei` immediately after, repeated every loop iteration rather than
once around the whole loop — a CTC tick (and the keyboard byte behind it) can otherwise be
delayed past a frame or dropped outright. `SetPaletteBoth` (200..256 entries, ~4 ms) follows
the same rule per palette entry once `Im2Active` is set; before `set_im2` it keeps the
whole table under one `di`, since the DSS IM1 handler (mouse `M_INT`) saves `Y_PORT` by
reading `#89` back and rewrites it on every interrupt.

`WaitFrame` (the frame-wait inside `FadePallete`/`UnfadePallete`: `WaitVsync` once
`set_im2` has run, a bare `halt` before it) stands in for the `halt` those fades used, and
their callers keep HL and D/E live across it, so `WaitVsync` changes only AF: anything
added to it that uses other registers (`KeysHandler` trashes B/D/E) must save them.

CBL/SFX (hit/die/point samples): `SfxHandleCblInterrupt` runs from all three IM2 handlers
(in `Im2Handler` after `Player`), not only from `#FF`: one IM2 ack clears every pending FPGA
request, so a CTC ack can swallow the CBL one, and in MAME the CTC's RETI also drops the
shared INT line under a request raised while `Player` ran; `#FE` bit 7 stays set until the
block is written, so the poll still finds it. It gates every feed on `#FE` bit 7
(`CBL_IND`, valid while the CBL is running) before writing a block, since vector `#FF` is
shared with VSync and every PS/2 byte; feeding on those too drains a sample in a fraction
of its real duration. It checks once more after feeding (`SfxCblEnabled` and bit 7
again), to catch up by one extra block if a half-empty event was missed while the vector
was busy with something else (modplay's `CBL_ISR`, `sources/modplay/src/lib/cbl.asm`,
re-reads bit 7 the same way, but only counts the overrun). `SfxWriteCblBlock`'s feed loop
groups OUTIs 8 at a time with the same source, pacing only between groups.

## Coding Style & Naming Conventions

Follow the existing assembly layout: labels at the left, opcodes and operands aligned in columns, and local labels prefixed with a dot, for example `.loadLoop` or `.error`. Keep include paths consistent with the current backslash style in assembly files. Use descriptive PascalCase for routines and data labels already following that pattern, such as `LoadResourceList`, `ReadExe`, and `FileReadErrorMessage`. Keep generated binaries out of hand edits; update their source images or resource lists instead.

## Testing Guidelines

Run `make test-emulator` after gameplay or rendering changes; it must end with `RESULT: PASS`. The test types `B:\FBIRD\FBIRD.EXE` in the DSS File Manager, checks the boot by the palette in VRAM (the Sprinter logo fades in, stays at least 3 s at full brightness, fades out, then the title fades in; `logo.png` and `title.png` screenshots) and plays to score 110 with an autopilot (override with `FB_SCORE`). It compares the playfield and road (rows 0..230) of every displayed frame with a reference rendered from the game state, and checks tube geometry and motion, scoring, the difficulty level by score (10 levels, capped at 200) and the gap, spawn distance and height of every new tube against its level's row in `LevelParams` (mirrored in the script), no moving tubes at level 0, the day/night theme cycling every 50 points with the palette fade of the switch, field medals appearing at 25/50/100/200, pause/continue in the Get Ready countdown and in play, death in the air (the game over frames hold the scene only while the bird falls; once it lies on the ground the title and the panel are drawn once per page and nothing is rendered any more), restart, and the return to DSS. The HUD rows, the Get Ready banner and the game over title and panel are not compared. On a picture mismatch, `build/autotest/mismatch-NNNNN.png` shows actual | expected | difference. It also checks, from the same io-write tap as the frame budget, that every ~50 Hz CTC music tick (writes to `#FFFD`) lands within 0.9..1.1 frame of the previous one — a tick dropped or doubled under too long a `di` — and that every CBL/SFX feed run (`#4E`/`#4F`, a hit/die/point sample) paced by the real half-empty IRQ takes at least 90% of its expected duration (128 bytes/16.384 ms per block) and at most 110% of its blocks plus one (a missed IRQ that was not caught up); a one-shot flush (`SfxInit`, `SfxAbortCblPlayback`) is not paced and is excluded.

The `AUTOTEST` build (`-DAUTOTEST=1`, all code under `IFDEF AUTOTEST`) has an immortal bird and stores the state each video page was drawn with (`DbgPage0`/`DbgPage1`, layout `DBG_*` in `src/cache_render.asm`); keep that record and `build_expected` in `tools/mame_fbird.lua` in step with the renderer. It is never shipped: `make` builds the normal `src/FBIRD.EXE`.

Without MAME, validate assembly changes with `cd src && make.bat` and confirm no assembler errors are reported. The test also measures the render time of every frame from the border writes around `RunRenderCache` (`out (#fe),2` / `0`) and fails if one takes longer than a frame; MAME (0.287) models the CPU, memory and accelerator wait states, but its timing is still a model, so frame budget, sound and hardware behavior need `build/FBIRD.img` in ZXMAK2 or on Sprinter-compatible hardware as well. Include screenshots or notes when visual behavior changes.

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