# How an attack opens

Spencer's ask (November 1, 2026): an attack shouldn't just be a hit-or-miss roll. The moment you strike, one of three things happens, by chance:

1. **Caught off guard (`ambush`).** You drop them before they react. A shot or a blow always lands: it kills or wounds by the scene's usual `shot_fatal` (bare hands use `unarmed.fatal_factor`). A keeper who is down, dead or senseless, can't stop you taking the goods, so a wounded keeper goes straight to the loot step. Anyone else on hand still saw it.
2. **They get away (`fled`).** They bolt before you can strike and raise the alarm. Nobody is hurt. A shot is still fired after them, so one bullet is spent. Faces are seen as usual and the party goes to the escape step. There's no unarmed-struggle injury, because there was no struggle.
3. **A fight (`fight`).** The tactical grid. An unarmed attack fights with no powder: every gun starts unloaded, so the party uses blades, clubbed stocks and fists, and the party's shot stays in the wagon. The target and the staff still shoot back.

Choosing to fight in a trail event still always opens the grid. This rule covers only how an attack *you start* opens.

## Odds (`data/crime_scenes.json` › `strike`)

Starting shares, gun / unarmed: off guard 35% / 20%, they get away 25% / 30%, fight the rest (40% / 50%).

- **Off guard** gains the usual crime `edge`: +4 points per successful job (up to 3, counting combat wins and the Outlaw background). Poor or fair health and a small party take it back down. It loses 5 points (`bystander_step`) for each other person on hand. A target who is already wounded adds 10. Against a soldier it is halved. It is clamped between 5% (`floor`) and 75%.
- **They get away:** a wounded target gets −10, mounted passing traders get +10, and the share is capped at 50%. Soldiers, a fort, a Native household on home ground, jail guards and pursuers never run, so their share goes to Fight.
- The odds appear on the attack panel ("As you strike: off guard 30%, they get away 25%, a fight 45%.") for both a shot and an unarmed attack.

## Attacks on party members

The same three openings apply, with different odds inputs. Each companion who joins you adds the old `participant_step`. Each one who refuses (close to the target or unwilling to kill) counts as a bystander who might shout a warning. A target with a broken leg can't run.

- **Off guard:** they are hit and can't strike back; if they live, they flee the party.
- **They get away:** they run and leave the party, unhurt.
- **A fight:** the grid, among the wagons. On your side: the leader and whoever joins. On the other side: the target, plus any close companion (family, partner, friend) who is Bold or Reckless and fit. Every death and wound carries over. Whoever fought you and lived leaves the party (`retaliated`); the others answer as before. Shots fired come out of the party's ball, and an unarmed fight spends none.

## Saves

- Incidents and companion attacks carry an optional `strike` key (`ambush`, `fled`, `fight`). Older saves have none and still load. A wounded keeper can be in the loot step only with `strike: ambush`.
- Off the grid (headless bots, tests), a `fight` opening falls back to the old hit roll. The UI rolls first (`crime.preroll_local` / `preroll_party`) and opens the grid only for a fight; `choose()` then uses that roll (`forced_strike`).
- Tests pin `forced_strike = "fight"` wherever they assume the old roll. The new openings are tested in `tests/test_strike.gd`.
