# Dairy feed energy calibration

October 26, 2026. This replaces the cow/goat 70%–95% generic ration-to-milk curve with **maintenance energy plus the milk currently being produced**. Hen nutrition and its opt-in use of edible portions remain unchanged. The existing milk ceilings stay 8 lb/cow and 2 lb/goat daily.

Players see upkeep coverage and feed-supported milk potential in Livestock. The internal nutrient arithmetic stays in the simulation.

## Physical feed and demand

The independent `simulation/ruminant_nutrition.gd` calculates pounds of dry matter (DM) and total digestible nutrients (TDN). Human food calories are not substituted for livestock TDN. Cow/goat budgets use these representative parameters in `data/livestock.json`:

| Parameter | Cow | Goat |
|---|---:|---:|
| Representative/reference live weight | 1,000 lb | 100 lb |
| Maximum daily DM intake | 2.2% body weight = 22 lb | 3.5% = 3.5 lb |
| Reference maintenance allowance | 8.8 lb TDN | 1.24 lb TDN |
| Additional energy per lb milk | 0.27 lb TDN | 0.33 lb TDN |
| Selected natural forage TDN fraction of DM | 60% | 65% |

These are explicit calibration assumptions, not measured 1848 trail-animal averages. The animal sizes are representative species settings, not new per-animal size traits. Maintenance scales by `(weight/reference weight)^0.75` for sensitivity experiments; intake capacity scales with weight. Clear-weather travel adds an authored 5% maintenance allowance, grueling travel 15%, in addition to the existing feeding-time opportunity cap. Dairy animals no longer also receive the old automatic grueling-work condition loss: that energy cost is charged once. Independent thirst/extreme-weather constraints still apply.

A bought pound of hay is now a physical pound containing an assumed **0.9 lb DM and 0.495 lb TDN** (90% DM, 55% TDN on DM). A daily feed deficit does not make dry matter and hay pounds interchangeable. Hay fills the actual energy gap up to the animal's intake limit. If hay is richer than poor forage it can replace forage; replaced forage is removed from intake and energy totals. Poorer hay cannot be piled on top of a full rumen. The simulation only consumes useful available hay and preserves full/partial physical pounds. Species groups share scarce carried hay in proportion to their feasible gaps.

Within each species, maintenance is covered first; surplus supports the current milk target. Tapered or dry animals consequently need less energy than animals at full lactation. The existing taper is applied to the milk amount once, not again as an unrelated feed penalty. Nutritional maintenance deficits drive existing gradual condition losses; Fair/Good body capacity remains unchanged. The numerical condition-loss clock itself is still an authored abstraction.

## Evidence and derivations

Sources rechecked October 26, 2026. The [preceding evidence review](FORAGE_EVIDENCE_AND_SHARING.md) records the fuller limitations.

- [Oregon State cattle requirements](https://extension.oregonstate.edu/catalog/cms-135221-basic-nutrient-requirements-beef-cattle), Appendix 2: the 1,000 lb dry mid-pregnancy example has 8.8 lb TDN; the 10 lb milk example has 11.5 lb TDN. The cow coefficient is the explicit approximation `(11.5−8.8)/10 = 0.27`. Those are different physiological states, not a controlled milk-energy experiment; the dry reference includes pregnancy. It is a practical low-yield proxy, not a pure maintenance measurement.
- [USDA AMS DM tables](https://www.ams.usda.gov/sites/default/files/media/NOP-5017-3-DryMatterDemandTablesforClassesofBeefCattle.pdf), table 2-1: the 1,000 lb, 10 lb peak-milk example spans 21.6–23 lb DM in early lactation. The selected 22 lb capacity lies within that envelope. [Nebraska Extension](https://beef.unl.edu/cattleproduction/forageconsumed-day/) also distinguishes lactating-cow DM intake from as-fed hay. This supports an intake scale, not an exact trail diet.
- [Langston goat feeding examples](https://goats.langston.edu/feeding-different-classes-goats/): 95 lb early-pregnancy doe, 1.19 lb TDN; 110 lb doe producing 4.5 lb milk, 2.8 lb TDN. Scaling the former to 100 lb gives approximately 1.24; adding 0.33 per milk pound predicts about 2.82 at 110 lb/4.5 lb milk. This interpolates different animals/stages and is expressly an estimate. Langston notes that diet composition affects intake predictions; these examples are not historical goat records.
- [Nebraska goat production](https://extensionpubs.unl.edu/publication/g2267/2016/html/view) gives a broad mature-doe intake envelope of 2–5% of weight; 3.5% is a central working allowance, not a breed-specific maximum.
- [Oklahoma State feed values](https://extension.okstate.edu/fact-sheets/nutritive-value-of-feeds-for-beef-cattle) distinguish moisture-free nutrient analysis from physical feed and include hay examples around 90% DM and mid-50s TDN. Those support the selected ordinary-hay proxy. They do not establish quality of an actual 1848 purchase. Natural forage quality values are selected moderate/good energy scenarios, not lab results for every trail region.
- [MSD Veterinary Manual goat nutrition](https://www.msdvetmanual.com/management-and-nutrition/nutrition-goats/nutritional-requirements-of-goats) distinguishes maintenance from production and metabolic body size. Its higher modern dairy potential is not used to raise the game's milk ceiling.

## Boundaries of this change

The existing habitat, monthly and travel-time caps now limit **obtainable dry matter**, rather than pretending to be nutrient requirements. Their values remain unchanged. Natural forage quality differs by species but is still constant across regions/months; local green-up, diet selection, grass depletion and site-specific nutrient quality need another calibration step. This patch establishes a physical/energy basis for that work, rather than assigning unsupported new regional percentages.

Protein/mineral balance, offspring milk share, body-reserve-supported temporary milk, pregnancy, feed spoilage, herd competition for a campsite and feed-quality effects on gut passage are not simulated. Energy sufficiency is therefore not a claim of a complete real-world ration. No prices, starting money, animal slaughter yields, maximum milk, care labor or human ration levels changed. The new hay-shopping diagnostic uses the actual feasible hay gap; the old campaign fallback remains for older runtimes. Historical studies must still be reproduced at their frozen snapshots.

## Saves and verification

Prior-rule on/off saves with real dairy animals and fodder were captured before editing; the missing-setting case is a derived compatibility variant. Fingerprint `7f82b97839c8d10929e9e90d7dcea47ec50694cffaae1e263686fd6f457bb2bb` is allowlisted. Loading preserves existing conditions, remaining lactation, choices, feed, food, money and random state; only future feeding uses the new rules.

Near-maintenance tests exposed sub-nanopound milk rounding into invalid saved products. New milk mass is canonicalized to nine decimal places before deriving its calories; rounded zero output creates no serving. Feed diagnostics saved in supply history also use canonical decimal precision, so exact JSON reloading preserves them. This is negligible numerical rounding, not a new food-unit rounding rule.

`tests/test_ruminant_nutrition.gd` covers independent reference anchors, feed energy conservation, rumen replacement, monotonic availability, sizes/quality/demand, actual late-lactation ticks, grueling maintenance, tiny products, previews and genuine prior saves. Its 5,446 checks supplement the existing livestock/feeding suites. Final runtime `ae977ce0da27e836e47d34afdcb18f0953a34a3e` passed all **84 test.ps1 suites**, **1,728 isolated actual dairy ticks** across the declared sensitivity grid and **40 default-context probes**. **24 complete farmer journeys** (cow/goats/mixed, standard/lean, May/July, two seeds 435000–435001, actual gap-based hay buying) recorded zero state/save/policy errors. These journeys purchased 630 lb hay in total. The complete source-stamped archives passed source/hash and feed/milk conservation checks. [Compact validation](ruminant-energy-validation-01.json), verifier `tests/summarize_ruminant_validation.py`; local raw sensitivity03, context01 and hunting-ruminant-energy-smoke-*-02 reports stay in ignored `.tools/`. Preflight sensitivity reports 01/02 and smoke reports 01 are excluded from publication evidence; they preceded the final precision/work-accounting corrections. This is not a new matched survival balance study.


In the default clear-weather, full-care resting context without hay, Fair/Good animals gave identical milk. May/July plains retained the 8/2 lb ceilings; high country supplied about 4.07/1.07 lb, versus the previous 1.6/0; sagebrush still supplied zero cow milk without supplementation. Ample hay restored ceilings in all 40 selected default-context cases. These are consequences of the stated nutrient assumptions, not new measured regional yields or evidence of a solved survival balance.
