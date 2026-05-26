#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

from png_utils import normalize_path, read_png


PAGE_SIZE = 16 * 1024


def output_name(path, counter):
    if counter == 0:
        return path

    suffix = path.suffix
    infix = suffix[1] if len(suffix) > 1 else "b"
    return path.with_name(f"{path.stem}.{infix}{counter - 1:02d}")


def add_color(palette, color):
    if color not in palette:
        if len(palette) >= 255:
            raise ValueError("The size of the palette table is exceeded")
        palette.append(color)
    return palette.index(color)


def merge_palette(global_palette, local_palette):
    for color in local_palette:
        if color[3] == 255 and color not in global_palette:
            global_palette.append(color)

    if len(global_palette) > 256:
        raise ValueError("The size of the palette table is exceeded")


def process_png(source, output, palette):
    image = read_png(source)
    merge_palette(palette, image["palette"])

    counter = 0
    length = 0
    writer = None

    try:
        writer = output_name(output, counter).open("wb")
        counter += 1

        for row in image["pixels"]:
            if length + image["width"] > PAGE_SIZE:
                writer.close()
                length = 0
                writer = output_name(output, counter).open("wb")
                counter += 1

            for color in row:
                index = add_color(palette, color) if color[3] == 255 else 255
                writer.write(bytes((index,)))
                length += 1
    finally:
        if writer is not None and not writer.closed:
            writer.close()


def write_palette(path, palette):
    lines = [f"        ;Palette of {len(palette)} colors", f"        db  {len(palette)}"]
    for r, g, b, _a in palette:
        lines.append(f"        db  0x{b:02X}, 0x{g:02X}, 0x{r:02X}, 0x00")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def process_spec(spec_file):
    spec_path = normalize_path(spec_file)
    palette = []

    with spec_path.open("r", encoding="utf-8") as reader:
        for line_number, line in enumerate(reader, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            source = normalize_path(line)
            if not source.exists():
                raise FileNotFoundError(f"{spec_file}:{line_number}: {source} not found")

            output = Path(source.stem + ".bin")
            process_png(source, output, palette)

    write_palette(Path(spec_path.stem + "_pal.asm"), palette)


def main():
    parser = argparse.ArgumentParser(description="Convert PNG resources to indexed Sprinter binaries.")
    parser.add_argument("spec", help="path to res.txt")
    args = parser.parse_args()

    try:
        process_spec(args.spec)
    except Exception as exc:
        print(exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
