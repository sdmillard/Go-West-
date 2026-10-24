# Combined survival balance pass

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

The final results and exact reproduction commands are recorded below after validation. A short [human playtest](PLAYTEST_CHECKLIST.md) remains necessary for warnings, hunting feel, readability and pacing.
