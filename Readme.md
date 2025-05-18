# FlappyBird for Sprinter

A prototype of FlappyBird game for Sprinter computer written in Z80 assembly language. The game uses Sprinter Accel for graphics output and AY-3-8912 sound chip (S.V.Bulba's PT3 player) for music playback.

![Game Screenshot](/screenshots/flappybird_screenshot.png)

[Watch gameplay video](/video/SprinterFlappyBird.mp4)

## About Sprinter Computer

The Sprinter is a microcomputer made by the Russian firm Peters Plus, Ltd.

It was built using what the company called a "Flex architecture", using an Altera PLD as part of the core logic. This allows the machine's hardware to be reconfigured on the fly for different ZX-Spectrum models compatibility or its own enhanced native mode (set by default on boot and running the Estex operating system).

### Specifications

The computer is built on a standard computer tower configuration, using standard floppy discs, CD-ROM and hard disk drives.

- CPU: Z84C15 at 21 MHz or 3.5 MHz, Altera PLD
- Graphic modes: 320 x 256 with 256 colors, 640 x 256 with 16 colors, text mode 80 x 32 with 16 colors, 16 million color palette, 256/512 Kb video RAM
- Sound: Beeper, AY-3-8910, 16-bit DAC
- IDE & FDD onboard controllers
- Two ISA-8 slots

[More information about Sprinter computer](https://en.wikipedia.org/wiki/Sprinter_(computer))

[Sprinter Fans Telegram Group](https://t.me/zx_sprinter)

## Features

- Classic FlappyBird gameplay
- Hardware-accelerated graphics using Sprinter Accel
- Music playback using AY-3-8912 sound chip
- PT3 music format support

## Requirements

- sjasmplus assembler
- osfmount utility (for creating disk images)
- ZXMAK2 emulator (for testing)

## Building

### Simple Build

To build just the executable:

```bash
make.bat
```

This will create `fbird.exe` in the current directory.

### Building Disk Image

To create a bootable disk image:

1. Make sure you have osfmount utility installed
2. Run:
```bash
make_image.bat
```

This will:
- Create a disk image in `build/FBIRD.img`
- Mount the image as drive X:
- Copy the executable and assets to the image
- Unmount the image
- Copy the image to ZXMAK2 emulator directory (if SPRINTER_EMULATOR environment variable is set)

## Project Structure

- `src/` - Source code files
  - `fbird.asm` - Main game code
  - `pt3play.asm` - PT3 music player
  - Other assembly source files
- `assets/` - Game resources
  - Binary files for graphics and music
- `tools/` - Build tools
  - `sjasmplus/` - Assembler
- `build/` - Build output directory

## Credits

- Game code: Dmitry Mikhalchenkov (Hard / WCG)
- PT3 Player: S.V.Bulba
- Sprinter Accel: Sprinter team
