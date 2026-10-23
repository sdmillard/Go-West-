# Seasonal pressure and the winter deadline

October 22, 2026. This implements Spencer's requirement that taking extra time has a meaningful seasonal cost. There is no automatic winter defeat date. Food-value investigation remains pending; this pass does not alter meat yields, meal units or prices.

## Historical basis and authored choices

[NPS, Making the Trek](https://www.nps.gov/oreg/learn/historyculture/making-the-trek.htm) describes April/May departures as a way to avoid winter snow in the high passes and identifies the Blue Mountains and Cascades as late-route barriers. [NPS's Columbia Gorge narrative](https://www.nps.gov/articles/000/overlanders-in-the-columbia-river-gorge-1840-1870-a-narrative-history.htm) describes travelers choosing the river route to avoid Cascade winter conditions. These support a seasonal race and regional differences, not exact monthly probabilities, forage yields or clinical damage rates.

The game retains its existing continuous overland route. No alternative Columbia boat route, lodging system or instant pass closure is introduced. All precise new multipliers are authored estimates in `data/survival_rules.json`, explicitly labeled as such.

## What changes in play

- Seasonal ground conditions slow travel from autumn into winter, even between storms. Both wagons and walking parties are affected. Summer ground factors stay at1; uplands receive a stronger penalty than lowland country.
- Poor winter forage reduces an ordinary camp-rest day's team recovery from4 condition points to2. Non-travel work also respects the lower forage recovery. Winter work adds strain, especially in uplands. Rest still helps, but no longer restores the animals at a summer rate.
- Winter blizzards become more frequent. The normal seasonal generator no longer draws its winter blizzard event during May-August. A forced-weather testing hook can still select it deliberately.
- Ordinary clothing continues to prevent the existing large unprotected-exposure penalty. In November-February blizzards, it no longer erases all exposure: a small additional storm penalty applies through the existing personal damage handling. Clothes remain materially useful.
- Autumn and winter notices appear in the travel story. The typed rest confirmation includes the current seasonal warning or a warning for the projected end of the planned rest. Opening or reading a warning costs no time and consumes no randomness.

November-February is the authored winter-risk window, not a claim that all regions share a single meteorological season. Snow remains possible in spring and autumn. The seasonal ground table changes by month, and short-term weather still varies. Team condition, load, fatigue, illness and actual delays continue to compound these effects.

## Weather and movement comparison

[Before](winter-pressure-before.json) and [after](winter-pressure-after.json) contain36 terrain/month scenarios with1,000 weather samples each. Each scenario uses the same seed, a healthy six-ox team and zero fatigue. Values below include weather and terrain before cargo; they are movement multipliers, not observed historical mileage. The scenario months are sampled separately, not stitched into reconstructed annual climate. The new generator consumes randomness differently, so individual days are not paired observations.

| Country | June, before | June, after | December, before | December, after |
| --- | ---: | ---: | ---: | ---: |
| Plains | 0.947 | 0.947 | 0.903 | 0.599 |
| Mountains | 0.763 | 0.765 | 0.709 | 0.366 |
| Blue Mountains/Cascades forest | 0.832 | 0.832 | 0.807 | 0.420 |

In the new mountain scenario, December movement is about48% of June movement. That is a substantial jump in difficulty before worsening animal condition, cargo and fatigue. The sampled December mountain scenario has187 blizzard days per1,000 draws. This is an authored model result, not an1848 climate estimate; the configured snow chance is conditional within the generator and must not be described as a direct daily frequency.

## Full journeys: stronger pressure, balance still open

[Diagnostic04](historical-diagnostic-04.json) repeats the108 setups from diagnostic03 under the new live rules. Setup quantities, prices, starting funds and study policies are unchanged. Previous reports remain archived with their earlier fingerprints.

| Capital,36 runs each | Arrivals before | Intact before | Arrivals after | Intact after |
| --- | ---: | ---: | ---: | ---: |
| Farmer | 27 | 19 | 23 | 3 |
| Carpenter | 36 | 36 | 36 | 33 |
| Banker | 36 | 36 | 36 | 35 |

Total after:95 arrivals,12 losses and one year-limit outcome, with zero selected inventory/party/remains/save/policy errors. Elapsed-day categories reconcile to final dates in every run. There is no live365-day defeat rule; that cap belongs to the diagnostic.

**The sharp loss of intact farmer parties is a material balance concern, not evidence that calibration is finished.** Much of the extra mortality is starvation and exposure as slow journeys extend into worse conditions. The comparison changes the seasonal package together; it does not isolate one multiplier as the cause of each death. Repeated rich-party food strategies also often duplicate behavior, so the rows are not independent historical travelers.

To examine whether decisions can help, [rest/care diagnostic02](rest-care-diagnostic-02.json) repeats128 earlier policy setups under the winter rules. In the six-ox farmer cohort, reference rest/care yields14/16 arrivals but only3 intact; later rest yields14/16 with7 intact; earlier care gives12/16 with5 intact; combined gives14/16 with4 intact. Carpenter arrivals remain16/16 for each policy, with13-16 intact. No selected errors occur. These small development samples demonstrate possible intact survival and consequential choices; they do not establish an optimal policy or a target win rate.

Retain the seasonal mechanism and warnings. Before further tuning, expand timely-departure and resource-use cohorts, investigate food value, and check human pacing. Do not inflate starting money to erase winter costs, but do not call a mechanically opaque cascade satisfactory merely because it is difficult.

## Compatibility and validation

The prior live fingerprint `e2552edfb52253cb1bdf283e9bec41c7b8e0118f89ec91d640cb9a99d4b115c0` is accepted by the existing migration path. An authentic pre-winter fixture checks unchanged cash, supplies, time, pending choices and RNG on load. Seasonal pressure is derived from the current calendar/region, so no new serialized weather-state fields are required. Future days follow the new rules; the past is not replayed or refunded.

All31 suites in `test.ps1` passed, including25 new winter checks covering malformed rules, summer/winter weather, actual movement, team recovery, walking, clothing, warnings and migration. The native rendered game view was inspected: the rest warning and meal quote fit the window. Rendering/import reported no script errors. Every new Godot script has its UID. Ongoing art changes and actual player saves were untouched.

Reproduce the direct seasonal study with Godot `--headless --path . --script tests/seasonal_pressure_study.gd -- --label=winter-pressure-next`; the script refuses existing labels. The journey harnesses likewise require new archive labels. Use project-local APPDATA as in `test.ps1`. Run `tests/test_winter.gd` for targeted regressions; its `--capture` flag saves the rendered rest preview under ignored `.tools/`.
