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

**News reaches traders too.** A passing trading party hears news with the same delays as a post, measured from where the party meets it. Once word naming the party has arrived, they refuse every trade ("The traders will not deal with you"). Traders the party robbed refuse outright. Travelers camped at any stop repeat what has reached that stop when the party talks with them.

## Emigrant camps

Other emigrant families now camp near the road. `passing_emigrants` is a second template, like the traders. About one camp a week is near (`every_days` 7, present for `window_days` 2, offset per journey). Each camp is named `emigrants:<region>:<n>` and enters the record on the first committed act.

- Each family has four people: the head of the family (the target), a partner, a grown son and a hired man. They carry $60 and 300 lb of food, of which up to 200 lb can be taken.
- They are armed and travel in company. Threats work 30% of the time, and a getaway injures someone 40% of the time. Nobody can hold the party long, so only 6% of escapes are stopped.
- The crime action aims at the stop's venue first, then traders on the road, then a nearby camp.
- Reports and news work as for traders: "your party shot at an emigrant family on the road through the …".

Camps can also be visited peacefully; see the section on visiting an emigrant camp below.

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

Companions revealing what they know after leaving is covered under tales below. Betrayal at low trust has its own section below.

## Visiting an emigrant camp peacefully

The same emigrant camps that the crime menu can target can also be visited peacefully: **Options → Visit an emigrant camp** (`open_camp`). The rules are in `data/trail_context.json` under `emigrant_camp`. They are authored tuning.

- **Trade.** 20 bullets for 40 lb of the family's food, up to twice per camp, with no day spent. Food traded away leaves their wagon, so a later robbery finds that much less.
- **Nursing.** They help nurse one traveler per camp: +10 health and a day of recovery, for one day. This is less than a post's paid care.
- **News.** Once per camp, with no day spent, they say which posts ahead have already heard of the party. If none have, they say they heard no talk of it.
- **Refusal.** A family the party wronged will not receive it, and neither will a camp that has heard the party named by witnesses or by a former companion.

Visits use the ordinary trade counters (`context.spent`, keyed by the camp). They need no crime-record change. The outlaw sampler's lawful control now visits every camp it meets.

## Betrayal at low trust (record version 8)

Some companions can betray the party: those whose values are Ruthless or Opportunistic. Such a companion reaches their **betrayal point** when trust falls to their betrayal threshold (10, less their relationship's attachment). View Party already warns "capable of betrayal" at that point. Nobody else ever betrays, however low their trust.

**When.** Each night on the trail, after the day's trust changes, a companion at the betrayal point turns on the party with a 12% chance. At most one companion does so per night. The roll is made only while someone is at the point, so ordinary journeys keep the same random stream.

**What they do.**

- **Theft.** An Opportunistic betrayer, or a Ruthless one who will not kill, robs the stores. Each other companion has a 25% chance to wake. Anyone who wakes stops the theft, but the thief still runs.
- **Night attack.** A Ruthless betrayer who will kill, if the leader is with the party and there is a bullet, shoots the leader first.
  - The chance to hit is 50%, less 10% for each other companion willing to defend the wagon, within the usual bounds.
  - A hit kills or wounds by the same rules as the leader's own attacks, and the cause names the betrayer.
  - The shot wakes everyone. If the leader dies, the journey goes on with the others.
- **What they take.** A theft that is not stopped, and every night attack, takes a quarter of the food, half the cash and a quarter of the bullets. The betrayer also takes the ordinary flight share.
- **Afterwards.** The betrayer is marked `fled` and leaves the party for good. The party hears what happened.

**Save validation.** Each betrayal names its member, act, result, the goods taken and who woke. The rules it must satisfy:

- The betrayer fled that same day, and betrayed only once.
- A stopped theft took nothing and someone woke.
- An unstopped theft had nobody wake.
- The leader died of the betrayer's shot if, and only if, the record says "killed".
- A fled member must have either an attack or a betrayal that explains it.

Version 7 records gain an empty betrayal list.

## Remains (record version 5)

Every death the party could reach goes into a remains ledger in the crime record. That covers a companion dying of anything, and a stranger the party killed. Each entry gives the person, their name, the cause and day of death, where the body is (a mile), its state, any money they carried, and whether the grave was ever opened. A death never grants food or anything else by itself.

| State | Within reach | What you can do |
| --- | --- | --- |
| Lying | At the same mile, unless living staff or survivors are still there to keep their own dead | Bury (1 day), carry, search a stranger's belongings |
| Carried | Always | Bury here (1 day), set down here, search |
| Buried | At the same mile | Dig up the grave (1 day), which leaves the body lying |
| Lost | Never | Nothing. Used for deaths from older saves, where nobody knows where the body lies |

**Tuning.** All values are authored in `data/crime_scenes.json`, not historical rates. A wrapped body counts as 150 lb of real cargo, and at most two ride with the party. A stranger killed by the party carries $2.50. A companion's own goods were already shared with the party, so there is nothing to search on them.

**Reactions.** Everyone with the wagon sees a grave opened. Companions close to the dead person (family, partner, friend) lose 12 trust and treat it as crossing a boundary. Others lose 3, and the Ruthless, Self-serving and Opportunistic lose nothing. Each memory carries the grave's id, so opening a second grave the same day is its own memory.

**Saves.** Only the dead have remains, one entry each, never ahead of the party. A companion's entry must match their death record. Carried bodies must match the cargo weight (`remains_lb`). A remembered desecration must match a grave marked as opened. Deaths with no entry, which only happens in records from before the ledger, join it as lost when the save is restored. An open list of the dead is rebuilt from the ledger.

A grave dug on the trail can be marked with a stone in the memorial book (`docs/SAVES_AND_GRAVESTONES.md`).

## Butchering and human meat (record version 6)

Butchering is its own decision. It is open to any body lying here or carried, whatever the party's food. It takes a day and leaves the body `processed`, with one batch of 40 ration-lb fresh meat (an authored, deliberately modest value). Each batch is tied to the body it came from and is never mixed into ordinary food. It spoils on the same schedule as other fresh meat. It can be dried or salted with the ordinary preservation rules, and it remains human meat. Its physical weight counts in `remains_lb`.

**Who knows.** Done openly, everyone with the wagon knows where the meat came from. Done in secret, each companion has a 35% chance to see it. The leader always knows. Learning is a single event per person and batch. That person's own boundary decides the reaction: −12 if they forbid it, −2 or +2 for disapproval or approval, nothing for the Cannibal special or those without a boundary. Anyone close to the dead person also loses 12 for the harm to the body. Eating it, carrying it and opening the menu again cost nothing further.

**Meals.** Nobody eats it unless chosen by name:

- *Eat it yourself* (the leader).
- *Offer it openly.* This tells them where every batch came from before they choose. Anyone whose boundary forbids it refuses, and is shown as refusing before you offer.
- *Serve it without telling them.* Only possible for someone who doesn't know.
- *Stop serving.*

Each day, before ordinary meals, every chosen eater is fed one ration from the oldest human meat. The ordinary ration then feeds only everyone else. When the meat runs out or spoils, the plan ends.

**Deception.** Each day a deceived eater has an 8% chance to find out. Discovery is remembered as its own wrong (−12), on top of their boundary's reaction, and they stop eating it. Someone who learns the truth any other way is no longer deceived either. Low trust then works through the ordinary departure rules.

**Saves.** Every batch needs a butchered body and can hold no more than that body yielded. Expiry stays within the preservation limits. An informed eater knows every batch. A deceived eater knows none, and is never the leader. Eaters must be with the party. Memories of butchering or deception must name a butchered body.

## Soldiers ride after the party

Only Fort Kearny has soldiers, so only Fort Kearny pursues. After the party escapes it, by slipping away or shooting its way out, soldiers may ride after it while any soldier other than the commissary sergeant is still alive. The chase window runs for 4 days from the getaway; the report's day marks it. Each day the party travels or rests in that window carries a 35% chance that they catch up. When they do, it is a new incident (`pursuit`, attempt `caught`) that opens straight into the standoff: shoot your way out or surrender, with the same odds, shots and wounds as at the post. Getting away again files its own report. The post chases the party once. Being caught is never counted as a successful job. Private posts and traders never pursue; they refuse service once they hear the news.

**Saves.** A chase must follow an escape from the same post, within its days, and there can be only one per post.

## What departed companions tell (record version 7)

A companion who leaves the party, whether at a settlement or by fleeing violence, tells others what they saw, but only the acts they object to:

- **Incidents they witnessed**, if they disapprove of or forbid robbery (or murder, for a shooting).
- **Attacks** they were present for, if they were the target, were close to the target, or object to murder.
- **Butchering** they learned of, if they object to cannibalism or were close to the dead person.

The Ruthless, and anyone without such a boundary, keep quiet. Their story starts where and when they left, and travels like witness reports: 2 days, then 25 miles a day in both directions. Any post it reaches refuses trade, paid care and the ferry, and its notice names the teller and what they said.

Stories are not stored. They are derived from the record each time. The only new saved fact is each body's `witnesses`: the companions who learned it was butchered. That knowledge outlasts the meat. Version 6 records take their witnesses from the meat still held.

## Outlaw journeys

`tests/outlaw_journeys.gd` drives 20 full-route journeys through public actions only: 5 strategies × 4 seeds, using the banker's suggested outfit and the existing cautious survival policy.

- **Lawful** is the control.
- **Road robber** robs up to three roadside parties.
- **Kearny** robs the commissary.
- **Open cannibal** shoots a companion on day 20, butchers any accessible dead openly and offers the meat.
- **Killer** does the same, but butchers in secret and serves the meat without telling.

Saves are round-tripped every 40 steps and at every crime or remains panel. Invariants include the carried-remains weight. The run fails on a blocked policy, a broken invariant, a failed save, or two months without progress.

The October 22 run (`docs/outlaw-journeys.json`) had **0 errors**:

- All 4 lawful journeys arrived intact.
- Robbers were captured, ran out of time near the end of the road, or arrived with fewer companions.
- At Kearny, one party was captured on the spot, one was caught by the pursuit and taken, and one shot its way out of the chase.
- Companion attacks killed, wounded or missed. Every miss or wound sent people away, and each who left told their story.

This is integration evidence, not balance evidence.

## Service audit

- A post that was robbed or lost its keeper is closed. Its trade and its paid local care are both refused there, not only once news reaches other posts. The party's own care kits still work anywhere.
- The ferry refuses passage after an incident, and the Barlow toll after the gatekeeper is killed (earlier sections).
- Stop activities are the party's own work (grazing, gear checks), so local staff don't affect them.
- Every open crime, attack or remains panel blocks travel, trade and rest until it is resolved, and is rebuilt from the record when a save loads.

## Other limits

Personal existing health specials still affect any actual injury damage. Paid trade at posts and with passing traders, paid care, the hired ferry and emigrant camp visits all respond to incidents and news. The Green River ferrymen, who are not a robbable scene, still refuse a party once news naming it reaches them. Unstaffed activities (grazing, repairing crossing gear) need nobody's help and are unaffected.

Reproduce using project-local APPDATA as in `test.ps1`: run `tests/test_crime.gd` for targeted checks or `tests/store_crime_journeys.gd` for the 24-route sample. Both use the actual engine. Keep previous balance reports archived.

