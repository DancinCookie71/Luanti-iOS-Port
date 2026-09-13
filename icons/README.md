# App icons

Drop a square PNG here (1024×1024 works best) for each build flavor:

- `lua.png` — used by `FLAVOR=lua` (no lightning bolt)
- `luajit.png` — used by `FLAVOR=luajit` (with lightning bolt)

`scripts/build-ios.sh` picks the matching file automatically and generates the
sizes iOS needs, then sets the icon, display name and bundle id:

| flavor | display name | bundle id |
|---|---|---|
| `lua` | Luanti | `org.luanti.luanti` |
| `luajit` | Luanti JIT | `org.luanti.luanti.luajit` |

(Different bundle ids so both can be installed side by side. Override with
`DISPLAY_NAME=…` / `BUNDLE_ID=…` when building.)
