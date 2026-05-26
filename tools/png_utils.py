#!/usr/bin/env python3
import binascii
import struct
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


class PngError(Exception):
    pass


def normalize_path(path):
    return Path(path.replace("\\", "/"))


def read_png(path):
    data = Path(path).read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise PngError(f"{path}: not a PNG file")

    pos = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = interlace = None
    palette = []
    transparency = []
    idat = bytearray()

    while pos < len(data):
        if pos + 8 > len(data):
            raise PngError(f"{path}: truncated chunk header")
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        pos += 8
        chunk = data[pos:pos + length]
        pos += length + 4

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, interlace = struct.unpack(">IIBBBBB", chunk)
        elif chunk_type == b"PLTE":
            palette = [
                (chunk[i], chunk[i + 1], chunk[i + 2], 255)
                for i in range(0, len(chunk), 3)
            ]
        elif chunk_type == b"tRNS":
            transparency = list(chunk)
        elif chunk_type == b"IDAT":
            idat.extend(chunk)
        elif chunk_type == b"IEND":
            break

    if width is None:
        raise PngError(f"{path}: missing IHDR")
    if bit_depth != 8 or interlace != 0:
        raise PngError(f"{path}: only 8-bit non-interlaced PNG files are supported")

    if color_type == 3:
        channels = 1
        for index, alpha in enumerate(transparency):
            if index < len(palette):
                r, g, b, _ = palette[index]
                palette[index] = (r, g, b, alpha)
    elif color_type == 2:
        channels = 3
    elif color_type == 6:
        channels = 4
    else:
        raise PngError(f"{path}: unsupported PNG color type {color_type}")

    rows = _unfilter(zlib.decompress(bytes(idat)), width, height, channels)
    pixels = []
    for row in rows:
        out_row = []
        if color_type == 3:
            for index in row:
                if index >= len(palette):
                    raise PngError(f"{path}: palette index {index} is out of range")
                out_row.append(palette[index])
        elif color_type == 2:
            for x in range(0, len(row), 3):
                out_row.append((row[x], row[x + 1], row[x + 2], 255))
        else:
            for x in range(0, len(row), 4):
                out_row.append((row[x], row[x + 1], row[x + 2], row[x + 3]))
        pixels.append(out_row)

    return {
        "width": width,
        "height": height,
        "palette": palette if color_type == 3 else [],
        "pixels": pixels,
    }


def write_rgba_png(path, width, height, pixels):
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b, a in row:
            raw.extend((r, g, b, a))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    payload = (
        PNG_SIGNATURE
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(bytes(raw)))
        + _chunk(b"IEND", b"")
    )

    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(payload)


def _chunk(chunk_type, data):
    crc = binascii.crc32(chunk_type)
    crc = binascii.crc32(data, crc) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def _unfilter(data, width, height, channels):
    stride = width * channels
    rows = []
    pos = 0
    previous = bytearray(stride)

    for _y in range(height):
        filter_type = data[pos]
        pos += 1
        current = bytearray(data[pos:pos + stride])
        pos += stride

        if filter_type == 1:
            for i in range(stride):
                current[i] = (current[i] + (current[i - channels] if i >= channels else 0)) & 0xFF
        elif filter_type == 2:
            for i in range(stride):
                current[i] = (current[i] + previous[i]) & 0xFF
        elif filter_type == 3:
            for i in range(stride):
                left = current[i - channels] if i >= channels else 0
                up = previous[i]
                current[i] = (current[i] + ((left + up) // 2)) & 0xFF
        elif filter_type == 4:
            for i in range(stride):
                left = current[i - channels] if i >= channels else 0
                up = previous[i]
                up_left = previous[i - channels] if i >= channels else 0
                current[i] = (current[i] + _paeth(left, up, up_left)) & 0xFF
        elif filter_type != 0:
            raise PngError(f"unsupported PNG filter {filter_type}")

        rows.append(bytes(current))
        previous = current

    return rows


def _paeth(a, b, c):
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c
