# GRIDRUNNER Godot Asset Pipeline

## Principle
Build a reusable visual language, not a pile of one-off props. Gameplay code must never depend on a specific final mesh. Prototype geometry can be swapped for final GLB assets without rewriting systems.

## Runtime format
Primary 3D interchange: glTF 2.0 / GLB.
Textures: PNG during development; compressed/imported by Godot for runtime.
PBR material channels: base color, normal, roughness, metallic, ambient occlusion, emissive where needed.

## Asset tiers
### Hero
Player bike, generator trailer, drones, important NPCs, Ghost Signal machinery. Unique geometry/materials and LODs.

### Modular environment
Walls, doors, windows, roofs, foundations, awnings, stairs, fences, road pieces, utility poles, substations, solar hardware, pipes, conduit. Designed on a consistent metric grid.

### Prop families
Crates, barrels, pallets, wire spools, motors, batteries, tools, pumps, appliances, scrap, signs, furniture, camp equipment. Make variants from shared meshes/materials.

### Natural
Rock families, cliffs, deadwood, grasses, shrubs, trees, ground debris. Favor instancing and material variation.

## Texture strategy
Use trim sheets and tileable materials heavily for buildings/infrastructure. Reserve unique texture sets for hero assets. Use decals for labels, rust, leaks, warnings, numbers, graffiti and environmental storytelling.

Recommended families:
- painted/rusted steel trim
- galvanized utility metal
- electrical equipment trim
- weathered wood
- concrete/masonry
- asphalt/road markings
- dirt/rock terrain
- industrial labels/signage decal atlas
- settlement signage decal atlas
- Ghost Signal emissive/technical atlas

## Naming
`gr_<category>_<family>_<asset>_<variant>`
Examples:
`gr_vehicle_bike_frame_a.glb`
`gr_power_generator_portable_a.glb`
`gr_building_wall_corrugated_4m_a.glb`
`gr_prop_crate_utility_b.glb`

## Scale
1 Godot unit = 1 meter. Model at real-world scale. Apply transforms before export. Forward orientation and pivots must be standardized per category.

## Collision
Hero/moving objects use authored simple collision shapes. Buildings use simplified collision meshes. Tiny clutter should generally have no collision unless gameplay requires it.

## LOD / performance
Hero: LOD0/1/2 where worthwhile.
Buildings: modular pieces plus distance simplification.
Small props: MultiMesh/instancing and aggressive distance culling.
Vegetation: MultiMesh and billboard/distance strategy.
Do not make thousands of unique materials.

Static procedural props are merged by material into local render-grid cells. Keep large road and terrain meshes separate, and keep cell origins near their geometry so visibility ranges measure the intended distance. MultiMeshes must also use local transforms and a conservative `custom_aabb`; Godot culls a MultiMesh as one unit, not per instance.

Use primitive `BoxShape3D`, `SphereShape3D`, `CapsuleShape3D` or `CylinderShape3D` collision for simple world objects. Reserve concave triangle collision for terrain and authored structures that genuinely need it. Run `tests/performance_regression.gd` after changing world generation, batching, foliage, visibility ranges or collision.

## Asset-sheet workflow
Concept sheets generated during development are references, not runtime assets. For each sheet:
1. approve silhouette/material language;
2. split into an asset manifest;
3. model reusable families;
4. UV against trim/tile materials where possible;
5. export GLB;
6. import into Godot;
7. create reusable `.tscn` scene with collision/interaction metadata;
8. replace graybox instance without changing gameplay code.

## First production pack
1. Electric dirt bike hero kit
2. Multi-source generator trailer hero kit
3. Scout drone hero kit
4. Roadside electrical infrastructure kit
5. Rural/industrial building modular kit
6. Salvage/junk prop kit
7. Terrain/rock/vegetation kit
8. GRIDRUNNER signage/decal atlas
9. Common PBR trim/material pack

This pack should be enough to build the migration test region at near-production visual quality before expanding asset breadth.
