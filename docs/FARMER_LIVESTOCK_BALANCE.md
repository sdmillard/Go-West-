# Farmer livestock balance comparison

October 25, 2026. Livestock supplies real food, but this study does not establish a reliable improvement in farmer completion. **No game rules were changed.** All simulation/data files match shipped livestock gameplay f685292. Study/observer snapshot affaad9 ran 432 journeys with zero state, save or policy errors; 78 Godot suites passed, including 120 observer/parity checks.

## Completion results

Each cell below contains 24 scenarios per phase: six underlying seeds repeated across May/July and standard/lean outfits. The confirmation seeds were fresh and declared in advance; neither game rules nor decisions were tuned between phases. Counts are paired scenarios, not 24 independent seeds.

| Starting animals | Decisions | Development arrivals | Confirmation arrivals |
|---|---|---:|---:|
| None | Existing mobile strategy | 2/24 | 1/24 |
| Two goats | Existing | 1/24 | 1/24 |
| Two goats | Care/feed/emergency-aware | 0/24 | 4/24 |
| One cow | Existing | 0/24 | 0/24 |
| One cow | Care/feed/emergency-aware | 0/24 | 0/24 |
| Six hens + grain | Existing | 1/24 | 0/24 |
| Six hens + grain | Care/feed/emergency-aware | 1/24 | 0/24 |
| Mixed herd | Existing | 0/24 | 1/24 |
| Mixed herd | Care/feed/emergency-aware | 1/24 | 0/24 |

The four confirmation goat arrivals all came from the six May/standard-outfit scenarios, versus one baseline arrival in that cell. Across the full confirmation matrix, goats retained the one baseline win and added three. But development had zero goat-aware arrivals against two baseline wins. This is a promising scenario-specific signal, not a replicated general benefit. No arm brought all five original travelers physically to Oregon in the confirmation set.

Arrival times are compared only when both paired journeys arrive. The goat-aware confirmation comparison has just one such pair (14 days quicker); there is too little paired completion evidence for a general speed claim. Earlier deaths are not faster trips.

## Food benefits and costs

Confirmation averages for the animal-aware strategy:

| Animals | Milk/egg food units actually eaten | Gross emergency-meat units added | Initial cash spent on animals/feed |
|---|---:|---:|---:|
| Two goats | 121.42 | 18.38 | $20 |
| One cow | 198.62 | 185.46 | $75 |
| Six hens | 6.54 | 0 | $5 |
| Mixed herd | 233.67 | 167.62 | $90 |

Milk/egg consumption is measured from actual provision batches, not inferred from pounds generated. Emergency meat is gross food added at butchery; it is not all necessarily eaten. Main-party requested food averaged roughly 2,500-2,700 units per confirmation journey. The supplemental food helps, while upfront purchases reduce money available for later supplies. Standard and lean outfits keep the farmer's original $675 budget; animals, coops and grain also have their actual weight. No free money was added.

Care management works within the existing mechanics. Mixed-herd days with insufficient available labor fell from 83.04% under existing assignments to 0.57% with reserved caretakers in confirmation. Actual milk/egg food eaten rose from 169.08 to 233.67 units, but there were no mixed-aware arrivals. Reserving companions also competes with hunting, foraging and other work; the aware policy bundles several decisions, so this does not isolate a single causal effect.

Hens expose a provisioning weakness in this outfit/strategy. Six birds use 1.5 lb grain daily, so the starting 50 lb lasts about 33 days. The aware flock arms made no grain purchases in this matrix. In one inspected confirmation May/standard run, grain was gone by the day-35 sample, Kearny purchases occurred on day 41, and Laramie purchases on day 62. Kearny is not a bulk post in current route data; grain is offered at bulk posts. Most hens subsequently died of poor condition: about 5.88 per confirmation flock run, with roughly 0.12 lost at crossings. A longer initial feed provision, different selling/culling decisions or a researched poultry-foraging mechanic remains untested here.

## Remaining pressure points

Food shortages and vitamin-C coverage still dominate failures. In the confirmation baseline, 48 recorded deaths were attributed to lack of food and 24 to scurvy. Food shortages preceded the first recorded main-party death in 21 of 24 baseline scenarios. Baseline median first shortage was day 145.5; milk and eggs do not supply the game's fruit/greens requirement. These are observed sequences and proximate causes, not a proof that one parameter caused each death.

The baseline median was 92 stationary days and 97 days with distance progress, with 27.5 rest days. Stationary time also includes hunting, foraging, crossings, trading and events; it is not all cautious recovery. More food alone does not remove these costs or the consequences of late seasonal travel.

The decision policy is another important limit. It raises the whole party to Filling rations whenever any active traveler is below 80 health or ill. Ordinary shopping retains $20; emergencies retain $10 while a future toll is ahead. It does not sell milk animals to finance food, optimize starting outfits, or search farmer-specific ration schedules. A human willing to spend reserves, sell stock or accept different risks can behave differently. These trials are controlled comparisons, not an optimal-player win-rate estimate or proof farmer journeys are impossible.

Next useful comparisons are farmer-specific ration/cash decisions and fresh-produce coverage, alongside realistic poultry feed logistics. Keep the present results intact before testing a revised policy or changing game numbers. Prices/yields should not be increased solely to make these particular seeds win.

## Reproduction and provenance

See [declared protocol](FARMER_LIVESTOCK_BALANCE_PROTOCOL.md), [complete compact results](farmer-livestock-balance-summary-01.json), tests/livestock_balance_campaign.gd and tests/summarize_livestock_balance.py. Development seeds 311000-311005; confirmation 321000-321005. Each phase has 216 journeys, nine arm/decision cells, two outfits and two departure months. All use steady pace, 65% hunting reactions, a shared riding horse, mobile outriders, parallel camp jobs and shared-stop fishing.

Full reports remain in parent ignored .tools/hunting-farmer-stock-*-01.json. All 36 copies were SHA-256 checked against isolated originals before cleanup; the summary records their hashes and actual source/rules fingerprints. Baseline carts, matched arm additions, original budgets, complete cells, sources and settings were checked. The summarizer verifies isolated originals during publication; retain raw parent reports for later inspection. Earlier smoke seed 310901 is excluded. The final full-suite log is .tools/farmer-stock-final-tests.log.
