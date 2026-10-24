# Hunting trips and mounted outriders

Open **Camp > Field trips > Outfit a hunting trip**, the companion's task menu, or the normal Hunt command. Choose the leader to play the hunting minigame or a companion to send away. Foot trips take one day; riding trips take one to three. A led pack animal increases cargo but does not turn a walker into a rider. Scouts and new Soldier/Criminal backgrounds remain future work.

## Actual people, packs and animals

Leader and companion hunts share one outfit calculation. Only the selected people and allocated horse/mule/tack add capacity. Good and Fair health retain full human capacity; Poor and Very Poor reduce it along the shared walking/hauling curve. Broken legs prevent human hauling. Rations for the chosen duration plus one reserve day, one clothing set and personal gear per person, and selected ammunition consume outbound capacity. Catch fits in the remaining room, within the existing 200 lb retrieval ceiling. The screen quotes these amounts before departure. Merely owning animals grants no outing cargo. Riding needs a saddle and bags; packing needs a pack saddle.

The actual food batches keep their weight, nutrients and expiry. Food, clothing, bullets, animals and tack leave the camp stores. Empty returns still consume meals and ammunition. Personal supplies and unused ammunition return once; catch is limited again by the receiving party's actual storage. Workload, country, season and weather affect animal wear through the shared mount formula. These are game rules, not a claim that every lone hunter historically hauled this amount.

The leader's explicit outfit uses the same rules, while the minigame remains interactive. Camp helpers must be explicitly selected, and in assignment mode must have Help leader hunt assigned. Other camp work can share that day. The older no-argument simulation hunting API retains group behavior for existing scripts; new UI hunts always supply an explicit outfit. Existing journey bots therefore do not yet measure the new outing economy.

## Away and returning

Each dispatched companion has their own saved supplies, health and random stream. They keep their roster slot but cannot simultaneously work in camp, haul for the party, defend it, lend passive specialist benefits or receive wages remotely. Living paid hunters accrue wages; eligible automatic payments resume after rejoining.

A mounted hunter can rejoin a moving party on the same continuous road within riding distance. Rivers, forks and opposite headings interrupt catch-up. A possible injury/mishap delays the return by one or two days. Hunting success and delays are authored tuning in data/field_outings.json, not measured historical probabilities.

Travel warns before leaving foot hunters or overdue riders. Crossings, forks, turning around and flight also warn about riding hunters. Back restores the previous choices; Leave records consent and restores the original action so it can be taken. Ordinary warnings offer a one-day wait. Flight warnings offer only Leave/Back, avoiding a free safe rest during combat.

If the party has moved beyond a possible reunion, the hunter becomes stranded at the departure camp. The map marks this camp separately from a wagon cache. **Camp > Field trips > Look for hunters at this camp** recovers them at that location. Their food can spoil or run out; illness, exposure, death or departure can follow. Survival hunting uses the same physical outfit allowance. A nearby mounted hunter may catch up on a safe continuous road depending on trust and temperament. Departing hunters take their allocated animals/tack. The party learns offscreen health and supplies on return.

Trip settings persist as preferences; trips do not automatically repeat. Standing camp chores remain unchanged.

## Persistence and verification

Character schema 5 strictly validates trip identity, route position, supplies, stock, timing and reserved party entries. A genuine schema-4 fixture from master 2e01155 verifies migration without changing inventory or the original random stream. The prior rules signatures are whitelisted. A genuine immediately preceding schema-5 fixture with an active mounted trip also preserves its actual reserved supplies, animals, return date and random streams after the carrying-curve change. Active trips, stranded camps, departure warnings and authoritative crime escape menus round-trip through JSON.

Focused checks cover shared carrying, reservations, meals and ammunition, wage settlement, travel and river timing, delayed returns, recovery, death, migration, rejected malformed saves, and actual UI dispatch. Native Godot screens were inspected. Full-suite and journey evidence is recorded in CLAUDE_HANDOFF.md after validation.

A new route-balance study using actual assignments and outfitted trips is still needed; these software checks do not certify farmer viability, hunting yields or total journey balance.

## Carrying audit and revised health breakpoints

Spencer reported a solo hunt limited to 10 lb at Fair health. The previous calculation reproduced it exactly at health 75: 50 x 0.75 = 37.5 lb gross, less 15 lb personal gear, 6 lb clothing, 6 lb food and 0.5 lb ammunition = 10 lb catch. At health 60 it left only 2 lb. There was no fixed 10 lb cap. This identified a health-label mismatch, not missing animal cargo.

Spencer chose full capacity through Good **and Fair**, with reductions beginning in Poor. One data-driven continuous curve now serves walking, outfitting, leader/delegated/guard hunting and loot hauling. It replaces the separate walking relief multiplier.

| Health score | Displayed condition | Human allowance |
| --- | --- | --- |
| 50-100 | Fair / Good | 100% |
| 20-49 | Poor | 50% at 20, smoothly rising to 100% at 50 |
| 1-19 | Very Poor | Smoothly rises from zero to 50% at 20 |
| 0 or dead/absent | Unavailable | Zero |
| Any score with broken leg | Injury restriction | Zero human hauling |

Base limits remain 40 lb per walker and 50 lb per retrieval participant, with the existing 200 lb group retrieval ceiling. Pack mass is still subtracted once. Thus the quoted solo foot hunter with a 27.5 lb pack has 22 lb catch room throughout Good/Fair. A Poor hunter at health 35 has 37.5 lb gross and 10 lb catch room. This is one-trip capacity, not total usable meat on the carcass.

These health breakpoints are explicit gameplay interpretation, not clinical measurements of strength. [Army load-carriage research](https://www.army.mil/article/234235/) supports treating load, terrain, fatigue and speed as interacting costs; it does not justify interpreting an abstract health score as a literal lifting-strength percentage. A revised day-hunt kit or multiple retrieval trips would be separate changes. The present change does not invent extra hauling or remove the actual pack costs.

## Horse cargo reference and remaining design

The [Forest Service packing guide](https://www.fs.usda.gov/t-d/pubs/pdfimage/95231202.pdf) gives horse pack loads around 200-300 lb and calls for properly balanced loads. [University of Minnesota Extension](https://extension.umn.edu/agriculture/animals-and-livestock/horse/guidelines-for-weight-carrying-capacity-of-horses) discusses approximately 20% of ideal body weight for an average light riding horse, including rider and tack, with conformation and conditioning affecting suitability. These are different working contexts, not a universal spare-cargo allowance.

Spencer supplied a game screenshot of a person leading a saddled horse carrying a deer. The basic transport arrangement is plausible; a game image does not establish safe load placement. Saddlebags are not the only way a riding horse can carry cargo. Current presets still use 175 lb pack-horse cargo, 200 lb pack-mule cargo and 25 lb saddlebag cargo. A ride-out/lead-home return with securely lashed meat and a greater saddle cargo allowance is a requested design direction, **not implemented by this checkpoint**. Do not claim the 25 lb bag limit is the horse's anatomical capacity or that a horse can take a full pack load while also carrying a rider.

Spencer also clarified that a loaded riding horse may still move with increased wear, rather than treating saddlebag volume as a hard anatomical load limit. A future load/return-mode change should distinguish a comfortable working load from a possible strenuous load, account for rider and tack, and feed extra cargo into speed and animal condition. A heavily loaded outrider must not retain unloaded catch-up speed. This is pending; current presets and their wear calculation remain the shipped limits.
