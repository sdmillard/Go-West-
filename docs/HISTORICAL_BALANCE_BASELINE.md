# Historical baseline before the full survival balance campaign

Reviewed October 22, 2026 against canonical master `ee615bc`. Research and calibration proposals only: this pass changes no prices, probabilities, saves or gameplay. This document takes precedence over archived balance reports when describing the next experiment; it does not supersede their recorded results.

## What the evidence can establish

Use dated evidence near the 1848 setting first, contemporary advice second, and later interpretation for comparison. A recommended outfit is not a measured diet; an individual diary is not a population rate. Distinguish cash from owned assets, heads from yokes, cargo from wagon weight, food mass from meal value, and moving days from elapsed days.

| Evidence checked | Historical observation | Limit and use |
| --- | --- | --- |
| [Palmer, 1847 guide in the 1906 reprint](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), printed pp.258-263 | Recommends eight oxen and a 2,500-lb starting load; cattle graze. Per adult, five weighed staples total 340 lb, with other provisions additional. Advises mid-April departure. St. Joseph work cattle cost $25-30 per pair; emergency Hall/Boise flour $20/100 lb. | Advice and reported prices from one author, not an 1848 Independence receipt. Do not promise his mission resupply arrangements in 1848. |
| [NPS, Traveling the Emigrant Trails](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm), Oregon Route / Supplies | Broad travel estimate: 12-15 miles/day, four-six months. Its $800-1,200 outfit estimate is for 1850 and includes a year's support. | Travel context, not an exact speed for every day. Total outfit expenditure is not cash left after buying a wagon. Its Ware food list is dated 1849. |
| [End of the Oregon Trail, Outfitting for the Journey](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) | Describes four-six oxen; distinguishes structural load capacity from advice to carry 1,600-1,800 lb. Its broad price list gives oxen $30-35/head and salt 6 cents/lb. | Explicitly spans the 1840s and early 1850s, with no single town/date. A useful alternative to Palmer, not a way to erase conflicting evidence. |
| [Marcy, The Prairie Traveler, 1859, ch.V: Jerking Meat](https://www.gutenberg.org/cache/epub/23066/pg23066-images.html) | Describes drying without salt and, in some circumstances, during travel. | Eleven years later; supports optional salt and variable processing opportunity. Does not establish our exact retention, weight, shelf life or mandatory stopped day. |
| [BLM, History Bits and Westward Quotes](https://www.blm.gov/learn/interpretive-centers/national-historic-oregon-trail-interpretive-center/explore/quotes), Louisa Cook, June 13, 1862 | A day's excited buffalo hunting produced only one small antelope. | Later first-person counterexample to guaranteed hunting success; it cannot supply an 1848 success percentage. The same collection documents trade and rare fatal attacks rather than continuous warfare. |
| [NPS, Cholera: A Trail Epidemic](https://www.nps.gov/articles/000/cholera-a-trail-epidemic.htm) | Places the major trail epidemic in the Gold Rush context; describes George Winslow's death in June 1849. | Supports keeping that epidemic context separate from 1848. No daily illness probability or universal mortality target follows. |
| [1850 federal census compendium](https://www2.census.gov/prod2/decennial/documents/1850c-05.pdf), printed pp.164-165 | Existing visually checked project wage audit records the 1848 inquiry's $10-15/month field labor with board and 75 cents-$1.50/day mechanics. | Retained from [the prior wage audit](HISTORICAL_ECONOMY.md) and its hashed local scan; not newly visually verified here. These are not trail mercenary contracts. |

Palmer's five staples are flour, pilot bread, bacon, rice and sugar; beans, fruit and meal include volume measures. Do not silently convert those bushels into pounds. Four yoke means eight animals. His steeper-road examples also describe temporarily combining teams; they do not establish a uniform per-ox speed bonus.

## Comparison with the current rules

### Food is the first calibration priority

`data/outfitting.json` suggests 1,700 food units for five adult-equivalent travelers: 340 each. This numerical resemblance to a period packing list does not validate nutritional equivalence. `data/provisions.json` consumes 1/2/3 units per person/day, while hunted meat enters the same meal-value pool at one unit per awarded pound. Dried meat has a separate physical cargo multiplier, but fresh meat versus staples does not.

Arithmetic for a healthy, intact five-person party, without purchases, losses, spoilage or hunting:

| Ration | Daily party use | Initial supply lasts | Supply needed for 180 days |
| --- | ---: | ---: | ---: |
| Bare | 5 | 340 days | 900 |
| Meager | 10 | 170 days | 1,800 |
| Filling | 15 | 113 complete days | 2,700 |

New departures select filling rations. Its 180-day deficit is therefore 1,000 units before any waste. That is an important authored dependency on hunting/purchases, not evidence that a historically provisioned party routinely needed that much extra food.

Before tuning hunting rewards, define a stable staple-equivalent meal unit and separate it from physical meat mass. A small internal conversion is sufficient; a large new cooking inventory is not required. Derive any eventual conversion from a documented food basket and modern food-composition evidence, clearly labeled as inference. This pass has not performed that nutritional reconstruction. Preserve cargo conservation across hunting, drying, consumption, spoilage and looting.

### Pace and the seasonal window

`data/survival_rules.json` starts from 22/26/30 miles per travel action. Team condition, fatigue, terrain, weather and load multiply those values; stops truncate travel at landmarks. Do not replace 22 with 12 merely by comparing the raw number to the historical summary.

Measure both miles per moving day and miles per elapsed day, plus dates at major landmarks. The current saved lawful camp-visiting sample arrives in 185, 199, 226 and 234 days (sorted), with all four arrivals but only three intact. Its policy and late departures differ from a timely, ordinary spring journey. It is integration evidence, not a historical cohort or a target to reproduce.

Use mid-April/May departures for the main historical calibration; keep March and August as early/late stress cohorts. Evaluate mountain and Cascade arrival dates, not only the final day count. Retain the route's 1,938 *reported guide miles*: they are not a GPS distance that should be rescaled to a modern round-number description.

### Livestock, loads and recovery

The game uses four oxen as its baseline, suggests six, permits fewer with penalties, and caps the speed factor at 1.10 for six or more. Cargo guideline is 2,500 lb; working capacity is an authored 625 lb/ox. Evidence supports a range of outfits rather than a universal four-animal minimum.

For the first matched experiment, compare four, six and eight head with the same cargo. Treat additional animals primarily as reserves and load/condition resilience; compare the existing speed bonus against no bonus before choosing. Do not change the player's agreed four-head baseline solely because one guide recommends more. Current grazing is abstracted through region, summer strain and rest; oxen do not eat communal human food. Test that condition and recovery make sparse forage matter without an unexplained human-ration charge.

The suggested cart weighs 2,359 lb under current item weights, including the 450-lb household allowance. It is below our 2,500-lb guideline but heavier than the museum's conservative advice. Record this as a meaningful loaded-wagon scenario, not a universally ideal outfit. Wagon mass and people are outside cargo accounting.

### Money, wages and replacement supplies

Current budgets are $600/$900/$1,400 with wagon, gun and basic tools already owned. Suggested purchases cost $392.60, leaving $207.40/$507.40/$1,007.40. Keep that distinction: the budgets are asset-sale/difficulty scenarios, not occupational annual salaries. A historical total outfit estimate cannot be applied again as spending cash after excluding the wagon.

Opening oxen are $30/head; Palmer's earlier paired price and the museum's higher per-head figure must remain separate benchmarks. Keep prices provisional until a dated local receipt can narrow the range. Salt is 6 cents/lb; mixed food is 6 cents/unit, not a flour quotation. Exact bundled ammunition, clothing, medicine/repair-kit prices still lack an itemized reconstruction. Hall/Boise's $40 base for 200 food units resembles a flour benchmark, but stock, commodity mixture and discounts are game decisions.

Keep the previous cash-plus-board wage scale for now. Exact background bases, personality premiums and scheduled trust rewards are authored. Measure cash paid, arrears and companion retention together; a journey that becomes easier because unpaid companions leave is not evidence of affordable payroll.

### Hunting, preservation, health and crime

Hunting's 100-lb recovery limit is classic-game design, not a universal human carrying limit. Species weights and per-outing success rates are estimates. The current two-day fresh window, 21/30-day preserved windows, 80/90% retained meal value and 5% salt cost are tuning, not recovered historical preservation equations. Test time, weather, transport and ammunition costs together before increasing yields.

Illness onset (3% base per eligible daily check), recovery days, damage and healing are authored probabilities. Cholera already has a `from_year: 1849` gate. Preserve that setting distinction; do not tune the whole 1848 party to a pooled decades-long mortality percentage. Report illness, accidents, starvation, exposure and violence separately.

Crime odds, pursuit rolls, information speed, human-meat yield and companion reactions have no demonstrated historical statistical calibration. Keep their exact values labeled as gameplay. Do not make deliberately violent strategies reproduce an ordinary emigrant cohort's mortality, and do not make the lawful trail dangerous mainly through armed attacks.

## Order of work before the large campaign

1. Fix the food-unit definition and its accounting assumptions on paper; identify any necessary small conversion change before tuning the economy.
2. Run a small lawful spring-departure diagnostic with four/six/eight oxen, ordinary volunteers and identical initial cargo. Separate hunting, drying and salted preservation. Record elapsed/moving days, landmark dates, food and cash trajectories, animal condition and causes of death.
3. Check current high-load and lighter-load outfits, one affordable hire, limited ammunition, and a missed resupply. Keep walking and abandonment as emergency stress cases.
4. Change only evidenced bottlenecks, preserving prior reports and recording each rules signature. Exact rates without historical denominators remain authored parameters.
5. Then run the roadmap's matched development campaign and held-out sample. Arrival, intact arrival, deaths, departures and capture remain separate outcomes. Human testing still follows for clarity and pacing.

No new source establishes a historically correct victory percentage. Historical timing, provisioning scale and plausible tradeoffs constrain balance; the game still needs transparent, winnable choices.
