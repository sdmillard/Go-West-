# Survival balance campaign, October 22, 2026

The game now has separate physical meat/food accounting, proportional personal hauling and a full public-action journey matrix. This is a reproducible development baseline, not a historical mortality model or a substitute for a human playtest.

## Frozen comparison

The final comparison uses 5,040 development journeys (`balance-development-03-*`) and 5,040 fresh validation journeys (`balance-heldout-02-*`). Development seeds 100-119 were used for diagnosis; the final validation reserves 2000-2019, after the working-team policy was fixed. The earlier validation seeds 1000-1019 belong to the superseded early-slaughter policy and are retained separately. No rules or final policy decisions were retuned to the final validation sample.

Each sample is 3 capital choices x 3 departure months (March/May/August) x 4 rosters x 7 strategies x 20 seeds. Roster: ordinary unpaid; two paid/two unpaid with minimum quoted weekly wages; all companions Frail; or Loyal/Veteran/Hardy plus the required Slow Healer flaw. Backgrounds and ordinary seeded personalities remain matched. These are representative creation-rule builds, not an exhaustive catalog search or an isolated causal test of one special.

Strategies are lawful hunting/drying, lawful salted preservation, no hunting, up to three roadside thefts, up to three roadside armed robberies, eating only accessible already-dead travelers, and one deliberate companion attack from day 20 followed by concealed processing/deception where possible. Attacks may miss, wound, kill or provoke retaliation/flight. The already-dead strategy never initiates an attack. The no-hunting arm can still use spare livestock for food.

Common policy: cautious pace; two food units per traveler when well, three when ill/below 80 health; rest when the worst active traveler falls below 55 or livestock/fatigue requires it; actual medical care when available; food purchases with cash reserve; hunting below 45 units at 65% scripted aim; drying/salted preservation with dry fallback. Pay active mercenaries' full arrears in id order when cash covers them plus$10. Preserve four working oxen before elective slaughter. The player remains free to slaughter any animal, including in an emergency; this threshold is a study decision, not a new game restriction.

All actions use the real simulation, including finite stock, encounters, disease, weather, wages, rumor/refusal, ammunition, provenance and time costs. No money, hunt reward or success is granted by a second survival model. At most365 days/2400actions are observed. **A year limit is a censored study outcome, not a game death or automatic defeat date.** No-time/distance progress over33successive actions is an explicit policy error.

Every final save is restored through the actual validator. The first seed of every cohort is additionally checked every 80actions, plus all open crime/remains panels. Invariants check nonnegative supplies/cash/ammunition/salt, living count, aggregate health, remains mass and tracked ordinary food. Rules and all simulation-source hashes are captured before running and checked again at the end. Separate capital shards are pooled only when signatures match.

## Results

The final pair has **10,080 journeys, no selected invariant/setup/save/route-policy errors**, and identical numerical-rule and simulation-source signatures. Full per-journey rows remain in the three capital shards for each label.

| Sample | Journeys | Arrivals | Intact arrivals | Lost | Study year limit | Captured/surrendered |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Development 03 | 5,040 | 3061 | 1542 | 1775 | 204 | 144 |
| Fresh validation 02 | 5,040 | 2925 | 1660 | 1900 | 215 | 108 |

Capture is a reported subset of outcomes, not an additional disjoint total. Intact means all five arrived with the party.

For a more interpretable subset: May, ordinary unpaid companions, lawful dry/salt policies,40 journeys per capital in each sample:

| Capital | Development arrived / intact | Fresh validation arrived / intact |
| --- | ---: | ---: |
| Farmer | 27 / 7 | 11 / 1 |
| Carpenter | 37 / 33 | 29 / 26 |
| Banker | 40 / 37 | 40 / 39 |

**Poor-party intact survival remains the weakest result.** The reserved farmer subset has 11/40 arrivals and 1/40 intact, versus banker 40/40and39/40. This establishes that lawful full-party survival is possible at every capital; it does not establish forgiving or fully settled difficulty. The validation result is published unchanged. Any numerical tuning after human feedback needs a new reserved sample, not a rewrite of these outcomes.

[Development summary](balance-development-03-summary.json)  |  [Fresh validation summary](balance-heldout-02-summary.json). The rule signature is`376c2029c6bbc9acc8338bb3a2d1f0a7eecfc1374cfd0c20fc07fd47d403e635`. The report source signatures include all simulation scripts and the actual campaign policy.

## What development caught

- The first food-value experiment made fresh meat less dense than staples. A fixed100 lb return and a later threshold-health hauling proposal were preserved as diagnostics05/06. The shipped hauling rule instead scales each person's contribution continuously and removes broken-leg carriers.
- Combined remains journeys exposed meal orders persisting after a diner died. Death/departure synchronization now clears them immediately, including terminal saves.
- Hardy could prevent a shot already resolved as fatal from matching its recorded death. Explicit fatal outcomes now kill through the health ledger; ordinary wound damage still uses resistance. Frail could turn a nominal wound lethal; the attack record now reports its actual lethal outcome. Targeted regressions cover both.
- Pack previews omitted carried bodies/human-derived food. They now count that mass before approving abandonment/repacking.
- An old integration test treated an August lawful journey reaching its observation limit as an error. It now separates elapsed-time limits from actual no-progress loops, as the main campaign does.
- The four-ox sensitivity cohort exposed a test-policy error: it was eating the working team down to one animal before hunting. In144 matched development journeys, excluding slaughter raised four-ox arrivals from 4/72 to 38/72, with no game-rule change. The final matrix preserves four workers before elective slaughter. Three focused regression cases keep that distinction from regressing.

## Focused studies

- `food-decisions-01.json`:180 farmer journeys, April/May, development seeds 100-109, meat value0.35/0.5/0.65 and reserve targets45/90/150. Per-instance sensitivity overrides never edited live JSON. Current0.5 remains provisional; greater food value usually helps, but hunting very early can add enough days to reduce intact survival. Final-save validity is checked; overridden future-rule replay parity is not claimed.
- `pace-aim-study-01.json` and`02.json`:144 journeys each, four/six oxen, cautious/steady pace,35/65/90% scripted aim, three capitals, May, seeds 110-113. The second isolates no slaughter. Scripted aim observes game positions and does not measure a person's actual skill.
- `emergency-journeys-02.json`:144 journeys,12explicit fixture scenarios x 3capitals x 4 development seeds. Four oxen, zero ammunition, zero-ox abandonment/walking, walking with livestock, broken leg, low health, an actually reached hostile store, meal refusers, all other companions leaving, spoiled human-derived food and an actually reached Fort Kearny robbery are covered. Every final/every 80-action save validates; no selected errors. Foot journeys are deliberately extreme and produced no arrivals in this sample. The first emergency archive retains a study-only one-item-at-a-time discard loop; the corrected policy discards an appropriate quantity per action.
- Clean-checkout integration:24 store journeys and 20 outlaw journeys, no selected errors. All33 suites pass, including33 meat/carrying checks,92remains checks and 3 working-team policy checks. Supplies and carried-loot panels were rendered and visually inspected.

## Interpretation and limits

Arrival can reward losing mouths to feed. Intact arrival, deaths, departures and capture are reported separately. Violence can have a useful material payoff and still cost companions and survival; no inevitable narrative punishment was added. Expensive payrolls remain a genuine food/cash obligation. Human hauling affects retrieval/foot packs, while wagon storage and ox pulling remain separate.

Food/cash/ammunition/party curves are sampled approximately every 30 days; counts include hunting, processing, explicit rest/care, wages paid/owed and criminal outcomes. Cause-of-death lists are actual party records. `empty_food_days` counts action-spans ending with an empty ordinary larder: it is a coarse scarcity proxy, **not an exact count of underfed days**, especially for multi-day actions or human-meat eaters. Older derived summaries call its mean `mean_starvation_days`; that label was corrected to`mean_empty_food_action_days`. Do not interpret either as measured historical starvation.

The5040rows share20 seed clusters and matched setups; they are not5040independent random trials. Overall arrival percentages mix intentional late starts, fragile parties, payroll burdens and violent play. The cautious bot is not an optimal human policy, and it does not independently optimize replacement clothing, every purchase, path or food reserve. The matrix does not establish a historically correct death rate, universal build ranking or complete ecological/medical realism.

Physical/nutritional values, per-person load allowances, weather odds and response rates remain authored estimates documented in[food/hauling](FOOD_VALUE_AND_HAULING.md),[historical prices](HISTORICAL_COST_AND_SURVIVAL_AUDIT.md) and[seasonal pressure](SEASONAL_PRESSURE.md). Full tuning should now be informed by[the human playtest](PLAYTEST_CHECKLIST.md), particularly aiming, warning clarity, interruptions and whether scarcity feels understandable. Replacement recruitment, route branches and a combat minigame remain later expansion work.

## Reproduction

Run the portable Godot headless with`--path . --script tests/balance_campaign.gd -- --label=NEW_LABEL --profession=farmer --seed-start=100 --seeds=20`; repeat for carpenter/banker. Archive labels cannot overwrite existing reports. Summarize with`python research/summarize_balance.py NEW_LABEL`. Use new reserved seeds for any future policy or numerical retuning. `tests/food_decision_study.gd`, `tests/pace_aim_study.gd`, `tests/pace_aim_no_slaughter.gd` and `tests/emergency_journeys.gd` reproduce the focused studies; choose a new archive label/path before rerunning.
