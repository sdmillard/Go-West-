# Claude handoff: Westward, Probably

Last updated October 23, 2026, after the disease part 2 PR (see Expanded mechanics). Sections below cover PRs #19 to #34. **Continue the existing project; do not restart it. Spencer requested a break. This is a saved checkpoint, not a request to continue working now.**

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
- Fixed stale meal orders after a diner dies/leaves; Hardy/fatal-shot and Frail/lethal-wound history mismatches; body/human-food weight missing from pack previews; and several study-policy stalls/timeout classifications. Save-rule fingerprint then: `376c2029…e635` (see PR #33 section for the current one).
- The final test policy preserves **four working oxen** before elective slaughter (`slaughter_team_floor=4`). Earlier bots ate working teams down to one, falsely exaggerating four-ox difficulty. This is a policy correction, not a player restriction: the player can still slaughter working animals in emergencies. Keep the three working-team regression cases.

- Crime follow-ups are finished: passing traders now refuse a party that news has named, and travelers at stops repeat that news (trader-news PR). Every crime phase and follow-up is merged. Next is new mechanics (a parallel thread), then the balance pass.
- PR #31: shooting a companion now opens a notice right away ("YOU SHOT AT <NAME>") with the result, who joined, fought back, objected, fled (with what they took) or stood by. Trust lines stay in the journal (`ui/main.gd` `_show_attack_result`).

## Aseprite art (published)

- The local Aseprite rebuild of all 52 scenes, the seven new sprites and `docs/GUI_ART_HANDOFF.md` were committed from the canonical checkout on branch `claude/aseprite-art-wiring`. The hunting sprites, headstone and ledger icons are wired into `ui/hunt_view.gd`, `ui/grave_view.gd` and `ui/main.gd`; the headstone was redrawn round-topped. The river-crossing and cabinet-chrome suggestions in that handoff are not implemented.
- Three `docs/balance-pilot-debug-*-farmer.json` files remain local debug copies and are not published.
- Scene redo batch 1 (Claude, branch `claude/scene-redo-1`): Burnt River, Devil's Gate, Deschutes, John Day, The Dalles and Wakarusa were redrawn with new `lib.lua` landscape helpers (`sky`, `smooth`, `ribbon`, `river`, `ridge`, `willow`, `basalt`). Batch 2 (PR #23 branch) redid Soda Springs, Independence Rock, Ash Hollow, Big Blue and Snake River. Spencer's review rules: fording wagons must read as knee-deep (`K.wade`) and figures must be in scale with landforms (`K.far_wagon`). Batch 3 redid the sparse scenes (Little Sandy, Powder River, South Pass, North Platte, Umatilla, Fort Kearny early, Green River) and added `K.peaks` for snowy ranges. Remaining older scenes still repeat the same two clouds and bottom-left wagon; review them case by case.
- Animation pass (Claude, at Spencer's request): PR #26 gave the travel wagon, oxen and walkers eight-frame cycles (`trail_view.gd` `FRAMES = 8`, `FPS = 12`). PR #27 redrew river crossings in a three-quarter (2:1 isometric) view after Spencer said the side view made rivers look small and the ferry fly in: `river_crossing.png` is a 720x300 world the view pans across, the wagon starts and stops on the banks, ferries dock at each shore, and `crossing_sprites.lua` renders depth-sorted `cross_*` sheets. `NEAR_BANK`/`FAR_BANK` in `trail_view.gd` must match the outlines in `river_crossing.lua`. PR #28 animates the hunt (`hunt_animals.lua`: walk/run/down rows, walking hunter, rifle smoke). Ferries still carry no mishap risk in the rules; consider that in the balance pass. PR #29 adds ambient loops to location pictures (`ui/scene_ambience.gd`, positions in `data/scene_ambience.json`, sprites from `ambience.lua`): chimney and cook-fire smoke, camp sparks, the Fort Hall HBC ensign and Fort Laramie US flag (their baked flags were removed), automatic glints on open water and passing birds. PR #30 makes travel scrolling layered on every terrain: the five travel scenes draw with `K.wrap` (marks wrap round the edges so layers tile) and `K.save_layers` writes `<scene>_sky/clouds/far/mid/ground` (or `_floor`) PNGs; `trail_view.gd` `PARALLAX` sets each layer's speed. The flattened pictures still back the hunting screen.

## Scene redos, round 3

- Spencer asked which scenes still needed work. Redone: Courthouse and Jail Rocks and Scotts Bluff (new `K.butte` kit helper: eroded clay/sandstone buttes with domed crowns, gullied walls and aprons; the Scotts Bluff road bends south to Robidoux Pass, correct for 1848), Kansas River (yellow-brown turbid water, darker and set apart from the sand, per Palmer "a muddy stream" and Fremont "yellow turbid current"; ferry crossings use the same colour; irregular gallery forest), Platte and South Platte (braided channels on a sand bed instead of stripe patterns), Fort Boise (corner-on adobe square, bastion with HBC ensign added to `scene_ambience.json`, meandering Boise mouth), Grande Ronde (seen from the steep descent) and Blue Mountains (road climbing into heavy timber, doubled team).
- De-templated: the repeated two clouds and the bottom-left wagon are gone from Barlow Pass, Eagle Creek, Elm Grove, Forts Bridger/Hall/Kearny/Laramie, Laurel Hill and Oregon City.

## Trading time and the post store (PR #33)

- Spencer: a day per purchase was too much ("I'm not spending 24 hours in the store"). Trading now costs **one day per visit**, charged on the first transaction (`context.trade_days`, `<offer key>|visit` in the context ledger), at posts and with passing traders alike.
- Fort posts (`trade_bulk`: Laramie, Bridger, Hall, Boise) open a **store counter** (`ui/post_store_view.gd`, engine `post_store` / `post_quote` / `post_checkout`): buy and sell any number of lots within the post's stock and buying demand, settled as one basket. Food sells by the 200 lb barrel-and-sack lot. Posts deal in cash only; barter stays with passing traders. Background is the new `location_post_store.png` (`post_store.lua`, an adobe fur-trade room).
- Passing traders keep fixed lot trades plus barter, and charge `passing_price_markup` (1.2) over regional prices. Save-rule fingerprint is now `dc09cc2cd670ca48cbd3e2d782101f203412ab54a7954aa66fed692538b14f0e` (previous one whitelisted in `economy_v1`).
- Balance check (`tests/full_trail_balance.gd`, 720 journeys): arrivals 369 before, 364 after; 370 with the time change alone (markup 1.0). Cell changes are within the noise of 20 runs. The study bots mostly sell at posts for tolls, so the saved days barely show; a shopping policy at posts belongs in the combined balance pass.

## UI readability sweep (PR #34)

- Spencer: the shot notice ran off the screen and tooltips were grey-on-black and unwrapped. Fixed across the UI in `ui/main.gd` (inherited by every child view):
  - Tooltips use theme types `TooltipPanel` (parchment `f6e7bc`, brown border) and `TooltipLabel` (dark ink). Godot's tooltip label never wraps, so `_wrap_tooltip` (hooked to `node_added`) hard-wraps every tooltip to `TOOLTIP_WIDTH` (240 px) as it appears. New `tooltip_text` anywhere needs no extra work.
  - Notices go through `notice(title, text)`: the label wraps at `NOTICE_WIDTH` (460 px) and `popup_fitted` resizes to the text and centers it. A bare `popup_centered()` on a resized AcceptDialog centers a zero-size window, which then grows off the right edge; use `popup_fitted` for dialogs whose text changes.
  - The shot notice is now a summary: result, fought back, joined, one "Fled:" line with the combined food/clothing/gear taken, objected, stood by. The journal keeps the per-person lines.
  - The guide scrolls in a fixed 500x250 frame (it was cut off at the bottom) and its trading paragraph now matches PR #33.
  - Drop-down lists explain each entry on hover, not just the selected one: companion temperament, values, background, relationship and flaw (`departure_view.gd` `describe_items`), plus pace and rations (follow-up PR to #34).
  - Party setup: the companion character sheet is closed by default. Each companion name has an EDIT button that opens that companion's sheet (`departure_view.gd` `open_editor`), with DONE to close (Spencer's request). The old TRAVELER 2-5 selector is gone. Entering the store closes the sheet.
  - SpinBox arrows are brown (they were near-white on parchment); the fort store counter columns were widened so prices no longer touch the item names.
- Visual check: every window and several tooltips were captured under Xvfb at 640x360 before and after. The capture script is not in the repo; `tests/test_ui.gd` now checks tooltip theme and wrapping, notice centering and guide height.

## Expanded mechanics: disease, climate, route branches (October 23, 2026)

Spencer's order: crime follow-ups and these expanded mechanics first, the big balance pass last. Do not tune balance in these PRs; mark new numbers as placeholders. Plan: disease (causes and contagion, then scurvy), climate (Platte storms and stampedes, heat and dry stretches, snowmelt rivers), then route branches open in 1848 (Greenwood Cutoff, Columbia raft vs Barlow Road, Fort Walla Walla detour).

- Disease part 1: illness is picked by month and region, measles/dysentery/typhoid spread within the party, measles leaves immunity (saved per traveler as `immune`), new non-contagious mountain fever in high country, cholera still locked to 1849+. See `docs/DISEASE.md` and `tests/test_disease.gd` (suite 34). Previous fingerprint `a76bde0b…81b7` whitelisted in `economy_v1`.
- Disease part 2: scurvy after 45+ days of meals without fresh (undried) meat (`party_health.days_without_fresh`, saved as top-level `days_without_fresh`); mends only on fresh-meat days; never a random illness. Previous fingerprint `4fbbe60d…7351` whitelisted. Dried fruit, pickles and foraged greens are not modeled yet.

## Stoic vs. Loyal (Spencer's choice, October 23, 2026)

- Loyal used to strictly beat Stoic (both cut ordinary trust losses, 50% vs 25%). Spencer chose to split them: **Stoic** halves trust lost to hardship only (`HARDSHIP` kinds in `party_character.gd`: rest days, resting/pushing with the sick, armed defense; catalog key `hardship_trust_loss`). **Loyal** takes losses in full but its breaking point is 10 lower (`LOYAL_STAY`) and it never betrays (`may_betray`). Wages and moral choices are not hardship. Previous fingerprint `dc09cc2c…f0e` whitelisted in `economy_v1`; current one is `a76bde0b…81b7`. Earlier balance studies that used Loyal rosters predate this change.

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
