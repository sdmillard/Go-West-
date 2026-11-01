# River crossings

Spencer noticed (November 1, 2026) that some stops added in October sat on rivers but had no crossing. Every route was checked against where the 1848 road actually crossed water, as opposed to following a bank.

## Crossings added

| Stop | Road | How | 1848 notes |
|---|---|---|---|
| Big Vermilion | main | camp made a crossing | Red Vermillion ford: steep clay banks, rock bottom; rain-fed. No longer a minor camp (minor stops must be camps). |
| Laramie River ford | main, new stop | 35 + 1 miles out of Scotts Bluff to Fort John (36) | Westbound wagons forded the Laramie to reach Fort John on its far bank. Snowmelt-fed: dangerous in the June rise. |
| Weber River crossing | Salt Lake branch, new stop | 85 + 36 of Clayton's 121 miles from Bridger | The pioneer company forded it at the foot of Echo Canyon in July 1847. |
| Bear River crossing | Hensley's cutoff, new stop | 60 + 170 of 230 miles | No ferry until the 1850s; companies forded on a bar or floated caulked wagon beds. The September 15, 1848 wagon opening stays on the Salt Lake edge. |
| White River crossing | Barlow road, new stop | 62 + 8 of 70 miles from The Dalles | Glacial, braided, milky water. The Dalles edge carries `closed_with: barlow_pass`, so the winter closure still shows and applies at The Dalles. |
| Gravelly Ford | South Road | camp made a crossing | Humboldt ford on a gravel bar; snowmelt-fed. |
| Klamath River crossing | South Road | camp made a crossing | Ford over the rock ledge below the lake. |
| Rogue River valley | South Road | camp made a crossing | The road forded the Rogue down the valley before turning north. |
| Umpqua valley | South Road | camp made a crossing | The road forded the Umpqua below the canyon. |

None had a ferry in 1848, so all offer ford and float (walkers swim, riders swim the horses). The route keeps 1,938 main-road miles and every branch keeps its length.

Not crossings: the Little Blue, Deer Creek, the Malheur, the Humboldt above the ford and the Columbia below the Umatilla are followed along a bank or crossed only as creeks. Canyon Creek is its own descent hazard. The Lost River has the natural stone bridge.

The North Platte (upper crossing) now has the Mormon ferry the trail news already spoke of: Brigham Young left ferrymen there in June 1847 and they returned in 1848. $1.50 a wagon, $3 in high water.

## Crossing world by country

`route.json` `crossing_country` picks the banks of the crossing animation (`ui/trail_view.gd` `CROSSING_COUNTRY`): none for the cottonwood prairie (`river_crossing.lua`), `sage` (Humboldt, Snake, Fort Boise, John Day, Deschutes, Bear River), `pine` (Klamath, White River) or `oak` (Rogue, Umpqua). The three regional worlds come from `art/aseprite/crossing_banks.lua` with the same bank outlines. The White River's water is drawn milky grey-green.

## Old saves

Records from the previous rules load through `economy_v1`. `save_store.gd` `bridge()` now walks through new river stops as well as camps, so a party caught mid-road lands on the right piece of the split road (fixtures `tests/fixtures/pre-crossings-*-v1.json`, made on master before this change). A record saved at Big Vermilion's old minor-camp menu loses its spare miles. Tests: `tests/test_crossings.gd`.
