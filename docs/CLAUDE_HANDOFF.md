# Claude handoff: Westward, Probably

Updated with every merged pull request, so a session cut off at any point loses nothing. Last update: October 22, 2026, with the peaceful emigrant camp PR (#18). **Continue the existing project; do not restart it.**

## Where things stand

- **Repository:** https://github.com/sdmillard/Go-West- (default branch `master`). Spencer's local copy is `C:\Users\Spencer\Projects\Oregon Trail`. `launch.cmd` fast-forwards a clean `master` before playing (PR #10).
- **Merged crime work, in order:**
  1. Named staff witnesses (#1).
  2. Situational odds (#2).
  3. Witness reports (#3).
  4. More venues (#4).
  5. Fort Kearny (#5).
  6. Passing traders (#6).
  7. Emigrant camps (#7, carried into master by #8).
  8. Companion bonds and attacks (#9).
  9. Remains ledger (#11).
  10. Butchering, human meat and meals (#12).
  11. Fort Kearny pursuit, plus a care/service audit (#13).
  12. Departed companions tell what they saw, plus the outlaw journey sampler (#14).
  13. Gravestones over companions buried on the trail (#15).
  14. Betrayal at low trust (#16, record version 8).
  15. Peaceful emigrant camp visits (#18).
- **Crime record:** version 8, in `simulation/crime_system.gd`. Each version has an `upgrade_vN` step, chained in `upgrade()`. Remains, human food and meals live in `simulation/remains.gd`, as static functions on `game.crime.record`.
- **Design reference:** `docs/STORE_CRIME_SLICE.md` describes every implemented mechanic, its tuning and its save rules. `docs/CRIME_AND_CANNIBALISM_ROADMAP.md` holds the plan.

## Next work

Roadmap phase 6 (information spread, pursuit, service audit):

- Traders and travelers carry news. This is already modeled as report travel delays, and companions' tales use the same delays.
- Done: `tests/outlaw_journeys.gd`, 20 full-route criminal and lawful journeys with no stuck encounters (0 errors on October 22). Rerun it after crime changes; it takes a few minutes.

Smaller follow-ups noted along the way:

- Done: a gravestone in the memorial book for graves dug on the trail (#15).
- Done: betrayal at low trust: night theft, or a night attack on the leader (#16).
- Done: a peaceful emigrant camp visit: trade, nursing, news (#18).

After phase 6 comes the full balance campaign (roadmap phase 7), which is not started.

## Working rules

- Spencer wants autonomous progress with few questions. Merge each PR yourself once the full local suite passes. The repo has no CI.
- Run the full suite in a clean worktree (Linux: Godot 4.5.1 headless, every suite listed in `test.ps1`, then `tests/store_crime_journeys.gd`). Never commit the regenerated `docs/first-store-journeys.json`, `research/local/` or `.tools/`.
- Any change to `data/*.json` rules changes the save fingerprint. Add the previous master's fingerprint to `economy_v1` in `data/save_migrations.json`. Compute it with `preload("res://simulation/save_store.gd").new().fingerprint()` run on that master.
- New scripts get a Godot `.gd.uid` file. Commit it.
- Saved JSON numbers come back as floats. Compare saved ids with `int()`, not `in`.
- Claude can't see Spencer's 5-hour usage meter. Keep this file current with each merge, and stop at a clean point if Spencer says the limit is near.

## Design commitments (from Spencer)

- Crime and cannibalism are part of Classic/historical mode.
- Outcomes are chance-based. Experience lowers risk and gives a small stealth bonus; it never adds evidence.
- Discovery depends on the scene: witnesses, venue and soldiers.
- Evidence and consequences ship with each crime.
- No morality meter and no hunger gate. Killing, butchering, eating and deceiving are separate decisions. Cannibal removes only the objection to eating.
- The setting is 1848. Fort Kearny is the only army post on the route; Laramie and Bridger are private posts.

## Codex historical balance review (October 22, 2026)

Before phase 7, read `docs/HISTORICAL_BALANCE_BASELINE.md`. Rechecked period guide evidence and public historical interpretation against current JSON and daily accounting. No gameplay or save rules changed. Main open issue: stable definition of staple-equivalent meal value versus physical hunted meat; 1,700 starting units last five travelers 113 complete days at the departure default filling ration, or 170 at meager. Team-size and cargo advice differs between sources; test four/six/eight head rather than declaring one universal historical minimum. Prices and wages retain their documented date/place/board limits. The latest saved lawful sample has four arrivals but one death, so earlier 'all intact' prose is stale. This is a research baseline, not completion of the full balance campaign. Existing local Aseprite edits were left untouched.

## Food price decision and diagnostic (October 22, 2026)

Read `docs/HISTORICAL_COST_AND_SURVIVAL_AUDIT.md` and `research/FOOD_PRICE_AUDIT.json`. The user explicitly accepts plausible thematic estimates where evidence is inconclusive, and does not want starting funds inflated to erase hardship. Opening food is now five cents (formerly six), an authored mixed-basket estimate informed by dated 1850 frontier prices; it is not an exact 1848 Independence tariff. Funds remain $600/$900/$1400; suggested cart is $375.60 with $224.40 farmer cash left. Prior fingerprint 26170f01a650385ddc81ef0e899a22c397b899dc44e467e8b00f95370f5b7303 migrates without repricing existing cash or inventory. The two 108-journey diagnostics are preserved separately. Five-cent farmer arrivals are 27/36, intact19; affluent rows repeat nonhunting behavior and are not independent food-strategy evidence. Zero selected invariant/setup/save errors; baseline includes one unresolved action-limit outcome, comparison includes two year limits. Investigate policy stall, accumulated rest/service/preservation days and physical meat versus food-value accounting next. Full phase7 and human playtest remain pending. Run the full suite before handing work back. Aseprite changes from other ongoing work remain untouched.

Validation for this checkpoint: all 29 suites in `test.ps1` passed; historical economy116 checks. Both diagnostic archives have108 rows. No art files were edited by this task.

## Journey policy and time audit (October 22, 2026)

Read `docs/JOURNEY_TIME_AUDIT.md`. Fixed the old toll fundraising policy's menu-index assumption: Back at an absent trader was falsely counted as a sale, causing a no-time loop. `tests/journey_trade_policy.gd` now selects actual cash-for-goods effects or real waiting; exhausted sales/refusals block explicitly. Added10 checks in `tests/test_journey_policy.gd` and the suite to `test.ps1` (30 suites pass). Diagnostic03 repeats108 current-price setups:99 arrived,7 lost,2 year limits; no selected errors, no outcome/survivor changes versus02, elapsed days reconcile. Preserving farmer runs spend about10 processing days,18-20 hunting days and36-39 explicit rest days; only8 of248 batches are below30 units. No game-rule change justified yet. The former six-cent capped setup was explicitly replayed:6 real wait days,10 actual sales, starvation loss on day254; no loop. Original archives retained. Next isolate rest/care decisions and food-value assumptions. New art remains other ongoing work.

## Rest/care decision study (October 22, 2026)

Read `docs/REST_AND_CARE_AUDIT.md` and `docs/rest-care-diagnostic-01.json`. Ran128 matched public-action journeys: reference, later rest, earlier care and combined; farmer/carpenter, April/May, dry/salt, seeds0-3. Study thresholds are now configurable, with unchanged defaults and exact parity against16 archived reference journeys. Reference rest counts:820 total,642 health-triggered,178 ox-triggered,4 fatigue-triggered (overlap allowed). Later rest had12/16 farmer arrivals all intact versus reference12/16,10 intact. Earlier care had13/16 farmer arrivals but only8 intact and28 deaths; affluent results differ. No dominant policy or justification to change game recovery rules. Keep reference defaults and game costs/rates unchanged;128 runs had zero selected invariant/save/policy errors. Next food value versus physical meat, then hired/emergency cohorts. Full phase7 remains pending. Existing art and actual player saves left alone.

## Seasonal pressure implemented (October 22, 2026)

Read `docs/SEASONAL_PRESSURE.md`. New authored monthly ground drag affects wagon/walking travel, more strongly in uplands; winter forage slows ox recovery and adds work strain; winter snow is more frequent; ordinary clothing does not erase the small winter-blizzard exposure floor. No automatic defeat date. Autumn/winter notices appear in travel text and typed-rest confirmation, including a future-month warning when relevant. Native rendered warning inspected;31 suites pass including25 winter checks. Previous live fingerprint e2552edfb52253cb1bdf283e9bec41c7b8e0118f89ec91d640cb9a99d4b115c0 migrates unchanged with authentic fixture. Data-loaded month lists are normalized to ints (JSON float membership mattered). Direct36x1000 scenario comparison and108 full journeys archived, plus128 rest/care follow-ups. Full journeys:95 arrivals,12 lost,1 diagnostic-year limit, no selected errors. Farmer intact arrivals fell19/36 to3/36: material balance concern, not completed calibration. Six-ox later-rest follow-up achieves14/16 farmer arrivals,7 intact versus reference14/16,3 intact. Keep hardship and investigate timely decisions/food accounting before further tuning. Meat food-value change remains unimplemented. Other ongoing art and real saves untouched.

## Complete Aseprite art overhaul & GUI sprite handoff (October 22, 2026)

- **All 52 existing game scenes and sprites** (`oxen`, `wagon`, `corolla`, `elder`, `lightsaber`, `prairie`, `river`, `travel_*`, and all 39 `location_*` landmarks/interiors/camp) have been rebuilt with the Aseprite Lua pipeline in `art/aseprite/scenes/*.lua`, installed into `art/pixels/`, imported into Godot, and verified with `./test.ps1` (167/167 art checks pass, 0 failures across all suites).
- **7 new UI / mini-game pixel-art assets** have also been authored in `art/aseprite/scenes/ui_sprites.lua` and installed into `art/pixels/`:
  - `hunt_bison.png` (`80x24`, 2 frames of `40x24`), `hunt_deer.png` (`54x22`, 2 frames of `27x22`), `hunt_rabbit.png` (`30x11`, 2 frames of `15x11`), `hunt_cover.png` (`24x14`, 2 frames of `12x14`), `hunt_hunter.png` (`16x18`), `gravestone_frame.png` (`432x150`), and `ledger_icons.png` (`56x8`, 7 icons of `8x8`).
- **Next UI wiring task:** Read [`docs/GUI_ART_HANDOFF.md`](GUI_ART_HANDOFF.md) for exact copy-pasteable instructions and code snippets to wire these installed sprites into `ui/hunt_view.gd`, `ui/grave_view.gd`, `ui/trail_view.gd`, `ui/main.gd`, and `tests/test_art.gd`.

