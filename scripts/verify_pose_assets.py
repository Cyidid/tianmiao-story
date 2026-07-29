#!/usr/bin/env python3
"""Validate the complete deterministic native pose set before release."""

from hashlib import sha256
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
POSES = ROOT / "Resources" / "Poses"
MASTER = ROOT / "assets" / "generated" / "tianmiao-character-sheet-v4-no-ground.png"
EXPECTED = {
    "idle": 2, "walk": 4, "jump": 4, "sleep": 2,
    "groom": 4, "scratch": 4, "roll": 5,
}
APPROVED_MASTER_HASH = "885468518416ce77df66981151195761b3287db5aefbb5e38062305e1957b8f1"
APPROVED_PIXEL_HASHES = {
    "groom_00.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "groom_01.png": "8e64880eb7b29db52f0cb454ba3667e979824ede2a7875999b63b5e5d423abbd",
    "groom_02.png": "8e64880eb7b29db52f0cb454ba3667e979824ede2a7875999b63b5e5d423abbd",
    "groom_03.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "idle_00.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "idle_01.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "jump_00.png": "ed2694bd1c2d2592bcf3fa2e99c2201532464307d16e5bec184988e2337d7604",
    "jump_01.png": "4ca26e64bcc76ab3950b98a6bb2138356c16b85aa3057b75474234c180335533",
    "jump_02.png": "2cb7d59fc0f7d53d591c81bad3d83e6ca0b0e6eae131c1750e0c16537caec842",
    "jump_03.png": "ed2694bd1c2d2592bcf3fa2e99c2201532464307d16e5bec184988e2337d7604",
    "roll_00.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "roll_01.png": "dda71aec87c3249f25812c180a35119705fc710a87dacfe3d686272f20ef4afa",
    "roll_02.png": "5b148e7bb7081d69edd973608a8d35b01cda5bd123f7e8330955584865507659",
    "roll_03.png": "dda71aec87c3249f25812c180a35119705fc710a87dacfe3d686272f20ef4afa",
    "roll_04.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "scratch_00.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "scratch_01.png": "95dc7f4d3d1e6591477f5712cb994ba23233bfee795f1c3b46df753f5982d9c7",
    "scratch_02.png": "95dc7f4d3d1e6591477f5712cb994ba23233bfee795f1c3b46df753f5982d9c7",
    "scratch_03.png": "56b6647818be02d68113f98b57517c843b3e4b30567a04de4416887c5edb4bc9",
    "sleep_00.png": "b44876856ec3cb0d2eef00b998943abdb69b870f9a58074c53654036185c37ad",
    "sleep_01.png": "b44876856ec3cb0d2eef00b998943abdb69b870f9a58074c53654036185c37ad",
    "walk_00.png": "4ca26e64bcc76ab3950b98a6bb2138356c16b85aa3057b75474234c180335533",
    "walk_01.png": "2cb7d59fc0f7d53d591c81bad3d83e6ca0b0e6eae131c1750e0c16537caec842",
    "walk_02.png": "09bf8b7f709839a157f7138974cbb7e82314af4b9e441ad3d973d3eeda377ab7",
    "walk_03.png": "2cb7d59fc0f7d53d591c81bad3d83e6ca0b0e6eae131c1750e0c16537caec842",
}


def fail(message: str) -> None:
    raise SystemExit(message)


if not MASTER.is_file():
    fail(f"Missing approved no-ground master sheet: {MASTER}")
if sha256(MASTER.read_bytes()).hexdigest() != APPROVED_MASTER_HASH:
    fail("No-ground master sheet changed; repeat visual QA before approving a new hash.")

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
            pixel_hash = sha256(image.convert("RGBA").tobytes()).hexdigest()
            if pixel_hash != APPROVED_PIXEL_HASHES[path.name]:
                fail(
                    f"Pose visual changed: {path.name}; repeat head-scale and ground-mark QA "
                    "before approving a new hash."
                )

actual = sorted(POSES.glob("*.png"))
if len(actual) != sum(EXPECTED.values()):
    fail(f"Unexpected pose frame count: {len(actual)}")

print(f"Verified {len(actual)} transparent full-pose frames.")
