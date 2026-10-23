# Economy, hunting and preservation balance

Historical record: prices, wages and cohort results below precede the [historical economy update](HISTORICAL_ECONOMY.md). That later audit records current figures and comparisons.

October 22, 2026. This pass implements affordable starting staples, revised trail funds, drying and optional salt-assisted preservation. It preserves the earlier [2,700-journey diagnosis](FULL_TRAIL_BALANCE.md) as an archived comparison.

## What the sources establish

- The inspected 1978 BASIC listing uses a $700 post-wagon spending budget and food expenditure units, not pounds. Labels 2660–2690 reward a skilled hunt with 52–58 units; labels 2750–2860 consume 13/18/23 per nominal fortnight. Successful hunting therefore covers roughly two to four turns. No per-batch meat-expiry ledger appears in that listing. These formulas cannot be copied directly into a daily pound-based game.
- The supplied 1985 manual gives banker/carpenter/farmer budgets of $2,500/$1,000/$400 and says hunting costs a day. Those are classic difficulty settings, not evidence for the real wealth of those occupations. [Bouchard](https://www.philipbouchard.com/oregon-trail/hunting.html) explains the 100-lb return cap as a hauling/wastefulness decision; it remains in our game.
- [Palmer’s 1847 guide](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), pp 258–262 of the 1906 reprint, recommends substantial provisions. Five weighed staple categories total 340 lb/adult, before other foods; salt also appears in the list. It quotes Hall/Boise emergency flour at $20/100 lb. These are source context, not a price for our entire mixed-food pool.
- The [BLM education guide](https://www.blm.gov/sites/blm.gov/files/learn_interp_nhotic_edguide.pdf), PDF p 24, contrasts $2/100 lb Independence flour with $20 Boise flour. PDF p 29 includes a later recollection of dried buffalo provisions for an 1845 journey. [Marcy’s 1859 guide](https://www.gutenberg.org/cache/epub/23066/pg23066-images.html), chapter V, describes preservation by drying without requiring salt. That later source supports plausibility, not exact 1848 labor or storage parameters.
- [NPS](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) gives an 1850 outfit/year-of-support estimate of $800–1,200. It includes more than our post-wagon cash and postdates 1848. It supplies broad scale only. None of these references authenticates exact occupation budgets, our 6-cent blended food price,10-cent salt price or preservation yields.

Provenance, local source hashes and date limits are in [the source ledger](../research/ECONOMY_PRESERVATION_SOURCES.json). No modern inflation conversion is used for in-game dollars.

## Shipped economy

| Item | Before | Now |
| --- | ---: | ---: |
| Farmer trail funds | $400 | $600 |
| Carpenter trail funds | $1,000 | $900 |
| Banker trail funds | $2,500 | $1,400 |
| Opening mixed staples | $0.20/lb | $0.06/lb |
| Suggested food | 800 lb | 1,700 lb |
| Suggested care kits | 0 | 2 |
| Suggested salt | unavailable | 10 lb at $0.10/lb |
| Suggested cart total | $380 | $333 |
| Farmer cash after that cart | $20 | $267 |

Wagon and basic household gear are already owned; the store now says so. The budgets are authored cash-on-hand difficulty levels, not annual wages or full historical outfit prices. The blended staple price is deliberately above the cited 2-cent flour example and below mountain scarcity prices. Other old prices are not certified as a reconstructed market. Hall/Boise remain $40/200-lb lots, other bulk posts $60/200 lb, passing wagons $15/50 lb; all transactions still cost a day and meals. Salt resupply is $2/10 lb with $0.50 resale, also a day. No profitable buy/sell loop is introduced.

The suggested cart weighs 2,359 lb against the 2,500-lb guideline; bulk food adds real load and slows progress. It gives 113 upper-bound filling-ration party-days for five adult-equivalent travelers, or 170 at meager rations, before losses/spoilage/delays. It is a large departure reserve, not a whole-road guarantee.

## Preservation in play

After hunting, open **Camp → Preserve meat**. The menu previews the batch, retained meals, salt and one-day cost. Drying works without salt. Salt is an optional improvement, purchased at departure or through trading; it is real carried inventory.

| Authored rule | Dry | Salt-assisted dry |
| --- | ---: | ---: |
| Processing | One camp day, up to 100 lb after meals | Same |
| Retained food value | 80% | 90% |
| Salt consumed | None | Rounded up from 5% of fresh input |
| Storage after processing day | Up to 21 trail days | Up to 30 trail days |
| Physical dried mass | 35% of retained ration-equivalent weight | Same |

Those numbers are explicit game tuning, not a period recipe, food-safety instruction or measured nutrition model. The day’s weather, meals, fatigue and illness still advance. Fresh meat that expires that morning cannot be rescued. Work does not grant people a free rest day; livestock get their normal non-travel recovery. There is no fuel inventory or weather-specific drying failure yet. Preservation does not recover meat left at the hunting site or bypass the 100-lb carry limit.

Food now displays **LB EQ**: staple-equivalent ration pounds. Removing water reduces physical cargo without throwing away the same fraction of meal value. Processing loss separately reduces food value. Example: with 100 fresh pounds and five people on filling rations, the processing day eats 15;85 remain. Drying retains 68 ration-lb weighing 23.8 actual cargo pounds; salt-assisted drying spends 5 lb salt and retains 76 ration-lb weighing 26.6 lb. The rest of the food pool is unchanged. This avoids charging travelers three physical pounds of dried meat for the same meals as three pounds of fresh provisions.

Sooner-expiring tracked food is consumed first. Both fresh and preserved leftovers can spoil. Discards, losses, salt transactions and processing are journaled. The menu separates staples, fresh food, preserved food and salt. New saves retain batch type/expiry and cargo behavior. Verified pre-update saves retain cash, supplies, people, time and RNG, with zero salt added; existing pending quotes are retained, future offers use current prices.

## Matched journey results

3,600 final-rule journeys: ten strategies × three professions × March/May/August departures × forty seeds. Seeds 0–19 were the development sample;20–39 were checked afterward without retuning. No-hunt is a control; each aiming level has fresh-only, drying and salt-assisted variants. All use the same suggested cart, steady pace, public engine actions, actual hunting geometry, care/rest and resupply. The mixed-ration policy eats 2 lb/person/day when well and 3 if any living traveler has a condition or health below 80 internally. It rests below 70 worst individual health or above 50 fatigue when fed. Aim is scripted 35/65/90% center aiming, not a measured human accuracy.

Preservation is attempted before other camp tasks when a usable fresh batch remains. Salt mode attempts resupply before hunting if under 5 lb, with at least$12 cash, and otherwise falls back to unsalted drying. Repeated hunting, preservation, buying and care all cost their real days/meals. Scripted routes and reused seeds make these paired comparisons, not independent historical mortality trials.

Farmer results below count **at least one survivor arriving**; intact means all five arrive. Every cell covers 60 journeys per sample, across the three months.

| Strategy | Seeds 0–19 arrivals | Seeds 20–39 arrivals | Combined arrivals | Combined intact | Mean days among arrivals |
| --- | ---: | ---: | ---: | ---: | ---: |
| no_hunt | 15/60 | 17/60 | 32/120 | 28/120 | 189.5 |
| hunt_35_fresh | 9/60 | 12/60 | 21/120 | 21/120 | 188.0 |
| hunt_35_dry | 38/60 | 37/60 | 75/120 | 30/120 | 244.6 |
| hunt_35_salt | 42/60 | 36/60 | 78/120 | 28/120 | 249.6 |
| hunt_65_fresh | 9/60 | 12/60 | 21/120 | 21/120 | 188.0 |
| hunt_65_dry | 49/60 | 47/60 | 96/120 | 42/120 | 256.0 |
| hunt_65_salt | 54/60 | 48/60 | 102/120 | 42/120 | 257.3 |
| hunt_90_fresh | 9/60 | 12/60 | 21/120 | 21/120 | 188.0 |
| hunt_90_dry | 52/60 | 53/60 | 105/120 | 44/120 | 258.9 |
| hunt_90_salt | 54/60 | 48/60 | 102/120 | 44/120 | 259.4 |

Across both samples at 65%-aim, preserving meat produces a viable farmer policy: fresh-only 21/120, drying 96/120, salt-assisted 102/120 arrivals. Salt does not guarantee a better result in each individual journey: its purchase days, cash and stock compete with other needs. No-hunt also remains winnable at 32/120. These are tested strategies, not optimal play.

Affluent parties usually resupply before they need to hunt, and remain easier. The farmer preservation strategy often takes roughly eight to nine months and loses companions. This proves a playable survival path under the present rules; it is not an historically calibrated duration or casualty distribution. Regional winter dangers, shorter/less wasteful policies and human hunting remain important follow-up work.

## Checks and reproduction

- Full regression suite passes after the feature, including simulation, route, art, UI, motion, health, survival, hunting, provisions, save replay/migration, graves and full-road journeys. The new preservation suite has 48 passing checks, including actual UI button use, store-row geometry, salt resupply, mass/food accounting, expiry, rejected actions, save continuation and old-save migration.
- Both 1,800-journey samples report zero selected invariant/setup errors. This does not turn a simulated loss into a software failure or certify all mechanics/history.
- Rendered store and preservation controls were inspected at native resolution. No human playtest is claimed.

Use the bundled Godot console with `--headless --path . --script tests/full_trail_balance.gd -- --preservation --label=economy-v2`; repeat with `--seed-start=20 --label=economy-v2-holdout`. Set project-local APPDATA as in `test.ps1`. Run `tests/write_economy_report.py` to regenerate this report. Keep earlier raw archives rather than overwriting them.

- [Development 1,800 journeys](economy-v2-preservation.json)
- [Held-out 1,800 journeys](economy-v2-holdout-preservation.json)
- [Rendered store](economy-store.png)
- [Preservation choices](preservation-options.png)

Rules signature: `ce11461cf338ec8e18a8e6287cf2c36dcaa6b40154785f55b1d8d6e637eacede`.

