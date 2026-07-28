#!/usr/bin/env python3
"""Validate the complete deterministic native pose set before release."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
POSES = ROOT / "Resources" / "Poses"
EXPECTED = {
    "idle": 2, "walk": 4, "jump": 4, "sleep": 2,
    "groom": 4, "scratch": 4, "roll": 5,
}


def fail(message: str) -> None:
    raise SystemExit(message)


for action, count in EXPECTED.items():
    for index in range(count):
        path = POSES / f"{action}_{index:02d}.png"
        if not path.is_file():
            fail(f"Missing pose frame: {path}")
        with Image.open(path) as image:
            if image.mode != "RGBA" or image.size != (420, 420):
                fail(f"Invalid pose canvas: {path} is {image.mode} {image.size}")
            bbox = image.getchannel("A").point(
                lambda value: 255 if value > 18 else 0
            ).getbbox()
            if bbox is None:
                fail(f"Empty pose frame: {path}")
            left, top, right, bottom = bbox
            if left <= 1 or top <= 1 or right >= 419 or bottom >= 419:
                fail(f"Pose touches the unsafe canvas edge: {path} {bbox}")

actual = sorted(POSES.glob("*.png"))
if len(actual) != sum(EXPECTED.values()):
    fail(f"Unexpected pose frame count: {len(actual)}")

print(f"Verified {len(actual)} transparent full-pose frames.")
