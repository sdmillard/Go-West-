# Route branches

October 23, 2026. Third part of the expanded mechanics, after [Disease](DISEASE.md) and [Climate](CLIMATE.md). Only roads open to an 1848 party are added.

## Engine

- `data/route.json` stays a directed graph from Independence to Oregon City. A stop may now list several roads in `next`. **The first road is the main road.** The 1,938-mile southern road via Bridger and the Barlow Road is unchanged, so policy bots and balance studies that pick the first "leave" choice still follow it.
- Forks happen only at stops, never at crossings. Every road must rejoin and end at the single destination. Unreachable stops, cycles, duplicate targets and unknown hazards are rejected.
- At a fork the stop offers one "leave" choice per road. Alternative roads carry `edge` (1, 2…) and an optional authored `label`. The chosen road goes into the journal.
- `game.route_path` records the stops actually reached. It is saved as a top-level `route_path` field and validated against real roads; older saves are placed on the main road. Walking back to an abandoned wagon retraces the road actually taken.
- `destination()` is the journey length along the road taken so far plus the main road onward, so the progress bar and guide-mile total follow the choice.
- Crime news distances use `route.node_miles()`: branch stops take their branch distance.
- A road may carry `"hazard": "waterless"`: each day on that leg the team takes 3 extra strain points when working and gets no grazing recovery, and every traveler loses 1 health to thirst. These are placeholders.

## Greenwood's Cutoff (Little Sandy to Soda Springs)

Palmer's 1847 table (rows 50–53) gives both roads from the Little Sandy: the northern road "is two and a half days less driving" and strikes the Green River "about forty miles above the southern trail." From the Big Sandy to the Green there is "No water and but little grass between" (40 miles).

| Road | Little Sandy to the Green | Green to Soda Springs | Total |
| --- | ---: | ---: | ---: |
| Southern road via Bridger (main) | 36 | 189 (53 to Bridger, 136 on) | 225 |
| Greenwood's Cutoff | 46 (6 + 40 dry) | 124 (64 to the junction on Bear River + 60) | 170 |

The cutoff saves 55 guide miles and skips Fort Bridger's post. Its crossing is a new snow-fed river stop, `greenwood_cutoff`, with no ferry. The name "Sublette Cutoff" belongs to 1849 and later, so the game uses Greenwood's name. The Aseprite thread supplied the location picture.

## Still to come

The Columbia River by raft from The Dalles (the alternative to the Barlow Road) and the Fort Walla Walla detour, once their distances are sourced.
