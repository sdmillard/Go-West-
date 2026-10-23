# Claude handoff: Westward, Probably

Last updated October 22, 2026, after merged PR #19. **Continue the existing project; do not restart it. Spencer requested a break. This is a saved checkpoint, not a request to continue working now.**

## Resume here

- Canonical local repository: `C:/Users/Spencer/Projects/Oregon Trail`. GitHub: https://github.com/sdmillard/Go-West- ; default branch `master`. The `Documents/ChatGPT/Oregon Trail` workspace is stale staging.
- Survival/accounting work is pushed and merged: [PR #19](https://github.com/sdmillard/Go-West-/pull/19), merge commit `4b7839640949d593d251d695236f8908334bc64e`. Local master was synced while preserving every pending working file. No implementation change is waiting for publication.
- Exact publication commit passed all **33 Godot suites**, plus **24 store journeys and 20 outlaw journeys**, in a clean isolated checkout. Temporary checkouts were removed. The earlier tested snapshot remains on local branch `codex/survival-accounting-validation-20261022`.
- Final campaign: **5,040 development journeys plus 5,040 fresh validation journeys**, with no selected state, save, setup or route-policy errors. Use `docs/BALANCE_CAMPAIGN.md`, `docs/balance-development-03-summary.json` and `docs/balance-heldout-02-summary.json`. Sources/rules match across the final pair. The earlier archives are superseded experiments, not additional independent evidence.
- Balance is **not declared settled**. In the final May/ordinary/unpaid/lawful subset, farmer arrival/intact counts were **11/40 and 1/40**; carpenter **29/40 and 26/40**; banker **40/40 and 39/40**. Human clarity, aiming and pacing playtests remain outstanding. See `docs/PLAYTEST_CHECKLIST.md`. Do not silently retune to or overwrite the held-out sample.

## What just shipped

- Purchased staples remain one physical pound per food unit. New meat supplies **0.5 food units per physical pound**, with a saved per-batch physical mass ratio. Consumption, preservation, salt costs, cargo, discards, caches and separately tracked human-derived food use the proper quantities. Valid legacy saves retain their original food quantities/mass rules.
- Shared `simulation/carrying.gd`: health scales personal load continuously. A broken leg removes that person's contribution until recovery. Full allowances are **50 lb/person for retrieval**, **40 lb/person gross packs on foot**. Hunting/retrieval caps at **200 physical lb** and actual cargo room. Only willing helpers participate in hunting/crime retrieval. Wagon storage stays tied to the wagon/team, not human health.
- Loot uses explicit scene `wagon_access`. An open holdup beside a wagon can load its available space; quiet theft and the Fort Kearny commissary require personal retrieval. The actual loot panel explains the limit. Do not restore the obsolete fixed 100 lb hunting HUD while editing the UI.
- Seasonal roads, grazing/work strain and winter exposure are implemented, with autumn/winter travel/rest warnings. Opening food is the documented **five-cent estimate**; starting funds remain **$600/$900/$1,400**. Current suggested outfit is **$375.60**. These are documented historical estimates, not an exact 1848 price reconstruction.
- Fixed stale meal orders after a diner dies/leaves; Hardy/fatal-shot and Frail/lethal-wound history mismatches; body/human-food weight missing from pack previews; and several study-policy stalls/timeout classifications. Current save-rule fingerprint: `376c2029c6bbc9acc8338bb3a2d1f0a7eecfc1374cfd0c20fc07fd47d403e635`.
- The final test policy preserves **four working oxen** before elective slaughter (`slaughter_team_floor=4`). Earlier bots ate working teams down to one, falsely exaggerating four-ox difficulty. This is a policy correction, not a player restriction: the player can still slaughter working animals in emergencies. Keep the three working-team regression cases.

## Local work that is NOT on GitHub

**Inspect `git status` before any cleanup, pull, branch change or publication. Do not discard or silently include the pending artwork.**

- Modified `art/aseprite/lib.lua`, `art/aseprite/scenes/independence.lua`, and many `art/pixels/*.png`.
- Untracked Aseprite scene Lua sources, seven new UI/hunting/memorial PNGs and their import metadata.
- Local-only `docs/GUI_ART_HANDOFF.md` describes the 52 rebuilt scenes and seven new GUI sprites, with proposed wiring. It was read for this handoff; its implementation claims still need to be checked against the current UI before proceeding. Those assets and their wiring were intentionally excluded from PR #19.
- Three untracked `docs/balance-pilot-debug-*-farmer.json` files are debug-only diagnostic copies. They are not required by the final reports and were not published. Preserve them locally unless cleanup is requested.
- The canonical handoff also contains the local art progress section below. A fresh GitHub clone will not contain those uncommitted art assets or the GUI art handoff. Coordinate from the canonical local checkout rather than assuming they were lost.

## Suggested order when Spencer resumes

1. Read this checkpoint, `docs/BALANCE_CAMPAIGN.md`, `docs/FOOD_VALUE_AND_HAULING.md` and the local `docs/GUI_ART_HANDOFF.md`; inspect the actual working tree.
2. Decide with the resumed task whether to finish/publish the pending art wiring or diagnose poor-party survival. Do not start replacement recruiting, extra route branches or a combat minigame by default.
3. For art wiring, follow `art/aseprite/README.md`, preserve hitboxes/gameplay and the new health/hauling/food-unit UI, then render the native screens. The suggested snippets may predate the current HUD; integrate them carefully.
4. For balancing, diagnose specific bottlenecks with public-action development studies and actual player saves when supplied. The current bot is not an optimal human player and does not optimize every replacement-clothing purchase. Keep real player saves untouched; test with `APPDATA` redirected into `.tools/userdata`.
5. Preserve the final validation outcome. Any later numerical/policy tuning needs fresh reserved seeds (for example an unused range starting at 3000), not a rewritten `heldout-02` archive. Rows share matched seed clusters; do not treat 5,040 rows as independent historical mortality trials. The empty-larder action-day counter is not an exact starvation-day count.
6. Run `./test.ps1` with Godot 4.5.1 before publishing code changes; use a clean isolated checkout as required below. After crime changes also run store/outlaw integration journeys. Do not commit generated `docs/first-store-journeys.json`, `.tools/`, `research/local/` or real saves. Add the previous fingerprint to migrations before changing data rules.

The remaining sections are chronological history. Their earlier "next work" and "not implemented" statements are superseded by **Resume here** and PR #19.

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

Phase7 now has a public-action matrix and archived development/validation passes. Read the latest food/hauling and campaign checkpoint below; older baseline statements are chronological snapshots.

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

Read `docs/JOURNEY_TIME_AUDIT.md`. Fixed the old toll fundraising policy's menu-index assumption: Back at an absent trader was falsely counted as a sale, causing a no-time loop. `tests/journey_trade_policy.gd` now selects actual cash-for-goods effects or real waiting; exhausted sales/refusals block explicitly. Added10 checks in `tests/test_journey_policy.gd` and the suite to `test.ps1` (30 suites pass). Diagnostic03 repeats108 current-price setups:99 arrived,7 lost,2 year limits; no selected errors, no outcome/survivor changes versus 02, elapsed days reconcile. Preserving farmer runs spend about10 processing days,18-20 hunting days and 36-39 explicit rest days; only8 of 248 batches are below 30 units. No game-rule change justified yet. The former six-cent capped setup was explicitly replayed:6 real wait days,10 actual sales, starvation loss on day 254; no loop. Original archives retained. Next isolate rest/care decisions and food-value assumptions. New art remains other ongoing work.

## Rest/care decision study (October 22, 2026)

Read `docs/REST_AND_CARE_AUDIT.md` and `docs/rest-care-diagnostic-01.json`. Ran128 matched public-action journeys: reference, later rest, earlier care and combined; farmer/carpenter, April/May, dry/salt, seeds 0-3. Study thresholds are now configurable, with unchanged defaults and exact parity against16 archived reference journeys. Reference rest counts:820 total,642 health-triggered,178 ox-triggered,4 fatigue-triggered (overlap allowed). Later rest had12/16 farmer arrivals all intact versus reference12/16,10 intact. Earlier care had13/16 farmer arrivals but only8 intact and 28 deaths; affluent results differ. No dominant policy or justification to change game recovery rules. Keep reference defaults and game costs/rates unchanged;128 runs had zero selected invariant/save/policy errors. Next food value versus physical meat, then hired/emergency cohorts. Full phase7 remains pending. Existing art and actual player saves left alone.

## Seasonal pressure implemented (October 22, 2026)

Read `docs/SEASONAL_PRESSURE.md`. New authored monthly ground drag affects wagon/walking travel, more strongly in uplands; winter forage slows ox recovery and adds work strain; winter snow is more frequent; ordinary clothing does not erase the small winter-blizzard exposure floor. No automatic defeat date. Autumn/winter notices appear in travel text and typed-rest confirmation, including a future-month warning when relevant. Native rendered warning inspected;31 suites pass including25 winter checks. Previous live fingerprint e2552edfb52253cb1bdf283e9bec41c7b8e0118f89ec91d640cb9a99d4b115c0 migrates unchanged with authentic fixture. Data-loaded month lists are normalized to ints (JSON float membership mattered). Direct36x1000 scenario comparison and 108 full journeys archived, plus128 rest/care follow-ups. Full journeys:95 arrivals,12 lost,1 diagnostic-year limit, no selected errors. Farmer intact arrivals fell19/36 to 3/36: material balance concern, not completed calibration. Six-ox later-rest follow-up achieves14/16 farmer arrivals,7 intact versus reference14/16,3 intact. Keep hardship and investigate timely decisions/food accounting before further tuning. Meat food-value change remains unimplemented. Other ongoing art and real saves untouched.

## Complete Aseprite art overhaul & GUI sprite handoff (October 22, 2026)

- **All 52 existing game scenes and sprites** (`oxen`, `wagon`, `corolla`, `elder`, `lightsaber`, `prairie`, `river`, `travel_*`, and all 39 `location_*` landmarks/interiors/camp) have been rebuilt with the Aseprite Lua pipeline in `art/aseprite/scenes/*.lua`, installed into `art/pixels/`, imported into Godot, and verified with `./test.ps1` (167/167 art checks pass, 0 failures across all suites).
- **7 new UI / mini-game pixel-art assets** have also been authored in `art/aseprite/scenes/ui_sprites.lua` and installed into `art/pixels/`:
  - `hunt_bison.png` (`80x24`, 2 frames of `40x24`), `hunt_deer.png` (`54x22`, 2 frames of `27x22`), `hunt_rabbit.png` (`30x11`, 2 frames of `15x11`), `hunt_cover.png` (`24x14`, 2 frames of `12x14`), `hunt_hunter.png` (`16x18`), `gravestone_frame.png` (`432x150`), and `ledger_icons.png` (`56x8`, 7 icons of `8x8`).
- **Next UI wiring task:** Read [`docs/GUI_ART_HANDOFF.md`](GUI_ART_HANDOFF.md) for exact copy-pasteable instructions and code snippets to wire these installed sprites into `ui/hunt_view.gd`, `ui/grave_view.gd`, `ui/trail_view.gd`, `ui/main.gd`, and `tests/test_art.gd`.



## Food value, health-based hauling and full campaign checkpoint (October 22, 2026)

Read `docs/FOOD_VALUE_AND_HAULING.md`, `docs/BALANCE_CAMPAIGN.md` and `docs/PLAYTEST_CHECKLIST.md` before changing balance. Canonical repo remains `C:/Users/Spencer/Projects/Oregon Trail`; the Documents/ChatGPT workspace is stale staging.

- New meat yields0.5 food units/physical lb. Each batch has a physical mass ratio, propagated through consumption, drying/salt, discards, caches, human-derived food and saves. Processing100 physical lb/day, salt by physical input; ordinary purchased staples remain1 lb/unit. Older batches without a ratio retain their original quantities/weights. Authentic fixture `pre-meat-value-save-v1.json`; invalid ratios reject. Previous live/interim fingerprints are in economy_v1; current signature is376c2029c6bbc9acc8338bb3a2d1f0a7eecfc1374cfd0c20fc07fd47d403e635. Funds unchanged; opening food remains5c estimate.
- Spencer explicitly requested proportional carrying by health, with broken legs removing contribution. Shared `simulation/carrying.gd`:50 lb/person retrieval at 100 health,40 lb/person gross foot packs; health scales linearly. Hunting cap200 physical lb plus actual room; only willing helpers count. Wagon capacity is unaffected by human health. Broken-leg/no-health contributions cannot bypass through a minimum. Derived references bind to restored actual party members, not serialized duplicate health. Pack quotes now count remains/human-food mass.
- Spencer also requested meaningful robbery hauling. `wagon_access` is explicit scene data: roadside/private store loading can use wagon room; Fort Kearny requires retrieval. Quiet theft always requires retrieval. Willing crime participants, health/injuries, actual room, scene limit and finite stock all count. Native loot panel explains alongside vs haul limit; current supplies/loot screenshots were inspected. This is an authored scene abstraction, not a measured historical distance model.
- Combined journeys caught stale human-meat meal orders after death/departure; synchronization now clears them. Explicit fatal attacks use `party_health.kill`, so Hardy cannot leave a recorded fatal victim alive. Frail-amplified lethal wounds are recorded as killed, including betrayal attacks. Ordinary damage mitigation remains. Remains 92 checks now covers these plus pack-body mass.
- Final balance pair:5040development03 seeds 100..119, then5040 fresh validation 02 seeds 2000..2019. Both have0selected errors; all final saves and representative intermediate states validate; source/rule signatures match. Core matrix:3capitals x3 months x4 rosters x7 strategies x20 seeds. Baseline ordinary/mixed-paid/Frail/selected3-special+1flaw parties; lawful dry/salt, no hunt, theft, robbery, already-dead meals, deliberate predation. Retain current data values; no tuning to final validation outcomes.
- Important study-policy correction: earlier profiles slaughtered working teams down to 1before hunting. A matched144+144pace/aim/4vs6ox study isolated this. Added optional `slaughter_team_floor` to full-trail policy, preserving old default1for archives; final campaign uses 4. Players retain all slaughter choices. Three regression cases guard old/new policy semantics. Earlier heldout01 belongs to the superseded policy; use final heldout02 for current results.
- Development 03:3061 arrivals/1542 intact; validation 02:2925 arrivals/1660 intact. May ordinary lawful 40 runs/capital: development farmer 27/7 intact, carpenter 37/33, banker 40/37; validation farmer 11/1, carpenter 29/26, banker 40/39. Lawful intact farmer survival exists but remains harsh and variable. Do not claim historical mortality fit or fully settled human difficulty. Counts share20 seed clusters; global arrival rates mix late starts, expensive rosters and violent choices. `empty_food_days` is an empty-larder action-span proxy, not exact starvation days; latest summaries call it mean_empty_food_action_days.
- Further studies:180 food-value/reserve journeys;144corrected emergency journeys covering4ox, no ammo, zero ox/walking, injury/low health, hostile store/fort, meal refusal, departures and spoilage. 0selected errors. First emergency archive preserves a policy-only single-item discard stall, corrected by batched drops. Test store journeys now distinguish actual policy stalls from a legitimate August year limit. Never commit regenerated docs/first-store-journeys.json.
- All33 suites pass in a clean isolated canonical worktree, including33 meat/carrying,92remains and 3 working-team policy checks.24 store and 20 outlaw integration journeys pass. Real saves were isolated via APPDATA in .tools; user saves untouched. No art was edited by this work. Ongoing Aseprite PNG/Lua/GUI-art handoff changes remain separate and must not be reverted or bundled accidentally.
- Human clarity/aim/pacing playtest remains next; use the short checklist. Recruitment, extra route branches and combat minigame remain later scope. The scripted policy does not optimize every clothing purchase or human decision. Further balancing should target observed bottlenecks using new development studies and fresh validation seeds; do not silently overwrite archives.

Publication: survival/accounting, research and balance reports were pushed and merged into `master` through https://github.com/sdmillard/Go-West-/pull/19 (merge4b7839640949d593d251d695236f8908334bc64e). Local master tracks that merge. Concurrent Aseprite artwork, GUI handoff and debug-only pilot archives remain local and were preserved. The publication commit passed all33suites plus24store/20outlaw journeys in a clean checkout. A tested snapshot remains on `codex/survival-accounting-validation-20261022`.
