# GRIDRUNNER — Godot Migration Prototype

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

Current controls: WASD move, mouse look, Shift sprint, Space jump, Esc releases mouse.

## Design rule
The browser version is an executable design reference, not code that must be preserved. Rebuild systems cleanly for Godot while preserving GRIDRUNNER gameplay, world identity, Ghost Signal content and player-facing behavior.

## Energy model
All sources and consumers should ultimately use a common model:

`source -> converter -> power bus -> storage -> consumer`

Power is kW. Stored/consumed energy is kWh. Fuel is deliberately scarce but should produce a major energy windfall when found. Solar is slow/renewable; water is location-dependent/continuous; recovered grid energy is powerful but requires access and repair.
