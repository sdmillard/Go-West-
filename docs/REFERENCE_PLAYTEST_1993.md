# Reference playtest: supplied Windows game

Observed October 21, 2026. This is a study of the user's supplied repack, not the original 1985 executable. Findings below are **1993-observed** unless explicitly marked as an inference.

## Build and environment

- Archive: `The-Oregon-Trail_Win-3x_EN_LGU-Repack-by-Bladez1992-DPKG-by-HorrorWeed.zip`.
- Archive SHA-256: `cf3be03ae8c9e6e1b5c2effcb13c68c0202d5673085ba0d471c6a46c162d1ff2`.
- ZIP contains one modern 32-bit installer, not source code.
- Installer ran inside a non-root, restricted Docker/Wine container with no personal-folder mounts and no external network route. Browser desktop access uses a separate fixed-endpoint loopback relay.
- Repack installs DOSBox 0.74-3 and Windows 3.11; the game is launched from Program Manager.
- Title/About screens display MECC copyright 1993. No numeric application version was visible; do not call this an authenticated unmodified first release.
- The display is configured for 640 × 480. The repack's scaling/fullscreen settings were changed for inspection; those are wrapper settings, not game rules.

## Departure and purchases

The setup screen requests a leader name and four other party members. Eight occupations are offered: banker, blacksmith, carpenter, doctor, farmer, merchant, saddlemaker and teacher. We used the banker with four default companion names, and selected an April departure. Available departure buttons run from March through August.

The banker had **$1,600** before purchases. This differs from the **$2,500** stated in the downloaded July 1985 H-106 booklet; preserve both edition-labelled observations rather than silently choosing one as universal.

Observed initial-store values:

| Item | Unit price | Maximum shown |
| --- | ---: | ---: |
| Oxen, each | $20 | 20 |
| Clothing, set | $10 | 50 |
| Ammunition, 20-bullet box | $2 | 100 boxes |
| Spare wheel | $10 | 3 |
| Spare axle | $10 | 3 |
| Spare tongue | $10 | 3 |
| Food, pound | $0.20 | 2,000 lb |

Purchased six oxen, five clothing sets, 20 ammunition boxes (400 bullets), two of each spare part and 1,200 lb food. The store displayed a **$510 total**. The interface computes a running bill before Buy. These are in-game prices, not claims about real nineteenth-century markets.

## Travel observations

- Started April 1, 1848, with good health, filling rations, steady pace and a heavy wagon.
- Continue starts automatic day-by-day movement. Time Out pauses it. Landmarks and modal events stop or interrupt travel.
- Travel screen combines a small wagon animation, route map, current conditions, distance, categorical health, food, pace, rations, wagon-weight category and a scrolling dated journal.
- Side controls include dropping cargo, a guide, party status, rations, buying, trade, conversation, rest, pace and hunting. Their presence is observed; not all have been exercised.
- First destination is Kansas River Crossing, **102 miles** from Independence.
- April 4: 42 miles traveled, 1,155 lb food. April 5: still 42 miles, 1,140 lb. April 9: 86 miles, 1,080 lb. April 11: river reached at 102 miles, 1,050 lb.
- Across this five-person, filling-ration run the food change is consistent with **15 lb per elapsed day**. This is an observed case, not a complete consumption algorithm.
- Fog produced an illustrated interruption costing a day, and recurred on subsequent days. The prototype's once-per-ID event policy is therefore an intentional simplification requiring future revision for ordinary weather events.
- Weight changed from Heavy to Middling as food was consumed. Exact weight thresholds and their effect on speed remain unverified.

Pace dialog offers Steady, Strenuous and Grueling, with qualitative explanations about hours traveled, rest and fatigue. Rations dialog offers Filling, Meager and Bare-bones meals. We retained Steady/Filling; this session does not establish the other tiers' numeric effects.

## First river decision

At Kansas River on April 11 the game reported **624 ft width and 5.2 ft depth** for this run. Options were ford, caulk/float, ferry, or wait. These are run-specific conditions, not fixed river dimensions.

The ferry offered a **$5 fare and six-day wait**. We accepted. This is an observed offer; the wait distribution, fixed/variable nature of the fare and ferry risk rules are not yet reconstructed. Our prototype's $15/one-day ferry is explicitly provisional and differs from this observation.

The crossing succeeded on **April 17**, with **960 lb food** remaining and good health. The six waiting days consumed another 90 lb. The next destination display showed **83 miles to the Big Blue River crossing**. We stopped this reference pass at the successful crossing; we have not completed a full original-game journey or tested every action.

## Installed-file inspection

Selected files were read from the container into ignored `research/local/windows-game/` for study:

| File | Bytes | Finding |
| --- | ---: | --- |
| `OREGON.EXE` | 4,099,088 | Compiled 16-bit NE Windows module, with menus, dialogs, string tables and custom/raw resources |
| `OREGONSP.DLL` | 7,449,088 | NE resource module; exact meaning of custom types not established |
| `OREGON.HLP` | 735,856 | Compiled help file, not plain-text source |
| `OREGON.INI` | variable | Preferences/window placement and high-score list; observed size changes with use |

The parser found 570 nonempty string-table entries across the executable and DLL. These can help locate UI terminology, but strings alone do not prove hidden calculations. No original art, game text or code is adopted into our implementation. File hashes and the detailed resource inventory remain with the local snapshots.

## Implementation consequences

1. Build an actual departure/outfitting flow before adding more unusual events.
2. Keep 1985 professions distinct from the Windows edition's expanded set.
3. Model individual spare components, ammunition units and an accountable purchase bill.
4. Support repeatable weather events and time costs that still consume food.
5. Use landmarks and pause/resume travel as the main loop; consider an optional single-day step for testing/accessibility.
6. Add river conditions, wait/ferry choices and a time-cost model before claiming crossing fidelity.
7. Treat UI observations and compiled-resource findings as evidence, not proof of all simulation formulas.

Screenshots supporting this session are in ignored `research/local/1993-*.png`. The BASIC algorithms and 1985 documentation are compared separately in `MECHANICS_LEDGER.md`.
