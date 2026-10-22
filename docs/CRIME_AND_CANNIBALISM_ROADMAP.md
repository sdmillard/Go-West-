# Crime, cannibalism and survival balance roadmap

October 22, 2026. **Planning document; these crime and cannibalism mechanics are not implemented yet.** The character catalog, personal health, defensive confrontations, finite trading, provisions, preservation, departures, route and compatible saves are the current foundation.

## Design commitments

- The narrator describes actions and results. Individual characters judge them through values, relationships, boundaries and knowledge. There is no universal morality meter.
- Crime can produce real immediate benefits: stolen supplies, retained cash, access to a road or use of a ferry. Resistance, injuries, escape, discovery and later consequences make those opportunities dangerous.
- Attempt, outcome and discovery are distinct facts. An unsuccessful attack can still destroy trust. A concealed act can be discovered later. Killing a witness cannot erase information they already passed on.
- Choosing to attack someone, killing them, treating their remains, consuming those remains and deceiving another eater are distinct decisions. No hunger threshold unlocks these actions. Physical access, available resources and the encounter state still matter.
- Cannibal removes that individual's objection to consumption. It grants no blanket acceptance of murder, coercion, deception or harming someone close to them.
- The existing two-special allowance, one optional flaw and third special slot remain. Recruitment, a new skill-level system and a combat minigame will not hold up this implementation sequence.

## First-release scope

Implement petty theft and armed robbery at stores; deliberate attacks on storekeepers, tollkeepers, ferry operators and companions; the immediate response to violence in a guarded fort; finite looting; escape/surrender/capture; bodies after accessible deaths; burial, grave disturbance, butchering, consumption and deceptive serving; local identification and delayed information spread; individual companion consequences.

The wider catalog also includes burglary, livestock theft, fraud and extortion. Record compatible incident types now, and add their playable encounters after the first integrated survival balance. Kidnapping, a prison simulation, territorial conquest, disguise systems, organized gangs and elaborate investigations stay outside this first release. Withholding care, abandonment and broken agreements remain separately identifiable grievances; they do not all automatically invoke the same settlement response.

## 1. Persistent people, incidents and knowledge

Build a small independent crime/incident service with JSON scene rules, rather than putting all resolution inside the UI or enlarging the travel engine indefinitely.

- **People:** persistent actor identities for service operators, nearby responders and companions. Distinguish identity from the party's five active roster slots. Future replacement must not overwrite a dead person's grave, debt, relationships, body or history. Keep the current roster behavior while introducing an identity layer that old saves can migrate into.
- **Service ownership:** connect shop stock, collected toll money, ferry equipment and access rights to a persistent location/service. Allow multiple workers or responders where the scene warrants them. A single death does not automatically transfer control of everything nearby.
- **Incidents:** unique incident and stage IDs; place/day; instigator, victim and participants; intent, attempt and outcome; ammunition and elapsed time; injuries/deaths; resource transfers; observers and evidence. Journal the actual quantities gained or lost.
- **Knowledge:** each observer can know particular facts, suspect an identity, report something or discover evidence later. Direct observation, confession and rumor are different evidence sources. No automatic worldwide knowledge.
- **Inventory:** resource ownership, remaining loot and provenance. Existing trade stock and looted stock must draw from one finite source. Moving or selling loot must not replenish it. Ordinary coins need no magical universal identification; incident evidence can still describe stolen money.
- **Clock and randomness:** assign encounter time costs once through the existing day system. Opening menus and viewing odds spend nothing and consume no RNG. A separate saved crime random stream avoids changing ordinary travel outcomes just by adding the feature. Committed outcomes survive save/load.
- **Compatibility:** version and validate new records, migrate a genuine pre-feature fixture, retain old cash/inventory/contracts and pending offers, and initialize older saves without invented crimes or witnesses. Do not conjure accessible bodies from old death records whose locations are unknown.

**Gate:** same seed/actions reproduce results; save/load works between encounter stages; repeated inspection, reopening, cancellation and restoration cannot duplicate people, loot, bodies, reactions or benefits. Lawful journeys retain their existing behavior.

## 2. First complete encounter: a store

The first playable slice should include its consequences, not stop at granting loot.

1. Inspect the store and choose an explicit theft, threat or attack action from a separate actions menu. Ordinary Continue/Trade choices remain safe defaults for existing journeys and automation.
2. Preview known resistance, nearby help, participating companions, ammunition and time commitments. Show uncertainty without revealing hidden witnesses or future random outcomes.
3. Resolve compliance, discovery, resistance or an attack. A shot spends ammunition and can miss, wound or kill; assault can also become fatal. The target and other people may react before looting becomes possible.
4. Let the player leave, flee, surrender, escalate or take a limited amount from reachable stock. Looting costs the configured time and uses real cargo capacity; some storage can remain inaccessible. A wound is not treated as a death.
5. Resolve immediate witnesses, local alarm and personal companion reactions. Close or alter the service persistently when its operator or stock is gone. Leaving the screen does not reopen a fresh shop.

Reuse the current party health/injury and ammunition systems. Start with explicit choices and seeded encounter resolution; a shooting minigame is optional future work.

**Gate:** successful theft/violence can yield a useful, correctly accounted benefit; credible failures exist; companions can refuse assistance; stock cannot be looted and sold repeatedly; the full encounter is saveable and appears in history.

## 3. Toll stations, ferries and guarded locations

Add scene variants on the same incident machinery:

| Situation | Possible benefit | Encounter-specific consequence |
| --- | --- | --- |
| Toll station | Pass without paying; take accessible collected money | Other attendants, resistance, witnesses and pursuit; the road's normal travel cost remains |
| Ferry | Seize and operate the ferry without paying | Securing the boat and operating without experienced help; increased, explicitly described crossing mishap risk and actual supply/injury losses |
| Guarded trading post | Obtain reachable goods or money | Nearby defenders, interrupted looting, changed future services and a difficult escape |
| Fort | A victim's possessions or access to guarded resources | Rapid armed response, blocked exits, substantially greater danger, surrender or capture; shooting a way out remains possible |

Use historical route/date gates and research the staffing, operation and physical setting of each venue before authoring its scene. Do not invent an operating ferry or fully staffed fort solely to supply a crime target. Record invented individual characters and exact risk parameters as authored content.

Escape depends on the available defenders, health, willing participants, ammunition, terrain and what has already happened. Existing clean-defense experience and successful crime counters can provide a modest capped experience contribution. Do not add a skill tree, guaranteed success, or repeatable experience from the same resolved target. Capture initially has a bounded outcome, including possible journey-ending capture with surviving characters recorded correctly; a prison simulation is unnecessary.

**Gate:** an isolated service and a guarded fort play differently. A dead operator remains dead; surviving crews still matter. Free passage does not remove normal crossing/travel hazards. Escape losses are recorded exactly, and a high-experience character remains vulnerable.

## 4. Companion attacks, bonds and immediate reactions

Expose an explicit attempt to attack a living companion independently of hunger. Show the intended target and participating/refusing people before commitment. Use the common attack/resistance system; intent does not guarantee a kill.

Add sparse named bonds between companions—friend, family, partner or rival—using persistent identities. The current catalog only describes relationships to the leader. Harm to a loved one needs its own response, rather than merely applying the same generic trust penalty to everyone.

Companions may defend the target, flee, refuse further help, demand separation or turn against the attacker according to their values, bonds and knowledge. A person may assist in escaping a dangerous scene while still condemning the original attack. Extend the current safe-settlement departure machinery to support immediate flight or confrontation where appropriate; a witnessed killing must not force everyone to wait politely for the next town.

Track trust and memories per incident/stage/observer. Existing daily activity deduplication must not suppress a second attack on a different person, and repeated UI refreshes must not charge the same reaction again. A failed attempt, a death and a later discovery can have different consequences without accidentally counting one fact multiple times.

**Gate:** witnessed failed attempts matter; survivors retain injuries and knowledge; close bonds change reactions; refusal/flight changes actual food needs, work, defense and capacity; killed and departed identities remain in history. No automatic replacement companion is granted.

## 5. Bodies, processing and consumption

Introduce a remains ledger linked to the deceased identity, cause/date/place of death, physical location, current accessibility and processing/burial state. Accessible NPC deaths and natural companion deaths use the same foundation as deliberate killings. Death never automatically grants food.

Keep these separate player decisions:

1. Leave or transport the remains, subject to physical capacity.
2. Bury them and optionally make a gravestone using the existing memorial system.
3. Disturb a grave or take possessions, where the player actually has access.
4. Process remains into a distinctly tracked food batch, with an abstract time cost, bounded yield and ordinary spoilage/preservation accounting.
5. Consume it personally, offer it openly to companions, or deliberately serve it deceptively.

Keep human-derived food provenance through storage, preservation, transfer and disposal. It must not become anonymous ordinary food simply by mixing or drying. The current daily shared-food model will need a per-person allocation step: willing informed eaters, refusers and deceived eaters can have different meals and knowledge. The normal ration button must never silently choose human remains for everybody.

Receiving nutrition, approving of consumption and approving of a death are independent. Cannibal affects consumption boundaries; murder and deception retain their own reactions. Apply consequences to identifiable decisions/discoveries, not every pound consumed or every opening of the provisions menu. Repeated deliberate acts can still accumulate consequences.

Exact yields, preparation time, shelf life, nutritional equivalence and any biological risks require explicit gameplay tuning and documented evidence limits. Use the existing food/cargo distinction and preservation costs. There is no unexplained morality-based health penalty. Use restrained original pixel art and clear, factual event text.

**Gate:** physical access is required; any cause of death can supply accessible remains; hunger is irrelevant to action availability; no duplicate body/food/grave rewards; consent and deception are explicit; ordinary eaters can refuse without receiving the food secretly through aggregate rations; all stages round-trip through saves.

## 6. Information spread, pursuit and a complete road pass

The earlier stages already have local witnesses and immediate responses. Extend them into delayed consequences along the route:

- Witnesses and reports carry information through plausible connections and travel delays. Distinguish an identified party from a vague description or suspicion. Killing or intimidating someone can prevent a future report but cannot retract one already delivered.
- Receiving locations can refuse trade, alter access, confront the party or trigger a pursuit/escape encounter based on their actual knowledge and capacity. Responses should describe the reported incident; a generic global reputation number is insufficient.
- Companions can reveal information after leaving or discovering concealed actions. Their own participation and observations matter. Concealment does not make every companion omniscient, and ordinary knowledge does not vanish when trust improves.
- Closed shops, lost ferry operators, stolen livestock, depleted stock and discarded bodies persist. Later injuries, illness deaths, graves and arrival summaries preserve their causes and links.
- Audit every legitimate service after hostile actions so the player cannot bypass combat by opening trade, resting through unresolved danger, reopening a dead operator's menu or returning to an earlier stage.

**Gate:** several full-route criminal and non-criminal journeys complete without stuck encounters, impossible services, replay exploits or contradictory knowledge. Do not begin the final balance campaign until phases 1–6 are integrated.

## 7. Full survival balance campaign

Freeze this feature set for the balance pass. Replacement recruitment, the remaining crime catalog and a combat minigame come afterward unless they are required to fix an integration defect.

### Strategies and cohorts

Compare lawful hunting/drying, lawful salted preservation, no-hunting control, opportunistic theft, armed robbery, consuming only already-dead companions, and deliberate predation. Script each strategy through actual public actions, not a second survival model. Do not assume a violent strategy automatically succeeds, or that a player must resort to crime to win.

Start with three starting-capital options × three departure seasons × four representative companion rosters × seven strategies × twenty seeds: **5,040 development journeys**. Reserve a separate twenty-seed sample for **5,040 held-out journeys** after tuning. Use matched initial parties/seeds across policies; preserve identical ordinary RNG streams where the actual elapsed days/actions remain the same. Historical comparisons and authored balance targets stay distinct.

Cover the full catalog through focused trait tests and targeted journey cohorts rather than trying every one of the 28 million builds. Representative rosters should include unpaid ordinary companions, an affordable mixed paid/free party, a fragile or demanding party, and a deliberately selected three-special/one-flaw party.

### Mechanics that must actually count

- Starting capital and owned equipment; exact prices, finite stock, discounts, resale spreads, theft/loot provenance and denied future services.
- Four/six-ox alternatives and depleted teams, fatigue, grazing, livestock losses/slaughter, wagon weight and abandonment, walking capacity, cache recovery and emergency crossings.
- Hunting skill/aim sensitivity, regional game, ammunition spent hunting **and fighting**, carrying limits, food equivalents, spoilage, drying, salt, processing days and meal consumption.
- Weather, season, clothing/exposure, terrain, pace, rations, typed camp rest, individual illness/injury, care availability, recovery, death and grave handling.
- Wages/debt, trust, helper willingness, specials/flaws, companion bonds, departure or flight, refused meals, accessible remains, informed consumption and discovery of deception.
- Local resistance, fort danger, failed crime attempts, pursuit, capture, lost time and supplies, changing access, and rumor delays.

Run targeted stress cases for zero ammunition, zero oxen, foot travel, low health, several refusers, a closed supply post, a failed attack without a death, an unwitnessed crime later discovered, all other companions leaving, and spoiled human-derived food. Use saved player journeys for diagnosis when available; preserve the player's real saves.

### What to measure

Report arrival, intact arrival, survivors with the party, deaths, departures/flight, capture and stranded/loop outcomes separately. Record travel duration, starvation days, hunting effort, supply/cash curves, wages paid and owed, ammunition use, loot, denied services, bodies/food provenance, witness knowledge and actual injury/death causes. Audit supply conservation and sample save/replay during journeys.

Arrival alone can reward a party for losing mouths to feed; it is not sufficient evidence of good balance. A useful criminal payoff and a meaningful risk can coexist. Tune transparent mechanics and bottlenecks rather than imposing an inevitable narrative punishment. Lawful, skilled survival must remain viable, while an expensive payroll or repeated violence should create real obligations and exposure to loss.

**Exit gate:** no selected invariant/setup/save/route-loop errors; demonstrated lawful survival across all capital options with suitable play; informative failures for weak strategies; useful but bounded crime payoffs; working companion/food consequences; held-out results published without retuning to that sample. Then conduct a human playtest for clarity, pacing and whether the danger feels understandable. Simulation results do not substitute for that playtest.

## Implementation handoff

Start with **phase 1's incident/actor/knowledge contracts and a save fixture**, then finish one store encounter end to end before multiplying locations. Add new modules and JSON scene definitions with explicit validation; keep the engine as the coordinator and the UI as a reader of previews/results. Extend the existing combat, health, provisions, character and save components at their existing boundaries.

Each phase should ship with targeted regression checks, actual native UI inspection and updated documentation. Archive previous balance reports instead of overwriting them. This roadmap establishes the order; it does not claim these features or the final balance campaign have already shipped.
