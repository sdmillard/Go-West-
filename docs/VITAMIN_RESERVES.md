# Gradual vitamin reserves

October 26, 2026. Prevention now tracks each traveler's nutrition history gradually. Small regular produce servings help; one good meal cannot reset weeks of deficiency. Individual health details show reserve as Well supplied, Adequate, Low or Depleted.

## How it works

Reserve is full at departure. With no vitamin-C food it depletes over the existing45-day onset scale; sustained depletion exposes the traveler to the existing rising scurvy chance. Reserve depletion does not itself mean a guaranteed immediate diagnosis.

The existing shared produce target is treated as an ample replenishing portion, distinct from minimum maintenance. One eighth maintains reserve; less slows depletion, and more gradually replenishes. A full portion restores seven empty-diet days, capped at full reserve. Thus one full meal after60 deficient-day equivalents leaves53, not zero. A tiny serving's contribution survives daily rounding.

Adequate current maintenance intake also prevents a fresh deficiency-onset roll while reserves rebuild. If insufficient intake resumes before reserves recover, the retained deficiency history still matters. This prevents a traveler from finishing scurvy treatment and immediately rolling a new case despite continued adequate intake.

Existing scurvy treatment remains separate: actual shared meal coverage proportionally advances recovery and reduces scurvy-only damage; full recovery still requires14 steps, with the existing rest/nursing effects. Replenishing reserves does not instantly clear an existing illness. Prices, finite shop stock, dried-produce vitamin retention and calories are unchanged. Automatic serving still uses the existing ample-portion policy; this change does not add player-controlled maintenance portions.

## Evidence and approximation

[NIH's vitamin C reference](https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/) distinguishes prolonged intake below about10mg/day associated with overt deficiency from adult recommended intake75-90mg/day, and describes body stores influencing onset. This supports separating prevention maintenance from ample intake and tracking history.

The game's ratio8 is an **authored approximation** inspired by that distinction. Generic produce is not assayed vitamin C, and no claim is made that a basket contains a particular clinical dose. The45-day scale, repletion rate, reserve bands and illness odds remain game abstractions. This is more gradual behavior, not a validated physiological model. Seasonal/species vitamin content and drying retention still need research.

## Parties, trips and saves

Every traveler retains personal reserve debt. Main-party meals update only active travelers. Wagon guards and outriders settle their own packed meals through the same reserve rule; their camp cannot borrow vitamins consumed at the wagon. Different histories remain different when travelers reunite.

Older saves initialize missing reserve state from each person's existing deficiency value, falling back to the older party value. They do not receive a free nutritional reset. New fractional state saves exactly and is checked on normal and detached-camp load paths. The legacy aggregate field now reports rounded worst-active deficiency debt, not literal consecutive produce-free days; policies therefore see the most depleted active traveler. The daily vitamin-meal observer continues counting actual adequate meals rather than treating full reserves as a meal.

## Validation and limits

[Protocol and disclosed revisions](VITAMIN_RESERVE_PROTOCOL.md), [compact evidence](vitamin-reserve-validation-03.json), verifier `tests/summarize_vitamin_reserves.py`; frozen runtime52f3a04. All **90 Godot suites** pass, including **34 focused reserve checks** for depletion, partial intake, maintenance/repletion, finite capacity, onset, current adequate intake, actual shared meals, independent detached meals, legacy saves, exact JSON round trips and malformed state.

The first candidate used a maintenance demand too close to an ample serving; all eight diagnostic journeys failed. It is retained and excluded in full. The second candidate's successful and failed reports are also excluded after review added the adequate-intake onset guard. Final validation restarted all cohorts at suffix03. No failed seed was selectively dropped.

Sixteen accepted integration journeys have zero report/log errors and source/archive hashes verified. They include eight diagnostic replays and eight fresh standard-May planning65 cases (four underlying seeds535200-535203 repeated over no-stock/goats). All starts retain the farmer's $675 total assets and unchanged strategy.

| Cohort | Arrivals /8 | With four originals | Recorded scurvy deaths |
|---|---:|---:|---:|
| Diagnostic replay | 5 | 2 | 4 |
| Fresh integration | 6 | 3 | 4 |

The preceding treatment-only rules also produced five arrivals in those eight replay cases, with different outcomes by setting. The reserve change is not a demonstrated overall win-rate improvement. Fresh cases are narrow integration evidence, not eight independent worlds or proof farmer balance is solved. Deaths, late journeys, produce access and the overall time budget remain concerns. Full per-case outcomes are in the compact evidence.

Raw local final reports `.tools/hunting-vitamin-reserve-{replay,fresh}-{none,goats}-03.json`; separate hash copies `.tools/vitamin-reserve-archives/`. All earlier reports/logs remain for diagnosis. Full test log `.tools/vitamin-reserve-final-tests-03.log`. Run `./test.ps1`, then `python -B tests/summarize_vitamin_reserves.py` where the raw archives are present. Earlier balance/audit documents describe their frozen runtimes, not current prevention rules.
