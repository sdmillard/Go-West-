# Fishing audit protocol

Frozen-game audit of the shipped generic fishing rules before species profiles or livestock are added. No price, starting funds, food amounts, catch odds, carrying or health changes. Food unit remains approximately 1,000 kcal. Distinguish edible fish weight from whole-fish weight; existing generated catch weights are already edible.

## Full journeys

Three policies, three professions, May/July departures, four world seeds per phase, shared horse/tack equipment, standard six-ox/1,700-food outfit, foot leader hunts, steady pace and the existing mobile-camp strategy: 144 journeys. Development seeds205000-205003; held-out215000-215003. Same carts and prices in every matched world. Hold configuration and scripts fixed across both phases.

- Off: unchanged existing mobile policy, no fishing. Observe access without consuming randomness or changing actions.
- Leader: retain existing choices, but replace a due hunt with reachable fishing once per named river per journey. Also allow that attempt at a river stop when below two daily meals. Walk where possible, otherwise take an actual fit available saddled horse. Every attempt takes its real day and meals; this bounded policy avoids endless low-yield fishing.
- Support: no extra fishing stops. During existing shared camp days, replace one available hunt helper with a nearby foot fisher while food is below six meals. Preserve nurse/patient, produce and drying priorities. Losing a hunt helper can reduce actual hauling.

Scripted reactions act on visible CAST/BITE state at65% successful bite reactions, using an independent seeded reaction stream. Never inspect future bite outcomes or create catches. A missed reaction expires naturally. Normal fishing equipment reservation, load limits, meals, preservation, weather, illness, private outings and crossings remain active. Existing strategies do not redesign starting outfits, replace horses adaptively or behave like optimal human players.

Observe leader casts, edible catch, actual retrieval, meal use, packed food and left-behind mass. Party food delta during a fishing day includes ordinary meals, spoilage and other workers; do not label it catch-only yield. Observe real companion returns, not assigned days. Daily access snapshots are sampled once before a public action, not an exhaustive map of every reachable-water moment.

Report arrival pairs, original survivors, underfed days, actual miles, ammunition used, cash, fishing food/time, hunting effort and stationary days. Only compare route-completion time where both paired runs arrive. A shorter failed journey is not faster completion.

## Controlled yield probes

1,800 actual one-day trips:100 reused seeds225000-225099, distances0/4/12 road miles, all three rations, leader health100/40, five present travelers, other companions assigned Rest. Use actual quotes, reactions, meals, carrying and saves; no forced bites/catches. Distance12 requires a real horse. This separates yield/range/carrying from a full journey's self-selected fishing occasions. These probes are not arrival evidence.

## Gates and evidence

Check instrumented/unmodified engine parity for leader and companion fishing, exact off-policy state/RNG parity, day/ammo/miles accounting and JSON saves. Run the full test.ps1 suite before handoff. Simulation/data remain unchanged, so earlier44 gameplay integrations are not claimed as new runs. Final reports must have declared row counts, zero state/save/policy/source errors, matching source/settings fingerprints and matched starting carts/costs. Preserve isolated originals by hash-verified copies before worktree cleanup. Keep pilots outside final cohorts.
