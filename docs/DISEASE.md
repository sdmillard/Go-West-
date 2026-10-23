# Disease: where illness comes from

October 23, 2026. First part of the post-crime mechanics expansion (disease, climate, route branches). All new numbers are **authored placeholders for the later balance pass**, not fitted epidemiology.

## What changed

Before this change, a spontaneous illness was picked uniformly from every unlocked illness. Now:

- **Season and region pick the illness.** The daily party-level onset roll is unchanged (3% base, scaled by rations, rest and exposure). When it fires, the illness is chosen by weight: `weight × months[month] × regions[region]`. Regions are the five broad habitats from `data/trail_context.json`. A region missing from `regions` uses `region_default` (default 1).
- **Contagion.** An illness with `spread_chance` gives every other traveler who is currently well and not immune that daily chance of catching it from each sick person. People who fell ill today pass it on from tomorrow. The history reads "Sam caught measles from Ada."
- **Immunity.** An illness marked `immunizing` (measles) leaves survivors immune. Immunity is saved per traveler (`immune`, validated on load).
- **Mountain fever** is new: high country, spring and summer, a long but usually survivable fever, not contagious.
- **Cholera** stays locked until 1849. The great trail epidemic began that year; the setting is 1848.

| Illness | Weight | Peak months | Regions favoured | Spreads | Immunity |
| --- | ---: | --- | --- | ---: | --- |
| Dysentery | 4 | June to September | Platte, sagebrush | 2%/day | no |
| Typhoid fever | 2 | July to October | Platte, sagebrush | 1.5%/day | no |
| Measles | 1.5 | February to June | Missouri border, Platte | 8%/day | yes |
| Mountain fever | 4 | April to August | high country only (sagebrush 0.3) | no | no |
| Exhaustion | 2 | any | any | no | no |
| Cholera | 1 | any | any | no | locked until 1849 |

## Scurvy (part 2)

- The engine counts `party_health.days_without_fresh`: each day's meals either include fresh (undried) meat from hunting or slaughter, or they don't. Staples and dried meat don't count. Human meat served through the remains ledger is not counted either way yet.
- Past `onset_days` (45), each well traveler has a daily chance of scurvy: 1%, plus 1% for every further 15 days, capped at 8%. These are placeholders.
- Scurvy is never picked as a random illness. It mends only on days the party eats fresh meat, and the roster says so. Without fresh food it keeps doing slow damage.
- Saved as a top-level `days_without_fresh` field (not in `state`, so migrated saves keep their state untouched); older saves start the count at 0.

NPS links scurvy to "diets lacking in vitamin C." Emigrants also carried dried fruit, pickles and vinegar, and gathered wild greens; none of those are modeled yet, so hunting is the only cure for now. That gap belongs to the outfitting/foraging work, not this PR.

## Historical grounding and limits

- [NPS, Death on the trails](https://www.nps.gov/articles/000/death-on-trails.htm): disease was "the number one killer, by a wide margin"; "the most dangerous diseases were those spread by poor sanitary conditions and personal contact"; cholera "results from a waterborne bacteria"; dysentery is common with "unsanitary conditions" and "seldom fatal if treated"; measles "more common among children"; mountain fever "usually not fatal", with symptoms matching typhoid or scarlet fever.
- [California Trail Center](https://www.californiatrailcenter.org/you-have-died-of-dysentery-diseases-on-the-california-trail/): dysentery spread through shared water; typhoid "highly contagious"; measles spread person to person.

The sources support which diseases mattered and how they spread. They do not give monthly or regional rates, spread probabilities or recovery times. Peaks in hot months and on the crowded Platte corridor are an authored reading of "waterborne" and "unsanitary"; the measles season reflects its spread among parties gathering in spring. Mountain fever's modern identity is uncertain, so the game gives it no specific modern diagnosis. Children and the elderly are not yet modeled separately, though the sources stress their greater risk.

## Verification

`tests/test_disease.gd` covers malformed data, regional and seasonal weights, the 1848 cholera lock, deterministic replay, contagion with named sources, immunity, non-contagious illness, the engine passing the current region, and immunity through save and load, scurvy onset and fresh-food recovery, and the fresh-meat day counter. Previous rules fingerprints `a76bde0b…81b7` (part 1) and `4fbbe60d…7351` (part 2) are whitelisted in `economy_v1`; existing saves continue under the new rules.
