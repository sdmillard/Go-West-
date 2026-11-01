# Walking balance (October 31, 2026)

Spencer listed walking as too harsh: in the play-style baseline, no party on foot ever reached Oregon (0 of 36). Walking may be brutal, but it must not be unfair.

## What was wrong

- **Walkers were slower than ox wagons.** On foot the bots made 10.7 miles a travel day; careful wagon parties made 14.1. A loaded pack began to slow the walkers once it was half full, so a full pack cost a quarter of the day's miles. In 1849-1850 foot-packers regularly passed the ox trains. Handcart companies in 1856 made 15-20 miles a day pulling carts.
- **Packs were small.** Five walkers carried 200 lb in all, of which 75 lb was personal gear. That left room for about eight days of food, so the party had to stop and trade every few days. Each trading visit costs a day. The bots made 78 counter visits per journey, spent their whole purse on food at trail prices, and starved.

## The change

- **Packs: 50 lb a person, up from 40** (`data/provisions.json` `walking.carry_lb_per_person`). The 15 lb of personal gear is still counted inside it, and health still scales it. A U.S. infantryman of the 1840s marched with roughly 45-50 lb. Modern guidance for long carries is about a quarter to a third of body weight, which is 40-55 lb for most adults.
- **A pack slows walkers only past 80% full, not 50%** (`Mounts.speed_factor`). A full pack now costs 10% of the day's miles instead of 25%. Animals still slow past 85%.

Not changed:

- Trading still costs a day (Spencer's rule since PR #33). A test that made passing traders free for walkers raised arrivals from 6 to only 8 of 36. It was not worth breaking the rule.
- Disease, hunger, river swimming and the other dangers on foot are unchanged.

## Before and after

These are play-style bots (`tests/play_style_baseline.gd`, on_foot style), 36 journeys: 12 seeds × farmer, carpenter and banker. The bot now fills its packs at each counter, and its starting kit carries 80 lb of food (it was 45). With the bot changes alone, arrivals stayed at 0.

| Measure | Before | Speed only | Speed and 50 lb packs |
| --- | --- | --- | --- |
| Arrived | 0 | 3 | 6 |
| Miles per travel day | 10.7 | 12.3 | 12.4 |
| Average miles reached | 1,167 | 1,238 | 1,406 |
| Counter visits per journey | 78 | 75 | 73 |

Most of the arrivals are bankers (5 of 6). They can afford to buy food at trail prices all the way west. Farmers on foot still do not make it. Walking is now the hardest way west, but it is no longer impossible. The leading causes of death are dysentery and lack of food.

The horse style was checked as well, because riders' companions walk: 14 of 36 arrive, the same as master.
