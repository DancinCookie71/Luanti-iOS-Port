# Luanti for iOS (experimental)

An unofficial iOS port of [Luanti](https://www.luanti.org/) (formerly Minetest),
packaged as an **unsigned `.ipa`** you can sign yourself and sideload.

> Status: **experimental, source-only / sideload only.** This is not an
> official Luanti project and is not on the App Store. Expect rough edges.

## What works

- Full client boots to the main menu on iPhone (tested on iPhone 15 / A16)
- Menu, text rendering, opaque/alpha textures, GUI scaling
- Landscape orientation (locked, matching Android)
- Public server list, ContentDB and the update checker (cURL + OpenSSL)
- Native text-input dialog for menu fields and chat (like Android)
- Joins and plays on servers

## Known limitations

- **No sound** (OpenAL is not built yet)
- **No LuaJIT** — bundled Lua 5.1 interpreter (iOS forbids JIT), so Lua-heavy
  games are slower
- Touch controls are not yet tuned for iOS
- Keyboard can slightly nudge the view on some screens
- `gettext` (translations), LevelDB/Redis/PostgreSQL backends disabled
- Sideloaded apps from a free Apple ID expire after 7 days (re-sign/reinstall)

## Download

Grab the latest `luanti-ios-unsigned.ipa` from the **Actions** tab (the
`luanti-ios-unsigned` artifact of the newest successful run), or from the
Releases page if one exists.

## Installing (no Apple account needed to *build*)

The `.ipa` is **unsigned**. Sign it with whatever you already use:

- **TrollStore** — installs unsigned apps directly (specific iOS versions)
- **ESign / Feather** — on-device signers
- **AltStore / Sideloadly** — sign locally with any (even free) Apple ID; note
  the 7-day expiry with a free account

Do **not** redistribute an `.ipa` signed with someone else's certificate.

## Building

Requirements: macOS with Xcode (and the iOS SDK), `cmake`, `ninja`,
`pkg-config`, `git`, and network access.

```sh
./scripts/build-ios.sh
# -> luanti-ios-unsigned.ipa
```

The script clones Luanti at the pinned tag, applies `patches/luanti-ios.patch`,
builds the iOS dependencies with vcpkg (using the SDL2 overlay in
`vcpkg-overlay/`), configures CMake for `arm64-ios`, builds, and packages the
`.ipa`.

The included [GitHub Actions workflow](.github/workflows/build-ios.yml) does the
same on every push and uploads the `.ipa` as an artifact.

To target the Simulator instead:

```sh
TRIPLET=arm64-ios-simulator SYSROOT=iphonesimulator ./scripts/build-ios.sh
```

## Repository layout

```
patches/luanti-ios.patch   # all engine/iOS changes (applies to luanti 5.17.0)
vcpkg-overlay/sdl2/        # patched SDL2 (UIScene lifecycle for iOS 26/27)
scripts/build-ios.sh       # end-to-end build
scripts/make_ipa.sh        # .app -> unsigned .ipa
scripts/gen_ios_gl_compat.sh  # regenerates the GL enum header
.github/workflows/         # CI
```

## Notable technical fixes

These are the non-obvious things that were needed to make it run (see the patch
for details):

- **SDL2 UIScene lifecycle** — iOS 26 warns, iOS 27 hard-traps apps that don't
  adopt `UIScene`. SDL2 doesn't, so the overlay adds a minimal scene delegate
  and attaches the window to the scene (`vcpkg-overlay/sdl2/scene-lifecycle.patch`).
- **ES2 texture correctness** — NPOT textures must use `GL_CLAMP_TO_EDGE`;
  `GL_APPLE_texture_format_BGRA8888` rejects `GL_BGRA` as an *internal* format;
  failed `glGenerateMipmap` must disable mipmaps.
- **Fonts** — Irrlicht draws glyphs with `glDrawRangeElements`, which does not
  exist in OpenGL ES 2; use `glDrawElements` there.
- **Screen framebuffer** — the driver rendered to framebuffer 0; on iOS that is
  not the EAGL drawable, so it now uses SDL's framebuffer.
- **Orientation** — SDL allows all orientations for resizable windows, so both
  the Info.plist and `SDL_HINT_ORIENTATIONS` are needed to stay landscape.
- **Native input dialog** — menu text fields and chat use a real iOS dialog
  above the keyboard instead of SDL's hidden field.

## License and credits

The Luanti engine and this patch set are licensed under
**LGPL-2.1-or-later**. Luanti is © the Luanti team and contributors; this repo
only contains the porting changes and build tooling. SDL2 is zlib-licensed.

If you distribute a binary built from this, you must also make the corresponding
source available (this repository, plus upstream Luanti).

## Contributing

Issues and PRs welcome. The engine fixes that are not iOS-specific (ES2 texture
and `glDrawRangeElements` correctness) are good candidates for upstreaming to
Luanti; the SDL2 scene patch is useful to anyone building SDL2 for current iOS.
