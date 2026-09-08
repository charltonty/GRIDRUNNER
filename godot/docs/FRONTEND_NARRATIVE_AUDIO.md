# GRIDRUNNER Frontend, Narrative, Audio & Tutorial

This document is the production contract for the player-facing layer. These are game systems, not polish to postpone until the end.

## Boot / intro flow
1. Studio / GRIDRUNNER boot sting (short, skippable after first launch).
2. Black screen: distant wind, relay static, electrical transient.
3. GRIDRUNNER: GHOST SIGNAL title reveal.
4. Main Menu.
5. New Game begins in-world at Start Camp rather than a long exposition cinematic.
6. Tutorial is diegetic and contextual. Experienced players can reduce/disable hints.

## Main Menu
- Continue
- New Game
  - Standard
  - Explorer
  - Survival
  - Custom
- Load Game
- Settings
- Controls
- Field Manual
- Accessibility
- Credits
- Quit

Visual direction: weathered field terminal layered over a slow live world camera. Sparse animation, electrical flicker, drifting dust, distant transmission infrastructure. Avoid generic sci-fi neon.

## Pause Menu
- Resume
- Map
- Journal
- Inventory
- Crafting
- Bike / Trailer
- Drones
- Field Manual
- Save Game
- Load Game
- Settings
- Quit to Main Menu

## Tablet / field interface
MAP | JOURNAL | GEAR | CRAFT | BIKE | POWER | DRONES | SIGNALS | PEOPLE

The tablet normally does not pause the simulation. ESC pause does.

## HUD icon language
Icons should remain readable at small sizes and share one line-weight/silhouette language.

Core set:
- battery / state of charge
- lightning / live power
- plug / grid connection
- generator
- fuel can
- solar
- water turbine
- bike
- trailer
- drone
- signal/link
- scan
- waypoint
- salvage
- tool
- ore/mining
- inventory/cargo
- crafting
- repair/condition
- warning/hazard
- objective
- person/NPC
- barter
- shelter/camp
- save
- audio/radio

Use vector/SVG source where practical so UI scales cleanly.

## Tutorial: First 15 minutes
Tutorial prompts only appear when relevant.

### 00:00 — Wake / orient
Objective: CHECK YOUR GEAR
Teach mouse look, WASD, interaction, Field HUD.
Environmental storytelling introduces the failed electrical frontier without an exposition dump.

### 02:00 — Bike
Objective: BRING THE BIKE ONLINE
Teach inspection, bike battery state, mount/dismount, throttle/braking, camera cycling.

### 05:00 — Trailer
Objective: CHECK THE POWER PLANT
Teach kW vs kWh through the interface, trailer battery bank, source/input/output concepts. Player sees generator but starts with little or no fuel.

### 07:00 — SCOUT-01
Objective: GET EYES ON THE ROAD
Teach launch, flight, altitude, battery, range, signal and scan. Scan identifies Milepost 09 and a salvage return.

### 10:00 — First salvage
Objective: TAKE WHAT STILL WORKS
Teach loot, carry/cargo, condition, components and persistent depletion.

### 12:00 — First person
Objective: ASK ABOUT THE LINE
Meet first resident. Dialogue points toward damaged utility infrastructure without turning the NPC into a tutorial robot.

### 15:00 — Hook
A strange relay burst interrupts ordinary radio/static. Journal records UNKNOWN SIGNAL. The player is free to investigate or continue preparing.

## NPC dialogue architecture
Dialogue data should be externalized from NPC controller code. Each conversation supports:
- speaker ID/name
- state/prerequisites
- line text
- optional player responses
- knowledge flags
- barter availability
- objective updates
- relationship/familiarity hooks
- one-shot and repeatable lines
- audio/voice event hook

NPCs should know local things: roads, weather, equipment, shortages, rumors, people. Avoid everyone knowing the entire plot.

### Initial cast
RIGGS — Milepost 09 repairman/scavenger. Practical, guarded, understands tools and local utility infrastructure.
MARA — route contact / survivor with broader local knowledge. Preserve useful characterization/content from browser build during migration.
NELL — Dry Creek resident who understands seasonal water flow and old turbine sites.
OWEN — salvage-yard operator/trader; values useful hardware over abstract currency.

## Sample first Riggs exchange
RIGGS: "That bike yours? Keep it off the shoulder past the old line yard. Ground's full of things that'll open a tire."

Player responses:
- "What happened to the line?"
- "I'm looking for charge."
- "Anything worth salvaging nearby?"
- Leave

If charge:
RIGGS: "Substation east of here used to feed half the valley. Dead last I checked. Dry Creek's safer if you've got a turbine. Slower, though."

If salvage:
RIGGS: "Redline yard. Everybody picks the easy piles. Nobody wants to crawl under anything. That's why there's still good copper there."

Later, after Ghost Signal activation:
RIGGS: "You hear that carrier last night? Don't tell me that was weather. Weather doesn't repeat itself."

## Audio architecture
Audio buses:
MASTER
- MUSIC
- WORLD
  - AMBIENCE
  - WEATHER
  - MACHINERY
  - VEHICLES
  - ELECTRICAL
- PLAYER
  - FOOTSTEPS
  - GEAR
- DRONE
- VOICE
- UI
- RADIO

Use positional 3D audio for physical sources and non-positional audio for UI/score.

### Required first-region sound families
Environment:
- open-country wind layers
- grass/brush movement
- insects/day wildlife
- sparse night wildlife
- distant metal creaks
- settlement room tones
- garage/workshop ambience
- interior/exterior filtering

Bike:
- motor whine by load/speed
- drivetrain/tire layers
- suspension impacts
- gravel/dirt/asphalt surfaces
- brake/regen response
- electrical contactors
- mount/dismount/stand

Power trailer:
- generator crank/start/run/load/stop
- cooling fan
- inverter whine
- contactors/relays
- cable connection
- battery cooling
- warning alarms

Electrical world:
- transformer hum
- switchgear clunks
- arcing/sparks
- line corona under appropriate conditions
- dead equipment silence contrasted with energized states

Drone:
- prop/motor load
- gimbal movement
- dock latch
- telemetry/UI
- weak-signal static/interference
- scan pulse

UI:
- focus/click/back
- tab changes
- objective update
- inventory transfer
- invalid action
- save confirmation
- low battery/warning hierarchy

Ghost Signal:
Build a recognizable sonic motif from radio carrier, phase beating, relay chatter and unnatural electrical timing rather than a generic horror sting.

## Music
Music should be restrained. Long stretches can be ambience-only. Use adaptive stems for discovery, danger, Ghost Signal and camp rather than constant looping score.

## Voice
Dialogue must work fully with text alone. Voice hooks are supported but voice acting is not required for prototype completion. Radio processing should never make critical dialogue unintelligible.

## Accessibility / options
- subtitles on/off
- subtitle size/background/speaker labels
- master/music/world/voice/UI levels
- mono audio option
- dynamic range presets
- visual alternatives for important audio cues
- tutorial hints full/reduced/off
- hold/toggle interaction options
- camera shake/head bob/FOV effects separately adjustable
- rebindable controls

## Save feedback
Autosaves and manual saves use a small unobtrusive icon plus timestamp. Never hide save failures. Manual saves live in Pause > Save Game; autosaves occur at meaningful transitions and configurable intervals.
