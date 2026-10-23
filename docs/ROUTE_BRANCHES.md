# Route branches

October 23, 2026. Third part of the expanded mechanics, after [Disease](DISEASE.md) and [Climate](CLIMATE.md). Only roads open to an 1848 party are added.

## Engine

- `data/route.json` stays a directed graph from Independence to Oregon City. A stop may now list several roads in `next`. **The first road is the main road.** The 1,938-mile southern road via Bridger and the Barlow Road is unchanged, so policy bots and balance studies that pick the first "leave" choice still follow it.
- Forks happen only at stops, never at crossings. Every road must rejoin and end at the single destination. Unreachable stops, cycles, duplicate targets and unknown hazards are rejected.
- At a fork the stop offers one "leave" choice per road. Alternative roads carry `edge` (1, 2…) and an optional authored `label`. The chosen road goes into the journal.
- `game.route_path` records the stops actually reached. It is saved as a top-level `route_path` field and validated against real roads; older saves are placed on the main road. Walking back to an abandoned wagon retraces the road actually taken.
- `destination()` is the journey length along the road taken so far plus the main road onward, so the progress bar and guide-mile total follow the choice.
- Crime news distances use `route.node_miles()`: branch stops take their branch distance.
- A road may carry `"hazard": "waterless"` (or `river`, `unrest`, below): each day on that leg the team takes 3 extra strain points when working and gets no grazing recovery, and every traveler loses 1 health to thirst. These are placeholders.

## Greenwood's Cutoff (Little Sandy to Soda Springs)

Palmer's 1847 table (rows 50–53) gives both roads from the Little Sandy: the northern road "is two and a half days less driving" and strikes the Green River "about forty miles above the southern trail." From the Big Sandy to the Green there is "No water and but little grass between" (40 miles).

| Road | Little Sandy to the Green | Green to Soda Springs | Total |
| --- | ---: | ---: | ---: |
| Southern road via Bridger (main) | 36 | 189 (53 to Bridger, 136 on) | 225 |
| Greenwood's Cutoff | 46 (6 + 40 dry) | 124 (64 to the junction on Bear River + 60) | 170 |

The cutoff saves 55 guide miles and skips Fort Bridger's post. Its crossing is a new snow-fed river stop, `greenwood_cutoff`, with no ferry. The name "Sublette Cutoff" belongs to 1849 and later, so the game uses Greenwood's name. The Aseprite thread supplied the location picture.

## The Columbia by raft (The Dalles to Oregon City)

At The Dalles the Barlow road stays first. The second choice builds a raft (3 days) and floats the Columbia:

| Leg | Miles | Basis |
| --- | ---: | --- |
| The Dalles to the Cascades (`columbia_raft`) | 40 | NPS: the river "flowed smoothly for about forty miles" below The Dalles |
| Cascades to Oregon City | 76 | 6 miles of rapids (NPS) + about 44 to the Willamette's mouth + about 26 up the Willamette to the falls (modern river-mile estimates, authored) |

The river route totals 1,894 guide miles against 1,938 by the Barlow road, and it avoids the Barlow toll and Laurel Hill.

- Road hazard `river`: the current carries the party at about 15 miles a day times the day's weather speed (wind). The team does not pull, a party with no oxen can still float, and wagon and ox trail events are skipped. In reality livestock were usually driven along trails; the game keeps the animals with the party.
- The Cascades stop (`portage` flag) offers **Portage around the rapids · 2 days** or **Run the rapids · 1 day** with a 30% wreck chance: up to 60 lb food, a clothing set and 15 health from everyone ("near drowning"). The rapids risk is validated in saves.
- Road `effects` (days only, 1 to 5) are copied onto the leave choice; that is how raft building costs time.
- Sources: [NPS, Overlanders in the Columbia River Gorge](https://www.nps.gov/articles/000/overlanders-in-the-columbia-river-gorge-1840-1870-a-narrative-history.htm) (rafts, Chinookan and HBC help, wind, livestock trails) and [Historic Oregon City, The Final Leg of the Trail](https://historicoregoncity.org/2019/04/02/the-final-leg-of-the-trail/) (HBC bateau about $80, rafts overturned by wind, about one in four took the river after the Barlow Road opened). Hiring an HBC boat is not offered yet.

## Fort Walla Walla through Cayuse War country (Blue Mountains to the John Day)

Spencer chose to add this as a dangerous detour. After the Whitman killings at Waiilatpu in November 1847, the Oregon volunteers fought the Cayuse through 1848, and the NPS notes that travelers "generally avoided Fort Walla Walla." The main road down the Umatilla stays first.

| Road | Miles | Basis |
| --- | ---: | --- |
| Main: Blue Mountains to Umatilla to John Day | 16 + 77 = 93 | Palmer rows 104 to 106 |
| Blue Mountains to `fort_walla_walla` | 55 | Authored estimate: about 30 to Waiilatpu and about 25 to the HBC post (`allocation_note`) |
| `fort_walla_walla` to John Day | 58 | Authored estimate: about 25 down the Columbia's south bank to the Umatilla's mouth, then Palmer's 33 (row 106) |

The detour is about 20 miles longer (1,958 guide miles in all by this road and the Barlow road).

- Both legs carry hazard `unrest`: trail events are twice as likely and riders/bandits weigh three times as much (placeholders).
- Three new events have `"hazard": "unrest"` and happen only on unrest legs: **Oregon volunteers** (share 30 lb food or refuse), **Cayuse riders** (trade a clothing set and 10 bullets for passage, go around for a day with team strain, or stand your ground as armed defense with a 30% wound risk) and **the Waiilatpu mission ruins** (a sober stop). The text frames the war from both sides: the measles deaths that preceded the killings, and the volunteers' campaign.
- Fort Walla Walla is an HBC post: bulk trade at Fort Hall's prices (`bulk_food_cents` 4000), care post, crime scene and fort talk like the other company posts. The Aseprite thread supplied the location picture (PR #43).
- Sources: [NPS, Death on the trails](https://www.nps.gov/articles/000/death-on-the-trails.htm), [Oregon Encyclopedia, Cayuse War](https://www.oregonencyclopedia.org/articles/cayuse_war/), [HistoryLink 7807](https://www.historylink.org/File/7807) (Fort Nez Percés / Walla Walla).
