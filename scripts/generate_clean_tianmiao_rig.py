#!/usr/bin/env python3
"""Generate clean transparent Tianmiao runtime layers.

The design-sheet crop was useful for exploration, but not for runtime: paper
texture and non-overlapped joints create halos and puppet tearing. This script
draws the app-facing layers directly so every PNG has clean alpha and stable
overlaps for animation.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources"
CANVAS = (360, 392)
S = 4

INK = (67, 68, 65, 255)
DARK = (70, 75, 73, 255)
MID = (132, 139, 136, 255)
LIGHT = (238, 238, 228, 255)
WHITE = (255, 253, 244, 255)
PINK = (255, 154, 148, 255)
PINK_DARK = (218, 118, 116, 255)
SHADOW = (85, 82, 75, 58)


def sc(points: Iterable[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(round(x * S), round(y * S)) for x, y in points]


def layer() -> Image.Image:
    return Image.new("RGBA", (CANVAS[0] * S, CANVAS[1] * S), (0, 0, 0, 0))


def aa(img: Image.Image) -> Image.Image:
    return img.resize(CANVAS, Image.Resampling.LANCZOS)


def draw_line(d: ImageDraw.ImageDraw, pts: Iterable[tuple[float, float]], fill=INK, width=3) -> None:
    d.line(sc(pts), fill=fill, width=round(width * S), joint="curve")


def ellipse(d: ImageDraw.ImageDraw, box: tuple[float, float, float, float], fill, outline=INK, width=2) -> None:
    d.ellipse(tuple(round(v * S) for v in box), fill=fill, outline=outline, width=round(width * S))


def polygon(d: ImageDraw.ImageDraw, pts: Iterable[tuple[float, float]], fill, outline=INK, width=2) -> None:
    points = list(pts)
    d.polygon(sc(points), fill=fill)
    if outline[3] and width > 0:
        d.line(sc(points + [points[0]]), fill=outline, width=round(width * S), joint="curve")


def soft_shadow(img: Image.Image, box: tuple[float, float, float, float], alpha=44) -> None:
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    d.ellipse(tuple(round(v * S) for v in box), fill=(60, 55, 48, alpha))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4 * S)))


def stripe(d: ImageDraw.ImageDraw, pts: Iterable[tuple[float, float]], width=5) -> None:
    draw_line(d, pts, fill=(58, 61, 59, 220), width=width)


def draw_tail_sit() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    soft_shadow(img, (75, 348, 208, 376), 32)
    draw_line(d, [(175, 320), (137, 329), (105, 349), (76, 355)], fill=INK, width=24)
    draw_line(d, [(175, 320), (137, 329), (105, 349), (76, 355)], fill=MID, width=19)
    for x in (88, 116, 145, 169):
        stripe(d, [(x, 345), (x - 15, 358)], width=5)
    return aa(img)


def draw_haunches_sit() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    ellipse(d, (128, 252, 306, 370), fill=(230, 232, 223, 255), width=2.4)
    ellipse(d, (154, 272, 226, 370), fill=WHITE, outline=(0, 0, 0, 0), width=0)
    stripe(d, [(260, 266), (287, 303)], 5)
    stripe(d, [(249, 295), (295, 328)], 5)
    stripe(d, [(136, 289), (162, 326)], 5)
    return aa(img)


def draw_body_sit() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    soft_shadow(img, (126, 345, 304, 376), 36)
    ellipse(d, (128, 194, 300, 366), fill=(231, 233, 224, 255), width=2.5)
    ellipse(d, (154, 201, 258, 366), fill=WHITE, outline=(0, 0, 0, 0), width=0)
    for x in (139, 151, 270, 282):
        stripe(d, [(x, 220), (x + (12 if x < 200 else -12), 278)], width=4)
    draw_line(d, [(178, 250), (174, 330)], fill=(170, 164, 154, 160), width=1.5)
    draw_line(d, [(230, 250), (236, 330)], fill=(170, 164, 154, 160), width=1.5)
    return aa(img)


def draw_paw_sit(left: bool) -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    x0 = 166 if left else 222
    ellipse(d, (x0, 246, x0 + 42, 373), fill=WHITE, width=2.2)
    ellipse(d, (x0 - 2, 336, x0 + 48, 376), fill=WHITE, width=2.2)
    for dx in (10, 22, 34):
        draw_line(d, [(x0 + dx, 354), (x0 + dx - 2, 366)], fill=(112, 107, 102, 190), width=1.1)
    return aa(img)


def draw_head_sit() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    # Ears behind face.
    polygon(d, [(93, 144), (124, 57), (149, 164)], fill=(137, 143, 140, 255), width=2.4)
    polygon(d, [(101, 141), (123, 78), (140, 156)], fill=PINK, outline=(126, 102, 98, 210), width=1.2)
    polygon(d, [(235, 88), (284, 25), (291, 148)], fill=(139, 145, 142, 255), width=2.4)
    polygon(d, [(246, 91), (279, 43), (282, 137)], fill=PINK, outline=(126, 102, 98, 210), width=1.2)
    for x in (116, 123, 130, 260, 271, 280):
        draw_line(d, [(x, 94), (x + 5, 137)], fill=PINK_DARK, width=1.2)

    ellipse(d, (68, 91, 307, 272), fill=(229, 231, 224, 255), width=2.8)
    polygon(d, [(141, 100), (193, 89), (234, 103), (220, 270), (135, 270)], fill=WHITE, outline=(0, 0, 0, 0), width=0)
    ellipse(d, (90, 144, 158, 213), fill=WHITE, width=2)
    ellipse(d, (195, 112, 273, 193), fill=WHITE, width=2)
    ellipse(d, (116, 165, 149, 198), fill=(15, 17, 18, 255), outline=(15, 17, 18, 255), width=1)
    ellipse(d, (226, 136, 262, 174), fill=(15, 17, 18, 255), outline=(15, 17, 18, 255), width=1)
    ellipse(d, (130, 168, 139, 177), fill=(255, 255, 255, 235), outline=(255, 255, 255, 235), width=1)
    ellipse(d, (239, 139, 249, 149), fill=(255, 255, 255, 235), outline=(255, 255, 255, 235), width=1)
    polygon(d, [(177, 202), (189, 199), (184, 209)], fill=(68, 66, 63, 255), outline=(68, 66, 63, 255), width=1)
    polygon(d, [(181, 220), (225, 224), (197, 260)], fill=PINK, width=1.8)
    draw_line(d, [(188, 223), (199, 251)], fill=(180, 90, 92, 190), width=1.2)
    for side, x1, x2 in [(-1, 80, 25), (1, 255, 328)]:
        for y in (196, 210, 224):
            draw_line(d, [(x1, y), (x2, y + side * (y - 205) * 0.2)], fill=(74, 72, 68, 210), width=1.5)
    for pts in [
        [(151, 96), (160, 134)], [(176, 92), (178, 135)], [(202, 95), (194, 134)],
        [(99, 154), (133, 174)], [(248, 112), (226, 147)], [(260, 170), (225, 177)],
    ]:
        stripe(d, pts, width=6)
    return aa(img)


def draw_walk_body() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    soft_shadow(img, (68, 328, 304, 356), 34)
    # Rounded chest and shoulder are part of the body layer so the head can
    # overlap naturally without a rectangular neck patch.
    ellipse(d, (72, 216, 150, 313), fill=WHITE, width=2.2)
    ellipse(d, (103, 196, 278, 306), fill=(226, 229, 221, 255), width=2.4)
    ellipse(d, (118, 226, 246, 310), fill=WHITE, outline=(0, 0, 0, 0), width=0)
    ellipse(d, (81, 229, 134, 302), fill=WHITE, outline=(0, 0, 0, 0), width=0)
    for x in (130, 154, 181, 210, 239):
        stripe(d, [(x, 204), (x - 11, 278)], width=5)
    stripe(d, [(93, 220), (124, 242)], width=4)
    return aa(img)


def draw_walk_tail() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    draw_line(d, [(241, 225), (265, 190), (307, 176), (331, 188)], fill=INK, width=22)
    draw_line(d, [(241, 225), (265, 190), (307, 176), (331, 188)], fill=MID, width=17)
    for x in (260, 288, 314):
        stripe(d, [(x, 192), (x + 8, 180)], width=5)
    return aa(img)


def draw_walk_leg(name: str) -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    specs = {
        "walk_rear_leg": {
            "line": [(136, 260), (122, 296), (96, 330)],
            "paw": (78, 321, 116, 343),
            "width": 22,
            "shade": [(123, 272), (112, 304), (94, 329)],
        },
        "walk_hind_leg": {
            "line": [(196, 260), (207, 296), (208, 332)],
            "paw": (198, 323, 230, 343),
            "width": 21,
            "shade": [(203, 272), (211, 305), (211, 331)],
        },
        "walk_front_down_leg": {
            "line": [(101, 252), (86, 294), (68, 333)],
            "paw": (49, 324, 83, 345),
            "width": 22,
            "shade": [(97, 265), (84, 299), (68, 333)],
        },
        "walk_front_leg": {
            "line": [(113, 252), (130, 289), (151, 326)],
            "paw": (132, 317, 169, 340),
            "width": 20,
            "shade": [(119, 265), (134, 296), (151, 326)],
        },
    }[name]
    draw_line(d, specs["line"], fill=INK, width=specs["width"] + 3)
    draw_line(d, specs["line"], fill=WHITE, width=specs["width"])
    ellipse(d, specs["paw"], fill=WHITE, width=2.0)
    draw_line(d, specs["shade"], fill=(172, 166, 156, 130), width=1.2)
    return aa(img)


def draw_walk_head() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img)
    polygon(d, [(54, 154), (72, 92), (102, 157)], fill=(137, 143, 140, 255), width=2.2)
    polygon(d, [(119, 133), (156, 84), (166, 164)], fill=(139, 145, 142, 255), width=2.2)
    polygon(d, [(60, 151), (73, 108), (92, 154)], fill=PINK, outline=(126, 102, 98, 210), width=1)
    polygon(d, [(127, 133), (153, 98), (158, 158)], fill=PINK, outline=(126, 102, 98, 210), width=1)
    ellipse(d, (34, 138, 171, 247), fill=(229, 231, 224, 255), width=2.4)
    ellipse(d, (52, 150, 148, 247), fill=WHITE, outline=(0, 0, 0, 0), width=0)
    ellipse(d, (50, 180, 92, 222), fill=WHITE, width=1.8)
    ellipse(d, (96, 158, 142, 205), fill=WHITE, width=1.8)
    ellipse(d, (63, 193, 84, 214), fill=(12, 14, 15, 255), outline=(12, 14, 15, 255), width=1)
    ellipse(d, (113, 174, 137, 199), fill=(12, 14, 15, 255), outline=(12, 14, 15, 255), width=1)
    ellipse(d, (71, 194, 77, 200), fill=(255, 255, 255, 235), outline=(255, 255, 255, 235), width=1)
    polygon(d, [(39, 215), (50, 212), (45, 220)], fill=INK, outline=INK, width=1)
    polygon(d, [(70, 218), (104, 222), (86, 246)], fill=PINK, width=1.4)
    for pts in [[(76, 146), (84, 173)], [(104, 137), (106, 166)], [(140, 164), (127, 186)], [(45, 165), (68, 177)]]:
        stripe(d, pts, width=5)
    for y in (210, 222):
        draw_line(d, [(43, y), (12, y + 3)], fill=(74, 72, 68, 210), width=1.2)
    return aa(img)


def save(name: str, img: Image.Image) -> None:
    img.save(OUT / f"{name}.png", optimize=True)


def composite(names: list[str]) -> Image.Image:
    out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    for name in names:
        out.alpha_composite(Image.open(OUT / f"{name}.png").convert("RGBA"))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    save("rig_tail", draw_tail_sit())
    save("rig_haunches", draw_haunches_sit())
    save("rig_body", draw_body_sit())
    save("rig_paw_left", draw_paw_sit(True))
    save("rig_paw_right", draw_paw_sit(False))
    save("rig_head", draw_head_sit())
    save("normal", composite(["rig_tail", "rig_haunches", "rig_body", "rig_paw_left", "rig_paw_right", "rig_head"]))

    save("walk_tail", draw_walk_tail())
    save("walk_body", draw_walk_body())
    for name in ("walk_rear_leg", "walk_hind_leg", "walk_front_down_leg", "walk_front_leg"):
        save(name, draw_walk_leg(name))
    save("walk_head", draw_walk_head())
    print(f"Generated clean Tianmiao runtime layers in {OUT}")


if __name__ == "__main__":
    main()
