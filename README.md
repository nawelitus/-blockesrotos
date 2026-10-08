# BlockesRotos

A block puzzle game for Android, built with Godot 4. Drag pieces onto an 8x8 grid, complete
rows and columns to clear them and chain combos. The game ends when none of the three offered
pieces fits.

- Classic mode, no timer. Pieces get harder as the score rises
- Three switchable skins: wood, colorful, neon. Blocks are drawn in each skin's own style
- Sounds are synthesized in code, light vibration, both can be turned off
- Offline, no ads, no tracking. The only permission is vibration
- UI text is in Spanish

Package id: `com.blockesrotos.game`. See `docs/DESIGN.md` for the rules and scoring.

## Requirements

- [Godot](https://godotengine.org) 4.7.2 (standard build) and its export templates
- JDK 17 and the Android SDK (platform 36, build-tools 36.1.0)
- Python 3 (only to regenerate `icon.svg`)

## Run the tests

They run headless and print a summary:

```
godot --headless --path . --import --quit
godot --headless --path . --quit-after 900 -s tools/test_core.gd
godot --headless --path . --quit-after 900 -s tools/test_sound.gd
```

## Build for Android

Debug APK (preset `Android`, signed with Godot's debug keystore):

```
godot --headless --path . --export-debug "Android" build/blockesrotos-debug.apk
```

Release bundle for Google Play (preset `Android Release`):

1. Install the Gradle build template once: extract `android_source.zip` from the export
   templates folder into `android/build/`, write `4.7.2.stable` into `android/.build_version`
   and add an empty `android/build/.gdignore`. The `android/` folder is not tracked.
2. Create an upload keystore and keep it, and its password, outside the repository.
3. Export it. The signing key is read from environment variables, never from the preset:

```
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=<path to .jks>
GODOT_ANDROID_KEYSTORE_RELEASE_USER=<key alias>
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<password>
godot --headless --path . --export-release "Android Release" build/blockesrotos-release.aab
```

## Store graphics

```
python -I tools/make_icon.py icon.svg
godot --path . --resolution 360x640 --rendering-driver opengl3 res://tools/store_render.tscn
```

`tools/shot.gd` plays through the real input path and saves a screenshot, which is handy to
check a visual change without a device.

## Project layout

| Path | Contents |
|---|---|
| `scripts/` | game code: board state, pieces, scoring, generator, UI, skins, audio |
| `skins/` | the three `GameSkin` resources |
| `tools/` | headless tests, screenshot and store graphics renderers, icon generator |
| `store/` | Google Play listing text, answers and graphics |
| `docs/` | design notes and static pages (privacy policy) |

## Licences

- The game is made with Godot Engine (MIT). Its licence and those of its components are
  shown inside the app under "Créditos y licencias".
- The game's own code, graphics and name are all rights reserved. See `LICENSE`.
