# Calorie-anchored recovered game and drying

## Scope and player experience

Spencer asked for plausible calories from an animal's edible yield, the amount a traveler actually recovers, and conversion to food units. This is a focused calibration of game meat and a calorie anchor for the existing abstraction, not a new ingredient-by-ingredient nutrition simulator.

One food unit represents approximately 1,000 kcal. Existing Bare / Meager / Filling settings stay 1 / 2 / 3 units per present traveler per day (about 1,000 / 2,000 / 3,000 kcal). The main display remains food units and familiar ration choices. Calorie totals are available on ledger/ration tooltips; players need not calculate them.

Existing purchased provisions remain an abstract mixed bundle at their existing weight and price. A unit's calorie anchor is not a claim that a pound of flour, meat and greens has the same energy. Individual shop-food recipes and nutritional differences between every food type remain unmodeled. No prices, initial funds, purchase quantities or hauling limits change. The matched survival-strategy policies remain unchanged; the separate current-outlaw integration policy now bounds consecutive health rests.

## Recovered game calculation

1. Existing generated species yield means edible portions, not live animal or whole carcass weight. Do not subtract dressing loss a second time.
2. Existing hunters, health, equipment, cargo and return-time rules determine physical pounds retrieved.
3. Apply species calorie density to those pounds, then convert to food units.

| Animal | Rounded recovered edible energy | Example: 100 lb actually retrieved |
|---|---:|---:|
| Deer | 550 kcal/lb | 55 units |
| Bison | 600 kcal/lb | 60 units |
| Rabbit | 520 kcal/lb | 52 units |

These are rounded lean-game estimates informed by USDA/ADF&G values, not nutrient assays of the game's randomly generated animals. Edible muscle, usable organs and reasonable recoverable fat are treated as one pool. Nothing adds a second free offal, marrow or broth bonus. The mix does not assume a whole pound of pure fat or that every scrap of every carcass is recovered.

Interactive hunts calculate a mass-weighted calorie density for the actual mixed kill, then apply the retrieved weight once. Companion hunts apply each animal's density to their recovered portions. Unspecified/legacy generic meat keeps a conservative 500 kcal/lb profile so existing generic yields and independent saved batches remain compatible.

The inventory still uses whole food units. Conversion rounds the recovered batch to whole units and keeps a minimum of one for a positive catch; this is a visible game granularity limit, especially for tiny rabbits, not exact calorie conservation at the single-mouthful scale. Physical batch ratios preserve the actual recovered weight. No claim is made that a one-pound rabbit literally contains 1,000 kcal. The calorie helpers retain the unrounded recovered-energy estimate for diagnosis. A future precision change would require updating the shared food ledger, trade, caches and saves rather than silently dropping fractions.

## Drying

Successful drying now retains 100% of the input food value with or without salt. It still spends a real camp day (or a companion's working day), consumes daily meals, respects the physical 100 lb batch cap and cannot rescue meat already spoiled. Salt still costs stock and extends authored storage from 21 to 30 days. Its previous 10% versus 20% automatic food penalty is removed. Tiny batches can no longer disappear solely due to retention rounding.

The existing 35% dried cargo-weight factor is retained as an authored packing approximation. That loss is water weight, not lost calories. Thus 100 lb of retrieved deer produces 55 food units; drying that input, before allowing for processing-day meals, keeps 55 units at 35 lb cargo. Salt does not create calories.

Food may still be lost to existing expiry, discards, illness/events and hauling limits. No new contamination system was added. Produce drying already retains its food value; its separately modeled vitamin-C loss remains. The same no-automatic-loss preservation data also applies to separately tracked human-derived food without mixing those supplies into ordinary food.

New meat/dried mass ratios use canonical decimal precision, and the displayed preserved mass is rounded canonically. This avoids save/load divergence when new calorie ratios or 100% retention create repeating/borderline decimals. Existing saved batches are not retroactively recalculated.

## Sources and interpretation

- [ADF&G Eating Game Meat](https://newsrelease.adfg.alaska.gov/index.cfm?adfg=hunting.eating), also in [Hunt Alaska 2012,p.33](https://www.adfg.alaska.gov/static/home/library/pdfs/wildlife/booklets_books/hunt_alaska_2012.pdf): rabbit 114 kcal/100 g, deer 117-145 depending on species, buffalo 138. These scale to roughly 517,531-658 and 626 kcal/lb. Preparation and fat content vary.
- [USDA FoodData Central, deer raw SR record 173855](https://fdc.nal.usda.gov/food-details/173855/nutrients): commonly tabulated lean raw deer 120 kcal/100 g, approximately 544 kcal/lb. The live detail page was not retrievable during this pass; the rounded deer estimate is also within the accessible ADF&G range. Do not treat this inaccessible page as a separately verified current assay.
- [UW Extension cooked game table](https://uwyoextension.org/uwnutrition/2025-uwyo-extension-hunting-guide/): cooked venison 134 kcal/3 oz, about 715 kcal per cooked pound. Cooked weight and fresh recovered weight cannot be substituted directly.
- [NCOAE trail meal planning](https://ncoae.org/blog/trail-nutrition-planning-and-prepping-backcountry-meals/): modern backpacking planning average 3,500 kcal/day, varying with conditions. The game's ration targets are authored selectable energy levels, not measured 1848 requirements, and do not dynamically add calories for every workload.
- [USDA FSIS jerky](https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/meat-fish/jerky): drying removes moisture and makes meat nutrient-dense/lightweight. [USU drying guidance](https://extension.usu.edu/preserve-the-harvest/research/home-drying-foods) likewise describes calorie concentration per weight. [NCHFP jerky](https://nchfp.uga.edu/how/dry/recipes/jerky) recommends removing fat, so real preparation can lose energy through discarded fat/drippings. There is no universal 10-20% calorie loss established here. Full retained energy for successful drying of the already-defined edible yield is a deliberate game abstraction.
- [Joel Palmer,1845-46 journal](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html), May 31 return journey: tongues and marrow bones were eaten. [Lodisa Frizzell's 1852 journal](https://www.gutenberg.org/cache/epub/31449/pg31449-images.html), June 1: marrow-bone soup accompanied rice. These establish use beyond steaks; they do not establish a universal offal yield or calorie bonus for every emigrant party. Broth water adds volume, not energy.

## Validation and results

Focused tests cover named-species energy, actual mixed kills, physical recovery once, zero drying food loss, tiny batches, no double processing, canonical JSON round trips and an authentic previous-rule save containing preserved meat and a reserved mounted trip. Preserve all old quantities/mass/RNG; apply new calculations only to subsequent harvests.

The final runtime/test checkpoint is 855f8c8. The unchanged mobile-camp strategy matrix uses development 185000-185003 and held-out 195000-195003 seeds, three professions, May/July, serial/parallel/mobile, shared equipment and steady pace: 144 new-version journeys. The previous-version mobile controls at 57171dd use the same seeds and unchanged strategy: 48 control journeys. Reports and actual food/time/survival outcomes remain separate from claims of historical accuracy or optimal player behavior. Farmer starts should be harder but viable; do not equalize profession win rates or tune to held-out worlds.


The final 144 journeys and 24 store + 20 current-policy outlaw integrations completed without source, state, save or policy errors. Compact evidence is in [strategy summary](calorie-food-summary-01.json) and [old/new comparison and archive digests](calorie-food-control-01.json). Full reports are retained in parent .tools/hunting-calorie-*-02.json, with separate hunting-calorie-control-*-01.json old-version archives. Copies were SHA-256 verified against the isolated originals.

| Held-out mobile journeys | Old arrivals / 8 | New arrivals / 8 | Old / new underfed days, summed | Old / new companion food returned |
|---|---:|---:|---:|---:|
| Farmer | 0 | 0 | 235 / 197 | 291 / 376 |
| Carpenter | 6 | 5 | 98 / 106 | 242 / 217 |
| Banker | 7 | 7 | 43 / 43 | 239 / 261 |

Development mobile arrivals were farmer 0 -> 0, carpenter 7 -> 7, banker 7 -> 8. Across all three new strategies there was one farmer development arrival (serial), and none in these held-out worlds. These small fixed-policy results do not establish practical farmer viability, and more delivered food does not guarantee a completed journey. The change combines calorie conversion and preservation retention; do not attribute its outcome solely to one of them.

An initial outlaw integration failed its existing two-month progress check: one scurvy-afflicted survivor stayed at mile 1440 hunting/resting into day 365. The diagnostic trace showed a policy loop, not blocked game controls. Only the current-outlaw integration profile now uses the already-supported two-day health-rest cap (three when critically ill). The archived outlaw runner and the matched survival-strategy policies remain untouched. Its final rerun passes all 20 scenarios. Initial failed report/logs and preliminary -01 campaign reports are kept separately and excluded from the final summaries.

Native UI review confirmed the ledger tooltip appears on hover and stays within the game window. The main ledger still displays units. A label mouse-filter correction was needed to make the new tooltip reachable.

## Ration-label discussion

Spencer considered 800 kcal per unit, then agreed to retain 1,000. Leaving existing daily amounts unchanged at 800 would make Bare / Meager / Filling 800 / 1,600 / 2,400 kcal. A lower unit value also creates 25% more unrounded units from the same recovered animal; it is a mechanical change, not merely a label.

Around 2,000 can be meager relative to sustained walking and trail labor, while 3,000 is a more credible ordinary travel allowance. [REI's modern backpacking guide](https://www.rei.com/learn/expert-advice/planning-menu.html) gives a variable 2,500-4,500 kcal/day comparator, not a measured emigrant requirement. Food needs are not yet individually calculated by body size, occupation or weather.

Current ration effects are indexed game rules: 1 / 2 / 3 units per present traveler; steady-pace ordinary health change -4 / -1 / 0; rest recovery +3 / +5 / +7 before other damage; illness risk multipliers 2.0 / 1.3 / 0.7 and ration-dependent severity rolls. Hunger debt also recovers more slowly at low rations, and scurvy still requires vitamin-C produce.

All 73 Godot suites passed on the final frozen checkpoint, including 29 focused calorie/preservation/save checks. Final log: parent .tools/calorie-final-tests-02.log. The first complete suite run also passed; it preceded the tooltip and integration-policy correction. Player saves and preexisting local farmer diagnostic files were preserved.
