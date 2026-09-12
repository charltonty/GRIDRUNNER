# GRIDRUNNER — Ghost Signal

Native Godot project for the GRIDRUNNER vertical slice. The project now lives directly at the repository root; the retired JavaScript/browser port is intentionally not kept on this branch.

**Engine baseline: Godot 4.4.1 stable using the Compatibility renderer.** Use this version unless an engine upgrade is being made as a deliberate, separately reviewed change.

**Latest upgrade: all five supplied GRIDRUNNER packs integrated.** See `ASSET_INTEGRATION.md` for the new buildings, interactions, validation and limitations. The Creek Service milestone below is preserved.

**Latest milestone: VS02 / Creek Service polish.** Read `POLISH_MILESTONE.md` for the new HUD, surface audio, authored service loop, SCOUT trial and controls. `POLISH_VALIDATION.md` records the current checks; the older documents below describe the preserved VS02 foundation.

Complete Godot source project, built directly on the supplied Vertical Slice 01 milestone. PC keyboard/mouse.

## Play

1. Clone the repository and check out this branch into a clean folder.
2. In Godot's Project Manager, import `project.godot` from the repository root.
3. Allow the asset import to finish. Press F5.
4. New Expedition → Standard starts at Black Creek camp.

The repository contains source and assets, not a Windows executable. No asset accounts are needed to play from Godot. Existing native VS01 saves are accepted and gain empty VS02 storage/progression fields. Back up any valued save before testing a milestone.

## Develop and validate

Run these commands from the repository root with Godot 4.4.1 on your `PATH`:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/native_smoke.gd
godot --headless --path . --script tests/vertical_slice_02.gd
godot --headless --path . --script tests/polish_regression.gd
godot --headless --path . --script tests/asset_integration_regression.gd
```

The repository-root cleanup was validated on Windows with Godot 4.4.1: **211 assertions passed with zero failures** across the four suites.

Read `CONTRIBUTING.md` before changing engine versions, moving resources, or committing imported assets.

## Controls

| Control | Action |
|---|---|
| WASD / mouse | Move or steer / look |
| Shift on foot | Sprint |
| Space on foot | Jump; hold does not auto-repeat |
| Ctrl on foot | Crouch; blocked ceiling prevents standing |
| E | Nearby interaction or physical pickup |
| F | Mount / dismount nearby bike |
| Space on bike / P | Brake / pedal |
| Backspace | Recover stuck bike to road |
| I | Backpack, inspection and accessible storage tabs |
| B | SCOUT-01 equipment bay |
| Q | Launch / recall drone |
| Space / Shift in drone | Ascend / descend |
| R | Scan; requires scanner module in drone mode |
| L | Toggle equipped drone spotlight |
| X | Marker designation / equipped utility action |
| 1 / 2 / 3 | Drone follow / hold / return |
| H | Cycle separate walking, bike or drone camera profiles |
| G / T | Power trailer controls / transfer reserve to bike |
| M | Route / discoveries |
| F5 / Escape | Save / pause |

Reduced motion is in the expedition pause menu. It disables the new landing camera response. All dialogue is text. Audio volume is adjustable.

## Opening route

Meet Mara → inspect Backpack → gather camp supplies → configure SCOUT-01 near the bike → launch/scan → recall → transfer supplies → ride toward Milepost Repair → stop at the service cabinet near x12, z−180 → investigate the carrier → stranded EV → solar storage → substation relay → Ghost Signal tower.

The opening tasks guide rather than lock the player into a sequence. The complete original three-leg campaign remains available. The new service-cabinet carrier is an early hook; the original tower remains the chapter transition.

See `WORK_COMPLETED.md`, `TEST_RESULTS.md`, `ASSET_CREDITS.md`, and the actual engine screenshots and icon sheets in `docs/` for scope, validation and remaining work.
