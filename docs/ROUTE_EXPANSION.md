# The continuous road to Oregon City

The playable overland corridor now connects **36 stops from Independence to Oregon City**, using **1,938 reported guide miles**. It follows the southern road via Bridger and the Barlow Road. Reaching the Platte is now a stop, not a false arrival in Oregon. Every stop has an original 432 × 150 pixel background; three additional travel landscapes change the scenery in mountains, dry country and western forest. See `route-gallery.png`, `western-preview.png` and `oregon-arrival.png`.

## Historical distance ledger

The principal source is [Joel Palmer's 1847 guide, table of distances, pp. 277–281 of the 1906 reprint](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#TABLE_OF_DISTANCES_FROM_INDEPENDENCE). The extracted factual table is archived as `research/PALMER_DISTANCE_TABLE.json`. In route edges, `source_rows` contains mileage contributions; `source_table_rows` identifies extraction row IDs. They are different fields. Selected contributions sum to 1,938 via the southern fork and wagon road; this is neither a modern GPS survey nor a claim that every 1848 wagon followed the same road. Palmer's narrative totals and his detailed table are not perfectly interchangeable.

Two subdivisions are explicitly authored: Fort Kearny is allocated 10 miles into the existing Platte-to-upper-South-Platte interval, and the final 160-mile Barlow-road aggregate is split 70/10/55/25 among the Mount Hood, Laurel Hill, Eagle Creek and Oregon City stops. Those subdivisions support playable stops; their exact cumulative guide positions are **estimates**, not additional primary measurements. The aggregate period distances are preserved. The upper South Platte crossing is the selected crossing in that corridor; the game does not require crossing at both lower and upper options.

| Stop | Cumulative guide miles | Role |
| --- | --- | --- |
| Independence | 0 | town |
| Elm Grove | 33 | camp |
| Wakarusa Creek | 53 | river |
| Kansas River | 81 | river |
| Big Blue River | 174 | river |
| Platte River corridor | 317 | camp |
| Fort Kearny site | 327 | camp |
| South Platte crossing | 482 | river |
| Ash Hollow | 502 | camp |
| Courthouse and Jail Rocks | 544 | camp |
| Chimney Rock | 560 | camp |
| Scotts Bluff / Robidoux route | 585 | camp |
| Fort John / Laramie | 621 | fort |
| North Platte crossing | 747 | river |
| Independence Rock | 792 | camp |
| Devil's Gate | 797 | camp |
| South Pass | 901 | camp |
| Little Sandy / southern road | 926 | camp |
| Green River crossing | 962 | river |
| Fort Bridger | 1015 | fort |
| Soda Springs | 1151 | camp |
| Fort Hall | 1213 | fort |
| Snake River / Three Island area | 1375 | river |
| Fort Boise / Snake crossing | 1491 | river |
| Burnt River | 1534 | camp |
| Powder River valley | 1588 | camp |
| Grande Ronde valley | 1620 | camp |
| Blue Mountains | 1647 | camp |
| Umatilla River | 1663 | river |
| John Day River | 1740 | river |
| Deschutes River | 1762 | river |
| The Dalles | 1778 | camp |
| Barlow Road / Mount Hood | 1848 | camp |
| Laurel Hill | 1858 | camp |
| Eagle Creek / Foster country | 1913 | camp |
| Oregon City / Willamette Falls | 1938 | destination |

## Comparison with the classic game

[Bouchard's firsthand geography account](https://www.philipbouchard.com/oregon-trail/real-geography.html) documents 18 landmarks, with branching paths so a normal journey visits fewer. Our comparisons use that account, not reverse-engineered 1985 source. BASIC remains useful for survival relationships but supplies no named intermediate route.

| Classic landmark or choice | This build |
| --- | --- |
| Independence, Kansas and Big Blue crossings | Retained; earlier guide-based opening mileage remains |
| Fort Kearney | Fort Kearny site, with a pre-June 1848 camp scene and a construction-era interpretation |
| Chimney Rock | Retained; Courthouse Rock, Ash Hollow and the Robidoux approach add context |
| Fort Laramie | Retained as the private adobe Fort John in 1848 |
| Independence Rock and South Pass | Retained; Devil's Gate is also a stop |
| Green River / Fort Bridger choices | Southern road through both is the main road; Greenwood's Cutoff is a choice at the Little Sandy (see [Route branches](ROUTE_BRANCHES.md)) |
| Soda Springs, Fort Hall, Snake crossing and Fort Boise | Retained, with a second Snake crossing at the old Boise post |
| Blue Mountains / Fort Walla Walla choice | Direct Umatilla corridor from Palmer; Walla Walla detour remains unimplemented, not declared historically nonexistent |
| The Dalles, Barlow Road / Columbia rafting | Barlow wagon road is the main road; a Columbia raft with a Cascades portage is a choice at The Dalles (see [Route branches](ROUTE_BRANCHES.md)) |
| Willamette Valley endpoint | Oregon City beside the Willamette, with named survivor and supply results |

This completes one supported overland itinerary, **not all classic branches or all historic alternatives**. There are no false buttons promising an unimplemented alternate route. Whitman Mission is not offered as a functioning 1848 resupply station.

## Stops, services and hazards

Fort John, Bridger and Hall offer bulk post trading; Boise combines post trading with its departure crossing. Post visits keep their own location background behind the service window and retain the unresolved stop on return. The 200 lb staple lot takes one day, with ordinary meals consumed. Hall and Boise use Palmer's earlier $20-per-hundred flour quote as an explicit reference; this is not a verified 1848 price for every food. Other post prices are game tuning. Passing-wagon trade and medical availability remain broad game abstractions rather than a measured daily market.

Fort Kearny is not a guaranteed stocked shop: [NPS dates construction to June 1848](https://www.nps.gov/places/000/fort-kearny-state-historical-park.htm). The early scene is used for arrivals before that month; later arrivals see a small sod/adobe construction camp, without the familiar later stockade. [NPS distinguishes Fort John's adobe trading era from the army post acquired in 1849](https://www.nps.gov/fola/faqs.htm?fullweb=1). [Robidoux Pass was used before the later Mitchell Pass wagon road](https://www.nps.gov/places/robidoux-pass.htm), so no later road through that notch is painted.

The Barlow offer uses the [Oregon Historical Society's early charter tariff](https://www.oregonencyclopedia.org/articles/barlow_road/): $5/wagon plus $0.10/head of livestock, represented by owned oxen. It is a reference tariff, not a reconstructed day-specific 1848 receipt. The offer updates when livestock changes. Laurel Hill offers a two-day controlled descent, or one hurried day with an authored 25% cargo/injury risk. Actual losses are clamped to inventory and recorded. The period danger is grounded in the road history; the probability and losses are gameplay choices.

Trail notes at selected stops provide advice without spending days or pretending to quote a named historical person. New river stops use the existing ford/float/weather mechanics. Small streams and every historical crossing are not individually simulated. Western hunting pools change with the corridor and stop offering bison beyond the selected high-country region; weights and absence in a particular pool are authored guidance, not reconstructed wildlife census data.

## Full-journey tuning and verification

Opening-only movement tuning made initial complete runs take about 263–289 days. That failed the intended travel scale. Nominal player paces are now 22/26/30 before weather, team condition, fatigue, load, terrain and landmark clipping. Terrain factors are mountains 0.8, forest 0.9 and dry country 0.95. These are coupled game parameters, **not historical unmodified wagon speeds**. The isolated legacy BASIC-style 102-mile fixture retains its original values.

Twelve real-engine test journeys use seeds 0–5, March and May departures, banker budgets, five travelers, six oxen, 1,700 lb starting food, clothing, 200 bullets, three spares and four kits. The policy fills rations, travels steadily, rests below 75 party condition or above 50 fatigue, and buys bulk food at posts below 1,250 lb. It deliberately represents a well-funded, prepared party, not every occupation or a human playtest.

All twelve reached Oregon City. March runs took 184–198 days (mean 189.8) with 30/30 travelers surviving; May runs took 187–193 days (mean 190.2) with 29/30 surviving. Actual moving-day averages were about 12.9 and 13.3 miles/day. [NPS gives a broad 10–15 miles/day and four-to-six-month context](https://www.nps.gov/jeff/planyourvisit/overland-wagon.htm); our roughly six-month sample is a comparison, not calibration to a historical population. Lower-budget expeditions, late departures, preservation, fine-grained climate and complete historical pricing need further balancing. Raw policy results are in `full-route-runs.json`.

The new suite exercises the actual full road, bulk trading, advice, toll changes after buying livestock, controlled descent, regional hunting pools, endpoint time locks, early Kearny presentation, post-window backgrounds and western save/load continuation. The previous 317-mile chapter remains an explicit regression fixture, not the player route. A verified prior opening-save fingerprint is migrated: a party saved at the old Platte completion resumes toward Kearny without spending time or losing supplies/health/history. Unknown rule mismatches still fail safely. See `data/save_migrations.json` and the real previous-version save fixture.

## Remaining depth

Columbia transport/portages, northern road branches, a Walla Walla detour, more animals and landmark conversations remain future work. The weather model is seasonal/terrain-based game tuning, not a fitted historical climate series. Imported reference illustrations remain ignored research files; runtime artwork is original. This is a complete playable corridor with an ending, not a claim that all systems or every 1848 detail are finished.
