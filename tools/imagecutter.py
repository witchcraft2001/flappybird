#!/usr/bin/env python3
import argparse
import sys

from png_utils import normalize_path, read_png, write_rgba_png


def process_spec(spec_file):
    spec_path = normalize_path(spec_file)
    with spec_path.open("r", encoding="utf-8") as reader:
        for line_number, line in enumerate(reader, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            if len(parts) != 6:
                raise ValueError(f"{spec_file}:{line_number}: expected 6 fields")

            source, output, x, y, width, height = parts
            crop_image(
                normalize_path(source),
                normalize_path(output),
                int(x),
                int(y),
                int(width),
                int(height),
                spec_file,
                line_number,
            )


def crop_image(source, output, x, y, width, height, spec_file, line_number):
    if width <= 0 or height <= 0:
        raise ValueError(f"{spec_file}:{line_number}: width and height must be positive")

    image = read_png(source)
    if x < 0 or y < 0 or x + width > image["width"] or y + height > image["height"]:
        raise ValueError(f"{spec_file}:{line_number}: crop rectangle is outside {source}")

    pixels = [
        image["pixels"][row][x:x + width]
        for row in range(y, y + height)
    ]
    write_rgba_png(output, width, height, pixels)


def main():
    parser = argparse.ArgumentParser(description="Cut PNG sprites according to a text spec.")
    parser.add_argument("spec", help="path to cut.txt")
    args = parser.parse_args()

    try:
        process_spec(args.spec)
    except Exception as exc:
        print(exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
