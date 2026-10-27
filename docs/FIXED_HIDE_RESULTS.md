# Leathercraft from the same hide supply

**With collection held fixed, crafting changes none of the arrival outcomes in
this sample and adds a modest amount of gross income.** Production rules, wages,
prices, yields and starting money remain unchanged.

## Controlled setup

[Protocol](FIXED_HIDE_PROTOCOL.md) and test sources were frozen in commit6362680
before confirmation outcomes; production base58c54a0. The pilot at572900 is excluded.

Run32 source journeys: four fresh worlds572000-572003 across April/May,
none/two goats and free/hired artisan. The source policy is the released skilled
farmer crew strategy. Worlds recur across strata; there are not32 independent
worlds. Prior whole-journey income results are not pooled with this study.

**13/32 journeys** reach a real stopped state with a recovered deer hide and
artisan2 available to dress it. The remaining19 never qualify: eight arrive and
11 lose their parties. They are reported separately, not silently removed or
counted as crafting successes/failures.

For each eligible state, restore two independent engines from the **same full
save**, including inventory, health, weather, contracts, game random streams,
hunting aim and policy counters. One branch can sell the skins; the other can
retain a pipeline and craft during already needed camp days. Neither branch
collects additional pelts. The 13 checkpoint batches contain **19 prepared rough
deer hides** in total, and their initial states match exactly in each pair.

The test does not force five rest days or promise that the artisan will finish.
Nursing, food preservation, forage, animal care, paid work, illness and willingness
continue to compete for their time. Holding material itself can change trade visits
and survival decisions, even if no craft stage is completed.

## Results after the checkpoint

| Measurement | Sell existing skins | Allow crafting |
|---|---:|---:|
| Eligible continuations | 13 | 13 |
| Reach Oregon | **3** | **3** |
| Arrive with >=4 original travelers present | 1 | 1 |
| Cases doing any crafting | 0 | 5 |
| Cases selling finished leather goods | 0 | 4 |
| Total gross receipts | $28.88 | $31.73 |
| Pelts | $10.88 | $8.08 |
| Finished goods | $0 | $7.65 |
| Keepsakes | $12.00 | $12.00 |
| Paid work | $6.00 | $4.00 |
| Sale visit days | 11 | 12 |
| Unmet meal food units | 610 | 644 |

These are totals over each arm's13 continuations, **not per-journey earnings or
profit**. Additional finished-goods sales are partly offset by fewer raw-hide sales
and less employment. The median matched gross-income difference is **$0**.

Crafting completes19 actual worker-days: five scraped hides, four softened hides,
four buckskins, three cut batches and **12 glove pairs**. All12 pairs and one
buckskin sell. One started hide does not reach finished buckskin. Eight eligible
continuations never perform a craft stage; eligibility at the checkpoint does not
guarantee spare work capacity later. No new skins or free materials enter either
branch. There are no extra pelt-preparation days after the common checkpoint.

No matched arrival is gained or lost. Among the **three shared arrivals**, crafting
arrives on the same day, seven days earlier and16 days earlier (median -7).
This tiny, selected group does not establish a general speed advantage. Across
all13 pairs, the median difference in elapsed time to the terminal outcome is0;
for losses, a later terminal day is not necessarily improved progress.

| Artisan / livestock | Source journeys | Eligible pairs | Skin-sale arrivals | Craft arrivals |
|---|---:|---:|---:|---:|
| Free / none | 8 | 2 | 1 | 1 |
| Free / two goats | 8 | 3 | 2 | 2 |
| Hired / none | 8 | 6 | 0 | 0 |
| Hired / two goats | 8 | 2 | 0 | 0 |

Checkpoint days range157-222, median194. This is a **late, cash-pressured conditional
sample**, not a test of earning through an artisan throughout a well supplied
journey. The existing source policy only starts considering pelts below$20. Hired
cells retain the prior veteran/loyal artisan and real weekly automatic contract;
results cannot be generalized to every hire or wage agreement.

## What this tells us

Leatherworking can add value to an existing hide, but it is a small supplementary
income source under these rules and priorities. Same-supply crafting does not
reproduce the three arrival losses seen in the earlier whole-strategy comparison;
that is consistent with investigating extra hide collection/preparation and sales
stops as costs. Different seeds, conditional selection and changed future harvest
rules mean this does **not** prove those costs caused the earlier losses.

The useful next balance investigation is **when earning and material processing
become available**, before the party is already in crisis. A low gross cash return
from late optional crafting is not grounds by itself to increase historical wages
or guarantee that a hired artisan pays their way. No tuning was made here.

## Evidence and reproduction

- `tests/run_fixed_hide.ps1` runs all32 source cases, refuses overwrites and archives
  the complete raw report/checkpoints plus SHA-256 receipt under ignored
  `.tools/fixed-hide-archives/`.
- `tests/summarize_fixed_hide.py` checks every declared cell, identical branch-start
  hashes, actual recovered materials, zero new harvest, sequential meal days,
  recipe/input conservation, real sales and weekly billing. Four corrupt evidence
  cases must be rejected. `--check` revalidates the published artifact.
- [Machine-readable results](fixed-hide-results-01.json) retain every source case,
  branch outcomes, per-case income/material results, exact source hashes and the
  raw archive receipt. Full saved checkpoints remain in the raw archive.
- `tests/test_fixed_hide.gd` has10 focused checks: complete save parity, independent
  modules/RNG, a next-day comparison against the plain production restore,
  unchanged sibling state, accurate post-fork day counting and eligibility gates.
- The previous96-case report also revalidates unchanged; log
  `.tools/fixed-hide-prior-evidence-check.log`.

**All98 Godot suites pass**, including the10 new checks. All32 source journeys and
26 continuations finish with zero recorded errors. Eligible checkpoints and the
periodic/final continuation save checks pass. Independent
verification and four negative accounting checks pass. Full suite log
`.tools/fixed-hide-full-tests-01.log`, SHA-256 `43196ef169042afe32bab6ff825902e2583231d11a4768241bfb9241bbfc56f2`.
