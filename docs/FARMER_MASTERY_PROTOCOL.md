# Farmer strategy mastery: frozen comparison

October 26, 2026. The question is whether informed use of the mechanics can sustain a farmer, rather than whether one fixed test script succeeds. This is a bounded test of explicit candidate strategies, not proof of an optimal human strategy or of universal winnability.

## Fixed gameplay and resources

Gameplay remains the version in `2ba568f2596e378861870e30ecc5c5e82d84c1bf`; simulation/data are unchanged. Every candidate uses the same $675 total starting assets, default five travelers, standard six oxen/1,700 food or lean four/1,200, shared horse/saddle/bags, 20 dried produce and original supplies. Compare no livestock and two goats. Same steady pace, lawful decisions, route alternatives, prices, weather/illness, carrying limits, finite stocks, meals, care, field risk and existing current-gap hay strategy. No free resources, invulnerability, save rerolls, outcome-based seed selection or knowledge of future random events.

The candidates act through existing public actions and quotes. The 65% and 85% shot-execution settings are explicit; improvement in the 85% candidate is not attributed to planning alone. They can use current food/health, visible supplies/prices, dates and public route knowledge (including the long stretches after Fort Laramie and Forts Hall/Boise). Numeric thresholds approximate visible condition/supply bands. They do not read RNG state or forthcoming encounters to choose actions. Shot execution is simulated explicitly and reported separately.

## Candidates frozen before fresh cohorts

1. **Baseline (65% aiming):** unchanged ordinary dairy-study decisions. The new diagnostic subclass must reproduce the same selected baseline journey outcomes. Existing auto-Filling for any active illness/<80 health, late food-window dispatch and foot hunts remain.
2. **Ration-only (65%):** Normal by default; Filling for serious illness or Poor condition only while eight Normal party-days of carried food remain. This is an economy candidate, not a claim that lower rations are always wise.
3. **Planning candidate (65%):** the skilled strategy below with the same shot execution as baseline, to separate planning from improved aiming.
4. **Planning + stronger execution (85%):** identical planning, better but imperfect hunting aim.

The planning candidate uses Filling preventively when well supplied (at least twelve Filling party-days or two Filling meals of fresh meat), economizes otherwise, and keeps deliberate recovery rules. It sends an eligible healthy outrider before supplies become scarce, only with at least three current party-meals and a mount at 65+ condition. It permits the leader to hunt while a rider is away instead of waiting until the last meal, and starts hunts at four-meal reserve rather than two. It chooses an existing whole-party wagon hunt when its public quote is valid, falling back to the usual foot outing where the wagon cannot go.

At open counters it builds one valid useful basket using actual prices, stock, cargo and cash: dried produce preferred when no produce remains and deficiency gap reaches ten days or scurvy is present; five baskets at a post or three on the road, fresh two if dried unavailable. It avoids gratuitous time-costing micro-visits for salt or ammunition alone unless urgent. It keeps $10 before Barlow, $2 afterward, and may spend down to $2 in a food emergency. It targets ordinary food 300 or 25 Normal party-meals at posts, 90 or seven meals on the road, with refill triggers at ten/four meals respectively; known upland/dry provisioning points target 900 at Fort Laramie and 600 at Hall/Boise, subject to actual money and capacity. Those are declared choices, not extra stock or cash. Grain/hay retain their public purchase constraints.

Companion drying is assigned for a meaningful quoted surviving surplus near expiry (at least one unit per current party member, minimum two), without displacing the reserved caretaker, nurse/patient or designated foragers. The leader dries a quoted surplus of at least one party-meal near expiry. Quotes retain normal spoil-before-meals-before-processing rules. All drying consumes real time/labor/salt and does not rescue expired meat. Existing health-rest limits and caregiver behavior are retained. No party traits, initial outfit redesign or hunt-yield changes are added.

## Cohorts and acceptance

Development seeds **495000–495003**, sealed confirmation **505000–505003**. Four candidates × two outfits × no-stock/goat arms × May/July × four seeds × two phases = **256 complete journeys / 32 reports of eight**. Four underlying seeds repeat across settings per phase; not 256 independent worlds. Every declared cell must finish and remain reported. No candidate is changed between development and confirmation. Do not select only winning starts or mix development pilots into the results.

Reserved pilots 489990–489993 were used to develop the candidate, including rejected over-shopping/late-hunting versions. Their reports remain separate and excluded. The final standard-May pilot arrived with four originals on two of four cases, but that is development evidence only. Pilot iterations replayed development cases to improve generic planning, not to select a favorable action using future encounters; all are excluded from the fresh cohorts. Baseline/observer plumbing seed 489989 and unit seed 489988 are excluded. Future candidate revisions require a new version and fresh held-out seeds.

Report arrivals, original travelers present/alive, dates and winter exposure, shortages, scurvy, money/spending, stops, hunts and actual field returns. Separate ordinary planning from shot execution and report May/July and outfit cells. A success with one survivor is not the same as four or all five. Preserve unsuccessful and error cases.

Read-only food counters classify raw-meat, preserved-meat and produce spoilage and count **all executed drying**, including companions. The old figure below one was leader-only; prior companion drying averaged 0.875–1.458 batches/38–78 units retained by arm. Legacy batch `pounds` are food units; actual physical mass comes from `mass_ratio`, so the old threshold was not a pounds-versus-calories error. No preservation engine change is justified solely by the counter label.

Require source/rule fingerprints, exact initial $675 budgets, matching carts, full cohort counts, meal consistency, classified spoilage equaling actual loss, public-action constraints and no state/save/policy errors. Run the full suite and plain/observed tests. Raw reports and pilot diagnostics stay locally in ignored `.tools/`; publish compact provenance and limitations. These candidates are not an assertion that all human expertise has been searched if they fail.


## Frozen source and launch

Use `tests/run_farmer_mastery.ps1` with the locally archived manifest. Labels distinguish baseline, ration-only, planning at 65%, and planning at 85%; both planning entries run the same skilled decision code. All candidates remain on the same gameplay version, with only test-strategy flags added to the inherited mobile driver (defaults preserve old behavior). Two excluded regression replays of seed 475000 exactly reproduced the prior no-stock standard and goat lean records on every previously recorded journey field, confirming baseline compatibility. The food classifier is independently state-neutral in controlled tests. No source or candidate changes are permitted during the matrix.
