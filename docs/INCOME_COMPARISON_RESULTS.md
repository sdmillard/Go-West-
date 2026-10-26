# Combined trail income: results

October 26, 2026. **The new income choices produce real spending money and reduce the aggregate food deficit in this sample, but they do not raise its arrival count or demonstrate September completion.** No production rule, price, wage, food yield or starting-money change was made during this study.

## Main fresh comparison

[Follow-up protocol](INCOME_FOLLOWUP_PROTOCOL.md), [manifest](income-comparison-manifest-02.json), [verified results and every paired case](income-comparison-summary-02.json). These32 journeys are16 matched pairs across four shared seeds568000-568003, April/May starts and no-stock/two-goat outfits. They are not32 independent random worlds. Both arms bring the same five keepsakes and use the existing informed65% hunting strategy, standard shared-horse cart and identical67500-cent opening cash-plus-outfit assets. Personal possessions are equal in both arms and are not an extra cash grant to the treatment.

| Measure across16 journeys per arm | Income unused | Income used |
|---|---:|---:|
| Arrived | 10 | 10 |
| Arrived with at least4 originals present | 7 | 8 |
| Arrived with all5 originals present | 0 | 0 |
| Arrived before October1 | 0 | 0 |
| Any recorded main-camp meal shortage | 8 | 9 |
| Unmet meal requirement, food units | 694.000 | 302.968 |
| Unmet fraction of required meals | 1.7124% | 0.7303% |
| Recorded lack-of-food deaths | 9 | 6 |
| Recorded scurvy deaths | 4 | 4 |
| Median first-shortage day, affected cases | 212 | 215 |
| Median cash at first shortage, affected cases | $4.64 | $2.32 |

These are outcomes of the complete decision bundle, with different subsequent lifetimes and encounters. Lower aggregate unmet food does not mean every party improved: one additional case experienced some shortage. Changed actions also change the calendar and random encounters. Four/five originals present is a reunion measure, not proof that every absent original died; outriders may still be away.

One pair gained an arrival and one lost an arrival. Nine pairs arrived in both arms: two were earlier with income, four later and three unchanged. Paired arrival differences ranged from61 days earlier to40 later, with median zero. Earliest arrival in either arm was October5. Do not read the longer-lived pooled treatment sample or the count of money-making days as a causal delay estimate for every traveler.

| Four-case cell | Unused / used arrivals |
|---|---:|
| April, no stock | 2 / 2 |
| May, no stock | 3 / 3 |
| April, two goats | 2 / 3 |
| May, two goats | 3 / 2 |

## What the money actually cost

Thirteen income-enabled parties earned something. Median gross receipts across all16 were **$10.23**, range$0-$16.85. The three that earned nothing already arrived in both arms; their identical outcomes are retained. Gross receipts are not net profit or a blanket survival bonus.

| Source across16 income-enabled journeys | Realized cash | Usage and costs |
|---|---:|---|
| Personal keepsakes | $78.00 | 52 unique items sold in13 journeys; permanently forfeited retention/possession |
| Pelts | $66.48 | 117 deer hides and32 rabbit pelts sold in12 journeys |
| Settlement wages | $1.00 | One paid day in one journey |
| Total | $145.48 | Not all attributable to one mechanism independently |

Actual skin preparation occupied **95 camp days** and consumed **605 food units**. It mechanically displaced **404.5 lb of meat** from those hunts' hauling allowance. The parties prepared118 deer hides and32 rabbit pelts; one deer hide was not realized as a sale. All recorded skin sales used the lower road offers. No bison hides were selected by this strategy. This does not prove that no player can make bison hides worthwhile.

Trading visits involving income occupied68 days and consumed425 food units. Some visits also make subsequent same-visit purchasing possible; these are actual associated days, not68 measured additional days versus the control. One work day at The Dalles consumed3 food units and paid$1 to a remaining traveler on day223 of seed568003's April/no-stock journey. **With only one paid work day, this study cannot establish the balance of settlement employment generally.**

Time, food, hauling and travel to a willing buyer matter alongside price. The extra income is mostly spent rather than retained: median terminal cash was$2.11 without it and$2.16 with it. It helps close some food gaps, but it neither manufactures produce nor removes disease and winter pressure. Small-looking cash differences should not be dismissed when a party is near a food purchase, but the ledger does not show a general increase in completion.

## Why there are two comparisons

The [original protocol](INCOME_COMPARISON_PROTOCOL.md) and [first results](income-comparison-summary-01.json) remain intact:32 journeys on seeds567000-567003, seven arrivals in each arm, with six versus seven arrivals having four originals present. Fourteen treatment parties earned$84 total, entirely from keepsakes. The strategy never prepared a skin or took a job, so that run did not adequately exercise the planned income bundle.

The study required four pre-existing meals before preparing a hide while normally initiating hunts with fewer than two. It ignored food from the animal already killed. It also imposed an October work cutoff beyond the game's own availability rules. These were overly cautious study decisions, not discovered production price or wage bugs.

The follow-up was declared before using new seeds, included known recoverable meat in that meal estimate, and removed the study's date cutoffs. Other buying, worker selection, margin, price and reserve rules stayed fixed. Its controlled fixtures demonstrate both empty-stock/real-harvest preparation and real offered employment after September. No extra hunts or free autonomous labor were added. The first run is development evidence; the second is its fresh confirmation. They are not pooled into a64-journey win rate, and7/16 versus10/16 across the different seeds is not a measured policy improvement.

## What to address next

Keep the period-based prices and production rules for now. **The next useful audit is the calendar and availability of income work**, especially whether preparation can share already-needed camp time through an explicit companion task, and why this strategy reaches useful paid work so rarely. Those are proposals for inspection, not changes made here. A single employment day does not justify raising wages. The fixed extra preparation day and repeated visits deserve scrutiny before a broad economic buff.

The game remains winnable for informed farmers in this bounded sample, with meaningful food/cash pressure. Dependable September arrivals, full original-party reunions and human playtest clarity remain open. Better party creation, aiming, batching, routing and use of mixed baskets were not exhaustively searched.

## Verification and reproducibility

Gameplay is unchanged from `b54cbb04cf14f92409993f5105e3dc708b0c1081`. The first policy was frozen in `acad41a`; follow-up in `9b64093`. All eight reports contain their complete declared cases and zero engine/policy/save/invariant errors. Raw source/rule fingerprints, exact opening assets, paired carts, daily action totals, meal accounting, classified spoilage, work receipts and sale-day traces are checked by `tests/summarize_income_comparison.py --version 1` or `--version 2`. The verifier checks all original/copy archive hashes and rejects changed recorded sources.

The runner `tests/run_income_comparison.ps1 -Version 1` or `-Version 2` refuses to overwrite reports. Local ignored raw files use `.tools/hunting-income-confirmation-*-01.json` / `.tools/hunting-income-followup-*-01.json`, with copies in `.tools/income-comparison-archives/` and per-report receipts/logs. A clean checkout must generate its own raw reports before running the verifier. The separate single-seed pilot is excluded from results.

All **94 Godot suites pass**, including23 first-comparison checks and11 follow-up checks, on frozen runtime/test sources `9b64093` (later edits are Python verification and documentation only). Final log `.tools/income-comparison-full-tests-02.log`, SHA-256 `0db5803049e109f200a8d4e58345adace9a04320a4edbe16779276318b95c952`. The earlier93-suite log also passes. Version2's raw diagnostic `no_positive_estimated_margin` includes carts rejected by its food-safety test; it means no accepted safe positive-margin cart, and must not be treated as a pure price-rejection count.
