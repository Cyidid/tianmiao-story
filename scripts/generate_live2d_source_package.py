#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "live2d-source" / "tianmiao"
LAYERS = OUT / "layers"
PREVIEWS = OUT / "previews"

SOURCE = ROOT / "Resources" / "normal.png"
RIG_PARTS = {
    "HeadBase": ROOT / "Resources" / "rig_head.png",
    "BodyBase": ROOT / "Resources" / "rig_body.png",
    "HipBase": ROOT / "Resources" / "rig_haunches.png",
    "FrontPawNear": ROOT / "Resources" / "rig_paw_left.png",
    "FrontPawFar": ROOT / "Resources" / "rig_paw_right.png",
    "TailRoot": ROOT / "Resources" / "rig_tail.png",
    "TailMid": ROOT / "Resources" / "rig_tail.png",
    "TailTip": ROOT / "Resources" / "rig_tail.png",
}

# Source-image crops are intentionally conservative. They are production
# starting points for Cubism cleanup, not final rigged meshes.
CROPS = {
    "EarL": (66, 91, 151, 191),
    "EarR": (196, 5, 278, 126),
    "EarInnerL": (80, 110, 142, 181),
    "EarInnerR": (211, 28, 264, 113),
    "EyeWhiteL": (132, 199, 194, 260),
    "EyeWhiteR": (202, 152, 273, 220),
    "PupilL": (150, 217, 184, 253),
    "PupilR": (223, 169, 260, 210),
    "EyeHighlightL": (155, 218, 169, 232),
    "EyeHighlightR": (229, 170, 244, 185),
    "FaceWhite": (101, 80, 279, 291),
    "ForeheadStripes": (136, 12, 238, 128),
    "CheekStripesL": (95, 182, 165, 272),
    "CheekStripesR": (235, 124, 293, 214),
    "Nose": (188, 252, 209, 269),
    "MouthUpper": (174, 258, 231, 315),
    "MouthInner": (169, 262, 232, 320),
    "MouthTongue": (187, 291, 221, 319),
    "WhiskersL": (72, 249, 170, 317),
    "WhiskersR": (226, 190, 321, 255),
    "ChestWhite": (123, 281, 238, 377),
    "BackStripes": (64, 169, 124, 360),
    "FrontLegNear": (139, 297, 178, 376),
    "FrontLegFar": (204, 282, 245, 376),
    "HindLegNear": (78, 318, 141, 376),
    "HindLegFar": (232, 292, 289, 376),
    "HindPawNear": (73, 337, 148, 376),
    "HindPawFar": (220, 330, 296, 376),
}

REQUIRED_LAYER_NAMES = [
    "HeadBase", "FaceWhite", "ForeheadStripes", "CheekStripesL", "CheekStripesR",
    "Nose", "MouthUpper", "MouthInner", "MouthTongue", "WhiskersL", "WhiskersR",
    "EarL", "EarR", "EarInnerL", "EarInnerR", "EyeWhiteL", "EyeWhiteR",
    "PupilL", "PupilR", "EyeHighlightL", "EyeHighlightR", "EyelidUpperL",
    "EyelidUpperR", "EyelidLowerL", "EyelidLowerR", "BodyBase", "ChestWhite",
    "BackStripes", "HipBase", "FrontLegNear", "FrontLegFar", "FrontPawNear",
    "FrontPawFar", "HindLegNear", "HindLegFar", "HindPawNear", "HindPawFar",
    "TailRoot", "TailMid", "TailTip", "TailStripes", "GroundShadow",
]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def trim(image: Image.Image, padding: int = 8) -> Image.Image:
    bbox = alpha_bbox(image)
    if bbox is None:
        return image
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(image.width, x1 + padding)
    y1 = min(image.height, y1 + padding)
    return image.crop((x0, y0, x1, y1))


def crop_source(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    return trim(source.crop(box), padding=4)


def make_shadow() -> Image.Image:
    image = Image.new("RGBA", (220, 54), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.ellipse((10, 12, 210, 44), fill=(34, 28, 22, 72))
    return image


def make_eyelid(size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.arc((4, 4, size[0] - 4, size[1] - 4), 190, 350, fill=(48, 48, 48, 255), width=4)
    return image


def load_layers() -> dict[str, Image.Image]:
    source = Image.open(SOURCE).convert("RGBA")
    layers: dict[str, Image.Image] = {}
    for name, path in RIG_PARTS.items():
        layers[name] = trim(Image.open(path).convert("RGBA"), padding=8)
    for name, box in CROPS.items():
        layers[name] = crop_source(source, box)

    layers["EyelidUpperL"] = make_eyelid((72, 36))
    layers["EyelidUpperR"] = make_eyelid((78, 38))
    layers["EyelidLowerL"] = make_eyelid((72, 28)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    layers["EyelidLowerR"] = make_eyelid((78, 30)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    layers["TailStripes"] = crop_source(source, (45, 317, 145, 376))
    layers["GroundShadow"] = make_shadow()
    return layers


def save_layers(layers: dict[str, Image.Image]) -> None:
    LAYERS.mkdir(parents=True, exist_ok=True)
    for name in REQUIRED_LAYER_NAMES:
        image = layers[name]
        image.save(LAYERS / f"{name}.png")


def make_sheet(layers: dict[str, Image.Image]) -> None:
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    cell_w, cell_h = 220, 180
    cols = 6
    rows = (len(REQUIRED_LAYER_NAMES) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("Arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()

    for idx, name in enumerate(REQUIRED_LAYER_NAMES):
        col = idx % cols
        row = idx // cols
        x = col * cell_w
        y = row * cell_h
        image = layers[name].copy()
        image.thumbnail((cell_w - 28, cell_h - 48), Image.Resampling.LANCZOS)
        px = x + (cell_w - image.width) // 2
        py = y + 12
        sheet.alpha_composite(image, (px, py))
        draw.text((x + 10, y + cell_h - 30), name, fill=(42, 42, 42, 255), font=font)
    sheet.save(PREVIEWS / "layer-source-sheet.png")

    white = Image.new("RGBA", sheet.size, (250, 248, 240, 255))
    grid = ImageDraw.Draw(white)
    for x in range(0, white.width, cell_w):
        grid.line((x, 0, x, white.height), fill=(224, 220, 210, 255), width=1)
    for y in range(0, white.height, cell_h):
        grid.line((0, y, white.width, y), fill=(224, 220, 210, 255), width=1)
    white.alpha_composite(sheet)
    white.convert("RGB").save(PREVIEWS / "layer-source-sheet-on-white.jpg", quality=94)


def write_manifest() -> None:
    lines = [
        "# Tianmiao Live2D Source Package",
        "",
        "This package is a Cubism production source kit, not a generated .moc3 model.",
        "",
        "Generated layer PNGs:",
    ]
    lines.extend(f"- layers/{name}.png" for name in REQUIRED_LAYER_NAMES)
    lines.extend([
        "",
        "Important limitations:",
        "- This is a production starting package for Cubism cleanup, not a final rig.",
        "- Layer PNGs are auto-cropped from the currently selected cat identity and existing transparent rig parts.",
        "- Small facial parts and overlap boundaries should be cleaned by a Cubism artist before mesh binding.",
        "- Motion reference art is visual guidance only and must not replace the selected cat identity.",
        "",
        "Generated previews:",
        "- alpha/model-sheet.png",
        "- alpha/motion-reference.png",
        "- previews/layer-source-sheet.png",
        "- previews/layer-source-sheet-on-white.jpg",
        "",
        "Next step: import these layers into Live2D Cubism Editor/Modeler, clean mesh boundaries, bind parameters, and export tianmiao.model3.json, tianmiao.moc3, textures, and motion3 files.",
    ])
    (OUT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    manifest = {
        "packageVersion": "source-v1",
        "character": "Tianmiao selected gray-white tabby",
        "sourceIdentity": "Resources/normal.png",
        "purpose": "Cubism production source kit, not a moc3 export",
        "limitations": [
            "Auto-cropped layer PNGs require artist cleanup before Cubism mesh binding.",
            "Motion reference art is visual guidance only.",
            "This package does not include model3, moc3, textures, or motion3 exports."
        ],
        "requiredLayerNames": REQUIRED_LAYER_NAMES,
        "modelSheet": "alpha/model-sheet.png",
        "motionReference": "alpha/motion-reference.png",
        "layerPreview": "previews/layer-source-sheet.png",
        "humanPreview": "previews/layer-source-sheet-on-white.jpg",
        "nextStep": "Import layers into Live2D Cubism Editor/Modeler and export model3/moc3/textures/motion3 files.",
    }
    (OUT / "source-package-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    layers = load_layers()
    missing = [name for name in REQUIRED_LAYER_NAMES if name not in layers]
    if missing:
        raise RuntimeError(f"Missing layers: {missing}")
    save_layers(layers)
    make_sheet(layers)
    write_manifest()
    print(f"Wrote Live2D source package to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
