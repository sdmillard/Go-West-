# Food value, physical cargo and human hauling

Implemented October 22, 2026. These are explicit game estimates, with development balance still in progress.

## Two quantities

Ordinary purchased food is a mixed staple basket: one food unit weighs one pound. New meat has **0.5 food units per physical pound**. A 100 lb haul therefore adds 50 food units and 100 lb cargo. Eating 15 meat units removes 30 lb physical meat. This keeps lower-density fresh meat from acquiring the meal value of the same weight of dry staples. Positive small batches round to a whole unit; the saved mass ratio preserves their physical weight exactly.

The conversion is not a claim that every cut or species has identical calories. [FAO's as-purchased food table](https://www.fao.org/4/x9892e/X9892e05.htm) lists wheat flour at 364 kcal/100g and game at 104; fatty/preserved meats differ substantially. The chosen0.5 represents an authored mixed-meat allowance, rather than literal lean-game calorimetry. The180-journey development sensitivity study compares0.35/0.5/0.65;0.5 remains the provisional current value. See `docs/food-decisions-01.json`.

Ordinary hunted meat, camp slaughter and human-derived food use the same conversion. Human-derived food retains its separate provenance, known sources and individually selected eaters. It never enters anonymous ordinary meals. Cargo, discards, cache transfers and saves retain each batch's physical ratio.

## Preservation

One processing day handles up to 100 **physical** lb, after that day's spoilage and meals. Drying retains 80% of food units; salt-assisted drying90%. Salt is five percent of physical input, rounded up to whole pounds. Dried cargo is 35% of the corresponding retained fresh mass. Thus40 physical lb =20 food units, salted to 18 units at 12.6 physical lb, costing2 lb salt. Existing21/30-day storage estimates remain unchanged. Repeated drying is forbidden.

## Health and carrying

Each active traveler contributes their current health fraction times an allowance:50 lb on retrieval jobs;40 lb gross pack capacity on foot. At50 health the contributions are25 lb and 20 lb respectively. A broken leg contributes zero until the condition ends. Dead/departed travelers contribute zero. A full hunting/retrieval trip is capped at 200 lb and actual cargo room. These limits and the linear health response are authored estimates, not recovered classic formulas or measured historical performance.

Hunting and crime retrieval count only companions willing to participate in the relevant action. Walking includes everyone still with the party; personal gear still occupies15 lb per traveler. Recovery changes capacity immediately. Health is read from the actual party ledger, including after loading; no duplicate health/capacity field is saved.

Wagon storage remains2500 lb, with team/load movement rules unchanged. Human health does not reduce wagon volume. When walking, existing supplies may become overweight after injury; the game requires discarding/repacking before further travel and never silently deletes possessions. A party with insufficient capacity even for personal gear may be unable to resume walking until it recovers; walking remains an emergency option.

## Loot location

Scenes declare `wagon_access`. Roadside traders/camps and ordinary private stores currently permit loading alongside a wagon after an open holdup. The Fort Kearny commissary requires carrying supplies away. Quiet theft always requires carrying goods away. This is an explicit encounter abstraction, not a simulation of distances or an assertion about a historical fort plan. The loot screen says whether the wagon is alongside or shows the current willing-helper limit. Stock, per-incident limits and actual cargo room still apply. Money has no new individual weight limit.

## Compatibility and verification

Older batches lacking `mass_ratio` retain their old food quantities and their original fresh1/dried0.35 ratios. Cash, supplies and dates are never retroactively converted. Authentic pre-change save fixtures and invalid-ratio cases are tested. An old walking save may need repacking under current live health rules, without losing goods on load.

The new accounting suite covers mass conservation, preservation preview purity, processing/salt limits, mixed legacy batches, discard, health-scaled hunting/walking, injury exclusion, willingness, location-aware loot, theft, loaded references and recovery. Native supplies UI inspected in `.tools/meat-cargo-preview.png`. Broader journey reports must be read with their own rule signatures: diagnostic05 used100 lb fixed retrieval;06 used an abandoned threshold-health proposal and is **not** the final carrying rule.

The combined-mechanics pilot additionally found and fixed stale meal orders after a diner's death and Hardy resistance preventing an attack already resolved as fatal from matching its death/history record. Damage resistance still applies to ordinary wounds; explicit fatal outcomes are final. Regression checks exercise both cases, including Frail turning a nominal wound into an actual death. Pack previews also include carried bodies/human-derived food, preventing invisible extra cargo.
