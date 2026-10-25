# Moving-wagon and parallel-camp follow-up

This tests Spencer's intended time-saving use of existing mechanics. It changes test decisions and observation only: no game rules, prices, food, hauling, recovery, horse speed or random probabilities change.

## Matched strategies

All strategies pay for the same standard supplies plus one horse, saddle, saddlebags and 20 dried produce. The runner uses equipment=shared and method=foot for every row; this deliberately gives serial/parallel controls the same purchased animal. Strategy is identified by motion_policy, not the inherited method field. Steady pace, actual adaptive rations, real prices, meals, weather, risks and seeded people apply.

- Serial: existing ordinary group-hunting policy without deliberate support chores.
- Parallel: support roster with nursing/foraging/drying combined into a necessary health/hunting/foraging day where possible. It does not automatically rest simply because a dryer is assigned. Dedicated preservation is reserved for raw meat expiring within two days and exceeding two daily meals. Existing meal/spoilage previews still determine actual processing.
- Mobile: parallel choices plus a fit willing companion dispatched for a real one-day mounted hunt at two to six current party meals in stock, returning ridden with actual limited cargo. The wagon continues while that trip is out if it has a daily meal. Urgent hunting/slaughter remains possible below that. Ordinary food stockpiling is skipped while a trip is out and two meals remain; urgent other counter needs can still cost a stop. Private due dates, health, catch and mishaps are not used. No remote rescue or replacement horse purchasing is automated.

The roster and public health still govern work and dispatch. Main foraging is not skipped unless assigned foragers can overlap an already intended hunt/health stop. Companion nursing avoids a duplicate dedicated care action; a travel day does not grant nursing/foraging/drying for free. Genuine supply, nutrition, health and event stops remain. This is a strategy bundle, not a causal isolation of each rule.

## Counts and bounds

Development: seeds145000-145003; held-out:155000-155003. Three professions, May/July, three strategies, four seeds =72 journeys per phase,144 total. The shared world seeds recur across strategies and professions, not144 independent worlds. Both phases run frozen unchanged sources; no tuning to held-out outcomes.

Observation distinguishes actual distance-progress days from travel-attempt days (travel can spend a day and fail to advance), traveling days with an away hunter, camp-action days, and all stationary days. Stationary includes crossings, trading and event delays as well as camp; it must not be presented as entirely avoidable camping. Action totals expose these distinctions. An away-hunter travel day can include an overdue/stranded trip, so separate moving-hunt days count actual shots; moving catch is not treated as delivered food. Actual catch delivered on travel actions is tracked separately. Multi-job counts require executed work. Completed journey durations are compared only for matched pairs that both arrive; partial deaths/one-year caps cannot prove faster completion.

Focused tests cover real travel with a dispatched hunter, paid/packed departure, actual shared nursing/drying/foraging, observer state/RNG parity, and movement accounting. A clean isolated full test run is required. Runtime simulation is unchanged; previous camp-work cohort remains archived separately. Preserve player saves and preexisting debug pilots.
