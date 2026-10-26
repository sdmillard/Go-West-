# Can skilled farmers survive?

October 26, 2026. **Yes, several tested farmers reach Oregon with most of their party, but dependable, timely farmer survival is not established.** Better planning helps at the same hunting accuracy; merely lowering rations does not solve the problem. This is evidence about four explicit automated strategies, not a ceiling on human skill.

## Fresh comparison

[Protocol and runtime amendment](FARMER_MASTERY_PROTOCOL.md), [verified compact results](farmer-mastery-summary-01.json), [reproducible cohort manifest](farmer-mastery-manifest-02.json). Source frozen at `293f5b5`, based on `2ba568f` plus the wagon/dairy roster repair. All candidates retain the same $675 starting assets, prices, yields, finite stock, illness, weather, carrying limits and ordinary action costs. No extra money, easier risks or favorable seed selection.

256 accepted journeys: 128 development and 128 fresh confirmation; four candidates, standard/lean outfits, no-stock/two-goat arms, May/July departures. Four underlying seeds repeat across the eight settings per candidate and phase. These are **not 256 independent worlds**, and the small cells do not estimate population win probabilities.

| Strategy | Development arrivals /32 | Confirmation arrivals /32 | Confirmation with 4+ originals | Confirmation before November |
|---|---:|---:|---:|---:|
| Earlier baseline, 65% aim | 1 | 1 | 0 | 0 |
| Ration-only, 65% | 1 | 0 | 0 | 0 |
| Better planning, 65% | 5 | 6 | 5 | 0 |
| Same planning, 85% | 4 | 5 | 5 | 0 |

No candidate brought all five originals to Oregon in either phase. Better aim alone cannot explain the planning gain: the 65% planning candidate also improves. The 85% sample does not outperform 65%, which does not establish that accuracy is harmful; different catches change subsequent decisions and outcomes. In confirmation, planning65 preserves the one baseline win and adds five; skilled85 adds four. Development did not show identical paired winners.

The planning bundle combines earlier outriders, hunting while they are away, valid whole-party wagon hunts, preventive Filling when well supplied, efficient counter baskets, route-aware food purchases, produce and preservation. This comparison cannot attribute the gain to one ingredient.

## Which starts worked?

Confirmation arrivals by setting, each cell four journeys (all May):

| Outfit / stock | Baseline65 | Ration-only65 | Planning65 | Planning85 |
|---|---:|---:|---:|---:|
| Standard / none | 1 | 0 | 4 | 3 |
| Standard / two goats | 0 | 0 | 1 | 1 |
| Lean / none | 0 | 0 | 1 | 1 |
| Lean / two goats | 0 | 0 | 0 | 0 |

Every July setting had zero arrivals. The standard/no-stock May result is encouraging, but its four confirmation cases reuse only four seeds. It does not certify a universal winning setup. Goats produce actual food, but buying them is not a guaranteed rescue for a tight farmer budget.

Planning65 confirmation arrivals took 196–287 days: November 13, November 20, November 22, November 23, January 3 and February 12. Five had four originals present; the latest had three. Planning85 had the same five four-person arrivals, omitting the February case. Winning this late remains a serious warning about the time budget. No promise of historically plausible arrival timing follows from these wins.

## Remaining bottlenecks

Confirmation aggregates, across all 32 journeys per strategy:

| Measure | Baseline65 | Ration-only65 | Planning65 | Planning85 |
|---|---:|---:|---:|---:|
| Unmet main-camp meal requirement | 10.18% | 5.31% | 2.92% | 2.89% |
| Median days with meal shortage | 34 | 21.5 | 13.5 | 15 |
| Recorded lack-of-food deaths | 62 | 63 | 31 | 34 |
| Recorded scurvy deaths | 30 | 40 | 28 | 29 |
| Mean leader hunting days | 39.0 | 31.1 | 34.5 | 36.3 |
| Mean explicit rest days | 21.8 | 51.2 | 44.9 | 47.6 |
| Mean stationary days, all causes | 89.2 | 116.4 | 123.8 | 129.7 |
| Mean successful drying batches, all workers | 1.59 | 3.69 | 10.97 | 11.41 |
| Mean food units retained by drying | 67.2 | 122.3 | 266.3 | 273.7 |
| Mean spoiled raw meat/fish units | 106.5 | 107.4 | 91.5 | 88.5 |

The classifier found no dried-meat or produce spoilage in these accepted cohorts; the measured main-camp waste is raw meat/fish. It reconciles exactly to actual spoilage. Drying retained more food, but residual raw waste remains. Successful batches are measured at actual processing; an attempt whose surplus disappears during that day's settlement does not count as success. Companion and leader work are both included.

Economizing postpones shortages but does not prevent health losses and can trigger more recovery stops. Planning reduces starvation substantially while scurvy remains nearly as common. It bought roughly 15 produce units per journey versus four in baseline, yet did not eliminate deficiency. That points toward auditing *when and to whom* vitamin-C food is served, availability along the road, and recurring illness/recovery costs; it does not prove a specific nutrition rule is wrong.

Time remains expensive. More successful parties can also live long enough to accumulate more days, so the aggregate stationary means are not a causal estimate of extra delay. Inspect individual histories and matched surviving pairs before changing day costs. Hunts, drying, shops, crossings and illness all contribute. Main-camp food totals exclude detached actors; their field records are separate. Recorded causes do not imply every death had one isolated cause.

The next bounded work should trace produce consumption/deficiency and recurring recovery stops in surviving and failed standard-May journeys, then examine initial provisioning and how the strategy spends hunting/preservation days. Do not buff livestock calories, starting money or weaken weather to compensate for an unexamined strategy. Initial outfits, traits and route choices have not been optimized; human players may find better decisions.

## Repair and verification

The first launch exposed a real runtime failure: wagon hunting replaced its work roster without a leader key, and a dairy herd's care assessment accessed it. The repair supplies the current leader and no patient marker, preserves every hunter's busy status, and gives no phantom dairy labor. A complete real wagon/dairy outing regression now checks settlement and cleanup.

**All first-launch suffix-01 reports are excluded**, successful or otherwise. Logs and partial reports remain locally for diagnosis. The entire matrix restarted under one repaired runtime with development 515000–515003 / confirmation 525000–525003, suffix 02. No candidate was retuned during the restart. Earlier strategy-development pilots 489990–489993 are also excluded.

All **87 Godot suites pass**, including 17 mastery checks and 1,183 horse/wagon checks. The verifier accepts all **256 journeys / 32 reports**, checks raw logs as well as reported errors, reconciles meals and spoilage, validates complete cohorts and matching starting carts, ties fingerprints to the frozen Git source, verifies the sole gameplay repair, and checks origin/archive hashes. All accepted reports have zero errors. Two separate baseline replays reproduced the previous study's recorded fields before the repair. The older 624-journey dairy report was regenerated only to add previously omitted companion drying metrics; its outcomes are unchanged.

Local raw reports: `.tools/hunting-farmer-mastery-*-02.json`, hash copies in `.tools/farmer-mastery-archives/`, receipts alongside them; unit log `.tools/farmer-mastery-tests.log`. Reproduce in a clean output directory with `tests/run_farmer_mastery.ps1 -Worker controls`, `planning65`, and `skilled85`; the launcher refuses to overwrite a cohort. Verify with `python -B tests/summarize_farmer_mastery.py` after the full test suite and reports. A clean clone needs new raw reports; ignored local archives are not published as repository assets.
