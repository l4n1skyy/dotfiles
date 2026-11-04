#!/usr/bin/env python3
"""Limine boot menu wallpaper: Catppuccin Mocha base and the "WELCOME L4N1SKYY" banner
(welcome-l4n1skyy.txt, ANSI Shadow block letters) in a mauve -> lavender gradient, like
the Plymouth logo, above the menu.

The banner is drawn cell by cell instead of through a font, so the blocks and the
double-line shadows stay pixel-sharp and join up between rows: a cell is CW x CH px
(1:2, like a terminal cell), full blocks fill it, the box-drawing shadows are two
T-px lines G px apart around the cell's centre.

Layout math (Limine 12.9 at 1920x1200, 8x16 font + 1px spacing = 213x75 cells):
branding row 1, help rows 3+5, the menu tree centered vertically (5 entries -> rows
35-39, y 560-640), selected entry's comment row 72, countdown row 73. The banner is
centered in the free band between y 224 (the editor (E) draws the entry's lines from
row 6, and the longest one, snapshot-latest, ends there) and the tree.

Usage: wallpaper.py [out.png] [--cell W] [--top Y]
"""
import argparse
import os
from PIL import Image, ImageDraw

ART = os.path.join(os.path.dirname(os.path.abspath(__file__)), "welcome-l4n1skyy.txt")
W, H = 1920, 1200
BAND = (224, 560)  # free rows between the editor's last line and the menu tree

BASE = (0x1E, 0x1E, 0x2E)
MAUVE = (0xCB, 0xA6, 0xF7)
LAVENDER = (0xB4, 0xBE, 0xFE)


def cell_rects(ch, cw, chh):
    """Filled rectangles (x0, y0, x1, y1, end-exclusive) that draw one character."""
    t = max(1, cw // 6)  # line thickness
    g = t  # gap between the two lines of a double line
    xl, xr = cw // 2 - g // 2 - t, cw // 2 + (g + 1) // 2  # left edges of the 2 verticals
    yt, yb = chh // 2 - g // 2 - t, chh // 2 + (g + 1) // 2  # top edges of the 2 horizontals
    if ch == "█":
        return [(0, 0, cw, chh)]
    if ch == "═":
        return [(0, yt, cw, yt + t), (0, yb, cw, yb + t)]
    if ch == "║":
        return [(xl, 0, xl + t, chh), (xr, 0, xr + t, chh)]
    if ch == "╗":  # down and left
        return [(0, yt, xr + t, yt + t), (xr, yt, xr + t, chh),
                (0, yb, xl + t, yb + t), (xl, yb, xl + t, chh)]
    if ch == "╔":  # down and right
        return [(xl, yt, cw, yt + t), (xl, yt, xl + t, chh),
                (xr, yb, cw, yb + t), (xr, yb, xr + t, chh)]
    if ch == "╝":  # up and left
        return [(0, yb, xr + t, yb + t), (xr, 0, xr + t, yb + t),
                (0, yt, xl + t, yt + t), (xl, 0, xl + t, yt + t)]
    if ch == "╚":  # up and right
        return [(xl, yb, cw, yb + t), (xl, 0, xl + t, yb + t),
                (xr, yt, cw, yt + t), (xr, 0, xr + t, yt + t)]
    if ch == " ":
        return []
    raise ValueError(f"no drawing for {ch!r}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", nargs="?", default="l4n1skyy.png")
    ap.add_argument("--cell", type=int, default=12, help="cell width in px (height = 2x)")
    ap.add_argument("--top", type=int, help="banner top edge in px (default: centered in the band)")
    args = ap.parse_args()

    with open(ART, encoding="utf-8") as f:
        lines = [l.rstrip() for l in f.read().splitlines()]
    while lines and not lines[-1]:
        lines.pop()
    cols = max(len(l) for l in lines)

    cw, chh = args.cell, 2 * args.cell
    bw, bh = cols * cw, len(lines) * chh
    left = (W - bw) // 2
    top = args.top if args.top is not None else (BAND[0] + BAND[1] - bh) // 2

    # The banner as a 1-bit mask, then painted through a horizontal gradient
    mask = Image.new("1", (bw, bh), 0)
    draw = ImageDraw.Draw(mask)
    for r, line in enumerate(lines):
        for c, ch in enumerate(line):
            for x0, y0, x1, y1 in cell_rects(ch, cw, chh):
                draw.rectangle((c * cw + x0, r * chh + y0, c * cw + x1 - 1, r * chh + y1 - 1), fill=1)

    grad = Image.new("RGB", (bw, bh))
    gpx = grad.load()
    for x in range(bw):
        t = x / (bw - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(MAUVE, LAVENDER))
        for y in range(bh):
            gpx[x, y] = c

    img = Image.new("RGB", (W, H), BASE)
    img.paste(grad, (left, top), mask)
    img.save(args.out, optimize=True)
    print(f"{args.out}: banner {bw}x{bh} at ({left},{top})")


if __name__ == "__main__":
    main()
