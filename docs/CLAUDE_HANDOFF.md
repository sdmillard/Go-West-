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

Publication branch: `codex/survival-accounting-hauling`. The numerical rules, code, tests, historical research and campaign archives are included. Concurrent Aseprite art and its GUI wiring handoff remain separate local work. GitHub PR history records publication/merge status. The tested local snapshot is retained on `codex/survival-accounting-validation-20261022`.
