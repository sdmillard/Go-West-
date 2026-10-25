# River fishing: first playable slice

Open Hunt & forage. Fishing appears only when a known river stop on the current road is reachable. Within four road miles, choose walking or an available saddled horse. Beyond four and up to twelve, a fit available horse and saddle are required; walking is disabled and the simulation rejects a foot launch. Without the horse, the distant fishing button is hidden. An animal reserved by an away expedition is absent from stock and cannot unlock another trip.

These are authored one-way access radii, measured along the current route edge to its river endpoints. They are not surveyed paths or a complete river GIS. Waterless and active rafting legs, blizzards, snow and thunderstorms are excluded. Heading east uses the same road position. Reaching every stretch of the Platte or other nearby streams is future site-data work, rather than assuming water is everywhere.

## Play

Choose transport, then CAST. Wait for BITE and click STRIKE within the reaction window. Striking early wastes the cast; waiting too long loses the fish. Empty casts are possible. Each outing has a maximum of six casts and a 35-second play clock. Round-trip travel reduces the casts available, and winter lowers bite opportunities. Returning early still costs one trail day including meals.

The artwork integration uses the supplied original Aseprite riverbank, angler, bobber and splash sheets with native retro controls. Casting, striking and landing play once; waiting loops and a bite submerges the bobber until resolved. The angler follows the active leader's appearance. It remains a timing minigame, not a simulation of species-specific tackle or rod physics. This art change is staged in the review checkout pending visual approval.

Basic reusable line/hooks are included with household tools for this slice. No ammunition is required or consumed. Fishing does not yet add a separately priced tackle inventory, bait collection, broken hooks or modern reels. Actual stock, saddle, packed meals, health-dependent hauling, rider/tack weight and existing animal load/condition rules come from the shared outing model. Light work on good grazing can have zero condition loss; heat, poor grazing and heavier loads can increase wear.

## Food and camp work

Catch amounts mean edible fish weight, not whole fish. Each landed catch is authored at one to four pounds, with a generic 600 kcal per edible pound estimate and the existing approximate 1,000 kcal per food unit. This is a conservative game profile, not a nutrient assay or a promise of salmon at every stop.

The shared catch settlement applies physical recovery once, feeds the day's party meals, then fits remaining fish into actual cargo room. Fish use the existing fresh-food expiry and drying systems. They do not count as vitamin-C produce. Reports and the journal show actual food eaten, packed and left behind.

Camp > Companion tasks offers Fish nearby within walking range. A willing, sufficiently healthy worker spends the shared camp day fishing; nurses reserve their patients first. Food arrives after meals, within that worker's hauling and the party's cargo limits. The standing assignment rests when no water is reachable. Autonomous mounted fishing trips and fishing while the wagon moves are not included in this slice. Offscreen bite/hook probabilities are authored in data/fishing.json, not guaranteed harvests.

## Architecture and compatibility

simulation/fishing.gd owns access, quotes, seeded opportunities, reaction timing and companion catch calculations. ui/fishing_view.gd presents those rules; ui/fishing_scene.gd draws the supplied sprites without changing simulation state. The existing active-outing guard and food settlement are shared with hunting, without allowing rifle actions in fishing. Saving during the minigame is blocked; returning settles exactly one day and restores reserved animal/tack stock. Completed catches and companion assignments persist through existing JSON save data.

The previous ebf0f6da...952c rules fingerprint is accepted through the compatible migration whitelist. Old stock and active trips are not recalculated. Hunting keeps its existing default ammunition requirement and random stream when fishing is unused. Fishing shares the existing outing counter, so an actual fishing trip changes the later activity seed.

## Research and authored assumptions

- [NPS, Traveling the Emigrant Trails](https://home.nps.gov/articles/000/traveling-emigrant-trails.htm) identifies the Little Blue, Platte, Sweetwater, Snake and Columbia river corridors. This supports researching specific access locations, not treating all road miles as riverbanks.
- [NPS Idaho Auto Tour guide](https://www.nps.gov/cali/planyourvisit/upload/ID%20ATR%20IG%20Final.pdf) records emigrant fishing and local Indigenous fisheries. Access and techniques should remain site-specific.
- [Confederated Tribes of the Umatilla Indian Reservation, tribal history](https://ctuir.org/about/brief-history-of-ctuir/) describes seasonal fisheries, hook-and-line and other techniques, drying fish and trade. Existing Indigenous fisheries are not represented as unoccupied limitless resources. Paid fishing assistance, local access arrangements and purchasing fish should be researched in a later encounter expansion.
- [Oregon Department of Fish and Wildlife, trout techniques](https://myodfw.com/articles/how-fish-trout) informs the distinction between water access, a bite and hooking a fish. Its modern tackle recommendations are not a historical equipment list.

Distances, travel speeds, cast counts, reaction windows, seasonal factors, catch sizes and calories are explicitly authored estimates. This slice adds an alternative food activity; it does not establish survival balance or historical catch rates.

## Verification

Frozen runtime/test checkpoint e3c8324 passed all 74 Godot suites, including 55 focused fishing checks, plus 24 store and 20 current-policy outlaw journeys. Their actual journey rows exactly match the previous calorie-calibration version when fishing is unused. These are regression checks, not a fishing-enabled survival balance campaign.

Focused coverage includes walking/mounted boundaries, missing and away horses, missing saddles, unfit animals, weather, eastward heading, read-only previews, zero-ammo and zero-food attempts, finite casts, premature/late strikes, large time steps, exactly one elapsed day, stock reservation/return, condition wear under heat, fish mass/food save round trips, standing companion tasks and actual UI visibility/disabled choices. A genuine previous-version active-outrider save loads with stock, trip and RNG preserved.

Native setup, bite and return screens were visually reviewed in the game window. The initial slice used temporary scenery. [The art handoff](FISHING_ART_BRIEF.md) and [final asset contract](../art/aseprite/FISHING.md) describe the supplied artwork and its draft integration.

Full reports and final logs remain in parent .tools/fishing-*. Copies of both integration reports were SHA-256 verified against the isolated originals before cleanup. [Evidence manifest](fishing-evidence.json) records hashes and the rules signature. Player saves and preexisting diagnostic files are preserved.
