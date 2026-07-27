#!/usr/bin/env python3
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "Resources" / "Live2D" / "Tianmiao"
MODEL_JSON = MODEL_DIR / "tianmiao.model3.json"
MODEL_MOC = MODEL_DIR / "tianmiao.moc3"
MOTIONS = ["idle", "blink", "tap", "walk", "groom", "scratch"]


def main() -> int:
    required = os.environ.get("REQUIRE_LIVE2D_ASSETS") == "1"
    missing = []

    for path in [MODEL_JSON, MODEL_MOC]:
        if not path.exists():
            missing.append(path.relative_to(ROOT).as_posix())

    for motion in MOTIONS:
        path = MODEL_DIR / "motions" / f"{motion}.motion3.json"
        if not path.exists():
            missing.append(path.relative_to(ROOT).as_posix())

    texture_dir = MODEL_DIR / "textures"
    if not texture_dir.exists() or not any(texture_dir.glob("*.png")):
        missing.append("Resources/Live2D/Tianmiao/textures/*.png")

    if MODEL_JSON.exists():
        try:
            data = json.loads(MODEL_JSON.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"Live2D model JSON is invalid: {exc}")
            return 1
        references = data.get("FileReferences", {})
        moc = references.get("Moc")
        if moc and not (MODEL_DIR / moc).exists():
            missing.append(f"Resources/Live2D/Tianmiao/{moc}")
        for texture in references.get("Textures", []):
            if not (MODEL_DIR / texture).exists():
                missing.append(f"Resources/Live2D/Tianmiao/{texture}")

    if missing:
        print("Live2D assets are not ready:")
        for item in missing:
            print(f"- {item}")
        if required:
            return 1
        print("Continuing because REQUIRE_LIVE2D_ASSETS is not set.")
        return 0

    print("Live2D assets are ready.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
