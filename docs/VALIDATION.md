# Validation record

Tested October 21, 2026 on Windows with official Godot 4.5.1 stable (`f62fdbde1`).

- `test.ps1`: **3,038 simulation checks, zero failures**; UI integration suite, zero failures.
- Seed sweep: 1,000 Unhinged journeys completed using default pace/rations and first affordable choices; arrival resources remained valid.
- Probability boundary grid: exactly 100 of 10,000 evenly spaced rolls selected the 1% absurd pool. This verifies the configured threshold, not a claim about the percentage of whole journeys with encounters.
- Classic mode: 1,000 forced low-roll checks returned no absurd content.
- Real main scene: headless startup and three frames, no errors.
- Rendered UI suite: passed using OpenGL compatibility renderer on the available NVIDIA GPU.
- `docs/preview.png`: updated after the Western pixel-art pass, captured from the actual 640 × 360 viewport. Presented at 2× in the game window. Travel, muddy trail, absurd encounters, field guide and journal captures were visually inspected; text, choices and controls fit within their panels.
- Rare content seed examples found through normal scheduling: Corolla 165, elder god 171, lightsaber 197; default settings, travel daily, first available choice.

The UI integration suite instantiates the actual scene and emits button signals; this is not a manual mouse playthrough. It exercises historical choices, completed-route controls, restart/mode selection, and all three absurd encounter presentations. Simulation tests separately verify their inventory/vehicle/resource effects.

No claim is made about complete historical balancing, mobile layout, exports, or parity with original game executables. The supplied 1993 game was subsequently installed and played inside the isolated reference environment; those observations are in `REFERENCE_PLAYTEST_1993.md`. The documented prototype scope is the runnable project, not a packaged standalone release.

Western art pass: retained the same 3,038 simulation checks and added art asset checks for crisp alpha, four-frame wagon/oxen animation, bitmap font glyphs and integer viewport scaling. The UI suite additionally checks the native canvas size and guide/journal windows. `launch.cmd` and `test.ps1` import assets before use so a fresh checkout can load the PNGs and font.

## Classic opening and automatic travel pass

The later historical-route pass extends player travel beyond this older validation scope.

- Added setup validation, rejection without state/RNG mutation, cent-accurate outfitting, single-use departure, copied party names, calendar selection, typed wheel consumption and preservation of cash cents through river payment.
- Added 60 complete Classic first-leg runs from outfitting across all three professions, alongside the previous 1,000 pre-outfitted regression journeys.
- UI integration exercises invalid and accepted shop input, the selected month, actual timer timeouts, Pause, encounter stops, explicit resumption, Guide/Journal pauses, Camp, terminal stops and cancellation of travel on restart.
- Added malformed shop data checks for negative prices, duplicate entries and missing professions.
- Rendered setup, travel and wheel-event screens were inspected at 640 × 360; their text and controls fit. Captures remain native game pixels, not mockups. The UI suite uses widget signals and timer callbacks, not a manual mouse playthrough.
- Final run: **3,185 simulation checks, 21 art checks, zero failures**; UI integration zero failures. This is still the opening leg to the Kansas River; clothing/ammunition effects, oxen-based speed, individual illness and full-route parity are not claimed.

## Historical corridor pass — October 22, 2026

- Sixty seeded player setups reach the Platte, guide mile 317; 1,000 older runs retain the isolated 102-mile regression fixture.
- **3,185 simulation checks, 26 route checks, 21 art checks: zero failures**. UI integration passes, including full-corridor deterministic replay.
- Route checks establish source-row sums, guide milestones, absent later ferry, no overshoot, connections, invalid/cyclic road rejection, stop locks, rest costs, preserved stage during rest and starvation at a stop.
- Assigned water stage changes ford/float risk. This tests game behavior, not historical frequencies.
- Additional scene captures cover Kaw, Big Blue and the chapter ending. Ending text explicitly says Oregon has not been reached. Art remains original and illustrative.

## Illustrated locations — October 22, 2026

- All six route IDs have distinct arrival textures; nine new images include setup, store and camp. Art checks validate native dimensions, distinct image data and crisp alpha. The suite now has **65 art checks**.
- UI tests exercise entering/leaving the store, retained unpurchased cart, unchanged simulation state during navigation, camp presentation, each real landmark's selected scene and the retained Platte ending scene.
- Simulation and route behavior remain unchanged: **3,185 simulation checks, 26 route checks**, zero failures. Headless and rendered UI suites pass.
- Captures include party preparation, store, camp, each stop, travel and dialogs. Visual inspection checks image placement, readable text and visible controls at native resolution. These checks use the actual scene and widget signals, not a manual mouse playthrough.
- Historical images were inspected directly for Independence, the comparative store and Wakarusa. Their dates/limits are recorded in `art/LOCATION_REFERENCES.md`; illustrations do not certify exact 1848 appearance.

## Scrolling and river animations — October 22, 2026

- Corrected the town builder: short facades get one window row; no window overlaps a door or its trim. Regenerated both town pictures and inspected the rendered setup view.
- Travel now uses tiled ground and horizon layers; the motion suite verifies scrolling advances during travel and freezes on Pause without changing simulation state or RNG.
- The engine emits a plain crossing result with method/place/mishap/loss. The UI plays a 2.8-second presentation of that committed result. Ford/float/ferry appearances, modal pause/resume, control locks, skip, real-clock completion, restart cancellation and terminal loss are exercised.
- **3,185 simulation, 26 route, 69 art and 28 motion checks pass**, plus the scene integration suite with zero failures. Both UI and motion suites also pass with the graphical renderer.
- Inspected midpoint captures for all three methods. `docs/river-crossings.gif` contains 126 rendered game frames; it is review media, not an asset driving gameplay.

Shoreline correction: sprite occlusion, ambient ripples, wakes and splashes now clip to a water mask derived from the same polygons that draw the banks. The wagon and livestock move onto/out past the far bank, revealing their dry lower parts. The graphical motion capture passes 37 checks, including nine pixel checks on dry bank areas at entry and exit; headless motion coverage remains 28 checks. Inspected late float/ford frames and regenerated the preview. No simulation rules changed.

## Crossing mishap history — October 22, 2026

- Crossing outcomes now store day, landmark, method, actual accident food/health losses and terminal status in `crossing_history`; a dated summary also enters the visible trail journal. Damage is measured after the crossing day's ordinary consumption, so scarce food and near-zero health report only what was actually lost.
- Mishaps pause forward motion while original pixel cargo boxes drift downstream. The result screen retains the river background, shows exact losses, and requires acknowledgement before another action. Skip and acknowledgement never reroll damage or spend another day. Existing risk and damage rules remain unchanged; this represents cargo loss, not a new capsize or drowning system.
- Forced safe/mishap, low-stock, fatal injury, starvation, journal visibility, acknowledgement locks and single-commit tests pass alongside the existing suites. Headless motion coverage is now 46 checks; graphical capture adds twelve dry-bank pixel checks. Inspected actual failure animation and result captures. The review GIF now contains 168 frames including the failure example.

## Classic health presentation and mechanics audit — October 22, 2026

- Read the full downloaded 1978 and 1975 listings; both hashes match the source manifest. Recorded all sixteen event branches, other major systems and transcription defects in `CLASSIC_MECHANICS_AUDIT.md`. Compared with the actual engine/JSON and the 1985 manual/designer account, distinguishing implemented, partial and missing behavior.
- Health now appears as GOOD/FAIR/POOR/VERY POOR rather than a numeric score. Crossing reports retain exact food losses and describe injuries without showing health-point damage; numeric deltas remain available in structured history for simulation accounting. The display bands (80/50/20 boundaries) are provisional, not recovered classic thresholds. No individual disease/death or weather model has been added.
- All existing simulation, route, art, UI and 46 headless motion checks pass; graphical motion capture passes 58 checks. Inspected the actual updated result screen and regenerated the review GIF. These checks validate current behavior, not classic health fidelity.

## Inspectable individual party — October 22, 2026

- Added independent per-member health/conditions, dated personal histories, recovery and irreversible death. Party condition derives from survivors; subsequent ration demand follows their count. Personal health notices interrupt travel and enter the journal. `data/health_conditions.json` provides validated provisional tuning; the original short-leg fixture remains aggregate-only.
- View Party lists all five people and opens selected personal details without exposing health points. Opening pauses travel and crossing animation. A single content wrapper keeps the roster and history columns separate inside the dialog; the UI test verifies they do not overlap. Inspected the rendered `docs/party.png`, a deliberately injected multi-condition/death fixture.
- **3,185 simulation, 26 route, 69 art, 46 headless motion and 30 health checks pass**, with zero UI-suite failures. The health suite passes with the graphical renderer too; motion capture passes 58 checks. Health tests include content rejection, individual damage, stable identities, named fatal illness/recovery, no revival, survivor rations, no-survivor loss, seeded replay, interruption/acknowledgement, personal-history selection, read-only viewing, animation pause and restart cleanup.
- Source-level health fixtures in route/motion tests now set individual health, rather than editing only the derived party summary. No survival probabilities, injury durations or category thresholds are claimed to reproduce the selected classic executable or actual disease behavior. See `PARTY_HEALTH.md` for the current limitations and continuation policy.

## BASIC survival foundation — October 22, 2026

- Added validated seasonal weather, visible precipitation/fog, exposure and clothing protection, rain-linked river changes, team size/condition/fatigue and load/terrain movement factors. Travel works the team; hunting and other stopped activities let it recover, with additional recovery during full rest. Insufficient food uses the poorest nutrition risk/severity branch even if the ration setting remains Filling.
- Added optional opening care/repair supplies, individual care and $20 medical-attention choices, ration-dependent mild/bad/serious severity, mouse hunting with ammunition/shot/carry limits, and trail purchases/sales/barter. Services preserve an unresolved landmark and backing out cannot spend time or change river stage for free.
- Added all sixteen source-selector encounter categories plus rider tactics as recurring JSON events, with weather eligibility, relative weights, cooldowns, typed spare use, named conditions and affordable alternatives. Every encounter choice is exercised. Actual stock-limited supply deltas are journaled separately from ordinary daily rations; crossings also record clothing loss.
- **3,185 simulation, 26 route, 69 art, 46 headless motion, 30 health and 112 survival checks pass**, with zero UI failures. Sixty player journeys use a public-action survival policy including hunting/rest and affordable resolutions; 1,000 legacy short-leg journeys remain intact. Survival tests include data rejection, actual movement/exposure, team/terrain, wet river risk, accounting, care, hunting mouse hits, duplicate-action guards, all event branches, cooldowns, service cancellation and restart cleanup.
- Graphical UI, health and survival suites pass; motion capture passes 58 checks. Inspected native-resolution store, hunting, status, guide and scrolling trade windows. Updated captures and the actual-rendered crossing GIF document the pass. New animal art is original code-drawn pixel work.
- No route extension, history certification or final balancing is claimed. `BASIC_SURVIVAL_BENCHMARK.md` records intentional adaptations, unverified formulas/service availability and the remaining route/terrain work. Historical services, climate calibration and final gameplay tuning remain explicit work before extending the road.

## Source-grounded balance pass 01 — October 22, 2026

- Compared inspected BASIC travel/ration/severity expressions with Palmer's 1847 outfit advice and NPS travel/load ranges. Added an evidence/limit manifest, including the 1849 epidemic chronology. Source advice is not treated as universal measurement or a clinical model.
- A separate real-engine experiment records 480 pre-change and 600 post-change policy runs (120 per profile, with Meager added afterward), seeds 0–19, three departure months and two budgets. A seeded 65% shot model replaces perfect hunting. Raw grouped results and the formatted before/after report are saved. These are modeled policies, not human playtests or historical mortality estimates.
- Tuned player-route nominal paces to 16/20/24 to bring cautious actual movement from 9.4 to 12.1 miles/moving day. Recovery on fed rest now follows rations (3/5/7 internal points). Nutrition-linked automatic onset excludes injuries; accidents can produce either broken arm or broken leg; automatic cholera begins in 1849+. Legacy fixture movement/rest values are retained.
- All existing checks pass, with **118 survival checks** now covering validated pace/recovery tables, actual ration-dependent rest, date eligibility and accident/illness separation. The full suite retains 3,185 simulation, 26 route, 69 art, 46 motion and 30 health checks with zero UI failures. The report documents the failed overly harsh initial recovery trial rather than calling its results historical fact.
- Rations, prices, complete load, species availability, regional climate and historical disease incidence remain uncalibrated where evidence is insufficient. No 10% whole-trail death estimate was converted into an opening-chapter daily death target. No route extension was made.

## Hunting depth pass — October 22, 2026

- Added a separately seeded activity model and validated JSON hunting rules: habitat pools, variable/empty encounters, directional movement and escape, gunfire flight, movable hunter, cover collision/line of fire, reload timing and bounded outings. All graphics remain original code-drawn pixels.
- Full staging suite passes: 3,185 simulation, 26 route, 69 art, 46 headless motion, 30 health, 121 survival and 218 hunting checks, with zero UI failures. Rendered survival suite also passes all 121 checks; native hunting captures were inspected for readable controls and status.
- Archived 600 policy runs in `hunting-balance-results.json`; cautious chapter arrivals remain 120/120 intact, with about three hunts per journey. The policy exercises reload/encounters but not human cover navigation or aiming; this is not a final difficulty or historical mortality calibration.
- See `HUNTING.md` for source limits, current control scheme, provisional meat yields and remaining preservation/region work.

## Food baseline, journey saves and memorials — October 22, 2026

- Replaced the food-only load cliff with explicit cargo; added fresh-meat batches, oldest-first meals, spoilage records, proportional partial-food penalties and cargo discard controls. Store shows mass and food-days estimates. The suggested 800 lb outfit totals $380. Hunting now varies recoverable yields within documented brackets and limits returns by free cargo space; a return report shows actual carried/wasted meat.
- Saved two 600-run policy experiments at 600 and 800 lb starts. The policy now resupplies for cash when possible rather than looping exclusively on hunts. At 800 lb, cautious parties reached the chapter end intact in 120/120 runs. These are documented game-policy observations, not historical mortality estimates.
- Added versioned JSON saves with rule compatibility checks, full state/RNG continuation, previous-file backup and safe load failure/recovery. Added original pixel gravestone editing, separate persistent archive and later roadside encounters. No route extension was made.
- Full staging checks pass: 3,185 simulation, 26 route, 69 art, 46 headless motion, 30 health, 122 survival, 218 hunting, 15 provisions, 146 saves and 11 graves, plus zero UI failures. Rendered survival/grave suites pass and native store/provisions/gravestone captures were inspected. See the food and persistence documents for remaining modeling and persistence limits.

## Continuous western route — October 22, 2026

- Added a 36-stop, 1,938-reported-mile southern/Barlow itinerary through Oregon City. Direct legs are compared against the extracted primary distance-table row IDs; Kearny and Barlow subdivisions are explicitly labeled allocations. The old Platte endpoint remains only in named opening regression fixtures.
- Authored 30 new stop scenes plus the pre-June Kearny variant and three travel-region landscapes. Viewed the Bullock Fort John plan, Jackson Three Island painting, Wilkins 1849 Soda Springs drawing and municipal WSU/Warre Oregon City view. Reference hashes, dates and limits are recorded; source pictures are not reused as game art.
- Added post bulk trading with stop-preserving windows, free trail notes, livestock-sensitive Barlow tariff, careful/hurried Laurel Hill descent with exact clamped loss reporting, western hunting pools and an Oregon arrival report. The complete-road movement pass rejects the initial roughly nine-month trial; prepared-party samples now average about 13 moving miles/day and roughly six months.
- Twelve full-route policy runs (two departure months, six seeds) reached Oregon City; 59/60 travelers survived. This is a well-funded prepared-party comparison, not a historical cohort or all-profession balance certification. Raw results and the source/game comparison are archived.
- Added verified migration of the preceding 317-mile save fingerprint; old Platte completion resumes west without consuming time or losing people/supplies. Unknown rule mismatches still preserve files and fail safely.
- Current checks: 3,185 simulation; 85 route; 167 art; zero UI failures; 46 headless motion; 30 health; 122 survival; 218 hunting; 15 provisions; 149 saves; 11 graves; 1,627 full-trail checks. Full-trail rendered checks also pass; Oregon arrival, post trading and native-pixel scene galleries were visually inspected.
- The continuous overland road is complete; optional northern shortcuts, Walla Walla detour and Columbia transport/portage gameplay remain explicitly unimplemented. Regional weather, ecology, prices and lower-budget survival still need deeper calibration.

## All-profession full-trail experiment — October 22, 2026

- Archived 2,700 journeys: 720 baseline, 720 adaptive-cash/toll policies, and 1,260 hunting/care cases with three aiming assumptions, two hunting thresholds and two ration sizes. All three professions, March/May/August departures and the same suggested $380 outfit are represented. See [full report and mechanic coverage](FULL_TRAIL_BALANCE.md).
- No game rules changed. Selected state/setup invariants reported zero errors; poor balance outcomes are retained. Every tested farmer policy failed, while wealthy cautious parties could arrive without hunting. Fresh-meat spoilage, outing time, starting cash and medical/resupply expenses need joint review. This does not prove every possible farmer outfit or policy is unwinnable.
- The baseline toll blocks were automated-decision failures, resolved in the adaptive batch using existing sales. Hunting skill assumptions exercise the real moving/cover/reload/escape model but are not human skill measurements. Reused seeds make these paired scenarios, not independent historical trials.
- Full regression suite rerun successfully: 3,185 simulation; 85 route; 167 art; zero UI failures; 46 headless motion; 30 health; 122 survival; 218 hunting; 15 provisions; 149 saves; 11 graves; 1,627 full-trail checks. No human playtest is claimed.

## Economy and preservation — October 22, 2026

- Rechecked the 1978 BASIC food/hunt/fort formulas, the supplied 1985 manual, Bouchard's carry-limit explanation, Palmer's outfit/price notes, BLM's reprinted accounts and Marcy's later preservation account. Sources and limits are in `research/ECONOMY_PRESERVATION_SOURCES.json`; no exact historical profession-income or mixed-food/salt receipt is claimed.
- Changed trail funds to $600/$900/$1,400 for farmer/carpenter/banker; opening staples to $0.06/lb; suggested food to 1,700 lb, plus two kits and ten lb salt. The suggested $333, 2,359 lb cart leaves the farmer $267. Wagon/gear ownership is explicit in the shop. Mountain resupply prices remain high.
- Added real camp-day preservation with meals/spoilage first, finite expiry, processing losses, optional consumed salt and separate dried cargo mass from meal-equivalent food value. Supplies, history and UI show the costs. Salt can be bought/sold/discarded. Prior verified saves migrate with existing funds/supplies and no free salt; preserved meals replay deterministically.
- Archived 3,600 final-rule journeys across professions, months, three aim levels and no-hunt/fresh/dry/salted controls, including seeds 20–39 checked after the development sample without tuning. At 65% scripted aim, farmer arrivals were 21/120 fresh-only, 96/120 dried and 102/120 salt-assisted; arrival can include companion deaths. Long eight-to-nine-month survival journeys and simplified regional/winter hazards remain limitations, not historical success-rate calibration.
- Full suite passes: 3,185 simulation; 85 route; 167 art; zero UI failures; 46 headless motion; 30 health; 122 survival; 218 hunting; 15 provisions; 48 new preservation checks; 149 saves; 11 graves; 1,627 full-trail checks. Store and preservation controls were also rendered and visually inspected. No human playtest is claimed.

## Spare oxen and camp meat — October 22, 2026

- Confirmed the supplied 1993 game has slaughter/meat-award/no-team text. Added explicit spare-ox slaughter through Provisions/Cargo, with a review/cancel step. Shooting uses exactly one bullet; assumed hand tools use none with an authored 35% wound chance. Both take a day, recover all usable meat without the hunting cap, allow cargo overload, feed today's meals, enter preservation/spoilage and preserve the last pulling pair.
- Grazing remains assumed and oxen do not consume human meal stock. Full fodder/water/pasture and herd upkeep remain unimplemented. Modern yield guidance is a scale reference only; shared team condition and 200–400 lb usable meat are tuning, not measured 1848 yields.
- Twenty-three new oxen checks pass, plus the complete existing suite. Rendered supplies and confirmation were inspected. A genuine prior preservation-version save was generated before updating the Projects copy and restores without changing its state or batches.
- Matched 360 journeys: farmer arrivals 54/60 without the spare-ox policy and 55/60 with it; intact arrivals 22/60 versus 50/60. No hand-tool actions or purchase-to-slaughter loops in that policy. See `OXEN_AND_CAMP_MEAT.md` and `reserve-team-oxen.json` for boundaries.

## Last-animal emergencies and walking recovery — October 22, 2026

- Removed the protected pulling pair: one ox can travel slowly; zero stops the wagon but leaves camp actions accessible. Added soft 625/1,250/1,875/2,500 lb team-load guidance for one/two/three/four-plus animals, without silently deleting overload. Shop and provisions display the limits.
- Added a reviewed pack-selection screen, one-day wagon abandonment, limited walking cargo, original walkers, foot river/descent/toll behavior and suppression of wagon-only mishaps. Money and surviving livestock remain with the party; unselected stock is cached at the actual mile.
- Added daily survival backtracking to the original location, aging cached food, seeded permanent cache loss, recovery with one ox, and conserved repacking without an animal. Cache and RNG survive saves; prior verified saves load with an empty cache. Return trips currently do not replay intermediate crossing choices or random encounters.
- Full suite passes, including 33 oxen and 32 new walking/cache checks. Native pack and walking captures were inspected. The 360-journey small-team policy comparison is archived; walking has focused integration checks, not a claimed all-route difficulty calibration. See `WALKING_AND_RECOVERY.md` for the authored weights, risks and remaining abstractions.

## Swimming on foot — October 22, 2026

- Foot travel now offers swimming or an available ferry. Authored mishap risk is 30% in low water and 80% in high water, above wagon ford/float risks at the same stage. Shared crossing damage affects individual health and records actual lost supplies in dated history.
- Original pixel swimmers stroke across the river, struggle and lose supplies on a mishap, then stand on dry banks. Foot ferry passengers stand aboard the platform. Rendered success and mishap frames were inspected.
- Pending swim offers and completed accidents round-trip through saves. Older pending wading offers upgrade without rerolling randomness or changing past history. The prior foot-crossing save validation omission is fixed.
- All regression suites pass, including 44 walking/cache checks, 149 save checks and 46 motion checks. This is authored emergency gameplay, not a historical swimming-risk reconstruction.

## Four-ox baseline and emergency survival study — October 22, 2026

- Kept four oxen at 100% pulling speed; five at 105%, six or more at 110%. One/two/three retain 25%/50%/75% before load and environmental modifiers. Bonus caps at six; wagon capacity and grazing assumptions are unchanged. Store/provisions expose the rule and were rendered and inspected.
- Added validated JSON team-speed factors, a flat no-bonus control, compatibility for the verified previous rule fingerprint, and a real pre-update save fixture. Existing money, stock, animals, time and random states survive migration.
- Full regression passes: 128 survival and 44 oxen checks, along with the existing walking/crossing/save/health/hunting/preservation/route suites. Prepared-party full-route checks now total 1,555 because updated mileage changes the number of steps.
- Archived 6,480 matched journeys plus 1,440 replacement-team follow-ups with zero invariant/setup errors. Forced emergency scenarios include cache abandonment, maximal valid packs, two actual walking days before backtracking, real cache loss and spoilage, final-ox slaughter, walking swimming/ferries, death-reduced capacity and public-action discards. The test policy now resupplies according to pack room and skips oversized bulk lots on foot.
- Matched successful six-ox journeys saved median 15 days with the bonus; four-ox controls were unchanged. Under bonus-on policies, replacement toward four animals yielded 321/360 arrivals; walking then cache recovery/rebuilding 212/360; late walking 131/360. Early walking had none under this policy and one-year cap. Arrival means at least one survivor, not all five. Food shortages dominate walking deaths. See TEAM_SIZE.md and the raw archives for full denominators, outcomes and limits.
- No human playtest or historical death-rate calibration is claimed. Trader scheduling, forage upkeep, and walking to nearby refuge/alternative transport remain design limits. Backtracking still does not replay intermediate river decisions.

## Regional conditions, finite traders and landmark activities — October 22, 2026

- Connected five existing habitat regions to weather selection, purchase premiums, passing-trader cycles and working-team forage strain, with a dry-season increment. Existing regional hunts, clothing/exposure, river stage and team rest still apply. These are authored proxies, not measured historical climate, grass or water budgets.
- Passing opportunities use deterministic four-day regional windows; finite buying and selling quotas persist across reopening and saves. Posts have persistent limited stock; waiting and every transaction consume actual days/meals. Existing post bulk-food prices remain explicit. Regional premiums apply to other purchases.
- Added twelve original stop conversations, three grazing activities and three crossing-gear preparations. Activities consume declared resources/time, remain at their landmark and cannot be repeated for free gains. The new Local Conditions / Stop Activities menu exposes them without requiring travel-pane scrolling.
- Added strict context/save validation, a real pre-update save fixture and verified fingerprint migration. Old pending quotes are honored; new menus use current opportunities and quotas. Prepared crossings, used activities, current quotes and consumed stock survive loading. Current saves cannot omit the ledger to refill stock.
- Full regression suite passes, including 47 new context checks and 1,856 full-trail integration checks. Native available-trader, waiting and local-activity screens were rendered and inspected; the real preparation button was exercised.
- Archived 360 ordinary journeys plus 6,480 matched survival/emergency runs and 1,440 rebuilding follow-ups under these rules; all have zero invariant/setup errors. Policies were updated to respect availability, rest worn teams, inspect stock, consider activities and preserve pending health acknowledgements. Counts and limitations are in REGIONAL_TRAVEL.md. Older team reports retain earlier rule signatures.
- Broader historical pricing, finer regions, water-source management, individual animal upkeep, localized paid medical care and refuge/transport remain future depth. Human playtesting is still needed, particularly for the substantially harder walking outcomes under scarce traders.

## Care access, combat consequences and food warnings — October 22, 2026

- Read the actual player save and backup without changing either. Recorded starvation on days134–139 and three deaths on139, followed by emergency slaughter and eventual two-person arrival. The save predates regional trader scarcity; no new-rule cause is inferred for its older journey.
- Restricted paid local help to four designated stopped posts, retained roadside self-care kits, and guarded actual selection of old offers. The service is labeled local care, not a verified resident1848 physician.
- Added validated combat JSON and saved party-level outcome history. Poor condition/fewer able defenders raise risk; three prior clean hostile defense wins cap experience help. Both defense and circling can injure/kill one traveler; serious wounds can be fatal later. Friendly rider intentions stay hidden and grant no victories.
- Added spoilage-aware three-day warnings before automatic travel/main Camp spending another day, plus a distinct empty-food warning. Preview and acknowledgement do not mutate supplies or RNG. Native warnings, defense and roadside care were visually checked.
- Full regression suite passes, including31 dedicated checks,2,400 matched hostile encounters and360 journey attempts with zero invariant errors. A real pre-update fixture verifies state-preserving migration without inventing victories; pending quotes/history round-trip. Detailed findings and limits are in CARE_COMBAT_AND_SAVE_REVIEW.md.

## Camp rest duration — October 22, 2026

- Camp and landmark rest now accept a typed whole-number duration from 1 to 30 days, with a meal estimate and free cancellation.
- Each day uses ordinary simulation rules; encounters, new health news, deaths and new food warnings interrupt the plan. Reports record completed versus requested days.
- Added dedicated input, layout, daily-equivalence, RNG, interruption and landmark regression checks. Native prompt and result screens rendered and inspected. Existing saves require no migration. See CAMP_REST.md.


## Companion foundation — October 22, 2026

- Added seeded companion traits/backgrounds, leader trust and twelve recent memories per companion. Actual rest, grueling travel with illness, medical care and hostile defense can produce explained reactions.
- No survival bonuses, autonomous actions or departures. Eight seeds times 35 paired policy steps preserve survival state and all existing RNG streams with reactions enabled or disabled.
- Dedicated suite: 315 passing checks, including actual action hooks, friendly/dead exclusions, bounded memories, save compatibility and malformed records, plus native party-screen inspection. See PARTY_CHARACTERS.md.


## Party boundaries, Loyal and wage framework — October 22, 2026

- Added approved/disapproved/forbidden action queries, reluctance and breaking thresholds, explicit betrayal capacity, leader relationship setup and special identifiers. No crimes, departures, recruitment or automatic family/special assignment.
- Loyal halves ordinary negative trust changes with half-point persistence; forbidden penalties remain full. Existing traits and memories migrate into validated character schema 2 without invented debts.
- Explicit mercenary agreements accrue integer-cent debt, allow payment on the due day, penalize missed installments once, and reward settlement without gifts or repeated-payment farming. Old debt retains its overdue status when a new bill arrives.
- Due dates pause automatic travel or a multi-day rest. View Party displays terms and supports actual payment, including final settlement after arrival.
- 62 dedicated framework checks pass, plus the existing 315 character checks. Native wage screen inspected. See PARTY_FRAMEWORK.md for scope and API details.


## Pre-departure party customization — October 22, 2026

- Added companion selection, temperament/values, backgrounds, leader relationships, special checkboxes and explicit mercenary terms to the illustrated preparation screen.
- Drafts survive switching and store visits without live state/RNG changes. Optional simulation setup validates atomically before buying supplies, commits independent profiles and starts agreed wage schedules only at departure.
- Dedicated setup tests cover actual controls, store/back, exact wage terms, invalid-input rejection, family/friend trust, departure, save/load and reset. Native preparation panel inspected. See PARTY_SETUP.md.

- New mercenary terms enforce a provisional minimum 100 cents per journey day and at most seven days between payments, in both UI and simulation. Existing saved contracts retain agreed terms. Setup suite: 17 checks pass.


## Background and special wage quotes — October 22, 2026

- Replaced the flat new-contract minimum with a pure background-based quote. Compassionate reduces demands, Pragmatic raises them, and Loyal/Veteran have explicit premiums. No skill levels, survival bonuses or new random rolls.
- Setup shows the contribution breakdown and updates the interval-adjusted minimum on edits. Both setup validation and direct contract creation enforce it; existing agreements are preserved.
- Framework suite: 72 checks; setup suite: 19 checks, including individual minimum rejection, Loyal/Veteran updates and unchanged agreements. Native quote panel inspected. Rates are provisional and documented in PARTY_SETUP.md.


## Background benefits and companion news — October 22, 2026

- Added validated party-benefit JSON: shorter hunter reloads, shorter time-based repairs, enhanced quoted care, five-percent purchase discounts and a bounded Veteran risk reduction. Fit living companions only; duplicate effects do not stack.
- Named gratitude/objections and trust-band warnings enter the saved party-news acknowledgement flow. Defense/grueling travel concerns are visible before commitment. No skill progression, departures or crimes.
- Preserved a real pre-update save fixture; recognized its old rules fingerprint and retained pending quotes/state/RNG. Enhanced care fields validate and round-trip.
- Full regression passes; dedicated benefits suite has 29 checks. Existing purchase tests now explicitly expect discounts; paired character-policy checks test determinism under the new mechanics.
- 360 full-route journeys: 344 arrivals, zero invariant/setup errors. Farmer 52/60 per policy, carpenter/banker 60/60. No paid-specialist or Veteran-party value conclusion is inferred. See BACKGROUND_BENEFITS.md and background-benefits-oxen.json.


## Refusal, settlement departure and paid/free tradeoffs — October 22, 2026

- Critical trust and forbidden boundaries can withhold background/defense participation. Persistent trust crisis or three unpaid installments produces a saved warning, with a day of notice before settlement departure.
- Explicit review transfers only listed available meals, clothing and personal gear. Departed people remain alive in history, stop eating/health progression/wages, reduce active counts and walking capacity, and do not alter cached goods. No departures at crossings or unbuilt early Fort Kearny.
- Schema 3 validates notice/departure/cargo records and migrates a real previous schema-2 fixture. Dedicated departure suite: 43 passing checks. Native review and departed-person screens inspected.
- Wage rewards normalize to +2 per seven paid days; late settlement reward is capped weekly. Store shows recurring commitments. Daily/weekly equivalence and actual payment paths are tested.
- 360 matched journeys, zero invariant/setup/save errors. Comparison records trust, retention, costs, deaths and departures. Funded banker paid parties retained all companions and averaged 80.1 trust versus 61.2 free, both 30/30 arrivals. Wage-poor cohorts lose members; arrival alone is not a ranking. See COMPANION_CONSEQUENCES.md and specialist-balance.json.



## Historical wage and economy pass — October 22, 2026

- Visually checked the federal census scan, printed pp.164–165/PDF32–33, and retained a hashed local copy. Distinguished 1848 boarded monthly labor from 1850 daily unboarded trade rates and later western boom wages.
- New cash-plus-food quotes: background bases40/90/50/60 cents per journey day; personality ±5, Loyal+10, Veteran+20. Opening ox30 dollars, salt6 cents/lb, passing ox45-dollar base. Budgets and unsupported bundles explicitly marked as authored abstractions.
- Historical economy suite112 passing checks, including all32 quote combinations at three payment intervals, malformed data rejection, exact outfit totals and an authentic previous-economy save with a higher contract retained.
- All existing regression suites pass in staging, including full trail1883, saves149 and departures43. Native wage editor rendered and visually inspected. Cash history deltas now use whole cents, fixing an exact round-trip failure exposed by the new fractional opening costs.
- 540 matched full-route journeys; zero selected state/setup/save errors. Includes one/two-hire cohorts, food/hunting, weather/disease, finite trading, wages and departures. Historical wage report retains results and limitations; previous specialist report remains archived. No human playtest claimed.

## Creation specials and flaws — October 22, 2026

Full staging regression passes. Party setup: 28 checks; party flaws: 27 checks. Two specials normally, three with exactly one optional flaw. Both UI and engine enforce the creation budget; old saves retain their specials. Personal health effects, saved/restored effects, independent drafts, invalid setup rejection and native UI capture are verified. See PARTY_FLAWS.md for exact effects and scope. No new full-route balance cohort is claimed.


## Expanded character catalog — October 22, 2026

Catalog suite: 576 passing checks, including 256 reproducible legal candidate offers, actual editor/departure, health/trust effects, helper eligibility and prior-catalog save compatibility. Existing regression suites pass. Twelve generated full-route parties: twelve arrivals,59/60 surviving travelers,zero departures,zero selected state/setup/save errors. This banker-funded integration sample is not a balanced survival-rate study. Native editor capture inspected. See CHARACTER_CATALOG.md and generated-party-journeys.json.


## First store incident slice — October 22, 2026

Store suite: 1,021 passing checks; native menu captured and inspected. Dedicated independent RNG and staged incident state round-trip. Actors, local knowledge, exact food/cash transfers, real ammo/day/meals, attempt reactions, physical barter depletion, store closure and capture are covered. Twenty-four full-route store-action/control runs finish with zero selected state/save/policy-loop errors. All24arrive in this banker-funded integration sample; this is not survival balance. The sampler now rejects limit outcomes and avoids treating a closed-store Back choice as a purchase. Canonical final regression is recorded in CLAUDE_HANDOFF.md.


Final checkpoint: all suites in the canonical Projects test.ps1 passed after all store refinements; exit0. Twenty-one changed files hash-verified during sync. Handoff completed with the last usage reading at2% remaining.



## Expanded ribbon, place choices, local targets and exits — October23

Feature commit `e0779d4` passed all42Godot suites from an isolated clean checkout. Dedicated coverage:53ribbon/preferences/exit checks,29local-target/place checks,46recruitment checks and119companion checks. UI tests use actual section buttons and an actual embedded title-bar X click. Save checks cover selected local staff/transient targets, dead staff and archived recruits.

The same feature commit completed24store and20outlaw full-route journeys without reported errors. These existing policies do not recruit replacements or optimize social/foraging choices, and target venue owners rather than every supporting worker. They provide regression evidence; the dedicated suites cover the new actions directly. Older balance campaigns are not validation of the combined new mechanics. Generated reports stay in ignored local storage. Native800x360 setup, trail, contextual place buttons, villainy hierarchy/local staff/toll collector, preferences and map were inspected.
