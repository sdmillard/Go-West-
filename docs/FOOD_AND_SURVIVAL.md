# Food, cargo and survival baseline

**Current rules:** [Food value and hauling](FOOD_VALUE_AND_HAULING.md) supersede this archived opening baseline. The current suggested outfit costs$375.60 with 1,700 lb staples, two care kits and 10 lb salt. New meat has separate food-unit value and physical weight; drying and salt-assisted drying are implemented. Treat the old prices, carry cap and opening-only results below as an archive.

**Full-route update:** [Route expansion](ROUTE_EXPANSION.md) now connects Oregon City and supersedes the opening-only movement tuning below. Archived chapter outcomes remain useful snapshots, not whole-trail predictions.

This pass precedes save/load, gravestones and route expansion. It closes the opening chapter's food-accounting gaps without claiming reconstructed 1848 physiology or ecology.

## Player rules

The suggested outfit now includes **800 lb food** and costs **$380**, leaving the farmer $20 before optional care kits. It provisions the opening corridor, not the entire trail. The store shows cargo mass and an upper-bound food-days estimate. **Options → Provisions / Cargo** distinguishes staples from fresh meat, shows the 2,500 lb departure guideline and permits discarding supplies without spending a day. Discards are permanent and recorded.

Cargo includes food, clothes, bullets, spare wheels/axles/tongues and care kits, plus an estimated 450 lb allowance for household equipment, bedding and tools. It excludes wagon weight, people and oxen. Item weights are explicit authored estimates in `data/provisions.json`, not measured artifacts: clothes 6 lb/set, bullets 0.1 lb/unit including an abstract ammunition allowance, wheel 35 lb, axle 60 lb, tongue 50 lb, care kit 2 lb. Opening purchases above 2,500 lb are refused. Later excess cargo slows travel and can be discarded. Load drag is continuous above 1,250 lb, reaching a 0.75 multiplier at 2,500 lb; the old food-only 1,200 lb cliff is removed. Team, terrain, fatigue and weather still multiply movement.

Bare/meager/filling use 1/2/3 lb per living traveler each day. All five are currently treated as adult-equivalent travelers. These are meal-supply proxies, not caloric calculations: flour, pork and lean meat do not have identical nutritional value. Staple composition, micronutrients and preservation processing are not simulated. Partial shortfalls proportionally scale the internal lack-of-food penalty instead of charging the full empty-larder penalty for being a pound short. Underfed days cannot grant rest healing. Nutrition-linked illness and ration-dependent recovery remain connected.

Hunting generates per-animal recoverable meat within ranges: **bison 200–450 lb, deer 42–85 lb, cottontail 1–2 lb**. Ranges are selected for gameplay within the source context below, not historical sampled distributions. The 100 lb classic carry cap and remaining wagon capacity limit actual return. Extra meat stays behind and is reported. A batch returned on day D can feed the party on D+1 and D+2; any remaining meat is discarded on D+3 before meals, with exact losses in the journal. Oldest fresh meat is eaten first, then staples. Buying/event food remains the abstract staple pool. Negative food events and discards update the meat ledger too. The two-day window is an authored game abstraction, **not a food-safety recommendation**; cooking/drying, temperature and carcass retrieval are not modeled.

## Evidence and limits

- [NPS overland-wagon interpretation](https://home.nps.gov/jeff/planyourvisit/overland-wagon.htm) supports a broad 2,500 lb supply guideline and explains why household equipment belongs in cargo. It does not specify our individual item weights or speed curve.
- [Palmer's 1847 outfit advice, pp. 258–261 in the 1906 reprint](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS) lists 340 lb/adult from five weighed staples alone, plus other provisions. This gives context for the scale of provisions; it does not prove our daily ration table or prices.
- [PNW Extension publication 517, table 2, printed page 23](https://www.nifa.usda.gov/sites/default/files/resource/Big%20Game%20from%20hunt%20to%20home.pdf) estimates roughly 42–86 lb boneless product from 80–160 lb field-dressed deer/antelope. It also distinguishes carcass and product weight and stresses meat handling. Selecting that animal-size bracket is our choice; modern processing tables are not trail hunting measurements.
- [Missouri Department of Conservation's cottontail account](https://mdc.mo.gov/discover-nature/field-guide/eastern-cottontail-cottontail-rabbit) gives a live weight around 2–3.25 lb. The former 4 lb meat reward was therefore unsuitable for this cottontail representation. Our 1–2 lb food award remains approximate, not a published dressing-yield estimate.
- [National Bison Association production guidance](https://nationalbison.org/raising-bison/) reports about 450 lb meat per carcass in a modern production context. This supports distinguishing a large animal from the 100 lb transport cap; our lower 200–450 lb field recovery range is an adaptation, not a verified emigrant yield distribution.

## Balance checks

The fixed-policy experiment still starts every profile with six oxen, five adult-equivalent travelers, 200 bullets, three spare parts and two kits across 20 seeds, three months and two budgets. Hunting uses a scripted 65% aiming policy that does not navigate cover. The updated policy buys food below 120 lb when affordable and otherwise hunts below 45 lb. Earlier hunt-first results are not directly comparable: the policy changed. Fresh meat and random encounters make repeated hunting a poor guaranteed resupply strategy, as intended.

| Starting food | Cautious intact arrivals | Meager intact arrivals | Bare-ration arrivals / intact | Grueling arrivals / intact |
| --- | --- | --- | --- | --- |
| 600 lb | 119/120 | 118/120 | 95/120 / 76/120 | 80/120 / 12/120 |
| 800 lb | 120/120 | 120/120 | 103/120 / 84/120 | 80/120 / 12/120 |

The 800 lb cautious group averaged 34.8 elapsed days; the bare-ration group remained much slower and riskier. Raw results are archived in `food-balance-600.json` and `food-balance-800.json`. These runs establish a playable opening baseline, not historical mortality predictions or a substitute for human playtesting. No complete-trail outfit, economy or climatic reconstruction is claimed. Reproduce with `tests/balance_report.gd -- --label=food-800 --food=800` through Godot.
