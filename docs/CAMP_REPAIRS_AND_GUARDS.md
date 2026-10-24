# Camp repairs and named stock guards

October 24, 2026. This completes the second camp-roster stage. Away hunts, mounted outings and new backgrounds remain pending.

## Repairing a broken wagon

A wagon breakdown now offers **Make camp and assign a repair crew** alongside the existing immediate choices. This spends no time. The broken part becomes a saved project, and the wagon cannot travel until the repair is complete or a real spare is fitted.

In Camp > Companion tasks, choose **Repair wagon > Patch** or **Make wooden repair**:

- Ordinary companions can patch: two work units, with one care kit consumed when work starts.
- A Carpenter, or a special granting Carpentry, contributes two units per working day. A patch therefore takes one day.
- Making a wooden repair requires Carpentry and three work units, so a Carpenter finishes in two working days without a kit. Usable local wood/tools remain abstracted as in the previous repair event.
- One person works on the broken part per day. Another repairer rests; they do not spend another kit or process the same part twice.
- Nursing reserves patients and kits first. A patient, unwilling companion or someone too ill to work cannot repair.

Progress and the already-spent kit survive interruptions, reassignment and save/load. Changing methods midway is blocked; resume the chosen method or fit a spare. A kit spent on an abandoned attempt is not refunded.

The footer shows the broken part and progress. **Work on repair yourself** lets the leader spend one day at a time on it, including the previous three-day wooden fallback without a trained companion. This prevents choosing a crew from trapping an expedition with no Carpenter. If the leader works, another companion does not also repair that part that day. Fitting an actual spare takes no day and consumes that spare.

Abandoning a damaged wagon moves its project into that wagon's cache. Returning restores the unfinished project; a newly purchased wagon does not inherit it. A broken wagon cannot be sold as a sound one. Cache theft/loss also loses that wagon's repair progress.

In shared-assignment mode, a Carpenter doing another job no longer passively shortens a leader repair event. The specialist must actually perform the assigned work. Existing group-action mode retains its former shared Carpenter assistance.

## Guarding stock

Assign **Guard stock** to a healthy, willing companion. This uses the existing horse/mule theft event's watch weighting, once. It adds no second theft roll, independent shield or combat bonus. Soldier-specific benefits remain a later stage.

In camp, the guard works instead of receiving rest recovery. Extra guards rest instead of stacking protection. A guard receiving nursing, too ill to work, absent or refusing gives no protection; another eligible assigned guard can take the watch.

The named watch also covers travel and trading nights. Those days do not run the other camp chores, and the watch charges the existing party sleep/fatigue cost once. The old anonymous night-watch toggle is used only in group-action mode; the Travel menu directs assignment-mode players to the roster. Keeping the old flag on does not stack protection or fatigue with a named guard.

The current watch protects against horse/mule theft. It does not invent oxen theft, prevent accidental stampedes or guarantee success in a bandit fight. With no horses or mules, the assignment reports that there is no stock watch to perform.

## Accounting and saves

Repair progress uses a validated optional camp_repair object; cached projects use the same validation. Named watch metadata identifies the actual worker and day. Both are ordinary JSON data. Character schema remains 4.

The new repair work settings change the rules fingerprint. The immediately preceding 420a7c10d6ec416596c727e16b692d949d15293d85e020f1069d63a734228c08 signature is whitelisted. Genuine tests/fixtures/pre-repair-guard-v4.json was captured from 3799a84 before implementation; its state, assignments and random streams migrate without invented repairs.

These work units are authored game rules, not historical measurements. No new profession balance or full-route success claim is made.
