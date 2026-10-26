# Bounded current-rules survival results

October 26, 2026. **Informed farmers can win, including October arrivals with four travelers, but dependable September completion is not demonstrated.** Food shortages remain the largest recorded cause of death. This pass is complete; no gameplay or candidate tuning was made during it.

[Protocol](BOUNDED_SURVIVAL_PROTOCOL.md), [manifest](bounded-survival-manifest-01.json), [verified evidence and every case](bounded-survival-summary-01.json). Gameplay7b5a29d, protocolfa02eb6. All96 fresh journeys/eight reports passed, and all90 Godot suites passed. Four underlying seeds545000-545003 repeat across outfits, stock arms and departure months; these are not96 independent worlds.

## What succeeded

Both strategies use65% simulated hunting aim, farmer$675 total starting assets, the same initial carts, steady pace, shared horse, actual public actions and existing current rules. Informed planning uses the previously frozen planning65 decisions; it was not tuned to these cases.

| Outcome | Ordinary /48 | Informed /48 |
|---|---:|---:|
| Arrived | 1 | 8 |
| Arrived with at least3 originals present | 0 | 5 |
| Arrived with at least4 originals present | 0 | 5 |
| Arrived with all5 present | 0 | 0 |
| Arrived before October1 | 0 | 0 |
| Arrived before November1 | 0 | 2 |

The two October successes were standard April departures: no-stock seed545001 on October18 (200 days, four originals), and goats seed545003 on October21 (203 days, four). Standard April/May settings had6/16 informed arrivals, five with four originals. The ordinary strategy's sole arrival was standard/goats/April seed545000, January15,1849, with two originals.

Each cell below has four journeys. Entries are ordinary/informed arrivals:

| Outfit / stock | April | May | July |
|---|---:|---:|---:|
| Standard / none | 0/2 | 0/2 | 0/1 |
| Standard / two goats | 1/1 | 0/1 | 0/0 |
| Lean / none | 0/1 | 0/0 | 0/0 |
| Lean / two goats | 0/0 | 0/0 | 0/0 |

The lean arrival reached Oregon December30 with two originals. The one informed July arrival came March23,1849, with two. Those are survival outcomes, not endorsements of those starts. Six of eight informed arrivals share underlying seed545003: random-case sensitivity remains substantial.

The informed strategy lost the one case that ordinary play won, while winning eight different cases. There are **zero pairs where both strategies arrived**, so no matched arrival-time improvement can be estimated. Overall completion counts do not establish that every decision in the informed bundle is superior or that no human strategy can do better.

## Remaining constraints

| Measure across each48 journeys | Ordinary | Informed |
|---|---:|---:|
| Journeys with recorded main-camp meal shortage | 48 | 43 |
| Unmet main-camp meal requirement | 10.28% | 2.66% |
| Median shortage days | 34 | 13.5 |
| Median first-shortage day, affected journeys | 144 | 196 |
| Median cash at first shortage | $20.01 | $2.21 |
| Recorded lack-of-food deaths | 121 | 48 |
| Recorded scurvy deaths | 36 | 30 |
| Recorded dysentery deaths | 35 | 23 |
| Mean leader hunting days | 42.0 | 31.9 |
| Mean explicit rest days | 21.1 | 42.9 |
| Mean food retained by all drying | 66.1 | 234.9 units |
| Mean raw meat/fish spoilage | 102.4 | 82.5 units |

Better planning reduces shortages substantially and postpones them, but much of its remaining food trouble occurs with nearly exhausted cash. Cash association does not prove one isolated economic cause; party health, location, finite stock and ability to hunt also matter. Most first shortages are in sagebrush/forest regions. Scurvy still kills people despite the new treatment/prevention mechanics; improved code does not manufacture produce access or continuous treatment.

Time remains a separate constraint. Arriving informed parties spent138-161 days attempting travel, plus50-120 days on other actions. For example, the October18 journey used141 travel days,26 rest,5 forage,4 care,3 drying and21 other event/service days. It required **no leader hunting days**; companion work and resupply were therefore important, and simply shortening the leader hunting minigame cannot explain or fix all delay. The October21 journey used140 travel days and63 other days, including27 rest and6 hunts.

Repeated short recovery stops, food work, crossings/services and travel conditions all contribute. These are not evidence of the strategy resting for a month at once. The surviving journeys and pooled ordinary/informed averages have different lifetimes, so larger aggregate rest or stationary totals cannot be read as causal extra delay. Travel actions include attempts and are not a clean estimate of unimpeded daily walking speed. No broad movement, weather or disease change is justified from these totals alone.

## Decision after this pass

Keep the current rules and move on to **pelts and trade valuables**, starting with actual hunting pelts and existing trade counters. The measured cash pressure gives that feature a useful purpose. It should create a limited way to earn money from real work, with physical loads and plausible prices, rather than a blanket starting-cash grant. This recommendation is an inference from the short-cash observations, not proof that pelts will solve survival.

Carry the calendar constraint forward explicitly: September arrivals remain unproven by these candidates, and the game is not declared fully balanced. Do not begin another general tuning loop here. After the trading feature, assess its own income/time/cargo effects against this frozen baseline. Initial outfit optimization, traits, alternative routes, bolder health decisions and stronger minigame execution remain unsearched human choices.

## Verification

All96 declared journeys and all eight reports remain included. No failed cell or seed was discarded. Check raw engine logs as well as report errors, complete seed/month cells, identical frozen source/rule fingerprints, exact67500-cent opening assets, paired carts, meal totals, all-worker drying and classified spoilage, and origin/archive hashes. Action-day totals reconcile to elapsed days. All90 suites pass on the unchanged runtime, including34 vitamin-reserve checks.

Verifier `tests/summarize_bounded_survival.py`; runner `tests/run_bounded_survival.ps1 -Worker baseline` or `planning65`. Local raw `.tools/hunting-bounded-survival-*-01.json`, copied reports `.tools/bounded-survival-archives/`, receipts alongside originals, unit log `.tools/bounded-survival-tests.log`. The runner refuses overwrites. A clean clone must generate its own ignored raw reports before the verifier can run. Earlier studies are separate frozen snapshots, not pooled evidence for this pass.
