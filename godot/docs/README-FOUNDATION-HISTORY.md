# GRIDRUNNER — Playable Native Foundation

## Current build

The native scene now includes an adapted three-leg campaign, bike and foot movement, physical drone flight, settlements/residents, salvage and mining, crafting/barter, trailer cargo, finite energy, native save/Continue and synthesized motor/UI audio. The browser game is unchanged. This is an editable Godot foundation, not full browser-feature or visual parity, and not an exported Windows executable.

Use **Godot 4.5.1** (the validation engine). Import `project.godot` from the ZIP, or `godot/project.godot` from this repository. Press **F5**, then New Expedition. The project uses Compatibility rendering.

### Active controls

| Key | Action |
| --- | --- |
| WASD / mouse | Movement and look; A/D steer bike |
| F / P | Mount or dismount nearby bike / pedal |
| Q | Launch or recall drone |
| Space / Shift | Drone ascend / descend |
| 1 / 2 / 3 | Follow / hold / return and dock |
| R / E | Scan / interact |
| H | Cycle viewpoint for current activity |
| I / G / M | Inventory / power / route list |
| T / F5 / Escape | Transfer reserve energy / save / menu |

### Architecture

`project.godot` registers `systems/session.gd` as Session and opens `scenes/frontend.tscn`. `scripts/frontend.gd` initializes or loads state, then opens `scenes/main.tscn`. Its `scripts/expedition.gd` builds the world and coordinates physics, vehicles, camera, interactions, audio, HUD and missions. Menus suspend its simulation. `data/port/content.json` contains browser-derived items, recipes, seeded loot, settlements, residents, mission sites and camera profiles. Old standalone controller scripts and design documents remain as reference; they are not simultaneously active.

Session owns atomic inventory transactions and validated save state. Native saves use `user://gridrunner_native.json`, with temporary-file replacement, manual saving and a 60-second autosave. Positions, depleted loot, tags, mission flags and view indices persist. Loading safely docks the drone. Browser saves are untouched; importing them is not implemented. There is one native save slot.

To add a mission, add a site to the world/content, a guarded transition in `mission()` and a test. A new Leg also needs spawn/bounds, chapter transitions and a wider validated Leg range. Drone abilities currently live in `update_drone`, `command_drone` and `scan`; extract a dedicated controller/class registry before adding multiple aircraft classes. Mesh helpers generate art; there are no production external models/textures. Generated WAV loops/tones provide audio, ready for replacement with licensed assets and positional players.

### Validation and limits

Run `godot --headless --path . --script res://tests/native_smoke.gd --quit-after 1000` from this directory. **The test writes a native test save**; back up your own save first. Tests exercise native movement/flight input, energy, transactions, saves and mission transitions; they do not constitute a complete human route playthrough or visual/audio QA.

Remaining work: production terrain/art and NPC animation; combat/threat systems; obstruction-aware signal and obstacle-avoiding return flight; full spatial sound/music; graphical map (currently a route list); graphics presets; keyboard rebinding, controller and touch controls; browser save import. Some charging and campaign interactions are simplified. Settings are partial and volume is session-only. See `CHANGELOG-NATIVE.md` for validation details.

---

## Original scaffold notes (historical)

Experimental Godot 4 branch. The existing web build in `dist/` remains the reference implementation and is intentionally untouched.

## Goal
Prove the core GRIDRUNNER loop in a native game engine before migrating Ghost Signal Legs 1–3.

Core architecture being established:
- first-person traversal
- electric bike and trailer
- generalized kW/kWh energy simulation
- rare fuel / high-value generator energy
- solar, water and recovered-grid inputs
- physical scout drone with battery, signal and scanning
- scavenging, inventory and persistent world state
- save/load and settings

## Open on PC
1. Install Godot 4.x.
2. Clone or download the `godot-prototype` branch.
3. In Godot Project Manager choose **Import**.
4. Select `godot/project.godot`.
5. Open the project and press F6/F5.

The original scaffold controls below have been superseded by the active controls above.

## Design rule
The browser version is an executable design reference, not code that must be preserved. Rebuild systems cleanly for Godot while preserving GRIDRUNNER gameplay, world identity, Ghost Signal content and player-facing behavior.

## Energy model
All sources and consumers should ultimately use a common model:

`source -> converter -> power bus -> storage -> consumer`

Power is kW. Stored/consumed energy is kWh. Fuel is deliberately scarce but should produce a major energy windfall when found. Solar is slow/renewable; water is location-dependent/continuous; recovered grid energy is powerful but requires access and repair.
