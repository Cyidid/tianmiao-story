#!/usr/bin/env bash
set -euo pipefail

DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
  echo "DEVELOPER_ID_APPLICATION is required for a formal release." >&2
  exit 1
fi
if [ -z "$NOTARY_PROFILE" ]; then
  echo "NOTARY_PROFILE is required for a formal release." >&2
  exit 1
fi

if ! security find-identity -v -p codesigning |
     grep -F "Developer ID Application:" |
     grep -Fq "$DEVELOPER_ID_APPLICATION"; then
  echo "Developer ID Application identity is unavailable: $DEVELOPER_ID_APPLICATION" >&2
  exit 1
fi

if ! xcrun notarytool history \
     --keychain-profile "$NOTARY_PROFILE" \
     --output-format json >/dev/null 2>&1; then
  echo "Notary credentials are unavailable for profile: $NOTARY_PROFILE" >&2
  exit 1
fi

echo "Developer ID and notary credentials are available."
