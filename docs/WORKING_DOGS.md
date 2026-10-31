# Working dogs

One optional adult farm shepherd travels with the party without taking a human slot. This is the first playable slice, not a training/breeding or dog-combat system.

## How to use

Buy **Working dog ($5)** during initial outfitting, or open **Camp > Dog** at a town or fort to buy one. A post has one offer for the journey; another post can supply a replacement after a loss. The new dog starts healthy, named BUDDY, assigned to camp watch. Camp > Dog lets you rename it and apply a standing job and feeding policy. No day passes for reviewing or changing the settings.

Jobs:

- **Camp watch:** a fit, fed dog can warn of approaching bandits, riders or horse thieves. A warning describes movement, not whether visitors are hostile. Horse-thief encounter weight is divided by two (minimum one), in addition to an existing human stock watch. It does not prevent attacks, win fights or guarantee safety.
- **Help hunt:** accompanies the leader's hunt. On an otherwise empty search it has a 35% chance of locating one normal regional animal. Each newly appearing rabbit gives one immediate 18% catch chance, requiring an actual rabbit still present and not already recovered. There is no wait timer and repeated frames never reroll a rabbit. It never kills deer or bison. The rabbit uses the species' normal 1-2 lb edible mass and 520 kcal/lb; it is part of normal retrieval, carrying, preservation and pelt calculations. No bullet is spent by the dog. With a fit hunting dog, Hunt remains available without ammunition. No catch is promised.
- **Rest:** reduces fatigue by 16 per day. Watch costs three fatigue per day; traveling without watch costs four; hunting costs twelve. At 75 fatigue work stops until the dog recovers. A watch dog at camp can pause automatically when exhausted and resume once eligible, but travel still tires it.

A dog needs condition 50+ (Fair or Good), fatigue below 75 and at least 75% of its previous meal to work. Resting at camp with at least 95% of its ration restores two condition; food deficits cost up to six condition per day. Waterless roads also cost three. These are authored game estimates with broad work thresholds, not measured historical illness rates.

## Food and risks

People eat first. The dog then uses **1.2 food units at rest** or **1.6 when traveling, hunting or watching**. One food unit remains 1,000 kcal. Food is removed from actual table portions, meat or staples; there is no free daily scrap allowance. Fruit, greens and vitamin-bearing portions are reserved for people. Uneaten fractions remain physical food with their original mass, expiry and vitamins. Dogs neither graze nor produce milk/eggs.

Feeding policies are share remaining provisions, reserve tomorrow's human meals, or do not share. A reserve policy can leave the dog hungry; it does not create food. Meals and condition appear in the journal and dog panel. Food-energy tracking abstracts diet quality and preparation; it is not a complete canine nutrition model.

Hunts have an authored 2% injury chance (20 condition lost) and still cost the normal outing day. River mishaps have an 8% dog-loss chance; surviving dogs lose ten condition and an already weak dog can die. Paid ferry passage has no swimming roll. Outcomes enter the journal, and dog losses appear in the crossing summary. No dog swimming animation is installed; the crossing scene does not draw a standing dog on water.

## Evidence and estimates

The [English Shepherd Club history](https://englishshepherd.org/breed-history/) supports the all-purpose farm-shepherd type as a visual/functional reference; it does not establish ownership by a specific 1848 wagon party. See [art references](DOG_ART.md).

Modern [MSD Veterinary Manual energy guidance](https://www.msdvetmanual.com/management-and-nutrition/nutrition-small-animals/nutritional-requirements-of-small-animals) uses RER = 70 x body kg^0.75 and activity multipliers as starting estimates. [AAHA guidance](https://www.aaha.org/link/5b8362407b574b699fa17834d8b03d58.aspx) gives intact-adult factors around 1.6-1.8 and light work 1.6-2.0, with wider working ranges. A nominal 20 kg dog's RER is approximately 662 kcal; the game's rounded 1,200/1,600 kcal allowances represent maintenance and sustained trail activity. Actual needs vary. The $5 purchase price, search/catch/warning chances, fatigue and accident rates are explicitly **authored estimates**, not recovered 1848 statistics. They are isolated in `data/dogs.json` where applicable; outfitting uses the same price.

## Persistence and scope

`simulation/working_dog.gd` owns the individual record separately from human party and dairy livestock. Saves retain name, condition, fatigue, feeding, job, daily/hunt markers and exhausted post offers. Rules fingerprints include dog data; the previous exact fingerprint is migrated, preserving supplies and adding no free dog. Malformed records are rejected. Dog rolls have deterministic purpose-specific streams; reviewing the panel does not consume random draws. Dog-free runs retain their original random streams and meals.

Only the **leader's hunts** use the dog in this slice. Detached hunters/outriders do not receive a phantom duplicate. Bonded ownership, morale, stock herding, training, breeding, combat and companion-led dog outings remain future work. No general survival or wage retuning is included.

## Validation

Focused suite `tests/test_dogs.gd`: 461 checks covering purchase costs, calorie/mass conservation, repeated partial meals, human priority, reserve/no-sharing policies, fatigue thresholds, rabbit-only catches, finite attempts, ammunition, search assistance, river/ferry outcomes, malformed rules/saves, migration, deterministic continuation and the real panel. Native screenshots were inspected for Camp > Dog, travel and the hunting minigame; local captures are `.tools/dog-panel.png`, `.tools/dog-travel.png`, `.tools/dog-hunt.png`.

All 101 suites in `test.ps1` pass (`.tools/dogs-full-tests.log`), including the final 461-check dog suite. Final UI checks also pass (`.tools/dogs-ui-final.log`). The independent focused run is `.tools/dogs-targeted-final.log`.

Usefulness testing and the appearance-trigger correction are recorded in [Dog usefulness results](DOG_USEFULNESS_RESULTS.md).
