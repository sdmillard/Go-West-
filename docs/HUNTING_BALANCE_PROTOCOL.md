# Hunting balance study protocol

This pass measures the actual game through public player actions. It does not impose equal outcomes or change historical prices, starting money, weather, disease, animal carrying or noise to obtain a desired win rate.

## Cohorts

Match seeds, profession, departure month, roster, route policy and aiming stream across seven strategies: legacy group hunting; explicitly outfitted group foot hunts; solo riding returns; solo strenuous riding returns; solo led returns; whole-party wagon hunts; and a companion riding out for two days and leading home while the party continues. Ordinary seeded companions retain their real backgrounds, trust and boundaries.

Two equipment cohorts separate method from purchasing decisions:
- Shared equipment: every strategy buys one horse, saddle and bags ($58). Other purchases match.
- Practical equipment: only mounted/companion strategies buy that outfit. Foot/wagon/legacy strategies keep that cash.
All begin with the actual suggested six-ox wagon outfit and 20 dried-produce items. No free animals, food, money or health are injected into campaign journeys.

The main policy seeks two current party meals before hunting, pushes past a brief health stop (one consecutive ordinary health rest; up to three when a person is very poorly), buys food/produce/ammunition through current counters, preserves surplus meat with salt, forages for vitamin C and preserves four working oxen. A six-meal stockpiling sensitivity distinguishes long waits from intrinsic survival difficulty. Outriders dispatch at four meals or the selected larger reserve: they must provision a two-day trip while the remaining party travels. A hunter still away is not dispatched again; emergency food shortages can prompt a real foot hunt.

Inaccessible wagon grounds, unavailable mounts/tack or a rejected expedition fall back to a legal foot hunt; failures and fallback counts are reported. The policy never reads private offscreen health/fates to choose actions. It accepts warnings to continue past away hunters, exposing real forks, separate crossings, bandits, delays and loss. It does not teleport hunters back, recover distant camps automatically, recruit replacements or commit elective crimes. Necessary encounters still use the current common policy. Standing helpers are selected through camp assignments.

## Measurement and validation

Test-only observers wrap actual meals, spoilage and field hunting/return calls. A regression suite compares serialized observed/unmodified games and RNG under the same actions. Main meals/spoilage are measured separately from private field catches; field catch generated is not claimed as total carcass yield or total private food eaten. Field returns are counted only when reunited. Remaining away companions are reported separately; an arrival is not automatically an intact reunited party.

Reports archive rules/source fingerprints, starting cost/cash, method/fallback use, actual retained/eaten catches, shots, hunger days, main spoilage, rest/preservation/travel activity, field condition losses and fates, journey duration, arrival, survivors and monthly progress. Arrival duration is summarized for arrivals separately so early deaths do not masquerade as fast journeys. Full reports stay in ignored .tools; a compact report and reproducible runner are committed.

Development and held-out seed ranges are separate. A small pilot diagnoses harness or deterministic mechanic faults before larger cohorts; it is not independent balance validation. Final source hashes must remain unchanged during a run. All suites and the 24 store/20 current-policy outlaw integrations remain required after a simulation fix.

## Fault exposed by the pilot

The original same-day outfit rejected hunters with insufficient food for meals plus a reserve day. In one actual farmer case, day 32 had seven food units, four travelers and forty bullets; the explicit foot hunt was forbidden. The new rule allows a same-day party to take only actual available food/clothing, with a visible short-supplies warning. Ammunition is still required. Longer expeditions still need full supplies/reserve. Failure still consumes a hungry day; success feeds the actual same-day meal before the remainder is packed. The pilot also exposed a stockpiling-policy trap: small catches cannot necessarily build a six-day reserve before spoiling.

## Limits

Finite seeded scripts do not establish historical accuracy or human aiming difficulty. The same seeds are reused across paired cohorts, so larger row counts are not that many independent worlds. Different decisions necessarily change later random draws and routes. A method with more food is not automatically preferable if it consumes cash, time, party work or animals.

Leader returns currently resolve within one shared hunting day. Leading home slows field pursuit and general travel, but does not extend a leader day hunt. This may give leading a structural advantage in that particular context; record it rather than silently claiming a time penalty the engine does not charge. A future sub-day/radius model would be a separate design decision.
