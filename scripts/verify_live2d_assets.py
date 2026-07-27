#!/usr/bin/env python3
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "Resources" / "Live2D" / "Tianmiao"
WEB_MODEL_DIR = ROOT / "web-preview" / "public" / "live2d" / "Tianmiao"
MANIFEST = MODEL_DIR / "tianmiao.live2d-manifest.json"
MODEL_JSON = MODEL_DIR / "tianmiao.model3.json"
MODEL_MOC = MODEL_DIR / "tianmiao.moc3"
MOTIONS = ["idle", "blink", "tap", "walk", "groom", "scratch"]


def load_json(path: Path, errors: list[str]):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{path.relative_to(ROOT)} is invalid JSON: {exc}")
        return None


def main() -> int:
    required = os.environ.get("REQUIRE_LIVE2D_ASSETS") == "1"
    missing: list[str] = []
    errors: list[str] = []

    for path in [MANIFEST, MODEL_JSON, MODEL_MOC]:
        if not path.exists():
            missing.append(path.relative_to(ROOT).as_posix())

    for motion in MOTIONS:
        path = MODEL_DIR / "motions" / f"{motion}.motion3.json"
        if not path.exists():
            missing.append(path.relative_to(ROOT).as_posix())

    texture_dir = MODEL_DIR / "textures"
    if not texture_dir.exists() or not any(texture_dir.glob("*.png")):
        missing.append("Resources/Live2D/Tianmiao/textures/*.png")

    if MANIFEST.exists():
        manifest = load_json(MANIFEST, errors)
        if manifest:
            supported = manifest.get("supportedMotions", [])
            if supported != MOTIONS:
                errors.append(f"supportedMotions must be {MOTIONS}, got {supported}")
            if manifest.get("modelPath") not in (None, "tianmiao.model3.json"):
                errors.append("modelPath must be tianmiao.model3.json")

    if MODEL_JSON.exists():
        data = load_json(MODEL_JSON, errors)
        if data:
            references = data.get("FileReferences", {})
            moc = references.get("Moc")
            if moc and not (MODEL_DIR / moc).exists():
                missing.append(f"Resources/Live2D/Tianmiao/{moc}")
            for texture in references.get("Textures", []):
                if not (MODEL_DIR / texture).exists():
                    missing.append(f"Resources/Live2D/Tianmiao/{texture}")
            motions = references.get("Motions", {})
            for motion in MOTIONS:
                entries = motions.get(motion)
                if not entries:
                    continue
                for entry in entries:
                    motion_file = entry.get("File")
                    if motion_file and not (MODEL_DIR / motion_file).exists():
                        missing.append(f"Resources/Live2D/Tianmiao/{motion_file}")

    if required and WEB_MODEL_DIR.exists():
        for path in [MANIFEST, MODEL_JSON, MODEL_MOC]:
            web_path = WEB_MODEL_DIR / path.relative_to(MODEL_DIR)
            if path.exists() and not web_path.exists():
                missing.append(web_path.relative_to(ROOT).as_posix())

    if errors:
        print("Live2D asset metadata has errors:")
        for item in errors:
            print(f"- {item}")
        return 1

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
