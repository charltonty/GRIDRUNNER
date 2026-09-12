# VS02 Creek Service — validation

Engine: Godot 4.4.1 stable, Linux. Existing source recovered from the completed VS02 project. The two original regression scripts are byte-identical to that checkpoint.

## Regression suites

**Release result: 175 assertions passed, 0 assertion failures.** All three suites exited with code 0. The shutdown-only harness warning described below remains explicitly recorded.

| Suite | Assertions | Purpose |
| --- | ---: | --- |
| `tests/native_smoke.gd` | 38 | Existing campaign, bike, drone, saves, power and transaction coverage |
| `tests/vertical_slice_02.gd` | 41 | Existing traversal, storage, modules, cargo and backward-compatible persistence |
| `tests/polish_regression.gd` | 96 | New modes, surface banks, cadence, physical paths, trial, signal, shortcut, records and NPC loading |

New coverage includes five distinct sample byte streams per surface; no adjacent sample-index repeat; no steps while idle/airborne or on the landing frame; crouch gain; impact-weighted landing; metadata resolution; all six forward course crossings; reverse rejection; best-time preservation; cancel on mode change; reception direction/distance; hidden carrier discovery; finite POI loot; powered shortcut; new and old saves; malformed records; actual CharacterBody traversal down all six service-trail segments; actual drone-body flight through every aperture; stable platform contact; and anatomical head loading.

Run from the project root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/native_smoke.gd
godot --headless --path . --script tests/vertical_slice_02.gd
godot --headless --path . --script tests/polish_regression.gd
```

## Problems caught and fixed

- A ground-ribbon seam could stop movement at a bend. Trails now have non-blocking audio surface volumes instead of overlapping coplanar physics faces. The physical walk test then completed every segment.
- JSON decodes numbers as floats; the foliage preset initially rejected valid reloaded saves. Numeric validation now explicitly handles integral float values. Both original save suites were rerun.
- Course-plane normals now ignore vertical tilt so vertical-only motion cannot masquerade as a forward crossing.
- Precision landing requires a contact-distance ground ray, not merely low speed near the platform. Hovering above it is not enough.
- Some upstream carpet files have identical bytes. The delivered interior/equipment composites include distinct restrained fabric tails; all 141 generated WAV files now have unique hashes.
- HUD contrast, notification wrapping, large world labels and early foliage brightness were adjusted after actual engine renders.

## Rendering and endurance

`tests/capture_polish.gd` produces actual engine images in `docs/polish-screenshots/`: WALK, bike, FPV, service loop, inventory, pilot record and a close character check. These are not concept renders. The separate character-check fixture exists only in the capture script.

`tests/endurance_polish.gd` completed **600 wall-clock seconds and 2,111 rendered frames** on an intermediate integrated build. It exercised walking/crouching, FPV, bike travel and audio-system operation, with explicit fixture resets between stages. It logged 151 step events, reached the service-trail endpoint twice and rode the road corridor. Its simple FPV autopilot did not progress the course; a separate final physical drone-body regression successfully flew all six apertures. Do not interpret the endurance run as a successful full campaign playthrough.

The virtual renderer was Mesa llvmpipe (CPU software OpenGL), not a hardware GPU. Sampled frame rates during the endurance run were roughly 1–8 FPS while other checks were also running. This is **not an acceptable target-PC performance result**, nor a useful hardware-GPU benchmark. Render captures report roughly 1–2k draw calls depending on view; further optimization and hardware profiling are still needed. New foliage is instanced and culled; PERFORMANCE mode reduces ground/scrub density and range. Geometry carrying gameplay collision is not removed by that setting.

Audio used the Dummy driver. WAV validation found no clipping (maximum sample magnitude below 0.58 full scale) and all files load in the engine. **No human headphone audition was performed.** The required subjective ten-minute audio comfort test and manual first-10–15-minute opening playtest remain outstanding.

Some test harness runs emitted shutdown-only ObjectDB/resource warnings when local fixture references remained live at `quit()`. A separate instantiate/free probe (`tests/leak_probe.gd`, five frames before and after deletion) exited without those warnings. This does not constitute a full memory-leak audit.

No Windows export or target-hardware benchmark is included. Delivered source preserves the existing systems but does not claim every item in the much broader production handoff is finished.
