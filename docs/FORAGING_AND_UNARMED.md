# Foraging, vitamin C and unarmed attacks

October 23, 2026. New values are explicit gameplay estimates pending a combined balance campaign.

## Foraging and scurvy

Options > Forage for greens and berries opens a confirmation. Canceling costs nothing. Searching takes one ordinary camp day, consumes meals, and advances weather, wages, illness and all other daily rules. No ammunition is required. Yield uses seeded RNG, regional habitat, monthly growing conditions and active walkers' health; broken legs prevent contribution. Snow, winter, rafting and waterless legs prevent gathering. A search can fail to produce a usable quantity. Carrying room limits the result.

Greens and berries supplement rather than replace bulk provisions: four physical pounds give one staple-equivalent food unit. They keep three days, cannot be processed with the meat-drying action, and retain their weight/type through saves, cargo packing and caches. The party shares meals; eating at least half a pound of tagged produce per living traveler counts as a vitamin-C day. This is a deliberately simple shared-party abstraction, not a milligram nutrition simulation or an identification guide.

The scurvy counter now checks **produce actually consumed** by the oldest-first meal ledger. Simply carrying it does nothing; spoiled or uneaten produce does nothing. Fresh/dried meat and unspecified staples no longer reset it. The legacy saved name `days_without_fresh` remains, but now means days without an adequate vitamin-C meal. Existing scurvy onset/recovery numbers are unchanged. Buying produce and preserving plants are future work; this first slice supplies it by foraging.

Historical basis: [NPS, Death and Danger](https://www.nps.gov/articles/000/death-on-trails.htm) identifies vitamin-C deficiency; [NPS, Fort Scott cooking](https://home.nps.gov/fosc/learn/education/cookhistory.htm) discusses frontier vegetables and wild onions; [NIH, Vitamin C](https://ods.od.nih.gov/factsheets/VitaminC/Consumer/) describes fruit and vegetable sources. These support the mechanism, not the game's yields, serving threshold, shelf life or seasonal rates.

## Unarmed attacks

Companion attack confirmations and venue crime menus offer an unarmed attack even with ammunition available. Shooting remains available when there are bullets. An unarmed attack uses no bullets, subtracts 25 percentage points from hit chance (companion minimum 5%), halves the fatal-hit probability, and adds a 45% chance of a 25-point wound to the leader. Existing companion reactions, witnesses, retaliation, news, pursuit, cargo limits and escape risks still apply. These odds are authored tuning, not historical combat statistics. A weak target can still be killed.

Venue assaults are distinct incident actions; companion attacks save the weapon used. Old attacks without weapon metadata remain gun attacks. Existing pre-change rules fingerprint is accepted for saves; inventory and cash are not repriced.

## Validation

`test_field_actions.gd` exercises cancellation, actual days/ammunition, deterministic forage, nutrition consumption, spoilage, carrying, save/load, and seeded companion/venue unarmed attacks. UI checks cover map zoom anchoring, panning bounds, stop hover after zoom, finding the wagon, fit and footer layout.
