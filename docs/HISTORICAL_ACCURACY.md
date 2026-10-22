# Historical accuracy takes priority

The user's October 22, 2026 decision supersedes matching 1985 gameplay when it conflicts with history. Keep the classic travel-and-decisions structure, but prefer evidence about the actual trail. The current setting is 1848. This does not certify every simulation rule as historically accurate.

## Opening distance anchors (retained within the full road)

[Palmer's 1847 guide, in the 1906 reprint](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html), pp. 277–278, reports camp-to-camp distances. Summing relevant rows gives:

| Stop | Miles since previous displayed stop | Cumulative guide miles |
| --- | ---: | ---: |
| Independence | 0 | 0 |
| Elm Grove | 33 | 33 |
| Wakarusa | 20 | 53 |
| Kansas River | 28 | 81 |
| Big Blue | 93 | 174 |
| Platte corridor | 143 | 317 |

Intermediate camps/streams are aggregated. These are one guide's estimates, not surveyed lengths or proof that every 1848 party followed an identical road. The source predates the setting and cannot establish later services. These opening anchors are retained within the new 1,938-guide-mile corridor to Oregon City. See [Route expansion](ROUTE_EXPANSION.md) for the complete distance ledger, authored subdivisions and classic-game comparisons.

## People, services and dates

- [NPS's Kansas River account](https://www.nps.gov/places/kansas-river-crossing-and-pappins-ferry.htm) places Pappin/Pappan ferry operations around 1843–1863, explains French-Creole and Kanza family connections, and reports a $1 wagon fare. The game uses that documented period price instead of the invented $15. It is not an authenticated tariff for a specific day in 1848. Sources differ about interruptions/ownership; the broad range does not prove continuous unchanged service. One-day ferry actions and guaranteed safety remain abstractions.
- [NPS dates Marshall's Big Blue ferry to 1852](https://www.nps.gov/places/000/historic-trails-park-marshalls-ferry.htm). It is absent from this 1848 corridor. This excludes that later service, not every possible crossing service anywhere on the river.
- [History Nebraska describes the Platte post's 1848 beginnings as Fort Childs](https://history.nebraska.gov/fort-kearny-as-a-sort-of-one-horse-affair/) and its modest buildings. We have not added a finished stockaded Fort Kearney. The new stop uses a pre-June camp and a construction-era interpretation, with no guaranteed stocked shop.
- [NPS distinguishes private Fort John from military Fort Laramie](https://www.nps.gov/fola/faqs.htm?fullweb=1); military purchase occurred in 1849. The new stop depicts the adobe trading era, without later army buildings.

Source URLs, hashes and retrieval outcomes are in `research/HISTORY_SOURCES.json`. The state-history page was read through web research but rejected direct downloading; its manifest records that failure. Period accounts and later editors have biases and obsolete language; their viewpoints are not neutral narration.

## Provisional game models

The [first balance pass](BALANCE_PASS_01.md) now documents the numerical comparison with BASIC, Palmer's outfit recommendations and NPS travel summaries. That report measured the opening only. The full-route pass now measures about 12.9–13.3 miles per moving day in its prepared-party sample; its nominal pace/terrain tuning supersedes the earlier opening-only movement calibration. Automatic cholera eligibility begins in 1849 as a conservative epidemic-context rule supported by NPS and a thesis abstract, not a claim of absolute absence of any possible 1848 case. Core food mass, whole-wagon load, prices, weather rates and actual disease risks still need their own historical calibration.

- Profession budgets and opening-store prices remain game fixtures, not established 1848 wages, wealth distributions or an Independence price list. A researched outfitting economy is still needed.
- Aggregate food, five-person starting parties, ration pounds, internal health values, rest recovery, speed and food costs are simplified mechanics. Personal health/severity/care and livestock fatigue now exist (see `PARTY_HEALTH.md` and `BASIC_SURVIVAL_BENCHMARK.md`), but their effects/durations remain provisional. Individual nutrition, forage, continuous water supplies and historical disease transmission/treatment remain incomplete.
- Rivers receive seeded low/high stages influenced by recent wet conditions. This is an assigned daily weather scenario, not reconstructed 1848 climate or hydrology. Waiting can change risk as wet conditions change; it does not grant an independent free stage reroll.
- Low-stage ford/float mishap chances are 8%/20%; high-stage chances are 65%/35%. These are provisional tuning, not historical frequencies. The general principle of low water favoring a ford and high swift water increasing danger follows the NPS Kaw account.
- Crossings consume one day. A mishap costs up to 30 lb food, one clothing set and individual health strain. These numbers and the safe ferry result are abstractions, not universal historical outcomes.
- The day-two wheel encounter is original authored material, not a documented diary incident or historical frequency model.
- Travel clips to stops and charges a whole day even when little distance remains. Smaller streams/camps are aggregated. Original pixel art illustrates the landscape without claiming a surveyed depiction.

## Next verification work

Research actual departure preparation, food components/quantities, wagon/load capacity, oxen requirements and period prices. Connect weather, rivers, livestock and health through explicit models. Check future services against arrival dates; distinguish traders, army posts and Indigenous communities. Consult multiple accounts and tribal/official historical sources as people and place context expands.

The survival pass provides first connected models, not historical certification. Uniformly available passing-wagon transactions and paid medical attention are temporary service abstractions. Care kits do not represent a particular effective period medicine; no treatment is claimed to cure a disease or snakebite. Robbery/rider/animal encounters are adapted game content with provisional rates, not asserted frequencies from actual diaries. The arbitrary BASIC winter instant-death deadline and routine fatal wolf attacks are intentionally replaced by weather/exposure and resource consequences.

Passing tests establishes software behavior, not historical truth. Historical facts, classic-game observations and gameplay tuning retain separate labels.

Location art now has its own dated evidence ledger in `art/LOCATION_REFERENCES.md`. A circa-1853 town engraving, modern museum interior photographs and an undated archival river photograph are references with explicit limits, not authenticated 1848 snapshots. Each current stop has an original illustration; interpretation remains labelled as such.
