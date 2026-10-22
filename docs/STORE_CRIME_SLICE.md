# First store encounter: implemented checkpoint

October 22, 2026. This implements part of roadmap phases 1–2. The complete crime/cannibalism roadmap remains `CRIME_AND_CANNIBALISM_ROADMAP.md`.

At an actual Fort Bridger landmark stop, open **Options → Actions at the Store**. This is a fictional keeper and authored local-staff encounter at the existing private trading establishment; it is not a reconstruction of a named person or an army fort. Other venues are not enabled yet.

## Playable actions

- Take supplies without paying. The attempt can go unnoticed or be noticed.
- Threaten the keeper with a gun. An available bullet is required; a threat does not spend it. The keeper can comply or resist.
- Shoot at the keeper. One bullet is spent; the shot can miss, wound or kill. A wounded keeper retains the wound; a dead keeper stays dead.
- Search the remaining store after the keeper's death. Reopening does not revive the keeper or replenish stock.
- Take reachable food and, after a successful armed action/search, the remaining cash stash; leave without collecting it; attempt escape; or surrender when confronted.

The first pass uses choices and seeded resolution, without a shooting minigame. The active party is explicitly present at this scene. Their observations and forbidden-action reactions apply even to unsuccessful attempts. The narrator reports outcomes; individual characters express objections. Current reaction severity still uses the existing bounded trust framework; the roadmap's stronger companion violence/bond consequences are later work.

An attempt costs one ordinary day; collecting loot costs another. Alerted escape costs a day and can cause a personal injury, a wound condition or capture. Surrender/capture ends this journey in custody, preserving living people as living. No false gravestone prompt is offered for an entirely living captured party. Closing the encounter panel does not resolve the incident or unlock normal travel; decisions remain available on the main event panel.

## State and conservation

`simulation/crime_system.gd` owns a dedicated RNG, immutable original-party identity keys, the keeper's persistent identity/state, incidents, per-observer facts, an active incident pointer and food/cash transfers. It does not execute UI code. Scene probabilities and initial stash quantities are authored tuning in `data/crime_scenes.json`.

Keeper food starts from the existing eight 200-lb post lots. Theft/looting and legitimate purchases/barter share the physical source. New transactions account for actual food quantities, including a 40-lb barter. The legacy offer/demand quotas remain separate constraints. For older saves that recorded only offer counts, migration conservatively retains their previously counted bulk depletion. Selling goods does not replenish the loot source. The $50 cash stash is a separate fixed cache, not a complete shop accounting model or a historical cash holding.

Each collection is capped at 200 lb and available physical cargo space. Cash and food are transferred once, before that collection day's ordinary meals and hazards. A local alarm closes legitimate trade with this keeper/staff. Passing traders elsewhere remain separate people. Loot provenance currently means incident transfer totals; individual stolen-item ownership chains and later resale recognition are not implemented.

## People, ownership and witnesses (record version 2)

Each scene lists its staff in `data/crime_scenes.json`. The first entry, `keeper`, owns the service; Bridger currently has the keeper and one hired hand, both authored roles rather than named historical people. Every staff member is a separate persistent actor (`keeper:fort_bridger`, `hand:fort_bridger`) with their own health. The service record (`services.fort_bridger`) holds the owner, staff list, cash stash, food sold/taken and the local alarm. Killing the keeper closes the store and opens the search action, but the hired hand stays alive and keeps what they saw.

Knowledge is per person. An unseen theft gives no local person any knowledge. A noticed attempt is seen by every staff member alive after it resolves; a keeper killed by the shot learns nothing. Validation enforces both directions, so a living witness cannot be edited out of a save and nobody can be added from another place. A dead person's earlier knowledge stays on record; later reporting must check whether its holder is alive. `local_witnesses()` lists the local people who know anything about an incident, which is the input phase 6 reporting needs.

Version 1 records (one keeper entry per place plus an aggregate `staff:<place>` observer) are upgraded on load: the keeper's stock, cash and alarm move to the service, and the aggregate observer's facts go to each staff member still alive. The genuine fixture `tests/fixtures/pre-witness-save-v1.json` is an active escape stage after a resisted robbery. Crime rolls and menu texts are unchanged, so the same seed and actions still give the same outcomes.

The rules fingerprint now ignores carriage returns. Windows Git checkouts converted the JSON rules to CRLF, which gave the same rules a different fingerprint on each platform; `.gitattributes` now keeps text files LF. Both fingerprints of the previous rules (`c64ed4…` from the Windows copy, `2805dd…` from an LF checkout) are accepted as compatible earlier saves.

## Identities

Original-party IDs use seed plus original slot; this is a safe namespace for the existing fixed five identities. Future recruitment still needs a slot-to-person mapping and identity allocation before replacing anyone. NPC actors have separate IDs. This checkpoint does not yet create a general corpse ledger or automatically convert deaths to food.

## Save and replay

The save contains the crime record and RNG state. The rules signature includes crime scene data. The real pre-crime fixture is migrated without inventing incidents, deaths or loot. Existing party names, health, traits, contracts, cash, inventory, pending offers and ordinary RNG state remain intact.

Validation checks identity keys, actor bounds, chronological incident IDs, legal action/outcome/stage combinations, observed facts, stock/cash conservation, active-stage consistency and incident-linked companion memories. Saved crime menus must exactly match the authoritative regenerated menu. A saved command cannot turn an escape screen into an extra loot action. Ordinary activity memories retain their earlier daily deduplication; incident reactions additionally use incident IDs.

## Verification

The dedicated store suite has **1,021 passing checks**: ninety seeded action attempts, outcome coverage, ammunition, real days/meals, full-cargo limits, attempt reactions, deterministic stage/escape replay, closed services, finite shared stock, exact barter depletion, authentic save migration, malformed/injected saves and native UI interactions. The menu screenshot was rendered and inspected.

The complete final regression suite passed in the canonical Projects repository after the exact-barter accounting and validation refinements. The Claude handoff records the delivered checkpoint.

`first-store-journeys.json` records **24 actual route journeys**, four strategies × six seeds. All 24 arrived with no deaths, departures, selected state/save errors or policy loops in this small banker-funded sample. One robbery/theft/shooting attempt was made upon reaching Fort Bridger, then the ordinary survival policy resumed. This is an integration sample, not evidence that crime is balanced. Targeted tests separately exercise resistance, wounds, death and forced capture. The sampler was corrected to distinguish a closed-store Back action from a purchase and to flag journey limits as errors.

## Remaining work

Finish and review the foundation before expanding it: precise participation/refusal and stronger witnessed violence responses; broader identity/ownership records; physical bodies and provenance. No distant enforcement, pursuit after departure, news carried by passing traders, guard combat, escape shooting, companion attacks, companion-to-companion bonds, emergency flight, toll/ferry crime, cannibalism, replacement recruitment or final survival balance has shipped.

## Situational odds

Scene values in `data/crime_scenes.json` are the odds for a healthy, inexperienced party with willing help against the full staff. `crime_system.odds()` adjusts them without using any randomness, from the shared `modifiers` block:

- **Experience:** each distinct target the party got away from (`left` or `escaped` after an unseen theft, compliance, wound, kill or search) plus each clean defensive victory counts once, capped at 3. Each point adds 4 percentage points. A noticed theft, resisted threat or missed shot does not count, and the same keeper never counts twice.
- **Condition:** below the existing combat thresholds (poor < 40, fair < 70 average health) the party loses 15 or 7 points.
- **Participants:** if fewer than two people are fit (health of at least the poor threshold) and willing for that act, the party loses 8 points. Willingness uses each companion's own boundaries, so murder and robbery can differ.
- **Staff:** every listed staff member already dead adds 8 points against resistance, and also makes an unnoticed theft more likely.

The resulting edge raises compliance and hit chance and lowers capture and escape-injury chances. Whether a theft is noticed depends mainly on who is there to notice; experience adds a smaller bonus (2 points per counted job, at most 6), and party condition never affects it. Modifiers cannot push any chance past 5% or 95%, so a capped veteran can still be caught. The store menu lists the factors (staff on hand, party condition, willing participants, jobs counted). All numbers are authored tuning for the balance campaign, not historical rates.

Saved crime menus now restore by checking their commands against the authoritative stage and regenerating the text, so descriptive text can change between versions without breaking saves.

## Witness reports (record version 3)

When an incident ends with the party leaving or escaping, its living local witnesses send one report (`record.reports`): the incident, origin, day, the senders in staff order, the union of their facts, and whether the party was **identified**. Face-to-face acts (threat, shot, search) identify the party. A noticed theft gives only a description. An unseen theft, or one whose only witness is dead, sends nothing.

News travels along the road with other parties and traders in both directions. It reaches a stop `delay_days` (2) after the report, plus one day per `miles_per_day` (25) guide miles from the origin, rounded up. Both values are authored tuning in `data/crime_scenes.json`, not measured rates. A party that moves faster than the news can still trade before it arrives.

At a trading post that has heard an identifying report, the post refuses to trade and refuses paid care, and its menu says what it heard and when. The party's own kits still work. A description-only report leaves the post open but adds a line saying people are wary of a party matching the description. Passing traders do not carry news yet.

Validation derives the expected reports from the incidents, so a report cannot be deleted, downgraded to a description, given other facts, or dated before its incident. Version 2 saves gain reports for their resolved, witnessed escapes, dated to the incident day (the resolution day was not stored). The genuine fixture `tests/fixtures/pre-report-save-v1.json` covers this.

### First journey sample with reports

`store-reports-journeys.json` reruns the 24-journey store sample with reports on. No-crime and theft journeys all arrive. 4 of 6 robbery journeys and all 6 shooting journeys run out of time before Oregon City: news reaches Fort Hall and Fort Boise before the party, both refuse resupply, and the parties limp on with too little food and too few oxen. The sampler now treats "out of time while still making progress" as an outcome and only flags a journey that stalls for 60 days as a policy loop. This is an integration sample, not balance evidence, but it already shows the news speed and refusal rules are strong enough to matter. The balance campaign should tune them together with loot size.

## More venues: every post, the toll gate and the ferry

Each scene in `data/crime_scenes.json` now has a `kind`: `store`, `toll` or `ferry`. All four trading posts on the route are stores: Fort John / Laramie (keeper, clerk and hired hand, so it is harder to rob), Fort Bridger, Fort Hall and Fort Boise (keeper and hired hand). Two route stops that already charge for passage are the new kinds. Both use the incident, witness and report machinery unchanged, and every role is authored, not a named historical person.

- **Barlow Road toll gate** (`barlow_pass`, one gatekeeper, $40 cash box, no food). Theft means slipping the wagons past the gate. Getting away after reaching the loot stage (an unseen pass, a complied threat, a killed gatekeeper or a search) waives the toll: the stop's continue choice costs nothing. A noticed attempt or resisted threat that runs off still owes the toll. A dead gatekeeper collects nothing.
- **Kansas River ferry** (`kansas_river`, ferryman and ferry hand, $15 cash box, no food). Theft means casting off with the ferry while the crew is away. Taking the ferry and getting away adds a "Cross on the taken ferry" choice with an authored mishap risk (12% low water, 30% high water, still scaled by the existing crossing factor). The hired ferry is no longer offered once the party has taken it, attacked the crew, or the crew has heard identifying news. A failed robbery leaves only fording and floating.

Passage is derived from the incidents (a `left` or `escaped` incident at that place that reached the loot stage and where the party took the prize), so the save record shape and version do not change. Stop choices are refreshed after each encounter. The taken ferry is appended to the end of the stop's choices, so earlier choice indices never shift. Reports name the venue ("robbed the ferry at Kansas River").

Saves made before these venues existed gain their people and services untouched when loaded; food bought at a post before then is counted conservatively, as `bind_party` already does. A record with only part of a venue is rejected rather than repaired. The genuine fixture `tests/fixtures/pre-venues-save-v1.json` is a reported Fort Bridger robbery saved under the previous rules.

## Fort Kearny: soldiers and the standoff

Fort Kearny is a `fort` scene: the commissary tent at the new army post, the only army post on the 1848 road. Before June 1848 the site has no garrison (`construction_from_month` in the route), so there is nobody to rob. The staff are a commissary sergeant (the target) and three soldiers on duty nearby (sentry, corporal of the guard, private). All are authored roles, not named people or a specific unit.

The commissary holds its own stock (`food_stock` 400 lb, up to 150 lb taken at once) plus a $25 cash box. Odds are much worse than at a store: theft goes unnoticed 30% of the time, a threat works 20% of the time, and soldiers stop 45% of escapes.

When soldiers stop an escape, the party is not simply captured. The incident enters a **standoff** stage, and the party must surrender or shoot its way out:

- Shooting out spends up to `breakout_shots` (3) bullets and a day. Each shot can drop a soldier. A soldier killed here stays dead and carries no knowledge onward, so killing witnesses can shrink a report but never cancel one from survivors.
- Soldiers fire back either way, wounding one or two of the party.
- The breakout succeeds at `breakout` (35%) plus the party's edge, within the usual 5–95% bounds. Failure ends the journey in custody.
- Without bullets, the only way out is surrender.

A store's staff still simply catch the party; only soldiers force a standoff. Saves validate the stage (forts only) and the extra shots (no more than the scene allows).

## Passing traders

The small trading parties already met on the road (the `passing:<region>:<window>` markets in `trail_context.gd`) can now be targeted too. The ROB, STEAL OR ATTACK HERE action aims at the venue at a stop when there is one, otherwise at traders available on the road.

- `passing_traders` in `data/crime_scenes.json` is a template: a lead trader, a packer and an armed hand, $30 cash, and food matching their three 50 lb trade lots (food already bought from them is gone). Each party is identified by its market key and enters the record (`actors` plus a service with the `mile` where it was met) only on the first committed act, so looking at the menu changes nothing.
- Robbed or alarmed traders refuse to trade, and other trading parties are unaffected. Reports from traders travel from the mile where they were met, and posts hear that "your party robbed a trading party on the road through the Platte grasslands".
- Validation accepts a trader service only if an incident targeted it, and its mile cannot lie beyond the party's own.

Traders do not yet carry news of other crimes; that belongs to the pursuit and news phase.

## Emigrant camps

Other emigrant families now camp near the road. `passing_emigrants` is a second template, like the traders. About one camp a week is near (`every_days` 7, present for `window_days` 2, offset per journey). Each camp is named `emigrants:<region>:<n>` and enters the record on the first committed act.

- Each family has four people: the head of the family (the target), a partner, a grown son and a hired man. They carry $60 and 300 lb of food, of which up to 200 lb can be taken.
- They are armed and travel in company. Threats work 30% of the time, and a getaway injures someone 40% of the time. Nobody can hold the party long, so only 6% of escapes are stopped.
- The crime action aims at the stop's venue first, then traders on the road, then a nearby camp.
- Reports and news work as for traders: "your party shot at an emigrant family on the road through the …".

So far a camp exists only as a crime target. Meeting one peacefully (trading, swapping news, helping) is not built yet.

## Companion bonds and attacks (record version 4)

**Bonds.** Each new journey draws sparse bonds between companions once, from its own random stream (so crime odds are unchanged). Per pair: family 10%, partner 6%, friend 18%, rival 10%, and nobody has two partners. Bonds are shown in View Party. Older saves upgrade with no bonds, because existing travelers are never given invented family. The leader's relationship to each companion is still the existing `relationship` field.

**Attacking a companion.** View Party has a SHOOT button for any companion with the party. The menu is pure and shows:

- the target;
- who joins: the leader plus companions willing to kill who are not family, partner or friend of the target;
- who refuses;
- the bonds involved;
- the chance to hit: 70% plus 5% per helper, within the usual bounds.

Committing spends one bullet and no day. A hit kills if the target is already weak, or half the time otherwise. Any other hit wounds for 40 and starts a wound condition. The cause of death names the killer.

**Immediate responses.** Every companion with the wagon sees the attack:

| Who | Response |
| --- | --- |
| The target, if alive, or anyone close to them (family, partner, friend) | Fights back if Bold or Reckless and fit; otherwise flees at once. A fighter hits the leader half the time for 30, then leaves too. |
| A rival of the target | Stands by and loses no trust. |
| Anyone who forbids murder | Flees at once if they saw a killing; objects and stays (with the usual trust loss) after a miss or a wound. |
| Everyone else | Stands by. |

Flight reuses the departure transfer: each person takes an equal share of a few days' food, a clothing set and personal gear. It happens anywhere on the road, not just at settlements, and is marked `fled` on the member.

Each attack records its result, helpers and every response. Memories carry the attack's id, so a second attack the same day is its own memory and replaying a menu charges nothing.

**Save validation.** A killing must match a dead target on that day. Anyone who fled or fought back must have left. A fled member must have an attack that caused it. Bonds must be distinct pairs with at most one partner each.

Not yet: an attack started by a companion, betrayal at low trust, or companions revealing what they know after leaving (the news phase).

## Other limits

Personal existing health specials still affect any actual injury damage. Paid trade, paid care and the hired ferry respond to incidents and news; other services are not yet governed by a general hostility/access system.

Reproduce using project-local APPDATA as in `test.ps1`: run `tests/test_crime.gd` for targeted checks or `tests/store_crime_journeys.gd` for the 24-route sample. Both use the actual engine. Keep previous balance reports archived.

