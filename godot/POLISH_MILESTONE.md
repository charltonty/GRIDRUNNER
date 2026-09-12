# GRIDRUNNER — VS02 / Creek Service polish milestone

This is an incremental build of the completed Vertical Slice 02, not a restart. Open `project.godot` in Godot 4.4.1 or compatible Godot 4, then F5 to run the project.

## Changes

- New WALK, E-DRIVE and SCOUT-01 instrument layouts: compass, field status, traction gauge, flight telemetry, antenna reception and expiring notifications. Locally bundled Barlow Condensed and IBM Plex Mono; matching inventory, storage, equipment, pause and journal theme.
- Thirteen surface categories, each with five step and five separate landing samples. Kenney CC0 foley replaces old generated footsteps. No adjacent sample repeats; distance-based cadence, quieter crouching, silent airborne movement and impact-weighted landing.
- Metadata on physics geometry and non-blocking trail surface volumes. Trail ribbons do not add overlapping coplanar collision faces.
- Spatial creek, foliage, insect and electrical ambience; restrained motor mix, tire/coasting layers, nearby external drone attenuation and smoothed rotor pitch. Synthesized ambience is not field-recorded wildlife.
- Compact creek-service loop southeast of camp: trails, clustered groundcover/scrub/canopy, rock shelves, fencing, culvert, survey beacons, salvage discoveries and a powered shortcut.
- Optional six-beacon Creek Run with ordered forward crossings, timer, restart, medals and persistent personal best. Gold ≤35 seconds; Silver ≤50 seconds; Bronze completion.
- Heading/position/altitude-sensitive carrier reception. The hidden repeater is not added to the scan map until resolved nearby.
- Precision landing platform; persistent flight/distance/scan/recovery records; finite-loot POIs, breaker, gate and bench lamp.
- CC0 MakeHuman anatomical head with original modular workwear, cap, backpack and gloves. Lightweight arm/attention loops; not a finished realistic humanoid rig or facial-animation system.
- Batched camp dressing, spatial foliage chunks and shorter two-split shadows. Pause → Foliage selects STANDARD or PERFORMANCE, reducing ground/scrub instances without removing routes or barriers.

## New-content route

1. Prepare at camp. Follow the Creek Service sign southeast of the shelter.
2. Take the trail east of the maintenance fence. Numbered paired poles are survey timing beacons.
3. Launch **Q**, approach the SCOUT LEAGUE terminal, and press **E** in drone mode to arm. Cross beacon 01 to start. **J** rearms while a trial is active or near the start; fly back to 01. Leaving manual FPV aborts without changing the best.
4. **R** scans with a scanner installed. Follow the CARRIER percentage near the creek; heading and altitude matter. Close scanning resolves the repeater. Return on foot for its stashed battery salvage.
5. Restore the service breaker with a screwdriver and one wire. Return to the maintenance gate and press **E** to open the saved shortcut.
6. Gently touch down on the marked service cabinet beyond the culvert. Two seconds of stable physical contact earns a precision perch.
7. **Escape → SCOUT / pilot record** opens the field log. Existing controls, campaign, inventory, bike, trailer and modules remain available.

## Scope and limitations

The improvement is concentrated around camp and its creek service pocket. The entire campaign corridor has not been redesigned into a gated level. The new gate is an optional shortcut, not a campaign lock.

One course is implemented. Photography, additional courses, full NPC skeletal walking/sitting, realistic clothing textures, environmental reverb/occlusion and advanced motor/suspension sounds remain unfinished. Bike condition and regeneration are not invented telemetry: they are not simulated. Range is an estimate; displayed power reflects the existing accelerated energy model.

The endurance run is automated with explicit fixture resets between modes. It is not a manual opening playthrough. A human ten-minute headphone audition was not possible here; audio comfort still needs listening on the player's equipment. Software-renderer measurements do not establish target-PC GPU performance.

See `POLISH_VALIDATION.md`, `ASSET_CREDITS.md` and `docs/test-logs/` for validation and provenance.
