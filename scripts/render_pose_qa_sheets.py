#!/usr/bin/env python3
"""Render all approved native poses against light, dark, and checker backgrounds."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
POSES = ROOT / "Resources" / "Poses"
OUTPUT = ROOT / "build" / "pose-qa"
THUMBNAIL = (210, 210)
TILE = (230, 246)
COLUMNS = 5


def checker(size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size, "#dfe5ed")
    draw = ImageDraw.Draw(image)
    block = 20
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill="#8a96a6")
    return image


def background(kind: str) -> Image.Image:
    if kind == "light":
        return Image.new("RGBA", (420, 420), "#f4f7fb")
    if kind == "dark":
        return Image.new("RGBA", (420, 420), "#202630")
    return checker((420, 420))


def render(kind: str, paths: list[Path]) -> None:
    rows = (len(paths) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (COLUMNS * TILE[0], rows * TILE[1]), "#d5dbe3")
    for index, path in enumerate(paths):
        pose = Image.open(path).convert("RGBA")
        stage = background(kind)
        stage.alpha_composite(pose)
        stage.thumbnail(THUMBNAIL, Image.Resampling.LANCZOS)
        tile = Image.new("RGB", TILE, "white")
        tile.paste(stage.convert("RGB"), (10, 8))
        ImageDraw.Draw(tile).text((10, 222), path.name, fill="black")
        sheet.paste(tile, ((index % COLUMNS) * TILE[0], (index // COLUMNS) * TILE[1]))
    sheet.save(OUTPUT / f"poses-{kind}.png", optimize=True)


def main() -> int:
    paths = sorted(POSES.glob("*.png"))
    if not paths:
        raise SystemExit(f"No pose frames found in {POSES}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for kind in ("light", "dark", "checker"):
        render(kind, paths)
    print(f"Rendered {len(paths)} frames on 3 backgrounds in {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
