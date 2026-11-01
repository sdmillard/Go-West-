# New stops, the Salt Lake road and Native nations on the map (October 31, 2026)

Spencer asked for more stops, a Salt Lake branch in the same PR, and the Native nations on the trail map with a light marker where territory starts and ends.

## Main-road stops

Each new stop sits at one of Palmer's own named camps (`research/PALMER_DISTANCE_TABLE.json`). Each old leg is split at a row boundary, so `source_rows` and `source_table_rows` still cite the guide. The main road is still 1,938 guide miles.

| Stop | Between | Palmer rows to the stop |
| --- | --- | --- |
| Big Vermilion | Kansas River to Big Blue | 6-9 (79 mi), then 10-11 (14) |
| Little Blue River | Big Blue to the Platte | 12, 14, 15 (70), then 16-17 (73) |
| Horse Shoe Creek | Fort Laramie to the North Platte crossing | 29-32 (36) |
| Deer Creek | the same road | 33-39 (65), then 40 (25) |
| Willow Spring | North Platte crossing to Independence Rock | 41-43 (23), then 44 (22) |
| Bear River valley | Bridger (60-65, 76) and Greenwood's cutoff (53, 64) rejoin here | then 66-72 (60) to Soda Springs |
| American Falls | Fort Hall to the Three Island crossing | 79-80 (18) |
| Raft River | the same road; the California road turns off | 81-82 (23) |
| Salmon Falls | the same road | 83-89 (98), then 90 (23) |
| Malheur River | Fort Boise to Burnt River | 94 (15), then 95-96 (28) |
| Columbia River at the Umatilla | the main road (105, 44) and the Walla Walla road (25, authored) rejoin here | then 106 (33) to the John Day |

All of them are `camp` stops. They add no new river crossings, so crossing risk is unchanged. Terrain and hunting region come from the stop before each one.

### Minor camps keep the day's travel

Reaching any stop ends that day's travel, so on average each extra stop would cost about half a day. The first balance run showed it: 12 more stops added about a week, and late June and late July arrivals fell from 23 and 22 of 36 to 12 and 12.

To keep that from happening, the 11 road camps are marked `"minor": true`. When a party reaches one partway through a day, the stop menu shows "about N more miles today" on the leave choice. If the party leaves at once, it makes those miles before camp (`day_miles_left`/`arrived_day` on the stop menu). A party that rests, trades or does anything else that takes the day starts fresh tomorrow.

Old stops and Salt Lake are not minor, so the tuned journey length (Spencer: don't shorten it) is unchanged.

## The Salt Lake road

- **Fort Bridger to Great Salt Lake City, 121 miles.** William Clayton's *Latter-Day Saints' Emigrants' Guide* (1848) gives about 121½.
- **Salt Lake to the Raft River, 230 miles.** This is an authored estimate: about 180 miles on the Salt Lake Cutoff to the California road near the City of Rocks, then about 50 down the Raft River valley.
- **The longer way.** The branch is about 112 miles longer than the road through Fort Hall.
- **When wagons can go.** Samuel Hensley's pack train broke the cutoff in summer 1848. Returning Mormon Battalion men made it a wagon road from September 15, 1848. The edge carries `"wagon_opens": "1848-09-15"`, checked by `wagon_road_unopened()` in the engine. Before that date a wagon party waits in the valley. Walkers and riders can go at once.
- **Salt Lake itself.** The town is short of food after the 1848 cricket year, so bulk food is dearer than at Fort Hall (`bulk_food_cents` 4500 against 4000). Its trading house is a `store` in `crime_scenes.json`, with more people about, so escape capture is 0.25. There are three days of hired work, at 3 workers a day. The valley is `open` for settling and has canyon timber for cabins.

## Native nations on the map

- **Labels.** `map.json` has `nations`, a label spot for each people named per stop in `cabins.json` `settle.peoples`. The settle rules and the map read the same list, so they cannot disagree. A test checks that every named people has a label and every label is a named people.
- **Border ticks.** `ui/map_view.gd` `draw_nations()` draws a light dashed tick across the road wherever the people changes from one stop to the next. Leaving open ground or a post also counts as a change. These ticks are the game's rule boundaries, not surveyed 1848 borders, which overlapped and moved.
- **Readability.** Names are drawn at screen size in dark plum on a pale paper halo, so they read over hills and rivers (Spencer, November 1, found the first purple labels hard to read and cluttered). At 1x only the larger peoples along the road are named; the smaller ones listed in `map.json` `nations_zoom` (the Columbia peoples, the Shawnee by Independence and the Applegate peoples) appear from 2x. Each name may slide a few pixels off its spot to stay clear of the roads, stops, map labels, the paper tags and other names (`draw_nation_names` in `ui/map_view.gd`); a name with no clear spot waits for more zoom. The label spots are the same as before, so the names still sit in each people's country along the road.
- **Tooltips.** Hovering a stop shows "<people> country.".

## Saves

Records from before this change are walked onto the split roads when loaded (`save_store.gd` `upgrade_split_roads`):

- New stops are filled into the route behind the party.
- A party caught mid-leg is placed on the right piece of the old road.
- East-west trail history is spread over the pieces.

The total journey length does not change.

## Art

All 12 new stops have Aseprite arrival scenes (`art/aseprite/scenes/<stop>.lua`), with winter and autumn versions. The six timber stops have cabin spots. `awaiting_art` is empty; it stays available for stops added later.

## Balance, before and after

These are play-style bots (`tests/play_style_baseline.gd`), 36 journeys per style: 12 seeds × farmer, carpenter and banker. Bots stay on the main road.

| Style | Before | After |
| --- | --- | --- |
| careful April | 28 | 29 |
| careful May | 24 | 25 |
| fighter | 29 | 30 |
| petty theft | 26 | 26 |
| criminal | 22 | 26 |
| horses | 11 | 14 |
| late June | 23 | 19 |
| late July | 22 | 17 |
| on foot / reckless | 0 / 0 | 0 / 0 |

Late starts are the most sensitive to the random draws, so they were rerun on a second seed set (91000-91011):

| Style | Before | After |
| --- | --- | --- |
| late June | 19 | 23 |
| late July | 13 | 21 |

Over both sets (72 journeys each), late June is 42 before and 42 after, and late July is 35 before and 38 after. The journey's pace at each mile matches master.

The first try, without minor camps, dropped late June and late July to 12 each. That is why the minor-camp rule exists.

The Applegate South Road (November 2026) is documented in [APPLEGATE_ROAD.md](APPLEGATE_ROAD.md).
