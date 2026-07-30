#!/usr/bin/env python3
"""Toruto 起動ロゴ生成スクリプト（依存なし・標準ライブラリのみ）。

AppIcon と同じモチーフ（3:4 の本体 + レンズ + 日付スタンプのオレンジ）を
背景なし（透過 PNG）で描く。

LaunchScreen.storyboard と SwiftUI の LaunchOverlay が同じ画像・同じ表示サイズを
使うことで、起動画面からアプリ本体への切り替わりが視覚的に見えなくなる。

使い方:
    python3 Design/generate_launch_logo.py
出力:
    Toruto/Resources/Assets.xcassets/LaunchLogo.imageset/LaunchLogo.png    (100x128)
    Toruto/Resources/Assets.xcassets/LaunchLogo.imageset/LaunchLogo@2x.png (200x256)
    Toruto/Resources/Assets.xcassets/LaunchLogo.imageset/LaunchLogo@3x.png (300x384)
"""

import math
import struct
import zlib
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / (
    "Toruto/Resources/Assets.xcassets/LaunchLogo.imageset"
)

# 表示サイズ（pt）と書き出すスケール
POINT_W, POINT_H = 100, 128
SCALES = (1, 2, 3)

# 設計座標系の高さ。generate_app_icon.py と同じ形状パラメータをそのまま使うため、
# 本体（高さ 820）に上下の余白を足した 900 を「ロゴ高さ = POINT_H」に対応させる
DESIGN_H = 900.0

# 配色（generate_app_icon.py と共通）
BODY_TOP = (23, 23, 28)
BODY_BOTTOM = (13, 13, 16)
FRAME_COLOR = (208, 208, 218)
RING_COLOR = (240, 240, 244)
GLASS_CENTER = (62, 116, 135)
GLASS_EDGE = (11, 20, 27)
ORANGE = (255, 138, 61)

# 形状パラメータ（generate_app_icon.py と共通）
FRAME_HALF_W, FRAME_HALF_H = 308, 410
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


def blend(dst, color, alpha):
    """透過を保ったまま source-over 合成する。dst / 戻り値は (rgb, alpha)"""
    src_a = clamp01(alpha)
    if src_a <= 0:
        return dst
    dst_rgb, dst_a = dst
    out_a = src_a + dst_a * (1 - src_a)
    if out_a <= 0:
        return ((0.0, 0.0, 0.0), 0.0)
    keep = dst_a * (1 - src_a)
    rgb = tuple((color[i] * src_a + dst_rgb[i] * keep) / out_a for i in range(3))
    return (rgb, out_a)


def pixel(px, py):
    """設計座標 (px, py) の色を (rgb, alpha) で返す。原点は中央"""
    dst = ((0.0, 0.0, 0.0), 0.0)

    # 本体（3:4 の角丸）: 縦グラデーションで塗り、その上に細枠
    d_frame = sd_round_rect(px, py, FRAME_HALF_W, FRAME_HALF_H, FRAME_RADIUS)
    body_cov = coverage(d_frame)
    if body_cov > 0:
        t = clamp01((py + FRAME_HALF_H) / (2 * FRAME_HALF_H))
        dst = blend(dst, mix(BODY_TOP, BODY_BOTTOM, t), body_cov)
        dst = blend(dst, (255, 255, 255), 0.035 * body_cov)
    dst = blend(dst, FRAME_COLOR, 0.5 * coverage(abs(d_frame) - FRAME_STROKE / 2))

    # レンズガラス（半径方向グラデーション）
    r = math.hypot(px, py)
    glass_cov = coverage(r - GLASS_R)
    if glass_cov > 0:
        t = clamp01(r / GLASS_R)
        dst = blend(dst, mix(GLASS_CENTER, GLASS_EDGE, t * t), glass_cov)

        # 絞りリング（さりげなく）
        dst = blend(dst, (255, 255, 255), 0.10 * coverage(abs(r - APERTURE_R) - APERTURE_W / 2) * glass_cov)

        # ハイライトとグリント
        hd = math.hypot(px + 78, py + 88)
        dst = blend(dst, (255, 255, 255), 0.28 * clamp01(1 - hd / 96) * glass_cov)
        gd = math.hypot(px - 66, py - 80)
        dst = blend(dst, (255, 255, 255), 0.10 * clamp01(1 - gd / 40) * glass_cov)

    # レンズ外周リング
    dst = blend(dst, RING_COLOR, coverage(abs(r - RING_R) - RING_W / 2))

    # 日付スタンプ風のオレンジバー（本体右下の内側）
    bar_cx = FRAME_HALF_W - STAMP_MARGIN - STAMP_W / 2
    bar_cy = FRAME_HALF_H - STAMP_MARGIN - STAMP_H / 2
    d_bar = sd_round_rect(px - bar_cx, py - bar_cy, STAMP_W / 2, STAMP_H / 2, STAMP_R)
    dst = blend(dst, ORANGE, 0.92 * coverage(d_bar))

    return dst


def write_png(path, width, height, rows):
    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # RGBA 8bit
    raw = b"".join(b"\x00" + row for row in rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def render(scale):
    width, height = POINT_W * scale, POINT_H * scale
    k = height / DESIGN_H  # 設計座標 → px の倍率
    rows = []
    for y in range(height):
        row = bytearray()
        py = (y + 0.5 - height / 2) / k
        for x in range(width):
            px = (x + 0.5 - width / 2) / k
            (r, g, b), a = pixel(px, py)
            row += bytes((int(r + 0.5), int(g + 0.5), int(b + 0.5), int(a * 255 + 0.5)))
        rows.append(bytes(row))
    return width, height, rows


def main():
    for scale in SCALES:
        suffix = "" if scale == 1 else f"@{scale}x"
        path = OUT_DIR / f"LaunchLogo{suffix}.png"
        width, height, rows = render(scale)
        write_png(path, width, height, rows)
        print(f"generated: {path} ({width}x{height})")


if __name__ == "__main__":
    main()
