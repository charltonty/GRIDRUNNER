# Validation — Vertical Slice 02

Engine: **Godot 4.4.1 stable**, Linux. Headless physics/gameplay testing plus actual OpenGL Compatibility renders under Mesa llvmpipe. Windows binaries and hardware-GPU performance were not tested.

## Repository-root cleanup validation

On 2026-09-11, the promoted repository-root project was imported and tested with the official Godot 4.4.1 Windows build:

- `tests/native_smoke.gd`: **38 passed, 0 failures**.
- `tests/vertical_slice_02.gd`: **41 passed, 0 failures**.
- `tests/polish_regression.gd`: **96 passed, 0 failures**.
- `tests/asset_integration_regression.gd`: **36 passed, 0 failures**.
- `tests/performance_regression.gd`: **4 passed, 0 failures**.
- Total: **215 passed, 0 failures**.

Headless GLB import emitted the previously documented dummy-renderer texture warnings. The full import and all five suites exited successfully.

## Static-world performance validation

On 2026-09-11, the Godot 4.4.1 Windows build reported 552 distance-culled static render cells, 194 local MultiMesh chunks and 1,041 of 1,330 geometry instances with explicit visibility ranges. Procedural collision now uses 162 boxes and 253 cylinders; only 38 concave shapes remain for terrain and authored building structures.

At the existing scripted human-camera position, the Compatibility renderer submitted 1,650 draw calls and 1,166,295 primitives after the change, compared with the checked-in baseline log's 1,782 draw calls and 1,435,438 primitives. This is a workload comparison, not a frame-time benchmark; the baseline was captured with Linux llvmpipe and the new reading with an Intel Arc A370M on Windows.

## Results

- Original `tests/native_smoke.gd`: **38 assertions passed, 0 failures**. Preserved without edits from the supplied VS01 ZIP.
- Added `tests/vertical_slice_02.gd`: **41 assertions passed, 0 failures**.
- Total: **79 assertions passed**. Exit code 0 for each completed suite.
- Icons: 123 PNGs rendered from `art/item_visual.gd`; the initially blank render was corrected by enabling SubViewport updates. Final icons visually inspected.
- Actual engine screenshots captured for camp, bike/trailer, drone, substation, Backpack, module bay, service corridor and main menu. Fixed overlapping new world labels and concatenated inventory quantity/mass text during visual QA.

## Behavioral coverage

Original suite covers on-foot movement, bike physical travel/brake/reverse/recovery, drone ascent/descent/scan/follow/hold/return, low-energy return, camera preferences, transaction atomicity, finite mining, 12 kW generator accounting, full-storage fuel conservation, native persistence, malformed saves, all campaign transitions/puzzles, and remote power-control rejection.

New suite covers physical jump height; landing with held jump and no automatic bounce; crouch body height; ceiling-constrained standing; wall collision; actual small-step crossing and slope climbing; physical pickup removing its mesh; duplicate pickup rejection; stacking and capacity; transfers/retrieval through bike/drone/trailer/workbench/world storage; battery-rack compatibility; drone cargo capacity; docked equip/unequip; airborne equip rejection; actual cargo pickup; actual module-related battery consumption; aimed marker consumption/world placement and cooldown; Backpack rows; fuel/storage/loot/module-related state persistence; opening flags; malformed overweight storage; and compatibility with saves missing the VS02 extension.

Tests use separate `gridrunner_regression_test.json` and `vs02_test.json` saves. The campaign tests call gameplay handlers for later chapters; they do not constitute a full manual ride through the map. Some tests position actors at a fixture before exercising movement or interactions.

## Reproduce

From the repository root, using Godot 4.4.1:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/native_smoke.gd
godot --headless --path . --script tests/vertical_slice_02.gd
godot --headless --path . --script tests/polish_regression.gd
godot --headless --path . --script tests/asset_integration_regression.gd
godot --headless --path . --script tests/performance_regression.gd
```

Graphical renderer required for icons/screenshots:

```sh
godot --path . --rendering-method gl_compatibility --script tests/render_icons.gd
godot --headless --path . --editor --import --quit
godot --path . --rendering-method gl_compatibility --script tests/capture_views.gd
```

## Runtime/environment limitations

The virtual display warns that V-Sync switching is unsupported. Headless import of some textured GLB files can emit a dummy-renderer texture warning; graphical rendering was used to inspect the imported models. Audio was routed to the dummy driver for graphical captures because this container has no speakers. Sound files are valid WAVs, but subjective audio quality was not auditioned on speakers.

These checks do not establish whole-game bug freedom, optimal performance, collision clearance everywhere, correct drone return around arbitrary obstacles, per-instance durability, a fully balanced economy, or a finished photorealistic opening. See `WORK_COMPLETED.md` for the explicit remaining scope.
