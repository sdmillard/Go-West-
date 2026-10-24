# Nutrition, weak packs and the cost of caution

October 24, 2026. Spencer asked to address nutrition and weak walking first, and challenged the assumption that long elapsed journeys prove time costs are wrong. His usual play keeps moving with sick companions, rests briefly, and reserves longer stops for serious trouble.

**This nutrition/risk change does not alter travel speeds or day costs.** The published build also preserves the independently merged horse-balance PR #84; its animal-load changes are checked separately below. The study now distinguishes cautious play, brief stops and pushing on. The results show a worthwhile payoff from riskier decisions without establishing that every late arrival is a timing bug.

**Current carrying rule:** [Field outings and shared health breakpoints](FIELD_OUTINGS.md) replace the walking relief formula below. Good/Fair now retain full capacity; Poor/Very Poor reduce it smoothly for walkers and retrieval alike. Existing nutrition changes remain.

## Gameplay changes

### Scurvy can start improving before it disappears

Previously, scurvy inflicted full damage even on a day with adequate vitamin-C food. The same meal advanced recovery, so a weak person could die while being fed the very food needed to recover.

Adequate vitamin-C meals now stop that day's scurvy damage. The existing fourteen nutritional recovery-day requirement remains; rest advances it faster, but **recovery can continue while traveling**. A day without enough vitamin C resumes the damage and pauses progress. Other diseases, hunger, injuries and weather are unaffected. Meat does not acquire vitamin C. Merely purchasing or carrying fruit still does not feed anyone.

This distinguishes early response from complete recovery, consistent in broad terms with [NHS guidance](https://www.nhs.uk/conditions/scurvy/) and a [professional reference](https://www.merckmanuals.com/professional/nutritional-disorders/vitamin-deficiency-dependency-and-toxicity/vitamin-c-deficiency?media=print). A [primary clinical case series](https://pmc.ncbi.nlm.nih.gov/articles/PMC11316608/) also documents the mobility consequences of deficiency. The [source ledger](../research/RECOVERY_AND_RISK_SOURCES.json) records their limits. The game's meal threshold and zero treated-day damage are authored tuning, not a clinical dose or mortality model.

### Moderate illness leaves some food room

The old walking rule interpreted the abstract health score as a linear percentage of carrying strength. Five people at health 60 had only 120 lb total capacity. Their 110 lb of actual gear left ten pounds for food: just five fresh-meat food units, despite needing fifteen on filling rations.

Pack capacity now uses f * (1 + max(0, 0.85 - f)), where f is the existing individual health/injury factor. Starting-health 85 and healthy 100 capacities remain 170 and 200 lb. Health 60 gives **150 lb**, leaving **40 lb** after the same gear. Health 50 gives 135 lb. Capacity still falls monotonically with health; the seriously ill can remain unable to carry enough. Dead, departed, guarding or broken-leg carriers still contribute zero.

This is an explicit game calibration, not a scientifically measured strength curve. It preserves the existing starting outfit, full-health allowance, actual gear weight and capacity-derived previews/saves. Hunting and robbery retrieval keep their existing linear health factors and 200 lb ceiling: no extra carcass or free food is granted. Wagon and animal cargo allowances are unchanged.

## Study-player corrections

The prior actor confused prevention with treatment: even after a scurvy diagnosis, it could wait for the normal twenty-day produce interval. It now seeks available produce/forage for active scurvy, with actual search days, stock, season, money and food costs. Prevention timing remains separate. This correction is applied identically to both production versions.

Three declared strategies use ordinary parties, three professions, April/May starts, the same supplies and 65% scripted aim:

| Decision | Cautious | Brief-stop traveler | Bold |
|---|---:|---:|---:|
| Pace | Slow | Slow | Steady |
| Health rest trigger | Below 55 | Below 35 | Below 20 |
| Consecutive ordinary health-rest days | Uncapped | 1 | 1 |
| Critical health exception | Uncapped | Up to 3 while below 20 | Up to 3 while below 20 |
| Seek care below | 55 | 35 | 25 |
| Rest working oxen below condition | 65 | 50 | 35 |

The limited actors resume moving before everyone is well. Animal exhaustion, overloads and fatigue still receive actual responses. These are bot choices, not restrictions on the player's 1-30 day camp rest control. Lower team condition can reduce speed or worsen emergencies, so skipping rests is not automatically a free gain.

## Matched and fresh evidence

The [original audit](balance-recovery-risk-02-summary.json) contains **1,440 source-frozen cases with zero selected state/save/setup/policy errors**, checked by the [protocol](../research/RECOVERY_AND_RISK_PROTOCOL.json).

- Full-route development: 72 before and 72 after, seeds 81000-81003.
- Fresh full-route validation: 144 after, seeds 82000-82007.
- Matched declared emergency fixtures: 288 before and 288 after, seeds 83000-83003.
- Fresh emergency validation: 576 after, seeds 84000-84007.
- Earlier dev-01 pilots preceded the treatment-policy correction and are excluded. No gameplay tuning followed the fresh validation.
- Baseline production is d9ad653, with identical study decisions frozen at 361055f. After-game checkpoint is 6de28c5. Source hashes and initial emergency fixture hashes are retained; every initial emergency matches after removing only its rules fingerprint.

### Risk can pay off

Each fresh strategy has 48 journeys (three professions, two months, eight seeds):

| Strategy | Arrived | All five originals arrived | Median days among arrivals | Arrived by September 30, 1848 |
|---|---:|---:|---:|---:|
| Cautious | 35/48 | 29/48 | 231 | 0 |
| Brief-stop traveler | 37/48 | 30/48 | 231 | 2 |
| Bold | 39/48 | 31/48 | 202 | 6 |

Among the **34 matching cases in which cautious and bold both arrived**, bold was faster in 24, with a median difference of **14.5 days saved**. Five cases arrived only under bold play; one arrived only under cautious play. This is a meaningful payoff, with exceptions.

The 29-day difference between the separate arrival medians compares different surviving cohorts; it must not be described as a guaranteed 29-day causal saving. Brief health stops alone did not improve the overall median in this sample. Faster pace, less care, animal condition, provisioning, season and the resulting events all interact.

Dates are computed from each actual April/May 1848 start plus elapsed days. An arrival in spring 1849 is not miscounted as reaching Oregon by September 1848 merely because its month number is small.

September is possible under the tested bold policy, but is not yet typical. The result supports leaving global speed and stop prices alone while investigating decisions and food/shopping behavior. It does not prove that excessive caution explains every delay or that this actor reproduces Spencer's choices.

### Weak walking improves without guaranteed rescue

Matched development, each walking health group has 24 cases:

| Initial condition | Before reached help | After |
|---|---:|---:|
| Ordinary | 19/24 | 21/24 |
| All at health 60 | 0/24 | 20/24 |
| One broken leg | 14/24 | 19/24 |

Fresh validation, each walking group has 48 cases: ordinary **44 reached help, all intact**; health 60 **36, all intact**; one broken leg **41 reached help, 40 intact**. Animal-supported controls all reached help. These are emergencies 30/75/150 miles from a post, not equal-supply walks from Missouri to Oregon.

Overall fresh emergency success is 553/576, with 552 intact parties. Remaining failures retain hunger, illness, injury, season and carrying constraints. The result is a usable emergency route, not an automatic rescue.

### Nutrition remains a decision problem

The gameplay correction removes full scurvy damage on adequate treatment days. It does not create produce where none exists or erase prior malnutrition. Fresh whole-route scurvy deaths were 25/25/16 under cautious/traveler/bold policies. The matched development changes were modest: cautious arrivals 20 -> 21, traveler 18 -> 18, bold 19 -> 19. It would be misleading to claim that scurvy or full-route survival is now completely balanced.

Regional scarcity, winter crops, four-pound produce units, binary nutritional credit and repeated food decisions remain abstractions worth watching. The separate forage-day and collection rules are unchanged. The next timing investigation should model the player's purchases, hunts and decisions to press on, rather than assume everyone ought to wait for full recovery.

## Verification and compatibility

Checkpoint 6de28c5 passed **all 62 Godot suites** in an isolated checkout, including 119 nutrition/pack, 216 policy, 56 emergency and 33 meat-accounting checks. The same checkpoint passed **24 store and 20 outlaw integration journeys**, zero reported errors. There are no UI/art changes.

Tests check weak severe scurvy surviving sustained nutritional recovery, deterioration when intake stops, unrelated illness still causing damage, monotonic pack capacity, broken-leg exclusion, unchanged retrieval limits, actual gear mass, brief-stop progression, early active treatment and JSON saves. A real preceding walking save loads without changing inventory, health, time or random streams. Existing old saves remain supported. One repeated-hunt assertion was corrected to accept meals from retained meat instead of requiring every day's newest catch to be eaten first; pound conservation and absence of hunger still apply.

Pre-merge checkpoint fingerprint: 95ac2b1f8aa23ca82be1c5abdae8ade04eb29346cdbc40c1951b8cf63dd3b744. Previous 6927c03c33aba3ab718e02606b39caa53355a215aa4182c564764aa580dc5403 is whitelisted.

Raw reports, excluded diagnostics and integration evidence are hash-verified in ignored .tools/recovery-evidence/. Public compact rows retain actual outcomes, counts, daily audits, fixture identities and computed dates. The publishing script reuses strict source/configuration/completeness checks and validates matching strategy scenarios and serialization. Preserve counterfactual branch codex/recovery-before-policy to reproduce the baseline. Player saves, earlier archives and the three local debug pilots are preserved.


## Concurrent horse update: combined publication

PR #84 (ac0072e) landed during this work. It reduces certain horse forage strains, treats all-mule strings differently and starts animal load drag later. Those independent changes are preserved. They are not nutrition changes or a new global timing adjustment.

Combined checkpoint **ddfab02** passed **all 62 suites**, now including **120** nutrition/pack checks and a genuine save captured from the horse-update build. The same checkpoint passed 24 store and 20 outlaw integration journeys with zero errors.

The [combined audit](balance-recovery-risk-03-summary.json) retains the original evidence and adds **752 combined checks**, for 2,192 versioned cases in total:

- **144 replays**, using the original final route seeds and decisions. Every scenario row, including outcomes, supplies, timing, daily audits and decision counts, matches exactly. These are replays, not independent new validation. The preceding wagon risk comparison therefore still applies to this combined build.
- **576 fresh emergency fixtures**, seeds 85000-85007: 531 reached help, 528 intact. Ordinary walking 43/48 intact; health-60 walking 32/48 reached help (29 intact); one-broken-leg walking 24/48 intact. All 432 animal-supported controls reached help. These use different seeds from the earlier fresh sample; do not attribute rate differences to the horse update.
- **32 fresh mounted/packing journeys**, seeds 86000-86003, April/May, salted provision-first, carpenter/banker. Arrivals out of eight each: mounted carpenter 2 (none intact), mounted banker 8 (7 intact), packing carpenter 2 (none intact), packing banker 8 (6 intact). Median banker arrivals: mounted 171.5 days, packing 221 days. This confirms that the combined animal mechanics run through full journeys, not that all budgets or parties are equally viable.

Current combined fingerprint: 38d5a0bdaca9f681aca65bb45c0da8a41029739b67400ff71cf0941e09647a75. Both the actual horse-update fingerprint 6f29f0fae730d228ef155a3a0b59928eb063602af261d95367b39519317f186f and the pre-merge nutrition fingerprint are whitelisted, along with the prior supported versions. Actual older journey state and random streams remain intact on migration. All evidence is labeled by its real source version.
