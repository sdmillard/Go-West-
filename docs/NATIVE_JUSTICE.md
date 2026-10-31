# Native households as crime targets, and their councils

Built October 31, 2026, from [NATIVE_JUSTICE_HANDOFF.md](NATIVE_JUSTICE_HANDOFF.md), with Spencer's decisions. **Every penalty here is invented for the game.** The research found no reliable source for 1848 penalties in these communities, so the council's terms are authored game rules. They are labelled "(Invented rule.)" in play.

## Who and what

Each of the seven Native visits has one household, a fixed crime venue keyed `native:<stop>` in `data/crime_scenes.json` (kind `household`):

| Visit | People | What can be taken |
|---|---|---|
| Platte | Pawnee provision keeper, relative, grown child | the two 40-unit provision parcels |
| Fort Hall | Shoshone and Bannock provision trader, relative, grown child | the two provision parcels (separate from the HBC post) |
| Grande Ronde | Nez Perce horse owner, herder, relative | the horse herd sold there |
| Umatilla | Umatilla garden keeper, relative, grown child | the two provision parcels |
| Deschutes | river pilot, relative | nothing: attack only |
| The Dalles | Wasco provision seller, relative, grown child | the two provision parcels |
| Cascades | Upper Chinookan load organizer, carrier, crew hand | nothing: attack only |

- The contact keeps their authored label as a target (for example, "The Pawnee provision keeper"). Kin are shown by role. Nobody is given an invented personal name.
- Households carry no cash.
- Stock is shared with peaceful dealings. Parcels bought or traded away can't be stolen, and stolen food leaves too little for a parcel. A stolen horse counts against the same herd the horse trade sells from.
- Fresh and dried produce baskets are not loot in this version.
- Theft, robbery, shooting and unarmed attacks use the ordinary crime mechanics and the tactical fight. A household fights on a camp-style map.
- Odds are authored: theft 40% unseen, threats work 25%, escape capture 15%. Ethnicity changes no combat value.

## Consequences

`CrimeSystem.household_refusal()` gives the reason a household turns the party away, or nothing. Only what they saw or heard counts:

- They saw the act (any noticed theft, robbery or attack).
- The contact is dead.
- Their council drove the party out of this country (same `hunting_region`).
- Identified news, or a former companion's tale, has reached them at the usual pace.

An unseen theft changes nothing until word of it arrives. A refusing household offers only the way back:

- no trade or work;
- no guide: an active Deschutes agreement stops guiding;
- no portage: the Cascades portage choice disappears;
- no horse trade at Grande Ronde.

## Kin pursuit

After an open crime the party got away from, kin may ride after it, the way Fort Kearny's soldiers do:

- once only, for 3 days plus notoriety (capped like the army), with a 30% chance each day;
- only while any kin other than the contact are alive.

A catch is a standoff: surrender, flee, or shoot your way out.

## The council

Anyone captured by a household, at the scene or by its pursuing kin, goes into custody with the `council` authority. The hearing is the next day. Waiting, vouching and the jailed-leader abandonment rules work as in [DETENTION.md](DETENTION.md). The council hears only wrongs done to its own household, each once.

| Worst act | Sentence | Terms (`detention.council`) |
|---|---|---|
| Theft | `returned` | the goods' worth twice over, at least $5 |
| Robbery or attack | `driven_out` | three times the loss, at least $25; no household in that country deals with the party again |
| Killing | `price` or `life` | the family chooses: $150 plus the loss, or the killer's life (the journey ends) |

- Payment is taken in cash first, then goods: food, clothing, bullets, parts, medicine and salt. Animals, wagons and gear are never taken.
- The chance the family wants a life is shown before the hearing. It starts at 35%, rises 35 points if the party can't cover the price, and falls 10 points if it surrendered.
- Paying the price also drives the party out.
- **Paying never erases violence.** A council's settlement answers to that council only, except a repaid theft. `Wanted.settled()` keeps an attack or killing open for regulators, bounty hunters and other juries who hear of it. Council sentences don't clear posted rewards.

## Fixes made along the way

- `Wanted.value_of` priced food restitution at an ox's price. Since the wagon and horses were added, `outfitter.goods[1]` is oxen. It now uses the food price.
- `Wanted.confiscate` could take horses, mules, saddles or produce, which the save validator then rejected. It now takes only the listed goods.

## Saves

- Crime record version is unchanged. `add_venues` gives older saves the seven untouched households.
- The previous rules fingerprint is listed in `data/save_migrations.json`.
- Validators cover household cash (always zero), witnesses, standoffs, kin pursuit and council sentences.

Tests: `tests/test_native_justice.gd`.
