# Refusal, departure and paid/free tradeoffs

Historical record: prices, wages and cohort results below precede the [historical economy update](HISTORICAL_ECONOMY.md). That later audit records current figures and comparisons.

Companions now have consequences for low trust and repeated broken wage agreements. There is still no recruitment during the journey, betrayal execution, crime encounter or new skill progression. The first traveler remains the player/leader and never leaves through these rules.

## Participation and notice

A companion refuses optional background assistance or armed-defense participation at or below their relationship-adjusted breaking point. Forbidden actions also prevent participation unless trust reaches the existing reluctant-acceptance threshold. The player can still hunt, repair, buy supplies, provide care or defend with baseline rules; refusing companions withhold their contributions. Refusers do not count as willing defenders in the small-party combat penalty. They can still be endangered by an attack on the wagon.

Breaking points remain 20 for fellow travelers, 15 for friends and 10 for family. A living companion warns of intent to leave when trust reaches that point, or when a mercenary has at least three missed installments with a balance still owed. The notice is journaled, shown in party news and saved. There is at least one day of notice. Ordinary disagreement is still halved by Loyal; forbidden actions take full penalties.

The cause is rechecked before a departure is committed. Improving trust above the breaking point or clearing the relevant wage debt can remove the immediate cause. Paying debt cannot erase a separate trust crisis. Prior missed-payment history remains recorded. A companion with high personal trust can still leave because a contract has repeatedly gone unpaid.

## Settlements and belongings

Departures occur at town/fort stops, not river crossings or isolated camps. Early-1848 Fort Kearny is excluded before June because the existing route already treats it as not yet built. On choosing Continue at an eligible stop, a service review lists the companions and exact transfers. Returning to the stop does not remove anyone, and trying Continue again does not bypass the review. Acknowledgement rechecks the current cause and leaves the remaining party at the same stop without consuming a day.

Each departing person takes up to three days of current rations, one available clothing set and the existing 15 lb personal-gear allowance. Scarce food is split evenly among simultaneous departures, with deterministic remainder handling; clothing is allocated in roster order. Only actual available stock is transferred, with the fresh/preserved food ledger updated. Wagon, oxen, ammunition, care kits and communal cash remain. Shared stock is an abstraction; more detailed ownership is deferred.

Departed travelers stay alive in their records. They stop consuming meals, receiving health changes, being selected for encounters, supplying benefits and accruing wages. The active party count, health average, displayed roster and walking capacity update. Their personal gear is removed from wagon cargo; on foot it follows the existing per-person gear calculation. Reduced pack capacity can leave the remaining walkers overloaded; the game asks them to discard or repack rather than silently deleting more possessions. Cached wagon contents are preserved.

Unpaid wages remain recorded. A departed mercenary can receive final payment while still at the same settlement, but paying does not silently rehire them. Payments are not available remotely after continuing. Journey summaries list deaths and departures separately. Family relationships currently connect companions to the leader, not a full network that automatically makes relatives leave together.

## Two ways to maintain a relationship

Free companions avoid a recurring cash obligation; their trust comes from relationships and decisions that fit their values. Paid companions have the additional predictable route of honoring the wage agreement. Payment does not remove their personal boundaries or guarantee obedience.

On-time wage settlement contributes the agreed interval's paid days. Every seven on-time paid days earns +2 trust, regardless of daily versus weekly billing. Daily payment therefore does not produce seven times the trust for the same work. Clearing late debt can earn +1 trust at most once in seven days. Partial payments reduce real debt but grant no settlement reward until the balance is cleared; overpayment and advance gifts remain unavailable. The party screen shows progress toward the next weekly reward. Existing trust and debt are preserved on load; older contracts start with zero unrecorded reward credit.

The store shows average weekly wages and the first due day beside the purchase decision. These are commitments against remaining trail funds, not an upfront hiring charge. Wage rates remain provisional. Paid and free parties are not ranked solely by arrival rate: reliable contract-based trust, cash pressure, retention, relationships and boundaries are different tradeoffs.

## Compatibility and checks

Character schema 3 saves exit notices and validates departed-member records, active counts, belongings, gear removal and wage reward progress. A real pre-update fixture verifies migration from schema 2 without invented warnings, altered people, supplies or RNG. Existing pending service quotes remain intact. Departure review and departed records round-trip, and unsupported/downgraded or malformed fields are rejected.

The dedicated departure suite has 43 passing checks: refusal/reluctance, defense participation, notice, safe locations, review/cancellation, payment resolving a pending review, living departures, exact inventory/cargo, health/meal exclusion, simultaneous scarce-food transfers, reduced walking capacity, preserved cache contents, migration, malformed data, daily/weekly reward equivalence, and actual UI paths. The wider regression suite passes. Native captures: `departure-review.png` and `departed-companion.png`.

## Matched journey study

`specialist-balance.json` records 360 journeys: four rosters, three professions, March/May/August departures and seeds 0–9. Every roster has the same four backgrounds. Paid rosters add Mercenary contracts at their quoted weekly minimum; Loyal/Veteran variants add those specials to all four companions. Free variants can choose the same specials through customization.

The existing salted-hunting/spare-ox policy uses 65% center aim, ordinary seeded weather/disease, finite traders, care and the full route. It pays active companions' full debt in member order when cash covers it plus a $10 reserve. It acknowledges real departure reviews and considers only active travelers when assessing health/rest. Runs stop at 365 days or 2,400 actions. No recruiting, forced-walking policy or deliberate immoral choices are included. Every final state passed real save validation; zero invariant/setup/save errors occurred.

| Roster | Arrivals / 90 | Total companions who left | Mean final companion trust | Mean wages paid per journey |
| --- | ---: | ---: | ---: | ---: |
| Free mixed backgrounds | 87 | 0 | 61.3 | $0 |
| Paid matching backgrounds | 77 | 144 | 53.9 | $482.78 |
| Free Loyal/Veteran | 87 | 0 | 61.4 | $0 |
| Paid Loyal/Veteran | 75 | 246 | 60.7 | $546.59 |

For the funded banker comparison, ordinary paid parties arrived in 30/30 runs, retained all 120 companions and averaged 80.1 trust, versus 61.2 for the matching free parties, also 30/30. That illustrates the contract mechanism when affordable. The paid farmer cohorts lost all companions; a sole remaining traveler can need much less food, so an arrival can conceal severe attrition. Deaths and departures are stored separately in the report.

These are scripted strategy results, not player difficulty estimates or proof that one roster is better. The paid cohorts hire all four companions; one/two hires or carefully chosen mixed rosters may have very different budgets. The cautious policy gives free companions few reasons to object and does not test the future value of high trust for morally difficult choices. Current customization also allows free versions of the same backgrounds/specials. Further balancing should assess contract reliability, moral/relationship management and retention together, rather than lowering wages merely to equalize win rates. Crime and betrayal remain deferred.


