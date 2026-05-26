# Repository Guidelines

## Project Structure & Module Organization

This repository contains a Sprinter/Z80 FlappyBird prototype. Main game code lives in `src/`, with `src/fbird.asm` as the entry point and helpers such as `grx_utils.asm`, `sys_utils.asm`, and `pt3play.asm`. Shared constants are under `src/include/`. Runtime binary assets are in `src/assets/`; editable artwork and generated resources are under `assets/`. Screenshots, images, and video captures live in `screenshots/`, `images/`, and `video/`. Utility scripts are in `tools/`.

## Build, Test, and Development Commands

Run build scripts from their owning directories:

- `make` builds `src/FBIRD.EXE`, creates `build/FBIRD.img`, and copies files into the image with `mtools`.
- `make resources` regenerates cut PNGs and binary assets using the Python tools in `tools/`.
- `cd src && make.bat` assembles `fbird.asm` with bundled `tools\sjasmplus\sjasmplus.exe` and writes `fbird.exe` plus `fbird.lst`.
- `cd src && make_image.bat` builds `FBIRD.EXE`, creates `build/FBIRD.img`, mounts it with OSFMount, and copies assets.
- `cd assets && prepare_res.bat` regenerates binary resources with the legacy tool.

## Coding Style & Naming Conventions

Follow the existing assembly layout: labels at the left, opcodes and operands aligned in columns, and local labels prefixed with a dot, for example `.loadLoop` or `.error`. Keep include paths consistent with the current backslash style in assembly files. Use descriptive PascalCase for routines and data labels already following that pattern, such as `LoadResource`, `AssetsDir`, and `OpenDirErrorMessage`. Keep generated binaries out of hand edits; update their source images or resource lists instead.

## Testing Guidelines

There is no automated test suite. Validate assembly changes with `cd src && make.bat` and confirm no assembler errors are reported. For gameplay, disk image, keyboard, graphics, or music changes, run `cd src && make_image.bat` and test `build/FBIRD.img` in ZXMAK2 or on Sprinter-compatible hardware. Include screenshots or notes when visual behavior changes.

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