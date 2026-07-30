#!/usr/bin/env python3
"""Toruto アプリアイコン生成スクリプト（依存なし・標準ライブラリのみ）。

モチーフ:
- ダークベース（ブランド: Simple / Stylish / Pocket Camera）
- 中央フレーム 3:4 の細枠（「保存される領域」の製品コンセプト）
- レンズ（ティール系のガラス + ハイライト）
- 日付スタンプ由来のオレンジのバー

使い方:
    python3 Design/generate_app_icon.py
出力:
    Toruto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024x1024, RGB 不透過)
"""

import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / (
    "Toruto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
)

CX = CY = SIZE / 2

# 配色
BG_TOP = (23, 23, 28)
BG_BOTTOM = (13, 13, 16)
FRAME_COLOR = (208, 208, 218)
RING_COLOR = (240, 240, 244)
GLASS_CENTER = (62, 116, 135)
GLASS_EDGE = (11, 20, 27)
ORANGE = (255, 138, 61)

# 形状パラメータ
FRAME_HALF_W, FRAME_HALF_H = 308, 410  # 3:4 よりわずかに縦長に見えない比率（616x820 ≒ 3:4）
FRAME_RADIUS = 72
FRAME_STROKE = 12
RING_R, RING_W = 252, 30
GLASS_R = RING_R - RING_W / 2
APERTURE_R, APERTURE_W = 140, 8
STAMP_W, STAMP_H, STAMP_R = 68, 22, 11
STAMP_MARGIN = 44


def clamp01(x):
    return 0.0 if x < 0 else (1.0 if x > 1 else x)


def coverage(signed_distance):
    """SDF 値 → 1px アンチエイリアスの被覆率"""
    return clamp01(0.5 - signed_distance)


def sd_round_rect(px, py, half_w, half_h, radius):
    qx = abs(px) - (half_w - radius)
    qy = abs(py) - (half_h - radius)
    ox = max(qx, 0.0)
    oy = max(qy, 0.0)
    return math.hypot(ox, oy) + min(max(qx, qy), 0.0) - radius


def mix(c0, c1, t):
    return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))


def over(base, color, alpha):
    return tuple(base[i] + (color[i] - base[i]) * alpha for i in range(3))


def pixel(x, y):
    # 背景の縦グラデーション
    color = mix(BG_TOP, BG_BOTTOM, y / SIZE)

    px, py = x - CX, y - CY

    # 中央フレーム: 内側をわずかに明るく + 細枠
    d_frame = sd_round_rect(px, py, FRAME_HALF_W, FRAME_HALF_H, FRAME_RADIUS)
    color = over(color, (255, 255, 255), 0.035 * coverage(d_frame))
    color = over(color, FRAME_COLOR, 0.5 * coverage(abs(d_frame) - FRAME_STROKE / 2))

    # レンズガラス（半径方向グラデーション）
    r = math.hypot(px, py)
    glass_cov = coverage(r - GLASS_R)
    if glass_cov > 0:
        t = clamp01(r / GLASS_R)
        glass = mix(GLASS_CENTER, GLASS_EDGE, t * t)
        color = over(color, glass, glass_cov)

        # 絞りリング（さりげなく）
        color = over(color, (255, 255, 255), 0.10 * coverage(abs(r - APERTURE_R) - APERTURE_W / 2) * glass_cov)

        # ハイライト（ソフトな円）とグリント
        hd = math.hypot(px + 78, py + 88)
        color = over(color, (255, 255, 255), 0.28 * clamp01(1 - hd / 96) * glass_cov)
        gd = math.hypot(px - 66, py - 80)
        color = over(color, (255, 255, 255), 0.10 * clamp01(1 - gd / 40) * glass_cov)

    # レンズ外周リング
    color = over(color, RING_COLOR, coverage(abs(r - RING_R) - RING_W / 2))

    # 日付スタンプ風のオレンジバー（フレーム右下の内側）
    bar_cx = FRAME_HALF_W - STAMP_MARGIN - STAMP_W / 2
    bar_cy = FRAME_HALF_H - STAMP_MARGIN - STAMP_H / 2
    d_bar = sd_round_rect(px - bar_cx, py - bar_cy, STAMP_W / 2, STAMP_H / 2, STAMP_R)
    color = over(color, ORANGE, 0.92 * coverage(d_bar))

    return color


def write_png(path, size, rows):
    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)  # RGB 8bit
    raw = b"".join(b"\x00" + row for row in rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def main():
    rows = []
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            r, g, b = pixel(x + 0.5, y + 0.5)
            row += bytes((int(r + 0.5), int(g + 0.5), int(b + 0.5)))
        rows.append(bytes(row))
    write_png(OUT, SIZE, rows)
    print(f"generated: {OUT}")


if __name__ == "__main__":
    main()
