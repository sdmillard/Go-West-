# Horses and mules

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
- **Pack train / on foot:** too few saddles. Everyone walks at the normal walking pace with full 50 lb packs, and the animals carry their saddlebags and packs.

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

## Buying and selling along the trail

Horses, mules, saddles, pack saddles and saddlebags are trade goods at every post counter, in the old lot menu, and with passing traders and emigrant families (`data/survival_rules.json` → `trade_lots`).

- A post keeps 4 horses, 3 mules, 4 saddles, 4 pack saddles and 6 pairs of saddlebags (the optional `post_lots` per lot) and sells at its regional price: a horse is $40 in the woodland and plains, $54 in the sagebrush.
- Passing traders and emigrant families roll their own stock and wants for animals and tack (`mount_stock` / `mount_wants` in `trail_context.json`). These rolls come after everything else a party or family carries, so every older meeting keeps the goods and purse it always had. Traders charge their usual markup.
- **Regional sell prices (Spencer):** where goods cost more to buy, they fetch more too. Every lot's sell price is multiplied by the region's price (not the traders' markup), so a horse sells for $15 on the plains and about $20 in sagebrush country. A wagon sold at a post pays half that post's own wagon price.
- **Resale cap:** nothing sells for as much as it costs at the same counter (a sell price that would reach the buy price is cut to half of it), and a family short of something never pays its own asking price. No buy-and-sell-back loop makes money.

## Robbery and theft

- Robbery demands can name horses, mules and tack, valued at Independence prices. Taking a trading party's or family's last saddle and pack animals strands them, so they resist harder (`mount_penalty` 0.15). A wagon can only be demanded if the party has oxen or demands them too.
- **Stealing works like a demand (Spencer's request).** At a store, commissary, trading party or camp, STEAL opens the same goods picker. The chance of going unseen is the scene's theft chance, minus `theft_value_penalty` (0.5) times the share of their goods taken, minus `animal_noise` (0.06) for each horse or mule led off. A theft never takes the cash box or a wagon, and it must be carried off by willing, fit helpers (animals walk themselves). Unseen, the party carries off exactly what it chose; noticed, it gets nothing and must run. Gates and ferries keep their old passage theft. Thefts begun without a basket (older saves) still take food as before.

## Horse country

- **Horse thieves** (`horse_thieves` in `trail_events.json`, weight 8, only for parties with horses or mules, wagon or not): at first light up to two animals are gone, horses before mules. Ride after the thieves (2 days, both back, 25% chance of a wound), search the nearby draws (1 day, one back; dropped when only one was taken), or let them go.
- **Night guard** (Travel → NIGHT GUARD ON THE STOCK): divides the horse thieves' weight by `guard_factor` (3) and costs `guard_fatigue` (2) fatigue every day. Optional state key `night_guard`.
- **Butchering** (Supplies → BUTCHER 1 HORSE / MULE): 250 lb from a horse, 220 from a mule, scaled from half to full by the animals' condition, with the ox rules for the bullet and for by-hand injury.
- **Nez Perce horse traders** at the Grande Ronde (`horse_traders` in `trail_context.json`): a horse for two clothing sets, a footsore ox, 60 bullets or $20 in coin, four horses per herd, the first trade costing the day. Before the 1847 killings at Waiilatpu both Cayuse and Nez Perce traded horses with emigrants there; with the Cayuse at war in 1848, the game credits Nez Perce families, who largely stayed out of it.

## Display

`horses.png` (PR #72) draws a single-file string in `ui/trail_view.gd`: riders (man, woman, mule rider, or doubled riders), then pack horses, pack mules and led animals, up to eight. Walkers follow when the party is on foot. The ledger shows MOUNTED, DOUBLED UP or PACK TRAIN with the animal count and condition; Supplies → Transport lists stock, tack and loads.

## Saves

The horse keys are optional: a party that never bought an animal, and every older record, has none, so their state and saves are unchanged. `tests/fixtures/pre-horses-save-v1.json` is a real save from the previous rules. The previous rules fingerprint is whitelisted in `data/save_migrations.json`.

## Escaping on horseback

- **A bonus, never a sure thing (Spencer).** Riding parties add `mounted_flight_bonus` (0.15, `wanted` in `data/crime_scenes.json`) to their escape odds; horse condition replaces ox condition as the speed term. The 85% escape cap stays, so even riders can be caught. In a crime scene's escape the bonus lowers the capture chance, down to the scene's floor at most.
- **Doubling up counts as riding** for a getaway: the flight plan always allows two to a saddle. A dash wears the horses as a hard day's ride at the fastest pace, sets the party doubling up when it had to, and can break the animals down.
- **Cut loose and ride.** A wagon party with horses enough for everyone two to a saddle, and no wagon already left behind, gets a third choice at an escape or a posse standoff: leave the wagon and ride. Nobody planned this, so the game grabs goods in a random order (food, bullets, clothing, medicine, salt; 30 to 100% of each while it fits), sheds food until the load rides, and leaves everything else, spare parts included, in the abandoned wagon at that spot. The journal lists what was grabbed. No extra day passes beyond the flight itself. At a stop, the wagon stands at the end of the leg that led there, so the party can come back for it.
- **Too few horses (Spencer).** With at least one saddled horse or mule but not enough for everyone, the choice opens a WHO RIDES? picker: two to a saddle, the leader always rides, and each companion can be taken along or left with the wagon. Those left behind become the abandoned wagon's guards (the wagon-guard camp), with two twists the party learns about on its return:
  - **Some slip away at once (Spencer: it depends on temperament and trust).** A companion at or below their breaking trust always goes. Otherwise Nervous (too frightened) and Self-serving (not reliable) companions always go unless Loyal; Loyal ones stay; anyone else goes with a chance of (60 − trust)%, so trusting companions stay (`left_behind_trust` 60).
  - **Pursuers may take in the rest** (`left_behind_taken` 0.4 each) when someone is chasing the party.

## Balance pass

See [HORSE_BALANCE.md](HORSE_BALANCE.md), which builds on the [historical and travel balance audit](HISTORY_AND_MOUNT_BALANCE.md) and [emergency travel calibration](EMERGENCY_TRAVEL_CALIBRATION.md). Forage strain is lower (sagebrush 1, highcountry and forest 0), all-mule strings take no forage strain, and load drag on daily distance starts at 75% of capacity for animal parties. Mounted bankers now arrive sooner than wagons (median 183 against 204 days). Packing is a lean, hungry option, and walking with no animals stays unviable by design.

## Validation

`tests/test_horse_flight.gd`: rider, wagon and walker flight odds, the escape cap, worn horses, doubled flight, the hard dash, who can cut loose, the scramble (what fits, the wagon left behind, no extra day, spare parts, the same seed scrambles the same way), saves after a getaway, the ride choice at a noticed theft at Fort Bridger and the save after it, no ride without horses, and the pre-horse-flight fixture, the riders picker (seats, toggles, back, saves, a rejected overfull pick), who slips away by temperament and trust, pursuers taking in those left, and the pre-riders fixture from an escape that could not yet ride.

`tests/test_horse_country.gd`: horse thieves (two horses, mules when there are no horses, one led horse behind a wagon), no thieves without animals, the night guard's effect and fatigue, saves, butchering horses and mules (condition, by hand), the Nez Perce traders (terms, day, stock, saves), regional sell prices with the resale cap, the pre-horse-thieves fixture, and the Travel and Supplies buttons.

`tests/test_horse_trade.gd`: post counter stock and prices, the resale cap, buying and selling, the lot menu, trader rolls that leave older meetings unchanged, trader sales, the stranding penalty, horse robbery demands, the wagon-needs-oxen rule, theft baskets (cash and wagon excluded, value and animal noise, haul limit, both outcomes, restitution, saves), the pre-horse-trade save fixture and the STEAL picker.


`tests/test_mounts.gd` (82 checks): store quotes with and without a wagon, packer departure, seat assignment, riding versus walking distance, mounted versus wagon first day, wear and rest, doubling up, sagebrush wear, breakdowns, led horses behind a wagon, abandoning the wagon with horses, save round trip, the real pre-horse save, wagonless events, the horse ford and swim (choice, mishaps, drowned animals, rising water, saves) and the travel view and ledger. Existing tests that priced the default outfit now include the $75 wagon; the store-layout check scrolls to the salt row in the longer list.

## Mount review fixes (October 24)

Initial walking and packing quotes now use the actual starting party health (85), through the same health and hauling rules as departure. Five walkers start with 170 lb capacity, including their 75 lb personal gear; mounted carrying limits are unchanged. Quotes remain independent of the current journey.

Exhaustion removes a horse or mule assigned to a saddle or pack, preferring working horses before working mules. Led-only stock and empty trains cannot suffer a carrying breakdown. Remaining stock can take over the lost animal pack, so losing an animal does not necessarily reduce capacity immediately.

The representative train is positioned inside the landscape with a gap between walkers and animals, keeping five walkers visible even with eight animals. Existing pixel assets are unchanged. These are correctness fixes. The subsequent [balance audit](HISTORY_AND_MOUNT_BALANCE.md) records separate current-rule evidence.


## Animal work and seasonal grazing (October 24)

The [total survival check](TOTAL_SURVIVAL_BALANCE.md) revises carrying strain: light cautious work can maintain condition on good grass, while full loads, haste, poor forage, waterless legs and winter remain costly. Pack-walking pace now affects animal work too. Rest recovery is limited by seasonal grazing; winter no longer restores summer condition per day. Doubling remains strenuous with any baggage. The 50% light-load threshold is authored, and actual animal size, rider/tack mass and grazing hours are not modeled individually. Prices and payload limits are unchanged. The matched study does not show a universal survival improvement.
