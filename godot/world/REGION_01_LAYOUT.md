# REGION 01 — BLACK CREEK FRONTIER

Purpose: first dense migration region proving traversal, power, scavenging, NPCs, interiors, drone reconnaissance and Ghost Signal gameplay.

Coordinate convention: X east/west, Z north/south, Y elevation. Origin is Start Camp.

## World anchors
- (0,0,0) START CAMP — player spawn, bike, power trailer, SCOUT-01 dock, workbench, solar deployable.
- (0,0,-70) OLD COUNTY ROAD — main northbound route.
- (-55,0,-180) MILEPOST 09 — small lived-in roadside settlement; garage, diner, two homes, Riggs encounter.
- (75,-4,-210) DRY CREEK — seasonal creek, culvert, water-turbine deployment point, scrap under bridge.
- (-115,2,-330) REDLINE SALVAGE — dense junkyard, crusher, sheds, vehicle hulks, component loot, rare fuel roll.
- (95,5,-390) QUARRY CUT — rock/material deposits, abandoned loader, utility shed, elevated drone vantage.
- (0,3,-480) BLACK CREEK SUBSTATION — damaged grid interface, electrical repair puzzle, high-value charge opportunity.
- (35,8,-560) RELAY HILL — communications hut and first major Ghost Signal source.

## Route structure
START CAMP -> COUNTY ROAD -> MILEPOST 09 / DRY CREEK -> SALVAGE / QUARRY -> SUBSTATION -> RELAY HILL.
The player can leave the road and approach sites from multiple directions.

## Density rules
Road corridor: poles every ~45–60 m with occasional broken spans; barriers/signs/culverts/abandoned vehicles at authored points.
Settlement: 4 enterable structures plus sheds/awnings and 30–50 clutter placements.
Salvage yard: 80+ visual clutter placements but only 20–30 gameplay-interactive objects. Repeated inert clutter should eventually use MultiMesh by spatial cluster.
Substation: strong silhouette from distance, fenced perimeter, transformer banks, switchgear, control building, damaged buswork and hazard zones.

## Gameplay loop
1. Spawn with partially charged bike and trailer.
2. Learn bike/trailer energy relationship.
3. Drone scan reveals settlement, creek power opportunity and distant substation signature.
4. Milepost NPC points toward tools/materials.
5. Salvage/Quarry provide components required for substation repair.
6. Rare fuel can appear in believable industrial/vehicle locations; a significant find is a major energy windfall.
7. Player repairs a safe fictionalized interface at the substation and recovers energy.
8. Restored equipment exposes/amplifies Ghost Signal at Relay Hill.

## Art direction
Warm dusty daylight at start; more steel/concrete and electrical infrastructure northward. Substation atmosphere becomes cooler, windier and electrically tense. Relay Hill introduces restrained Ghost Signal emissive language.

## Scene hierarchy target
Main
- World
  - Region01
    - Terrain
    - RoadNetwork
    - Infrastructure
    - StartCamp
    - Milepost09
    - DryCreek
    - RedlineSalvage
    - QuarryCut
    - BlackCreekSubstation
    - RelayHill
    - WorldClutter
- PlayerRig
- VehicleRig
- DroneRig
- Systems
- GUI

Sites should be self-contained reusable scenes with loose coupling. World controller supplies mission/state dependencies rather than sites hard-coding global paths.
