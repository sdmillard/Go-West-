# Companion camp work: first playable stage

October 24, 2026. The shared camp-day stage is implemented. Away hunts, repair, stock guarding, mounted tasks and new backgrounds remain later stages in [the implementation plan](COMPANION_TASKS_IMPLEMENTATION.md).

## Playing

Open **Camp > Companion tasks**. Give each companion a standing job: Rest, Forage, Dry meat, Salt + dry meat, Nurse a named patient, or Help leader hunt. The roster is a bordered table, with one companion and their complete assignment per row. Click the task cell: Nursing branches to a traveler list, and Dry meat branches to air drying or salt-assisted drying. The completed row reads, for example, Nursing Dan. The window fits the table and cost footer, shrinking when fewer companions need rows and scrolling only when necessary. Descriptions and eligibility details appear on hover. The bottom summarizes one shared day, meals, reserved kits, morning meat, salt and upcoming wages; warnings explain blocked jobs. This is a read-only estimate with the leader resting, and the chosen leader action can change available inputs. Assigning jobs takes no time.

Selecting the first assignment enables shared camp work. Unassigned companions rest; only assigned hunt helpers accompany the leader and haul meat. Clear jobs / Use group actions restores the earlier whole-party action behavior. Existing saves and new journeys begin with group actions, allowing the new labor model to be tested without silently changing a player's existing strategy.

Use Rest, hunt, forage, care or preservation as the leader's action. Jobs run during those camp days, including each day of a multi-day rest. They pause during travel, crossings, trading and unrelated event delays. Trading alongside camp work is not in this first stage.

## A shared day

Each worker has one job. Workers miss rest recovery and advance injury/illness recovery at the ordinary working rate; resting people get the existing resting rate. People receiving nursing cannot simultaneously work or help haul the hunt. Too ill, injured or unwilling companions rest instead, with an explanation in the journal. Health and willingness are rechecked daily.

The day coordinator reserves nursing patients and available kits in party order. Leader-selected care takes priority over delegated care and cannot overspend the final kit. A Caregiver nurse improves treatment through the existing specialist values; that person no longer also grants passive care to the leader. An assigned Hunter can assist the minigame, but a Hunter foraging or drying meat cannot also reload or haul for it. Carpentry and Trading remain as before until their respective tasks are built. Veteran remains a combat special.

One worker handles the available drying batch using the existing processing rules. Extra driers rest rather than process the same food twice. Meals and spoilage happen before processing. The morning quote bounds the input; evening hunting returns are excluded, so today's catch cannot also complete a full day of drying.

Foragers combine their work into a single harvest roll and share real storage room. New produce arrives after that day's meals. Finds below four physical pounds remain loose greens: they count toward cargo and appear in Supplies, can be dropped by pound, spoil normally and provide vitamin C when actually eaten. They do not invent a whole staple-equivalent food unit. This preserves nutrition while retaining the current coarse food-unit model.

Meals, calendar, weather, spoilage, social changes and wages advance once. Automatic mercenary pay uses that same daily wage tick. Routine harvest and drying reports go to the journal without interrupting every day of a planned rest; existing illness, relationship, wage and encounter interruptions remain.

## Saves and boundaries

Character schema 4 adds a strictly validated task collection keyed by actual traveler IDs; past travelers retain their history and a replacement cannot inherit a former member's assignment. The optional loose-greens fields have bounded integer quantities and expiry dates. Saves cannot capture a hunt or a half-resolved day.

The genuine schema-3 fixture at tests/fixtures/pre-camp-tasks-v3.json was captured from master aa0a096 before these changes, with rules fingerprint 38d5a0bdaca9f681aca65bb45c0da8a41029739b67400ff71cf0941e09647a75. Its state and random streams migrate unchanged, with no invented assignments. The former fingerprint is whitelisted; camp_tasks.json is now included in the rule signature.

This is an implementation milestone, not a survival balance sign-off. Existing journey actors use group actions. Future comparison actors must assign jobs before measuring possible farmer time savings. The earlier 5-10 / 13-26 day estimates remain hypothetical overlap estimates, not measured results for this feature.

## Validation

Implementation checkpoint f4d42d0 passed all 64 Godot suites in a clean isolated checkout, including 61 companion-work checks. The same sources completed 24 store and 20 outlaw integration journeys with zero reported errors. Native roster views, including the scrolled lower rows, were inspected and shown to Spencer. The new suite exercises overlapping nursing/drying/forage/hunting, per-person recovery, blocked or unwilling workers, morning-only drying, shared kits, patient/helper exclusivity, multi-day rest, small-harvest nutrition/cargo/discards, malformed saves and genuine schema-3 migration.

Current rules fingerprint: 420a7c10d6ec416596c727e16b692d949d15293d85e020f1069d63a734228c08. Logs and verified integration reports remain in ignored .tools/camp-tasks-* files. The initial failed save/observer checks are retained separately from the final passing run. No full-route balance benefit or new art is claimed. Actual player saves and the three preexisting debug pilots were preserved.

Final UI checkpoint b994305 passed all64 suites, including73 companion-work checks. It follows Spencer's bordered chore-chart sketch, with hover descriptions, cascading task options, combined Nursing/name rows, a shared cost footer and content-fitted window. The24store/20outlaw integration pass at08e75b9 uses identical simulation/data sources; later changes are UI, tests and documentation only. Final native table and submenu views were inspected and shown.
