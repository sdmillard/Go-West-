# Dog usefulness test

The dog has useful but limited roles. Camp watch shows a practical theft-deterrence benefit in this sample; leader-hunting help does not consistently cover the dog's food, particularly across non-hunting travel days. No food-price, feeding-rate, search-chance or catch-chance buff was applied.

Spencer requested that the rabbit-catching chance happen **when the rabbit appears**. That is now implemented: one immediate 18% roll per newly appearing rabbit, no eight-second timer, no repeated frame rolls, and no deer/bison kills. Multiple distinct rabbits each get their own chance. Catch meat still uses normal calories, retrieval and carrying. Existing dog saves preserve their condition, fatigue, settings and purchase record.

## Controlled hunting

800 actual-engine outings = 40 matched seed clusters x 5 regions x 2 shot-timing policies x 2 dog arms. These are 400 matched comparisons, not 800 independent worlds. Each pair starts with the same supplies, team, human roster and aim seed; dog purchase costs an additional $5. The main quick policy shoots immediately at 65% accuracy; the sensitivity waits eight seconds before shooting in **both** arms. Rules are identical across timings and the dog never needs the wait.

| Measure across 200 matched pairs | Quick hunts | Wait-eight-seconds sensitivity |
| --- | ---: | ---: |
| Extra raw meat obtained with dog | 463 lb | 240 lb |
| Rabbit meat caught by dog | 27 lb | 27 lb |
| Previously empty searches with game located | 18 | 18 |
| Food eaten by dogs | 320 units | 320 units |
| Net remaining food difference, dog minus no dog | -64 units | -187 units |
| Mean net remaining food difference per outing | -0.32 units | -0.935 units |
| Pairs with more remaining food using dog | 7 / 200 | 4 / 200 |

Net food uses actual remaining inventory including exact fractional table portions. Dog meals are **already charged** in that net difference; subtracting the 320 units again would double-count them. Raw meat is not the same as carried food: catches differ in energy density, retrieval and packing limits. The purchase charge is separate from the food comparison.

The extra meat and occasional better hunt are real. The current help is intermittent, while feeding is daily. Waiting is not a solution: animals can leave during that delay, and the dog no longer requires it.

## Journeys

96 complete attempts: farmer/banker x April/May x eight matched seeds x no dog/hunting dog/watch dog. Same ordinary public-action strategy, same 65% aim and initial non-dog cart per matched case. Dog arms pay $5. Food sharing is enabled. Jobs rest the dog when tired, ill or underfed, without adding dog-only rest days. No replacement dog is bought. Main journey hunts shoot immediately. Runs stop at an outcome, 360 days, 2,400 decisions or a detected action error.

| Measure | No dog | Hunting dog | Watch dog |
| --- | ---: | ---: | ---: |
| Journeys | 32 | 32 | 32 |
| Oregon arrivals | 5 | 4 | 6 |
| Parties lost | 21 | 21 | 20 |
| Still traveling at day cap | 6 | 7 | 6 |
| Mean dog food per attempted journey | 0 | 331.91 units | 323.81 units |
| Horse-thief encounters | 71 | 71 | 40 |
| Explicit dog warnings | 0 | 0 | 24 |

Hunting dogs assisted 1,053 of 1,209 hunts, caught 262 lb of rabbit, and located game on 84 otherwise empty searches. Of 32 dogs, 25 were alive at the endpoint, with four recorded river losses and 16 hunting injuries. Watch dogs were fit for watch on 5,034 of their 6,881 fed days; 21 were alive at the endpoint and five had recorded crossing losses. Endpoints include parties dying and runs being capped, so these are not lifetime mortality rates.

Horse-thief weighting changes from 8 to 4 while a dog is eligible (before any additional named human guard). The 40-versus-71 observed encounters are consistent with that mechanic, but the journeys differ in length, available stock, recovery choices and mortality. These pooled totals do not establish an exact percentage reduction. Warnings currently add information/flavor and **do not improve combat rolls**. Theft deterrence is the watch dog's concrete mechanical benefit.

Arrivals of 5/4/6 are too few to establish a survival advantage. All farmer cases failed under this one declared automated strategy in all arms; that does not prove that farmer play or dog ownership is unwinnable. The policy does not optimize companion work or use zero-ammunition dog-only hunts, and it collects no pelts for sale. It is a bounded usefulness check, not a new general survival-balance certification.

## Assessment

- **Watch dog:** has a useful protective role with an ongoing food cost. Keep its effect visible; don't imply that a bark wins a fight.
- **Hunting dog:** useful occasionally, but presently a weak food investment over an entire journey. Its help applies only to the leader's hunts, while upkeep continues during travel, rest and other work. Rabbit catches alone are far too small to pay that bill.
- **Next design discussion:** broaden useful work (for example stock tending or accompanying a selected companion hunt) before arbitrarily increasing rabbit yield or cutting plausible food needs. No such expansion or automatic balance tuning is part of this test.

## Reproduction and validation

Primary archive: local `.tools/dog-usefulness-03.json`; compact verified results: [dog-usefulness-results-03.json](dog-usefulness-results-03.json). Raw SHA-256 and source/rules hashes are in the compact report. The campaign refuses to overwrite an archive. Diagnostic source is `tests/dog_usefulness_campaign.gd`, `dog_usefulness_policy.gd` and `dog_usefulness_observer.gd`.

Run Godot with `--headless --path . --script tests/dog_usefulness_campaign.gd`, using a fresh output path/version for a repeat. Run `python -B tests/summarize_dog_usefulness.py` to verify paired coverage, source hashes, finite measurements, 96 successful save checks and totals. The 800 controlled outings and 96 journeys completed with zero study errors. The independently computed net food includes partial portions, avoiding truncation in the legacy per-hunt food receipt.

Versions01/02 and the pilot remain local development archives and are excluded from the primary totals. Version01 still used the eight-second trigger; version02 used immediate chances but patient journey hunts. Version03 is the primary quick-hunt result. Seed clusters repeat across professions, months and habitats; the rows must not be treated as independent population trials.

Regression: all101 suites passed after the appearance correction (529 dog checks at that checkpoint); the final focused dog suite passes531 including explicit migration of a previous-timer dog save. No changes to ration prices, dog energy needs or hunt yields were made during this audit.
