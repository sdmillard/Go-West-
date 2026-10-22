# Claude handoff — Westward, Probably

Prepared October 22, 2026 at Spencer's request as Codex approached the end of its five-hour usage window. **Continue the existing project; do not restart it.** The final verification note at the end records the delivered checkpoint.

## User intent and next objective

Implement the crime/cannibalism roadmap, then perform a full survival balance campaign. The first Fort Bridger store encounter is implemented and tested; the remainder is unfinished. Read `CRIME_AND_CANNIBALISM_ROADMAP.md`, `STORE_CRIME_SLICE.md` and `CHARACTER_CATALOG.md` before extending anything.

The user explicitly wants these to be actions a character can take. The game should report events neutrally; characters judge them individually. There is no global morality meter or hunger requirement for violence/cannibalism. An attack can fail. Killing, looting, processing remains, eating and deceiving another eater are separate decisions. Cannibal removes a consumption objection, not a murder/deception objection. Natural deaths can produce accessible remains too; death alone must not automatically grant food.

Successful violence may produce immediate benefits: shoot a tollkeeper and potentially avoid the toll; kill/rob a shopkeeper and take finite stock; seize a ferry and operate it with increased mishap risk. Guarded locations should be much more dangerous, with a possible but risky escape. Witnesses, identity, evidence, information spread, relationships and practical access produce the consequences. The user dislikes repetitive permission questions; progress autonomously within this approved scope, with concise updates.

## Project and environment

- **Canonical repo:** `C:\Users\Spencer\Projects\Oregon Trail`.
- **Writable staging copy for this Codex session:** `C:\Users\Spencer\Documents\ChatGPT\Oregon Trail`. Changed files were explicitly copied to the canonical repo and hash-verified. See final note below for the last sync status.
- Godot 4.5.1 console: `.tools/godot/Godot_v4.5.1-stable_win64_console.exe` in either copy. Language: GDScript. Original drawn pixel art, 640×360 mouse interface. No proprietary art copied.
- PowerShell tests: `& ./test.ps1`. It imports assets, isolates APPDATA to `.tools/userdata`, runs all suites, and fails on error/FAIL text as well as exit status.
- **Never run tests against the player's real save directory.** For a standalone test, first set `$env:APPDATA=Join-Path (Get-Location) '.tools/userdata'`, then run the console with `--headless --path . --script tests/test_crime.gd`.
- Use `--script tests/test_crime.gd -- --capture` without `--headless` for native capture. Inspect the saved image with an image viewer. Rendering uses the existing Godot UI; no image generation is needed.
- New modules/tests have `.gd.uid` companions. Let Godot import generate them and retain stable files.
- Staging `.tools/` and `research/local/` are ignored. Canonical writes required scoped tool escalation in this Codex sandbox; the user has already authorized the Projects repo. No commit/push/PR was requested or made by this pass.
- There is an old `simulation/trail_engine (# Edit conflict 2026-10-22 6jawb5C #).gd`. Leave it alone. The game uses ordinary `simulation/trail_engine.gd`.

## Existing game to preserve

Complete 36-stop route, 1,938 reported guide miles, Independence to Oregon City through Bridger/Hall/Boise/Barlow. Historical accuracy takes priority over copying classic rules; the setting is 1848. Later ferries/fort functions must respect chronology. Absurd lightsaber/Corolla/elder-god examples are parked, not the current priority.

Individual health, illness/severity/recovery/death, paid local care at selected posts, kits, weather/exposure, rations, typed multi-day rest, hunting/aim/ammunition, carrying limits, fresh-food expiry, drying and optional salt, wagon load, ox condition/team size, ox slaughter, wagon abandonment, foot travel, cache recovery and river outcomes already exist. Do not replace them with a second model. Existing defensive combat is risk-based, with bounded experience/Veteran effects; there is no combat minigame.

Opening cash is $600 farmer/$900 carpenter/$1,400 banker, understood as expedition capital from savings/liquidated assets. Wagon/gun/basic tools are retained. Suggested six-ox outfit is $392.60. Oxen $30/head, salt6¢/lb, mixed food6¢/ration-equivalent lb. Wages are cash plus communal food: bases40/90/50/60¢ per day for Hunting/Carpentry/Caregiving/Trading, with personality/special premiums. Old contracts are preserved. These are historically scaled game values, not certified receipts for every item.

Characters have 8 temperaments, 8 values,16 specials,12 flaws,13 relationships to the leader and4 backgrounds. Creation permits two specials, or three with one optional flaw. Old saved characters retain their valid specials. Personal effects and helper abilities are real; duplicates of a background benefit do not stack. The seeded generator returns detached candidate offers and powers the creation Generate button. **Actual replacement recruitment and bonds between companions are not implemented.** The player leads the first roster slot; there are currently five fixed identity records. Dead/departed people stay in history.

Paid companions gain trust from honored contracts; free companions depend on relationships/decisions. Wage rewards are normalized across schedules. Current low-trust refusal and warned departure operate at settlements, with explicit belongings transfer. These are not yet strong enough to represent immediate flight/retaliation after companion murder; follow roadmap phase4.

## New code and exact current behavior

`simulation/crime_system.gd`:

- Loads `data/crime_scenes.json`; only `fort_bridger` is enabled. This is an authored fictional keeper/local-staff scene at the private trading post, not a named historical keeper or army garrison.
- Own RNG seeded independently; record version1 with `people`, `actors`, `incidents`, `active`. Original party keys are `party:<seed>:original:<slot>`. Keeper key is `keeper:fort_bridger`; `staff:fort_bridger` is currently an aggregate local observer, not a simulated guard actor.
- Actor persists health, cash_cents, food_taken, food_sold, alarm state. Starts100 health, $50 fixed cash stash; food source is eight200-lb lots. The stash is separate from normal shop accounting. Actor identity and injuries/death are not regenerated on reopening.
- Commands theft/robbery/shoot/raid → loot or escape → report → done; back before commitment is free. A committed attempt uses a day; shooting spends one bullet; threats require a bullet but do not spend it. Collecting loot costs a day; alerted escape costs a day and may injure/capture. Surrender/capture ends the journey with living people still alive. Capture is a bounded terminal outcome, not imprisonment gameplay.
- Loot is at most200lb and available physical cargo room, plus the remaining cash stash after successful armed action/raid. Undetected petty theft takes food only. Every transfer is recorded once. Existing meals, spoilage, disease, wages and health effects continue on elapsed days.
- A noticed attempt alarms the staff and closes this store's legitimate trade. Other posts/passing traders are unaffected. No delayed reports, pursuit or remote enforcement exists yet.
- The party is explicitly present and observes the scene. Per-incident knowledge stores attempt/loot/escape facts; current local observation is intentionally coarse. Current attack/escape probabilities are fixed scene tuning, not yet adjusted for healthy defenders/experience/participation.
- Food purchases/barter and loot share physical stock. `consume_trade()` records the actual food transferred; a40lb barter consumes40, not200. Legacy offer quotas remain. Old save depletion can only be inferred from old offer counts; migration conservatively preserves that depletion.

Engine hooks (`simulation/trail_engine.gd`): crime initialization/binding after departure, `open_crime()`, crime command dispatch ahead of ordinary service handling, trade access/stock guards, and consumption accounting. A crime starts only at an actual eligible landmark stop, never merely because the last landmark was Bridger while already traveling away. Active pending decisions block ordinary travel/services.

Character hook (`simulation/party_character.gd`): `react_to_incident()` reuses existing boundaries with incident-aware memories. `remember(...,incident_id=0)` keeps daily deduplication for normal actions and separately deduplicates crime reactions. Forbidden attempts currently cost12 trust. This is inherited framework tuning, not the finished violence consequence model. No helper automatically participates just because they observed.

Save hook (`simulation/save_store.gd`): snapshots include crime record/RNG; fingerprint includes crime_scenes. Validates record shape, amounts, stages/outcomes, actors, observation facts, cash/food conservation and incident memories. Crime menus must equal an authoritative regenerated menu after restore, preventing saved-command injection. Old non-crime saves initialize clean records via migration. Pre-crime rules signature `f6e5acff6247c2a38a8b571042ab6a8259735c06f88b45301d6733012c57e264` is whitelisted. Genuine fixture: `tests/fixtures/pre-crime-save-v1.json`.

UI (`ui/main.gd`): Options → Actions at the Store. Unsupported locations get a factual availability message. Menu labels describe actions, not a moral alignment path. Closing an active panel leaves the encounter pending; it does not grant escape. Living captured parties do not get a false grave prompt.

Current rules signature: `c64ed4cc5f04858322050c034d1407fd7713d24355852af0ffeeabb44839694c`.

## Tests, evidence and policy correction

- `tests/test_crime.gd`: **1,021 passing checks** after final changes. Ninety seeded attempts cover misses, wounds, death, compliance/resistance and detection. Checks real days/meals/ammo, trust on failure, incident deduplication, preview purity, stage replay, finite stock, exact barter, injected saves, genuine migration and actual UI. A forced capture case checks the living-party grave prompt.
- `tests/store_crime_journeys.gd`:24 full-route journeys, four strategies × six seeds, actual arrival at Bridger, then at most one crime and normal survival policy. `docs/first-store-journeys.json` contains the report. Final run:24 arrivals,0 deaths,0 departures,0 selected invariant/save/policy-loop errors. This tiny banker-funded sample is **not balance certification**, and should not justify lowering risks or increasing loot. Targeted tests cover dangerous outcomes separately.
- The first sampler initially looped on a closed store. `tests/full_trail_balance.gd` was corrected so its bulk-buy branch requires positive food effects; a Back choice is not a purchase. The sampler now explicitly flags a journey limit as an error. Old lawful-policy behavior is otherwise unchanged.
- Native `docs/store-actions.png` was rendered and inspected. Current scene uses the existing service dialog; no crime-specific animations shipped.
- Full regression passed before the final physical barter/state-validation refinements; targeted crime checks and24-route sample passed afterward. Read the final note below for the canonical full regression after those refinements.

## Recommended next work

1. Review/finish the foundation before multiplying scenes. Introduce genuine named actor witnesses and service ownership/participation; current nearby staff is an aggregate fact. Make actor/incident validation extensible across multiple venues. Keep scene data, preview and command execution authoritative and independent of UI.
2. Add toll/ferry/guarded-location variants with researched route/date availability, real benefits and their own resistance/escape/crossing risks. Respect the private nature of1848Bridger. Add health, willing participants, defenders and modest capped experience to resolution. The store's fixed probabilities are a first slice only.
3. Add inter-companion bonds, attempted companion violence, target resistance, immediate flight/retaliation and appropriately strong reactions. Don't simply apply−12trust and make everyone wait for the next safe town. Preserve each person's identity and actual resources when they leave.
4. Implement bodies, burial/grave disturbance, distinct human-food provenance, processing and per-person meals/consent. Current shared aggregate food must not silently feed everyone human remains. Preserve provenance through drying/salt/storage; no free or duplicated bodies from old saves.
5. Add reports/delays/recognition/pursuit and hostility/access integration for services beyond this store. Current alarm only closes local trade; local care and other activities are not yet a general hostility system.
6. Only after integrated crime/cannibalism works, run the roadmap's full development/held-out survival balance and a human playtest. Arrival alone hides losses of companions. No automatic free replacement companions; recruitment is still separate future work.

Do not implement a worldwide morality score, starvation-only action gate, guaranteed kill/loot, infinite stock, a universal all-knowing witness system, automatic human-food sharing, or unexplained supernatural health penalties. Do not expand into prison management, a combat minigame or a new skill tree before this sequence is playable.

## Final verification / delivery note

FINAL: 21 source/test/documentation/report files were copied into the canonical Projects repository and hash-verified. The complete canonical test.ps1 run then exited0 with every suite passing, including Store crime1,021, Character catalog576, Simulation3,185, Saves149 and Full trail1,883 checks. This includes the final exact barter accounting and validation refinements. The native store menu was inspected. The24-route report is the final corrected no-loop sample. No required test is running or known failing at handoff. Latest usage reading was98% used /2% remaining, after the reading advanced from95% between checks; feature work has stopped. No external message to Claude has been sent; this file is the handoff artifact.

