# Rest and care decision study

October 22, 2026. This follows [the journey-time audit](JOURNEY_TIME_AUDIT.md). It changes study-policy options and measurements only. Live illness damage, recovery, rest healing, costs, event rates, food and movement remain unchanged.

## Question and experiment

Do long journeys result from unnecessary rest, or does resting protect people and animals from costly setbacks? Does using care earlier shorten illness enough to justify its cost?

The diagnostic uses 128 journeys: four decision policies x farmer/carpenter capital x April/May departures x drying/salt strategies x seeds0-3. All use the suggested six-ox cart, default seed-matched unpaid companions, steady pace and the existing adaptive-ration policy. Other hunting, trade, preservation and crossing decisions are shared. These are small development cohorts, not historical mortality estimates, human playtests or the held-out balance campaign.

| Study policy | Rest if worst active health below | Offer care to an eligible ill/injured traveler below |
| --- | ---: | ---: |
| Reference | 70 | 55 |
| Later rest | 55 | 55 |
| Earlier care | 70 | 70 |
| Combined | 55 | 70 |

These are internal diagnostic thresholds, not new player health bars or suggested real-world medical decisions. Fatigue above50 and team condition below65 still independently prompt rest. The same food requirement for resting and three-day interval between care attempts apply throughout. Own kits are used when present; otherwise paid care requires a real available service. Candidate selection remains roster order, not an optimized triage policy. Care days consume resources and elapsed time and receive the game's existing rest effects.

## Results

Each row has sixteen runs. Mean arrival days includes only arrivals; it is not comparable to an all-run duration when the losing parties differ.

| Policy | Capital | Arrivals | All five intact | Mean arrival days | Mean explicit rests, all runs | Care actions, total | Deaths, total |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Reference | Farmer | 12/16 | 10/16 | 209.2 | 26.8 | 2 | 25 |
| Later rest | Farmer | 12/16 | 12/16 | 198.0 | 18.8 | 10 | 20 |
| Earlier care | Farmer | 13/16 | 8/16 | 214.7 | 28.8 | 18 | 28 |
| Combined | Farmer | 11/16 | 7/16 | 223.5 | 24.4 | 16 | 31 |
| Reference | Carpenter | 16/16 | 16/16 | 193.0 | 24.5 | 2 | 0 |
| Later rest | Carpenter | 16/16 | 16/16 | 194.9 | 17.6 | 10 | 0 |
| Earlier care | Carpenter | 16/16 | 16/16 | 190.6 | 19.9 | 16 | 0 |
| Combined | Carpenter | 16/16 | 14/16 | 193.4 | 17.8 | 20 | 2 |

Raw data: [rest/care diagnostic01](rest-care-diagnostic-01.json). It includes setup keys, policy parameters, outcomes, dates, money, food, remaining kits, cause-specific deaths, rest-trigger counts and regular condition/supply snapshots. Identical seeds and affluent dry/salt strategies often repeat behavior; do not treat every row as an independent statistical observation.

Across the 32 reference journeys, 820 explicit rest actions occurred. Low health was present at642, low team condition at178 and high fatigue at4. Reasons can overlap, so these counts must not be added into an exclusive partition. This policy's rest burden is chiefly about people and team condition, rather than a simple fatigue timer.

## Interpretation and decision

Later rest is worth testing further: in the farmer sample it preserved the same arrival count with more intact arrivals and less time. That result is not a reason to reduce the game's healing or make injuries harmless. Allowing health to fall farther also makes more travelers eligible for the unchanged care policy, and can increase vulnerability to unlucky damage. The combined policy's losses show that apparently sensible choices need not combine into a better result.

Earlier care helps the carpenter sample's duration modestly, but the farmer's extra arrival comes with fewer intact groups and more deaths. Arrival alone would conceal that cost. Paying for help or spending kits can compete with food and replacement supplies; extra elapsed days also affect weather, wages and disease. The current experiment does not isolate which of those downstream effects explains each death. Examine the recorded trajectories before changing their costs.

No one threshold pair dominates these outcomes. Keep the reference policy defaults and live rules unchanged for now. Retain configurable study thresholds so future cohorts can test more deliberate triage, forecasting and timing without rewriting the simulation engine. The next priority is food value versus physical meat mass, followed by targeted paid-party and emergency-survival cases before the full campaign.

## Validation and reproduction

The reference arm reproduces all sixteen overlapping archived diagnostic03 setups exactly for outcome, date, mileage, survivors, cash and food. This checks that adding configurable policy inputs did not silently change the default behavior. The live rules signature matches diagnostic03. All128 runs completed without selected inventory/party/remains invariant errors, failed save round trips or policy stalls. Limits remain classified separately from arrival/death.

The diagnostic uses public engine actions. It samples saves every80 actions and at the end, aborts after33 no-progress actions, and refuses an existing report label. Use the isolated APPDATA setup in `test.ps1`, then run Godot headless with `--script tests/rest_care_diagnostic.gd -- --label=rest-care-diagnostic-02` to create another archive. Preserve the original when changing policies. The Godot UID is included for the new script.

Validation completed: all 30 suites in test.ps1 passed after the study-policy changes.

The later [seasonal-pressure update](SEASONAL_PRESSURE.md) changes live winter rules and reruns this study as diagnostic02. Results above remain the pre-update record.
