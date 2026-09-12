#!/usr/bin/env bash
# Package a built .app bundle into an unsigned .ipa (Payload/<name>.app).
# The result can be signed/installed with any on-device signing tool,
# AltStore, Sideloadly, TrollStore, etc.
set -euo pipefail

APP="${1:?usage: make_ipa.sh <path/to/App.app> [output.ipa]}"
OUT="${2:-$(pwd)/$(basename "${APP%.app}").ipa}"

if [ ! -d "$APP" ]; then
	echo "error: $APP is not a directory" >&2
	exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/Payload"
# ditto preserves symlinks, permissions and resource forks correctly
ditto "$APP" "$WORK/Payload/$(basename "$APP")"

rm -f "$OUT"
( cd "$WORK" && zip -qry "$OUT" Payload )

echo "wrote: $OUT"
unzip -l "$OUT" | head -8
