# Cricket Championship 3D

A mobile-friendly cricket prototype built with Godot 4. It includes a procedural stadium, simple player/umpire visuals, a score HUD, Hindi/English text commentary, and test controls for ball outcomes.

## Important scope note
This is a **prototype**, not yet a photorealistic 3D cricket game. The current scene uses procedural 2D/2.5D drawings so the first build can be tested without licensed models or large downloads. The next development phase is to replace these with licensed 3D player/stadium assets and real 3D gameplay.

## Controls
- `1`: Dot ball
- `2`: Single
- `3`: Double
- `4`: Four
- `5`: Six
- `6`: Wicket
- `H`: Hindi commentary
- `E`: English commentary
- `C`: toggle cinematic label
- `R`: reset match

On touch devices, tap the lower control zone to trigger test outcomes and tap the right side of the top HUD to toggle cinematic mode. These are prototype/testing controls, not final batting/bowling controls.

## Build
Open with Godot 4.3+ and install matching export templates. Configure Android export once in Godot, then use the workflow in `.github/workflows/android-build.yml`. The workflow expects the Android export preset `Android` to be configured in `export_presets.cfg`. Do not commit signing keys or passwords.

## Planned milestones
1. Stable prototype and score-rule tests.
2. Proper 3D stadium, player rigs and animations.
3. Batting/bowling/fielding gameplay and ball physics.
4. Commentary event library and optional speech.
5. Mobile controls, performance profiles, QA and release builds.

Team names and trademarks belong to their respective owners. Use licensed assets for official logos, player likenesses, and audio.
