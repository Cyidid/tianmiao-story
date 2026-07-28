#!/usr/bin/env python3
"""Extract deterministic full-pose sprites from the selected Tianmiao master sheet."""

from pathlib import Path

from PIL import Image

from generate_tianmiao_selected_assets import fit_to_canvas, paper_to_alpha


ROOT = Path(__file__).resolve().parents[1]
SHEET_PATH = ROOT / "assets" / "generated" / "tianmiao-character-sheet-v3-selected.png"
OUTPUT = ROOT / "Resources" / "Poses"
CANVAS = (420, 420)

# Each crop contains exactly one pose from the approved character sheet.
POSE_BOXES = {
    # Use the compact seated pose from the same row as the movement poses.
    # The former top-row seated poses had a much larger head, which caused a
    # visible size jump whenever the cat started or stopped moving.
    "sit_compact": (280, 532, 475, 815),
    "walk_contact": (455, 548, 690, 807),
    "walk_passing": (655, 546, 925, 806),
    "walk_reach": (850, 548, 1190, 811),
    "crouch": (1182, 534, 1525, 812),
    "groom": (30, 747, 330, 1020),
    "scratch": (292, 748, 590, 1020),
    "sleep": (545, 757, 889, 1018),
    "roll_back": (850, 752, 1190, 1022),
    "roll_side": (1120, 756, 1530, 1022),
}

SEQUENCES = {
    "idle": ["sit_compact", "sit_compact"],
    "walk": ["walk_contact", "walk_passing", "walk_reach", "walk_passing"],
    "jump": ["crouch", "walk_contact", "walk_passing", "crouch"],
    "sleep": ["sleep", "sleep"],
    "groom": ["sit_compact", "groom", "groom", "sit_compact"],
    "scratch": ["sit_compact", "scratch", "scratch", "sit_compact"],
    "roll": ["sit_compact", "roll_side", "roll_back", "roll_side", "sit_compact"],
}

def main() -> int:
    sheet = Image.open(SHEET_PATH).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)

    poses: dict[str, Image.Image] = {}
    for name, box in POSE_BOXES.items():
        extracted = paper_to_alpha(sheet.crop(box))
        poses[name] = fit_to_canvas(extracted, CANVAS, bottom_padding=18)

    for action, pose_names in SEQUENCES.items():
        for index, pose_name in enumerate(pose_names):
            poses[pose_name].save(OUTPUT / f"{action}_{index:02d}.png", optimize=True)

    print(f"Generated {sum(len(items) for items in SEQUENCES.values())} pose frames in {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
