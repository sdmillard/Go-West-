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
| beached_ship | place | Fort Kearny to Fort John | Three-master on the grass; salt pork for directions, or recruit Hollis Venn, the ship's carpenter |
| cul_de_sac | place | South Pass to Soda Springs | Eleven empty houses; rest a day on a lawn (people and team) |
| laundromat | place | either side of Soda Springs | $1 wash, health |
| round_hole | place | Fort Hall to The Dalles | Drop in bullets or food; something may come back |
| traffic_light | place | just short of South Pass | Wait a day, or run it (risk to team and party) |
| novablade | road | miles 60–1500 | The Novablade: the best blade in any tactical fight (see WEAPONS.md) |
| civet | road | miles 100–1200, needs a wagon | The 2002 Hanabi Civet tows the wagon 30 mi/day for 3 days (`fuel`) |
| elder_god | road | miles 150–1800 | Food offering for health, or refuse |
| vending_machine | road | miles 500–1500 | Takes no coin of yours; shake it |
| french_bison | road | miles 200–900 | Hunting advice (40 lb), will not be shot |
| phone_booth | road | miles 1150–1700 | Extended warranty |
| frog_rain | road | miles 100–1400 | 30 lb of frog legs |
| mirror_train | road | miles 700–1700 | Your own party, a week older, going east; trade |

Names are invented (Spencer: legally distinct names, so Novablade, Hanabi Civet, Taco Hut).

## Handoff: what to build next (November 1, 2026)

Spencer approved every item below. Build them in this order. Each one is its own PR, with tests in `tests/test_unhinged.gd`.

1. **Sailor companion (beached_ship) — implemented.** "Sign on the sailor" recruits Hollis Venn through `party_recruitment.gd`'s normal hiring path. The ship's carpenter uses the existing Carpentry background (there is no sailing or rope background). No wages or extra day; ordinary recruit clothing, personal gear, relationships and permanent traveler history apply. The traveler-record/contact limits still apply, and the sailor can join only once. Offer and recruited-party saves are covered in `tests/test_unhinged.gd`. **Next: item 2.**
2. **Cul-de-sac ending (cul_de_sac).** Add a choice "Move into a house" that settles the party there. Follow `docs/CABINS_AND_ENDINGS.md` and the settle code: add a new `state.settled` kind, an ending score factor in `data/scoring.json` (suggest the same as settling at a post), and an ending picture `location_ending_cul_de_sac`. That picture is for the Aseprite thread, or use the place picture until it exists.
3. **Laundromat slows disease.** "Wash everything" should also lower disease onset for some days, for example `state.clean_until = day + 14`. Find the daily disease onset in `party_health.gd` or the disease clocks and scale it down while clean. Keep it modest.
4. **The sphere on the horizon.** `game.oddities.in_view(game)` already lists `onyx_sphere` while the party is at a `visible_from` stop. Draw a big black disc on the travel horizon in `ui/trail_view.gd` (behind the ground layer), and in stop pictures, while it is in view. The sprite is for the Aseprite thread. "The compass points only at it" can be a journal line.
5. **Road encounter sprites.** Each road oddity has only text on the travel strip. Draw small sprites for novablade, civet (a beige sedan towing the wagon, used while `fuel` > 0; replaces `art/pixels/corolla.png`), vending_machine, french_bison, phone_booth, frog_rain (an overlay) and mirror_train (an east-facing copy of the party's wagon). Wire them in `trail_view.gd` `match encounter`.
6. **More oddities.** Add new entries to `data/events.json` with `"category": "absurd"`, `oddity`, `chance` (keep about 0.25) and placement fields. Use invented names only, never a real brand (Spencer: legally distinct, for example Taco Hut, Novablade, Hanabi Civet). Tell them in the same plain 1848 voice as everything else.

Rules to keep:
- Classic must deal nothing.
- The deal uses its own RNG (`hash("oddities:%d" % seed)`); never draw from `game.rng` in `deal`.
- Any edit to `data/*.json` rules changes the save fingerprint. Add the previous master fingerprint to `data/save_migrations.json` `economy_v1`.
- Run `./test.ps1`. Also run `tests/chaos_journeys.gd -- --unhinged`, which forces every oddity into each bot journey.
- Art: the place pictures are in `art/aseprite/scenes/oddities.lua`, written but not rendered yet; the Aseprite thread is rendering them for Spencer's approval. Register each one in `data/location_scenes.json` as `event_<id>`. The elder god is deliberately not pixel art (`elder_rift.png`, full window resolution).

Tests: `tests/test_unhinged.gd`. `tests/chaos_journeys.gd -- --unhinged` forces every oddity into each bot journey.
