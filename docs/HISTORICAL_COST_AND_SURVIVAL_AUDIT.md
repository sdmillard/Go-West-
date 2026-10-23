# Food costs and survival: evidence, choices and a matched diagnostic

October 22, 2026. This follows [the historical baseline](HISTORICAL_BALANCE_BASELINE.md). Spencer's direction is to use the best historical evidence, accept hard economic choices, and improvise plausibly where the record cannot settle an exact value. Do not compensate every expense with more starting money.

## Decision shipped

Opening mixed food is now **5 cents per staple-equivalent unit**, formerly 6 cents. This is an informed estimate, not a certified 1848 Independence receipt. The default 1,700-unit food purchase costs $85, down from $102. Its quantity and cargo are unchanged. The complete suggested six-ox cart costs **$375.60**.

| Starting capital scenario | Funds before shopping | Cash after suggested cart |
| --- | ---: | ---: |
| Farmer | $600 | $224.40 |
| Carpenter | $900 | $524.40 |
| Banker | $1,400 | $1,024.40 |

These funds represent different asset-sale and difficulty scenarios. Wagon, gun and basic household equipment are already owned. No source reviewed establishes these exact occupation-based cash amounts; retained funds must not be advertised as historical salaries or a statistical household average. They were not raised to offset supplies. Smaller carts, different teams and unpaid companions remain meaningful choices.

## Price evidence and calculation

A primary newspaper gives comparable dated quotations, with important limits:

| Food | Kanesville, March 20, 1850 | Kanesville, May 1, 1850 |
| --- | ---: | ---: |
| Flour, per 100 lb | $2.50-2.75 | $6.00-6.50 |
| Bacon, per lb | 6 cents | 8-9 cents |
| Sugar, per lb | 9-10 cents | 9-10 cents |
| Rice, per lb | 8 cents | 8 cents |

Sources: [March Frontier Guardian, p3 col4](https://byustudies.byu.edu/online-book/the-frontier-guardian/march-20-1850-volume-2-number-4-146), [May Frontier Guardian, p3 col4](https://byustudies.byu.edu/online-book/the-frontier-guardian/may-1-1850-volume-2-number-7-146). Both postdate the setting and describe a different departure market. The May report explicitly describes scarce supply and strong demand; it is not a normal permanent price list for every location.

For a partial comparison basket of 200 lb flour, 75 lb bacon, 25 lb sugar and 10 lb rice, weighted cost is $12.55-13.30 for 310 lb in March, or **4.05-4.29 cents/lb**. The same basket costs $21.05-23.05 in May, or **6.79-7.44 cents/lb**. These are calculations from the reported component prices, not an actual basket sale. They omit bread, beans, fruit, coffee, tea and other supplies. Choosing 5 cents for the broader game bundle allows some room for those goods, preparation and local merchant variation. The precise allowance is authored; no historical profit margin was recovered.

We also inspected [Merchants' Magazine, April 1849, printed p438](https://fraser.stlouisfed.org/files/docs/publications/merchmag/merchmag_v20_184904.pdf), visually checking PDF page87. Its 1848 St. Louis flour figure is $4.25 per barrel in an **estimated produce-receipts valuation**, not a retail departure-store quote. It is useful contemporary context, but cannot certify the entire food price. The source ledger records the scan hash, headings and limitations; third-party downloads remain ignored.

Reproduce the basket and current cart arithmetic with `research/food_cost_audit.py`. Exact inputs, dates, URLs and limits are in `research/FOOD_PRICE_AUDIT.json`.

## What the other investigations support

**Travel and calendar.** [NPS](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) gives a broad 12-15 miles/day and four-six months. The four six-ox carpenter/no-hunting reference journeys here take 129-134 moving days over 1,938 guide miles: about 14.5-15.0 miles per moving day. Their total durations are 180-210 days, including 16-39 explicit rest actions, 5-7 trade actions and other delays. Simply raising base speed would obscure the distinction between reasonable movement and accumulated overhead. Inspect rest thresholds, illness and service-day costs next, while retaining consequences for bad timing. April 1 in the experiment is an early stress departure; May 1 is closer to ordinary spring timing. Neither represents a reconstructed single historical wagon train.

**Teams, load and grazing.** [Palmer's 1847 guide, pp258-263](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS) advises eight oxen and a 2,500-lb starting load, with cattle relying on grass. [The End of the Oregon Trail's broader interpretation](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) describes four-six head and more conservative load advice. Retain the four-head baseline and six-head suggestion; eight is insurance, not a required minimum. Current speed bonuses stop at six: purchasing eight costs $60 more without an immediate speed gain, but leaves reserves after losses. The diagnostic keeps human cargo identical across teams. Sparse forage remains an abstraction in condition, season and rest; the evidence supports grazing rather than charging oxen communal human provisions. Exact capacity and recovery curves remain authored.

**Hunting and preservation.** [Marcy's 1859 handbook, chI/V](https://www.gutenberg.org/cache/epub/23066/pg23066-images.html) supports variable provisioning needs, drying without salt and opportunities to process during travel. It also describes weakness on lean meat despite large consumption. This later expedition account cannot establish a universal family diet, daily processing allowance or shelf life. Keep optional salt, ammunition costs, finite hauling and spoilage. Investigate whether charging a full stopped day for every small preservation batch creates too much calendar overhead before increasing hunting yields. No exact drying retention or expiry figure became a historical fact in this pass.

**Food value.** [FAO's composition table](https://www.fao.org/4/x9892e/X9892e05.htm), in modern as-purchased weights, lists wheat flour at 364 kcal/100g and a broad game-meat category at 104. That is evidence against universal pound-for-pound energy equivalence, not a ready conversion for field-recovered edible meat. The game's existing units are deliberately abstract. This price-only change does not certify those nutrition assumptions. A future small conversion must preserve actual carcass/cargo mass and be tested against hunting, ordinary meals and exceptional meals together. Avoid a large nutrient-management interface solely to claim false precision.

**Health, wages and danger.** Retain the existing [cash-plus-board wage audit](HISTORICAL_ECONOMY.md) and 1849 cholera gate. Period guides and pooled casualty counts do not establish our daily illness or combat probabilities. Classify causes and financial pressures rather than impose a historical-looking global death quota. The single cholera death in the new diagnostic occurs during a journey extending into 1849, consistent with the existing year gate. Crime and betrayal remain authored choices and risks, not requirements for lawful survival.

## Matched diagnostic: 216 journeys, no live rule overrides

[Six-cent baseline](historical-diagnostic-01.json) and [five-cent comparison](historical-diagnostic-02.json) each contain 108 journeys: three capital scenarios, April/May departures, four/six/eight oxen, three food strategies, and seeds0-1. Default unpaid parties are matched by seed. Strategies are no hunting, hunting/drying, and hunting/salt-assisted drying. The same cautious adaptive public-action policy handles weather, health, care, finite trade, crossings and tolls. Salt can fall back to drying. No crime, slaughter, walking policy, hired companions or peaceful-camp visits are used. This is a narrow affordability/timing diagnosis, not the full mechanic cohort or held-out campaign.

Both samples retain rules signatures, regular food/cash/animal/cargo snapshots, first-arrival landmark dates, action counts and final causes. Saves are round-tripped every80 actions and at the end. Selected inventory, party and remains invariants are checked after actions.

| Capital scenario, 36 runs each | Six-cent arrivals | Six-cent intact | Five-cent arrivals | Five-cent intact |
| --- | ---: | ---: | ---: | ---: |
| Farmer | 23 | 15 | 27 | 19 |
| Carpenter | 36 | 36 | 36 | 36 |
| Banker | 36 | 36 | 36 | 36 |

Before: 95 arrivals, 12 losses, one action-limit outcome. After: 99 arrivals, seven losses, two year-limit outcomes. Both report zero selected invariant/setup/save errors. **The old action-limit result is unresolved policy evidence, not a death or a claim that the policy never loops.** The original baseline remains archived; do not suppress it when interpreting the comparison. Identical seeds are not independent travelers, and richer parties do not hunt in this sample, so their three food-strategy rows repeat the same behavior. No victory percentage here is a target.

Farmer outcomes at five cents (four runs in each cell):

| Team | No hunting: arrival / intact | Drying: arrival / intact | Salt strategy: arrival / intact |
| --- | ---: | ---: | ---: |
| Four oxen | 2 / 2 | 4 / 3 | 3 / 2 |
| Six oxen | 2 / 2 | 4 / 3 | 4 / 3 |
| Eight oxen | 1 / 0 | 3 / 2 | 4 / 2 |

These tiny cells show useful tradeoffs, not reliable probability estimates. More oxen cost reserves that could buy meals; extra animals are not automatically the safest purchase for a cash-poor party. Preservation helps here but can add considerable time. Across all five-cent runs, 45 deaths are attributed to lack of food, seven exposure, four dysentery and one each cholera, measles and typhoid. They are simulated outcomes under this policy, not clinical findings or historical incidence.

## Validation, compatibility and next work

The old six-cent save fingerprint is accepted through the existing economy migration. An authentic pre-change save fixture verifies that cash, supplies, pending choices and RNG survive unchanged; there is no retroactive refund. New departures pay the new quote. Relevant exact-price UI/simulation tests are updated.

To reproduce: use the isolated APPDATA setup in `test.ps1`, then run Godot headless with `--script tests/historical_diagnostic.gd -- --label=historical-diagnostic-03`. The harness refuses an existing output name. Reproducing the older price state requires the matching older rules; neither archived report is overwritten. The study is separate from the regular regression suites.

Next: examine the capped baseline policy, service/rest/preservation overhead and meat-value accounting before changing more prices or speeds. Add a small hired-party and emergency-survival cohort, then the roadmap's broader campaign. Keep economically hard outcomes where decisions and setbacks explain them; improve previews or choices where the player cannot understand or respond to the pressure.

Validation completed: all 29 suites in `test.ps1` passed, including 116 historical-economy checks and the authentic pre-price save migration. The two diagnostic archives contain 108 runs each. This does not clear the baseline action-limit policy finding or constitute the full balance campaign.

Follow-up: [Journey policy and time audit](JOURNEY_TIME_AUDIT.md) resolves the baseline menu loop, records an explicit replay and adds elapsed-day accounting. It retains the original archives and current game rules.
