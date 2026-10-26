# Mixed feeding: matched survival comparison

October 26, 2026. **624 accepted journeys, zero recorded state/save/policy errors.** The new feeding rules increased gross egg food but did not establish a reliable farmer survival improvement. Milk fell sharply under regional forage caps. Human-food sharing nearly cancelled the egg calories in the tested policy. These findings identify problems to investigate; they do not establish that all farmer play is unwinnable.

No biological yields, prices, starting funds, nutrition thresholds, forage caps or sharing defaults were adjusted in response to these results. The only runtime correction in this comparison repairs an egg-progress save boundary.

## Design and provenance

The [preregistered protocol](FEEDING_COMPARISON_PROTOCOL.md) and amendment 2 define 480 primary journeys and 144 secondary fodder-policy journeys. Each arm/phase below contains 24 journeys: six seeds across May/July and standard/lean outfits. Six underlying seeds repeat across settings; these are not 624 independent worlds. Development seeds are 385000–385005; confirmation 395000–395005. The original matrix used different seeds and was excluded in its entirety after exposing the save defect.

Old gameplay: `8c9987474b85c8148f925db690494a2b9dbb7d7f` (pre-mixed-feeding with the same numerical repair). New gameplay: `64318410e93cfc5ed28039436374921da5731c10`. Common instrumentation: `3fd422212fc150e28f1ab9a26a13c3788f98737c`. Report hashes, rule signatures, cell results and observer hashes are in [the compact evidence](feeding-comparison-summary-01.json). Raw reports and archive receipts remain locally in ignored `.tools/`; they are required to rerun the summarizer and are not distributed with a fresh clone.

All 52 source-stamped reports passed validation. All **48 matched no-livestock controls were identical** in outcomes, days, actions, route and food/cash records. Both versions used the same initial carts and $675 total resources, no initial fodder, lawful farmer parties, a shared horse, adaptive rations, support camp work/fishing and mobile outriders. The secondary policy buys fodder at current deficits, with cash/cargo/stock constraints; it is a decision change, not an isolated feeding-rule comparison. Its initial carts match the fixed-policy carts.

## Arrivals

| Livestock | Development old → new | Confirmation old → new |
|---|---:|---:|
| None | 2 → 2 | 2 → 2 |
| Two goats | 0 → 0 | 1 → 0 |
| Cow | 0 → 0 | 0 → 0 |
| Hens | 0 → 1 | 0 → 0 |
| Mixed | 0 → 0 | 0 → 0 |

The new-only fodder policy produced one cow arrival in development versus zero without fodder. No goat, cow or mixed fodder journeys arrived in confirmation. This policy buys only against the current region's gap and does not forecast future pasture or optimize livestock sales. It does not show that fodder can never help.

## Where the food went

Confirmation means below are food units actually eaten per journey; one unit is 1,000 kcal. Different survival/exposure lengths mean lifetime production is not a pure daily yield comparison.

| Livestock | Old eaten | New eaten | New with fodder |
|---|---:|---:|---:|
| Two goats | 90.228 | 45.572 | 59.891 |
| Cow | 122.982 | 66.775 | 81.231 |
| Hens | 5.631 | 13.627 | — |
| Mixed | 191.634 | 105.802 | 126.070 |

Recorded dairy spoilage and packing losses were zero in these cohorts: generated dairy was eaten. The milk decline therefore comes from production/exposure, not lost servings. Fodder purchases averaged 22 lb for goats, 58.25 lb for cows and 60.583 lb for mixed herds in confirmation.

Hens shared **13.605 units of edible human portions**, against 13.627 units of eggs eaten. The arithmetic difference is about 0.021 units; that subtraction is an opportunity-cost indicator, not a causal survival estimate. Sharing protects the current day's meal and vitamin-bearing portions, but the eligible remnants are still real food, not otherwise inedible waste.

A separate exploratory check used fresh seeds 405000–405005 with hens, May/July and both outfits: 24 sharing-on and 24 sharing-off journeys, identical paired starting carts and zero errors. Sharing on averaged 13.156 egg units eaten and 13.141 human units fed back; off averaged 11.181 egg units and no human food shared. Both had zero arrivals. This supports reviewing sharing's role/default, while showing that changing the checkbox alone did not solve these test journeys. It was run after inspecting confirmation and is not pooled as independent validation. [Exploratory evidence](feeding-exploratory-summary-01.json).

## Forage assumptions are a calibration target

Forty controlled probes held care, clear weather, full lactation and rest constant, crossing May/July, five regions, Fair/Good condition and absent/plentiful fodder. Fair and Good gave identical output. Ample fodder restored the base 8 lb cow / 2 lb goat yield in every probe. Without fodder:

| Region | May cow / goat milk lb | July cow / goat milk lb |
|---|---:|---:|
| Woodland | 8 / 2 | 4.8 / 1.2 |
| Plains | 8 / 2 | 4.8 / 1.2 |
| High country | 1.6 / 0 | 1.6 / 0 |
| Sagebrush | 0 / 1.2 | 0 / 1.2 |
| Forest | 3.2 / 2 | 3.2 / 1.2 |

These are model outputs, **not historical measurements**. Natural intake is capped by season, habitat and available feeding time. Milk then uses surplus above 70% maintenance, reaching full production at 95%. Thus 75% intake gives 20% cow milk and the high-country goat cap of 70% gives none. The broad normal-condition range avoids the previous linear health collapse, but coarse hunting-region pasture proxies combined with this steep surplus curve can still suppress output. Resource availability and nutrient demand at modest yields need independent evidence before further tuning. The [realism audit](LIVESTOCK_REALISM_AUDIT.md) remains the source for the unchanged base-yield proxies.

## Wider survival bottlenecks and test-player limits

Confirmation no-stock journeys first ran short at median day 140 with $20.04 remaining. Of 22 journeys with recorded main-party deaths, 21 had a food shortage first. New livestock arms first ran short around days 126.5–137, typically near the scripted cash reserves. Scurvy remained consequential. Forage calories alone do not measure its vitamin contribution.

No-stock journeys had median 30.5 explicit rest days, 105 stationary days and 104 progress days. Stationary days include hunting, events, shopping and crossings; they are not all cautious rest. Leader hunting averaged 49.375 attempts per journey; approximately a quarter of attempts brought no food. Detached hunters returned a mean 54.667 food units. Those figures warrant examining hunting workload, dispatch timing and preserved food, rather than treating all delays as recuperation. Hunt counters include legacy integer reporting, so they are not an exact calorie balance.

The test player retains earlier choices: Filling rations when any active traveler is ill or below 80 health, $20 normal/$10 emergency reserves, one shared mount, late low-food dispatch triggers and no optimized livestock sales or farmer outfitting search. Main-camp meal totals exclude detached actors. Poor results under this policy do not prove risky human choices cannot work. Next comparisons should separately test rations, earlier dispatch, produce coverage and spending reserves, with fresh confirmation seeds.

## Egg save boundary and validation

The first matrix exposed real egg progress `0.99999999999999956` serializing to `1.0`, which the strict save validator rejected. Egg accumulation is now canonicalized to 12 decimals before laying/remainder checks. A narrowly fingerprinted migration repairs that exact old-save boundary without granting eggs, money or time. Current-rule forged progress of 1 and genuinely invalid values remain rejected. The authentic failing save is retained as a fixture.

The entire first matrix is excluded, including completed confirmation cells; amendment 2 restarted both versions with fresh seeds and the same repair. `test.ps1` passed **all 82 suites**; the new egg suite includes **523 checks**, authentic-save recovery and repeated annual laying/save cycles. Old/new observer parity checks passed. The accepted 624 journeys, separate 48 sharing journeys and 40 probes all passed their source/archive checks. Scripts: `tests/summarize_feeding_comparison.py` and `tests/summarize_feeding_diagnostics.py`.

The next work is to calibrate forage availability and low-yield nutrient demand, review the edible-food sharing choice, then compare test-player strategies. Keep base yields tied to evidence, not arrival targets.
