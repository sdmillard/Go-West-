# Seasonal river fish

Fishing now chooses from seven fish types and six habitat profiles mapped to all 12 existing river stops. Ordinary positive rounding is used: 4.49 units -> 4; 4.50 -> 5. The catch popup says "You caught a [fish]! ([whole weight] lbs)"; the end report tracks edible flesh and actual packed food. Whole catches are named in the journal.

## Profiles and authored ranges

| Profile | Sites | Fish |
|---|---|---|
| Prairie | Wakarusa, Kansas, Big Blue, South/North Platte crossings | Channel catfish, white sucker |
| Green River | Green River crossing and Greenwood branch | Flannelmouth sucker, Colorado River cutthroat, mountain whitefish |
| Lower Snake | Three Island area, Fort Boise | Redband trout, mountain whitefish, seasonal Chinook |
| Umatilla | Umatilla | Redband, mountain whitefish, seasonal Chinook |
| John Day | John Day | Redband, mountain whitefish, spring-profile Chinook |
| Deschutes | Deschutes | Redband, mountain whitefish, seasonal Chinook |

Salmon have zero selection weight outside their configured run windows. Resident fish remain possible in winter, with lower overall bite factors. Prairie catfish favor warmer months; sucker weights favor spring. These are authored monthly approximations informed by habitat/run evidence, not measured 1848 catch probabilities or current fishing regulations.

| Fish | Usual whole weight | Occasional large weight | Edible fraction | kcal per edible lb |
|---|---:|---:|---:|---:|
| Channel catfish |1-4 lb |5-10 lb |50% |430 |
| White sucker |0.5-2.5 lb |3-4 lb |55% |420 |
| Flannelmouth sucker |1-3 lb |4-6 lb |55% |420 proxy |
| Colorado River cutthroat |0.5-2 lb |2.5-4 lb |55% |540 proxy |
| Redband trout |0.5-2.5 lb |3-5 lb |55% |540 |
| Mountain whitefish |0.5-1.5 lb |2-3 lb |55% |600 proxy |
| Chinook salmon |6-16 lb |18-28 lb |60% |810 |

Rare size bands occur 4-8% of selected fish, depending on type. Whole weights are quarter-pound steps; edible mass is retained fractionally. Fractions and size frequencies are game estimates, not a fillet-only laboratory yield or a historical catch survey. Larger salmon are localized, not a blanket fishing buff. The existing access radii, casts/time, horse requirements, meals, ammo-free activity, cargo, animal wear and preservation are unchanged.

## Food conversion and compatibility

Whole weight -> edible fraction -> actual retrieval -> species calories -> sum the catch -> round once to food units. Mixed catches use their mass-weighted energy density and proportional retrieval when hauling limits bind. Companions use the same species/season rules and aggregate their actual landed fish before conversion.

There is no per-fish minimum unit. A total catch below 500 kcal rounds to zero; several small fish may collectively cross the threshold. The existing whole-unit inventory cannot preserve sub-unit energy credits. A zero-unit catch creates no food batch, and any unrepresented flesh is reported as left behind. Non-fishing generic meat keeps its existing minimum-one convention for compatibility. No broad food/economy rebalance is included.

Fractional mass is preserved through retrieval, fresh batches, drying and JSON saves. Animation uses floating catch weight so a sub-pound landing still plays. The fishing audit observers also retain fractional quantities and actual generated units; historical audit rows retain their old reconstruction semantics.

The prior 55df67ba...07b06 rules fingerprint is whitelisted. An authentic previous-source fixture contains old generic fish batches and an active away hunter. Existing food amounts, physical ratios, reserved stock and RNG remain unchanged; future catches use the profiles. Active fishing still must finish before saving.

## Evidence and limits

- [Kansas wildlife department, channel catfish](https://www.ksoutdoors.gov/outdoor-activities/fishing-in-kansas/what-to-fish/channel-catfish) supports river/prairie-stream habitat. [Wyoming Game and Fish, Big Creek](https://wgfd.wyo.gov/Fishing-Update/Big-Creek-fish-passage-project-to-benefit-trout) identifies native white sucker in the North Platte drainage. Warm lower-crossing profiles do not copy modern stocked trout fisheries.
- [Wyoming Game and Fish, Green River](https://wgfd.wyo.gov/Fishing-and-Boating/Instream-Flow-XStream-Angler/Instream-Flow-Map/Green-River---Segment-No.-1), [native sucker restoration](https://wgfd.wyo.gov/Regional-Offices/Green-River-Region/Green-River-Region-News/Native-fish-restoration-project-underway-on-Big-Sa), and [US Forest Service basin assessment](https://www.fs.usda.gov/sites/nfs/files/publication/20250714Draft%20B-T%20Supplemental%20Assessment%20Information_0.pdf) inform native basin membership. Upper-basin records do not establish exact catch odds at the wagon crossing; those weights are authored.
- [ODFW redband trout](https://myodfw.com/fishing/species/redband-rainbow-trout) identifies native eastern-Oregon rainbows. [Northwest Power and Conservation Council](https://www.nwcouncil.org/reports/columbia-river-history/salmonandsteelhead/) describes spring, summer and fall salmon runs. [NOAA run timing](https://www.fisheries.noaa.gov/west-coast/climate/run-timing-matters-evolution-plasticity-and-functional-extinction-unique-pacific) supports timing differences. Our month-by-site matrices are approximations, not all reaches of a river sharing identical runs.
- [Columbia River Inter-Tribal Fish Commission](https://critfc.org/tribal-treaty-fishing-rights/policy-support/columbia-river-treaty/area-blocked-salmon-columbia-basin/) identifies Shoshone Falls as the historical salmon barrier. The two mapped Snake sites are downstream; this does not add salmon to Fort Hall or waters above the falls.
- Raw edible energy references: [USDA fish tables](https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR/SR28/reports/sr28fg15.pdf) for channel catfish, white sucker and wild rainbow; [NOAA Chinook](https://www.fisheries.noaa.gov/species/chinook-salmon) for salmon. Flannelmouth/cutthroat/whitefish entries are explicitly labeled nutritional proxies rather than claimed assays.
- [FAO fish-yield compilation](https://www.fao.org/4/T0219E/T0219E01.htm) distinguishes skinless fillets and edible flesh; its Pacific-salmon edible-flesh estimate is about 62%. The authored 50-60% factors are practical approximations and are applied once. No free bone-broth or organ-calorie bonus is added.
- Indigenous fisheries, access and seasonal knowledge are not unoccupied infinite resources. This patch does not add nets, commercial harvesting, new access arrangements or encounters. It also does not promise that more realistic small catches make farmer journeys easier.

No new art is required: existing fishing sprites represent the action; names and weights identify individual catches. Livestock remains queued after this fishing calibration.

## Frozen validation results (October 25, 2026)

Runtime/data/GDScript were frozen at e2cb920. All 76 Godot suites passed, including 2,718 seasonal-fish checks, 78 existing fishing checks and 46 audit checks. Native previews verified the setup list, fractional landing and named/weighted catch popup using the existing approved art.

The final campaign covered 144 new-rule journeys, 48 paired old-rule support-policy controls and 1,800 actual controlled fishing trips. Full archives remain in ignored .tools; [compact results](seasonal-fish-summary-01.json) and [hashes/control checks](seasonal-fish-validation-01.json) record their provenance. All report copies were verified against isolated originals. Journey policy sources and matched starting outfits/costs were unchanged. The 24 store and 20 outlaw journeys had identical rows to their previous unfished controls.

In the controlled healthy prairie-bank sample, mean edible yield was 3.18 lb and mean generated food 1.33 units per outing, compared with the previous generic model's 7.12 lb / 4.27 units. At four road miles on foot, new mean food was 0.72 units; at twelve miles by horse, 0.55. These are one-site probe results, not averages across all rivers or seasons. The new calculation uses whole-fish mass and species energy; this is a correction, not a food buff.

In paired support-policy journeys, development farmer arrivals changed from 0/8 to 1/8; held-out farmer arrivals stayed 0/8. Carpenter and banker arrival counts were unchanged in both phases (development 6/8 each; held-out 7/8 and 8/8). These small cohorts do not establish farmer balance. Held-out off/leader/support farmer arrivals were all 0/8. No rules were tuned after viewing those results. Larger western seasonal catches and broader survival choices need human playtesting; livestock remains the next proposed feature.
