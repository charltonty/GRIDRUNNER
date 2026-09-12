# VS02 Asset Integration

## Play

Extract the ZIP into a new folder, import `project.godot` with Godot 4.4.1, allow imports to finish, then press F5. Choose New Expedition → Standard. This is a complete source project, not a standalone executable. Blender is not needed to play. Back up valued saves before using this milestone.

## Added

- 85 exported GLB assets from Electrical 01, Field Camp 02, Routes 03, Salvage 04 and Architecture 05. Textures are embedded; showroom objects are excluded.
- Five explorable buildings along the service area: Utility House, Roadside Store, Texas House with upstairs, Maintenance Workshop and Creek Pump.
- Interactable building doors, tool-gated locked service doors, saved door states and five finite salvage caches that remain collected after saving/loading.
- Camp, workbench, generators, electrical cabinets, route props and physical item visuals use the supplied models. Existing VS02 progression and gameplay remain in place.
- Clear connecting paths, interior practical lights, stable floor collision and a continuous collider beneath the visible house stairs.

## Validation

Tested in Godot 4.4.1 stable. 211 assertions passed: 38 native, 41 VS02, 96 Creek Service polish and 36 asset-integration checks. The integration suite physically checks entrances, upstairs traversal, door operation, cache duplication prevention and restored save state. Logs are in `docs/validation/`.

Nine actual engine screenshots are in `docs/asset-screenshots/`. These use a detached inspection camera; any interaction prompt belongs to the player left at camp.

## Scope and known limitations

This upgrades the existing vertical slice; it is not a finished commercial game. Existing stylized vegetation and NPCs remain. Tests use a headless runtime and screenshots use the Compatibility renderer; target-hardware performance and a full manual playthrough are not certified. Some test shutdowns report ObjectDB/resource teardown warnings despite passing assertions.

## Re-export

`tools/export_packs.py` targets Blender 4.4.3. Run Blender in background with `--python tools/export_packs.py -- source.blend assets/packs`. Repeat for each supplied pack. Original Blender packs are not duplicated in this game ZIP. Architecture preserves tiled PBR materials; procedural prop materials are baked into 512px color/ORM atlases. Floor boxes avoid triangle seam snagging; stair traversal collision is added in `systems/asset_integration.gd`.

## Asset rights

The five new GRIDRUNNER packs are user-supplied assets. This integration does not grant or change their license. Existing third-party credits and license files remain in the project.
