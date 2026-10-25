# Livestock and individual animal condition

## Using it

Buy milk cows, milk goats, laying hens and poultry grain during initial outfitting or at an open post counter. Suggested outfits still include none. Open **Supplies > Livestock** or **Camp > Livestock / Working Team** for condition, remaining lactation, daily-care settings, feed, butchery and working ox selection. The separate grain drop control uses quarter-pound units. Animals can be sold at open posts; they are not assumed available at every passing trader.

Existing oxen, horses and mules now have individual condition records. New purchases append healthy animals without changing existing ones. Choose up to six working oxen with the checkboxes, or use **Hitch up to six fittest oxen**. Uncheck old animals before checking replacements; zero selected oxen stops wagon travel. The selected count controls pulling speed and load guideline. Spare oxen avoid working strain and can recover slowly when grazing permits; a whole rest day recovers individual animals, including unhitched ones. A lame-ox event damages one animal. The main ledger shows the working average; individual values appear in the livestock window.

Horses and mules retain individual condition through purchases and outing allocation/return. Outings take the fittest available stock and preserve its actual departure condition; returning wear does not heal the animals left behind. Existing mounted-travel wear is still driven by the shared load/condition model and applied to the present mounts; this does not add per-horse rider selection.

## Initial rules and their limits

| Purchase | Price | Full-condition spring output before travel/care reductions | Physical cost |
|---|---:|---|---|
| Milk cow | $75 | Up to 8 lb milk/day, 277 kcal/lb | Led; no pack capacity |
| Milk goat | $10 estimate | Up to 2 lb milk/day, 313 kcal/lb | Led; no pack capacity |
| Laying hen | $0.50 estimate | About one egg per two good days, ~72 kcal/egg | 4 lb bird plus 6 lb coop per six hens |
| Poultry grain | $0.01 per quarter lb, estimate | Each hen consumes a quarter lb/day | Actual grain weight |

Milk animals are adults already in milk, with an authored 180 days of remaining lactation. Output tapers during the last 60 days; there are no calves, kids, breeding or free restarts of lactation. This assumes offspring are no longer taking a share of the purchased animal's milk. Dairy animals graze/browse instead of eating the party's staple-food units. Existing waterless-road hazards, season, hard travel, inadequate care and poor condition reduce yield or condition; zero condition loses the animal. There is no separate measured water inventory or detailed forage ecology.

Daily care is a bounded household chore: 0.4 hours/cow, 0.2/goat, 0.025/hen; at most half an hour per healthy available person, capped at two hours on ordinary days or four on rest days. Patients being nursed, their nurses and companions on other assigned work cannot also provide this care. Outing members and a leader engaged in a camp action are excluded. Chores add fatigue; under-staffed herds receive partial production. These labor rates, limits, production curves and condition losses are authored tuning, not historical measurements. Hens still consume prepared grain if milking/collection care is switched off. No grain means no egg output and declining hen condition.

Milk and eggs use edible mass and actual calories. Small egg lots accumulate as physical perishable products before conversion; fractional eggs never generate a minimum food unit. The combined products round once (4.49 -> 4; 4.5 -> 5) to the existing 1,000 kcal units. The whole-unit inventory still introduces rounding error. Milk has a one-day storage window and eggs a fourteen-day game window; these are abstractions, not food-safety guidance. Mixed lots use the earliest expiry. A party may eat today's production before storing the remainder, even if its packs start full. Uneaten excess is left behind with a history entry. Unconverted products also weigh something and can be discarded in the livestock panel.

Dairy/egg batches cannot pass through the meat-drying action and do not reset the game's fruit/greens vitamin-C requirement. Butter/cheese processing is deferred. Live animals, coops and grain remain with the party when leaving a wagon; grain is not a standard cache/outing supply. Review pack weight and discard grain/products when necessary. This initial version does not provide a general livestock abandonment, breeding, pet or dairy-processing system.

Post supply and buying demand are finite per market. Purchases/sales use the existing counter visit/day and cash rules. Animal sale price is half local purchase price; it is not an appraisal of breed or individual condition. Regular ferries add an authored ten cents per milk cow/goat. Barlow tolls include them at the existing per-head rate. Paid ferries retain existing safe-passage behavior; a mishap while fording, floating or using a seized ferry can lose livestock, recorded in crossing history and the journal. These probabilities are estimates.

Emergency butchery permanently removes one animal and takes a day. Cow/goat gun slaughter costs one bullet; hand slaughter uses the existing 35% injury convention. Routine hen butchery needs no bullet and does not inherit cattle-handling injury risk. Actual edible yield depends on condition, converts by a labeled nutrition proxy and respects cargo after the camp meal. Milk animals do not replace trained draft oxen.

## Historical and biological evidence

- [End of the Oregon Trail, outfitting](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) describes milk cows and wagon-mounted coops and gives a broad $70-75 milk-cow estimate for the 1840s/early 1850s. It explicitly cautions that its price list is not a quotation for one town/date. Goat/hen/grain prices above remain estimates.
- [BLM education guide](https://www.blm.gov/sites/default/files/learn_interp_nhotic_edguide.pdf) describes family milk cows as dietary supplements. [BLM student reading](https://www.blm.gov/sites/default/files/docs/2025-12/nhotic-student-pre-reading.pdf) includes goats and chickens among emigrants' livestock. [NPS emigrant travel](https://home.nps.gov/articles/000/traveling-emigrant-trails.htm) describes night grazing and butter-making using wagon motion. Presence is supported; exact trail yields are not established.
- [USDA raw dairy/egg tables](https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR/SR28/reports/sr28fg01.pdf): whole cow milk about 61 kcal/100 g, goat milk about 69 and whole raw egg about 143; the game rounds their per-pound values. Added vitamin D in a reference entry does not assert fortification on the trail. Slaughter energy/yield figures are broad species/condition proxies.
- [Cornell backyard chickens](https://washington.cce.cornell.edu/agriculture/livestock/backyard-chickens) and [Missouri Extension hen budget](https://extension.missouri.edu/publications/g741) support modest daily laying and roughly quarter-pound daily feed. [Wisconsin seasonal husbandry](https://livestock.extension.wisc.edu/articles/preparing-for-winter/) describes reduced laying with short days. Modern husbandry guides inform constraints, not modern breed productivity transplanted into 1848.
- [UC dairy animals](https://ucanr.edu/site/small-acreage-landowners/dairy-animals) discusses lactation, dry periods and increased water demand. [NASS dairy history](https://data.nass.usda.gov/Publications/Trends_in_U.S._Agriculture/Livestock_and_Dairy/index.php) shows even 1944 annual milk yield was far below modern industrial averages. Our trail yields are deliberately authored conservative allowances, not a reconstructed breed/lactation dataset.

## Artwork and compatibility

Spencer supplied and approved livestock-art-drafts.zip. Original Lua source is art/aseprite/scenes/livestock.lua; verification is art/aseprite/verify_livestock.lua. Native PNGs are installed; reproducible editable files regenerate into ignored output. Travel/camp/crossing sprites and ledger icons use the supplied frame registration. Walking crossing rows have no water pixels. No proprietary artwork is included.

Genuine pre-livestock and older saves retain supplies, cash, elapsed time, random streams and old condition. Legacy shared condition is initially assigned uniformly to the existing animals. They receive no new livestock, feed or health. New animal/selected-team/product records are saved and validated. See [validation protocol](LIVESTOCK_VALIDATION_PROTOCOL.md); final results will be recorded after frozen testing. Farmer balance is not declared solved.
