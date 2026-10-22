# Bouchard's complete public Oregon Trail series

Historical accuracy now takes priority when it differs from these game design choices. These notes remain comparisons, not authority for real geography, prices or 1848 services. See `HISTORICAL_ACCURACY.md`.

Read all nine stories linked from the [author's Oregon Trail index](https://www.philipbouchard.com/oregon-trail.html), including the later-game comparison. This is the public website series, not the separately sold book. Local HTML and text snapshots are private research under ignored `research/local/bouchard/`; URLs, retrieval times and hashes are in `research/BOUCHARD_SOURCES.json`. Refresh with `research/read_bouchard.py`.

These are firsthand retrospective accounts. They explain design intent and some final behavior, but are not a complete specification of a particular disk release. Draft algorithms and discarded concepts must remain distinct from shipped behavior. The following are short original research notes, not replacement copies of the essays.

## 1. Earlier versions

[The Earliest Versions of the Game](https://www.philipbouchard.com/oregon-trail/early-versions.html)

The lineage runs from the 1971 classroom experiment through the 1975 MECC timeshare release and the 1980 Apple II adaptation. Early Apple II shooting became graphical, while much of the earlier turn structure remained. The 1985 product abandoned that inherited code and its algorithms.

Project consequence: use BASIC to understand the historical ancestor and compare decisions. It cannot establish the arithmetic of the 1985 daily simulation. Keep source-era evidence separate in the mechanics ledger.

## 2. Imagining the new design

[Imagining the New Design](https://www.philipbouchard.com/oregon-trail/imagining-design.html)

The redesign pairs daily resource updates with travel between named landmarks. Geography selects relevant activities; automatic travel stops for landmarks, important events or player intervention. Rest, rations, pace and other actions interact with the continuing resource model. Hunting, purchasing, risk, resource management and random incidents remain central, with more ways to make meaningful decisions.

Project consequence: retain an independent simulation engine, and give every time-consuming activity one shared daily advancement path. The mouse interface should offer Continue and Pause, with activity availability tied to the current situation. Our one-day button is a prototype, not the intended final travel loop.

## 3. The travel screen

[The Travel Screen](https://www.philipbouchard.com/oregon-trail/travel-screen.html)

The early large scenic travel view tested poorly. A small wagon animation, compact status information and approaching landmark symbols made progress engaging; the larger landmark illustration then gave arrival more impact. Ground color conveyed environmental conditions, and selected events had special illustrations. The displayed single ox was acknowledged as an abstraction.

Project consequence: preserve clear date, food, health and distance information around our original pixel animation. Make landmark arrival visually distinct. Neither wagon sprite count nor animation speed should determine inventory or miles traveled. Our richer 16-bit scenery is a deliberate presentation choice, to be tested for readability.

## 4. Hunting

[The Hunting Activity](https://www.philipbouchard.com/oregon-trail/hunting.html)

Hunting uses an eight-direction character, landscape obstacles and animals selected for the current environment. Memory pressure reduced planned animal variety and animation complexity. The final 100-pound carry limit deliberately made waste visible; some later editions allowed 200 pounds. Mastery over repeated attempts was intentional.

Project consequence: later implement a skill activity whose results return ammunition used, time spent and recoverable food to the simulation. Keep meat killed distinct from meat recovered. Use 100 pounds as the documented 1985 target, pending disk observation; do not import a later edition's cap silently. The essay's proposed species list is not a verified shipped roster.

## 5. Rivers

[Crossing Rivers](https://www.philipbouchard.com/oregon-trail/crossing-rivers.html)

Four crossings represent different rivers. Conditions include depth, width, current and bottom type; recent rainfall has greater influence than older rainfall. Ford, float and ferry outcomes depend on those conditions. Draft fording breakpoints changed during development: the final account describes a 2.5–3-foot swamping range costing drying time without supply or ox losses. The guide's final risk reduction is described as 80%, replacing an earlier 50%; warning and refusal behavior was cut. Successful animation could also represent muddy or swamped crossings, with text explaining the result.

Project consequence: replace the prototype's universal float probability with a condition-based resolver and explicit outcomes. Keep crossing calculation separate from animation. Do not transcribe draft screenshots as final executable rules; exact probabilities, boundary inclusivity and losses still need verification.

## 6. Real geography

[Incorporating Real Geography](https://www.philipbouchard.com/oregon-trail/real-geography.html)

The account identifies 18 locations connected by 20 segments and three branch decisions; a typical route visits 16 locations over 15 segments. The setting became 1848 to accommodate the selected forts. Weather uses month and location, with six climate locations and twelve monthly tables each. Terrain also influences hunting.

Project consequence: define a route graph rather than an unconditional linear list. Maintain separate location, segment, climate and hunting-region data. The geography essay describes six zones, whereas the hunting essay describes five terrain zones: these are unresolved model distinctions, not permission to invent a single verified zone map. Distances and climate table values are not supplied here.

## 7. Columbia rafting

[Rafting Down the Columbia River](https://www.philipbouchard.com/oregon-trail/rafting-columbia.html)

The ambitious original rafting idea was cut, then revived as a simpler finale. The shipped activity centers on dodging rocks and landing at a signed exit. Hiring guides and intermediate portages were omitted. Bouchard criticizes its rough animation and disproportionate collision losses; graduated collision damage is a hindsight suggestion rather than a shipped rule.

Project consequence: keep the Columbia finale separate from ordinary river crossings. First reproduce the documented objective and exit sequence using original assets. Any later refinement of collision damage needs a New design label. Do not accidentally implement discarded portaging as Classic behavior.

## 8. Humans

[Including Humans in the Design](https://www.philipbouchard.com/oregon-trail/including-humans.html)

Named companions make illness and death personal. Shopkeeper advice and conversations at landmarks teach practical and contextual information. Native people appear as knowledgeable participants, including expert river guides. Elaborate bargaining, tense encounters and rewards for donating supplies to other parties were considered but not shipped in this design.

Project consequence: add named party members and original, contextual landmark dialogue alongside the resource systems. Keep the simpler documented trading activity distinct from expanded diplomacy or charity mechanics. Do not carry the early BASIC hostile-rider scenario into the 1985 baseline by assumption.

## 9. A different journey

[A Different Journey to Oregon](https://www.philipbouchard.com/oregon-trail/different-journey.html)

The comparison is with the separate 1991 game Lewis & Clark Stayed Home. It explores different navigation, crew assignments, conversations, bargaining and scoring. It also clarifies Oregon Trail's simpler conversation selection and end-of-journey evaluation. These are comparisons between products, not an Oregon Trail expansion specification.

Project consequence: optional advice can keep setup approachable, but free exploration, assigned crew jobs, negotiated village trade and expedition scoring belong outside our current Classic scope. Use the comparison to understand design tradeoffs rather than treating every pictured feature as Oregon Trail behavior.

## Implementation priorities derived from this reading

These are our engineering decisions, not quotations or claims of completed work:

1. Add departure setup, named party and inventory accounting for the opening store.
2. Replace manual daily travel with Continue/Pause while preserving deterministic daily simulation; automatically stop at events and landmarks.
3. Add a route graph and calendar, then climate/weather, accumulating health effects and individual illness states.
4. Make river conditions and crossing outcomes consume the same daily resource model, including waiting and drying delays.
5. Complete hunting, fort purchases, simple trades, landmark conversations, scoring and the ending routes.
6. Test full Classic journeys before enabling the parked absurd examples.

The existing short slice remains runnable, with provisional numbers explicitly labelled in the ledger. No game behavior changes solely because a retrospective contains a plausible-looking draft formula.
