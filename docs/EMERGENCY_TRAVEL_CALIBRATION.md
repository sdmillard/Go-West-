# Emergency travel and hunting calibration

October 24, 2026. Implementation checkpoint 267c495; game rules fingerprint
02285c8f33534be2cfbab8846219c5186d8c2acbc47f2f81f757e28ee5ea01ed.
This is a targeted correction after the [preceding historical/mount audit](HISTORY_AND_MOUNT_BALANCE.md), not a declaration that every survival mode is balanced.

## What changed

A successful hunt previously charged that day's meals before the catch existed and then rejected meat that did not fit the packs. A sick party could kill an animal and starve while leaving all its meat behind.

Starting a hunt now locks other actions. Returning settles one real day: the catch, limited by health and willing helpers, can feed camp before the remaining meat is packed. The final report separates pounds eaten, pounds packed, packed food units, meat left behind and any other camp loss. Every physical pound is accounted for. It keeps existing supplies, uses actual post-meal capacity and retains the original batch expiry/mass ratio. No temporary field-meal markers survive in saves.

Species yields, ammunition, aiming, retrieval capacity and food conversion have not increased. Deer currently yield 42-85 usable pounds, supplying 21-42 food units. Five people on filling rations need 15 units/day: roughly 1.4-2.8 days of food if the remainder is usable. A kill is not guaranteed, carried meat still spoils, and no persistent carcass cache was added. Existing Camp > Preserve meat processes carried meat; the abandoned catch cannot be recovered later.

Missing food now adds fractional missed ration-days. Initial damage is 2 health/day of total shortage, rising every seven deficit days to a maximum of 6; partial meals reduce the shortage. Ordinary and filling meals repay 0.5 and 1 deficit-days respectively, while bare-bones meals do not repay debt. Health recovery waits until a later fully fed day after the deficit clears, preventing alternate fasting/rest from manufacturing health. Hunger also adds fatigue. These are authored tuning values, not a clinical starvation clock. Injury, illness, thirst and exposure remain separate.

Offscreen wagon guards use the same shortage transition, with their own cache deficit. When surviving guards rejoin, the larger deficit is retained in the shared party model. This is a conservative abstraction, not individual nutrition tracking. Deficit precision is canonical to thousandths so fractional meals save and replay exactly. Previous-rule saves load without inventing past deprivation; a genuine pre-change save is tested.

Walking base pace rises from 12 to 20 guide miles/day, with pack-assisted walking using 22. Weather, terrain, season, pace, burden and fatigue still reduce actual progress. Mounted base pace remains 32. Broken legs still prevent hauling; personal capacity still scales with health.

## Evidence and limits

The dated [source ledger](../research/EMERGENCY_TRAVEL_SOURCES.json) distinguishes observations, historical summaries and authored game choices.

- [BLM's historical summary](https://www.blm.gov/sites/default/files/docs/2025-12/nhotic-student-pre-reading.pdf) describes emigrants usually walking, aiming at 20 miles but commonly managing 10-15 miles/day. Those walkers had wagon support; this is not evidence for unlimited wilderness subsistence.
- [The 2021 Hadza GPS study](https://pmc.ncbi.nlm.nih.gov/articles/PMC8060163/) records task-dependent daily foraging movement. Search loops and camp activity do not directly measure sustainable point-to-point marching speed. Group averages are not character ethnicity or sex modifiers.
- [Primary research on subsistence energetics](https://doi.org/10.1126/science.abf0130) supports considering high effort, variable returns, skill, technology and sharing together. It does not imply guaranteed daily kills or that berries alone supply a full diet.
- [Experimental load-carriage research](https://pmc.ncbi.nlm.nih.gov/articles/PMC3922835/) supports a cost for carrying weight, but its treadmill measurements do not supply an exact trail pace formula.
- [Clinical fasting research](https://www.jci.org/articles/view/105481) establishes metabolic adaptation, not an outdoor survival deadline. A modern long-distance hiker case is also a limited comparison because of fitness, equipment and resupply.

The 20/22 pace bases and shortage constants are game calibration constrained by this context and tested behavior. Current food units are an abstract basket; this patch does not claim a complete calorie/protein/fat budget. Foraging mainly provides produce/vitamins, not the full range of roots, nuts, tubers, honey and learned practices used by real subsistence communities.

## Matched emergency comparison

The driver is tests/emergency_travel_campaign.gd. Initial snapshots place five travelers 30, 75 or 150 guide miles east of Fort John/Laramie, in June or August, with ordinary health, health 60, or one broken leg. The wagon control keeps its team; other modes lose all oxen and perform the actual legal abandonment/packing action. Horse/mule stock, supplies, banker liquidity and all other initial conditions are declared. After preparation, real provision-first actions encounter natural weather, illness and events. Success means reaching the post within 45 elapsed days, not completing Oregon.

Development used seeds 67000-67003 (288 cases/version). Final held-out comparison used 69000-69007 (576 cases/version). Before is master 39776c2; after is game checkpoint 9606e2f. Later commits change tests/docs only. No gameplay tuning followed the final sample.

[The compact paired archive](balance-emergency-heldout-02-summary.json) verifies that every initial save matches exactly after removing only the rules fingerprint. It preserves source hashes, per-case fixture hashes, outcomes and metrics. Full snapshots are retained locally in ignored .tools/emergency-{before,final}-heldout-raw.json. The publishing script rejects missing/duplicate cases, changed initial fixtures and recorded campaign errors; all four rejection paths were checked with deliberately corrupted copies.

Each cell below contains 48 cases (3 distances x 2 months x 8 seeds). All successful emergency cases retained all five original travelers.

| Mode / health | Reached help before | Reached help after |
|---|---:|---:|
| Walking / ordinary | 20/48 | 42/48 |
| Walking / health 60 | 0/48 | 0/48 |
| Walking / one broken leg | 0/48 | 20/48 |
| Wagon / each health case | 48/48 | 48/48 |
| Packing / each health case | 48/48 | 48/48 |
| Mounted / each health case | 48/48 | 48/48 |

Ordinary walking by distance: 30 miles 14/16 -> 16/16; 75 miles 6/16 -> 14/16; 150 miles 0/16 -> 12/16. These are descriptive results of one explicit policy, not population survival probabilities.

Health-60 walkers still fail this policy. Low gross capacity leaves little food space after fixed gear; the actor can spend most days hunting/resting instead of progressing. The field-meal fix removes starvation despite a successful daily catch in controlled tests, but does not prove those travelers can march between posts while ill. That remaining capacity/recovery problem must not be hidden by the aggregate improvement.

## Whole-route check

The same provision-first journey policy ran 128 journeys/version: farmer/banker x wagon/mounted/packing/walking x April/May x 8 fresh seeds (69000-69007). Raw archives: [before](balance-emergency-route-before-02.json), [after](balance-emergency-route-after-02.json). Both report zero selected invariant/save/setup/policy errors.

Each row is 16 journeys. Arrival counts are followed by intact original parties in parentheses.

| Mode | Farmer before -> after | Banker before -> after |
|---|---:|---:|
| Wagon | 2 (2) -> 5 (2) | 14 (14) -> 15 (15) |
| Mounted | 0 -> 0 | 9 (7) -> 14 (9) |
| Packing | 0 -> 0 | 0 -> 8 (7) |
| Walking | 0 -> 0 | 0 -> 0 |

Arriving banker median elapsed days: wagon 216 -> 217, mounted 224 -> 247.5, packing after 327.5. Newly surviving slow journeys can raise elapsed medians; do not describe these as historical-duration fidelity. After-change farmer wagons have two year-limit cases; banker packers have four. Failed routes are retained in the archive. Shared seeds/configurations are paired scenarios, not independent human playtest observations.

Whole-route development used seeds 68000-68003 (64 journeys/version). Intermediate runs before the hunting fix remain local diagnostic evidence and are not pooled into final totals.

## Verification and remaining work

Checkpoint 267c495 passed all 60 Godot suites in a clean isolated checkout. Identical production sources at 9606e2f also completed 24 store and 20 outlaw integration journeys with zero reported errors. Logs and verified reports are retained in ignored .tools/emergency-*. Tests cover gradual deprivation, partial meals, recovery, fasting exploits, genuine old saves, deterministic fractional saves, a broken-leg hauling exclusion and seven successive controlled successful hunts by a health-60 party. Retained meat fits actual capacity and every pound is eaten, packed, left or explicitly lost elsewhere. A failed hunt still spends its day. Native Godot hunting-report layout was rendered and inspected at 800x360.

An older full-trail regression actor could acknowledge an overweight warning forever after survival improved. It now discards actual surplus goods or takes a real recovery day; the capacity rule was not relaxed. Hunting observers count actual packed food and field meals separately, rather than interpreting net inventory changes as yield.

Still open: weak-walker fixed gear/recovery and opportunities to carry preserved calories; full-trip low-budget pack provisioning; horse/mule load and grazing wear; seasonal animal recovery; real player hunting accuracy and clarity. A larger pack allowance or a new campsite carcass feature would require its own design and fresh validation. Earlier balance archives retain their original rules and are not current balance sign-offs.
