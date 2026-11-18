#!/usr/bin/env python3
"""Writes Rageborn's shape textures: white shapes on transparent, tinted in game.
Standard library only. Each shape is a signed distance in pixels (negative inside); the edge
is anti-aliased from that distance. Run from the repo root: python3 -I tools/gen_textures.py"""
import math, os, struct

OUT = os.path.join(os.path.dirname(__file__), "..", "Rageborn", "Media", "Textures")


def write(name, w, h, alpha):
    """alpha(x, y) -> 0..1 for pixel centres; x right, y down, origin at the image centre."""
    body = bytearray()
    for py in range(h):
        for px in range(w):
            a = alpha(px + 0.5 - w / 2, py + 0.5 - h / 2)
            body += bytes((255, 255, 255, max(0, min(255, int(a * 255 + 0.5)))))
    head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(head + body)


def cover(sd):
    return max(0.0, min(1.0, 0.5 - sd))


def box(x, y, hw, hh, r=0.0):
    qx, qy = abs(x) - hw + r, abs(y) - hh + r
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def capsule(x, y, ax, ay, bx, by, r):
    px, py, dx, dy = x - ax, y - ay, bx - ax, by - ay
    t = max(0.0, min(1.0, (px * dx + py * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - dx * t, py - dy * t) - r


def rot(x, y, deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return x * c + y * s, -x * s + y * c


def sword(x, y, s):
    """A sword pointing up, s = half its length in pixels."""
    blade = capsule(x, y, 0, -0.95 * s, 0, 0.25 * s, 0.07 * s)
    tip = max(abs(x) * 2.6 + (-y - 0.95 * s), -y - 1.2 * s) if y < -0.95 * s else 1e9
    guard = capsule(x, y, -0.3 * s, 0.3 * s, 0.3 * s, 0.3 * s, 0.055 * s)
    grip = capsule(x, y, 0, 0.3 * s, 0, 0.72 * s, 0.045 * s)
    pommel = math.hypot(x, y - 0.82 * s) - 0.085 * s
    return min(blade, tip, guard, grip, pommel)


def ring(x, y):
    return cover(abs(math.hypot(x, y) - 104) - 9)


def arc(x, y):
    # the left side of a big circle, thick in the middle and tapering to both ends
    cx = 150.0
    ang = math.atan2(y, x - cx)                    # pi = pointing left
    off = abs(abs(ang) - math.pi) / 1.05           # 0 in the middle, 1 at the ends
    if off >= 1:
        return 0.0
    return cover(abs(math.hypot(x - cx, y) - 180) - 15 * (1 - off * off))


def glow(x, y):
    d = math.hypot(x, y) / 64
    return max(0.0, 1 - d) ** 2


def frame(x, y):
    return cover(abs(box(x, y, 52, 52, 12)) - 5)


def bar(x, y):
    return cover(box(x, y, 124, 12, 6))


def spark(x, y):
    ax, ay = abs(x) / 62, abs(y) / 62
    star = max(0.0, 1 - (math.sqrt(ax) + math.sqrt(ay)) ** 2)
    return min(1.0, star * 1.6 + max(0.0, 1 - math.hypot(x, y) / 14) ** 2)


def edge(x, y):
    t = (x + 32) / 64                              # 0 at the left side, 1 at the right
    return (1 - t) ** 2


def mask(x, y):
    return cover(math.hypot(x, y) - 62)


def corner(x, y):
    # an L bracket in the top-left
    return cover(min(box(x + 2, y + 22, 24, 4, 3), box(x + 22, y + 2, 4, 24, 3)))


def blades(x, y):
    return cover(min(sword(*rot(x, y, 40), 54), sword(*rot(x, y, -40), 54)))


def shield(x, y):
    top = -50.0
    if y < top - 1:
        return 0.0
    half = 44.0 if y < 4 else 44.0 * math.sqrt(max(0.0, 1 - ((y - 4) / 54.0) ** 2))
    return min(cover(abs(x) - half), cover(top - y))


def drop(x, y):
    body = math.hypot(x, y - 14) - 34
    if -52 <= y <= 4:
        t = (y + 52) / 56.0
        body = min(body, abs(x) - 31.5 * t ** 1.25)
    return cover(body)


SHAPES = [("ring", 256, 256, ring), ("arc", 128, 256, arc), ("glow", 128, 128, glow),
          ("frame", 128, 128, frame), ("bar", 256, 32, bar), ("spark", 128, 128, spark),
          ("edge", 64, 256, edge), ("mask", 128, 128, mask), ("corner", 64, 64, corner),
          ("blades", 128, 128, blades), ("shield", 128, 128, shield), ("drop", 128, 128, drop)]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, w, h, fn in SHAPES:
        write(name, w, h, fn)
        print("wrote", name, w, h)
