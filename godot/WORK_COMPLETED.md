# Vertical Slice 02 — implemented scope and next priorities

## Preserved foundation

This is the supplied VS01 project with additions, not a replacement game. The active controller remains `scripts/expedition.gd`. Bike travel, braking, reverse, recovery, trailer generation, drone flight/scan/recall, independent POVs, NPC trading, mining/crafting, all three campaign legs and native save/load remain. The original 38-assertion `tests/native_smoke.gd` is preserved.

## Implemented

- Traversal: edge-triggered 6.2 m/s jump, 0.12 s coyote time, 0.14 s jump buffer, gravity and limited air acceleration, 0.3 m swept step handling, walkable slopes, crouching with overhead clearance, landing detection, nonlethal fall damage, encumbrance slowdown, restrained landing camera response with reduced-motion toggle.
- Physical catalogue: **123 item definitions**, shared reusable model families, mass/category/value/condition metadata, electrical specifications for relevant hardware, and **123 matching 128px model-rendered icons**. This is a reusable catalogue, not 123 unique hand-sculpted objects. 34 finite loose loot placements are authored into the opening. Additional catalogue definitions are ready for later loot tables.
- Backpack: icon rows, quantities, mass and capacity, category filtering, name/mass sorting, inspection card, compatible contextual actions, hand-tool selection, usable recovery supplies and salvage. The hand-tool slot records equipment; it does not yet animate a held tool.
- Storage: common atomic transfers for Backpack, bike cargo, drone cargo, trailer, workbench, battery rack, fuel storage and one roadside world-storage station. Capacity and battery/fuel compatibility checks. Physical proximity required by the interface. Existing trailer contents preserved. Original campaign loot containers retain their existing finite-loot screens.
- Drone modules: two slots; scanner, spotlight, marker, cargo or utility; modelled attachments; dock/proximity requirements; 2 kg cargo tray; airborne collection of light physical loot; loaded tray cannot be removed; cargo requires its module. Power and mass affect actual flight battery consumption.
- Marker action: aim at a collidable surface within 100 m, consume one of three markers, add a visible world designation/map entry, 1.5 s cooldown. Rearm at the camp workbench for steel/plastic. Utility module can activate nearby elevated mission switches; existing campaign switch behavior remains available for compatibility. No weapons/ordnance system added.
- Camp/corridor: sleeping area, storage shelving/bins, diagnostic bench, drone repair bench, component clutter, water/supplies, cables, low traversal obstacles, service-cabinet salvage pocket, damaged roadside materials, fences, grouped rocks, route signs and an early Ghost Signal audio/text hook. The distant map has not been enlarged.
- Art/audio: 15 Kenney CC0 model imports, recolored/rescaled with the existing material system; 27 consistent SVG UI symbols and reference sheet; item sheet; new jump, landing, pickup, container, module, signal, wood and metal footstep audio. Original ambientCG PBR materials retained.
- Persistence: new storage contents, modules, remaining payload, picked objects, equipped tool and opening flags save with the expedition; old VS01 saves migrate on load. Test saves use separate filenames.

## Energy balance

The existing 12 kW generator and five-real-minute game hour remain. It yields 3 kWh per litre, stops consuming fuel when the 0.8 kWh reserve is full, and supports transferring reserve to the 2 kWh bike. A full 5 L can represents 15 kWh, so filling equipment requires multiple generation/transfer cycles. Drone energy capacity is treated as 0.4 kWh. Power is kW; stored/output energy is kWh. Fuel is finite and valuable; two authored opening fuel discoveries supplement the inherited loot tables.

## Known limitations and remaining priorities

- This is still a stylized, procedural indie-game milestone, not the photorealistic reference art. NPCs and some prop silhouettes remain visibly primitive. The supplied bike/drone hero models remain the base; this pass adds modules rather than replacing them with scanned assets.
- Item condition is definition-level metadata; per-instance wear, electrical state per battery item, stack splitting, drag/drop, quick slots, backpack body model and tool-use animations are not implemented. Food/water currently restore health; no new hunger/thirst simulation.
- Workbench/battery/fuel/world storage use the common inventory backend, but stored electrical items are not automatically wired into the camp power network. Transfer fuel to Backpack and pour it at the trailer. One nearby world-storage station is configured; original loot containers are not all migrated.
- Marker designations are session-local: payload consumption persists, but placed markers are not recreated after load. No projectile combat, cargo-drop physics, NPC reactions to markers, or advanced drone obstacle-avoiding return. Existing return can collide with structures.
- Crouch and small steps are implemented; mantle/vault/parkour are not. Fall damage leaves at least 1 HP. Ground footsteps distinguish dirt/asphalt and tagged wood/metal/concrete, but not every legacy collider has a surface tag.
- No new dynamic weather, detailed decal atlas, voiced dialogue, character animation system, controller/touch support, input rebinding or Windows executable. Decorative furnishings often have no collision; gameplay barriers/benches/cabinets do.
- No hardware-GPU benchmark or timed human 10–15-minute playthrough. The opening density is concentrated at authored stops, with recognizable gaps along the inherited long road. Further work should deepen those stops before expanding the map.

Next priorities: per-instance item/battery state and camp power integration; migrate remaining containers; marker persistence and drone obstacle avoidance; higher-quality NPC/bike/environment assets; traversal playtesting on Windows; richer authored interactions and contextual dialogue.
