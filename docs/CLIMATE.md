# Climate: storms, heat and snowmelt rivers

October 23, 2026. Second part of the expanded mechanics, after [Disease](DISEASE.md). All new numbers are **authored placeholders for the later balance pass**. This builds on the existing regional weather weights ([Regional travel](REGIONAL_TRAVEL.md)) and seasonal pressure ([Seasonal pressure](SEASONAL_PRESSURE.md)).

## What changed

- **Weather can be seasonal and regional.** A weather entry in `data/survival_rules.json` may list `months` it can occur in and `regions` multipliers (keyed by the five broad habitats; 0 excludes a region). The engine passes the current region id into the daily weather draw.
- **Thunderstorm** (April to August): heavy rain and lightning, speed 0.6, wets the ground fast (raising rivers). Twice as likely on the Platte grasslands, rare in the western forest. It also takes the regional rain multiplier.
- **Scorching heat** (June to August): speed 0.85, one extra point of daily team strain while working, and illness onset risk ×1.25. Twice as likely in sagebrush country.
- **Stampede** (trail event, only during thunderstorms or hail, needs at least two oxen): two oxen run off in the night. Round both up in two days, recover one in a day, or go on without them.
- **Snowmelt rivers.** River nodes can be `"river_source": "snowmelt"` (South and North Platte, Green, both Snake crossings) or rain-fed (the default). The chance a river is running high on arrival follows a monthly table: snow-fed rivers peak in June (80%) and drop to 15% by September; rain-fed rivers peak with spring rains (60% in May). Recent wet ground still forces high water as before. This replaces the flat 45%.

| Month | Rain-fed high | Snow-fed high |
| --- | ---: | ---: |
| April | 55% | 35% |
| May | 60% | 60% |
| June | 55% | 80% |
| July | 40% | 60% |
| August | 30% | 30% |
| September | 30% | 15% |

## Historical grounding and limits

The [NPS auto tour guide for Nebraska and northeastern Colorado](https://www.nps.gov/orgs/1453/upload/National-Historic-Trails-Auto-Tour-Route-Interpretive-Guide-Nebraska-and-Northeastern-Colorado.pdf) describes "the furious storms that raged over the plains, stampeding livestock and terrifying travelers," the Platte "rushing and boiling and yellow with mud, a mile wide," and "the choking dust ... under the hot Nebraska sun." The Platte, Green and Snake are fed by Rocky Mountain snowpack, which is why the early-summer rise is tied to them and not to the Kansas or Big Blue.

The sources support the kinds of weather and their seasons. They do not give daily frequencies, speed effects, stampede rates or river-stage probabilities; those are authored. Weather remains a seeded daily draw, not reconstructed 1848 climate.

## Art

The travel screen shows placeholder procedural effects (heavy rain plus lightning flashes for thunderstorms, shimmer bands for heat) until the Aseprite thread delivers overlays for weather ids `thunderstorm` and `heat`, a stampede event picture, and a high-water look keyed on `river_stage == "high"`.

## Verification

`tests/test_climate.gd` covers malformed climate data, seasonal and regional sampling, zero-weight exclusion, the snowmelt table, route river sources, heat strain on the team, the stampede's losses and recovery, no stampede with fewer than two oxen, and new weather through save and load. The previous rules fingerprint `fb3094a3…95ee` is whitelisted in `economy_v1`.
