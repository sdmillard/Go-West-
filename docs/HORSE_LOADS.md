# Horse loads and whole-party wagon hunts

The outfit screen now offers a normal load, a heavier return, leading the mount home, or leading it home heavily loaded. Choose these under **Hunt & Forage > Outfit a hunting trip**. A leader outing still takes one shared day; a companion riding outing can take one to three days. The selected return mode is remembered, but trips never automatically repeat.

## Physical accounting

All numbers below are authored game assumptions, not precise 1848 measurements. The horse and mule each have a 250 lb working total, a 375 lb emergency total ceiling, 25 lb fitted tack and a standard 150 lb rider allowance. Tack includes fitted bags; unused saddles, pack saddles and bags are physical cargo (25, 25 and 2 lb). Rider body weight is not freight. Personal equipment, clothing, reserve food and ammunition consume freight room.

| One animal | Working freight | Allowed with heavy order |
| --- | ---: | ---: |
| Riding with bags | 75 lb | 150 lb |
| Riding without bags | 50 lb | 125 lb |
| Proper pack saddle, no rider | 225 lb | 300 lb |
| Led with a riding saddle, no rider | 225 lb | 300 lb |

The secured-load allowance and the total physical ceiling both apply. Riders do not also provide a walking backpack. Walking participants add their own health-dependent allowance; the existing 200 lb human retrieval ceiling caps people only, with animal capacity added separately. Personal gear is included within the allowance rather than supplied as free extra room.

Good and Fair retain full human carrying. Poor and Very Poor reduce it; a broken leg removes human hauling. These previously approved health breakpoints are unchanged.

Loading above the working allowance requires an explicit heavy order. The actual rider/tack/cargo load slows movement and adds wear; merely selecting permission does not strain an empty animal. Leading frees rider weight but uses pack-train walking pace. Loaded outriders use the same physical accounting, terrain, weather and seasonal movement effects when following. A horse can give out; the actual animal is lost and surviving tack is recovered with its hunter rather than duplicating stock.

**Travel > Lead animals / Allow heavy load** applies the same choices to a party traveling without a wagon. Supplies > Transport shows current freight, working/allowed limits and the animal rider/tack/cargo breakdown. Drop supplies includes unused tack. Old saved journeys and old three-field outing preferences continue to load; optional orders are not invented during migration.

## Wagon hunt

Choose **Bring wagon - everyone** for the leader. Everyone currently present joins, including injured passengers; this can be two surviving travelers rather than the original five. Away hunters and wagon guards are not present. Only willing, physically capable people contribute as hunters. A functioning wagon and ox team, ammunition and spare wagon cargo room are required.

Woodland, plains and sagebrush hunting grounds currently permit wagon access; forest and high country do not. This is an explicit accessibility abstraction, not a road network inside each hunting map.

The hunt uses actual wagon ammunition and cargo, takes one day and one party meal, and works the ox team. Camp jobs, nursing and their material costs are suspended for that day; standing assignments remain for subsequent days. Food returned is still subject to actual wagon space, spoilage and preservation.

A noisy wagon approach has an authored 35% chance of scaring away each potential animal before it appears. Some hunts remain good, some become empty. Noise does not change shot accuracy, animal health, speed or meat yield. Its independent seeded rolls keep the same underlying encounter opportunities comparable with ordinary hunts. This is gameplay tuning, not a measured historical rate.

## Hunting art correction

Deer antlers previously extended above their 22-pixel animation cells, by up to six pixels during a jump. Rabbit ears/feet also reached adjacent cells. Padded sheets now contain complete frames; visual padding is separate from the original shot targets. Sprites and cover spawn on the foreground ground, and hunter movement remains there. The sky is drawn before the animals.

Original pixel art is rebuilt through the Aseprite Lua pipeline. No proprietary art is used.

## Evidence and limits

[University of Minnesota Extension](https://extension.umn.edu/agriculture/animals-and-livestock/horse/guidelines-for-weight-carrying-capacity-of-horses) discusses rider and tack together, approximately 20% body weight as a starting point for light riding horses, and effects of conformation, fitness, duration and terrain. The [Forest Service packing guide](https://www.fs.usda.gov/t-d/pubs/pdfimage/95231202.pdf) provides a practical pack-stock reference; packing is a different use from carrying a rider. [Marcy's 1859 Prairie Traveler, chapter III](https://www.kancoll.org/books/marcy/machap03.htm) is period context for pack care and travel, later than the game's 1848 setting.

These sources inform the distinction between riding, packing and overload. They do not establish the game's fixed animal sizes, rider allowance, strenuous ceiling or noise rate. Whole-route balance with dispatched hunters and deliberate heavy loads remains a separate study; ordinary journey bots do not exercise every new mode.

The focused suite covers physical budgets, health boundaries, quotations without side effects, load wear/speed, save migration, lost animals and recovered tack, whole-party membership, interrupted chores, costs, accessibility, noise and ground placement. Native Godot screens were inspected.
