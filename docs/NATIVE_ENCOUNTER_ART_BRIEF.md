# Native community encounter artwork

Review brief, October 27, 2026. These are original scenes for specific local visits in 1848, not a generic camp asset. Spencer approved the first Wasco scene on October27,2026. It is installed for The Dalles visit and companion search; the other six visits retain their existing landmark backgrounds.

Follow [the Aseprite Lua workflow](../art/aseprite/README.md): 432 × 150 pixels, existing named palette, integer pixels, opaque background, upper-left light. Deliver the Lua source, layered Aseprite file and nearest-neighbor enlarged preview. Show Spencer each draft before installation. Do not trace references or reuse proprietary game art.

## Seven scene briefs

| Proposed PNG | Visit | Composition and evidence limits |
|---|---|---|
| encounter_platte | Pawnee trading families | Platte-country seasonal trading stop, river valley and provision bundles. Pawnee farming and buffalo hunts are documented; do not transplant a later reservation village or assume all housing was tipis. |
| encounter_fort_hall | Northern Shoshone and Bannock families | Families meeting near the private trading post, seasonal provisions and animals. Distinct communities; no 1868 reservation buildings, flags or signage. Research any dwelling before including it. |
| encounter_grande_ronde | Nez Perce horse traders | Valley grassland, several horses and people negotiating beside the herd. Avoid making every horse a modern registered Appaloosa or adding ceremonial clothing. |
| encounter_umatilla | Umatilla trading families | River-country provisions, produce and exchange near occupied food-growing ground. Do not treat Umatilla, Cayuse and Walla Walla as one nation or use later reservation layouts. |
| encounter_deschutes | Sahaptin-speaking river families | Swift rocky channel, local pilot, canoe and waiting loads on an actual gravel bar. Fishing places remain visible. Guidance does not make the water safe. |
| encounter_the_dalles | Wasco trading families | Columbia basalt shelves, prepared food parcels, baskets, plain work rack and exchange at a landing. Original composition; not a surveyed reconstruction. |
| encounter_columbia_raft | Upper Chinookan portage crews | Cascades landing, loads being carried along a shore path, river rapids and working families. No locks, railway or later commercial portage infrastructure. |

Keep the everyday work legible at native size: exchanging goods, handling horses, navigating water or carrying loads. Do not use feathered warbonnets, tipis or decorative motifs as a universal shorthand. Clothing, canoe construction, basket patterns and architecture require place- and date-specific references before detailed rendering. Sacred designs and invented ritual scenes are unnecessary.

## First composition draft

Source: `art/aseprite/scenes/encounter_wasco.lua`. Review outputs: `.tools/native-art-review/encounter_wasco_draft.png`, its `_x3.png` preview and layered `.aseprite`. Approved and installed as `art/pixels/encounter_the_dalles.png`, with identical PNG bytes to the reviewed draft. This intentionally omits unverified house architecture; plain garments, a dugout silhouette and baskets remain provisional visual interpretations, not authenticated artifact replicas. Refine figure scale, clothing and equipment references before treating it as final artwork.

## Runtime contract

Proposed filenames above end in `.png`; only `encounter_the_dalles.png` is installed. Install further scenes after approval via the Aseprite pipeline and display the community image in the existing main illustration area while its visit is open, restoring the landmark on exit. Keep the 432 × 150 composition so the service menu and party preview remain usable. Recruitment should retain the community setting without implying that every person there wishes to leave home. Do not edit simulation rules to install artwork.

## Reference starting points

- [Pawnee Nation: homeland and seasonal hunts](https://pawneenation.org/historical-marker-pawnee-marker-nebraska/).
- [Shoshone-Bannock Tribes: history and ancestral country](https://www.sbtribes.com/about/).
- [CTUIR: Umatilla, Cayuse and Walla Walla history](https://ctuir.org/about/brief-history-of-ctuir/).
- [Confederated Tribes of Warm Springs: Wasco and Warm Springs history](https://warmsprings-nsn.gov/history/).
- [Nez Perce tribal newsletter: horse history](https://nezperce.org/wp-content/uploads/2022/04/Volume-4-Issue-8.pdf).
- [NPS: overlanders in the Columbia Gorge](https://home.nps.gov/articles/000/overlanders-in-the-columbia-river-gorge-1840-1870-a-narrative-history.htm) and [full historical report](https://www.nps.gov/oreg/learn/historyculture/upload/HRA_Columbia_River_Narrative_History_Final_200917-reduced-size.pdf).

These sources establish activities and geographic context. They do not authenticate every garment, basket or boat in the draft. Seek dated museum/tribal material for the next detail pass, without copying or tracing objects into the artwork.

## Detail-reference follow-up

[Warm Springs community arts and basketry account](https://www.lib.uidaho.edu/digital/L3/ShowOneObjectSiteID66ObjectID981.html), credited to the Confederated Tribes of Warm Springs,2003: describes food-storage bags, plant-fiber nets, basket hats and tule mats, with objects separately dated1800s,1905,1950s and2000s. Treat those dates separately: a modern demonstration is evidence of technique, not a literal1848 outfit. Do not reproduce meaningful woven designs as generic decoration. This supports storage containers and fishing work but does not authenticate the draft's silhouettes.

[Royal Ontario Museum on Paul Kane](https://www.rom.on.ca/rom-publications/wanderings-artist-among-indians-north-america) identifies his late1840s travels and later1859 publication. His sketches may help establish period equipment once checked individually; later finished paintings and an outsider's interpretation are not neutral exact reconstructions. The Stark Museum catalogue search identified *Three Canoes and Paddles of the Columbia River*, but its object page was bot-blocked during this pass; construction details remain unverified rather than inferred from a search title.

## Installed Wasco scene

`data/location_scenes.json` maps the presentation-only encounter key `the_dalles` to `encounter_the_dalles`. The main illustration switches while its community visit or local recruitment is open, including a restored save, and returns to the existing Dalles landmark on exit. Other visits retain their landmarks. No economy data, simulation RNG, save fingerprint or supply totals changed. The approved composition retains the evidence limits described above; approval does not make it an authenticated reconstruction.
