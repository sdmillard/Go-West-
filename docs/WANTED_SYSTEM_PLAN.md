# Wanted system: build plan

Status: approved by Spencer on October 23, 2026 ("build the wanted system"). Implemented on `codex/wanted-system`; see [implementation and historical limits](WANTED_SYSTEM.md). The sections below preserve the original plan.

## Goal

Crime should catch up with the party. Lawmen, soldiers, emigrant regulators or bounty hunters come after it, and how likely that is grows with how much crime people know about. Being caught leads to a sentence that fits the worst known crime. Only a killing ends the game.

## What already exists (build on it, do not duplicate)

- **Capture ends the journey.** In `simulation/crime_system.gd`, `result()` with `captured` or `surrendered` sets `status="lost"` and gives the loss reason "The party's journey ended in custody." This applies to captures during a crime scene: escape rolls and the Fort Kearny breakout.
- **Fort Kearny pursuit.** `pursuer()` and `check_pursuit()` are called from `travel()`, `rest()` and landmark rest. They create an incident with `{action:"pursuit", attempt:"caught", stage:"standoff"}`. The rules are in `data/crime_scenes.json` under `fort_kearny.pursuit` (4 days, 35% per day). See "Soldiers ride after the party" in `docs/STORE_CRIME_SLICE.md`.
- **News.** `record.reports` hold identified and unidentified reports. `arrival()` gives a report's delay by distance (`news_rules`). `heard()`, `tales()` and `refuses()` reuse the same timing. Posts, traders (#40), the Green River ferry, camps, local care and recruitment all refuse a party that news has named.
- **Facts you can count.** `record.incidents` (action, attempt, resolution, knowledge), `record.attacks` (companion shootings), `record.remains` (butchering with witnesses) and `record.betrayals`.

## Design rules (from Spencer, also in project memory)

- Outcomes are chance-based.
- Experience never adds evidence or notoriety. A dedicated criminal faces more consequences only because each crime is a new chance to be known.
- Discovery depends on the scene: who witnessed it and where it happened.
- It is 1848. Fort Kearny is the only army post on the route; Laramie and Bridger are private posts. There is no civil law west of the Missouri.

## 1. Notoriety (derived, never stored)

`crime.notoriety(game, place_or_mile)` is the sum, over everything known at that place by now, of:

| Known act (an identified report or a tale that has arrived) | Weight |
| --- | --- |
| Theft | 1 |
| Robbery, raid | 2 |
| Shot at or killed someone (`shoot`, `assault`, a companion attack in a tale) | 4 |
| Fought soldiers (any Fort Kearny incident, pursuit breakout) | 5 |
| Butchering told by a former companion | 3 |

- Count only what `heard()` and `heard_tales()` would return there. Unidentified reports count half.
- Keep it a pure function of the record. Notoriety needs no save change. Bounty postings (below) do.
- Show it in View Party as a plain line: "Wanted: not known / talked about / wanted / notorious". Thresholds are about 0, 1–3, 4–8, and 9 or more.

## 2. Who comes (by region, historically plausible)

Each one is a new scene template in `crime_scenes.json`, like `passing_traders`, with its own people created when it is met.

- **Missouri posse (`posse`).** Only from Independence through roughly the Big Blue (within about 150 guide miles). It can come only for crimes reported east of there. A county sheriff had no authority beyond the state line, so after that line it stops.
- **Army detachment.** The existing Fort Kearny pursuit. Extend its window by notoriety, for example 4 days plus 1 for each 4 notoriety points, capped at 10.
- **Emigrant regulators (`regulators`).** Anywhere on the road. Wagon companies held trials and hanged murderers (well attested for 1849–52, and plausible for 1848). They come only for violent crimes (shoot, assault, or a killing in a tale).
- **Bounty hunters (`bounty_hunters`).** Anywhere, but only after a reward is posted. A reward is posted when an identified report of violence, or a robbery worth at least $50, reaches a company post: Fort Hall or Fort Boise (HBC), Fort Laramie or Fort Bridger (private). Store postings in a new record list `bounties: [{id, day, post, cents, incidents}]`. That makes this **crime record version 9**, with `upgrade_v8` adding an empty list and save validation of each posting. The reward is authored, scaled by notoriety, about $50 to $500.

## 3. When they arrive

- Add `check_wanted(game)` beside `check_pursuit` in `travel()`, `rest()` and landmark rest. Use `crime.rng` only when notoriety is above 0, so lawful journeys keep the same random stream (betrayal does the same).
- Daily chance = `base × notoriety`, capped at about 25%.
  - Time decay: halve the chance for every 20 days since the most recent known crime.
  - Region gate: posse only near Missouri; regulators and bounty hunters anywhere.
  - Allow at most one pursuer encounter at a time, and a cool-down of about 10 days after one ends.
- Reuse the incident machinery: create an incident with `action:"wanted"`, `attempt:"caught"`, `stage:"standoff"` and `place` set to the pursuer template key. That brings the panel, saves and journal for free. Add "wanted" to the accepted actions and give `news_text` a phrase for it.

## 4. The encounter panel (choices)

1. **Surrender.** Leads to a trial (section 5).
2. **Flee.** Chance based on oxen condition, pace and the pursuer type (a posse is mounted and harder to outrun). Failure is the same as being caught without surrendering, with one wound roll. Success costs a day and adds no new report.
3. **Fight.** Use the Kearny breakout logic with the pursuer's `breakout`, `shot_hit` and so on. Killing a pursuer makes a new identified report (if any survive) and adds notoriety. Losing the fight is the same as being captured.
4. **Pay them off.** Bounty hunters only: pay the posted reward plus about 20%. This clears that bounty, but notoriety stays.

## 5. Sentences (only a killing ends the game)

The worst known crime decides the sentence. This is emigrant or frontier justice, not a court.

| Worst known crime | Sentence |
| --- | --- |
| Theft | Return the goods or pay double their value in cash or goods; companions remember it (about −3 trust). Journey continues. |
| Robbery or raid | Goods and cash taken up to the stolen amount, plus a flogging (leader wounded about 30 with a wound condition). Each companion who joined may be "banished": they leave the party (flee machinery). Journey continues. |
| Shot someone who lived | The same as robbery plus banishment of the leader's helpers, and the oxen or the wagon may be seized (authored chance). Journey continues. |
| Any killing, including a companion killed and told of | Hanged. `status="lost"`, loss reason "The party's leader was hanged for murder." This is game over. |

Surrendering after a capture should be a little more lenient than being caught, for example no flogging for robbery. Record the trial on the incident (resolution `tried`, plus a `sentence` field) so saves and the journal stay honest.

## 6. Tests to add

- `test_crime`:
  - Notoriety weights and arrival timing.
  - No roll when notoriety is 0 (`rng.state` unchanged).
  - Each pursuer is region-gated, including no posse past the Big Blue.
  - Bounty posting, plus its save round trip and tampering checks.
  - Each choice: surrender, flee, fight and pay off.
  - Each sentence row, with a killing ending the game.
  - The v8 to v9 upgrade.
- `tests/outlaw_journeys.gd`: give the robber and killer strategies a policy for wanted panels (fight, then surrender) and record wanted encounters in the rows. Keep 0 errors.
- UI: when a wanted panel opens during travel or rest, show it. Fort Kearny pursuit already does this in `ui/main.gd` after travel and camp rest. Show Spencer any new UI before merging.

## 7. Working rules reminder

- Every `data/*.json` rules change: add the previous master's fingerprint to `economy_v1` in `data/save_migrations.json`.
- Run the full headless suite in a clean worktree, then `tests/store_crime_journeys.gd` and `tests/outlaw_journeys.gd`. Merge once everything passes.
- Update `docs/STORE_CRIME_SLICE.md` (new section) and `docs/CLAUDE_HANDOFF.md` with the PR.
