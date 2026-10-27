# Wage crews and leathercraft: integrated balance results

October 26, 2026. **Income helps in some cases, but this crafting strategy is not
a survival improvement.** No production wages, prices, food yields or health rules
were changed. This is a completed test, not a claim of final balance.

## What was tested

[Protocol](CREW_CRAFT_PROTOCOL.md) was frozen in commit
`58f38a169c4ead459626072e8d6d551883f5c567`, before confirmation outcomes.
Production base: `581fc4ab64a21122afef880f39ec782adca74b4a`.
There are **96 journeys / 32 matched triplets**, using four fresh seeds
571000-571003 across April/May, no livestock/two goats, and free/hired artisan.
The same four worlds recur in these strata; these are not 96 independent worlds.
Two development pilots at 570900 were excluded. Previous income studies used
other rules/policies and are not pooled here.

Each party has Carpentry, Leatherworking, Hunting and Caregiving companions, a
shared horse, five optional keepsakes, and the established skilled farmer survival
policy (65% seeded hunting accuracy, adaptive rations, nursing, preservation,
foraging, fishing opportunities, mobile hunters and animal care). No extra money
or hides were injected into journeys. Starting resources and profiles match
exactly across each triplet. Lawful play; no replacement recruitment.

- **Off:** existing survival, no new income activities.
- **Crew:** actual-kill pelts, consented keepsake sales and maximum-gross legal
  work crews when cash is below $20 plus a weekly contract bill. Normal buying,
  food gates, nursing, reserved livestock carers and finite jobs apply.
- **Craft:** same income rules, plus leathercraft on existing stopped days and
  one reserved material pipeline when affordable. Harvest valuation can prefer
  deer hides using potential glove resale, so this tests a whole crafting strategy,
  not merely the effect of a craft button on identical harvested hides.

The hired artisan has Veteran/Loyal, one Proud flaw and a market-priced automatic
weekly contract: **$7.00 or $7.70**, depending on the seeded profile. This is a
specific relatively expensive hire, not evidence about every possible mercenary.

## Arrivals and survival

| Party setup | Off | Crews and sales | Crews, sales and crafting |
|---|---:|---:|---:|
| Free companions (16 each) | 12 | 11 | 10 |
| Hired artisan (16 each) | 1 | 4 | 2 |
| All arrivals (32 each) | **13** | **15** | **12** |
| Arrivals with >=4 original travelers present | 7 | 7 | 5 |
| Recorded food-related deaths | 29 | 18 | 29 |
| Unmet meal food units | 2,062.871 | 1,320.623 | 1,461.623 |

No arrival was before October. Hired-artist arrivals never retained four original
travelers. Arrival alone therefore overstates party success.

Matched results versus off: crews gain five arrivals and lose three; crafting gains
two and loses three. Compared directly with crews, crafting gains none and loses
three. These are descriptive outcomes of four seeded worlds, not probability
estimates or proof of an optimal strategy.

Among the ten shared off/crew arrivals, the median day difference is +3 (range
-6 to +39). Off/craft also has ten shared arrivals: median +3, range -6 to +101.
These conditional timing figures exclude unmatched failures.

| Setup / livestock | Off | Crews | Craft |
|---|---:|---:|---:|
| Free / none | 6/8 | 5/8 | 4/8 |
| Free / two goats | 6/8 | 6/8 | 6/8 |
| Hired / none | 1/8 | 0/8 | 0/8 |
| Hired / two goats | 0/8 | 4/8 | 2/8 |

The goats are not held free of their care, purchase, feeding or survival costs.

## Money, materials and time

Each income column below totals its own 32 journeys; these are **gross receipts**,
not profits or an individual player's expected earnings.

| Measurement | Crews and sales | With crafting |
|---|---:|---:|
| Gross receipts | $524.28 | $660.84 |
| Local employment | $212.20 | $212.20 |
| Keepsakes | $184.50 | $184.50 |
| Pelts | $127.58 | $137.60 |
| Finished leather goods | $0 | $126.54 |
| Paid worker-days / calendar workdays | 181 / 105 | 181 / 105 |
| Actual workday meals eaten (food units) | 1,180 | 1,180 |
| Sale visit days | 136 | 154 |
| Pelt preparation days | 171 | 251 |
| Pelt preparation meals (food units) | 1,014 | 1,582 |
| Hunt return haul displaced by skins (lb) | 1,102.5 | 2,225.5 |

The market wage floor adds **$4.20 total** above nominal local job rates in each
income arm. Every worker's actual receipt matches max(job rate, market quote).
181 employees are not incorrectly counted as 181 separate party meal-days.

Crafting operates in 10/32 cases, sells finished goods in 9, and performs **293
real worker-days**: 63 scraped hides, 62 softened hides, 60 buckskins, 54 cut
batches and **216 glove pairs**. All 216 pairs and six buckskins sell. Some materials
are lost or remain unfinished; no hypothetical glove value is booked as income.
No journey crafts concurrently with a paid crew under this priority policy, although
the direct integration fixture confirms that an unselected artisan can do so.

Those 293 crafting days already overlap stopped days needed by the survival
strategy; they are not 293 extra calendar days. The changed hide collection adds
80 actual preparation days and 568 preparation food units relative to crews, while
sale visits add 18 days. Calendar costs, lost meat hauling and later weather can
outweigh the sale proceeds. There is no simple net-profit figure: ordinary camp
food and livestock output would otherwise also occur, and routes diverge.

For the 16 hired-artist journeys, median actual companion wages paid are **$111.65**
in both income arms; median local work receipts from the **whole party** are only
$8.45 (crews) / $9.00 (craft). Median total gross income is $19.805 / $20.385.
All these medians are separate summaries, not a per-case subtraction. Normal wage
arrears, missed payments, departures and deaths still occur. The full route offers
only 25 authored paid worker-days across all posts, shared by the party. A local
job covering one daily wage does not fund a continuous season-long contract.

## Assessment

Employment has a measurable benefit for this hired-artisan setup, especially with
goats, but does not make it an easy or reliably successful start. Free parties remain
winnable without relying on the new income sources. The aggregate cash gain from
crafting is concentrated; even median earnings do not improve in every stratum.

The next useful balance investigation is the **decision to recover more hides and
spend time preparing/selling them**, plus earning earlier at finite posts. A narrower
comparison should hold hide collection fixed to isolate the incremental benefit of
using an artisan on an already needed camp day. This pass does not justify raising
historical wages, removing crafting labor, or treating gross sales as free money.

Existing [wage estimates](TRAIL_INCOME.md) and [crafting estimates](LEATHERCRAFT.md)
remain unchanged. This campaign tests implementation and consequences; it does not
establish new historical tariffs, garment yields or hand-processing times.

## Reproduction and verification

- `tests/run_crew_craft.ps1`: all twelve cells, isolated save data, refuses existing
  reports, archives every raw JSON and records source commit/SHA-256.
- `tests/summarize_crew_craft.py`: exact matrix, source/rule signatures, starting
  parity, unique meal-days, real employee receipts/quotas, wage floors and weekly
  billing, recipe stages, available materials, paid/crafting conflicts and sales.
  Seven deliberately corrupt accounting cases are rejected.
- [Machine-readable evidence](crew-craft-results-01.json) contains every case,
  stratified summaries, all matched comparisons, raw archive hashes and source map.
  Large raw reports and logs remain in ignored `.tools/crew-craft-archives/`.
- Generate after a fresh campaign with the bundled Python runtime and `-B
  tests/summarize_crew_craft.py`; use `--check` to verify the published artifact
  without overwriting it. Older published studies remain untouched.

**Validation:** all 97 Godot suites pass; the new integrated fixture has 21 checks,
including legal customization, identical starts, actual multi-worker pay/food,
parallel craft, blocked double work, all five physical stages, real shop proceeds,
automatic weekly pay and save restoration. All 96 journeys have zero simulation
or save/invariant errors, and all 32 triplets pass the independent evidence audit.
Full suite log: `.tools/crew-craft-full-tests-01.log`, SHA-256 `b1e9586e07e9ad0798864802f1ecce2122e5868eafaacfff1c4bf6312f2495d0`.
