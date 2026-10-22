# Classic opening flow

**Current food/load update:** see [Food and survival baseline](FOOD_AND_SURVIVAL.md) for the 800 lb suggested outfit, total cargo, variable hunting yields and fresh-meat spoilage. Earlier balance numbers below are archived observations.

Historical accuracy now takes priority over game parity. Budgets/prices below remain game fixtures pending a researched period economy; they are not evidence of actual wages or prices. Player travel now extends to the Platte. See `HISTORICAL_ACCURACY.md`.

The player begins with an illustrated town preparation view. Enter five names, choose banker/carpenter/farmer and a March–August departure, then Enter the Store. The separate interior view shows the uncommitted cart. Party returns to preparation while preserving all inputs; Depart commits once. A suggested $380 outfit (including 800 lb food) is preselected and can be changed before purchase.

## Evidence and provisional choices

| Value or behavior | Current basis |
| --- | --- |
| Banker $2,500; carpenter $1,000; farmer $400 | July 1985 H-106 booklet, PDF page 4. Pending confirmation on the supplied Apple II disks; the observed 1993 banker instead had $1,600 |
| Five names | Bouchard's firsthand 1985 design account |
| March–August choices | Observed 1993 setup; exact 1985 menu still to verify |
| Oxen $20 each, max 20 | Observed 1993 shop |
| Food $0.20/lb, max 2,000 | Observed 1993 shop |
| Clothes $10/set, max 50 | Observed 1993 shop |
| Ammunition $2 per 20-bullet box, max 100 boxes | Observed 1993 shop |
| Wheels, axles, tongues $10 each, max 3 each | Observed 1993 shop |
| Optional care/repair kits $5 each, max 40 | New survival tuning; not an observed period or classic price. Suggested quantity zero; the current suggested cart totals $380 |
| At least two oxen; suggested quantities | New design for the playable slice |
| Steady pace and Filling rations on departure | Initial settings observed in the 1993 run; numeric travel/health formulas remain provisional |
| One daily update every 1.25 real seconds | New presentation tuning; simulation does not depend on this interval |

This deliberately documented mixture is not a claim of exact 1985 executable parity. See `MECHANICS_LEDGER.md`, `REFERENCE_PLAYTEST_1993.md` and `BOUCHARD_DESIGN_NOTES.md` for source context.

## Accounting and state

`data/outfitting.json` stores integer-cent prices, limits and suggestions. `simulation/outfitting.gd` validates the catalogue and quotes without mutating state. The engine validates party names, month, profession, quantities, affordability and the oxen requirement before committing departure. Rejection leaves inventory, date and RNG unchanged. Departure cannot be committed twice.

Money is quoted in integer cents and stored as dollars rounded to cents for compatibility with existing event costs. Bullet boxes convert to individual bullets. Wheels, axles and tongues remain separate; `parts` is a derived summary, and authored events must use typed component effects. A wheel encounter cannot consume an axle instead. Zero spare wheels still permits the time-consuming repair alternative.

Party names are copied on commit and recorded in the journal; departure creates individual health records for View Party (see `PARTY_HEALTH.md`). Clothing protects from exposure; ammunition supports hunting and protective encounter choices. Team size, condition and fatigue modify progress; month affects the seasonal weather scenario. Profession score multipliers remain unimplemented. See `BASIC_SURVIVAL_BENCHMARK.md` for current systems and provisional tuning.

The public interface constructs `Simulation.new(seed, "classic", true)` to require setup. The default constructor retains the earlier pre-outfitted first-leg fixture for scripted engine regressions and parked experimental examples; it is not exposed as a player bypass.

## Travel controls

Continue starts the UI timer; each timeout asks the simulation to advance one day. Pause cancels the timer. Important encounters, river arrival, defeat and completion stop it automatically. Choosing an encounter result leaves travel paused until Continue is selected again.

Camp first stops travel, then advances one rest day. Guide, Journal and pace/ration changes also stop travel. New Journey cancels the old timer and creates a fresh outfitting state. No wall-clock timestamps or timer nodes are used by the simulation engine; its calendar is derived from the selected departure date and elapsed whole days.

Crossing choice effects and the single RNG outcome are committed once before a visual begins. A 2.8-second ford/float/ferry animation holds the controls; Skip finishes the presentation without changing that result. Guide and Journal pause the animation, and New Journey cancels it. Completion leaves travel paused. The engine's `last_crossing` data is presentation input, not a second rule resolver.
