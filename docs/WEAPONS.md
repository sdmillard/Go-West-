# Arms

Built October 31, 2026, with Spencer's decision: "Period kit, revolvers rare". All numbers are authored game values in `data/weapons.json`, not measured historical data.

## What the party carries

- Every traveler sets out with their own rifle and belt knife (`home_kit`). `state.arms_home` records how many did, so the weight of those stays in personal gear.
- The outfitter sells more: extra rifle $15, shotgun $12, single-shot pistol $6, Colt revolver $50 (only one), knife $1, hatchet $1.50. Bought arms add their weight to the load.
- Arms are counted in `game.state` like other goods (`rifles`, `shotguns`, `pistols`, `revolvers`, `knives`, `hatchets`). `simulation/armory.gd` holds the rules.
- Journeys saved before arms get one rifle and knife per traveler when loaded.

## Shooting and hunting

- `can_fire()`: bullets and any firearm. Needed to shoot, attack, break out or fight on the trail with guns.
- `can_hunt_with_gun()`: bullets and a long gun (rifle or shotgun). A pistol or Colt is no hunting arm.

## In a tactical fight

Each traveler takes one firearm and one blade from the party's stock, in squad order (leader first). The scarcer close arms go first (Colt, shotgun, rifle, pistol; hatchet before knife), so a bought piece is always in someone's hands. Anyone left over fights with a blade or bare hands.

| Arm | Loads | Range (best / most) | Character |
|---|---|---|---|
| Rifle | 1 | 4 / 11 | the only arm that reaches far |
| Shotgun | 2 | 2 / 6 | surest and hardest up close, falls off fast |
| Colt | 5 | 3 / 6 | many quick shots, lighter hits, slow to refill the cylinder |
| Pistol | 1 | 2 / 5 | quick and cheap, weak and short |

- Pistols snap-fire for 3 AP, long guns 4.
- Reloading fills the gun as far as the pouch allows.
- Melee uses the blade: a hatchet hits hardest and a knife strikes quickest (2 AP). Without a blade, a long gun is clubbed by the stock and anyone else uses their fists.

## Not yet

- Arms at post store counters.
- Stealing arms.
- Arms taken in custody, then jailbreak as a tactical fight.

Tests: `tests/test_weapons.gd`.
