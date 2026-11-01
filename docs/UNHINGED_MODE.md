# Unhinged mode

Spencer started this mode on November 1, 2026 (he also calls it surreal mode). The plan comes from [PROJECT_BRIEF.md](PROJECT_BRIEF.md), section 5. It is the same 1848 simulation, plus a few impossible things, told in the same plain voice as a broken axle. It should never become nonstop comedy.

## How a journey gets its oddities

Pick **UNHINGED** in the mode box on the bottom bar, then press **NEW JOURNEY**. The mode is saved with the journey.

The seed deals the journey its own assortment (`simulation/oddities.gd`, `deal`). Each oddity in `data/events.json` with `"category": "absurd"` has a `chance` of being dealt. The deal uses its own random stream, so it never changes the main game's dice. Same seed, same oddities. Over seeds 0 to 399, a journey gets about 4 oddities on average, and fewer than 2% get none.

- **Places** (`"oddity": "place"`) stand at one mile on one stretch of road: listed `edges`, or every main-road stretch in a `span`. `near` sets how far along the stretch (default a quarter to three quarters). They are marked on the trail map as teal diamonds with their `label`, and turn pale once visited. They meet the party before the stop ahead. A place on a branch the party does not take is simply missed.
- **Road encounters** (`"oddity": "road"`) wait at a guide mile inside their `miles` window. `"needs": "wagon"` holds an encounter back (to later in the road) while the party has no wagon.
- `visible_from` lists stops where a huge place can be seen from afar. `view_notes` are journal lines written on some days while it is in view (the Onyx Sphere).

Classic deals nothing. Every oddity happens at most once (it goes into `seen`).

## The oddities (November 1)

| Id | Kind | Where | What it does |
| --- | --- | --- | --- |
| taco_hut | place | Elm Grove to Fort Kearny | Eat ($2, health), sack of food ($3 for 30 lb), Fire Sauce packets |
| prairie_light | place | Fort Kearny to Fort John | Lighthouse: safe rest day, fish $1 for 20 lb |
| onyx_sphere | place | Weber River to Salt Lake to Hensley's Bear River ford | Seen from Bridger to the Raft River; touching it costs a day, may heal |
| beached_ship | place | Fort Kearny to Fort John | Three-master on the grass; salt pork for directions |
| cul_de_sac | place | South Pass to Soda Springs | Eleven empty houses; rest a day on a lawn (people and team) |
| laundromat | place | either side of Soda Springs | $1 wash, health |
| round_hole | place | Fort Hall to The Dalles | Drop in bullets or food; something may come back |
| traffic_light | place | just short of South Pass | Wait a day, or run it (risk to team and party) |
| novablade | road | miles 60–1500 | The Novablade, kept in the pack |
| civet | road | miles 100–1200, needs a wagon | The 2002 Hanabi Civet tows the wagon 30 mi/day for 3 days (`fuel`) |
| elder_god | road | miles 150–1800 | Food offering for health, or refuse |
| vending_machine | road | miles 500–1500 | Takes no coin of yours; shake it |
| french_bison | road | miles 200–900 | Hunting advice (40 lb), will not be shot |
| phone_booth | road | miles 1150–1700 | Extended warranty |
| frog_rain | road | miles 100–1400 | 30 lb of frog legs |
| mirror_train | road | miles 700–1700 | Your own party, a week older, going east; trade |

Names are invented (Spencer: legally distinct names, so Novablade, Hanabi Civet, Taco Hut).

## Still to do

- Art: place pictures (`event_<id>`, 432 × 150, wired in `main.gd` `_event_scene` once they exist in `data/location_scenes.json`), road sprites, the sphere on the travel horizon, and the elder god in a realistic, high-detail style that clashes with the pixel art (Spencer).
- Deeper versions Spencer approved: a sailor from the ship joins as a companion, settling in the cul-de-sac as its own ending, clean clothes slowing disease, the compass pointing at the sphere, and the Novablade as a blade in tactical fights.

Tests: `tests/test_unhinged.gd`. `tests/chaos_journeys.gd -- --unhinged` forces every oddity into each bot journey.
