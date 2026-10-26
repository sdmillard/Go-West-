# Livestock realism audit

October 25, 2026. Spencer's requirement: production follows defensible husbandry and historical evidence; farmer win rates do not determine animal yields. This audit changes no gameplay rules, prices, saves or artwork. It identifies corrections to make before another survival comparison.

## Findings

Keep the current milk/egg calorie densities. Spencer approved modern non-industrial/smallholding yields as practical proxies, so exact 1848 yield records are not a prerequisite. Retain the base production figures provisionally against the heritage/smallholding comparisons below; they are working proxies, not measured 1848 trail yields. Correct the food conversion, feeding model and care accounting before interpreting further farmer results.

| Assumption | Current implementation | Assessment |
|---|---|---|
| Cow milk energy | 277 kcal/edible lb | Supported as a rounded whole-milk reference value. |
| Goat milk energy | 313 kcal/edible lb | Supported as a rounded whole-milk reference value. |
| Egg energy | 650 kcal/edible lb; 0.11 lb per egg | About 72 kcal per egg; shell excluded from edible mass. |
| Cow production | 8 lb/day before modifiers | Provisional allowance; no directly comparable 1848 trail yield found. |
| Goat production | 2 lb/day before modifiers | Provisional allowance; no directly comparable trail breed/lactation/feed dataset found. |
| Hen production | 0.5 egg/day before modifiers | Provisional, not an established historical average. Traditional scavenging flocks can lay much less. |
| Feed | Each hen requires 0.25 lb purchased grain daily | Omits scraps, insects and seeds; also treats grain as if it were a complete ration. |
| Grazing/browsing | Cow and goat share one monthly curve | Omits forage type, local availability and time to feed. |
| Condition | Winter subtracts two points/day even with full care | Calendar-driven death; fully grain-fed hens also suffer it. No evidence supports this universal clock. |
| Care | Available workers depend on standing camp assignments | Idle assignments can reduce care during travel. |
| Lactation | All milk animals bought with 180 days left; final 60 taper | An explicit purchase assumption, not a biological duration shared by all animals. |
| Slaughter | Cow 250 lb, goat 25 lb, hen 2 lb edible meat at full condition | Broad estimates, not measured trail-animal carcass yields. Body size and edible recovery are not modeled. |
| Prices | Cow $75; goat $10; hen $0.50; grain $0.04/lb | Cow has a broad period museum anchor. Others remain estimates. No change justified by survival outcomes. |
| Storage | Milk one day; eggs fourteen; mixed lots use earliest expiry | Game abstractions. Temperature, shell status and separate lots are not represented. |

## Controlled reproduction

The [machine-readable report](livestock-realism-audit-01.json) records 13 fixtures against unchanged gameplay at master `e09150ffa5a0a65620d1e05b49a0e72fab5389fa`. It includes normalized source hashes and the save-rule fingerprint. The [diagnostic runner](../tests/livestock_realism_audit.gd) calls the actual livestock module with healthy people and clear weather, holding human meals, routes, health deterioration and random streams fixed. January is injected after a legal May departure. This is a module experiment, not a complete playable January journey.

Run from the project directory:

```powershell
& ./.tools/godot/Godot_v4.5.1-stable_win64_console.exe --headless --path . --script tests/livestock_realism_audit.gd
```

All 13 fixtures completed without setup or livestock-record validation errors. These observations expose existing behavior; they are not assertions that the behavior is correct. The script is separate from the regression suite so future fixes do not have to preserve defects. It rewrites the report deliberately; keep this baseline when comparing revisions.

### Whole units distort recurring production

In May, full condition and full care, on one rest day:

| Animals | Produced edible milk | Source kcal | Inventory kcal | Difference |
|---|---:|---:|---:|---:|
| One cow | 8 lb | 2,216 | 2,000 | -9.7% |
| One goat | 2 lb | 626 | 1,000 | +59.7% |
| Two goats | 4 lb | 1,252 | 1,000 | -20.1% |
| Cow + goat | 10 lb | 2,842 | 3,000 | +5.6% |

The problem is conversion, not animal biology. Rounding each combined recurring batch changes calories according to herd composition. Six fed hens laid 90 eggs over 30 isolated May days: 6,435 kcal produced, 7,000 represented by converted food plus 429 kcal still held as eggs. The conversion had already created 994 kcal. Converted output is gross production, not food eaten; no consumption or packing occurred in these fixtures.

Small milk lots below half a unit can instead expire entirely before becoming edible food. The isolated winter goat produced about 3,953 kcal over its remaining life, but none reached the integer food inventory. This compounds reduced biological output with an inventory threshold.

Corrective requirement: retain actual product energy and edible mass through meals, expiry, storage, discards and saves. Whole-number food units may remain a player-facing display, but display rounding must not create calories or make a small drink unavailable. Simply changing rounding to floor would lose more food. A permanent calorie credit must not survive expiry of the product that supplied it. Regression cases must include different herd groupings, sub-unit meals, product-specific spoilage, packing and genuine old saves.

### Feed and winter are conflated

Six hens without purchased grain all died on day 20 in otherwise favorable May conditions, regardless of hypothetical scraps or surroundings; those food sources do not exist in the module. Six hens with ample grain and full care still all died on day 50 in January/February. The cow and goat also died on day 50 despite resting and full care. Remaining egg products explain why the hen fixture continued recording after the last animal died.

Winter hardship is real, but month alone cannot describe feed intake, body reserves, shelter or water. The present death schedule is an authored rule, not an evidence-based estimate of time to starvation. Ruminants currently have no carried forage or supplement alternative; fully grain-fed hens cannot avoid the separate seasonal condition loss.

Corrective requirement: separate maintenance nutrition from surplus available for milk/eggs. Use finite, species-appropriate forage/scraps/feed resources and reduced production before severe condition loss. Winter can reduce forage and laying, raise maintenance demand and add exposure; it should not directly kill every animal after the same number of days irrespective of intake.

### Standing jobs can remove nonexistent labor

A cow plus goat needs 0.6 care-hours. In the travel fixture, four companions with standing Forage assignments reduce available care from full coverage to 83.3%, and milk from 8.50 to 7.08 lb. Those standing camp chores are not actually being performed on this moving day. The leader alone still covers one cow's 0.4-hour demand, so that smaller control correctly shows no difference.

Corrective requirement: use work actually performed that day, including real outings, nursing and rest restrictions. Do not charge a companion twice or reserve them for a chore that did not execute. The present minutes-per-animal and half-hour-per-person budgets are estimates, not measured period work records.

## Evidence and its limits

Sources checked October 25, 2026. Historical presence, modern physiology and authored game assumptions are different kinds of evidence.

- [USDA SR28 dairy and egg tables](https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR/SR28/reports/sr28fg01.pdf): whole cow milk about 61 kcal/100 g, goat milk 69, raw whole egg 143. These convert to approximately 277, 313 and 649 kcal/lb. Entries include NDB 01211, 01106 and 01123. A vitamin-D-added reference does not imply fortified milk in 1848. These values support energy density, not daily animal productivity.
- [End of the Oregon Trail: Outfitting for the Journey](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/): describes milk cows and wagon-mounted chicken coops, and milk/eggs supplementing preserved provisions. Its $70–75 milk-cow estimate is a broad period compilation, explicitly not a single town/date quote. It does not establish daily yields. Presence of cows and chickens is better supported here than a precise goat price or frequency of goats on the trail.
- [FAO, Small-scale Poultry Production, chapter 3](https://www.fao.org/4/y5169e/y5169e04.htm): scavenging includes household residues, insects, seeds and other local resources. Available food is finite and seasonal; poor resources may sustain birds without surplus for eggs. Its tropical village studies are evidence for mechanisms, not measured Oregon Trail camp supplies. Do not copy household waste weights or a modern village grain allowance directly into the wagon model.
- [FAO, chapter 10, table 10.1](https://www.fao.org/4/y5169e/y5169e0b.htm): illustrative traditional systems span 20–30 eggs/hen/year at low-input scavenging, 40–60 with initial improvements, and 160–180 at a later stage with improved breeds and complete diets. These are different production systems, not a range to average into an 1848 default. Eggs laid also differ from eggs available to people when birds brood and reproduce; the game currently has no breeding.
- [OSU Extension, How to Feed Your Laying Hens](https://extension.oregonstate.edu/catalog/pnw-477-how-feed-your-laying-hens): hens use seeds, insects and some greens; scraps and pasture can supplement food, but do not automatically form a complete laying ration. Plain scratch grain differs from balanced layer feed. Spring/summer offer more pasture feeding value than winter. This supports mixed feeding and nutrient limits, not unlimited free eggs or a precise trail scrap percentage.
- [Merck Veterinary Manual, Nutrition of Goats](https://www.merckvetmanual.com/management-and-nutrition/preventative-health-care-and-husbandry-of-goats/nutrition-of-goats): forage/browse should form the diet's foundation; lactation increases nutritional demands, and additional energy may be needed. Water and local forage quality matter. This supports browsing and conditional supplementation, not treating all terrain as equivalent or grain as a replacement for roughage.
- [Penn State, Dairy Goat Production](https://extension.psu.edu/dairy-goat-production): milk depends on genetics, diet and lactation stage; modern average lactation is about 284 days, with a peak after kidding. Its 2019 breed records are selected modern dairy evidence, not trail goat yields. Buying an already-lactating adult is a valid simplification, but 180 days remaining and the fixed taper must stay labeled as assumptions.
- [UC Agriculture and Natural Resources, Dairy Animals](https://ucanr.edu/site/small-acreage-landowners/dairy-animals): milking requires daily labor; feed and water demand increase during lactation, and inadequate forage can lower both condition and production. It distinguishes lactating and dry periods. Its modern intake figures depend on body size and productivity; they are not a mandatory ration for a small low-yield trail cow.
- [USDA NASS dairy history](https://data.nass.usda.gov/Publications/Trends_in_U.S._Agriculture/Livestock_and_Dairy/index.php): 4,572 lb/cow/year in 1944 illustrates how far modern production has changed. It does not prove an 1848 cow should produce 8 lb/day. Annual national averages include different lactation circumstances from a particular animal's daily output. Earlier butter/cheese totals cannot simply be read as total fluid milk yields.

No sufficiently matched source was found for precise 1848 trail yields. That uncertainty does not prevent calibration: use the accepted modern smallholding proxies below, label the assumptions, and compare similar husbandry rather than demanding unavailable historical precision. Farmer wins still do not justify raising yields. Slaughter recovery, goat/hen prices, milk loss during hard travel, storage windows and exact care times remain explicit estimates requiring narrower evidence or sensitivity analysis.

## Modern smallholding proxies accepted for calibration

Spencer approved this approach during the audit: use comparable modern non-industrial production instead of waiting for exact historical output records. Match animal type, size, diet, lactation stage, milking frequency and offspring share where possible. Non-commercial ownership alone does not guarantee old genetics or low-input feeding. Small-scale heritage keepers can provide useful observations even when they sell surplus milk or products; they are not automatically representative population averages.

| Reference | Observed or described yield | Implication for current base rate |
|---|---|---|
| [American Milking Devon Cattle Association, March 2017, pp. 2–3](https://www.milkingdevons.org/nl1701.pdf) | Keeper reports 0.5 to 2 or more gallons **per milking**, depending on lactation stage; describes adaptation to once-daily milking. | About 4–17+ lb per milking using roughly 8.6 lb per US gallon. The current 8 lb/day is within this example for a once-daily routine; the report is not a controlled pasture-only trial or a breed-wide average. Do not silently double its figures. |
| [Heritage goat keeper Erin Link, interview transcript at 7:19–8:00](https://thriftyhomesteader.com/rare-san-clemente-island-goats/) | Her San Clemente Island goats provide roughly 2–4 lb/day with two milkings, with substantial variation in adult size. | The current 2 lb/day is a plausible lower-end working proxy. This is direct keeper testimony, not a sampled national yield; it does not establish San Clemente goats as Oregon Trail stock. |
| [Rare Breeds Survival Trust, Dorking](https://www.rbst.org.uk/watchlist-breed/dorking/) and [Livestock Conservancy, Dorking](https://livestockconservancy.org/dorking-chicken/) | Around 150 eggs/year in the former; potential 170–190 in the latter, with broodiness and strain differences. The Conservancy documents distribution in America before 1840. | Current 0.5 egg/day has a 182.5-egg annual equivalent **before** season/care/travel modifiers. This is plausible as potential production, but is not the game's realized yearly output. Sources disagree enough to warrant a range, not false precision. |

These references support using the existing rates as starting allowances while repairing feeding/accounting. They do not establish the product of all current penalties as realistic. The Devon report is a small heritage dairy account and the goat keeper sells soap; these are useful smallholding analogues, not evidence that every non-commercial animal has unchanged productivity since 1848. Historical relevance of the Devon is additionally supported by the [Conservancy breed history](https://livestockconservancy.org/milking-devon-cattle/), which identifies Devon oxen on the Oregon Trail.

### Avoid another linear-capacity collapse

Spencer specifically wants to avoid the earlier walker problem: modest deterioration should not immediately make an animal unproductive. The present output multiplies condition/100, care fraction, season, a travel factor and sometimes a waterless factor; the same hardship can also reduce condition each day. This can count one underlying nutritional problem several times.

For the revision, keep a broad normal-condition operating range rather than an automatic proportional penalty for every lost point. Distinguish current intake/production surplus from stored body condition. Modest shortfalls should reduce surplus production before causing severe debility; sustained deficits can reduce reserves and eventually threaten survival. Healthy or fair animals should not become useless merely because several mildly adverse labels overlap. Real severe water shortage, starvation or illness can still be dangerous. Avoid unconditional minimum milk/egg production when nutrition cannot support it.

Use explicit severity bands or smooth thresholds, not an unexamined chain of linear percentages. Numerical breakpoints remain authored calibration choices. Acceptance tests should compare healthy/fair/poor animals under adequate and inadequate feeding, examine values immediately around each breakpoint, and verify no double penalty for the same feed deficit. Repeat travel/camp comparisons with actual available feeding time; a rest day with no food is not equivalent to recovery on good pasture.

## Implementation order and acceptance

1. Conserve milk/egg calories and mass through actual meals and spoilage, retaining simple displayed units and migrating genuine saves. This removes a measurable accounting artifact before any animal yield comparison.
2. Charge care against actual daily work. Keep patient/rest restrictions and real away-time intact.
3. Implement mixed hen nutrition: bounded meal residues from actual food preparation, finite scratching opportunities at camp, and purchased supplements. No food from uneaten supplies, no complete diet assumed from plain grain, no duplicate scraps per bird.
4. Separate cow grazing and goat browsing using route habitat, season and available feeding time; expose shortage and supplementation. Separate maintenance from lactation/egg surplus and exposure. Exact resource fractions remain tuning estimates until evidence supports them.
5. Repeat the controlled fixtures, then rerun matched farmer scenarios with frozen rules and fresh confirmation seeds. Record actual food eaten, feed use, caretaker work, condition and cash alongside arrivals. Do not tune production to a desired success percentage.

The [previous farmer study](FARMER_LIVESTOCK_BALANCE.md) remains the survival baseline, not a biological validation. No animal yields or starting funds were increased in this audit. The next change should address the accounting and feeding defects above before judging whether livestock is worth its cost.
