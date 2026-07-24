#!/usr/bin/env python3
"""Prepare the selected watercolor Tianmiao sheet for the runtime rig."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SELECTED_SHEET = Path(
    "/Users/cydid/.codex/generated_images/019f875f-56a5-7302-a81f-9c4353df06d5/"
    "call_iFKg4rIJb6qMZoDO6DgmKTfn.png"
)
MASTER_OUT = ROOT / "assets" / "generated" / "tianmiao-character-sheet-v3-selected.png"
RESOURCES = ROOT / "Resources"
MULTIVIEW = ROOT / "assets" / "source" / "multiview"

CANVAS = (360, 392)
NORMAL_BOX = (38, 32, 286, 366)
WALK_BOX = (610, 585, 930, 795)
BACKGROUND_DISTANCE = 38


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def sampled_background(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    samples: list[tuple[int, int, int]] = []
    w, h = rgb.size
    for x in range(0, w, max(1, w // 16)):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, h - 1)))
    for y in range(0, h, max(1, h // 16)):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((w - 1, y)))
    samples.sort(key=lambda c: sum(c))
    mid = samples[len(samples) // 2]
    return mid


def paper_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    rgb = rgba.convert("RGB")
    bg = sampled_background(rgb)
    w, h = rgb.size
    seen = bytearray(w * h)
    background = bytearray(w * h)
    queue: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        idx = y * w + x
        if seen[idx]:
            return
        seen[idx] = 1
        if color_distance(rgb.getpixel((x, y)), bg) <= BACKGROUND_DISTANCE:
            background[idx] = 1
            queue.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                push(nx, ny)

    bg_mask = Image.frombytes("L", (w, h), bytes(255 if v else 0 for v in background))
    subject = ImageChops.invert(bg_mask)
    subject = subject.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    alpha = ImageChops.multiply(rgba.getchannel("A"), subject)
    rgba.putalpha(alpha)
    return keep_primary_subject(rgba)


def keep_primary_subject(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    w, h = rgba.size
    pix = alpha.load()
    seen = bytearray(w * h)
    components: list[list[tuple[int, int]]] = []

    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if seen[idx] or pix[x, y] <= 18:
                continue
            seen[idx] = 1
            stack = [(x, y)]
            component: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        nidx = ny * w + nx
                        if not seen[nidx] and pix[nx, ny] > 18:
                            seen[nidx] = 1
                            stack.append((nx, ny))
            components.append(component)

    if not components:
        return rgba

    largest = max(components, key=len)
    keep = set(largest)
    out_alpha = Image.new("L", rgba.size, 0)
    out_pix = out_alpha.load()
    for x, y in keep:
        out_pix[x, y] = pix[x, y]
    out_alpha = out_alpha.filter(ImageFilter.GaussianBlur(0.25))
    rgba.putalpha(out_alpha)
    return rgba


def content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda v: 255 if v > 12 else 0).getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    return bbox


def fit_to_canvas(image: Image.Image, canvas_size: tuple[int, int], bottom_padding: int) -> Image.Image:
    bbox = content_bbox(image)
    cropped = image.crop(bbox)
    max_w = canvas_size[0] - 24
    max_h = canvas_size[1] - 20
    scale = min(max_w / cropped.width, max_h / cropped.height)
    cropped = cropped.resize(
        (round(cropped.width * scale), round(cropped.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - cropped.width) // 2
    y = canvas_size[1] - cropped.height - bottom_padding
    canvas.alpha_composite(cropped, (x, max(0, y)))
    return canvas


def save_icns() -> None:
    import subprocess

    subprocess.run(["python3", str(ROOT / "scripts" / "generate_app_icon.py")], check=True)
    iconset = ROOT / "build" / "AppIcon.iconset"
    out = RESOURCES / "AppIcon.icns"
    if out.exists():
        out.unlink()
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(out)], check=True)


def main() -> int:
    if not SELECTED_SHEET.exists():
        raise FileNotFoundError(SELECTED_SHEET)

    RESOURCES.mkdir(parents=True, exist_ok=True)
    MULTIVIEW.mkdir(parents=True, exist_ok=True)
    MASTER_OUT.parent.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(SELECTED_SHEET).convert("RGBA")
    sheet.save(MASTER_OUT, optimize=True)

    normal = fit_to_canvas(paper_to_alpha(sheet.crop(NORMAL_BOX)), CANVAS, bottom_padding=16)
    normal.save(RESOURCES / "normal.png", optimize=True)

    walk = fit_to_canvas(paper_to_alpha(sheet.crop(WALK_BOX)), (326, 250), bottom_padding=8)
    walk_source = MULTIVIEW / "tianmiao-selected-walk.png"
    walk.save(walk_source, optimize=True)

    save_icns()
    print(f"Saved selected master: {MASTER_OUT}")
    print(f"Saved runtime neutral: {RESOURCES / 'normal.png'}")
    print(f"Saved runtime walk source: {walk_source}")
    print(f"Saved icon: {RESOURCES / 'AppIcon.icns'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
