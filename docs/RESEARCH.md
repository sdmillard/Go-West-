# Research and fidelity notes

Research date: October 21, 2026. Public references were studied for mechanics and presentation. No classic game assets or BASIC code were copied into this project. Public accessibility alone is not a redistribution license.

Update: reference snapshots are now downloaded under ignored `research/local/`. This includes BASIC listings, so the statement above applies to the independently implemented game, not the research library. Source hashes and URLs are in `research/SOURCES.json`. Use `MECHANICS_LEDGER.md` for the current status of individual rules and `PROJECT_BRIEF.md` for the supplied design brief. Classic-first development takes priority over all optional absurd content.

## 1978: a source reference, not the later simulation

[1978 BASIC transcription](https://raw.githubusercontent.com/topherPedersen/OregonTrail1978/master/oregon.bas), with [provenance and compatibility modifications](https://github.com/topherPedersen/OregonTrail1978). The repository identifies the May/June 1978 Creative Computing printing and links its magazine scan. This is a modern transcription with stated edits, not an authenticated unmodified original.

Inspection: BASIC lines 6470–6790 identify food, ammunition, clothing, cash, mileage and event flags. Lines 6290–6440 connect eating choices to illness. These support resource pressure and event-driven survival as useful design references. Our implementation does not translate these formulas or claim they are the 1985 algorithms. The original variable meanings also differ from the physical pound/unit inventory used here.

## 1985: the mechanical target

[MECC July 1985 Apple II instruction booklet](https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/educational/mecc/documentation/oregon_trail/The%20Oregon%20Trail.pdf). Printed advice covers managing pace and supplies, resting, ration changes and river crossing alternatives. The travel display reports food, health, date, mileage and distance to a landmark. These informed the prototype's controls and status display. Hunting, trade, professions and the complete route described there remain unimplemented.

[R. Philip Bouchard, Imagining the New Design](https://www.philipbouchard.com/oregon-trail/imagining-design.html). The lead designer distinguishes the original two-week turns from a new landmark-based framework, with passing time tied to resource management. This supports using a separate engine and explicit landmark decisions. Our daily turns are a prototype interaction choice, not a reproduction of the original time controller. The new design's cumulative health model is the basis for including aggregate health; individual illnesses still need their own system.

[Bouchard, Crossing Rivers](https://www.philipbouchard.com/oregon-trail/crossing-rivers.html). The classic model uses depth, width, current, bottom type and recent rainfall, with different crossing methods and outcomes. Kansas River is one of the four selected crossings. Here we deliberately use a safe paid ferry and a simplified risky float. The $15 fare, one-day delay, 35% mishap probability and losses are **our provisional values**. They are not transcribed classic formulas. Ford/wait/guide choices require the future river/weather model.

## 1993: interface reference

[MECC historical chronology](https://mecc.co/history/) records the Windows disk/CD releases in 1993. [The 1993 Windows game reference and screenshots](https://oregontrail.ws/games/the-oregon-trail-cd-rom) provide a secondary archival presentation of the mouse-driven edition. The archive describes menu-based interactions and the continuing supply/landmark journey. We consulted that presentation, not a locally executed original game; visual and numerical parity have not been established. We use visible clickable actions and encounter choices while designing an original layout and palette.

The 1993 Windows edition and 1992 DOS Deluxe are distinct releases; their dates should not be conflated. Mouse menus are inspiration, not a reason to rebuild Windows 3.1 or run the proprietary executable.

## Implemented tuning versus verified design

| Mechanic | Current slice | Fidelity status |
| --- | --- | --- |
| Time and landmarks | Daily actions, 102-mile first leg | Classic-inspired structure; endpoint convention needs source-level mileage verification |
| Starting inventory | 180 lb food, $60, 2 generic parts, health 85 | Original starter kit; no store or profession yet |
| Pace | 12/18/24 miles + seeded ±2 | Provisional |
| Rations | 1/2/3 lb per person per day | Provisional quantities; familiar tier concept |
| Health | Travel ration adjustment −3/0/+1, pace penalty 0/1/4 | Simplified original formula |
| Rest | +7 health if fully fed; no mileage | Classic-inspired behavior, provisional amount |
| Starvation | −18 health/day if food falls short | Provisional; zero food never heals during rest |
| Mud | Guaranteed day-2 decision | Original historical-style scenario, not a quoted diary event |
| River | $15 safe ferry or 35% float mishap | Simplified original tuning |
| Absurd encounters | 1% on eligible days, once per ID | Original extension; excluded from Classic |

The game currently models the travelers' logistical perspective, not a complete history of the trail or its effects on Native nations. Historical content expansion should use specific sources and avoid importing the older games' stereotypes as simulation rules.

## Next research and implementation steps

1. Verify route mileages, store prices, starting roles and daily consumption against original documentation and observed gameplay.
2. Expand party state and weather before calibrating disease and river probabilities.
3. Add shopping and hunting, then compare survival and resource curves across thousands of seeds.
4. Add versioned saves and external content packs after the state/content contracts stabilize.
5. Move vehicles, locations and item properties into validated data once a second route segment needs them.

Engine tooling: [Godot 4.5.1 official release](https://github.com/godotengine/godot/releases/tag/4.5.1-stable), [official command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html). Development runtime is pinned to 4.5.1; it is not represented as the latest release.
