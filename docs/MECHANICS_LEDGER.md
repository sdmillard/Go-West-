# Mechanics research ledger

Current implementation updates supersede older prototype amounts below: [economy/preservation](ECONOMY_AND_PRESERVATION.md), [walking](WALKING_AND_RECOVERY.md), and [regional conditions, trading and activities](REGIONAL_TRAVEL.md). Earlier source comparisons remain archival evidence.

Latest calibration: [Balance pass 01](BALANCE_PASS_01.md) compares BASIC arithmetic, period provisioning advice and NPS travel ranges with engine output. Nominal player paces are now 16/20/24, fed rest recovery 3/5/7 by ration level, spontaneous injuries removed from illness rolls, and automatic cholera gated to 1849+. Historical bounds and gameplay values remain explicitly separate; this is not a recovered classic algorithm or a fitted mortality model.

Current implementation: the [BASIC survival benchmark](BASIC_SURVIVAL_BENCHMARK.md) adds weather/exposure, clothing, team condition/fatigue, hunting/ammunition, purchases/barter, care and functional counterparts to the sixteen selector categories plus rider tactics. Earlier missing-feature notes are research history where superseded by this benchmark. Route extension remains deferred until these mechanics are tuned.

Current direction: **historical accuracy takes priority over matching classic-game rules** (user decision October 22, 2026). The games remain comparison references. The setting is 1848; absurd content stays parked. See `HISTORICAL_ACCURACY.md` for supported changes and outstanding limitations.

The complete BASIC coverage comparison is in [Classic mechanics audit](CLASSIC_MECHANICS_AUDIT.md): all sixteen primary event branches, the other major systems, transcription problems, and later classic features absent from BASIC. The subsequent [party-health pass](PARTY_HEALTH.md) adds inspectable individuals, named conditions, recovery and personal deaths. Health is presented verbally; formulas, condition odds and recovery tuning remain provisional.

Evidence labels:

- **BASIC-verified**: inspected in a named local BASIC listing. Does not imply later-version behavior.
- **1985-documented**: stated in original 1985 documentation or a firsthand design account.
- **1993-observed**: personally observed in the supplied running Windows game, whose title/About show a 1993 copyright. Exact numeric build version remains unverified. See `REFERENCE_PLAYTEST_1993.md`.
- **New design**: our implementation or provisional tuning.
- **Unresolved**: evidence incomplete or edition uncertain.

Downloaded references and their hashes are recorded in `research/SOURCES.json`. Full third-party documents are under ignored `research/local/`; our game does not depend on them.

The complete public nine-story Bouchard series has also been read and archived. See `BOUCHARD_DESIGN_NOTES.md` and `research/BOUCHARD_SOURCES.json`. Distinguish final behavior from draft algorithms, cut ideas and comparisons to Lewis & Clark Stayed Home.

| Rule | Evidence and edition | Current implementation / decision |
| --- | --- | --- |
| BASIC distance | BASIC-verified, 1978 listing line 2860: base 200 miles plus animal-spending adjustment and random variation | Historical reference only; do not use as a daily 1985 formula |
| BASIC ration consumption | BASIC-verified, 1978 lines 2740–2850: three eating choices; cost 8 + 5 × choice per turn, tracked in food expenditure units | Not equivalent to pounds/person/day; current daily consumption is New design |
| BASIC event selection | BASIC-verified, 1978 lines 3540–3650: cumulative threshold selection from a single random value | Pattern reference; not a verified 1985 event frequency table |
| BASIC illness | BASIC-verified, 1978 lines 6290–6440: eating choice affects illness branching | Do not present prototype aggregate health as this system |
| Time framework | 1985-documented, Bouchard design retrospective: daily simulation within landmark-based travel, automatic travel interrupted by player/events | Continue/Pause implemented in the UI; event and river stops are automatic. 1.25 seconds/day is New design |
| Professions | 1985-documented, July 1985 H-106 booklet, PDF page 4: banker $2500, carpenter $1000, farmer $400 | Implemented using booklet values. Confirm against the selected executable before treating as universal 1985 values; score multipliers absent |
| Health/rest/rations | 1985-documented, H-106 booklet, PDF pages 4 and 8; Bouchard design account | Individual health, named conditions, severity, care, exposure, recovery and deaths exist. Conditional ration/severity branching follows BASIC; daily odds, strain, duration, verbal bands and treatment effects remain New design |
| Buying supplies | 1985-documented, H-106 booklet, PDF pages 4–5; 1993-observed prices/limits | Opening store and typed components implemented. Store values use 1993 observations, pending 1985 verification; see `OUTFITTING.md` |
| River choices | Historical NPS accounts plus classic design references | Player corridor uses a documented $1 period Kaw fare; no Marshall ferry in 1848. Stage-dependent odds/losses and one-day actions remain New design |
| Route | Historical primary guide: Palmer 1847, pp. 277–278 in 1906 reprint | Player corridor now reaches Oregon City over 1,938 reported guide miles; see `ROUTE_EXPANSION.md` for the continuous southern/Barlow itinerary and deferred branches. Kansas at 81 and Big Blue at 174 sum this guide's estimates, not universal surveyed lengths. The scripted 102-mile fixture remains only for regressions |
| Party | 1985-documented, Bouchard human-character account: leader and four named companions | Five named records with independent health/conditions, history and survival state. View Party shows each person; surviving count controls food demand. Continuation after leader death is provisional |
| Weather | 1985-documented, H-106 booklet PDF page 10 describes location/month-based weather | Daily seasonal/terrain scenario model implemented; movement, exposure, wet ground and river risk connected. No verified climate statistics yet |
| Art/interface | 1993-observed mouse interface; Bouchard's 1985 travel-screen design account | Original Western pixel assets and mouse menus. Compact travel status and distinct landmark arrival are design targets |
| Starter supplies | New design | Player chooses purchases; suggested $380 / 800 lb-food outfit and initial health 85 are provisional. Old 180-food/$60/two-wheel fixture remains only for direct scripted simulations |
| Current events | New design | Day-2 muddy wheel and mile-102 river trigger are prototype content, not verified classic event timing |
| Rarity and absurd examples | New design, deferred | Existing development examples retained, unavailable through the Classic-first game menu |

## New Windows observations, kept separate from 1985

These describe a game, not authority for actual geography or prices. The historical corridor supersedes the old player-facing 102-mile endpoint.

- Eight occupations; banker starts with $1,600. The 1985 booklet says $2,500 for the banker. The discrepancy is recorded, not silently resolved.
- First store prices and maxima, three separate spare-part types, and 20-bullet boxes are documented in `REFERENCE_PLAYTEST_1993.md`.
- Kansas River is 102 miles from Independence in the observed Windows build. This verifies our first-leg distance for that edition, not independently for all 1985 builds.
- In the observed five-person Filling run, food consumption matched 15 lb/day including fog delays. Other ration formulas remain unverified.
- Automatic movement, Time Out, illustrated repeatable fog events, weight categories and four river methods were directly observed.
- Ferry offer in this run: $5 and six days waiting. Our current $15/one-day choice is still New design, pending a proper river implementation.
- Compiled executable/resource/help/settings files are available for local examination; none is the 1985/1993 source code.

## Verification order

1. Completed: inspect the supplied Windows installer in isolation; running game shows 1993 copyright. Exact numeric build remains unresolved.
2. Completed for the observed Windows run: departure, banker setup, outfitting, quantities/prices and party setup. Compare the supplied Apple II disks before adopting edition-specific values.
3. Completed opening implementation: departure/store/party data with inventory accounting tests. Continue/Pause implemented; verify exact 1985 values before claiming parity.
4. Verify the route, travel/ration/health behavior, weather, illness and repair rules.
5. Add hunting, trading and scoring, then compare complete journey outcomes.
6. Resume optional absurd content after Classic has a stable, documented baseline.

The 1978 repository header mentions July–August while its README links the May–June magazine. The downloaded May–June scan contains the Oregon material around PDF pages 140–147. Treat the transcription as a modified reference with a provenance discrepancy to resolve, not an exact archival facsimile.

Sources: [BASIC reference repository](https://github.com/fortran-gaming/oregon-trail-1975), [July 1985 manual](https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/educational/mecc/documentation/oregon_trail/The%20Oregon%20Trail.pdf), [Bouchard design account](https://www.philipbouchard.com/oregon-trail/imagining-design.html), [Bouchard river account](https://www.philipbouchard.com/oregon-trail/crossing-rivers.html), [Bouchard geography account](https://www.philipbouchard.com/oregon-trail/real-geography.html).
