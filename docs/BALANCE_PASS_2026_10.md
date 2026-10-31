# Big balance pass, October 31, 2026

Spencer's rule: options need not be equally viable, but nothing may be bullshit (no free wins, no unfair or cheap failures). Tactical combat lethality is out of scope unless asked.

## Baseline (master at PR #139)

`tests/play_style_baseline.gd` plays whole journeys through public actions, one declared bot per play style, three professions, seeds 90000-90011 (12 per cell, 360 journeys, about 6 minutes on four cores). `tests/summarize_play_styles.py` turns the raw `.tools/play-style-<label>.json` files into these tables.

```
godot --headless --path . --script tests/play_style_baseline.gd -- --label=base-careful_apr --seeds=12 --styles=careful_apr
python3 tests/summarize_play_styles.py .tools/play-style-base-*.json --markdown
```

Styles: `careful_apr`/`careful_may` (steady, adaptive rations, rest, care, salt, buys produce), `fighter` (careful but always defends against bandits), `reckless` (grueling, meager, rests only below 25 health, fords, fights), `on_foot` and `horses` (fixed kits from the mount campaign), `petty` (one theft from a camp or trader), `criminal` (three thefts and three robberies at transient targets), `late_jun`/`late_jul` (careful). Fights here use the old quick odds; in play, fighting opens the tactical game.

| Style | Arrived | Median days | Survivors at arrival | Leader died | Custody | Other loss | Out of time | Deaths/journey | Starving days | Cash at arrival |
|---|---|---|---|---|---|---|---|---|---|---|
| careful_apr | 24/36 | 207.0 | 4.92 | 11 | 0 | 0 | 1 | 0.78 | 0.0 | 224.25 |
| careful_may | 20/36 | 251.5 | 4.8 | 15 | 0 | 0 | 1 | 1.06 | 0.0 | 179.65 |
| criminal | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| fighter | 26/36 | 207.0 | 4.88 | 10 | 0 | 0 | 0 | 0.67 | 0.0 | 250.56 |
| horses | 12/36 | 183.5 | 4.92 | 24 | 0 | 0 | 0 | 1.78 | 2.0 | 205.05 |
| late_jul | 20/36 | 293.0 | 4.85 | 14 | 0 | 0 | 2 | 1.08 | 0.0 | 290.08 |
| late_jun | 19/36 | 286 | 4.84 | 17 | 0 | 0 | 0 | 1.28 | 0.0 | 198.18 |
| on_foot | 0/36 | 0 | 0 | 31 | 0 | 0 | 5 | 2.92 | 62.5 | 0 |
| petty | 24/36 | 203.0 | 4.88 | 11 | 0 | 0 | 1 | 0.86 | 0.0 | 176.0 |
| reckless | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |

| Style | Arrived | Median days | Survivors at arrival | Leader died | Custody | Other loss | Out of time | Deaths/journey | Starving days | Cash at arrival |
|---|---|---|---|---|---|---|---|---|---|---|
| careful_apr / farmer | 2/12 | 227.5 | 5 | 9 | 0 | 0 | 1 | 1.92 | 1.5 | 7.52 |
| careful_apr / carpenter | 10/12 | 203.5 | 4.9 | 2 | 0 | 0 | 0 | 0.33 | 0.0 | 144.8 |
| careful_apr / banker | 12/12 | 203.5 | 4.92 | 0 | 0 | 0 | 0 | 0.08 | 0.0 | 598.58 |
| careful_may / farmer | 1/12 | 211 | 5 | 10 | 0 | 0 | 1 | 1.75 | 4.5 | 14.52 |
| careful_may / carpenter | 9/12 | 276 | 4.56 | 3 | 0 | 0 | 0 | 0.92 | 0.0 | 14.8 |
| careful_may / banker | 10/12 | 251.5 | 5 | 2 | 0 | 0 | 0 | 0.5 | 0.0 | 489.13 |
| criminal / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| criminal / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| criminal / banker | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| fighter / farmer | 3/12 | 196 | 5 | 9 | 0 | 0 | 0 | 1.5 | 0.5 | 14.55 |
| fighter / carpenter | 11/12 | 207 | 4.91 | 1 | 0 | 0 | 0 | 0.33 | 0.0 | 183.4 |
| fighter / banker | 12/12 | 209.0 | 4.83 | 0 | 0 | 0 | 0 | 0.17 | 0.0 | 644.8 |
| horses / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.17 | 13.0 | 0 |
| horses / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 3.08 | 7.5 | 0 |
| horses / banker | 12/12 | 183.5 | 4.92 | 0 | 0 | 0 | 0 | 0.08 | 0.0 | 205.05 |
| late_jul / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.5 | 2.0 | 0 |
| late_jul / carpenter | 9/12 | 296 | 4.67 | 1 | 0 | 0 | 2 | 0.5 | 0.0 | 18.55 |
| late_jul / banker | 11/12 | 292 | 5 | 1 | 0 | 0 | 0 | 0.25 | 0.0 | 435.85 |
| late_jun / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.33 | 2.5 | 0 |
| late_jun / carpenter | 9/12 | 310 | 4.67 | 3 | 0 | 0 | 0 | 1.0 | 0.0 | 20.07 |
| late_jun / banker | 10/12 | 283.5 | 5 | 2 | 0 | 0 | 0 | 0.5 | 0.0 | 439.11 |
| on_foot / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.92 | 50.0 | 0 |
| on_foot / carpenter | 0/12 | 0 | 0 | 11 | 0 | 0 | 1 | 3.17 | 72.0 | 0 |
| on_foot / banker | 0/12 | 0 | 0 | 8 | 0 | 0 | 4 | 2.67 | 67.0 | 0 |
| petty / farmer | 3/12 | 237 | 5 | 8 | 0 | 0 | 1 | 2.0 | 3.0 | 14.67 |
| petty / carpenter | 10/12 | 202.5 | 4.8 | 2 | 0 | 0 | 0 | 0.42 | 0.0 | 126.71 |
| petty / banker | 11/12 | 203 | 4.91 | 1 | 0 | 0 | 0 | 0.17 | 0.0 | 606.35 |
| reckless / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |
| reckless / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |
| reckless / banker | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |

Findings (full write-up shared with Spencer as a Claude Doc):

- Money decides arrival: lawful wagon styles arrive farmer 6/60, carpenter 48/60, banker 55/60. Farmers keep $216 after the suggested outfit and bottom out near $10.
- Scurvy is the top killer (51 of 175 lawful deaths), then dysentery 27, pneumonia 20, smallpox 20.
- 67 of 71 lawful losses are leader deaths, clustered at miles 1,350-1,913.
- Departure month barely matters: July 20/36 against April 24/36; late parties cross the western mountains in winter and just move slower.
- Careful April journeys take a median 207 days; May parties arrive in December or January.
- Criminal journeys all fail, mostly to scurvy, because identified news closes every store for good. A single theft changes nothing.
- Grueling pace is never usable (bare + grueling is -7 health a day).
- Walking: 0/36, mostly lack of food.

Proposed tuning order: scurvy and disease mix; farmer money; winter danger for late starts (needs Spencer); crime refusals (needs Spencer); pace and rations; no change to fights.

## Step 1: scurvy (October 31)

Why scurvy was the top killer, checked against the code and against modern and historical numbers:

- **Dried fruit did nothing.** Meals served the full shared vitamin portion every day, so a party's dried fruit was eaten in its first week while reserves were still full. Preserved fruit is now opened only as far as today's vitamin debt can use it (a full portion when someone has scurvy). Fresh produce, which spoils in days, is served as before.
- **Fresh meat counted for nothing.** Raw muscle meat holds a few mg of vitamin C per 100 g and organs more; about 10 mg a day kept scurvy away in the Sheffield experiment. Freshly killed meat and fish now give 0.03 produce-pound equivalents per cooked pound (`provisions.foraging.fresh_meat_vitamin_ratio`, about 5 mg/lb against an 80 mg half-pound portion). Salted, dried and staple food give none. Milk is still counted as none.
- **It killed far too fast and almost never healed.** A serious case did 6 damage a day; only 8 of 218 cases ever recovered. Historically scurvy disabled for weeks and killed over months (Fort Stevenson, winter 1867-68: 79 cases, 2 deaths). Scurvy now wears a traveler down to 25 health (`scurvy.health_floor`), then drains one point every four days without vitamin C (`floor_drain_days`), so it can still kill, over months. Treatment is unchanged: bleeding damage stops with vitamin C and the case clears after 14 adequate days.
- Onset (45 days of reserve, then a rising daily chance) matches the 1-3 months to first signs in depletion studies and was not changed.

Before and after, same seeds (90000-90011):

| | Lawful arrivals (180) | Farmer | Carpenter | Banker | Scurvy cases | Scurvy deaths (all 360) |
|---|---|---|---|---|---|---|
| Baseline | 109 | 6/60 | 48/60 | 55/60 | not counted | 113 |
| Floor only | 115 | 9/60 | 50/60 | 56/60 | 443 | 0 |
| Floor, slow drain, fresh meat, dried-fruit fix | 129 | 20/60 | 51/60 | 58/60 | 122 | 9 |

| Style | Arrived | Median days | Survivors at arrival | Leader died | Custody | Other loss | Out of time | Deaths/journey | Starving days | Cash at arrival |
|---|---|---|---|---|---|---|---|---|---|---|
| careful_apr | 26/36 | 211.0 | 4.92 | 8 | 0 | 0 | 2 | 0.69 | 0.0 | 194.55 |
| careful_may | 26/36 | 236.5 | 4.65 | 9 | 0 | 0 | 1 | 0.81 | 0.0 | 145.28 |
| criminal | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 1.75 | 0.0 | 0 |
| fighter | 29/36 | 211 | 4.79 | 4 | 0 | 0 | 3 | 0.64 | 0.0 | 221.95 |
| horses | 14/36 | 185.5 | 4.64 | 22 | 0 | 0 | 0 | 1.86 | 5.0 | 221.28 |
| late_jul | 21/36 | 287 | 4.67 | 13 | 0 | 0 | 2 | 0.94 | 0.0 | 93.37 |
| late_jun | 27/36 | 292 | 4.81 | 9 | 0 | 0 | 0 | 0.72 | 0.0 | 59.33 |
| on_foot | 0/36 | 0 | 0 | 28 | 0 | 0 | 8 | 2.39 | 57.5 | 0 |
| petty | 23/36 | 212 | 4.83 | 10 | 0 | 0 | 3 | 0.75 | 0.0 | 157.77 |
| reckless | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |

Every remaining scurvy case starts past mile 1,200 (Snake River onward) at a median of day 211. Careful April parties spend about 137 days moving, 30 resting and 45 on stops and events, so they reach the dry far west in autumn. Journey length is the next question for Spencer. Late starts now do even better (June 27/36), which sharpens the "leaving late costs nothing" finding.

## Step 2: winter (October 31)

Spencer: a careful party taking long is the point, time against risk is the core trade-off, so journeys stay long and lateness gets dangerous instead. He picked all three rules below, asked that a dead animal can be butchered rather than wasted, and that valleys below a pass be "safer, not safe".

Rules (data/route.json, all labelled authored, not reconstructed 1848 weather):

- **Barlow Road closed to wagons November to April** (`wagon_closed_months`). The Dalles labels the road "snowbound to wagons November to April"; the Columbia raft and resting stay open, and walkers may still go around. Barlow's own 1845 party was caught by snow and cached wagons at Fort Deposit; a military train left 45 wagons on the road in 1849.
- **Snow country** (`snow_country`) at South Pass and the Blue Mountains (November to March) and the Barlow Road (November to April). On the leg into, or at, the pass: 40% (Barlow 50%) of travel days are snowbound (a day passes, no miles), and animals lose 4 condition a day even in camp; at 0 condition each day has a 15% chance an ox, mule or horse dies. A starved animal offers its carcass: butcher it (1 day, the worn-out minimum yield: 200 lb from an ox, no bullet) or leave it.
- **Sheltered valleys:** camped at the landmark below a pass, before starting the climb (for example Grande Ronde below the Blue Mountains), there are no snowbound days, but animals still lose 2 a day (`valley_strain`), about what winter rest recovers, so they hold rather than heal.
- **Warnings:** in September and October the season notice names the high country still ahead ("snow closes the high country from November"); in season it says "Winter in snow country near X" or "Winter below X: the valley is sheltered but grass is poor".

The baseline bot now pushes on in snow country instead of resting for its team or fatigue (resting there cannot recover them). The first version, without that and with no valley shelter, was a trap rather than a danger: late June arrivals fell to 2 of 36 as parties sat for months on the climb.

Same 360 journeys (seeds 90000-90011), before = step 1 rules:

| Style | Before | After |
|---|---|---|
| Careful April | 26 | 28 |
| Careful May | 26 | 24 |
| Late June | 27 | 21 |
| Late July | 21 | 17 |
| Fighter | 29 | 29 |
| Horses | 14 | 11 |
| Petty thief | 23 | 23 |

Lawful arrivals 129 → 119 of 180. Late parties: bankers still arrive (24 of 24), carpenters 17 → 13, farmers 8 → 1 of 24. Money buys a way through winter; a poor late party mostly does not. Tried and rejected: 45%/5 a day (late July 12 of 36, too harsh) and 30%/3 a day (late July 17 with no valley strain, too soft once the bot pushed on).

Follow-ups (Spencer's ideas, not built): a winter cabin buildable anywhere if the party spends the days, with camp life rather than dead time, and possibly a "settled short of Oregon" ending.

## Step 3: professions as skills (October 31)

Farmers failed because the wagon is already full at Independence (2,500 lb cargo, 2,000 lb food cap), so every profession leaves with the same food; cash decides whether a party can restock at posts once that food runs low around day 150. Spencer did not want farmers made richer just to make the game easier: professions should give the leader abilities, like companion backgrounds, not extra gear.

`simulation/profession_skill.gd` reads `profession_skills` in `data/party_benefits.json`. Every skill needs a fit leader (at least `minimum_health`, no serious condition). The leader then counts as a specialist in the matching companion background (`camp_tasks.specialist(game,0,...)` and `characters.available`).

| Profession | Purse | Skill |
|---|---|---|
| Banker | $1,475 | none: the purse is the edge (Spencer) |
| Merchant | $1,250 | Trading: 5% off cash purchases |
| Doctor | $1,100 | Caregiving: better care |
| Carpenter | $975 | Carpentry: faster and wooden repairs, carpentry work |
| Saddler | $750 | Leatherworking: buckskin, leather goods, harness work |
| Hunter | $700 | Hunting: faster reloads, hunter's aim (+4%) in tactical fights |
| Farmer | $675 | Stockman: team strain -1 on hard days, +1 recovery on rest days with grass, half again as much foraging, butchering +25% meat and no hand injury, milk and eggs +25% |
| Soldier | $650 | Soldiering: counts as a Veteran, soldier's aim (+8%), thieves avoid a soldier's watch |
| Outlaw | $600 | Outlawry: one prior job of crime experience (still capped) |

Soldiering and Outlawry are also new companion backgrounds (party editor); generated parties and recruits still deal the original five (`DEALT_SKILLS`) so existing seeds keep their companions. Hunting companions and Sharpshooters also get the hunter's aim. Spencer raised the hunter, soldier and outlaw purses from $600/$550/$450, where the money gap swamped any skill.

Lawful arrivals of 60 (careful April/May, fighter, late June/July; same seeds):

| Profession | Arrived |
|---|---|
| Banker | 59 |
| Merchant | 56 |
| Doctor | 51 |
| Carpenter | 48 |
| Saddler | 27 |
| Farmer | 20 (13 before Stockman) |
| Hunter | 13 |
| Soldier | 12 |
| Outlaw | 7 (its skill pays only in crime) |
