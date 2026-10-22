# Claude handoff: Westward, Probably

Updated with every merged pull request, so a session cut off at any point loses nothing. Last update: October 22, 2026, with the departed-companion tales PR (#14). **Continue the existing project; do not restart it.**

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
- **Crime record:** version 7, in `simulation/crime_system.gd`. Each version has an `upgrade_vN` step, chained in `upgrade()`. Remains, human food and meals live in `simulation/remains.gd`, as static functions on `game.crime.record`.
- **Design reference:** `docs/STORE_CRIME_SLICE.md` describes every implemented mechanic, its tuning and its save rules. `docs/CRIME_AND_CANNIBALISM_ROADMAP.md` holds the plan.

## Next work

Roadmap phase 6 (information spread, pursuit, service audit):

- Traders and travelers carry news. This is already modeled as report travel delays, and companions' tales use the same delays.
- Done: `tests/outlaw_journeys.gd`, 20 full-route criminal and lawful journeys with no stuck encounters (0 errors on October 22). Rerun it after crime changes; it takes a few minutes.

Smaller follow-ups noted along the way:

- A gravestone in the memorial book for graves dug on the trail.
- Attacks started by companions, and betrayal at low trust.
- A peaceful emigrant camp encounter.

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
