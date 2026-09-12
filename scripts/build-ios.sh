#!/usr/bin/env bash
#
# Builds an unsigned Luanti iOS .ipa (device, arm64).
# Requires: Xcode (with an iOS SDK), cmake, ninja, pkg-config, git.
#
# Usage:  ./scripts/build-ios.sh
# Env:    LUANTI_TAG, VCPKG_COMMIT, TRIPLET, WORK, OUT
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

LUANTI_TAG="${LUANTI_TAG:-5.17.0}"
VCPKG_COMMIT="${VCPKG_COMMIT:-a1cae005c39be7b18ba319fced856b68d7276271}"
TRIPLET="${TRIPLET:-arm64-ios}"
SYSROOT="${SYSROOT:-iphoneos}"
WORK="${WORK:-$ROOT/work}"
BUILD="$WORK/build-$TRIPLET"
OUT="${OUT:-$ROOT/luanti-ios-unsigned.ipa}"

mkdir -p "$WORK"

if ! xcodebuild -version >/dev/null 2>&1; then
	echo "error: Xcode is required (xcode-select -s /Applications/Xcode.app)" >&2
	exit 1
fi

# --- Luanti source -----------------------------------------------------------
if [ ! -d "$WORK/luanti/.git" ]; then
	git clone --depth 1 --branch "$LUANTI_TAG" \
		https://github.com/luanti-org/luanti.git "$WORK/luanti"
fi
if git -C "$WORK/luanti" apply --check "$ROOT/patches/luanti-ios.patch" >/dev/null 2>&1; then
	git -C "$WORK/luanti" apply "$ROOT/patches/luanti-ios.patch"
	echo "Applied patches/luanti-ios.patch"
else
	echo "Patch already applied, continuing."
fi

# --- vcpkg -------------------------------------------------------------------
if [ ! -d "$WORK/vcpkg/.git" ]; then
	git clone https://github.com/microsoft/vcpkg.git "$WORK/vcpkg"
fi
git -C "$WORK/vcpkg" checkout -q "$VCPKG_COMMIT"
"$WORK/vcpkg/bootstrap-vcpkg.sh" -disableMetrics

"$WORK/vcpkg/vcpkg" install \
	sdl2 zlib zstd sqlite3 freetype libjpeg-turbo libpng curl \
	--triplet "$TRIPLET" \
	--overlay-ports="$ROOT/vcpkg-overlay"

# --- Configure & build -------------------------------------------------------
cmake -G Ninja -S "$WORK/luanti" -B "$BUILD" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_SYSTEM_NAME=iOS \
	-DCMAKE_OSX_SYSROOT="$SYSROOT" \
	-DCMAKE_OSX_ARCHITECTURES=arm64 \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
	-DCMAKE_TOOLCHAIN_FILE="$WORK/vcpkg/scripts/buildsystems/vcpkg.cmake" \
	-DVCPKG_TARGET_TRIPLET="$TRIPLET" \
	-DVCPKG_MANIFEST_MODE=OFF \
	-DBUILD_CLIENT=TRUE -DBUILD_SERVER=FALSE \
	-DBUILD_UNITTESTS=FALSE -DBUILD_BENCHMARKS=FALSE -DBUILD_DOCUMENTATION=FALSE \
	-DENABLE_GETTEXT=FALSE -DENABLE_CURL=TRUE -DENABLE_SOUND=FALSE \
	-DENABLE_OPENSSL=TRUE -DENABLE_POSTGRESQL=FALSE -DENABLE_LEVELDB=FALSE \
	-DENABLE_REDIS=FALSE -DENABLE_SPATIAL=FALSE -DENABLE_CURSES=FALSE \
	-DENABLE_PROMETHEUS=FALSE -DENABLE_SYSTEM_GMP=FALSE \
	-DENABLE_SYSTEM_JSONCPP=FALSE -DENABLE_LTO=FALSE -DRUN_IN_PLACE=FALSE

ninja -C "$BUILD"

# --- Package -----------------------------------------------------------------
"$ROOT/scripts/make_ipa.sh" "$BUILD/bin/luanti.app" "$OUT"
