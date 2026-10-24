# Horses and mules (step 1)

October 24, 2026. Design: [Horses on the trail](https://claude.ai/artifact/RTG34wkhgqh5dZoSxKN9PX). All loads, miles and wear below are authored game tuning in `data/provisions.json` → `mounts`, not measured 1848 figures.

## The Independence store

The wagon is now a listed item: **WAGON $75 (MAX 1)**, one in the cart by default. Every profession's starting cash rose by $75, so the default outfit leaves the same money as before. Carts from before the listing (scripts, studies) still buy one wagon.

New items: horses $40, mules $50, saddle and bridle $15, pack saddle $5, saddlebags $3. A party that leaves without a wagon departs as packers on foot (`vehicle == "foot"`), with only personal gear (15 lb a person). A wagon still needs at least one ox; packers need no oxen. Without a wagon, the whole outfit must fit what the riders, walkers and animals can carry.

## Seats and loads

`simulation/mounts.gd` works out how the animals are used each day:

- Horses go under the saddles first, mules under the pack saddles. Only as many saddles are used as there are riders.
- A saddle animal carries one rider and, with saddlebags, 25 lb. A pack horse carries 175 lb, a pack mule 200 lb. Spare animals are led and carry nothing.
- **Mounted:** every traveler has a saddle. Riders carry only their 15 lb personal gear.
- **Doubled up** (Travel → DOUBLE UP): with at least one saddle per two travelers, two ride each saddled animal at riding pace. Doubled riders also carry only personal gear.
- **Pack train / on foot:** too few saddles. Everyone walks at the normal walking pace with full 40 lb packs, and the animals carry their saddlebags and packs.

Example for five: five saddle horses with bags and three pack mules carry 800 lb in all (75 gear, 125 bags, 600 packs), against the wagon's 2,500.

Abandoning the wagon or selling it at a post keeps the animals and tack, and the pack and sale quotes use the animals' loads. Horses led behind a wagon add no capacity and take no wear.

## Pace and condition

- A mounted day is 32 miles before pace (+15% / +30%), condition, load, weather, terrain, season and fatigue. Walking stays at 12. On matched days a mounted party covers roughly 1.3 times a loaded wagon's ground.
- Riders gain fatigue more slowly than walkers or wagon drivers.
- Horses and mules share one condition (`horse_health`). Each carrying day costs 1, plus the region's strain, the season's working strain, bad weather and waterless legs, plus extra for poor grass: high country and forest +1, sagebrush +2. Mounted parties add the pace setting. Doubling up multiplies the day's wear by four.
- A rest day restores 4, an ordinary day without carrying restores 1. Waterless legs allow no recovery.
- An animal ridden to zero gives out and is left on the road (horses before mules). The rest recover to 35.

## Wagonless events

A party with no wagon never meets wagon troubles: breakdowns, wagon fires, swamped loads, hail damage and the cracked-wheel muddy trail are skipped, along with the oxen events. Shared encounters (bandits, riders and the like) speak of the party instead of the wagon, and any strain they put on a team falls on the horses and mules (`horse_health`), or on nobody when the party walks with no animals.

## River crossings

A party with horses or mules gets one crossing choice besides any ferry, set by the water: **Ford with the horses** in low water (8% mishap risk before the river's own factor) or **Swim the horses across** in high water (40%). If the water rises while the party waits, the ford becomes a swim. A mishap costs the usual food, clothing and injuries; in high water the current also drowns one animal. Walkers without animals still swim with their packs. These odds are authored gameplay tuning.

`cross_horses.png` (PR #72) draws the stock two abreast in the crossing scene: riders walk the landings, wade a ford and swim high water; pack horses (and led horses) and pack mules do the same. On a ferry, the deck takes two ranks of riders, or one rank of animals with the walkers behind.

## Display

`horses.png` (PR #72) draws a single-file string in `ui/trail_view.gd`: riders (man, woman, mule rider, or doubled riders), then pack horses, pack mules and led animals, up to eight. Walkers follow when the party is on foot. The ledger shows MOUNTED, DOUBLED UP or PACK TRAIN with the animal count and condition; Supplies → Transport lists stock, tack and loads.

## Saves

The horse keys are optional: a party that never bought an animal, and every older record, has none, so their state and saves are unchanged. `tests/fixtures/pre-horses-save-v1.json` is a real save from the previous rules. The previous rules fingerprint is whitelisted in `data/save_migrations.json`.

## Not yet built

Later steps from the design: horses, mules and tack at posts and traders (and in robbery demands, with the resale cap); theft, horse butchering and Cayuse/Nez Perce trade; flight bonuses in the wanted system, and fleeing a wagon on horseback with an automatic, hasty saddlebag pack; a balance study of wagon, packer and walking journeys.

## Validation

`tests/test_mounts.gd` (64 checks): store quotes with and without a wagon, packer departure, seat assignment, riding versus walking distance, mounted versus wagon first day, wear and rest, doubling up, sagebrush wear, breakdowns, led horses behind a wagon, abandoning the wagon with horses, save round trip, the real pre-horse save, wagonless events, the horse ford and swim (choice, mishaps, drowned animals, rising water, saves) and the travel view and ledger. Existing tests that priced the default outfit now include the $75 wagon; the store-layout check scrolls to the salt row in the longer list.
