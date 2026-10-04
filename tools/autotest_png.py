#!/usr/bin/env python3
"""Turn the frame dumps of tools/mame_fbird.lua into PNGs: actual | expected | difference.

Each NAME.act / NAME.exp pair holds 320-pixel rows of colour indexes; the result is NAME.png
(differing pixels are red on a dimmed copy of the actual frame). The dumps are removed.
"""
import re
import sys
from pathlib import Path

from png_utils import write_rgba_png

WIDTH = 320
GAP = 4


def read_palette(path):
    palette = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*db\s+0x(..),\s*0x(..),\s*0x(..),\s*0x..", line)
        if m:
            b, g, r = (int(v, 16) for v in m.groups())
            palette.append((r, g, b, 255))
    return palette


def convert(act_path, palette):
    act = act_path.read_bytes()
    exp = act_path.with_suffix(".exp").read_bytes()
    rows = len(act) // WIDTH

    def colour(index):
        return palette[index] if index < len(palette) else (255, 0, 255, 255)

    pixels = []
    for y in range(rows):
        a = act[y * WIDTH:(y + 1) * WIDTH]
        e = exp[y * WIDTH:(y + 1) * WIDTH]
        row = [colour(i) for i in a] + [(0, 0, 0, 255)] * GAP + [colour(i) for i in e] + [(0, 0, 0, 255)] * GAP
        for ia, ie in zip(a, e):
            if ia != ie:
                row.append((255, 0, 0, 255))
            else:
                r, g, b, _ = colour(ia)
                row.append((r // 4, g // 4, b // 4, 255))
        pixels.append(row)
    write_rgba_png(act_path.with_suffix(".png"), WIDTH * 3 + GAP * 2, rows, pixels)
    act_path.unlink()
    act_path.with_suffix(".exp").unlink()


def main():
    if len(sys.argv) != 3:
        print("usage: autotest_png.py OUT_DIR PALETTE.asm", file=sys.stderr)
        return 2
    palette = read_palette(sys.argv[2])
    for act_path in sorted(Path(sys.argv[1]).glob("*.act")):
        convert(act_path, palette)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
