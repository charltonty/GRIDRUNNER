# VS02 polish asset manifest

Acquired and checked 2026-09-09. Original asset credits remain in `ASSET_CREDITS.md`.

| Asset / bundled location | Creator | Source | License | Changes |
| --- | --- | --- | --- | --- |
| Footstep and landing banks, `assets/audio/polish/` | Kenney + original GRIDRUNNER processing | https://kenney.nl/assets/impact-sounds | CC0 1.0; bundled `Kenney-LICENSE.txt` | Five source variants each of grass, concrete, wood, carpet and snow; metal-light and soft-heavy contacts. Resampled mono 24 kHz, filtered, peak-normalized, composite landing layers. Snow is a granular donor, not a claimed authentic recording of gravel/mud. |
| Creek, leaves_wind, insects, electrical, tire, freewheel WAVs | Original GRIDRUNNER procedural synthesis | `tools/build_polish_audio.py` | Original project-generated content; no external recording | Long-form noise/modulation layers; gain and distance controlled in runtime. |
| Equipment movement WAVs | Kenney + GRIDRUNNER processing | Same Impact Sounds pack | CC0 1.0 | Quiet filtered carpet contact used as restrained fabric/equipment layer. |
| Barlow Condensed SemiBold | Jeremy Tribby / Barlow contributors | https://github.com/google/fonts/tree/main/ofl/barlowcondensed | SIL Open Font License 1.1, bundled `assets/fonts/Barlow-OFL.txt` | Unmodified font, bundled locally. |
| IBM Plex Mono Regular | IBM / Plex contributors | https://github.com/google/fonts/tree/main/ofl/ibmplexmono | SIL Open Font License 1.1, bundled `assets/fonts/IBM-OFL.txt` | Unmodified font, bundled locally. |
| `assets/humans/field_head.obj` | MakeHuman Community | https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj | Base mesh is CC0 1.0; see bundled `MakeHuman-LICENSE.md`, section C | Head-only extraction of body group, no helper meshes, coordinate scale and orientation conversion. Approximately 4.2k vertices / 8.4k triangles. No MakeHuman application code incorporated. |
| Workwear, backpack, cap, gloves, pivot animation | Original GRIDRUNNER geometry | `art/human_visual.gd` | Original project-generated content | Shared head plus reusable clothing components. Not imported third-party animation. |
| Trail geometry, culvert, beacons, groundcover placement, HUD | Original GRIDRUNNER code/art | `world/authored_opening.gd`, `systems/field_hud.gd` | Original project-generated content | Builds on existing credited FieldKit materials and original foliage meshes. |

The MakeHuman asset/source split is documented at https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md and https://static.makehumancommunity.org/about/license.html. Only graphical asset data was used; the program's AGPL source code was not copied into this game.

## Surface bank provenance

| Runtime category | Base family | Additional processing |
| --- | --- | --- |
| dirt, dry soil, grass, leaves | grass | Different low-pass profiles; leaves add a soft granular tail |
| gravel, mud, shallow water | snow | Granular/wet noise layering and distinct filtering; synthesized interpretation |
| rock, concrete, asphalt | concrete | Material-dependent bandwidth |
| wood | wood | Restrained filtering |
| metal | concrete + metal-light contact | Low-level metallic contact overlay |
| interior flooring | carpet | Soft filtering |

All categories have five distinct step files and five distinct landing files. Every landing also uses a soft-heavy contact component. Rebuild with `python tools/build_polish_audio.py /path/to/Impact-Sounds/Audio` after installing numpy/scipy and ffmpeg. Rebuild the head with `python tools/build_human_head.py /path/to/base.obj`. Generated assets are already bundled; these dependencies are not required to play.
