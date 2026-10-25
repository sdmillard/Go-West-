# Parallel work and moving-wagon follow-up

Runtime is unchanged. Frozen test checkpoint **4351bd4** completed **144 journeys**, split into 72 development and 72 fresh validation, with zero source/state/save/policy errors. All **71 Godot suites** passed, including 235 focused motion/camp checks. No game prices, starting funds, health, carrying, recovery or hunting probabilities were tuned.

## Question and setup

Spencer expects necessary camp jobs to happen together and outriders to hunt while the wagon moves. The previous coordinated script could take a separate preservation day despite assigning a dryer. This follow-up changes test decisions to exercise those advantages, using serial / parallel / mobile strategies described in [the protocol](MOBILE_CAMP_PROTOCOL.md). All pay for identical supplies and one horse/saddle/bags; the inherited method field stays foot, while motion_policy identifies the actual strategy. This is a strategy bundle, not a clean isolation of each feature.

The mobile strategy dispatches a fit willing hunter for one real mounted day before a food emergency, returning ridden with actual reduced cargo. While a hunter is out, it continues with a meal in stock and avoids ordinary food stockpiling stops if two meals remain. Urgent purchases, real care, nutrition, weather, crossings and shortages still take time. Camp chores run only during actual camp actions, never for free during travel. Lost horses are not automatically replaced; remote rescue and adaptive equipment investment remain absent.

Four reused seeds per phase, three professions, May/July and three strategies make 72 journeys per phase. Development 145000-145003; validation 155000-155003. These are not 144 independent worlds. The earlier pilot and camp studies are separate.

## Arrivals and time

Each strategy/profession has eight runs per phase.

| Phase | Profession | Serial arrivals | Parallel arrivals | Mobile arrivals |
|---|---|---:|---:|---:|
| development | farmer | 0/8 | 0/8 | 1/8 |
| development | carpenter | 7/8 | 6/8 | 6/8 |
| development | banker | 8/8 | 8/8 | 8/8 |
| validation | farmer | 0/8 | 0/8 | 0/8 |
| validation | carpenter | 5/8 | 5/8 | 6/8 |
| validation | banker | 8/8 | 7/8 | 7/8 |

No serial farmer arrived in either phase, so there are **no matched arriving farmer pairs** from which to estimate completed-route time savings. Mobile had one development arrival and none held-out. Earlier deaths cannot be presented as shorter journeys. The experiment does not establish farmer viability or a guaranteed gain from either strategy.

For matched held-out arrivals, negative differences mean fewer days than serial. These tiny paired samples are reported directly. Stationary includes trade/crossing/event delays as well as camp.

| Profession / strategy | Both arrived | Median total-day difference | Median stationary-day difference |
|---|---:|---:|---:|
| carpenter / parallel | 4 | 5.0 | 8.0 |
| carpenter / mobile | 4 | 5.0 | 8.0 |
| banker / parallel | 7 | -10 | -5 |
| banker / mobile | 7 | -10 | -5 |

The same mechanics save days in some matched journeys and add days in others. Branch/encounter/health histories diverge once decisions differ, so these paired totals cannot attribute every saved day to a single chore. Inspect individual pairs and survival, rather than selecting the quickest survivors.

## Did work actually overlap?

Held-out mobile groups below have eight journeys each. Moving-hunt days require an actual shot on a travel day. Returned catch means food units actually rejoining inventory, not every pound killed. Delivered on travel can include an attempted travel day without distance progress; separate progress counters are retained.

| Profession | Dispatches | Moving-hunt days | Catch food returned on travel actions | All catch food returned | Shared multi-job camp days |
|---|---:|---:|---:|---:|---:|
| farmer | 38 | 23 | 128 | 155 | 251 |
| carpenter | 32 | 17 | 127 | 317 | 294 |
| banker | 29 | 26 | 233 | 275 | 189 |

Focused checks additionally demonstrate a wagon gaining miles while its hunter is out, no automatic wait day at departure, and a single necessary health rest executing nursing, drying and foraging together. Serialized observer and uninstrumented games match exactly over public decisions and RNG streams. Actual executed work, not assignment count, defines a shared-work day.

## What to investigate next

The intended overlap exists. However, held-out farmer mobile trips returned only **155 food units across 38 dispatches** (128 on travel actions). They generated 204 catch food units; not all generated catch reaches the wagon; private meals, spoilage and delayed/missing returns can reduce delivery. There was one observed mount loss and no observed field deaths in this subset. None of these means hunts are free: food/ammo/tack/horse condition and missing/delayed hunters still matter.

A concrete authored asymmetry merits review: simulation/field_outings.gd currently makes **one hunting attempt and spends one bullet per hunting day**, even when an empty encounter or reserved return search yields no catch. The leader minigame can allow several shots (configured shot_limit 5). This is not a historical measurement, nor proof that simply multiplying companion attempts would balance the game. Audit encounter opportunities, actual search time, ammo, return cargo and private meals before deciding whether that abstraction is too restrictive.

Food/illness/season cascades, lost helpers and task priorities also remain. The script still makes fixed one-day ridden trips and does not adapt duration, return mode or replacement animals. The farmer results therefore do not disprove the benefit of well-managed outriders. No rule was changed merely to make the scripts win.

## Evidence

Full archives: parent .tools/hunting-mobile-{development,validation}-{serial,parallel,mobile}-01.json. All six were copied and SHA-256 checked against the isolated checkpoint. [Compact summary](mobile-camp-summary-01.json) records digests, frozen source hashes, actual motion/job totals, outcomes and every paired time difference. tests/summarize_mobile_camp.py rejects errors, incomplete/unmatched/duplicate cohorts, source/rule/settings mismatches, or differing starting carts/costs.

The full test log is .tools/mobile-final-tests.log. Each phase/strategy has its own mobile-*.log. Run ./test.ps1; reproduce campaigns using the protocol flags with a fresh label and the declared seed start. The runtime simulation/data were not modified, so the preceding 44 integration journeys remain prior-checkpoint evidence rather than newly claimed runs. Player saves and the existing debug pilots were preserved.
