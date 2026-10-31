# Columbia / Cascades rafting prototype

Current presentation: [approved isometric artwork](RAFTING_ART.md) is installed in the main game, with obstacle circles removed. The sections below retain the prototype and tuning history.

The existing Columbia branch now has a playable isometric steering activity at **Cascades of the Columbia**. Running it replaces the old single 30% wreck roll. The Barlow route, 1,894-mile river itinerary, three-day raft building at The Dalles and two-day portage alternative remain.

## Try it

Double-click `play-rafting-prototype.cmd` from the repository. It opens the real game at the Cascades with a supplied practice party. Its user-data folder is `.tools/rafting-practice-userdata`, separate from normal saves. Press **F6** to restart the practice scenario. In ordinary play, take the Columbia branch at The Dalles and reach the Cascades stop.

Choose **Run the rapids · steer the raft · 1 day**, then press **START**. Move the pointer across the river to steer toward that cross-channel position; pointing farther upstream does not change the desired channel position. Avoid rocks, drifting logs and the shoreline. The current causes a small sideways drift. Hull condition and remaining seconds are visible. PAUSE freezes the model; the window's X pauses and keeps the run open. Press CONTINUE after a finish or wreck to settle the outcome.

The simulation is separate from rendering: deterministic generated course, fixed 60 Hz physics, one collision per obstacle, and a 1.5-second bank-impact cooldown. Large frame gaps are capped to prevent unseen collision jumps. The same seed and launch day give the same course. Thirteen hazards in authored passage patterns over twenty-five seconds are prototype parameters, not a map or time scale of the real rapids. See [current pattern design and validation](RAFTING_PATTERNS.md). A0.35-second collision grace prevents stacked cluster damage.

## Consequences and calendar

Launching spends no supplies or trail time. Finishing commits **one day**, with normal meals, weather, health, animal care and wages. Active runs block saving, loading and other activities; a paused run remains active. Finishing twice cannot charge twice. Portage skips the minigame and takes two normal days.

Each impact removes 20 points from the activity's 100-point hull condition. Five impacts wreck it. Each impact can cost 12 food units, capped at 60; three or more can also cost one clothing set. Losses are capped to actual inventory and recorded separately from meals. Two impacts can wound a real traveler; three or more can break an arm. A wreck causes the existing 15-point near-drowning damage to the party and has an authored 20% chance of drowning one actual survivor. There is no additional hidden 30% wreck roll after a clean run.

Individual injuries and deaths use the existing party health/history system. The journal, supply history and saved `rafting_history` retain the actual outcome, including every traveler killed by collision damage rather than only the separate drowning roll. If survivors remain after a wreck, the story assumes they reach shore and re-lash salvaged material into a raft within this abstract activity day; there is no persistent boat-resource system yet. The surviving party then continues the existing lower-river leg. A successful rapid run does not instantly finish the whole trail.

These collision, loss, injury and drowning numbers are authored prototype estimates. Passing tests establishes accounting and reachable outcomes, not that the difficulty or historical mortality is calibrated.

## Historical basis and boundaries

The [National Park Service Gorge history](https://www.nps.gov/articles/000/overlanders-in-the-columbia-river-gorge-1840-1870-a-narrative-history.htm) distinguishes the roughly forty-mile reach below The Dalles from the roughly six-mile Cascades obstacle. It describes extensive Chinookan navigation and portage services, with nearly all 1843 overlanders paying for portage assistance. Many emigrants sent livestock by trails instead of transporting them on rafts. This supports a cautious portage alternative and a deliberately hazardous rapids option, rather than depicting running rapids as the usual safe choice.

The prototype represents the **Cascades**, not Celilo Falls upstream. Existing route simplifications remain: the party's animal bookkeeping stays together, and the onward river leg combines lower Columbia travel with the upstream Willamette approach to Oregon City. Those are abstractions, not claims that animals all rode the deck or that the current carried rafts upstream. Hiring and paying guides, separate livestock drivers and detailed final-leg navigation remain outside this first activity.

## Art

The screen reuses the project's existing `river_crossing`, `cross_raft`, `cross_wagon`, `cross_people` and `flotsam` art, with palette recoloring of the actual travelers. Banks are mirrored to match the raft projection. Collision rings and simple rock markers are temporary gameplay guides. The confusing channel-edge lines have been removed; collisions now use the visible coast with a margin for the raft hull. No newly commissioned scene or copied proprietary art was installed. See [the final-art brief](RAFTING_ART_BRIEF.md) before drawing the dedicated Gorge/rapids animation set.

## Files and persistence

- `simulation/rafting.gd`: standalone model and strict outcome validation.
- `data/rafting.json`: authored prototype parameters, included in the rules fingerprint.
- `ui/rafting_scene.gd`, `ui/rafting_view.gd`: existing-art projection, mouse input, controls and feedback.
- `simulation/trail_engine.gd`: launches from the Cascades choice and commits real outcomes.
- `tests/play_rafting_prototype.gd`: isolated practice scenario only.

The previous exact rules fingerprint is allowlisted. Previously saved Cascades choices upgrade from their old `portage_risk` field to the interactive choice without changing earned money, supplies or time. Old saves gain an empty outcome history. Malformed records are rejected, and active minigame sessions are not serialized.

## Validation

All102 regression suites pass. Final focused suite:135 checks. Coverage includes fixed-step equivalence at30/60fps, invalid inputs, forty generated courses completed by an avoidance policy, bank-induced wrecks, no repeated obstacle damage, atomic launch/settlement, blocked conflicting actions/saves, real cargo loss, individual wounds/drowning, old-save migration, malformed outcome types, portage and native pause controls. Final save suite has149 checks.

Local logs: `.tools/rafting-full-tests.log`, `rafting-targeted-final.log`, `rafting-branches-final.log`, `rafting-saves-final.log`, `rafting-practice-smoke.log`. Native screenshots inspected: `.tools/rafting-choice.png`, `rafting-prototype-start.png`, `rafting-prototype-running.png`, `rafting-prototype-wreck.png`, `rafting-prototype-report.png`. The generic scene and obstacle markers still need player feedback and final artwork.

## First player clearance revision

Spencer found the raft too large for the gaps and the internal edge lines confusing. The revised view gives the same raft more room, centers its deck on the physical collision point, and reduces14 hazards to10 (about2.85seconds between obstacles instead of1.97). The gold channel lines and steering guide were removed. Both shores are framed in view, and bank collisions follow the existing coastline rather than an internal invisible channel. A hull half-width prevents the deck from passing onto land.

Coast bounds are calibrated from the existing crossing background's alpha boundary at the raft station and stored in the rafting rules. Tests sample actual water/land pixels on both sides of both shores, verify clear water outside the old guides is safe, and verify the hull is stopped at the coast. Forty generated courses also complete with a one-second delay in avoidance commands. This checks reachable steering with reaction time, not human difficulty certification. Collision penalties and injury/drowning rates are unchanged.

## Full-width obstacle placement

Spencer found that the widened river left the shoreline routes free of obstacles. Course version2 now stratifies ten hazards across the entire hull-clear river width, with extra coverage near each shore and a deterministic shuffled order. Placement is generated before steering starts and never follows the player. The existing long gaps between hazards, current strength, steering speed and collision penalties are unchanged.

In the actual physics tests, eighty constant near-shore runs (forty seeds, both shores) each hit at least two real obstacles, without counting bank contacts. Another104 runs sampling thirteen fixed lateral routes across eight seeds all met an obstacle. The ordinary avoidance policy still completes forty courses, and forty more courses complete with a one-second steering delay. This removes a collision-free bank rail without rebuilding the cramped course.

Focused rafting suite:157 checks. Native regenerated course view inspected; local logs `.tools/rafting-full-width-tests.log`, `.tools/rafting-full-width-visual.log`, `.tools/rafting-full-width-regression.log`. Rules fingerprint includes course_version2 and the previous exact signature remains migrated, preserving saved party state and completed outcomes.

Full-width generator validation: all102 suites pass, including157 rafting checks (`.tools/rafting-full-width-regression.log`).

## Faster approach after playtest

Spencer found the full-width course too easy. Rafting now travels at18 world units/second instead of15: a20% increase. Duration is25seconds instead of30, keeping the exact450-unit course, ten obstacle positions, physical gaps and wide shore boundaries. Average encounter spacing becomes about2.38seconds rather than2.85. Steering response, drift strength and collision/casualty costs are unchanged.

The actual-physics checks still complete forty courses using ordinary avoidance and forty with a one-second steering delay. The previous bank-hugging/fixed-lane tests still pass. Old completed30second records remain loadable; the outcome validator retains their1800tick history. Focused suite168 checks; log `.tools/rafting-faster-tests.log`. Full regression log `.tools/rafting-faster-full-tests.log`.

Pace revision validation: all102 suites pass, including168 rafting checks (`.tools/rafting-faster-full-tests.log`). Updated native countdown and course view inspected.

## Slightly higher obstacle rate

Spencer requested a small increase after testing the faster approach. The course now has12 obstacles instead of10 over the same25seconds and450 world units. Average spacing between hazards is about1.94seconds (35world units), previously2.38seconds. The wide shoreline geometry, raft footprint, speed18, steering response and penalties are unchanged. Full-width, shore-adjacent coverage remains seeded rather than following the player.

Focused suite172 checks pass, including ordinary and one-second-delayed steering across forty courses each, the bank-hugging tests and saved-history compatibility. Logs: `.tools/rafting-density-tests.log`, `.tools/rafting-density-full-tests.log`. Restart the practice application to load the revised rules.

Obstacle-rate revision validation: all102 suites pass, including172 rafting checks (`.tools/rafting-density-full-tests.log`).
