# Companion task assignments

October 24, 2026. Spencer proposed replacing the always-on companion background bonuses with tasks you send companions to do. This file records the design worked out with him in the "Design companion task assignments" thread. Spencer approved implementation on October 24. **The shared camp-day first stage is now implemented**; see [playing and scope](COMPANION_CAMP_WORK.md). Repair and named stock guards are now built too; see [repair/guard behavior](CAMP_REPAIRS_AND_GUARDS.md). Away hunting, mounted work and new backgrounds remain to build, one reviewed change per stage. The working analysis is also at https://claude.ai/artifact/EPrfj7aDmxBNN9cRj4FYGW.

## Why

Today each specialist gives a small passive bonus while alive, willing and at 40+ health with no serious condition (`data/party_benefits.json`, `party_character.gd` `available()`): Hunting reloads 20% faster, Carpentry saves a repair day, Caregiving adds +2 health and +1 recovery day to care, Trading takes 5% off purchases, Veteran cuts fight injury risk by 3 points. Most players never notice these. Tasks make companions hands you spend, and make a specialist's value (and wage) visible.

Every camp action is currently a whole-party day: hunt, care, drying, forage and rest each spend a day of meals. Parallel work should remove that artificial sequencing cost. Do not invent penalties just to preserve the old difficulty; use real constraints such as worker recovery, supplies, carrying and the timing of returns. See [the implementation stages](COMPANION_TASKS_IMPLEMENTATION.md) for the proposed sequence and acceptance checks.

## Core rules

- The leader is the player. Whatever the player clicks (rest, the hunting minigame, trade, care) is the leader's day, unchanged.
- Each companion holds a standing assignment that runs on every day spent in camp. Unassigned companions rest.
- **Decided:** companions who work that day do not get rest recovery. This is the main cost. Task tooltips must say so.
- Low-trust companions refuse tasks through the existing `willing()` check.
- Assignments persist across a multi-day camp rest; existing rest interruptions apply, plus an overdue or hurt hunter.

## Tasks

| Task | Who | Kind | Specialist edge | Ends when |
| --- | --- | --- | --- | --- |
| Rest (default) | Anyone | In camp | None | Fallback |
| Nurse a patient | Anyone, uses a kit | In camp | Caregiver: more health, faster recovery | Break camp or patient well |
| Dry meat | Anyone | In camp | None, or a little less loss | Break camp (finished batches keep) |
| Forage | Anyone healthy | In camp | None | Each day is its own search |
| Repair wagon | Anyone for small fixes | In camp | Carpenter: fewer days; maybe only a carpenter can make a wooden part | Done, or break camp (progress kept) |
| Guard the stock | Anyone | In camp | Soldier: better odds against thieves and night raids | Toggled off (replaces today's night guard) |
| Hunt | Anyone with bullets | Away | Hunter: better average yield, still has bad days | Returns, usually at nightfall |
| Hunt with the leader | Anyone | Joins the minigame | Hunter: today's reload bonus, plus hauling | End of the hunt |
| Outrider hunt | Anyone with a spare horse or mule | Away, on travel days | Hunter as above | Rejoins at evening camp |
| Scout ahead | Rider | Away, on travel days | Soldier: warns of riders, high water, poor grazing | Rejoins at evening camp |
| Quiet theft | Criminal | Away, at night | Criminal only | Returns before dawn, or is caught |

Trading stays passive (trading already costs a visit day). Veteran stays passive in fights.

## Away tasks (decided with Spencer)

- **Packs:** anyone sent away takes their pack exactly like a departing companion: their share of rations, a clothing set and personal gear, plus whatever bullets the player hands them.
- **Carrying:** an away hunter uses the same rule as the leader's hunt: each hunter carries one person's share (50 lb at full health, `hunting.json` `carry_per_person_lb`, linear health factor), plus the cargo of any horse or mule taken, within the 200 lb ceiling. A lone hunter on foot brings back about 50 lb; send two, or a horse, for more.
- **Yield:** resolved abstractly like wagon-guard hunts (`wagon_guards.gd`): real bullets, region, season, hit chance. Yield varies: some outings are good, some bring little or nothing. Tune the average near a decent human minigame hunt, Hunter specialists a little better on average.
- **Length:** a hunt on foot is a same-day trip. A mounted outrider can be sent for one to three days. Mishaps stretch either: getting lost, a lame or strayed horse, an injury, following a herd too far. The player learns why only when the hunter returns.
- **Leaving without them:** choosing Continue with someone away shows "Herbert hasn't returned from hunting." with WAIT A DAY / LEAVE WITHOUT HIM / BACK. Automatic travel and Villainy flight must check this too; nobody is lost without a warning.
- **Stranded companions (decided):** they have no way of knowing you left. They return to an empty camp and stay there as a camp of one, like wagon guards: living on what they carried and their own hunting, able to sicken, wander off or die. The player can turn back (return travel exists) and fetch them; the map marks where they were left.
- **Mounted catch-up (decided):** a late mounted hunter may catch up with the train depending on trust and temperament, using the riders-picker rule from PR #79 (broken trust never comes back; Nervous or Self-serving may not unless Loyal). Sending a low-trust companion out alone on your horse with a pack and bullets risks never seeing either again.
- **Other consequences:** an away companion is not a defender (small-party combat penalty already counts willing defenders) and may meet trouble alone, especially on `unrest` legs. Stranding someone costs trust with the rest (Compassionate objects, family hardest). Wages keep accruing and cannot be paid remotely. The riders picker shows away companions as unavailable.

## New backgrounds (workshopping)

Add to `party_character.gd` `SKILLS`, wage bases and catalog text.

- **Soldier:** guard and scout tasks. **Decided:** separate from the Veteran special. Soldier is training and duties; Veteran is having actually fought, and any background can have it. A Soldier who never fought gets no fight bonus; a Soldier with Veteran gets both. Possible risk: a deserter whom Fort Kearny soldiers recognize; higher wage.
- **Criminal:** quiet theft as an away task. Counts toward crime experience (lower execution risk and a small not-noticed bonus, never less evidence, per the crime design). If caught, they are the one named; may already be wanted back east; more willing to betray or rob the party at low trust.

## Systems touched

- Party benefits and `available()`: Hunting, Carpentry, Caregiving move to task bonuses.
- Core camp day (`rest`, `_tick_day`, `party_health.tick`): rest recovery per person; tasks resolve each camp day.
- Care, drying, forage (`open_care`, `preserve_meat`, `_gather_forage`): companion versions alongside the leader's action.
- Departure (`_choose_landmark`, departure review): the "hasn't returned" check.
- Wagon guards: reuse the offscreen camp for stranded companions; one pattern, not two.
- Wanted system, combat, wages, trust: hooks listed above.
- Saves: per-member task fields, character schema 4, previous rules fingerprint whitelisted in `data/save_migrations.json` with a genuine pre-change fixture.
- Tests: a new task suite; update the benefit, camp rest, departure and hunting suites. Study bots must assign tasks or they understate parties.

## Build order

1. In-camp tasks: per-person rest recovery, the camp roster UI (one row per companion with a task dropdown and quote tooltip), nursing, drying, forage, repair, guard.
2. Away hunting: abstract hunt, return times and mishaps, the "hasn't returned" prompt, stranded companions, trust/combat/wanted hooks.
3. Mounted outriders and scouting on travel days.
4. Soldier and Criminal backgrounds.
5. Balance check: update study bots, rerun on unused seeds, and compare with the horse baseline in `docs/HORSE_BALANCE.md` (`tests/mount_balance_campaign.gd`, seeds 75000-75005). Spencer's usual play keeps moving and makes brief stops (`docs/NUTRITION_PACKS_AND_RISK.md`), so judge tasks by their value on short stops too.
