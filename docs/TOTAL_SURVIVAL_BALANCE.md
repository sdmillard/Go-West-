# Total survival balance check

October 24, 2026. **The game is winnable, but a full historical/balance sign-off would be premature.** Long elapsed journeys, weak walking capacity, nutrition recovery and low-budget pack provisioning remain the largest problems. The animal correction in this pass is a better-supported rule, not a general increase in survival.

Implementation checkpoint: e517454. Rules fingerprint:
6927c03c33aba3ab718e02606b39caa53355a215aa4182c564764aa580dc5403.
Baseline game: master 3b68496, with the same corrected study policy frozen at b211d72.

## Scope and evidence

The [published audit](balance-total-02-summary.json) contains **4,428 complete source-frozen scenarios**, zero selected state/save/setup/policy errors, scenario results, cohort configurations and hashes of every original report. Its [protocol](../research/TOTAL_BALANCE_PROTOCOL.json) names seeds, comparisons and exclusions. The [source ledger](../research/TOTAL_BALANCE_SOURCES.json) identifies historical observations, contemporary measurements and limitations.

This checks food, preservation, forage, vitamins, health, rest, weather, travel time, animal work, load, money, wages, companion composition, crime consequences and route branches together. It is neither an exhaustive search of all player choices nor a historical population study.

| Cohort | Before | After / final |
|---|---:|---:|
| Full mechanics development: 3 professions, 3 departure months, 5 rosters, 9 strategies, 2 seeds | 810 | 810 |
| Transport development: 3 professions, 4 modes, 3 months, hunt/no-hunt, 2 seeds | 144 | 144 |
| Controlled emergencies: 4 modes, 3 health cases, 3 distances, 2 months, 4 seeds | 288 | 288 |
| Fresh full mechanics validation, 4 seeds | â€” | 1,620 |
| Fresh transport validation, 4 seeds | â€” | 288 |
| Main / Greenwood / Columbia route sensitivity | â€” | 18 |
| 35% / 65% / 90% scripted aiming sensitivity | â€” | 18 |

Development full-mechanics seeds: 71000-71001; transport: 72000-72001. Fresh full-mechanics seeds: 74000-74003; transport: 73000-73003. Emergencies: 75000-75003; routes: 76000-76001; aiming: 77000-77001. No production tuning followed the fresh validation sample.

The broad cohort includes ordinary, two paid, Frail, selected three-special/one-flaw and generated rosters. Policies include salted preservation, unsalted drying, steady pace, no hunting, theft, robbery, already-dead remains, predation and recruitment. Selected traits obey creation limits. Every journey uses real outfitting, actual cash, stock, illness, weather, events and public actions; aiming is an explicit bot assumption.

The emergency snapshots declare location and starting health; they are not fictitious full journeys from Missouri. Only their initial preparation is controlled. Subsequent actions pay actual time and supplies. All successful emergency cases kept the five original travelers.

## Corrections made

**Animal work:** a lightly loaded train at cautious pace can maintain condition on good grazing. Full loads, haste, poor forage, waterless stretches and winter still impose strain. Faster pack walking now costs condition too. Doubling remains strenuous regardless of baggage. Rest recovery is capped by seasonal grazing, so winter does not grant the same recovery as summer.

The load threshold is an authored 50% of the current gross allowance, not a measured biological boundary. Animal sizes, rider body mass, tack mass and actual grazing hours are not individually modeled. Carrying limits and prices have not changed.

**Simulation policy:** worn oxen with stock still present now receive an actual recovery day rather than an endless no-time warning loop. A just-fed walker can leave camp after a successful hunt instead of repeating hunts to reach a food reserve that cannot fit in the packs. Those are study-player corrections, not new player restrictions or free supplies.

Both production versions use the same corrected decision/observer sources. The initial old-actor pilot (540 farmer journeys and 288 transport journeys, plus a small diagnostic) contained stalls and is excluded from the formal totals. Its raw evidence remains local.

The immediately preceding genuine packer save migrates without changing cash, inventory, condition, time or random streams. Older migration fixtures still pass. The [previous hunting-meal and gradual-shortage fixes](EMERGENCY_TRAVEL_CALIBRATION.md) remain in place.

## Historical and contemporary checks

| System | What the evidence supports | Current assessment |
|---|---|---|
| Wagon load and movement | [NPS](https://www.nps.gov/jeff/planyourvisit/overland-wagon.htm) gives a broad 2,500 lb supply guideline, 10-15 miles/day and four-six months. | Load and moving-day speed are defensible. Total elapsed journeys are often substantially too long. |
| Starting provisions | [Palmer's 1847 guide](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html) lists 340 lb/adult across flour, bread, bacon, rice and sugar, plus other supplies. | 1,700 starting staple units for five matches only those five weighed components. It is not a complete menu or an exact family calorie budget. |
| Deer yield | [Ohio's measured 115-deer sample](https://dam.assets.ohio.gov/image/upload/ohiodnr.gov/documents/wildlife/wild-ohio-harvest-community/Venison%20Yield.pdf) averaged 52.19 lb boneless venison. | Current 42-85 usable lb is plausible in scale. The Ohio sample is not a universal 1848 mule-deer yield. A successful kill now feeds its hunting day before packing. |
| Food energy | [NDSU's game-meat publication](https://ucanr.edu/sites/default/files/2020-09/335733.pdf) distinguishes lean venison from calorie-dense staples and fats. | 0.5 food units/lb meat is an abstraction. A unit does not have a rigorously equal calorie or macronutrient content across every food. Do not describe lean meat alone as a complete diet. |
| Foraging | [Primary subsistence research](https://doi.org/10.1126/science.abf0130) and [GPS research](https://pmc.ncbi.nlm.nih.gov/articles/PMC8060163/) show skill, effort, ecology, cooperation and variable returns. | Current berries/greens supplement calories and vitamins. They do not represent a complete hunter-gatherer food system. No guaranteed daily kill or harvest is justified. |
| Preservation | Period guides describe dried provisions; modern extension guidance emphasizes cooling, heat and clean handling. | Salt/yield/mass/time tradeoffs work mechanically. Fixed two-day raw meat and 21/30-day dried-meat lifetimes are game abstractions, not food-safety guidance or recovered period assays. |
| Scurvy | [NIH ODS](https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/) ties it to sustained vitamin C deficiency and variable body reserves. | Produce actually eaten matters; ordinary meat does not clear deficiency. The game's 45-day onset gate, half-pound produce serving, quarter dried retention and binary daily recovery credit are authored and need further calibration. |
| Animal condition | [Marcy 1859](https://www.kancoll.org/books/marcy/machap03.htm) describes sustainable moderate work with good grass/water and attention; [current extension guidance](https://extension.rutgers.edu/horse-pasture-management) confirms substantial forage requirements. | Corrected unconditional work loss and season-independent rest. Coarse habitats and a shared condition value remain a simplification. |
| Pack loads | Marcy recommends 125 lb for a long mule journey; Palmer reproduces regional examples of 200 lb pack horses with rest. | Evidence differs by purpose and conditions. Current 175/200 lb animal allowances are generous, not demonstrated universal safe loads. Reducing them alone would worsen existing provision failures. |
| Walking capacity | [Load-carriage experiments](https://pmc.ncbi.nlm.nih.gov/articles/PMC3922835/) support a load cost. | They do not validate linear health scaling, fixed personal gear or the broken-leg cutoff numerically. Current weak-walker failures are still serious. |
| Economy and wages | The [earlier federal wage scan](https://www2.census.gov/prod2/decennial/documents/1850c-05.pdf) distinguishes boarded and unboarded labor; Palmer documents costly emergency flour. | Prices have period anchors; exact store stock, margins, trait premiums and profession budgets remain authored. No inflation shortcut or invented occupational wealth distribution is used. |
| Mortality and crime | [NPS's multi-decade synthesis](https://www.nps.gov/articles/000/death-on-trails.htm) emphasizes disease, accidents, drowning and weather, with murder comparatively rare. | These game scenarios deliberately include late starts and repeated predation. Their losses must not be calibrated to one aggregate historical mortality percentage. Exact crime and combat probabilities remain game design. |

The 1978 BASIC code and 1985 designer/manual references remain gameplay comparisons, not historical measuring instruments. BASIC's expenditure/food counters cannot simply be read as modern physical pounds. The 1985 carry cap is a design decision. The 1993 interface supplies presentation references, not a nutritional model.

### Current money and carrying arithmetic

The actual default cart costs **$450.60**, weighs **2,359 lb**, and leaves **$224.40 / $524.40 / $1,024.40** from farmer/carpenter/banker budgets of $675/$975/$1,475. The broad study adds 20 dried-produce units for $8 and 14 lb. Starting funds represent an authored amount available to outfit, not annual salary.

Five travelers at health 85 have 170 lb gross walking capacity; at health 60, 120 lb. With 75 lb personal gear, five clothing sets (30 lb), 20 bullets (2 lb), one kit (2 lb) and salt (1 lb), only **60 / 10 lb** remain for food respectively. Fresh meat at two physical pounds per food unit therefore fits only 30 / 5 units. That is a direct explanation for the weak-party cliff, rather than evidence that humans historically could not walk and forage.

Rations treat the five travelers equally; the model does not reconstruct adult/child body sizes and individual caloric expenditure. The fixed gear, food equivalence and recovery interactions need review together.

## Final validation results

### Lawful ordinary wagon parties

Fresh full-mechanics May starts, four seeds each. Arrival means at least one traveler reached Oregon; intact means all five original travelers arrived.

| Profession | Salted hunting arrivals | Intact | Median elapsed days of arrivals |
|---|---:|---:|---:|
| Farmer | 0/4 | 0/4 | â€” |
| Carpenter | 4/4 | 3/4 | 263 |
| Banker | 4/4 | 4/4 | 253 |

The independently provision-first transport policy has different buying/hunting targets. Across March/May salted wagon starts it produced farmer **2/8 arrivals, 1/8 intact**, carpenter **7/8 intact arrivals**, banker **8/8 intact arrivals**. Policy sensitivity matters: a failing farmer cohort does not prove there is no winning decision sequence.

For spring salted transport starts, out of eight each:

| Mode | Farmer arrivals (intact) | Carpenter | Banker |
|---|---:|---:|---:|
| Wagon | 2 (1) | 7 (7) | 8 (8) |
| Mounted | 0 | 2 (2) | 8 (7) |
| Packing | 0 | 1 (1) | 4 (4) |
| Walking from departure | 0 | 0 | 0 |

Median arriving banker elapsed days: wagon 210, mounted 223, packing 258.5. All are beyond a simple 120-180-day target. Moving-day speed can still be reasonable: two development banker wagons made 12.5/13.6 miles per moving day, but took 235/208 elapsed days after 80/65 nonmoving days. Shops, care, events, rest and processing have real cumulative costs.

### Preservation, money, companions and villainy

Across the equally weighted broad validation matrix, each strategy has 180 scenarios: salted 104 arrivals, dry 99, steady pace 101, no hunting 95, theft 63, robbery 3, already-dead remains 104, predation 0, recruitment 103. These include every tested wealth, season and roster; they are not ordinary-player win probabilities.

- Preservation is useful in some situations but has no universal win in this sample. Time and affordable purchases can outweigh retained meat.
- The robbery actor commits up to three offenses and then follows its declared flee/surrender policy. Its 3/180 outcome is a warning about that approach, not proof that every possible robbery decision is equally bad. Predation is deliberately initiated; it is not a starvation-only policy.
- The already-dead policy matched lawful salted arrivals, often because no useful remains opportunity arose. It does not establish a free, universally superior cannibalism strategy.
- Paid rosters arrived in 121/324 mixed scenarios versus 143/324 ordinary, 137/324 Frail, 139/324 selected and 132/324 generated. Wages, trust, legal trait limits, combat and departures all take effect. These small per-cell samples do not establish that every trait is priced fairly.
- Broad validation recorded 189 wanted encounters, 580 departures, 2,674 scurvy episodes and 1,588 deaths attributed to scurvy. Recurrent nutrition failure is a major finding, especially on long or disrupted journeys. It is not a measured historical scurvy rate.
- March/May/August mixed cohorts arrived 295/540, 241/540 and 136/540, with median successful elapsed days 195/251/302.5. Late departure is costly. Better March outcomes also warrant checking the game's simplified early-grass/river tradeoff rather than assuming early departure is always historically superior.

Aiming sensitivities produced 3/6, 4/6 and 3/6 arrivals at 35/65/90% scripted aim. Underfed party-days fell 89 -> 37 -> 28. Better aim helps food acquisition but small samples, later events and travel decisions prevent a monotonic victory guarantee. These are not measurements of human mouse skill.

### Emergency and route checks

With the corrected actor, ordinary walkers reached help **24/24**, health-60 walkers **0/24**, and a party with one broken leg **17/24**. Animal-supported controls succeeded in all 216 cases. Before and after animal-rule versions have identical emergency outcomes here; do not attribute the difference from older actor studies to the grazing patch.

All three tested roads actually appear in their route records. In the two-seed ordinary May comparison, each road had one farmer arrival, two carpenter and two banker arrivals. Greenwood did not uniformly save elapsed time; Columbia was faster in these cases. Route differences have their real crossings, tolls, terrain and delays, rather than an invented flat shortcut bonus.

## Assessment and next work

1. **Nutrition and recovery first.** Explain actual vitamin intake and sustained recovery, inspect the severe recurrent scurvy outcomes, and review food-equivalent calories without confusing physical meat mass with meal units.
2. **Then elapsed time and provisioning.** Audit repeated short shopping stops, care and processing days, late-route stock and reserves. Preserve the agreed one-day-per-store-visit behavior unless deliberately replacing its time model; simply increasing walking speed will not solve these delays.
3. **Weak walking needs an agency/capacity review.** Health scaling plus unavoidable gear leaves almost no food buffer. Test lighter load choices, recovery and preserved food together; do not simply grant free food or declare all walking impossible.
4. **Continue pack/animal calibration.** The corrected development transport sample went from 54/144 arrivals to 51/144 (46 shared successes, eight before-only and five after-only). The rule is more defensible, but winter costs can worsen some late journeys. There is no general balance improvement claim.
5. **Human playtesting remains necessary** for aiming, visible warnings, shopping friction and the feeling of loss. No player's active save was modified.

## Verification and reproducibility

All **61 Godot suites** passed in an isolated checkout at e517454, including 20 new animal-work checks, 211 current-policy checks, 338 mount-policy checks and all existing accounting, health, crime, social, saves, UI and route suites. The same production sources passed **24 store and 20 outlaw integration journeys**, zero reported errors. There are no UI/art changes.

research/summarize_total_balance.py rejects missing/duplicate/unexpected cases, recorded errors, absent source identity, bad day accounting, mismatched comparison decisions/settings, different initial emergency fixtures and validation sources that differ from development. Six deliberately corrupted archive variants were checked. The compact scenario serialization is parsed back and compared before publication.

Raw reports and integration evidence are hash-verified in ignored .tools/total-balance-evidence/. The public summary retains configurations, game/decision hashes, raw SHA256 identities, per-case outcomes, audits and counts; monthly inventory curves and detailed crime records remain in raw evidence. The baseline counterfactual is retained on branch codex/total-balance-before-policy (b211d72); after implementation is e517454. Use these to reproduce the runs. Run the drivers with the protocol's exact seed ranges/settings in isolated APPDATA directories; write fresh archive names. Rebuild the public summary from the declared protocol and the retained raw files. Earlier campaigns and the three preexisting debug pilots remain unchanged.
