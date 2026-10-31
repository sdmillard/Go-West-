# Winter cabins, settling short, and scores

Spencer (October 31):
- a party can build a cabin anywhere it is willing to spend the time;
- it can settle short of Oregon anywhere, at any time, within the constraints;
- staying where it is not wanted gets it run off;
- every ending gets points.

The design discussion is in the thread "Run the big balance pass". Rules live in `data/cabins.json` and `data/scoring.json`, and the code in `simulation/cabins.gd` and `simulation/scoring.gd`.

## Cabins

- **Where:** only at stops with timber (`timber` in `cabins.json`). These are the wooded border country, cottonwood river bottoms and the forested west, but not the bare plains or the sagebrush.
- **What it takes:** a hatchet and 15 worker-days.
  - Every fit (health 40 or more) and willing traveler gives one worker-day per CAMP > CABIN > BUILD day. That is 2 work units, or 3 for Carpentry (a carpenter leader or companion).
  - Builders work instead of resting, and meals are eaten as usual.
  - In November 1846 the Donner Party's Graves cabin went up in about three days with help ([Donner Party Diary](https://donnerpartydiary.com/nov46.html)).
- **Saving:** progress is kept per stop in `state.cabins`.
- **Shelter:** a party at a stop with a finished cabin has:
  - no storm damage;
  - no cold exposure;
  - winter illness risk times 0.6.

  Food, scurvy, animals without grass and everything else go on as usual. Winter is lived day by day, with no skip.

## Settling short

CAMP > CABIN > SETTLE HERE FOR GOOD works at any stop except the destination, at any time, while the leader is alive. It asks for confirmation and shows what staying means.

| Where | Who decides | Result |
|---|---|---|
| Independence, the Willamette edge (`open`) | nobody | Settled |
| Laramie, Bridger, Hall, Boise, Walla Walla (`posts`) | the post | Settled as post hands, unless the post refuses the party over known crimes; then run off |
| Everywhere else (`peoples`, approximate for 1848) | the people of that country | 30% agree, decided once per party and place apart from the game's dice. Known crimes, a refusing household or a council banishment means refusal. Staying anyway means run off |

The journey then ends with status `settled` and `state.settled` = {place, kind, people}. The kind is one of:
- `open`;
- `post`;
- `cabin` (welcomed, with a finished cabin);
- `run_off`.

## Scores for every ending

The score is:

(travelers + goods + cash + keepsakes) × ending × profession

- **Travelers:** 100 points each if healthy (70+), 70 if fair (40+), 40 if poor.
- **Goods:** the stock, mounts, wagon, food, clothing, arms, parts, kits and salt still owned, at Independence prices, 1 point per $5.
- **Cash:** 1 point per $5.
- **Keepsakes:** their arrival points, as before.
- **Ending:** Oregon 1, settled 0.6, run off 0.3, turned back east 0.25, lost 0.
- **Profession:** the banker's purse over yours, to one decimal. For example, farmer 2.2, outlaw 2.5, banker 1.

Every ending screen shows the breakdown.
