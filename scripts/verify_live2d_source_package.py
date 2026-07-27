#!/usr/bin/env python3
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "assets" / "live2d-source" / "tianmiao"
MANIFEST = PACKAGE / "source-package-manifest.json"


def fail(message: str) -> int:
    print(f"Live2D source package error: {message}")
    return 1


def check_alpha_png(path: Path) -> str | None:
    if not path.exists():
        return f"missing {path.relative_to(ROOT)}"
    try:
        image = Image.open(path)
    except OSError as exc:
        return f"cannot open {path.relative_to(ROOT)}: {exc}"
    if image.mode != "RGBA":
        return f"{path.relative_to(ROOT)} must be RGBA, got {image.mode}"
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return f"{path.relative_to(ROOT)} has empty alpha"
    return None


def main() -> int:
    if not MANIFEST.exists():
        return fail(f"missing {MANIFEST.relative_to(ROOT)}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    layer_names = manifest.get("requiredLayerNames", [])
    if len(layer_names) < 40:
        return fail("manifest has too few layer names")

    errors: list[str] = []
    for rel in [manifest["modelSheet"], manifest["motionReference"], manifest["layerPreview"]]:
        error = check_alpha_png(PACKAGE / rel)
        if error:
            errors.append(error)
    for name in layer_names:
        error = check_alpha_png(PACKAGE / "layers" / f"{name}.png")
        if error:
            errors.append(error)

    human_preview = PACKAGE / manifest["humanPreview"]
    if not human_preview.exists():
        errors.append(f"missing {human_preview.relative_to(ROOT)}")

    if errors:
        print("Live2D source package is not ready:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Live2D source package is ready with {len(layer_names)} layers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
