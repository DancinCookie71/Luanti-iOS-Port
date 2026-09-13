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

## Two builds: `lua` and `luajit`

**There are TWO different types of `.ipa`** available. They are identical except
for the Lua engine embedded in the client:

| | `luanti-ios-lua.ipa` | `luanti-ios-luajit.ipa` |
|---|---|---|
| Lua engine | bundled PUC Lua 5.1 | LuaJIT 2.1 |
| Compatibility | runs everywhere | runs everywhere |
| Speed | baseline | usually **~2–4× faster** Lua |
| Best for | simplest / maximum compatibility | heavier mods and games |

- **Use `lua`** if you just want it to work — it runs fine, but may be slower
  with heavier mods (lots of Lua per tick).
- **Use `luajit`** if you play Lua-heavy games/mods. Despite the name it does
  **not** require anything special on iOS — it uses LuaJIT's **interpreter**.

> **About "JIT":** LuaJIT's *tracing JIT compiler* needs writable **and**
> executable memory, which iOS forbids for normal apps. Upstream LuaJIT
> therefore hard-disables the JIT on iOS (`LJ_OS_NOJIT`), so the `luajit` build
> here is LuaJIT's (still quite fast) interpreter, **not** the JIT. Getting the
> real JIT would require a patched LuaJIT plus a JIT-enabled launch (a JIT
> enabler such as StikDebug/JITStreamer, or a jailbreak) — that is experimental
> and is not shipped here. The client logs which mode it ended up in at startup:
> `LuaJIT: JIT compiler is enabled / unavailable (running interpreted)`.

## Known limitations

- **No sound** (OpenAL is not built yet)
- **No tracing JIT** — the `luajit` build uses LuaJIT's interpreter (see above);
  Lua-heavy games are still slower than on desktop
- Touch controls are not yet tuned for iOS
- Keyboard can slightly nudge the view on some screens
- `gettext` (translations), LevelDB/Redis/PostgreSQL backends disabled
- Sideloaded apps from a free Apple ID expire after 7 days (re-sign/reinstall) [Apple Limitation - We can't and never will be able to fix this]

## Download

Grab either build from the **Actions** tab of the newest successful run:

- `luanti-ios-lua` — bundled Lua 5.1
- `luanti-ios-luajit` — LuaJIT

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
FLAVOR=lua    ./scripts/build-ios.sh   # -> luanti-ios-lua.ipa
FLAVOR=luajit ./scripts/build-ios.sh   # -> luanti-ios-luajit.ipa
```

The script clones Luanti at the pinned tag, applies `patches/luanti-ios.patch`,
builds the iOS dependencies with vcpkg (using the SDL2 overlay in
`vcpkg-overlay/`), configures CMake for `arm64-ios`, builds, and packages the
`.ipa`. For `FLAVOR=luajit` it additionally builds LuaJIT for iOS
(`scripts/build-luajit-ios.sh`) and links it in.

The included [GitHub Actions workflow](.github/workflows/build-ios.yml) builds
**both** flavors on every push and uploads both `.ipa`s as artifacts.

To target the Simulator instead (bundled-Lua flavor):

```sh
TRIPLET=arm64-ios-simulator SYSROOT=iphonesimulator FLAVOR=lua ./scripts/build-ios.sh
```

## Repository layout

```
patches/luanti-ios.patch       # all engine/iOS changes (applies to luanti 5.17.0)
vcpkg-overlay/sdl2/            # patched SDL2 (UIScene lifecycle for iOS 26/27)
scripts/build-ios.sh           # end-to-end build (FLAVOR=lua|luajit)
scripts/build-luajit-ios.sh    # builds LuaJIT for iOS
scripts/make_ipa.sh            # .app -> unsigned .ipa
scripts/gen_ios_gl_compat.sh   # regenerates the GL enum header
.github/workflows/             # CI (both flavors)
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
