# The Applegates' South Road (November 1, 2026)

Spencer asked for the Applegate Trail as a branch. In 1846 Jesse and Lindsay Applegate and Levi Scott opened it to keep Oregon emigrants off the Columbia. It also kept them away from the British posts. In-game it leaves the main road at the Raft River and rejoins it at Oregon City.

## The road

The branch has 15 stops, all `camp` stops. Distances are authored estimates from modern trail guides (Trails West, NPS California and Applegate trail maps), checked against figures from 1847-1848 diaries and letters (Hulin, Olmsted, Huber, W. S. Adams). Every edge carries an `allocation_note`.

| Stop | Miles from the last | Notes |
| --- | --- | --- |
| City of Rocks | 50 | Up the California road from the Raft River |
| Humboldt Wells | 100 | Granite Pass, Thousand Springs |
| Gravelly Ford | 90 | Down the Humboldt |
| Applegate turnoff (Lassen Meadows) | 120 | Raids on the stock |
| Black Rock | 58 | **Waterless**: Antelope and Rabbit Hole springs are poor |
| High Rock Canyon | 40 | Raids |
| Fandango Pass | 55 | Raids; snow November to March; steep descent |
| Goose Lake | 20 | Raids |
| Tule Lake | 60 | Raids (Modoc country) |
| Klamath River crossing | 45 | Raids |
| Green Springs Mountain | 25 | Cascade summit; snow December to March; descent |
| Rogue River valley | 30 | Raids |
| Canyon Creek | 85 | Raids; the canyon is let down like a descent |
| Umpqua valley | 35 | |
| Head of the Willamette | 70 | Open to settlers (Skinner's claim) |
| Oregon City | 110 | Down the valley |

That is 993 miles from the Raft River, against 684 by the Columbia, or 309 more. Huber (1847) and Adams (1848) both put it about 300 miles longer. The main road is still 1,938 miles. The longest way, by Salt Lake and the South Road, is now 2,359.

## Rules

- **The fork.** At the Raft River the choice reads "Take the South Road to Oregon … about 300 miles longer". After August 31 it adds "late in the year for this road; snow on the passes from November" (edge field `late_after`, checked by `road_late()`). The Raft River's trail notes explain the trade: it avoids the Blue Mountains, the Cayuse country and the Barlow toll, but it has no posts or traders, the dry drive, the raids, and the canyon.
- **No traders.** Stops flagged `remote` have no passing traders (`context.market()` returns `remote`). The status line reads NO TRADERS ON THIS ROAD. Emigrant camps can still appear.
- **Raids** (edge hazard `raids`, `RAIDS` in the engine). Trail events are 1.25 times as likely, and stock losses twice as heavily weighted. The new event **Arrows in the night** (`arrows_in_the_stock`) kills one ox and wounds the rest (-10 team condition). It needs at least two oxen. The player can butcher the dead ox (a day, no bullet), rest the wounded oxen, or push on. A night guard or a watchdog cuts the chance, as for horse thieves. Sources: in 1847 Hudson's company lost 16-17 head near Goose Lake, and Shasta men shot horses in a Rogue valley camp.
- **Relief from the settlements** (`RELIEF`). This is the 1846 story: Thomas Holt's party brought flour and cattle to the late companies in the Umpqua. It happens once per journey, in the Rogue valley, at Canyon Creek or in the Umpqua valley, from October to March, and only for a party in need: less than ten days of food, or a failing team. Settlers bring 40 lb of flour a traveler. If the team is short of four oxen or worn out, they also bring fresh oxen, which raises the team's condition.
- **Peoples on the map.** Western Shoshone, Northern Paiute, Pit River, Modoc, Klamath, Shasta, Takelma and Umpqua (`cabins.json` `settle.peoples`, `map.json` `nations`). The Northern Paiute label moved south, between the Malheur and Black Rock.
- **Timber.** Cabins can be built at City of Rocks (juniper), Fandango Pass, Goose Lake, Klamath, Green Springs, the Rogue, Canyon Creek, the Umpqua and the head of the Willamette.

## Fixes found along the way

- **A waterless leg hurt a party that hadn't set out on it yet.** Thirst, the loss of grass, dog strain and the hide-dressing block all applied whenever the current edge was waterless, including a party sitting at leg mile 0. A new `on_dry_stretch()` makes them apply only out on the leg, or on the day the party sets out on it. A camp on the stream before the drive keeps its water.
- **Old saves.** PR #152 changed `provisions.json` without whitelisting the rules version before it. Both the post-#150 rules (`a258c092…`) and the post-#152 rules (`345bc2eb…`) are now in `economy_v1`, so Spencer's saves from those versions load.
- **Garbled labels.** The Greenwood and Walla Walla choices showed "Â·" and "Ã©". They are fixed in `route.json`.
- **Play bots.** They no longer rest in a desert or in snow, where resting heals nothing. A team that collapses on a dry stretch leaves the wagon and walks out. Bots take the South Road only while the fork says it is not late.
- **Study flags.** `tests/play_style_baseline.gd` takes `--branch=TEXT`, `--team-rest=N` and `--pace=N`. With `--branch=south road` the bot stocks 1,600 lb of food at the last posts.

## Balance

These are play-style bots taking the South Road (`--branch="south road"`), over two seed sets (90000 and 91000), farmer, carpenter and banker. Only parties that reach the fork by August 31 take it.

| Careful April parties | On the South Road | Arrived |
| --- | --- | --- |
| Before the relief party | 67 | 15 (22%) |
| With the relief party | 67 | 19 (28%) |
| With relief, driving at a faster pace | 70 | 28 (40%) |
| Main road, for comparison | 36 | 29 (81%) |

Careful May parties reach the fork later, and 3 of 28 arrive.

The time is the killer. At the bots' careful pace they reach the turnoff in September, Fandango Pass in late October, and the Rogue in November. That is close to the 1846 companies, who did not reach the Willamette until November and December. The South Road is a gamble that rewards an early start, a strong team and a lot of food, and a party that drives hard. The main-road styles are unchanged within noise.

Spencer has a decision card open: keep it a gamble, keep the relief parties (built, and recommended), or soften the road.
