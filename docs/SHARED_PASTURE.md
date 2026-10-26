# Shared pasture assessment and grazing stops

October 26, 2026.

Oxen, saddle/pack animals and dairy livestock now obtain local environmental information through one pure `simulation/pasture.gd` assessment. It reads the current region, month, seasonal pressure, weather and waterless-road status. Dairy animals use its grass/browse opportunity; oxen and mounts use its established recovery and strain responses. Previews consume no time, supplies or randomness.

This reuses the existing environment and condition system rather than creating another map of grazing regions. It preserves ordinary ox/mount balance: the existing terrain, winter, late-dry-plains, weather and waterless costs are moved into the assessment without adding them twice. Reserve oxen also read the shared recovery result. Dairy maintenance, hay and milk energy calculations remain species-specific.

## Named grazing camps

The existing activities at Ash Hollow, Soda Springs and Grande Ronde are now available when the party has oxen, horses, mules, cows or goats. Hens alone do not make a grazing activity available.

Selecting a named better camp still takes one real rest day with normal meals, weather, care, production, expiry and health checks. On that day, dairy animals can use better local grass/browse instead of the broad habitat cap. The calendar availability and waterless constraint still apply; it does not turn winter into summer. Existing milk ceilings remain unchanged.

The better-camp benefit is scoped to the synchronous activity tick. It is cleared afterward, cannot be saved as an ongoing bonus and cannot be repeatedly claimed at the same stop under the existing one-use activity ledger. Merely arriving or previewing the stop does not activate it. Travelers away on outings receive no automatic camp benefit.

Oxen retain the existing eight-point activity bonus plus ordinary seasonal rest recovery. A party without oxen receives no phantom ox-condition effect. Horses and mules receive their normal rest recovery. Dairy animals receive the actual rest-day feeding opportunity, not arbitrary milk or a direct condition gift. A good camp may produce no extra milk when an animal already has enough feed for its current yield ceiling.

## What is and is not shared

| Input | Existing source | Consumers |
|---|---|---|
| Region and local hazard | Route/context and current edge | All animal environment assessments |
| Season and forage opportunity | Existing livestock monthly and habitat allowances | Dairy DM intake; common pasture preview |
| Seasonal recovery and work pressure | Existing survival seasonal tables | Oxen and mounts |
| Regional/weather/waterless work strain | Context, weather, established waterless cost | Oxen/mount condition response |
| A deliberately selected better grazing camp | Current one-day named activity | Dairy grass/browse opportunity; existing team/rest benefits |

The shared assessment does **not** yet give draft oxen or mounts a full hay/TDN ledger. Their older condition rules remain an approximation; differing responses are not evidence of measured species intake. Changing the dairy habitat quantity table alone does not automatically recalibrate oxen wear. A future grazing calibration should revise the shared environmental assessment and each species response together, with matched survival checks. Local pasture quality, site depletion and herd competition remain open; this patch introduces no new historical yield claims or regional percentage tuning.

The common assessment exposes both grass and browse because goats can use different plants. It does not make goats and cattle have the same diet, or make dairy feed support the draft team for free. Dairy fodder is still consumed through its existing dairy ledger.

## Saves and validation

Actual prior-runtime dairy/hay on/off saves were captured before editing, plus a derived older missing-setting case. Prior fingerprint `cabcdcef300fd35ca27b1be9d943ded92b9601d41f5a8e2e8fe3f6cb596a6440` is allowlisted. Loads preserve resources, livestock, conditions, lactation and random state, and grant no active grazing benefit.

`tests/test_shared_pasture.gd` has 741 focused checks: twelve months × five regions × wet/waterless contexts, established work/recovery parity, common dairy inputs, preview purity, an actual oxless dairy/pack grazing day, one-use enforcement, winter limits, hen-only exclusion and save compatibility. Existing named-stop tests retain their exact ox recovery expectation. Final runtime `6a8872f5365ad920ba100707e7075be7232fc7a2` passed all **85 test.ps1 suites**. Eight complete ordinary-journey pairs (16 journeys: no-stock/mixed, May/July, seeds 445000–445001) matched exactly on the recorded outcome, time, distance, food, money, party survival, action/work/travel and livestock/feeding records. Sources and archive hashes verified, with zero recorded errors. These two seeds repeat across settings; the result is a small regression comparison, not a survival balance study. [Compact validation](shared-pasture-validation-01.json), verifier `tests/summarize_shared_pasture.py`; raw reports `.tools/hunting-shared-pasture-{old,new}-{none,mixed}-01.json` and suite log `.tools/shared-pasture-tests.log` remain local.
