# Calorie-anchored recovered game and drying

## Scope and player experience

Spencer asked for plausible calories from an animal's edible yield, the amount a traveler actually recovers, and conversion to food units. This is a focused calibration of game meat and a calorie anchor for the existing abstraction, not a new ingredient-by-ingredient nutrition simulator.

One food unit represents approximately 1,000 kcal. Existing Bare / Meager / Filling settings stay 1 / 2 / 3 units per present traveler per day (about 1,000 / 2,000 / 3,000 kcal). The main display remains food units and familiar ration choices. Calorie totals are available on ledger/ration tooltips; players need not calculate them.

Existing purchased provisions remain an abstract mixed bundle at their existing weight and price. A unit's calorie anchor is not a claim that a pound of flour, meat and greens has the same energy. Individual shop-food recipes and nutritional differences between every food type remain unmodeled. No prices, initial funds, purchase quantities, hauling limits or automated travel policies are changed in this pass.

## Recovered game calculation

1. Existing generated species yield means edible portions, not live animal or whole carcass weight. Do not subtract dressing loss a second time.
2. Existing hunters, health, equipment, cargo and return-time rules determine physical pounds retrieved.
3. Apply species calorie density to those pounds, then convert to food units.

| Animal | Rounded recovered edible energy | Example:100 lb actually retrieved |
|---|---:|---:|
| Deer |550 kcal/lb |55 units |
| Bison |600 kcal/lb |60 units |
| Rabbit |520 kcal/lb |52 units |

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
- [Joel Palmer,1845-46 journal](https://www.gutenberg.org/cache/epub/46906/pg 46906-images.html), May 31 return journey: tongues and marrow bones were eaten. [Lodisa Frizzell's 1852 journal](https://www.gutenberg.org/cache/epub/31449/pg 31449-images.html), June 1: marrow-bone soup accompanied rice. These establish use beyond steaks; they do not establish a universal offal yield or calorie bonus for every emigrant party. Broth water adds volume, not energy.

## Validation plan

Focused tests cover named-species energy, actual mixed kills, physical recovery once, zero drying food loss, tiny batches, no double processing, canonical JSON round trips and an authentic previous-rule save containing preserved meat and a reserved mounted trip. Preserve all old quantities/mass/RNG; apply new calculations only to subsequent harvests.

Run all 73 suites and 24 store +20 current-policy outlaw journeys on frozen final sources. Repeat the unchanged mobile-camp strategy matrix using new development 185000-185003 and held-out 195000-195003 seeds, three professions, May/July, serial/parallel/mobile, same shared equipment and steady pace:144 new-version journeys. Old-version mobile controls use the same seeds and policy. Reports and actual food/time/survival outcomes remain separate from claims of historical accuracy or optimal player behavior. Farmer starts should be harder but viable; do not equalize profession win rates or tune to held-out worlds.
