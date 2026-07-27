#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "live2d-source" / "tianmiao"
LAYERS = OUT / "layers"
PREVIEWS = OUT / "previews"
ALPHA = OUT / "alpha"
GENERATED = OUT / "generated"

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


def fit(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    copy = image.copy()
    copy.thumbnail(box, Image.Resampling.LANCZOS)
    return copy


def load_identity_pose() -> Image.Image:
    model_sheet = ALPHA / "model-sheet.png"
    if model_sheet.exists():
        sheet = Image.open(model_sheet).convert("RGBA")
        first_pose = sheet.crop((0, 0, sheet.width // 5, sheet.height))
        return trim(first_pose, padding=8)
    return trim(Image.open(SOURCE).convert("RGBA"), padding=8)


def make_blink_pose(source: Image.Image) -> Image.Image:
    image = source.copy()
    draw = ImageDraw.Draw(image)
    w, h = image.size
    draw.arc((w * 0.30, h * 0.30, w * 0.48, h * 0.42), 190, 350, fill=(42, 42, 42, 255), width=max(3, w // 60))
    draw.arc((w * 0.53, h * 0.30, w * 0.72, h * 0.42), 190, 350, fill=(42, 42, 42, 255), width=max(3, w // 60))
    return image


def make_tap_pose(source: Image.Image) -> Image.Image:
    return source.rotate(-8, expand=True, resample=Image.Resampling.BICUBIC)


def make_walk_pose(source: Image.Image) -> Image.Image:
    image = source.copy()
    draw = ImageDraw.Draw(image)
    # Keep this as an identity reference, not a fake frame made from the
    # rejected walking slices that still contain dark matte artifacts.
    w, h = image.size
    for x0, y0, x1, y1 in [
        (w * 0.34, h * 0.76, w * 0.46, h * 0.92),
        (w * 0.58, h * 0.74, w * 0.70, h * 0.90),
    ]:
        draw.arc((x0, y0, x1, y1), 210, 340, fill=(55, 55, 55, 170), width=4)
    draw.arc((w * 0.05, h * 0.67, w * 0.38, h * 0.93), 18, 146, fill=(55, 55, 55, 150), width=5)
    return image.rotate(1.8, expand=True, resample=Image.Resampling.BICUBIC)


def make_groom_pose(source: Image.Image) -> Image.Image:
    image = source.copy()
    paw = Image.open(ROOT / "Resources" / "rig_paw_left.png").convert("RGBA")
    paw = trim(paw, padding=2).rotate(-18, expand=True, resample=Image.Resampling.BICUBIC)
    paw.thumbnail((max(48, image.width // 5), max(72, image.height // 4)), Image.Resampling.LANCZOS)
    image.alpha_composite(paw, (image.width // 2 - paw.width // 2, image.height // 2 - paw.height // 5))
    return image


def make_scratch_pose(source: Image.Image) -> Image.Image:
    image = source.copy()
    paw = Image.open(ROOT / "Resources" / "rig_paw_right.png").convert("RGBA")
    paw = trim(paw, padding=2).rotate(16, expand=True, resample=Image.Resampling.BICUBIC)
    paw.thumbnail((max(54, image.width // 4), max(82, image.height // 3)), Image.Resampling.LANCZOS)
    image.alpha_composite(paw, (int(image.width * 0.62), int(image.height * 0.42)))
    draw = ImageDraw.Draw(image)
    for offset in [0, 11, 22]:
        y = int(image.height * 0.45) + offset
        draw.line((int(image.width * 0.82), y, int(image.width * 0.95), y - 18), fill=(42, 42, 42, 210), width=3)
    return image


def make_identity_locked_motion_reference() -> None:
    ALPHA.mkdir(parents=True, exist_ok=True)
    GENERATED.mkdir(parents=True, exist_ok=True)
    source = load_identity_pose()
    poses = [
        ("idle", source),
        ("blink", trim(make_blink_pose(source), padding=8)),
        ("tap", trim(make_tap_pose(source), padding=8)),
        ("walk", trim(make_walk_pose(source), padding=8)),
        ("groom", trim(make_groom_pose(source), padding=8)),
        ("scratch", trim(make_scratch_pose(source), padding=8)),
    ]
    cell_w, cell_h = 360, 360
    cols = 3
    sheet = Image.new("RGBA", (cols * cell_w, 2 * cell_h), (0, 0, 0, 0))
    labeled = Image.new("RGBA", sheet.size, (0, 255, 0, 255))
    draw = ImageDraw.Draw(labeled)
    try:
        font = ImageFont.truetype("Arial.ttf", 32)
    except OSError:
        font = ImageFont.load_default()

    for idx, (label, pose) in enumerate(poses):
        col = idx % cols
        row = idx // cols
        image = fit(pose, (260, 276))
        x = col * cell_w + (cell_w - image.width) // 2
        y = row * cell_h + 24
        sheet.alpha_composite(image, (x, y))
        labeled.alpha_composite(image, (x, y))
        text_x = col * cell_w + 24
        text_y = row * cell_h + cell_h - 54
        draw.text((text_x, text_y), label, fill=(32, 32, 32, 255), font=font)

    sheet.save(ALPHA / "motion-reference.png")
    labeled.save(GENERATED / "motion-reference-identity-composite.png")
    labeled.save(GENERATED / "motion-reference-chroma.png")


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
        "- The current motion reference is identity-locked from alpha/model-sheet.png, not a separate AI-redrawn cat.",
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
    make_identity_locked_motion_reference()
    write_manifest()
    print(f"Wrote Live2D source package to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
