#!/usr/bin/env python3
import argparse
import filecmp
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources" / "Live2D" / "Tianmiao"
TARGET = ROOT / "web-preview" / "public" / "live2d" / "Tianmiao"
EXCLUDED_NAMES = {"native-sdk-adapter.README.md", "sdk-adapter.README.md"}


def iter_files(root: Path):
    return sorted(path for path in root.rglob("*") if path.is_file() and path.name not in EXCLUDED_NAMES)


def check_sync() -> int:
    if not SOURCE.exists():
        print(f"Missing source directory: {SOURCE.relative_to(ROOT)}")
        return 1
    missing = []
    changed = []
    source_rels = {path.relative_to(SOURCE) for path in iter_files(SOURCE)}
    for rel in sorted(source_rels):
        source_file = SOURCE / rel
        target_file = TARGET / rel
        if not target_file.exists():
            missing.append(target_file.relative_to(ROOT).as_posix())
        elif not filecmp.cmp(source_file, target_file, shallow=False):
            changed.append(target_file.relative_to(ROOT).as_posix())
    extra = []
    if TARGET.exists():
        for target_file in iter_files(TARGET):
            if target_file.relative_to(TARGET) not in source_rels:
                extra.append(target_file.relative_to(ROOT).as_posix())
    if missing or changed or extra:
        print("Live2D web assets are out of sync.")
        for label, items in [("missing", missing), ("changed", changed), ("extra", extra)]:
            for item in items:
                print(f"- {label}: {item}")
        return 1
    print("Live2D web assets are in sync.")
    return 0


def sync_assets() -> int:
    if not SOURCE.exists():
        print(f"Missing source directory: {SOURCE.relative_to(ROOT)}")
        return 1
    TARGET.mkdir(parents=True, exist_ok=True)
    source_rels = {path.relative_to(SOURCE) for path in iter_files(SOURCE)}
    for target_file in iter_files(TARGET):
        rel = target_file.relative_to(TARGET)
        if rel not in source_rels:
            target_file.unlink()
    for source_file in iter_files(SOURCE):
        rel = source_file.relative_to(SOURCE)
        target_file = TARGET / rel
        target_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_file, target_file)
    print(f"Synced {SOURCE.relative_to(ROOT)} -> {TARGET.relative_to(ROOT)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync Tianmiao Live2D assets into the web preview.")
    parser.add_argument("--check", action="store_true", help="Only verify that web assets match app assets.")
    args = parser.parse_args()
    if args.check:
        return check_sync()
    return sync_assets()


if __name__ == "__main__":
    raise SystemExit(main())
