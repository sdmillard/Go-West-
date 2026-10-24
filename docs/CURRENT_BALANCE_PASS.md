# Combined survival balance pass

Spencer's balance criterion is fair, understandable consequences, not equal outcomes for every choice. Poverty, late departure, payroll obligations, injury and violent crime may impose very different risks. The checks look for accounting errors, impossible saves, misleading previews, stalled actions, dominant loopholes and whether sensible lawful play has a viable path; they do not flatten those differences into equal win rates.

This pass updates the automated policy for the current game: exact-unit counters, foraging, fresh/dried produce, party composition, paid contracts, replacement companions and wanted encounters. Earlier balance archives describe earlier rules and policies; their totals are not pooled into this sample.

## What changed

Fresh produce and dried fruit are purchasable before departure and at eligible trail counters. Camp drying reserves its input before the work day's meals. Meals share a produce serving before consuming other provisions; carrying or selling fruit provides no dietary benefit. See [produce rules, estimates and sources](PRODUCE_AND_NUTRITION.md).

The pass also exposed two wanted-system defects: saved transient crime origins were compared against an empty validation object, and a nonfatal sentence could give health to a dead original leader after a failed flight. Restoring uses the candidate crime record, and punishment applies to a surviving traveler. Regression cases retain strict save validation.

Opening funds remain $600/$900/$1,400. Ordinary food remains five cents per opening food unit, oxen $30 each, and meat remains half a food unit per physical pound. The study does not raise wealth or food yields to compensate for poor automated purchasing decisions.

## Method

The campaign invokes the actual simulation and public actions. Its observer counts actual underfed days through the engine's food-shortage health effect, as well as elapsed work/rest days, vitamin meals and scurvy person-days. A parity regression compares its complete saved state and RNG against the original engine.

Three capitals, March/May/August starts, five rosters (ordinary, two paid companions, Frail, selected specials plus a flaw, and generated candidates), and ten strategies cross every selected seed. Strategies are the archived legacy policy, salted preservation, unsalted preservation, steady pace, no hunting, theft, robbery, processing existing dead, deliberate companion predation, and recruitment. Crime is attempted only when a real opportunity exists; results retain the actual incident count.

The modern policy shops with money, finite stock and cargo limits, conserves cash for poor hunting regions and tolls, buys ammunition before exhausting its food budget, forages when vitamins run low, preserves only a surplus large enough to justify a work day, and preserves four working oxen before elective slaughter. The ordinary opening cart adds twenty dried baskets ($8, 14 lb); this is a declared study choice, not a forced purchase or a free grant. Legacy comparisons use the same opening cart but the older policy thereafter.

The hunt policy uses a declared 65% aim setting. Human accuracy, speed and decisions may differ. Development and held-out seeds are separated; each completed shard records rule and source hashes, settings and errors. The runner refuses to overwrite reports or accept source changes during a run. The summarizer refuses mismatched shards or technical errors.

Arriving with five replacements is not counted as preserving the original five. Year limits are separate from deaths. Repeated use of one seed across cohorts makes these matched comparisons, not thousands of independent random seeds. No historical mortality percentage is used as a target win rate.

## Historical bounds

[National Park Service trail guidance](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) describes roughly 12–15 miles per day and four to six months, with costly resupply. These constrain interpretation rather than demand every scripted journey finish in that window. Slow travel, frequent hunting, illness and prolonged rest can take longer; late departures encounter winter.

[Palmer's 1847 guide](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html) recommends dried fruit. The game's mixed-basket produce prices, vitamin retention and shelf lives are explicit thematic estimates; there is no definitive recovered price or single drying method for every post and month. See [historical economic estimates](HISTORICAL_ECONOMY.md), [baseline](HISTORICAL_BALANCE_BASELINE.md) and [produce evidence](PRODUCE_AND_NUTRITION.md).

## Focused hunting evidence

[Controlled hunting report](current-hunting-study-01.json): 1,350 real outings, five habitats × three aim settings × three health/injury conditions × thirty matched seeds. Each hunt charges actual ammunition, one day and normal meals. Starting health and habitat are explicit fixtures, not claims about encounter frequencies. No selected technical errors were reported.

At the 65% aim setting with healthy helpers, mean net food after the day's fifteen-unit meal was +14.9 in woodland, +23.8 on plains, +17.5 in high country, +4.8 in sagebrush and +18.2 in forest. Physical retrieval averaged 59.6, 77.5, 64.6, 39.1 and 65.9 lb respectively. Each habitat had four empty hunts in its thirty matched healthy trials. These figures include losses and misses; they are not guaranteed returns. Injury lowers carrying capacity, so hunting is not an unlimited emergency food source.

## Reading the archives

The first current-game legacy pilot and development-02 are diagnostic archives containing recorded errors. They must not be reported as clean balance validation. Early policy probes also use different source revisions; do not pool their totals. An emergency fixture initially killed the leader without updating the explicit party-size cache; its invalid fixture is preserved in study-01 and corrected in the later study.

Final results and exact reproduction commands are recorded below. A short [human playtest](PLAYTEST_CHECKLIST.md) remains necessary for warnings, hunting feel, readability and pacing.

## Outfitting sensitivity

Fifty-four matched May/ordinary/salted-policy journeys compared 0, 20 and 60 dried baskets (six development seeds, 3400–3405, each capital). All use paid, legal opening purchases and the same frozen sources as the final campaign. Every shard reported zero selected technical errors.

| Dried baskets | Cost / extra mass | Farmer arrivals / original intact | Carpenter | Banker |
| --- | --- | ---: | ---: | ---: |
| 0 | $0 / 0 lb | 1 / 1 of 6 | 6 / 6 of 6 | 6 / 6 of 6 |
| 20 | $8 / 14 lb | 2 / 0 of 6 | 6 / 6 of 6 | 6 / 6 of 6 |
| 60 | $24 / 42 lb | 2 / 0 of 6 | 5 / 4 of 6 | 6 / 6 of 6 |

Additional fruit increased the number of actual vitamin-bearing meal days, but did not dominate the survival results. It consumes money that could buy ammunition, care or western resupply; changed meals and decisions also change subsequent random draws. These six seeds are a sensitivity check, not proof that a particular reserve is optimal. No default purchase is imposed. Fresh and dried produce remain available in initial outfitting with visible prices, mass and expiry information.

Raw shards follow balance-current-outfit-{0,20,60}-01-{farmer,carpenter,banker}.json.

## Emergency fixtures

[Final emergency report](current-emergency-study-03.json): 192 journeys, sixteen scenarios × three capitals × four development seeds (3300–3303), May. **Zero selected invariant, save or policy errors.** There were 115 arrivals, 76 losses and one year limit. This deliberately perturbed sample is not an ordinary arrival rate.

Scenarios include four oxen, zero ammunition, immediate walking/zero oxen, low health, broken leg, scurvy, fresh/dried opening reserves, loss of the original leader, departures, food refusal, unserved human-derived food and hostile posts/forts. Immediate walking from Independence produced no arrivals in these twenty-four walking trials; a full-route pack journey remains an emergency gamble, not a guaranteed rescue. The twelve leader-dead fixtures continued and arrived without resurrecting the original leader. Other fixtures have different nutrition demands and party sizes, so their success is not evidence that deaths or dismissals are generally beneficial.

Actions after preparation use the real engine. Crime cases are only attempted if the party actually reaches the eligible venue. The raw report records whether that happened. Study-01's twelve invalid leader fixtures and twenty-four associated errors remain archived; study-02 corrects preparation, and study-03 adds final-source freezing.

## Final development matrix

Development-03 uses four previously explored seeds, 3104–3107: **1,800 journeys, zero selected state, save, setup or policy errors**. It produced 677 arrivals, 582 preserving all five originals, 1,018 losses and 105 year limits. Development-02's 3,600 diagnostic runs recorded 42 injured-walker policy stalls; those are retained as errors and excluded from the clean final totals.

This is a deliberately mixed matrix, not a forecast for an ordinary player. Its May/ordinary salted-policy farmer cell had zero arrivals in four development seeds, while the separate eight-seed timely probe had two intact arrivals and the six-seed zero-fruit outfitting control had one intact arrival. These small, differently sampled cohorts demonstrate viability but also substantial uncertainty and severe low-budget difficulty. They are not combined into a single success rate.

The steady-policy development cell had an intact farmer arrival in 192 days. Ordinary May carpenter/banker steady arrivals took 186–203 days, versus 239–280 days under the more cautious salted policy. This puts the slower campaign averages in context: many simulated journeys spend long periods resting, hunting, shopping and encountering winter. The study does not establish every cautious journey as a historically typical duration.

Across all development rosters/capitals/strategies, March had 294/600 arrivals, May 244/600 and August 139/600. Salted-policy scurvy burden averaged 31.6 person-days per run, against 729.9 for the archived policy that never forages. These policies differ in shopping and other actions too, so this is not an isolated causal estimate for foraging.

Independent validation uses unused seeds 5000–5007 with the same frozen sources and settings. No game parameter or policy change will be made in response to its results.

## Reproduce

Use Godot 4.5.1 and Python's standard library. Keep study runtime data away from player saves. Each label must be unused; the scripts intentionally refuse to replace an archive.

```powershell
$env:APPDATA = Join-Path (Get-Location) '.tools/study-userdata'
foreach ($capital in @('farmer','carpenter','banker')) {
  godot --headless --path . --script tests/current_balance_campaign.gd -- --label=current-development-rerun --profession=$capital --seed-start=3104 --seeds=4
}
python research/summarize_current_balance.py current-development-rerun
foreach ($capital in @('farmer','carpenter','banker')) {
  godot --headless --path . --script tests/current_balance_campaign.gd -- --label=current-heldout-rerun --profession=$capital --seed-start=5000 --seeds=8
}
python research/summarize_current_balance.py current-heldout-rerun
```

Replace the executable name with the local portable Godot path if it is not on PATH. The second command reproduces the archived validation; reusing those seeds after tuning does not create a new held-out sample.

Use the same runner with May/ordinary/salt, seeds 3400–3405, and --outfit-dried=0, 20 or 60 to reproduce the outfitting comparisons under separate labels. The focused hunting/emergency runners have their own fixed output names; preserve existing archives and choose new names in a separate checkout before rerunning.

The complete 48-suite regression run and 24 store / 20 outlaw integration journeys passed against feature checkpoint 341cf82 in a clean isolated checkout. New dedicated coverage includes 52 produce checks, 206 observer/policy checks and 173 wanted checks. Native outfitting and trail-counter layouts were rendered and inspected, and the initial store was shown to Spencer. Older tracked integration reports, player saves and the three preexisting untracked debug archives were preserved.

## Independent validation results

Validation-01 uses eight unused seeds, 5000–5007: **3,600 journeys with zero selected state, save, setup or policy errors**. The final development/validation pair totals **5,400 clean journeys** with identical game/policy sources and settings. The held-out sample was read after the rules were frozen; no settings were adjusted to its outcomes.

Validation produced **1398 arrivals, 1215 preserving the original five, 2070 losses and 132 year limits**. These totals mix deliberately difficult choices and rosters; they are not a target win rate or an estimate of historical emigrant survival.

| Starting capital | Arrivals | Original five arrive | Runs | Mean actual underfed days |
| --- | ---: | ---: | ---: | ---: |
| Farmer | 50 | 33 | 1200 | 6.0 |
| Carpenter | 496 | 426 | 1200 | 3.6 |
| Banker | 852 | 756 | 1200 | 1.5 |

For ordinary unpaid parties leaving in May with the salted policy, the comparable cells were:

| Starting capital | Arrivals | Original five arrive | Runs |
| --- | ---: | ---: | ---: |
| Farmer | 1 | 1 | 8 |
| Carpenter | 8 | 8 | 8 |
| Banker | 8 | 8 | 8 |

The farmer result includes an intact lawful arrival on unused seed 5001 in 202 days. Low-budget play is demonstrably viable, and remains unforgiving under this particular cautious policy. This does not prove that all reasonable human strategies are equally viable, or that their risks are adequately communicated.

| Departure month | Arrivals | Runs |
| --- | ---: | ---: |
| March | 610 | 1200 |
| May | 507 | 1200 |
| August | 281 | 1200 |

The salted policy averaged 24.5 scurvy person-days per journey, versus 705.9 for the archived policy that never forages. The policies differ in other decisions too. Current-mechanics decisions improved many matched outcomes without changing starting wealth or hunting food value.

Validation recorded 318 later wanted encounters and 261 sentences. Violent strategies include real food, ammunition, injury, trust, service-loss and pursuit costs. Their outcomes need not equal lawful play.

[Development summary](balance-current-development-03-summary.json) and [validation summary](balance-current-heldout-01-summary.json) contain all cells, matched comparisons, seed clusters and source/rule fingerprints. Raw shards use the same label plus farmer, carpenter or banker. The final summaries deliberately exclude failed diagnostics, the separate outfitting comparisons, emergency fixtures and controlled hunts.

## Remaining judgment

This pass establishes coherent accounting, legal action paths and viable journeys. It does not certify every numerical risk as fair. Human playtesting should check whether food, vitamin shortages, declining hauling capacity, approaching winter, payroll and crime consequences are visible soon enough to act on. An adverse outcome is not itself a defect; an unexplained or internally inconsistent one is. Further tuning should address demonstrated unreasonable tradeoffs rather than equalize the cells above.
