# Unhinged mode

Spencer started this mode on November 1, 2026 (he also calls it surreal mode). The plan comes from [PROJECT_BRIEF.md](PROJECT_BRIEF.md), section 5. It is the same 1848 simulation, plus a few impossible things, told in the same plain voice as a broken axle. It should never become nonstop comedy.

## How a journey gets its oddities

Pick **UNHINGED** in the mode box on the bottom bar, then press **NEW JOURNEY**. The mode is saved with the journey.

The seed deals the journey its own assortment (`simulation/oddities.gd`, `deal`). Each oddity in `data/events.json` with `"category": "absurd"` has a `chance` of being dealt. The stories are authored entries; the seed selects and places them rather than writing new stories. The deal uses its own random stream, so it never changes the main game's dice. Same seed and catalog, same oddities. With the expanded catalog, a journey gets about 5 oddities on average. New entries are appended so the older encounters retain their seeded deals and locations.

- **Places** (`"oddity": "place"`) stand at one mile on one stretch of road: listed `edges`, or every main-road stretch in a `span`. `near` sets how far along the stretch (default a quarter to three quarters). They are marked on the trail map as teal diamonds with their `label`, and turn pale once visited. They meet the party before the stop ahead. A place on a branch the party does not take is simply missed.
- **Road encounters** (`"oddity": "road"`) wait at a guide mile inside their `miles` window. `"needs": "wagon"` holds an encounter back (to later in the road) while the party has no wagon.
- `visible_from` lists stops where a huge place can be seen from afar. `view_notes` are journal lines written on some days while it is in view (the Onyx Sphere).

Classic deals nothing. Every oddity happens at most once (it goes into `seen`).

If the authorities take a traveler carrying the Novablade, it is held with their other arms and returned on release. Saves accept the single blade both during custody and in the completed hearing record; this also repairs loading the detention saves rejected before the validation fix.

## The oddities (November 1)

| Id | Kind | Where | What it does |
| --- | --- | --- | --- |
| taco_hut | place | Elm Grove to Fort Kearny | Eat ($2, health), sack of food ($3 for 30 lb), Fire Sauce packets |
| prairie_light | place | Fort Kearny to Fort John | Lighthouse: safe rest day, fish $1 for 20 lb |
| onyx_sphere | place | Weber River to Salt Lake to Hensley's Bear River ford | Seen from Bridger to the Raft River; touching it costs a day, may heal |
| beached_ship | place | Fort Kearny to Fort John | Three-master on the grass; salt pork for directions, or recruit Hollis Venn, the ship's carpenter |
| cul_de_sac | place | South Pass to Soda Springs | Eleven empty houses; rest a day on a lawn, or move into one and end the journey |
| laundromat | place | either side of Soda Springs | $1 wash, health, 20% less spontaneous illness onset for 14 days |
| round_hole | place | Fort Hall to The Dalles | Drop in bullets or food; something may come back |
| traffic_light | place | just short of South Pass | Wait a day, or run it (risk to team and party) |
| novablade | road | miles 60–1500 | The Novablade: the best blade in any tactical fight (see WEAPONS.md) |
| civet | road | miles 100–1200, needs a wagon | The roof-loaded 2002 Hanabi Civet replaces one wagon; 90 mi/day for 3 driving days, then surviving oxen can pull it |
| elder_god | road | miles 150–1800 | Food offering for health, or refuse |
| vending_machine | road | miles 500–1500 | Takes no coin of yours; shake it |
| french_bison | road | miles 200–900 | Hunting advice (40 lb), will not be shot |
| phone_booth | road | miles 1150–1700 | Extended warranty |
| frog_rain | road | miles 100–1400 | 30 lb of frog legs |
| mirror_train | road | miles 700–1700 | Your own party, a week older, going east; trade |
| prairie_lift | place | Fort Kearny to Fort John | A lift standing in the grass; a real day of rest and meals, or leave it alone |
| parcel_cart | road | miles 250–1100 | A parcel in your own handwriting; $2 for one clothing set, or refuse |
| moon_cart | road | miles 1100–1750 | Mind a small moon on a handcart for a day and meals; earn 50 cents |

Names are invented (Spencer: legally distinct names, so Novablade, Hanabi Civet, Taco Hut).

## Handoff: what to build next (November 1, 2026)

Spencer approved every item below. Build them in this order. Each one is its own PR, with tests in `tests/test_unhinged.gd`.

1. **Sailor companion (beached_ship) — implemented.** "Sign on the sailor" recruits Hollis Venn through `party_recruitment.gd`'s normal hiring path. The ship's carpenter uses the existing Carpentry background (there is no sailing or rope background). No wages or extra day; ordinary recruit clothing, personal gear, relationships and permanent traveler history apply. The traveler-record/contact limits still apply, and the sailor can join only once. Offer and recruited-party saves are covered in `tests/test_unhinged.gd`.
2. **Cul-de-sac ending (cul_de_sac) — implemented.** "Move into a house" ends the journey with `state.settled.kind = "cul_de_sac"`, using the ordinary settlement factor (0.6). The ending screen uses `ending_cul_de_sac`, currently sharing the place picture until a dedicated ending picture exists. No extra day or supplies; the party stays at its encounter mile and saves there.
3. **Laundromat slows disease — implemented.** "Wash everything" keeps its $1 cost and health benefit and sets `state.clean_until = day + 14`. The next fourteen daily spontaneous-onset rolls use a 0.8 multiplier, including the expiry day; day fifteen returns to normal. This is a modest authored Unhinged benefit, not a medical model. Existing illness courses, contagion, wound infections and scurvy are unchanged. The optional expiry saves and loads; older saves gain no free protection, and Classic cannot use it.
4. **The sphere on the horizon — implemented.** `ui/far_sphere.gd` draws it on the travel horizon and in stop pictures while `onyx_sphere` is in view, sized by map distance from the party (`main.gd` `_sphere_look`). "The compass points only at it" can still be a journal line.
5. **Road encounter sprites — implemented.** `trail_view.gd` reuses the existing Novablade, beige sedan, hunting bison, wagon and traveler art. Only the vending machine, phone booth and four-pose frogs are new, approved Aseprite sprites (`scenes/road_oddities.lua`). Frog rain shares the weather clouds, emerges from their lower edge and hops on the ground; it never rolls simulation dice. The mirror train reflects the party's existing wagon and traveler palettes eastward.

   **Civet revision (Spencer):** the sedan replaces one wagon rather than towing it. The ordinary vehicle ledger still handles capacity, repairs, drivers, caches and sales; optional `state.civet_wagon_id` identifies the replaced slot. The running car does not inherit the old wagon's broken part. Fuel gives three powered travel days, including the final day with no oxen. After fuel expires the sedan remains, uses normal ox-drawn movement, and stops if no team survives. Its identity survives saving and caching; buying a different wagon does not recreate it. The original `corolla.png` filename is retained to reuse approved artwork, not as an in-game name. **Next: item 6, more oddities.**

   **Faster, loaded Civet:** powered travel is now 90 miles per driving day. `civet_drive_day` and `civet_miles_left` retain that day's unused distance across ordinary stops, including after the final fuel unit is committed. Continuing the same drive uses no additional day, meals or fuel and gets no extra daily random encounter roll. Resting, a paid crossing or another activity that advances the calendar expires the unused allowance. The approved `civet_loaded.png` shows sacks, bedrolls, a crate and blanket lashed to the roof from acquisition onward, powered or ox-drawn; the roadside car before acquisition stays empty. The wagon never returns to replace the car when fuel ends.
6. **More oddities — first batch implemented.** The lift, parcel cart and moon cart are appended to `data/events.json`, each at chance 0.25, with no real brand names. The lift has a route span and map label; the carts have road mile windows. They use the existing text encounters and choice effects. Declining grants nothing, paid choices enforce their cost, and waiting costs actual days and meals. Tests cover their offers, accounting, saves, seeded compatibility and one-use behavior. Further batches can use the same fields and plain 1848 voice; this completes the original handoff's six steps.

Rules to keep:
- Classic must deal nothing.
- The deal uses its own RNG (`hash("oddities:%d" % seed)`); never draw from `game.rng` in `deal`.
- Any edit to `data/*.json` rules changes the save fingerprint. Add the previous master fingerprint to `data/save_migrations.json` `economy_v1`.
- Run `./test.ps1`. Also run `tests/chaos_journeys.gd -- --unhinged`, which forces every oddity into each bot journey.
- Art: the 8 place pictures in `art/aseprite/scenes/oddities.lua` are installed (`art/pixels/event_<id>.png`) and registered in `data/location_scenes.json`. The elder god is deliberately not pixel art (`elder_rift.png`, full window resolution).

Tests: `tests/test_unhinged.gd`. `tests/chaos_journeys.gd -- --unhinged` forces every oddity into each bot journey.
