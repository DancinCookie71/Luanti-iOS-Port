#!/usr/bin/env bash
#
# Builds LuaJIT as a static library for iOS (arm64 device).
#
# Note: upstream LuaJIT disables its JIT compiler on iOS (LJ_OS_NOJIT in
# lj_arch.h) because iOS forbids writable+executable memory. This build is
# therefore LuaJIT's (faster) interpreter, not the tracing JIT.
#
# Output: $WORK/luajit-ios/{lib/libluajit.a,include/*.h}
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/work}"
LUAJIT_REPO="${LUAJIT_REPO:-https://github.com/LuaJIT/LuaJIT.git}"
LUAJIT_REF="${LUAJIT_REF:-v2.1}"
SRC="$WORK/luajit-src"
OUT="${LUAJIT_OUT:-$WORK/luajit-ios}"

if [ ! -d "$SRC/.git" ]; then
	git clone --depth 1 --branch "$LUAJIT_REF" "$LUAJIT_REPO" "$SRC"
fi

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos --find clang)"
AR="$(xcrun --sdk iphoneos --find ar)"
STRIP="$(xcrun --sdk iphoneos --find strip)"

make -C "$SRC" TARGET_SYS=iOS clean >/dev/null 2>&1 || true
make -C "$SRC" TARGET_SYS=iOS BUILDMODE=static \
	HOST_CC=clang \
	CC="$CLANG -arch arm64 -isysroot $SDK -miphoneos-version-min=15.0" \
	TARGET_AR="$AR rcus" \
	TARGET_STRIP="$STRIP -x" \
	-j"$(sysctl -n hw.ncpu)"

rm -rf "$OUT"
mkdir -p "$OUT/lib" "$OUT/include"
cp "$SRC/src/libluajit.a" "$OUT/lib/"
for h in lua.h luajit.h lauxlib.h lualib.h lua.hpp; do
	[ -f "$SRC/src/$h" ] && cp "$SRC/src/$h" "$OUT/include/"
done

echo "LuaJIT built at $OUT"
