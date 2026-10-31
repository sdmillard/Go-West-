# Columbia rafting patterns

The course now combines authored passages instead of evenly spaced independent obstacles. Run `play-rafting-prototype.cmd`; close and reopen a running practice application to load these changes. F6 restarts the already-loaded scenario.

## Course and controls

The same 25-second course, speed18, steering1.1, current, coastline and raft footprint remain. Thirteen individual hazards form nine encounter waves. Every run has:

1. Four-second entry with one central rock.
2. A six-second slalom or split passage.
3. Two seconds without new encounters.
4. The other six-second challenge.
5. Five seconds of alternating shore clusters and one laterally drifting log.
6. Two-second clear exit.

The slalom alternates a slow drifting log, a fixed rock and a faster sweeping log. The split passage offers left/right routes past a drifting log beside a fixed central rock, then a gap between outer rocks. Shore clusters obstruct both bank shortcuts at different moments, followed by the original wide-sweeping log. Four logs follow sinusoidal paths at different rates, each with a small directional wake. Course order, mirror direction and log phase use a private seeded generator, fixed before player input. Nothing tracks the player.

Course version4 replaces three rocks with moving logs; it retains thirteen hazards, nine encounter waves, the same breathers and existing consequences. Angular rates are0.55,1.25,1.1 and0.9radians/second, with respective normalized amplitudes0.24,0.38,0.32 and0.55. Mirror direction and seeded phase vary the opening, while rate and amplitude remain authored.

Pattern duration, local encounter time, normalized lateral position, kind and log motion live in `data/rafting.json`. Empty breather/exit templates reserve time instead of filling every available space. These are authored gameplay estimates, not a reconstruction of the actual rapids.

## Collision and route checks

Actual collisions still remove20 hull points and use the existing supply/injury/wreck rules. A new0.35-second grace period prevents overlapping objects in a single cluster from stacking damage. Objects contacted during grace are consumed as contacts without a second impact. Later encounters can damage the raft again; bank cooldown remains1.5seconds.

Before launch, the model propagates reachable lateral intervals through every60Hz step. It reserves0.75seconds of initial reaction time, limits steering to80% of actual speed, adds0.04 lateral clearance, and enlarges the longitudinal collision window from3 to3.5world units. Moving logs are evaluated at the same elapsed time as actual collisions. It backtracks a witness route through those intervals. The witness is for validation, never shown to the player or used to steer their raft.

Generation can try eight seeded candidates. If none validates, launch fails without spending time, replacing the pending choice, or removing portage. No unvalidated fallback is launched. This protects playability under future pattern edits. Validation covers physical reachability; it does not certify human difficulty, mouse comfort or the quality of every choice.

Tests replay80 witness routes through the actual physics, requiring zero impacts. They also reject an impassable wall, sample two-second on-screen warning geometry, verify seed variation/log motion, check cluster grace and distinct later impacts, and retain the ordinary/delayed steering, bank-hugging, fixed-lane, consequences, calendar, pause and save tests. Previous uniform-course and one-log-pattern saves, including completed25/30second histories, retain their state.

## Design references

- [Race the Sun developer interview](https://procedural-generation.isaackarth.com/2016/04/20/race-the-sun-behind-the-scenes-something-i-want.html): handmade obstacle patterns, regional sequencing and brief breathers informed the pattern library.
- [Adam Saltsman: Tuning Canabalt](https://www.gamedeveloper.com/design/tuning-canabalt): movement-aware generation, visible warning and forgiving collision geometry informed the clearance and reachability checks.
- [Activision River Raid manual](https://www.atariage.com/manual_html_page.php?SoftwareLabelID=409): channels, islands and moving hazards informed alternating passages and the log. We retain the existing coastline rather than narrowing it again.

These are design precedents. No source code or artwork from those games is copied.

## Validation record

Current moving-log suite:491 checks, zero failures (`.tools/rafting-moving-tests.log`), including moving-position collision, exact elapsed-time motion and30/60fps obstacle-position equivalence. The previous single-log pattern revision passed all102 regression suites (`.tools/rafting-pattern-full-tests.log`). All102 suites also pass with the four-log course (`.tools/rafting-moving-full-tests.log`). Native captures: `.tools/rafting-moving-6.png`, `rafting-moving-8.png`, `rafting-moving-15.png`, `rafting-moving-21.png`. The approved [rafting art pack](RAFTING_ART.md) replaces temporary obstacle circles and the old raft, with animated foam and wreck timbers. Crossing-bank, wagon and traveler art are retained.
