# Arms

Built October 31, 2026, with Spencer's decision: "Period kit, revolvers rare". All numbers are authored game values in `data/weapons.json`, not measured historical data.

## What the party carries

- Every traveler sets out with their own rifle and belt knife (`home_kit`). `state.arms_home` records how many did, so the weight of those stays in personal gear.
- The outfitter sells more: extra rifle $15, shotgun $12, single-shot pistol $6, Colt revolver $50 (only one), knife $1, hatchet $1.50. Bought arms add their weight to the load.
- Arms are counted in `game.state` like other goods (`rifles`, `shotguns`, `pistols`, `revolvers`, `knives`, `hatchets`). `simulation/armory.gd` holds the rules.
- Journeys saved before arms get one rifle and knife per traveler on restore (`Armory.settle`). Tests that compare a migrated state use `SaveStore.upgraded_state()`.

## Shooting and hunting

- `can_fire()`: bullets and any firearm. Needed to shoot, attack, break out or fight on the trail with guns.
- `can_hunt_with_gun()`: bullets and a long gun (rifle or shotgun). A pistol or Colt is no hunting arm.

## In a tactical fight

Arms are still counted as party stock, but the player can hand a piece to a chosen traveler (November 1, 2026, Spencer chose "show and assign"). VIEW PARTY shows each traveler's gun and blade as icons on their row, and the selected traveler has a GUN and a BLADE picker: AUTO, any arm the party holds, or none. Picks live in `state.arms_assigned` (`{"<traveler id>": {"weapon": key or "", "blade": key or ""}}`, optional in saves).

When a fight starts, `Armory.loadout_for(state, ids)` first gives each fighter their pick while the stock lasts, then shares out the rest to everyone on AUTO in squad order (leader first), scarcer close arms first (Colt, shotgun, rifle, pistol; hatchet before knife), so a bought piece is always in someone's hands. A pick that has been stolen, sold or held falls back to AUTO without being forgotten. Handing the last piece of a kind to someone takes it from whoever had it picked. Travelers who don't fight (guarding, away, unwilling) don't hold their pick back from the others. Anyone left over fights with a blade or bare hands.

| Arm | Loads | Range (best / most) | Character |
|---|---|---|---|
| Rifle | 1 | 4 / 11 | the only arm that reaches far |
| Shotgun | 2 | 2 / 6 | surest and hardest up close, falls off fast |
| Colt | 5 | 3 / 6 | many quick shots, lighter hits, slow to refill the cylinder |
| Pistol | 1 | 2 / 5 | quick and cheap, weak and short |

- Pistols snap-fire for 3 AP, long guns 4.
- Reloading fills the gun as far as the pouch allows.
- Melee uses the blade: a hatchet hits hardest and a knife strikes quickest (2 AP). Without a blade, a long gun is clubbed by the stock and anyone else uses their fists.

## Trading, theft and custody

- Post store counters sell rifles (2 on hand), a shotgun (1), pistols (2), knives (4) and hatchets (3) at the region's prices, and buy them back for less. Only Independence sells the Colt. Passing traders and emigrant camps don't deal in arms yet.
- A post's arms can be stolen or demanded in a robbery like its other goods.
- Bandits can demand a Colt, shotgun, pistol or rifle among the goods. When they take the wagon, they take the spare arms in it but not each traveler's own rifle.
- When the party is taken into custody, each accused gives up the firearm and blade they carry (their pick first, `custody.arms`). They get them back when they walk free (discharged, bailed, fined, or sentenced without prison). This sets up jailbreak as a tactical fight.

Tests: `tests/test_weapons.gd`.
