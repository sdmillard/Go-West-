# Historical accuracy and current travel balance

Reviewed October 24, 2026. Historical evidence takes priority over classic-game rules. This is an audit of the current rules and a reproducible survival test, not a claim that every system has been historically calibrated. No game prices, health, yields, speed, wear, probabilities or save rules were changed by this work.

## Historical findings

| Topic | Evidence and current assessment |
| --- | --- |
| Timing and wagon progress | [NPS travel overview](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) gives broad 12-15 miles/day and four-six month travel context. Compare actual moving and elapsed days, not the unmodified base speed. [NPS trek overview](https://www.nps.gov/oreg/learn/historyculture/making-the-trek.htm) supports April/May departures and late mountain danger. It does not establish a historical win percentage. |
| Wagon load and oxen | [Palmer, 1847 guide, pp.258-263](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html) advises eight oxen and 2,500 lb. The [Oregon City museum compilation](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) describes four-six as a common minimum. These are differing recommendations. Our six-ox suggestion and four-ox normal team are defensible gameplay choices, not the one historical standard. |
| Opening food | Palmer lists 340 lb per adult of five weighed staples, with other goods additional. The game's 1,700 units for five people resembles that scale, but mixed food units, adult-equivalent eaters and 1/2/3-unit daily rations are abstractions. Keep meal value distinct from fresh-meat mass. |
| Pack loads | [Marcy, 1859, chapter IV](https://www.kancoll.org/books/marcy/machap04.htm) recommends 125 lb for a mule on a long journey and emphasizes pack fit. The game's uniform 200 lb per mule and 175 lb per pack horse are generous unsupported routine loads. The later guide is useful comparison, not proof that every 1848 mule had a 125 lb maximum. |
| Pack and walking speed | The game gives all non-mounted packers the emergency walking base of 12 miles before load, weather, terrain, fatigue and seasonal penalties. Marcy describes pack trains avoiding some wagon delays. A party with animals carrying its supplies should not be presumed to move like overloaded emergency refugees. This is a calibration concern, not a measured pack-train speed series. |
| Grazing and wear | [Marcy, 1859, chapter III](https://www.kancoll.org/books/marcy/machap03.htm) describes maintaining condition with good grass, water and management. The game instead charges at least one carrying-wear point even in ideal conditions. Poor country, haste and doubling should hurt; unavoidable deterioration on good grazing needs review. Horse rest recovery is a flat four outside waterless sections, while ox recovery already responds to season. That winter asymmetry is also unsupported. |
| Stock prices and budgets | Palmer records Bridger horses at $25-50 in trade, while his Oregon work-horse prices are much higher. Neither supports a universal cash tariff. Current $40 horses, $50 mules, $15 saddles, $5 pack saddles and $3 bags are authored estimates. The museum list gives very different mule and tack prices but spans dates/markets. Do not automatically replace one invented exact figure with a different decontextualized figure. Opening $675/$975/$1,475 includes buying the explicit $75 wagon; occupational wealth remains gameplay shorthand for liquidated assets. |
| Forts and dates | [NPS Fort Kearny](https://www.nps.gov/places/000/fort-kearny-state-historical-park.htm) dates construction from June 1848. The game already gates staffed crime targets before June and depicts a site, not a mature fortress. Fort John/Laramie is still a private post in this setting; Old Fort Boise is not the 1863 army fort. Finite counters remain authored inventory, not recovered receipts. |
| Scurvy and preserved fruit | [NIH vitamin-C reference](https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/) supports deficiency and storage/heat losses. Actual produce eaten now supplies the game's vitamin contribution. A shared deficiency counter, 25% dried retention, generic basket contents, 90-day storage and exact onset odds remain game estimates. Dried fruit is period-compatible; every dried basket should not be represented as a guaranteed antiscorbutic. |
| Cholera and other dangers | [NPS epidemic account](https://www.nps.gov/articles/000/cholera-a-trail-epidemic.htm) locates the major trail epidemic in the Gold Rush years. Automatic cholera is already gated from 1849. That is a scenario boundary, not proof of no possible 1848 case. Injury, treatment, attack, theft, pursuit and river mishap percentages have no verified historical denominators. Do not interpret simulated deaths or fights as emigrant population statistics. |
| Classic-game comparison | The locally archived 1978 BASIC transcription budgets money and abstract food credit; its quantities are not measured pounds. [Bouchard's hunting retrospective](https://www.philipbouchard.com/oregon-trail/hunting.html) identifies the 100 lb haul cap as a deliberate game decision. Retain classic structure and regional hunting without treating either formula as historical evidence. |

The dated source ledger is [HISTORY_MOUNT_BALANCE_SOURCES.json](../research/HISTORY_MOUNT_BALANCE_SOURCES.json). Older route, wages, preservation and location-art evidence remains in the linked specialist documents; this pass does not replace their date/place qualifications or claim a fresh visual inspection of the census scan.

## Method

The new [campaign](../tests/mount_balance_campaign.gd) uses actual public engine actions: departure, exact counter purchases, travel, camp rest, foraging, aiming and firing, recovering meat, preservation, crossings, care, trades and ordinary encounters. It never supplies free food, cash, health, animals or favorable weather. Observation is tested against the normal engine's state and random streams for all four travel modes.

Each run has five initial travelers with ordinary generated starting profiles and no custom paid contracts. All three profession budgets use the same declared outfit within a mode; affordability is checked before starting. Opening food is 1,700 for wagons, 450 for mounted and light packing, and 45 for walkers. Mounted parties buy five horses, three pack mules and appropriate tack; light packers buy three mules. Heavy packing separately tests eight mules and 1,400 food at a $579.30 opening cost. Walking preserves only a small legal load; it is an emergency stress case, not an equally provisioned expedition.

Policies use cautious pace, meager rations escalating when someone is sick or weak, care/rest, produce, actual resupply and optional salted preservation. Hunting uses visible targets and a separate seeded 65% aim-success decision; the 45% sensitivity is separate. That percentage is an input for the test actor, not a measured human hit rate. No-hunt cases continue to buy and forage. Mounted support buys useful replacement stock when affordable and rests carrying animals below 65 condition. The earlier current-policy behavior remains the default unless mount support is explicitly enabled.

Do not compare pooled success rates as independent historical probabilities: modes share seed blocks, starting food and costs differ, and decisions consume random streams differently. Spring, August, hunting and no-hunting outcomes stay separate. A year limit is recorded as such, rather than called a death. Policy stalls, illegal departures, broken state invariants, save failures and changed source files are errors, rather than defeats.

## Results

All **1,112 formal journeys** completed with **zero selected simulation, invariant, save, illegal-departure, source-change or policy-stall errors**. That is software evidence, not a successful balance verdict. Production simulation/data sources and the rules fingerprint are identical across formal reports. [Machine summary](balance-mount-summary-01.json) preserves configurations separately.

### Held-out spring departures

Default mount-aware cautious policy, salted preservation and 65% aim input; April and May, eight fresh seeds each. Each cell is **arrivals / intact arrivals out of 16 journeys**. Intact means all five original travelers remain.

| Opening mode | Farmer | Carpenter | Banker |
| --- | ---: | ---: | ---: |
| Six-ox wagon | 5 / 4 | 15 / 13 | 15 / 15 |
| Five riders + three pack mules | 0 / 0 | 0 / 0 | 13 / 10 |
| Three pack mules, travelers on foot | 0 / 0 | 0 / 0 | 0 / 0 |
| All on foot | 0 / 0 | 0 / 0 | 0 / 0 |

Successful wagon journeys had median elapsed days of 203, 236 and 220 respectively; successful banker mounted journeys had a 298-day median. Across the spring cells, wagon moving-day means were about 13-14 miles, packing about 8, and mounted about 17-20. Moving speed alone misses illness, rest, hunting, processing and winter delays. Elapsed times often exceed the broad NPS four-six month reference. Simply increasing mounted speed would miss that problem.

Without hunting, spring wagon arrivals were 2/16, 10/16 and 15/16 for farmer/carpenter/banker; banker mounted arrivals were 10/16. Other mounted budgets, packing and walking had none. In August hunting cells, wagons had 10/24 arrivals and mounted parties 2/24 across budgets; packing and walking had none.

### Check the test actor before blaming the rules

The provision-first policy buys larger reserves at posts and hunts below 30 units rather than 90. It uses fresh seeds 65000-65003, April/May, the same outfits and 65% aim input. It is **not a matched-seed causal comparison** with the table above.

Across eight runs per profession, wagon arrivals were 2/8, 7/8 and 6/8; mounted 0/8, 1/8 and 3/8. Light packing and walking still had none. One carpenter mounted success shows that a default-policy failure is not proof of universal impossibility. Several cells used far fewer hunts under the alternate policy.

Heavy packing bought eight mules and 1,400 food, affordable for every budget at **$579.30**. It had **0/72 arrivals** with the default policy across April/May/August and **0/24** with provision-first in April/May. Default-policy moving means were roughly 7.5-8.6 miles/day. Some rich parties survived to the one-year study limit without finishing. The time/resource problem persists under both policies; more stock and funds alone did not remove it.

### Separate stress and skill cohorts

| Cohort | Runs | Arrivals |
| --- | ---: | --- |
| Night guard, mounted/light packing, farmer/banker, May/August | 32 | 6 banker, all mounted; no farmer |
| Whole-expedition doubled riding, farmer/banker, May/August | 16 | None |
| Four-ox wagon, farmer/banker, May/August | 16 | 6 banker; no farmer |
| Abandon wagon at departure, farmer/banker, May/August | 16 | None |
| 45% aim, wagon/mounted, all budgets, April/May | 48 | Per-cell results in machine summary |

Guard and four-ox stresses have no separately matched control at their seed range, so no effect size follows from these counts. Whole-expedition doubling misuses an emergency dash; it does not test whether a short escape is viable. Departure abandonment is a worst-case start, not every late-trail recovery scenario.

### Evidence and reproducibility

- **183e399**: 216 development journeys and 80 guard/doubled/four-ox/abandonment stresses.
- **5b5a609**: 576 held-out journeys, 72 heavy-packing comparisons and 48 skill sensitivities.
- **3d2c9c5**: 96 provision-first comparisons and 24 provision-first heavy-packing journeys. This adds a test driver; production rules are unchanged.
- Checkpoint 3d2c9c5 passed **59 Godot suites**, including **300 mount-policy checks**. Checkpoint 5b5a609, with identical production sources, passed **24 store and 20 outlaw integrations** with zero reported errors. Logs and integration reports remain in ignored .tools/history-*.
- Development-01 detected changing test sources while running. Its 216 journeys remain an ignored diagnostic, excluded from the 1,112. The eight-run opening and three-run heavy pilots are also excluded. Player saves and original archives were preserved.

Raw archives record seeds, outfits, opening quotes, outcomes, actual days/moving miles, hunts/rests, nutrition, illness, stock and source hashes. Summaries retain mode, profession, month and hunting strategy separately. The summary tool rejects broken evidence: errors, missing/duplicate rows and missing source identity; deliberate invalid fixtures exercised those paths.

Example commands from the matching checkpoint; use unused labels:

~~~text
godot --headless --path . --script tests/mount_balance_campaign.gd -- --label=mount-heldout-new --seed-start=62000 --seeds=8
godot --headless --path . --script tests/mount_balance_campaign.gd -- --label=mount-heavy-new --seed-start=62000 --seeds=8 --modes=packing --strategies=salt --stress=heavy_pack
godot --headless --path . --script tests/mount_provisioned_campaign.gd -- --label=mount-provisioned-new --seed-start=65000 --seeds=4 --months=4,5 --strategies=salt
python research/summarize_mount_balance.py docs/balance-mount-heldout-01.json --output docs/balance-mount-summary-new.json
~~~

Reusing the original seeds reproduces evidence; validate later tuning with a fresh seed range.

## What this tests and what remains

The journeys exercise food/weight, health and scurvy, hunting skill and hauling, preservation, finite resupply, money, animal condition/loss, crossings, time and seasons together. Stress cohorts cover night guard, doubled riding, four oxen and voluntary abandonment. Full regression and store/outlaw integrations cover correctness of the wider mechanics.

This is not a new all-traits/all-crimes balance matrix, a human aiming/usability test, reconstructed 1848 weather, or a claim that every lawful strategy wins. Hired parties, extensive reverse travel, guarded caches, replacement recruits and every criminal strategy do not receive new population-scale balancing evidence here. Their existing regression checks and earlier campaigns retain their narrower scope.

## Calibration priorities

1. Separate ordinary pack-assisted foot travel from the emergency walking model. Calibrate actual moving and total elapsed days against plausible travel, keeping severe injury and overburdening consequential.
2. Reconcile sustainable pack loads, grazing, condition loss and seasonal recovery together. A lower nominal mule allowance without fixing time would make an already difficult pack expedition worse.
3. Recheck food, western resupply opportunities and hunting dependency after those changes. Preserve the distinction between missing meals, vitamin deficiency, spoilage and lost hauling capacity.
4. Review stock/tack prices with dated local evidence where possible; keep uncertain values labeled as estimates. Do not subsidize every bad outcome by raising starting cash.
5. Rerun a fresh validation seed range after actual rule changes. The results here diagnose current rules; they do not validate a future patch.

Historical fidelity and fairness mean coherent, understandable consequences and viable preparations. They do not require equal strength for walking, pack trains and wagons, nor a universally easy journey.
