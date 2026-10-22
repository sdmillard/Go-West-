# Background benefits and companion news

Fixed backgrounds now have modest practical effects. The later [companion consequences](COMPANION_CONSEQUENCES.md) add refusal and settlement departure to this foundation. There are no skill levels, skill progression, additional needs simulation, departures or crime encounters in this increment. All numbers are authored tuning in `data/party_benefits.json`, not historical measurements.

| Background/special | Benefit |
| --- | --- |
| Hunting | Rifle reload time is 20% shorter. Ammunition, shot limit, meat yields and the 100 lb retrieval cap are unchanged. |
| Carpentry | Patch/wooden wagon repairs take one fewer day, with a minimum of one day. Spare parts still get consumed normally. |
| Caregiving | Newly quoted care restores 2 extra health and advances the patient's condition recovery one extra day. Kits/cash, the day and meals are still required. |
| Trading | Cash purchase quotes are discounted 5%, rounded to cents after regional/post prices. Selling prices and barter are unchanged. |
| Veteran | Confrontation injury chance is reduced by three percentage points, subject to normal injury-risk floors. It never makes combat safe. |

Only a living companion with at least 40 health and no severity-three condition supplies a benefit. The player/leader has no automatic background bonus. Duplicate backgrounds and multiple veterans do not stack. Benefits do not depend on trust yet; refusals and departures remain deferred. Setup tooltips and View Party explain the benefits and their health requirements. Existing wage premiums remain provisional; this does not establish that every paid specialist is economically worthwhile.

## Quotes, timing and saves

Repair time, care bonuses, purchase prices and confrontation odds are quoted before committing. Pending quotes survive saving/loading, even if they were made under the previous rules. Hunting uses the available hunter when firing; journeys cannot be saved during a hunt. Care bonuses are explicit validated fields in new offers, so a prior saved offer is not silently improved on selection.

Party-benefit JSON participates in the rules fingerprint. The actual preceding fingerprint is recognized for migration, and a genuine pre-change fixture verifies preservation of party, date, supplies, RNG and pending offers. No past action is replayed. Future offers and actions use current rules.

## Objections, gratitude and warnings

Existing trust reactions now produce named party news on the first reaction of a type still represented in recent memories. A negative reaction explicitly states an objection; positive reactions explain appreciation. Newly entering the approaching-breaking-point, breaking-point or critical-betrayal-warning band also produces news. Repeating a reaction within the same band does not itself make another threshold warning. After old memories roll off the twelve-entry list, that reaction can be introduced again.

News uses the existing saved party-notice queue and acknowledgement flow. It pauses ordinary automatic travel and can interrupt a multi-day rest. At a stopped landmark, queued party news appears with the stop's text without replacing its choices. Before a hostile defense choice or grueling travel with a sick/injured party, the travel panel also previews which companions have concerns without changing trust or rolling randomness. View Party retains each companion's boundaries, current warning and concrete memories.

Breaking points remain information rather than an automatic departure. No betrayal is executed. A former matched test asserting no survival change from characters would no longer describe this version: background effects intentionally change prices, recovery and hunt timing, and news changes when travel pauses. The paired policy regression now checks determinism under the same choices and seed.

## Validation and initial journeys

The dedicated suite has 29 checks covering availability, poor health/serious illness/death, actual hunt/repair/care/trade actions, unchanged costs and caps where applicable, duplicate Veteran limits, combat floors, persisted warnings, pure concern queries, care-quote validation and real previous-save migration. Native party-warning and benefit-detail screens were inspected.

`background-benefits-oxen.json` records 360 journeys across seeds 0–19, March/May/August departures, three professions and two existing policies: hunting/preservation and spare-ox emergency food. Both policies use normal seeded weather, food aging, care, trader stock and the complete route. All parties start with the existing one-of-each background roster, neutral relationships and no mercenary contracts or Veteran special.

| Profession | Hunting/preservation arrivals | Spare-ox arrivals |
| --- | ---: | ---: |
| Farmer | 52/60 | 52/60 |
| Carpenter | 60/60 | 60/60 |
| Banker | 60/60 | 60/60 |

Total: 344/360 arrivals, zero invariant/setup errors. These policies mostly avoid armed defense and do not deliberately enter forced walking. Veteran combat behavior is covered by focused tests, not by this cohort. This is an initial whole-route regression under the new rules, not a specialist value study or aggressive-combat certification. Older benchmark artifacts retain their earlier rules signatures.

