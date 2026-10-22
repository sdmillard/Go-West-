# Oxen, grazing and emergency meat

October 22, 2026. **Options → Provisions / Cargo** now offers shooting/butchering a spare ox or butchering by hand. A review dialog shows the permanent loss, remaining team, food, ammunition/time and possible injury before committing. Cancelling spends nothing.

- Shooting costs exactly one bullet and one camp day per animal.
- Hand butchering uses the assumed household tools and no ammunition. It takes a day and has an authored 35% chance of wounding a living traveler; an existing wound may worsen. Guns, knives and a hatchet are assumed equipment, rather than separately priced purchases.
- You may now slaughter the last ox. With one, the wagon moves very slowly; with none, wagon travel stops until a replacement is obtained or the wagon is abandoned. Smaller teams also have reduced working-load guidelines. See [walking and recovery](WALKING_AND_RECOVERY.md).
- A healthy-team animal supplies 400 lb usable fresh meat. The shared team-condition proxy lowers this toward 200 lb for a severely worn team. These are game estimates, not the animal's live weight or an authenticated historical yield table.
- All usable meat is recovered at camp; the hunting retrieval cap is bypassed. It may overload the wagon. Today's meals can use the meat, so an empty camp can benefit immediately. It then enters the normal fresh-food, spoilage, drying/salt and cargo systems. The existing 100-lb processing batch size means a whole ox cannot all be preserved in one action.
- Oxen do not consume human rations. Grazing is assumed; pasture, hay, water requirements and herd-size pressure on forage are not yet separate systems. Keeping many animals therefore has fewer upkeep costs than a fuller historical model would require.

Four oxen is the normal pulling baseline; five give +5% speed and six or more +10%, with no extra wagon cargo allowance. The suggested outfit remains six. See [team-size testing](TEAM_SIZE.md) for the current matched survival study; older results below retain their original rule signatures.

Replacement oxen already exist in **Trade**: $30 for one animal or 100 ration-lb of food in barter, with a day and meals consumed. Starting animals remain $20 each. These are authored game prices and passing-wagon availability is an abstraction, not a guarantee of stock everywhere on the historical route.

## Source comparison

The supplied 1985 manual describes buying supplies and trading along the way. The inspected BASIC version models animal investment/quality rather than our counted herd; its food formula is a party ration deduction, not a per-ox feed budget. We have not recovered a complete 1985 feeding algorithm.

The extracted strings from the supplied 1993 Windows game explicitly include an ox-slaughter offer, a meat-award message and a no-oxen/trade-for-a-team notice (`research/local/windows-game/string-tables.json`). This confirms that version presented the choice; strings alone do not establish its yield, timing, ammunition or risk formula. Our hand-tool branch is a new gameplay choice.

[Palmer's 1847 outfit account](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), pp. 258–262 in the 1906 reprint, describes cattle relying on prairie grass and recommends reserve teams. It supports grazing as the starting model, rather than charging oxen the party's flour/meat ration.

[Wisconsin Extension](https://livestock.extension.wisc.edu/articles/how-much-meat-should-a-beef-animal-yield/) distinguishes live weight, carcass weight and take-home product; its modern example yields 481 lb from a 1,200-lb finished animal. That is a scale/reference check, not evidence that an 1848 working ox gave exactly 400 lb. The condition-to-yield curve, one-day task, last-pair restriction and 35% hand-injury chance are explicitly authored tuning. No real-world slaughter procedure is provided.

## Verification and balance

The focused oxen suite passes 23 checks: unchanged human ration demand with a larger herd, replacement purchase, exact ammunition/day use, full meat recovery and overload, same-day emergency meals, preservation, worn-team yield, last-pair protection, no-ammunition rejection, hand-tool success/injury cases, encounter/landmark handling, save continuation, actual previous-version preservation-save migration and UI review/cancel/confirm. The supply menu and confirmation were rendered and inspected. The complete existing suite also passes.

The archived, last-pair-protected 360-journey experiment used all three professions, March/May/August departures and seeds 0–19. Both policies hunt at 65% scripted center aiming, use mixed rations/care/rest and preserve with salt when possible. The spare-ox policy additionally shoots one spare animal below 90 food before buying provisions, kept the pulling pair, and preserved the meat. It does not buy animals solely to slaughter or use hand butchering.

| Farmer outcome, 60 runs each | Hunting/preservation | Spare-ox option |
| --- | ---: | ---: |
| At least one traveler arrives | 54 | 55 |
| All five arrive | 22 | 50 |

The new option often protects companions, while losing reserves, slowing a smaller team, using time/ammunition, and risking wasted meat. This is a strong emergency resource and may need further economy/forage calibration. It is not a historical casualty estimate or a proof of optimal play. The hand-injury branch has focused tests; it was not used by these journey policies.

[Raw 360 journeys](reserve-team-oxen.json). Reproduce through the bundled Godot console with `--headless --path . --script tests/full_trail_balance.gd -- --oxen --label=reserve-team`, using project-local APPDATA as in `test.ps1`. Earlier economy/preservation archives remain unchanged.

The current focused oxen suite has 33 checks. The older 23-check and last-pair balance figures above are snapshots; [walking and recovery](WALKING_AND_RECOVERY.md) documents the updated rules and validation.
