#!/usr/bin/env python3

import json
import math
import os
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "ExpiryMate" / "Assets.xcassets"
APP_ICON_SET = ASSETS / "AppIcon.appiconset"
LAUNCH_IMAGE_SET = ASSETS / "LaunchBrandMark.imageset"
LAUNCH_BG_SET = ASSETS / "LaunchBackground.colorset"


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def blend(dst, src):
    sr, sg, sb, sa = src
    dr, dg, db, da = dst
    sa_n = sa / 255.0
    da_n = da / 255.0
    out_a = sa_n + da_n * (1.0 - sa_n)
    if out_a <= 0:
        return (0, 0, 0, 0)
    out_r = (sr * sa_n + dr * da_n * (1.0 - sa_n)) / out_a
    out_g = (sg * sa_n + dg * da_n * (1.0 - sa_n)) / out_a
    out_b = (sb * sa_n + db * da_n * (1.0 - sa_n)) / out_a
    return (clamp(out_r), clamp(out_g), clamp(out_b), clamp(out_a * 255))


class Canvas:
    def __init__(self, width, height, fill=(0, 0, 0, 0)):
        self.width = width
        self.height = height
        self.pixels = [fill] * (width * height)

    def index(self, x, y):
        return y * self.width + x

    def set(self, x, y, color):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[self.index(x, y)] = color

    def get(self, x, y):
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.pixels[self.index(x, y)]
        return (0, 0, 0, 0)

    def blend_pixel(self, x, y, color):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[self.index(x, y)] = blend(self.pixels[self.index(x, y)], color)

    def write_png(self, path):
        def chunk(tag, data):
            return (
                struct.pack(">I", len(data))
                + tag
                + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
            )

        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for x in range(self.width):
                raw.extend(self.pixels[self.index(x, y)])

        png = bytearray(b"\x89PNG\r\n\x1a\n")
        png += chunk(
            b"IHDR",
            struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0),
        )
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        png += chunk(b"IEND", b"")
        path.write_bytes(png)


def lerp_color(a, b, t):
    return tuple(clamp(a[i] + (b[i] - a[i]) * t) for i in range(4))


def point_in_rounded_rect(x, y, rect, radius):
    left, top, right, bottom = rect
    if x < left or x > right or y < top or y > bottom:
        return False
    inner_left = left + radius
    inner_right = right - radius
    inner_top = top + radius
    inner_bottom = bottom - radius
    if inner_left <= x <= inner_right or inner_top <= y <= inner_bottom:
        return True
    corners = [
        (inner_left, inner_top),
        (inner_right, inner_top),
        (inner_left, inner_bottom),
        (inner_right, inner_bottom),
    ]
    for cx, cy in corners:
        if (x - cx) ** 2 + (y - cy) ** 2 <= radius ** 2:
            return True
    return False


def draw_rounded_rect(canvas, rect, radius, color):
    left, top, right, bottom = rect
    for y in range(max(0, int(top)), min(canvas.height, int(bottom) + 1)):
        for x in range(max(0, int(left)), min(canvas.width, int(right) + 1)):
            if point_in_rounded_rect(x + 0.5, y + 0.5, rect, radius):
                canvas.blend_pixel(x, y, color)


def draw_circle(canvas, cx, cy, radius, color):
    left = max(0, int(cx - radius - 1))
    right = min(canvas.width, int(cx + radius + 1))
    top = max(0, int(cy - radius - 1))
    bottom = min(canvas.height, int(cy + radius + 1))
    radius_sq = radius * radius
    for y in range(top, bottom):
        for x in range(left, right):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= radius_sq:
                canvas.blend_pixel(x, y, color)


def distance_to_segment(px, py, ax, ay, bx, by):
    abx = bx - ax
    aby = by - ay
    apx = px - ax
    apy = py - ay
    denom = abx * abx + aby * aby
    if denom == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, (apx * abx + apy * aby) / denom))
    qx = ax + abx * t
    qy = ay + aby * t
    return math.hypot(px - qx, py - qy)


def draw_thick_line(canvas, ax, ay, bx, by, width, color):
    pad = width / 2 + 2
    left = max(0, int(min(ax, bx) - pad))
    right = min(canvas.width, int(max(ax, bx) + pad))
    top = max(0, int(min(ay, by) - pad))
    bottom = min(canvas.height, int(max(ay, by) + pad))
    threshold = width / 2
    for y in range(top, bottom):
        for x in range(left, right):
            if distance_to_segment(x + 0.5, y + 0.5, ax, ay, bx, by) <= threshold:
                canvas.blend_pixel(x, y, color)


def draw_background(canvas, colors):
    top_left, top_right, bottom_left, glow = colors
    for y in range(canvas.height):
        yn = y / max(canvas.height - 1, 1)
        for x in range(canvas.width):
            xn = x / max(canvas.width - 1, 1)
            base = lerp_color(top_left, top_right, (xn + yn * 0.7) / 1.7)
            base = lerp_color(base, bottom_left, yn * 0.9)

            glow_a = max(0.0, 1.0 - math.hypot(xn - 0.18, yn - 0.12) / 0.82)
            glow_b = max(0.0, 1.0 - math.hypot(xn - 0.86, yn - 0.88) / 0.76)

            r = base[0] + glow[0] * glow_a * 0.18 + 255 * glow_b * 0.05
            g = base[1] + glow[1] * glow_a * 0.14 + 255 * glow_b * 0.05
            b = base[2] + glow[2] * glow_a * 0.24 + 255 * glow_b * 0.08
            canvas.set(x, y, (clamp(r), clamp(g), clamp(b), 255))


def draw_icon_mark(canvas, x, y, w, h, include_shadow=True):
    shadow_color = (16, 28, 56, 36)
    if include_shadow:
        draw_rounded_rect(
            canvas,
            (x + w * 0.02, y + h * 0.06, x + w + w * 0.02, y + h + h * 0.06),
            w * 0.16,
            shadow_color,
        )

    draw_rounded_rect(canvas, (x, y, x + w, y + h), w * 0.16, (255, 255, 255, 255))

    header_h = h * 0.25
    draw_rounded_rect(canvas, (x, y, x + w, y + header_h), w * 0.16, (255, 128, 88, 255))
    draw_rounded_rect(canvas, (x, y + header_h * 0.44, x + w, y + header_h), 0, (255, 105, 92, 255))

    ring_w = w * 0.1
    ring_h = h * 0.15
    ring_y = y - ring_h * 0.22
    draw_rounded_rect(
        canvas,
        (x + w * 0.2, ring_y, x + w * 0.2 + ring_w, ring_y + ring_h),
        ring_w * 0.48,
        (255, 255, 255, 235),
    )
    draw_rounded_rect(
        canvas,
        (x + w * 0.7, ring_y, x + w * 0.7 + ring_w, ring_y + ring_h),
        ring_w * 0.48,
        (255, 255, 255, 235),
    )

    line_color = (225, 232, 244, 255)
    for idx in range(3):
        line_y = y + header_h + h * (0.14 + idx * 0.13)
        draw_rounded_rect(
            canvas,
            (x + w * 0.18, line_y, x + w * (0.58 if idx == 0 else 0.5), line_y + h * 0.036),
            h * 0.018,
            line_color,
        )

    draw_thick_line(
        canvas,
        x + w * 0.28,
        y + h * 0.68,
        x + w * 0.44,
        y + h * 0.83,
        w * 0.085,
        (87, 116, 255, 255),
    )
    draw_thick_line(
        canvas,
        x + w * 0.44,
        y + h * 0.83,
        x + w * 0.76,
        y + h * 0.52,
        w * 0.085,
        (87, 116, 255, 255),
    )

    draw_circle(canvas, x + w * 0.84, y + h * 0.19, w * 0.1, (255, 155, 72, 255))
    draw_circle(canvas, x + w * 0.84, y + h * 0.19, w * 0.046, (255, 246, 240, 220))


def render_app_icon(size):
    canvas = Canvas(size, size)
    draw_background(
        canvas,
        (
            (255, 121, 89, 255),
            (108, 128, 255, 255),
            (39, 74, 168, 255),
            (96, 220, 255, 255),
        ),
    )

    draw_circle(canvas, size * 0.15, size * 0.16, size * 0.19, (255, 255, 255, 18))
    draw_circle(canvas, size * 0.88, size * 0.82, size * 0.22, (255, 255, 255, 14))

    card_w = size * 0.56
    card_h = size * 0.66
    card_x = (size - card_w) / 2
    card_y = (size - card_h) / 2
    draw_icon_mark(canvas, card_x, card_y, card_w, card_h, include_shadow=True)
    return canvas


def render_launch_mark(size):
    canvas = Canvas(size, size, (0, 0, 0, 0))
    mark_w = size * 0.56
    mark_h = size * 0.66
    mark_x = (size - mark_w) / 2
    mark_y = (size - mark_h) / 2
    draw_icon_mark(canvas, mark_x, mark_y, mark_w, mark_h, include_shadow=False)
    return canvas


def ensure_contents_json():
    app_icons = [
        ("20x20", "2x", 40, "app-icon-20@2x.png"),
        ("20x20", "3x", 60, "app-icon-20@3x.png"),
        ("29x29", "2x", 58, "app-icon-29@2x.png"),
        ("29x29", "3x", 87, "app-icon-29@3x.png"),
        ("40x40", "2x", 80, "app-icon-40@2x.png"),
        ("40x40", "3x", 120, "app-icon-40@3x.png"),
        ("60x60", "2x", 120, "app-icon-60@2x.png"),
        ("60x60", "3x", 180, "app-icon-60@3x.png"),
        ("1024x1024", "1x", 1024, "app-icon-1024.png"),
    ]

    APP_ICON_SET.mkdir(parents=True, exist_ok=True)
    images = []
    for size_name, scale, px, filename in app_icons:
        entry = {
            "size": size_name,
            "scale": scale,
            "filename": filename,
        }
        if size_name == "1024x1024":
            entry["idiom"] = "ios-marketing"
        else:
            entry["idiom"] = "iphone"
        images.append(entry)

        render_app_icon(px).write_png(APP_ICON_SET / filename)

    (APP_ICON_SET / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    LAUNCH_IMAGE_SET.mkdir(parents=True, exist_ok=True)
    launch_images = [
        ("1x", 180, "launch-brand-1x.png"),
        ("2x", 360, "launch-brand-2x.png"),
        ("3x", 540, "launch-brand-3x.png"),
    ]
    for scale, px, filename in launch_images:
        render_launch_mark(px).write_png(LAUNCH_IMAGE_SET / filename)

    (LAUNCH_IMAGE_SET / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"idiom": "universal", "scale": scale, "filename": filename}
                    for scale, _, filename in launch_images
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )

    LAUNCH_BG_SET.mkdir(parents=True, exist_ok=True)
    (LAUNCH_BG_SET / "Contents.json").write_text(
        json.dumps(
            {
                "colors": [
                    {
                        "idiom": "universal",
                        "color": {
                            "color-space": "srgb",
                            "components": {
                                "red": "0.173",
                                "green": "0.286",
                                "blue": "0.659",
                                "alpha": "1.000",
                            },
                        },
                    }
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    ensure_contents_json()
