# Classic mechanics audit — October 22, 2026

**Snapshot before the individual-party implementation.** The later [party-health pass](PARTY_HEALTH.md) implements named health state, illnesses/injuries, recovery, deaths, survivor ration accounting and an inspectable roster. Its tuning is provisional. The gap descriptions below preserve the state when this audit was made; they are not the current health feature list.

The subsequent [BASIC survival benchmark](BASIC_SURVIVAL_BENCHMARK.md) records the weather, hunting, team, supplies, care and repeatable-event implementation at the earlier Platte milestone. The route now reaches Oregon City; use the [full-trail mechanics and balance report](FULL_TRAIL_BALANCE.md) for the latest coverage, experiments and remaining limits.

Scope: inspected the complete downloaded 1978 BASIC transcription, cross-checked the 1975 transcription, and compared them with the current engine, JSON events, interface, 1985 booklet and Bouchard's design account. This is a source inspection, not an executed BASIC playthrough or a claim to have recovered the 1985 algorithms. BASIC references below are program line labels, not text-editor line numbers.

## Health: the most important gap

Our current engine has one persistent 0–100 party-health value. Rations, pace, rest, hunger and crossing damage change it; zero ends the entire journey. Names are strings, `party_size` remains five, and no member can independently become sick, recover or die. There are no disease, injury, treatment, recovery or cause-of-death records. Buying clothing currently has no health consequence.

That is only a prototype. The desired classic presentation is a **party condition in words**, plus events concerning named people, rather than visible hit points. Our 1993 reference run already showed categorical health (`REFERENCE_PLAYTEST_1993.md`); the 1985 booklet's travel screenshot and scoring table likewise use verbal health categories. Internal numbers can support the model without becoming a conventional player-facing health meter.

Bouchard describes cumulative party health alongside individual illnesses and injuries, influenced by weather, rations and pace. He lists named diseases/symptoms including dysentery and cholera. His account of human characters confirms that sickness and deaths identify the affected companion. These establish behavior, not numeric probabilities or recovery formulas. [Design account](https://www.philipbouchard.com/oregon-trail/imagining-design.html), [human characters](https://www.philipbouchard.com/oregon-trail/including-humans.html).

The BASIC model is different:

| Mechanic | 1978 BASIC evidence | What it does |
| --- | --- | --- |
| Persistent state | 820, 1920–1980, 6480–6790 | Tracks injury `K8`, illness `S4`, supplies and cash; no ongoing health-points variable or individual member records. |
| Illness severity | 6300–6440 | Mild costs 2 miscellaneous-supply units and 5 miles; bad costs 5 units and 5 miles; serious costs 10 units and sets a medical-attention flag. Negative medical stock is fatal. These are expenditure units, not pounds or modern medicine doses. |
| Nutrition affects illness | 4610–4660, 6300–6360 | Eating choice affects both entry into the illness routine and its severity. Cold exposure can also enter the routine. |
| Doctor bill | 1920–1980, 5080–5160 | An injury or serious-illness flag triggers a $20 bill at the next turn. Insufficient cash ends the game. Successful payment clears both flags. |
| Broken limb | 3740–3780 | Daughter breaks an **arm**; costs distance and supplies for a sling. This is not a tracked broken-leg condition. |
| Other injuries | 3170–3210, 4030–4080 | Knife/gunshot injuries set the injury flag. |
| Animal injury | 3700–3730 | An **ox** injures a leg, reduces animal quality and slows subsequent travel. |
| Named disease | 5060–5160, 6290–6460 | No dysentery or cholera in either inspected BASIC listing. Fatal illness is generally reported as pneumonia; injury deaths are separate. |
| Other deaths | 1690–1710, 3500–3530, 4220–4260, 4340–4390, 5060–5170 | Winter deadline, attacks, snakebite without supplies, starvation, unaffordable doctor and depleted medical supplies can end the run. |

For illustration only, algebraic interpretation of 6300–6360 gives the following severity distribution **conditional on entering the illness routine**, assuming independent uniform draws: poor eating = 10% mild / 54% bad / 36% serious; moderate = 45% / 49.5% / 5.5%; well = 80% / 19.5% / 0.5%. These are not daily disease odds, later-game formulas, or historical fatality rates. No such probabilities have been added to our engine.

## Every primary BASIC event branch

The selector at 3550–3650 uses thresholds `6,11,13,15,17,22,32,35,37,42,44,54,64,69,95`, then a final default branch. The percentages below are interval widths under a uniform draw, before conditional branches. Riders are an additional separate encounter, not part of this table. Events repeat in BASIC; our current authored encounters normally enter `seen` once.

| Branch / share | BASIC labels | Behavior | Current game |
| --- | --- | --- | --- |
| Wagon breakdown / 6% | 3660–3690 | Repair supplies and reduced progress. | Partial: one scheduled muddy-wheel event; no recurring damage system. |
| Ox injured / 5% | 3700–3730 | Immediate delay and persistent animal-quality reduction. | Missing; ox count does not affect speed or fatigue. |
| Daughter's broken arm / 2% | 3740–3780 | Sling supplies and delay. | Missing individual injuries. |
| Wandering ox / 2% | 3790–3810 | Search delays travel. | Missing. |
| Lost child / 2% | 3820–3840 | Search delays travel. | Missing. |
| Unsafe water / 5% | 3850–3870 | Delay seeking a clean spring. | Missing water/contamination system. |
| Heavy rain or western cold / 10% | 3880–3940, 4490–4550 | Rain damages food, ammunition and supplies; beyond mile 950, clothing can determine illness. | Missing weather and clothing effects. Mud story is not weather simulation. |
| Bandits / 3% | 3950–4080 | Shooting, cash/ammunition/animal losses, injury. | Missing; not automatically a desired historical feature. Transcription control-flow problems noted below. |
| Wagon fire / 2% | 4120–4170 | Food, ammunition, supplies and progress lost. | Missing. |
| Fog / 5% | 4180–4200 | Lost progress. | Observed in the 1993 game; missing here. |
| Snakebite / 2% | 4210–4270 | Ammunition and medicine consumed; insufficient medicine is fatal. | Missing; do not treat its medical abstraction as historical treatment evidence. |
| Swamped wagon / 10% | 4280–4320 | Food and clothing loss, delay. | Partial: interactive river choices and animated, dated mishap records; current losses are food and shared health, not clothing. |
| Wild animals / 10% | 4330–4470 | Shooting, ammunition/food/clothing loss, possible fatal injury. | Missing; needs historical review rather than automatic adoption. |
| Hail / 5% | 4560–4600 | Ammunition/supplies and progress lost. | Missing. |
| Illness eligibility / 26% | 4610–4660 | Enters illness routine always if eating poorly, with 75% chance moderately, 50% well. | Missing. |
| Assistance / 5% | 4670–4690 | Adds 14 food-expenditure units. | Missing; future encounters should identify people and context using researched sources. |

## Other BASIC systems and current coverage

| System | BASIC labels | Coverage / gap |
| --- | --- | --- |
| Outfitting and budget | 800–1190 | Implemented with later-style typed inventory and profession budgets. BASIC instead starts with $700 after wagon purchase, buys animal quality for $200–300, and converts $1 to 50 bullets. Do not merge editions' prices. |
| Time and seasons | 1200–1720 | BASIC uses fixed two-week turns from March 29, 1847 and a winter deadline. We use daily time in 1848; no weather or winter model. Keep daily time. |
| Progress | 2860, 3700–3730 | BASIC uses roughly 200 miles/turn plus ox investment and randomness; many delays subtract miles. Our 12/18/24 daily pace model does not respond to ox condition, load or terrain. Do not copy negative-mile delays into a landmark route. |
| Fort resupply | 2060–2510 | BASIC alternates fort availability, charges cash for reduced-value stock (two-thirds of starting purchasing power), and reduces progress by 45 miles. We have an opening store only; no en-route economy or restocking. |
| Hunting | 2530–2710 | Requires at least 40 bullets; consumes travel progress; shooting performance affects food and ammunition. Missing entirely. Our bullets currently have no survival use. |
| Rations and hunger | 2720–2850 | Three eating levels consume 13/18/23 food-expenditure units per turn; too little for even poor eating ends the run. Our pounds/person/day and gradual hunger damage are different provisional rules. |
| Riders and tactics | 2880–3530 | Run, attack, continue or circle; apparent intentions can mislead; outcomes depend on shooting/resources. Missing, but not a requirement to restore: Bouchard explicitly removed hostile riders in 1985. |
| Shooting skill | 710–790, 6130–6280 | Skill selection and timed typing; wrong word penalizes performance. Missing. A mouse-driven hunting design should replace terminal typing. |
| Mountain travel | 4710–5040 | Terrain delays, getting lost, wagon damage, South Pass/Blue Mountains flags, snow, supply loss and clothing checks. Missing; chapter currently ends before the mountains. |
| Resource coupling | 1750–1980 and event routines | Medicine/repairs share miscellaneous stock; ammunition, clothing, ox quality and cash matter repeatedly. Our food and spares have some uses; clothing and bullets are inventory-only, oxen matter only to departure validation, and medicine is absent. |
| Loss conclusion | 5050–5410 | Cause-specific death and a funeral/notification dialogue. We have a generic journey-ended panel plus specific crossing history; no personal death record or epitaph. |
| Full arrival | 5420–6120 | Oregon City after 2,040 miles, fractional final turn, refunded unused rations, final inventory/date. We have only the researched opening corridor to the Platte and whole-day stop accounting. |
| Replay and scoring | Whole listing | BASIC has no points, persistent graves or high-score list. Those later features are missing here, but must not be attributed to BASIC. |

## Later classic features BASIC cannot establish

Use the 1985 booklet and Bouchard's account for these; exact executable behavior still needs verification:

- Individual companion illness, injury, survival, recovery events and named deaths; categorical party condition.
- Daily weather tied to month/location, with consequences for health and river conditions.
- Geographic route choices, landmark activities, conversations, and contextual guidance.
- Graphical hunting, regional animals, and meat carry limits.
- Trading, en-route purchases and replacement oxen; repeated part failures and repairs.
- Later river methods/conditions and the Columbia rafting conclusion.
- Survivor/resource scoring, profession multipliers, high scores, and persistent epitaphs.
- Period music. Our original graphics and mouse interface are deliberate presentation choices.

Opening purchases, names, three professions, Continue/Pause, rations, pace, rest, a single researched route segment, illustrated stops and river choices exist, but their presence does not establish complete classic fidelity. The current event list contains one player-route historical-style non-river event: the day-two wheel problem. Rare absurd examples remain parked.

## Implementation order resulting from this audit

1. **People and health:** show verbal condition; give each named member a stable identity, living/dead state and condition history. Track illness/injury onset, persistence, recovery/worsening and named death events. Keep party condition distinct from individual diagnoses. Adjust food demand for survivors and define who can continue after a death. Do not claim the designer's diary supplies exact thresholds or mortality formulas.
2. **Daily environment:** weather, season, clean water and exposure; connect these to health, livestock and river stage. Research period context before choosing disease occurrence/treatment rules.
3. **Survival resources:** hunting/food replenishment, usable ammunition, livestock condition, clothing protection, repairs and en-route purchases/trades.
4. **Repeatable events:** conditions and cooldowns instead of the single-use `seen` mechanism for all events. Record consequences and stop travel for meaningful personal events, as crossing mishaps already do.
5. **Journey completion:** remaining researched route, terrain/branches, final travel choices, graves and scoring.

Historical accuracy remains the user's priority. This is a coverage checklist, not a request to reproduce every combat trope, fictional medical rule, numerical probability or transcription defect.

## Source reliability and validation

Local source hashes match `research/SOURCES.json`:

- 1978: `57d631dd1feed37815e4340faf8ee73102511040a7dab9913e090dd235e74b0f`.
- 1975: `73cf15422fcc866244f84a791d13275657eadbed25718b9ef8c099c2c4762bc3`.

The [reference repository](https://github.com/fortran-gaming/oregon-trail-1975) supplies adapted transcriptions, not the 1985 source. The 1978 header and repository README disagree on the magazine issue. Several details require checking against the magazine before implementing exact formulas:

- 1978 line 4720 has a malformed mountain conditional; the 1975 version has an explicit comparison at 3105.
- The 1978 selector enters the bandit routine at 3960, skipping its title; flow at 3980/4020 bypasses a shooting-success test. The 1975 routine has a corresponding test at 2735.
- Several 1978 event titles are skipped by selector targets; snakebite flow can fall through into a fording title without applying fording losses. Do not confuse displayed prose with executed effects.
- The downloaded 1975 shooting subroutine (4500–4535) is a modified stub, not an authentic timing implementation. Its arrival check at 700 also allows a turn-count shortcut, unlike 1978's distance test. It is a cross-reference, not an unquestioned executable standard.

No disease or personal-death system was silently added by this audit. A presentation correction replaces visible 0–100 health with provisional verbal bands; underlying mechanics remain incomplete. Exact category thresholds are new design until verified against the selected classic executable. Passing the current tests cannot establish missing health mechanics or historical truth.
