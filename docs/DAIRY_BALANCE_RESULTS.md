# Calibrated dairy: matched farmer balance results

October 26, 2026. **624 accepted journeys, 52 complete reports, zero recorded state/save/policy errors. All 48 no-stock control pairs were identical.**

Dairy animals now supplied appreciably more food under the same tested strategy, but that did not establish a reliable farmer completion rate. Current fixed-policy livestock arms had no arrivals in either phase. One hay-supported cow journey arrived in development and one hay-supported goat journey in confirmation. The next bottleneck is the broader food/vitamin/time strategy, not evidence for inflating milk yields.

No gameplay parameters, prices, starting cash, yields or ordinary decisions were tuned in this pass. New files add read-only measurement and a reproducible launcher. [Protocol and infrastructure amendment](DAIRY_BALANCE_PROTOCOL.md), [complete compact evidence](dairy-balance-summary-01.json).

## What was compared

Prior gameplay `64318410e93cfc5ed28039436374921da5731c10` is the mixed-feeding version from the previous full study. Current gameplay `d7bb74b55333b75e05536d284389b60ac96e34df` includes opt-in edible hen portions, dairy energy budgets and shared pasture. The study measures that package, not separate causal effects of each change. Both use the egg-save correction.

Common instrumentation snapshot `912c7b53547cc442cd7238f6ab46d71663c60fb4`; prior instrumented baseline `0ce16141bc6169409bd7705a55d7ceb6487d90b9`. Simulation/data match the declared gameplay refs; common observer and inherited decision sources match byte-for-byte. The launcher/output-folder amendment is `5d372553eb71790f8eb716659a6680b8d21950aa`.

Primary: 480 journeys with fixed ordinary decisions, five livestock arms, both versions/outfits, May/July. Secondary: 144 current-rule goat/cow/mixed journeys using the existing current-gap hay-shopping strategy. All start with the same $675 total resources and matched carts, no opening hay. Standard means six oxen/1,700 food; lean four/1,200. Other shared equipment, produce, aim, pace, care reservation, adaptive rations, hunting/field/camp work and shopping remain frozen.

Each arm/version/phase below pools **24 scenarios**: six seeds × two months × two outfits. Development 475000–475005; sealed confirmation 485000–485005. Those underlying seeds repeat across settings, so this is not 624 independent worlds or a precise population win-rate estimate. The first three attempted batches could not write reports because output directories were missing. Their logs remain; all are excluded and the complete matrix restarted with fresh seeds before any accepted archive. Confirmation was not used to tune settings.

## Arrivals did not establish improved survival

| Arm | Development prior → current | Confirmation prior → current |
|---|---:|---:|
| No livestock | 1 → 1 | 1 → 1 |
| Two goats | 0 → 0 | 2 → 0 |
| Cow | 0 → 0 | 0 → 0 |
| Six hens | 1 → 0 | 0 → 0 |
| Mixed herd | 0 → 0 | 0 → 0 |

None of these cohorts produced an arrival with all five original travelers present. The two prior-rule goat arrivals were standard May scenarios, arriving after 292 and 304 days with one and two originals present. The corresponding current journeys ended around 1,800 miles. More available milk changes later actions and hazard exposure; these few outcomes do not establish that milk itself causes failure or that every human farmer strategy is unwinnable.

The secondary hay strategy produced one development cow arrival and one confirmation goat arrival; all other secondary arms/phases had none. The confirmation goat arrival was standard May seed 485005, day 293, two originals present and $0.04 left. It demonstrates a surviving path, not a robust or smooth journey.

## The added dairy food was eaten

Confirmation means are actual food units eaten per journey (1 unit = 1,000 kcal). Lifetime output also depends on animal survival, slaughter and journey length.

| Arm | Prior milk/egg units eaten | Current | Current with hay |
|---|---:|---:|---:|
| Two goats | 48.316 | 89.742 | 101.403 |
| Cow | 76.434 | 97.230 | 109.823 |
| Hens | 13.227 | 10.788 | — |
| Mixed | 122.574 | 165.815 | 183.656 |

Recorded dairy spoilage and packing losses were zero in these confirmation arms: generated dairy reached actual meals. Herd-day averages also increased (goats 0.360→0.626 units, cow 0.766→0.954, mixed 0.892→1.163), although herd composition and culling still differ. These are not controlled biological yield measurements.

Prior hens received 13.198 units of edible human food while producing 13.227 egg units. Current hens received zero human portions and supplied 10.788 units. The arithmetic egg-minus-shared-food indicator therefore changes from about 0.030 to 10.788 units. This measures opportunity cost, not a separately randomized causal survival benefit. Mixed-herd human portions shared similarly fell from 16.668 to zero.

That human-food protection does not solve hen husbandry. In confirmation, 135 of 144 hens were lost to condition in both hen-only cohorts; the remaining nine were crossing losses. Current hens spent 24.3% of observed living animal-days below Fair versus 15.0% previously. Mixed current hens spent 28.7% below Fair. Grain restocking, dispatch/care priorities, selling/culling and the cost of keeping a flock merit policy review. The data do not justify free eggs or returning to automatic human-food consumption.

Milk-animal condition improved in the pooled exposure records: goat mean living condition 87.9→92.2; cow 84.9→87.6. Goat condition deaths fell 10→8; cow 6→3. Crossing losses and emergency slaughter still mattered (current goats nine crossing losses/31 butchered; cows eight/13). Condition averages are survivor/exposure-weighted; deaths and animal-days are retained alongside them in the evidence.

## Hay helped production at modest road spending

| Confirmation arm | Mean hay bought per journey | Mean hay spending | Journeys buying hay | Arrivals fixed → hay |
|---|---:|---:|---:|---:|
| Goats | 22.58 lb | $0.55 | 24/24 | 0 → 1 |
| Cow | 29.33 lb | $0.67 | 15/24 | 0 → 0 |
| Mixed | 40.00 lb | $0.89 | 21/24 | 0 → 0 |

These means include non-buyers; prices are measured at the actual counters. They exclude opening animal/grain costs, which remain in each outfit's starting budget. The shopping rule buys only against the current gap, keeps $20 and respects stock/cargo. It does not forecast later terrain. Low average spending does not prove that any quantity could have been purchased earlier or that hay never helps survival.

Cow and mixed-herd starts still commit $75 and $90 more capital than no-stock starts. Actual benefits must be weighed against that initial cash and care labor; animals were not required to be financially equivalent to bought food.

## Remaining food, vitamins and time bottlenecks

Current confirmation cohorts first ran short at median days 124.5–137.5. Main-camp unmet meals were roughly 8.7–10.9% over the full journeys, often concentrated near the end. Shortage preceded recorded party deaths in 23/23 no-stock journeys with such deaths, 24/24 goats, 24/24 cows, 23/24 hens and 22/24 mixed. This is temporal association, not proof that every illness death was caused by hunger.

| Current arm | Median first shortage day | Cash at first shortage | Median scurvy person-days | Median rest / stationary days |
|---|---:|---:|---:|---:|
| No livestock | 137.5 | $11.63 | 13 | 27 / 96.5 |
| Goats | 136 | $20.03 | 37.5 | 31.5 / 89 |
| Cow | 133 | $10.33 | 64 | 30 / 95 |
| Hens | 124.5 | $20.05 | 49 | 28 / 90.5 |
| Mixed | 131.5 | $10.35 | 56 | 29 / 93.5 |

For example, no-stock confirmation recorded 43 lack-of-food deaths and 27 scurvy deaths. Dairy does not substitute for the game's fruit/greens requirement. Different paths and survival lengths make disease counts imperfect comparisons of risk. The cash readings near the policy's reserves identify a spending decision to test, not spare money that was necessarily at an open store.

Hunting remains a major time cost: current cohorts averaged about 41–48 leader hunts per journey. Around 30% of attempts were empty. Legacy hunt counters report about 5.84–7.19 food units packed per attempt plus 3.35–4.07 units eaten on the hunting day. Those counters truncate fractional servings, and actual party size changes; they are not an exact net daily calorie balance. Returned outrider catches averaged about 62–77 units per journey in current arms, excluding outbound supplies and their separate meals.

Recorded food spoilage averaged 105–131 units per journey. **Correction:** the earlier “fewer than one preservation action” figure counted only leader actions. Companions also averaged 0.875–1.458 drying batches, retaining about 38–78 units per journey, depending on the arm. The strategy did use preservation; the remaining waste needs classification before concluding that more drying would prevent it. Batch `pounds` are food units despite their legacy name, so comparing that field with meal units is dimensionally consistent. Some loss may be unavoidable; this does not establish all of it could have been retained.

Only about 27–32 median days were explicit rest; stationary totals near 89–97 also include hunts, events, crossings, shopping and other actions. These are not simply overly cautious weeks spent nursing everyone. Main-camp meal accounting excludes detached actors, whose records are kept separately.

Named grazing was actually used by the inherited policy (confirmation current: four goat, two cow and four mixed-herd visits across 24 scenarios each). This is not an optimized grazing strategy or a separate evaluation of the new activity benefit. Care coverage shortages were under 1% of herd-days, but reserving caretakers can still displace hunters/foragers; good coverage does not mean labor is free.

## What to test next

Keep these gameplay rules frozen for the next policy comparison. First audit food-value/spoilage and preservation decisions; then test sustainable ration choices, earlier outrider dispatch, produce coverage and emergency spending as separately labeled changes. Current behavior switches to Filling whenever any active traveler is ill or below 80 health and dispatches proactively only inside a low-food window. Test those choices rather than silently weakening disease or increasing milk to meet a success target.

A lean start is meant to be harder, and successful risky play need not preserve every traveler. These results show that the tested strategy remains unreliable; they do not demand equal outcomes across professions or livestock choices.

## Verification and reproduction

All **86 `test.ps1` suites** passed. Both versions passed **72 plain/observed parity checks**, including actual feed checkouts and saved random streams. All 624 accepted journeys passed source/rule, state/save/policy, exact starting-budget/cart, purchase-cost and meal-consistency checks. Original and parent archives match their receipt hashes. The [verifier](../tests/summarize_dairy_balance.py) uses the full declared cells and keeps both phases and unsuccessful scenarios.

Raw reports, manifests, receipts, failed infrastructure logs and suite logs remain locally in ignored `.tools/`. They are required for the verifier and are not shipped with a fresh clone. Compact evidence records source refs, report hashes, per-cell results and limitations. No survival result was used to tune biological yields.
