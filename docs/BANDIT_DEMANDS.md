# Variable bandit demands

Bandits now draw their terms once when the encounter starts. The demand can be cheap cash, a larger uneven sum, one to three types of goods, cash plus goods, or rarely the loaded wagon. Actual carried holdings cap every quantity. A rich banker can face a trivial small demand or a substantial cash/ox demand; this is not a fixed percentage charged at every robbery.

The authored small/medium/severe tiers have weights 4/3/1. Small cash requests are capped at $20; medium requests can range up to half the purse and severe requests up to its entirety. Goods amounts are random within 15%, 50% or 100% of each held item, rounded to at least one when an item is present. Goods are selected without repeats, weighted toward food and ammunition. Goods-only and mixed requests are possible. These ranges are gameplay choices, not recovered historical frequencies.

A 3% wagon-demand draw is possible only while traveling with a wagon. The offer explicitly states the loss of wagon, ox team and packed goods, plus any stated cash. Worn clothing, personal tools and remaining cash stay with the survivors. Surrender leaves the party on foot, without packed food or ammunition. Carried bodies are set down at the scene, and separately tracked food in the cargo is lost. The stolen wagon never becomes a recoverable cache. This is distinct from voluntarily abandoning a wagon.

All terms appear before the payment choice. Normal requirements prevent paying goods the party no longer has. Surrender deducts exactly the quoted amounts, records losses and spends no invented work day. Giving up produce does not count as eating it. Defense retains its actual ammunition, injury/death, experience and companion-concern rules. Flight retains its existing day/team-strain cost. This change varies demands rather than changing those combat odds.

The pending choice saves the concrete terms and RNG state. Loading or refreshing does not roll again. Previous compatible saves with a fixed $20 encounter retain that original offer. The previous rules fingerprint, 70ef4aad8342b811479b0122dc1411ba920da95bfdcf7f169d0753110a4391eb, is whitelisted.

The 5,400-journey [combined balance checkpoint](CURRENT_BALANCE_PASS.md) predates this change and remains a frozen baseline. The new feature has its own bounded-demand, payment, saved-choice, whole-wagon, body/food and interface regressions plus integration validation. Human judgment remains necessary for whether each tradeoff is understandable and reasonable.

## Validation

Feature checkpoint 6b6987e passed all 49 Godot suites in a clean isolated checkout, including 3,673 demand checks. The 256-quote rich-party sweep produced 161 cash/goods bundles, 51 cash-only demands, 44 goods-only demands and seven wagon demands. These are deterministic regression coverage, not measured historical frequencies. Native mixed and full-wagon screens were inspected; the mixed example was shown to Spencer.

Forty-eight additional full-route journeys (May, ordinary party, three capitals, salted/steady policies, seeds 6000–6007) reported zero selected errors. The [summary](balance-bandit-validation-01-summary.json) retains matching source hashes and rules. Twenty-four store and twenty outlaw integration journeys passed. The initial store run recorded one no-time loop in its obsolete trading policy; switching that harness to the existing current counter/foraging policy resolved it. Game rules were not weakened.
