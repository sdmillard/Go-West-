# Companion camp work: first playable stage

October 24, 2026. The shared camp-day stage is implemented. Away hunts, repair, stock guarding, mounted tasks and new backgrounds remain later stages in [the implementation plan](COMPANION_TASKS_IMPLEMENTATION.md).

## Playing

Open **Camp > Companion tasks**. Give each companion a standing job: Rest, Forage, Dry meat, Salt + dry meat, Nurse a named patient, or Help leader hunt. The roster explains current eligibility, inputs and expected results. Assigning jobs takes no time.

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
