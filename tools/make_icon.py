"""Generates icon.svg: a 3x3 block grid with two displaced blocks and a broken centre.

Run: python -I tools/make_icon.py icon.svg
Everything stays inside the central 66% of the 512 canvas, because Android crops
launcher icons to a circle.
"""
import sys

START = 104
STEP = 106
SIZE = 92

BLOCKS = [
    # col, row, colour, rotation, dx, dy
    (0, 0, "#ff5d6c", 0, 0, 0),
    (1, 0, "#ff9f43", 0, 0, 0),
    (2, 0, "#feca57", 14, 10, -14),
    (0, 1, "#1dd1a1", 0, 0, 0),
    (2, 1, "#48dbfb", 0, 0, 0),
    (0, 2, "#5f7cff", -12, -12, 10),
    (1, 2, "#a55eea", 0, 0, 0),
    (2, 2, "#ff6bcb", 0, 0, 0),
]


def block(col, row, colour, rot, dx, dy):
    x = START + STEP * col
    y = START + STEP * row
    cx, cy = x + SIZE / 2, y + SIZE / 2
    transform = ""
    if rot or dx or dy:
        transform = f' transform="translate({dx} {dy}) rotate({rot} {cx} {cy})"'
    return (
        f'  <g{transform}>\n'
        f'    <rect x="{x}" y="{y + 5}" width="{SIZE}" height="{SIZE}" rx="20" fill="#000" opacity="0.28"/>\n'
        f'    <rect x="{x}" y="{y}" width="{SIZE}" height="{SIZE}" rx="20" fill="{colour}"/>\n'
        f'    <rect x="{x + 10}" y="{y + 8}" width="{SIZE - 20}" height="22" rx="11" fill="#fff" opacity="0.28"/>\n'
        f'  </g>\n'
    )


def main(out_path):
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">\n',
        '  <defs>\n'
        '    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">\n'
        '      <stop offset="0" stop-color="#2a2f7a"/>\n'
        '      <stop offset="1" stop-color="#7a2d9a"/>\n'
        '    </linearGradient>\n'
        '  </defs>\n',
        '  <rect width="512" height="512" rx="112" fill="url(#bg)"/>\n',
    ]
    for b in BLOCKS:
        parts.append(block(*b))
    # Broken centre block: two shards pulled apart along the diagonal.
    parts.append(
        '  <g>\n'
        '    <polygon points="206,206 292,206 206,292" fill="#ffe66d" transform="translate(-5 -5)"/>\n'
        '    <polygon points="300,214 300,300 214,300" fill="#ff9f1c" transform="translate(5 5)"/>\n'
        '  </g>\n'
    )
    parts.append('</svg>\n')
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("".join(parts))


if __name__ == "__main__":
    main(sys.argv[1])
