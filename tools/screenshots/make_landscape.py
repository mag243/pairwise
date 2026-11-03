"""Draws the landscape that Preview shows in the page's pictures (ADR 0065): a sky, a sun,
two hills and the sea, the same every time. Writes a PNG with the standard library alone.

Usage: python3 -I make_landscape.py <out.png>
"""

import math
import struct
import sys
import zlib

WIDTH, HEIGHT = 1240, 960
SKY_TOP, SKY_BOTTOM = (92, 148, 214), (255, 206, 160)
SUN = (255, 240, 190)
SUN_X, SUN_Y, SUN_RADIUS = 870, 330, 70
FAR_HILL, NEAR_HILL = (92, 128, 132), (58, 104, 84)
SEA_TOP, SEA_BOTTOM = (70, 128, 168), (32, 78, 120)
SEA_LINE = 640


def mix(first, second, part):
    return tuple(int(first[i] + (second[i] - first[i]) * part) for i in range(3))


def far_hill(x):
    return 560 - 150 * math.sin(x / 390 + 0.4) ** 2


def near_hill(x):
    return 900 - 330 * max(0.0, math.cos(x / 420 + 0.2)) ** 2


def colour(x, y):
    if y > near_hill(x):
        return NEAR_HILL
    if y > SEA_LINE:
        return mix(SEA_TOP, SEA_BOTTOM, (y - SEA_LINE) / (HEIGHT - SEA_LINE))
    if y > far_hill(x):
        return FAR_HILL
    if (x - SUN_X) ** 2 + (y - SUN_Y) ** 2 < SUN_RADIUS**2:
        return SUN
    return mix(SKY_TOP, SKY_BOTTOM, y / SEA_LINE)


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))


def main(path):
    rows = bytearray()
    for y in range(HEIGHT):
        rows.append(0)
        for x in range(WIDTH):
            rows.extend(colour(x, y))
    header = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 2, 0, 0, 0)
    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n")
        out.write(chunk(b"IHDR", header))
        out.write(chunk(b"IDAT", zlib.compress(bytes(rows))))
        out.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    main(sys.argv[1])
