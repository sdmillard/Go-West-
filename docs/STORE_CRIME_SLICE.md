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

## Other limits

Personal existing health specials still affect any actual injury damage. Paid trade, paid care and the hired ferry respond to incidents and news; other services are not yet governed by a general hostility/access system. Fort Kearny (the only army post on the 1848 route) has no scene yet.

Reproduce using project-local APPDATA as in `test.ps1`: run `tests/test_crime.gd` for targeted checks or `tests/store_crime_journeys.gd` for the 24-route sample. Both use the actual engine. Keep previous balance reports archived.

