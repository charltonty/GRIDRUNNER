# Native Godot foundation — 2026-09-08

## Completed in this migration pass

- Kept the original Godot scaffold and browser implementation; wired the frontend to a native playable expedition scene.
- Added walking/bike/drone modes, physical collisions, bike power consumption, pedaling, trailer presentation and separate camera profiles.
- Added drone inertia, climb/descent, battery, distance-based signal, damage, scan tags, follow, hold and return/docking. Autonomous commands restore the pilot's previous foot/bike mode.
- Imported browser content into a self-contained JSON dataset: items, recipes, seeded resources, settlements, residents and Leg 2/3 sites.
- Built procedural roads, power infrastructure, buildings and resident representations for the active Leg. Added salvage, timed mining, capacity-aware transactions, crafting, limited barter and cargo transfer.
- Added finite generator fuel, reserve energy, solar generation and transfers. Full storage conserves fuel.
- Implemented adapted relay/tower, waterworks/breaker and antenna/capacitor/core campaign paths, chapter transitions and ending choices.
- Added technical HUD, inventory/power/discovery menus, manual and periodic saves, Continue, native validation and safe drone recovery on load.
- Added synthesized vehicle and UI sound, volume control and frontend start variants.
- Documented active controls, extension points and incomplete parity in README.

## Validation

Godot 4.5.1 Linux headless editor import succeeded. `tests/native_smoke.gd` completed with **25 passing checks and zero failures**. This includes physical keyboard bike acceleration and drone ascent/descent, launch/follow/hold/docking, scanning, camera preferences, inventory atomicity, generator rates, save/reload, malformed-save rejection and fixture-driven progression through all three Legs to the restore ending.

The descent check allows time for the drone's upward inertia to reverse. Mission tests call the native interaction functions and emit menu-button signals; they do not physically ride the entire route. Native frontend startup is also checked separately. Verbose engine shutdown may report an unclaimed `Master` StringName and platform controller-mapping diagnostics; the smoke run has no script errors or ObjectDB leak warning.

## Still requiring PC playtest / further porting

Visual framing and collision feel, audible mixing, full manual campaign route and the alternate ending need human playtesting. Production graphics/assets, combat, full spatial ambience/music, graphical map, mobile/controller/rebinding support, graphics presets, obstruction-aware drone signal/pathfinding and browser-save migration are not complete. Do not describe this as a full v7.4-equivalent release.

The live browser branch and Pages deployment are intentionally unchanged.
