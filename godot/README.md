# GRIDRUNNER — VS02 Asset Integration

**Latest upgrade: all five supplied GRIDRUNNER packs integrated.** See `ASSET_INTEGRATION.md` for the new buildings, interactions, validation and limitations. The Creek Service milestone below is preserved.

**Latest milestone: VS02 / Creek Service polish.** Read `POLISH_MILESTONE.md` for the new HUD, surface audio, authored service loop, SCOUT trial and controls. `POLISH_VALIDATION.md` records the current checks; the older documents below describe the preserved VS02 foundation.

Complete Godot source project, built directly on the supplied Vertical Slice 01 milestone. PC keyboard/mouse. Tested with Godot 4.4.1 stable, Compatibility renderer.

## Play

1. Extract this entire ZIP into a new folder. Do not overlay an older project.
2. In Godot, Import `GRIDRUNNER-Godot/project.godot`.
3. Allow the asset import to finish. Press F5.
4. New Expedition → Standard starts at Black Creek camp.

The ZIP contains source and assets, not a Windows executable. No downloads or asset accounts are needed to play from Godot. Existing native VS01 saves are accepted and gain empty VS02 storage/progression fields. Native saves are separate from browser saves. Back up any valued save before testing a milestone.

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
