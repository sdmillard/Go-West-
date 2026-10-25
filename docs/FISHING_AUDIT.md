# Fishing audit: food, time and the next calibration

## Outcome

The current generic fishing model is supplementary food. A lone angler cannot fully feed five people on Filling rations even on the best possible configured day: six catches times four edible pounds times 600 kcal/lb is 14,400 kcal, rounded to 14 food units, versus 15 units needed. Travel reduces the available casts further.

The calorie conversion is functioning; the larger constraint is catch quantity against the cost of another whole party-day. In these bounded journey policies, assigning one companion to fish during an existing stop helped more than adding a separate leader fishing day. This does not establish an optimal family fishing strategy or practical farmer viability.

No game rules were changed by the audit. See [protocol](FISHING_AUDIT_PROTOCOL.md) and [full compact summary with input hashes](fishing-audit-summary-01.json).

## Controlled actual trips

Each cell below uses 100 matched seeds, a healthy leader, five present travelers, actual public-action fishing at 65% scripted successful bite reactions, normal meals and no forced catches. Other companions are assigned Rest. The full controlled study includes all three rations and leader health 100/40: 1,800 trips.

| One-way distance | Transport | Mean casts | Mean edible fish retrieved | Mean food generated | Party food change at Filling |
|---|---|---:|---:|---:|---:|
| At the river | Foot |6 |7.12 lb |4.27 units | -10.73 units |
|4 road miles | Foot |3 |3.72 lb |2.20 units | -12.80 units |
|12 road miles | Horse |2 |2.62 lb |1.57 units | -13.43 units |

Negative stock change includes the family's actual 15-unit daily meal. It is not a calorie loss in the fish. These rows describe extra stationary fishing days, with zero road progress. A human could react more accurately; the six-cast/four-pound hard ceiling still applies. Mounted reach provides access rather than a magical yield multiplier.

Whole-unit rounding's aggregate energy bias in these healthy cells was approximately -0.05%, -1.43% and -0.13%. It is not the main cause of low catch food in this sample. Tiny catches still have the previously documented minimum-one-unit approximation; fractional species weights would require attention to that granularity.

## Full journeys

144 journeys: baseline / leader fishing / shared-stop companion fishing, three professions, May/July, four development seeds and four separate held-out seeds, matched standard outfit and costs. Normal mobile hunting, camp priorities, nutrition, weather, crossings and funds remain active.

| Held-out policy | Farmer arrivals /8 | Carpenter /8 | Banker /8 | Farmer underfed days, summed |
|---|---:|---:|---:|---:|
| Baseline, no fishing |0 |7 |8 |203 |
| Leader fishing |0 |7 |8 |223 |
| One shared-stop fisher |1 |7 |8 |198 |

Held-out farmers made 10 leader fishing trips under the leader policy. Support fishers returned 203 food units across the eight farmer runs. Development farmer arrivals were0/8 for every policy. The new held-out support arrival has no paired baseline arrival, so it supplies no completed-route time-saving estimate. Small cohorts, one scripted outfit and a fixed policy do not establish robust viability.

The leader policy attempts each named river at most once; it is not a plan to camp indefinitely while fishing. Support protects existing nurses, patients, produce and drying priorities, then replaces one hunt helper. That helper's lost hunting-haul contribution is real. It adds no extra fishing stop.

This audit does not test every possible family assignment. Several people fishing together, deliberate stockpiling, adaptive equipment changes and expert play may differ. Access is currently road distance to known river endpoints, so nearby water along unmodeled stretches is missed. Access counters are sampled once before a daily action, not a complete opportunity log; the raw bad-weather counter includes weather snapshots even where no fishable site would otherwise be in reach.

## Calories: verified raw edible weight

One food unit remains approximately 1,000 kcal. Current generic fish are 600 kcal per edible pound, or 0.6 unrounded units/lb. Existing generated pounds already mean edible catch; do not subtract a dressing percentage again.

| Reference food | kcal /100 g raw edible portion | Approximate kcal / edible lb | Unrounded units / lb |
|---|---:|---:|---:|
| Wild channel catfish |95 |431 |0.431 |
| Wild rainbow trout |119 |540 |0.540 |
| Mixed trout |148 |671 |0.671 |
| Chinook salmon |179 |812 |0.812 |

Catfish and trout values come from [USDA Standard Reference 28, fish tables](https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR/SR28/reports/sr28fg15.pdf), NDB 15010, 15115 and 15114 (PDF pages 130, 577 and 565). These are amounts per 100 grams of edible food, not yields from whole fish. The alternate 80400535 USDA PDF path timed out; the 80400525 report was accessible. Chinook comes from [NOAA's raw 100-g nutrition table](https://www.fisheries.noaa.gov/species/chinook-salmon). Pound conversion uses 453.59237 g/lb. Do not substitute cooked-ounce values for raw recovered weight.

These references support 600 as a rough generic compromise, not the correct value for every species, river or season. No species-specific calorie profiles are implemented by this audit.

## Next fishing calibration, then livestock

Spencer proposed per-river weighted fish lists and species weight ranges. That is the appropriate structure for the next calibration:

1. Research native/historically present fish at each accessible water, including seasonal abundance and the limits of emigrant hook-and-line equipment. Do not populate 1848 waters from modern stocked-fish lists.
2. Define a weight distribution per fish type, with occasional larger specimens. Distinguish whole-catch weight, edible yield and actually retrieved portions.
3. Apply the species' raw-edible calorie density and sum the recovered catch before food-unit rounding. Avoid giving a small fish a full meal solely through per-fish rounding.
4. Compare useful food per worker-day and extra party-day, including travel, carrying, other camp jobs and ammunition saved. Larger or richer fish should be localized rather than uniformly increasing every river's yield.
5. Repeat matched journeys on fresh worlds after those rules change.

Livestock follows: dairy cows, goats and chickens. Research lactation, animal condition, grazing/water, feed, labor, production seasonality, spoilage, transport and losses before setting outputs. Trade goods, pelts and personal heirlooms remain separate proposed features.

## Verification and provenance

Frozen audit commit 8ef1bf6 passed all 75 Godot suites, including 46 new observer/policy checks. Leader and companion observation preserves actual state and random streams; off-policy public decisions match the existing mobile strategy. All 144 full journeys and 1,800 controlled trips finished with zero source, state, save or policy errors. Final output copies were SHA-256 verified against their isolated originals.

Full reports are parent .tools/hunting-fishing-audit-*-01.json and .tools/fishing-yield-audit-01.json. Final test log: .tools/fishing-audit-final-tests.log. The summary validates declared cohorts, complete pairings, identical starting resources/settings and source/rules fingerprints. Tests, data collection and summary are reproducible via tests/fishing_campaign.gd, tests/fishing_yield_audit.gd and tests/summarize_fishing_audit.py.

Simulation and data are unchanged from the shipped artwork version. Earlier 44 gameplay integration runs are not claimed as new runs. Player saves and the preexisting farmer debug files are preserved.
