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
        try:
            index = palette.index(None)
            palette[index] = color
        except ValueError:
            if len(palette) >= 255:
                raise ValueError("The size of the palette table is exceeded")
            palette.append(color)
    return palette.index(color)


def merge_palette(global_palette, local_palette):
    for color in local_palette:
        if color[3] == 255 and color not in global_palette:
            add_color(global_palette, color)

    if len(global_palette) > 255:
        raise ValueError("The size of the palette table is exceeded")


def merge_image_colors(global_palette, source):
    image = read_png(source)
    merge_palette(global_palette, image["palette"])

    for row in image["pixels"]:
        for color in row:
            if color[3] == 255 and color not in global_palette:
                add_color(global_palette, color)


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
    for color in palette:
        if color is None:
            color = (0, 0, 0, 255)
        r, g, b, _a = color
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

            parts = line.split()
            reserve = len(parts) == 5 and parts[0].lower() == "reserve"
            palette_only = len(parts) == 2 and parts[0].lower() == "palette"
            if reserve:
                index = int(parts[1], 0)
                if index < 0 or index >= 255:
                    raise ValueError(f"{spec_file}:{line_number}: reserve index is out of range")
                color = tuple(int(part, 0) for part in parts[2:5]) + (255,)
                while len(palette) <= index:
                    palette.append(None)
                if palette[index] is not None and palette[index] != color:
                    raise ValueError(f"{spec_file}:{line_number}: palette index {index} is already reserved")
                palette[index] = color
                continue

            if palette_only:
                source = normalize_path(parts[1])
            elif len(parts) == 1:
                source = normalize_path(parts[0])
            else:
                raise ValueError(f"{spec_file}:{line_number}: expected path or 'palette path'")

            if not source.exists():
                raise FileNotFoundError(f"{spec_file}:{line_number}: {source} not found")

            if palette_only:
                merge_image_colors(palette, source)
                continue

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
