# Wages and purchasing power in the 1848 setting

The later [character catalog](CHARACTER_CATALOG.md) adds authored premiums for new specials. This audit records the earlier wage scale and simulation cohorts; new hired combinations can quote up to 1.30 dollars/day before voluntary higher offers. Original background bases, budgets and item prices remain as recorded here.

October 22, 2026. This replaces the provisional wage scale in PARTY_SETUP.md. Values are nominal period dollars. We compare cash **plus board** with cash plus board, and separate owned equipment, spending money and wages. No modern inflation multiplier is used.

## Evidence and its limits

The [1850 Census statistical compendium](https://www2.census.gov/prod2/decennial/documents/1850c-05.pdf), printed pp.164–165 (PDF pp.32–33), summarizes an **1848** Patent Office inquiry: free white field laborers received about $10–$15 monthly with board; mechanics generally 75¢–$1.50 daily. These are different employment arrangements, not interchangeable daily/monthly rates. The same page's **1850** Missouri table reports $11.81 monthly for a boarded farm hand, 55¢ daily boarded labor, 75¢ unboarded labor, $1.48 daily unboarded carpentry, and $1.31 weekly board. Its Oregon figures belong to a later, very different market. These observations provide scale, not a recovered emigrant hiring tariff. Historical discriminatory categories are source context; the game does not price people by sex or race.

We downloaded that federal scan and visually checked the relevant pages. The local source ledger records its hash and pagination. The [University of Missouri wage guide](https://libraryguides.missouri.edu/pricesandwages/1840-1849) helps distinguish occupation, date and board arrangements.

The [End of the Oregon Trail price compilation](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) gives oxen around $30–$35 each, salt 6¢/lb and flour 2¢/lb. It explicitly combines 1840s/early-1850s evidence across places. We use the low oxen estimate and salt estimate as provisional anchors; these are **not verified Independence shop prices for 1848**. Its 1857 labor complaint is unsuitable as our baseline.

[Palmer's 1847 guide](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), already inspected in the previous economy pass, quotes Hall/Boise emergency flour at $20/100 lb. We retain that anchor for the existing 200-lb bulk offer, with the documented mixed-food abstraction. The [NPS $800–$1,200 estimate](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) covers outfitting and a year's support in **1850**; it is not an 1848 cash wage or a mandatory amount left after shopping.

## New agreements: cash plus party provisions

| Background | Base cash/day | Equivalent per 30 journey days |
| --- | ---: | ---: |
| Hunting/general camp contribution | $0.40 | $12.00 |
| Carpentry | $0.90 | $27.00 |
| Caregiving | $0.50 | $15.00 |
| Trading | $0.60 | $18.00 |

The hunting base approximates boarded monthly labor; the carpentry base allows a skilled premium. For scale only, 26 days at the Missouri unboarded carpenter rate less 30 days of its reported weekly board is about $32.86. That calculation assumes continuous employment and should not be treated as a quoted contract. Our $27 base is an authored compromise for a companion who also receives passage and provisions, and provides intermittent repairs rather than full-time shop production. Caregiving means practical camp help, not a physician. Trading is an authored negotiation/experience premium; no historical occupation series establishes that exact rate.

Compassionate subtracts 5¢/day; Pragmatic adds 5¢; Loyal adds 10¢; Veteran adds 20¢. These **personality and special-trait prices are game tuning**, not findings about historical personality pricing. Minimum defensive floor: 30¢. Actual selectable quotes run 35¢–$1.25/day ($10.50–$37.50 per 30 days). Cautious/Bold, Cannibal and relationships do not change wages. All figures and premiums are in `data/party_benefits.json`, checked before use.

Food is already taken from communal provisions. The cash wage does not buy meals a second time. Existing daily travel/rest/care days continue counting toward wages. The 30-day amounts above are comparison units; contracts remain exact integer cents every 1–7 days. Billing frequency, sick pay, wage trust gains and notice rules are authored game contracts. Old agreements, arrears and due dates remain unchanged when a save loads. Free companions keep the same backgrounds and boundaries; paid companions gain a predictable trust mechanism at a recurring cost.

## Economy audit

| Item/system | Current treatment | Evidence status |
| --- | --- | --- |
| Opening ox | $30/head, formerly $20 | Broad period compilation; provisional local estimate |
| Passing trader ox | $45 base, formerly $30; regional factor/eligible discount apply | Authored transport/scarcity margin; resale remains $10 base |
| Opening salt | 6¢/lb, formerly 10¢ | Broad period compilation |
| Mixed opening food | 6¢ per staple-equivalent lb | Blended game commodity, not flour alone |
| Hall/Boise food | $40/200-lb base lot before companion discount | Earlier guide's emergency flour benchmark; availability/mixture abstracted |
| Other traders, regional margins, stock limits | Existing bounded offers and spreads | Scarcity is supported; precise multipliers and lots are tuning |
| Clothing, parts, ammunition, combined care/repair kits | Existing $10/set, $10/part, $2/20 shots, $5/kit | Bundles need itemized reconstruction; no exact historical certification |
| Paid care and river fares | Existing quoted transactions | Not a universal historical fee schedule; Barlow toll evidence documented separately |
| Farmer/carpenter/banker funds | $600/$900/$1,400 | Difficulty budgets; not annual occupational earnings |

The wagon, gun and basic household/survival tools are already owned. Thus the suggested six-ox outfit is **$392.60**, leaving **$207.40** for a farmer. No change to its cargo weight. A neutral basic hire costs $72 cash over 180 days; four neutral backgrounds cost $432, plus their communal supplies. A farmer should be able to consider one hire, but cannot assume they can fund four throughout the journey. A player can still choose four oxen instead of six to retain another $60, at the existing team-speed tradeoff. We do not silently increase starting funds to cancel the cost of hiring.

## Verification and simulation

The dedicated economy suite checks exact interval minima across every background/value/Loyal/Veteran combination, malformed wage data, actual outfit cost and migration of an authentic old higher-wage contract. Existing framework tests cover debt, payments, trust rewards and departures. Native party-editor capture verifies that cash, party food and the 30-day equivalent are readable.

The matched journey report is `historical-wages-balance.json`; the previous `specialist-balance.json` remains archived. This is an archived run from before the creation trait cap. The current `tests/specialist_balance.gd` writes `flaw-budget-balance.json`, requires Slow Healer for its three-special cohort, and therefore is a different experiment. Use project-local APPDATA as shown in `test.ps1`. Six cohorts cover three professions, March/May/August and seeds 0–9: volunteers, four ordinary hires, equivalent free/paid Loyal Veterans, one hire and two hires. Hire positions use seed-shuffled backgrounds. All use the same cautious 65%-aim salted-hunting policy, real food costs, ordinary disease/weather, and full debt payments only when $10 remains. Departures and final saves use normal engine actions. This is an affordability comparison, not a historical mortality reconstruction or a human playtest. See the appended results below.

### Matched results

All 540 journeys completed with zero selected invariant, setup or final-save errors. Each table cell covers 30 journeys (three departure months × ten seeds). Arrivals mean at least one survivor reaches Oregon, not an intact group.

| Roster | Farmer arrivals | Carpenter arrivals | Banker arrivals | Departures across all 90 runs |
| --- | ---: | ---: | ---: | ---: |
| Volunteers | 25/30 | 30/30 | 30/30 | 0 |
| One ordinary hire | 18/30 | 30/30 | 30/30 | 4 |
| Two ordinary hires | 17/30 | 28/30 | 30/30 | 12 |
| Four ordinary hires | 25/30 | 26/30 | 30/30 | 110 |
| Free Loyal Veterans | 25/30 | 30/30 | 30/30 | 0 |
| Four hired Loyal Veterans | 28/30 | 22/30 | 30/30 | 139 |

Carpenter one-hire parties paid a mean $111.33 over their actual journeys with no companion departures; banker one-hire parties paid $114.47 with none. Farmers paid $71.62 with four departures total, but fewer survived than the volunteer control. Cash spent paying a companion can compete with food, replacement animals and care even before a missed bill. This policy pays in roster order and protects only a $10 reserve; it is not an optimal survival budget or proof that one hire is always affordable.

Four ordinary hires retained 111 of 120 companion slots across carpenter runs versus 63 in the earlier placeholder-wage study; banker parties retained all 120 with mean trust 99.9 versus about 61 for volunteers. Those before/after counts also include changed ox/salt prices, so they do not isolate wages. Farmers with four ordinary hires still lost 107 companions to departures. Their 25 arrivals cannot be read as strong hired-party performance; departures reduce food demand. Even the apparently better farmer arrival count for paid Loyal Veterans hides all 120 companions departing.

Hiring now has a historically plausible cash scale and a functioning trust advantage when financed, while four-person payrolls remain a substantial undertaking. Starting cash, bundled commodity definitions, route delays and survival policy still influence affordability. No outcome percentage is used as a target historical death rate. Rules signature: `cbceaf523eb55ce31ca786db0e9bbcd147fb3422010753e94214049f77c9292e`.


