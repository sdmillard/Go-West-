# Coordinated companion work study

This is a test policy using existing public camp assignments and outing actions. It does not add automatic job assignment to the player's game, alter prices, grant food/medicine, change carrying or modify recovery rates.

## Matched policies

- Off: the preceding hunting policy, with its ordinary helper selections but no deliberate nursing/foraging/drying assignments.
- Support: assign actual companions to support jobs while retaining the preceding leader-action priorities. Actual job reservations can reduce hunting helpers and hauling; this is part of the tradeoff.
- Coordinated: the same support roster, plus brief camp days for a leader needing nursing or a worthwhile morning meat batch, and a real one-day companion hunt when the leader cannot haul in a food emergency. These changes form a player-strategy bundle rather than an estimate of jobs in isolation.

All main comparisons use steady pace, the unchanged standard six-ox/1,700-food outfit, practical equipment costs, actual seeded characters, May/July departures, three professions and legacy/foot/led/outrider strategies. Six matched development seeds and six separate held-out seeds are reused across policies. Prices, funds, health, hauling, yields and weather remain fixed. The previous studies used older game/policy checkpoints and are not pooled.

## Roster choices

The policy clears active companion roles through public assignment actions. It reserves at most one nurse/patient, prioritizing serious illness or very poor health and an available caregiver. A patient rests and cannot hunt/work. Care kits must exist. A nurse cannot also hunt or forage.

When produce is scarce, up to two eligible foragers are assigned. One healthy person gathering on the plains can bring less than the party's vitamin-meal target, so the initial single-forager pilot is not treated as adequate preventive nutrition. Seasonal conditions and actual health still constrain harvest; partial pounds and actual meals matter.

A willing worker dries a real morning surplus using the existing after-meal/spoilage offer, preferring available salt. The same day's new hunt cannot also finish drying. Remaining eligible people help a leader hunt, up to three helpers alongside the leader. Solo mounted trips leave those unused helpers resting; helpers do not secretly join the selected outfit.

Coordinated nursing rest is bounded to one such leader-care day per three days. Processing takes a real camp day when it needs one. Emergency dispatch uses one actual companion, actual tack/ammunition and a one-day trip; the main party can wait briefly for the public expected return. Hidden offscreen health, death, delayed due dates and private food are not used to choose actions. Distant rescue is not automated.

These are declared heuristics, not optimal play. The support/coordinated comparison helps distinguish job use from deliberate changes in leader actions.

## Observation and invariants

Test-only subclasses wrap actual nursing, preservation, foraging and daily accounting. Public-action replay checks compare serialized observed/unmodified games and random streams. Audits count executed nursing visits and kits, processed/retained food units and salt, forager person-days, and actual harvest reaching inventory. Shared harvest includes the leader on explicit forage days; it is not attributed solely to companions. Assigned but blocked work is not credited as a successful treatment or batch.

The study records arrival, original survivors, reunion, actual hunger, spoilage, camp activities, materials, harvest, costs and travel. Fewer days among a different set of survivors do not prove faster matched journeys. Deaths and a test-only one-year cap remain outcomes; software/state/save failures remain errors. Reports archive immutable source/rule fingerprints and refuse overwrite.

## Corrections required before measurement

Camp work used fixed party slot zero as the leader. After that traveler died, a survivor acting as the hunter could be marked as resting and the leader's forage option could report no worker. Camp roles now follow the first active traveler, consistently with the interactive hunt. That person is not duplicated as a companion, helper or separate field hunter. Nursing ends for the actual acting leader upon another activity. Existing saves derive the role from the roster, without a new stored schema.

Explicitly selected weak but willing hunt helpers could also retain a fallback Rest entry from the camp roster. Actual participants now work that day. The existing partial hauling curve remains; no new health cutoff is imposed.

All comparison policies use the corrected game so fake rest recovery cannot be credited to coordination. No historical/economic/health tuning was introduced to make a policy win.
