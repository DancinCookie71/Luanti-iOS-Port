#!/usr/bin/env bash
#
# Sets an app icon (and optionally display name / bundle id) on a built .app.
#
# Usage: apply_icon.sh <App.app> <icon.png> [display_name] [bundle_id]
# The icon should be at least 1024x1024, square PNG.
#
set -euo pipefail

APP="${1:?usage: apply_icon.sh <App.app> <icon.png> [display_name] [bundle_id]}"
ICON="${2:?need a source icon png}"
NAME="${3:-}"
BUNDLE_ID="${4:-}"
PLIST="$APP/Info.plist"
PB=/usr/libexec/PlistBuddy

if [ ! -f "$ICON" ]; then
	echo "error: icon not found: $ICON" >&2
	exit 1
fi

gen() { sips -z "$1" "$1" "$ICON" --out "$APP/$2" >/dev/null; }

gen 40   "AppIcon-20@2x.png"
gen 60   "AppIcon-20@3x.png"
gen 58   "AppIcon-29@2x.png"
gen 87   "AppIcon-29@3x.png"
gen 80   "AppIcon-40@2x.png"
gen 120  "AppIcon-40@3x.png"
gen 120  "AppIcon-60@2x.png"
gen 180  "AppIcon-60@3x.png"
gen 152  "AppIcon-76@2x.png"
gen 167  "AppIcon-83.5@2x.png"
gen 1024 "AppIcon-1024.png"
# Some installers look for this
gen 1024 "iTunesArtwork"
cp "$ICON" "$APP/iTunesArtwork" 2>/dev/null || true
rm -f "$APP/iTunesArtwork" 2>/dev/null || true
gen 1024 "iTunesArtwork"

# Primary icon set
$PB -c "Delete :CFBundleIcons" "$PLIST" 2>/dev/null || true
$PB -c "Add :CFBundleIcons dict" "$PLIST"
$PB -c "Add :CFBundleIcons:CFBundlePrimaryIcon dict" "$PLIST"
$PB -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$PLIST"
for n in AppIcon-20 AppIcon-29 AppIcon-40 AppIcon-60 AppIcon-76 AppIcon-83.5; do
	$PB -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles: string $n" "$PLIST"
done

# Legacy icon list
$PB -c "Delete :CFBundleIconFiles" "$PLIST" 2>/dev/null || true
$PB -c "Add :CFBundleIconFiles array" "$PLIST"
$PB -c "Add :CFBundleIconFiles: string AppIcon-60" "$PLIST"

if [ -n "$NAME" ]; then
	$PB -c "Set :CFBundleDisplayName $NAME" "$PLIST" 2>/dev/null || \
		$PB -c "Add :CFBundleDisplayName string $NAME" "$PLIST"
	$PB -c "Set :CFBundleName $NAME" "$PLIST" 2>/dev/null || \
		$PB -c "Add :CFBundleName string $NAME" "$PLIST"
fi
if [ -n "$BUNDLE_ID" ]; then
	$PB -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST"
fi

echo "Applied icon $(basename "$ICON") to $(basename "$APP")${NAME:+ (name: $NAME)}"
