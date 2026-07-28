#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_DIR="${QA_EVIDENCE_DIR:-}"
MIN_DURATION="${QA_MIN_DURATION:-9.8}"
ACTIONS=(idle walk click drag jump sleep wake roll groom scratch)

if [ -z "$EVIDENCE_DIR" ] || [ ! -d "$EVIDENCE_DIR" ]; then
  echo "QA_EVIDENCE_DIR must point to the reviewed v3.22 recording directory." >&2
  exit 1
fi
if ! command -v ffprobe >/dev/null 2>&1; then
  echo "ffprobe is required to verify visual release evidence." >&2
  exit 1
fi

for action in "${ACTIONS[@]}"; do
  video="$EVIDENCE_DIR/v3.22-${action}.mp4"
  if [ ! -s "$video" ]; then
    echo "Missing visual evidence: $video" >&2
    exit 1
  fi
  duration="$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$video")"
  awk -v duration="$duration" -v minimum="$MIN_DURATION" \
    'BEGIN { exit !(duration + 0 >= minimum + 0) }' || {
      echo "$video is only ${duration}s; at least ${MIN_DURATION}s is required." >&2
      exit 1
    }
  dimensions="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=s=x:p=0 "$video")"
  if [ -z "$dimensions" ]; then
    echo "No video stream found in $video." >&2
    exit 1
  fi
  printf 'verified %-8s %7ss %s\n' "$action" "$duration" "$dimensions"
done

python3 "$ROOT_DIR/scripts/verify_pose_assets.py"
echo "Visual QA evidence gate passed."
