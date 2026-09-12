# Asset credits

## Downloaded and bundled

| Asset | Creator / publisher | Source | License |
| --- | --- | --- | --- |
| Asphalt 011 | ambientCG | https://ambientcg.com/view?id=Asphalt011 | CC0 1.0 |
| Ground 037 | ambientCG | https://ambientcg.com/view?id=Ground037 | CC0 1.0 |
| Rock 030 | ambientCG | https://ambientcg.com/view?id=Rock030 | CC0 1.0 |
| Wood 051 | ambientCG | https://ambientcg.com/view?id=Wood051 | CC0 1.0 |

Each set includes the actual 1K JPG color, OpenGL normal and roughness maps in `assets/materials/`. Source pixels are unchanged; Godot settings add tint, tiling, mipmaps and filtering. Some outdoor materials use constant high roughness instead of the bundled map to avoid excessive highlights.

License policy: https://docs.ambientcg.com/license/
CC0 deed: https://creativecommons.org/publicdomain/zero/1.0/

CC0 does not require attribution; these credits retain provenance. No editorial-only or noncommercial assets were added.

## Original additions

- `art/kit.gd`, `art/prop.gd`, `art/foliage.gdshader`: electric bike, scout quadcopter, power trailer, generator, solar arrays, cabinets, workbenches, crates, barrels, pallets, sheds, poles/cables, substation, simplified humanoids, terrain, rocks, grass and trees.
- Material wear uses Godot procedural noise. No external model download is needed.
- `assets/audio/`: original synthesized wind, motor, rotor and two footstep WAVs. No third-party recordings, music or voices.
- HUD/menu additions use Godot controls and the default font.
- `docs/screenshots/`: actual Godot renders of the project, not concept art.

Existing GRIDRUNNER code, story and data were retained from the user's canonical project. Reference images guided the design but are not redistributed as runtime assets. No real motorcycle branding was added.

## Vertical Slice 02 additions

The subsequent Creek Service polish additions (Kenney foley, MakeHuman head mesh, bundled fonts and original level/UI assets) are documented in `ASSET_MANIFEST_POLISH.md`, with their local license files. Earlier generated footsteps remain for backward asset compatibility but are superseded by the new surface banks.

- **Kenney — Survival Kit 2.0**: https://kenney.nl/assets/survival-kit . License verified on the source page and in the downloaded `License.txt`: **CC0 1.0**, commercially reusable. Imported 15 GLB models (bedroll, bedroll-packed, tent-canvas, bucket, box-open, box-large-open, bottle, metal-panel-screws, resource-planks, tool-shovel, rock-a/b/c, rock-flat, tree-log-small). Original license retained at `assets/kenney/LICENSE.txt`. Modified placement, scale and material overrides use GRIDRUNNER's shared materials. These are stylized donor meshes, not photogrammetry.
- **Original GRIDRUNNER geometry**: `art/item_visual.gd`, module mounts, camp service layout and roadside pocket. Generated for this project; no third-party source. 123 data definitions share reusable geometry families; they are not 123 individually sculpted hero models.
- **Original item icons**: Godot renders of the corresponding `ItemVisual` geometry, consistent orthographic camera and lighting, 128×128 PNG. Rebuild using `tests/render_icons.gd` with a graphical renderer.
- **Original short audio effects**: jump, landing, pickup, container, module, wood/metal footsteps and Ghost Signal, synthesized for this project. No sampled recordings or external music.
- All Vertical Slice 01 credits and PBR textures remain included and unchanged.
