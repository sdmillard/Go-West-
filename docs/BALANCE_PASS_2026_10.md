# Big balance pass, October 31, 2026

Spencer's rule: options need not be equally viable, but nothing may be bullshit (no free wins, no unfair or cheap failures). Tactical combat lethality is out of scope unless asked.

## Baseline (master at PR #139)

`tests/play_style_baseline.gd` plays whole journeys through public actions, one declared bot per play style, three professions, seeds 90000-90011 (12 per cell, 360 journeys, about 6 minutes on four cores). `tests/summarize_play_styles.py` turns the raw `.tools/play-style-<label>.json` files into these tables.

```
godot --headless --path . --script tests/play_style_baseline.gd -- --label=base-careful_apr --seeds=12 --styles=careful_apr
python3 tests/summarize_play_styles.py .tools/play-style-base-*.json --markdown
```

Styles: `careful_apr`/`careful_may` (steady, adaptive rations, rest, care, salt, buys produce), `fighter` (careful but always defends against bandits), `reckless` (grueling, meager, rests only below 25 health, fords, fights), `on_foot` and `horses` (fixed kits from the mount campaign), `petty` (one theft from a camp or trader), `criminal` (three thefts and three robberies at transient targets), `late_jun`/`late_jul` (careful). Fights here use the old quick odds; in play, fighting opens the tactical game.

| Style | Arrived | Median days | Survivors at arrival | Leader died | Custody | Other loss | Out of time | Deaths/journey | Starving days | Cash at arrival |
|---|---|---|---|---|---|---|---|---|---|---|
| careful_apr | 24/36 | 207.0 | 4.92 | 11 | 0 | 0 | 1 | 0.78 | 0.0 | 224.25 |
| careful_may | 20/36 | 251.5 | 4.8 | 15 | 0 | 0 | 1 | 1.06 | 0.0 | 179.65 |
| criminal | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| fighter | 26/36 | 207.0 | 4.88 | 10 | 0 | 0 | 0 | 0.67 | 0.0 | 250.56 |
| horses | 12/36 | 183.5 | 4.92 | 24 | 0 | 0 | 0 | 1.78 | 2.0 | 205.05 |
| late_jul | 20/36 | 293.0 | 4.85 | 14 | 0 | 0 | 2 | 1.08 | 0.0 | 290.08 |
| late_jun | 19/36 | 286 | 4.84 | 17 | 0 | 0 | 0 | 1.28 | 0.0 | 198.18 |
| on_foot | 0/36 | 0 | 0 | 31 | 0 | 0 | 5 | 2.92 | 62.5 | 0 |
| petty | 24/36 | 203.0 | 4.88 | 11 | 0 | 0 | 1 | 0.86 | 0.0 | 176.0 |
| reckless | 0/36 | 0 | 0 | 36 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |

| Style | Arrived | Median days | Survivors at arrival | Leader died | Custody | Other loss | Out of time | Deaths/journey | Starving days | Cash at arrival |
|---|---|---|---|---|---|---|---|---|---|---|
| careful_apr / farmer | 2/12 | 227.5 | 5 | 9 | 0 | 0 | 1 | 1.92 | 1.5 | 7.52 |
| careful_apr / carpenter | 10/12 | 203.5 | 4.9 | 2 | 0 | 0 | 0 | 0.33 | 0.0 | 144.8 |
| careful_apr / banker | 12/12 | 203.5 | 4.92 | 0 | 0 | 0 | 0 | 0.08 | 0.0 | 598.58 |
| careful_may / farmer | 1/12 | 211 | 5 | 10 | 0 | 0 | 1 | 1.75 | 4.5 | 14.52 |
| careful_may / carpenter | 9/12 | 276 | 4.56 | 3 | 0 | 0 | 0 | 0.92 | 0.0 | 14.8 |
| careful_may / banker | 10/12 | 251.5 | 5 | 2 | 0 | 0 | 0 | 0.5 | 0.0 | 489.13 |
| criminal / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| criminal / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| criminal / banker | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 1.83 | 0.0 | 0 |
| fighter / farmer | 3/12 | 196 | 5 | 9 | 0 | 0 | 0 | 1.5 | 0.5 | 14.55 |
| fighter / carpenter | 11/12 | 207 | 4.91 | 1 | 0 | 0 | 0 | 0.33 | 0.0 | 183.4 |
| fighter / banker | 12/12 | 209.0 | 4.83 | 0 | 0 | 0 | 0 | 0.17 | 0.0 | 644.8 |
| horses / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.17 | 13.0 | 0 |
| horses / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 3.08 | 7.5 | 0 |
| horses / banker | 12/12 | 183.5 | 4.92 | 0 | 0 | 0 | 0 | 0.08 | 0.0 | 205.05 |
| late_jul / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.5 | 2.0 | 0 |
| late_jul / carpenter | 9/12 | 296 | 4.67 | 1 | 0 | 0 | 2 | 0.5 | 0.0 | 18.55 |
| late_jul / banker | 11/12 | 292 | 5 | 1 | 0 | 0 | 0 | 0.25 | 0.0 | 435.85 |
| late_jun / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.33 | 2.5 | 0 |
| late_jun / carpenter | 9/12 | 310 | 4.67 | 3 | 0 | 0 | 0 | 1.0 | 0.0 | 20.07 |
| late_jun / banker | 10/12 | 283.5 | 5 | 2 | 0 | 0 | 0 | 0.5 | 0.0 | 439.11 |
| on_foot / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.92 | 50.0 | 0 |
| on_foot / carpenter | 0/12 | 0 | 0 | 11 | 0 | 0 | 1 | 3.17 | 72.0 | 0 |
| on_foot / banker | 0/12 | 0 | 0 | 8 | 0 | 0 | 4 | 2.67 | 67.0 | 0 |
| petty / farmer | 3/12 | 237 | 5 | 8 | 0 | 0 | 1 | 2.0 | 3.0 | 14.67 |
| petty / carpenter | 10/12 | 202.5 | 4.8 | 2 | 0 | 0 | 0 | 0.42 | 0.0 | 126.71 |
| petty / banker | 11/12 | 203 | 4.91 | 1 | 0 | 0 | 0 | 0.17 | 0.0 | 606.35 |
| reckless / farmer | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |
| reckless / carpenter | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |
| reckless / banker | 0/12 | 0 | 0 | 12 | 0 | 0 | 0 | 2.42 | 0.0 | 0 |

Findings (full write-up shared with Spencer as a Claude Doc):

- Money decides arrival: lawful wagon styles arrive farmer 6/60, carpenter 48/60, banker 55/60. Farmers keep $216 after the suggested outfit and bottom out near $10.
- Scurvy is the top killer (51 of 175 lawful deaths), then dysentery 27, pneumonia 20, smallpox 20.
- 67 of 71 lawful losses are leader deaths, clustered at miles 1,350-1,913.
- Departure month barely matters: July 20/36 against April 24/36; late parties cross the western mountains in winter and just move slower.
- Careful April journeys take a median 207 days; May parties arrive in December or January.
- Criminal journeys all fail, mostly to scurvy, because identified news closes every store for good. A single theft changes nothing.
- Grueling pace is never usable (bare + grueling is -7 health a day).
- Walking: 0/36, mostly lack of food.

Proposed tuning order: scurvy and disease mix; farmer money; winter danger for late starts (needs Spencer); crime refusals (needs Spencer); pace and rations; no change to fights.
