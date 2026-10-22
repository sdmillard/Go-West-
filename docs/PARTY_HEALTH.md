# Traveling party and personal health

The subsequent survival pass connects weather/exposure, clothing, ration-dependent onset/severity and medical care. See `BASIC_SURVIVAL_BENCHMARK.md` for current behavior. Initial-pass descriptions below are superseded where noted by that record.

The [first balance pass](BALANCE_PASS_01.md) further separates accidents from spontaneous illness, gates automatic cholera onset to 1849+, and gives fed rest 3/5/7 internal recovery points for bare/meager/filling meals. These recovery points are game tuning. Injury events can produce broken arms or legs; food quality no longer chooses impact severity. Explicit test scenarios can still introduce any defined condition regardless of date.

The player can open **View Party** from the wagon ledger. All five travelers remain listed, including those who have died. Each row shows a verbal condition and, when present, an active illness or injury. Selecting a name reveals all active conditions, their onset days and that traveler's history. Long histories scroll. No numeric health meter appears in this view.

Opening the roster pauses travel and crossing animation. Reading or selecting a traveler never consumes time, food or randomness. Closing it leaves travel stopped until the player continues. The roster is available at landmarks, after crossing mishaps and after the journey ends. New Journey closes it and clears the former party.

## Simulation contract

- Each committed departure creates five records with stable numeric identities, names, internal health, living/dead state, active conditions and personal history. Duplicate names do not merge people. `state.party` retains the original name list for compatibility; `party_health.members` owns personal health state.
- The party-wide condition derives from the rounded mean health of survivors. It is a summary, not a substitute for personal diagnoses. A traveler can have an injury while still rated GOOD. The current category boundaries remain provisional: 80/50/20.
- Nutrition, pace, rest and crossing damage affect the health of each living member. Illness/injury progression affects the individual who has that condition. Crossing injuries also enter personal history.
- Health notices stop ordinary automatic travel and identify the affected person. Onset, recovery and deaths enter both the personal record and the trail journal. Acknowledgement spends no extra day. Multiple notices on one day are grouped. At a landmark they may wait until leaving that stop; the roster and journal already show them.
- A person's health reaching zero records death day and cause. Rest cannot revive them. Other survivors continue; food demand uses the living count starting on subsequent days. This prototype allows survivors to continue even if the first named traveler dies. The journey ends when none remain. This continuation policy is our choice, not verified leader-death behavior from a particular classic executable.
- `state.health` is a derived summary for player journeys; do not edit it to change an individual's health. The old direct-constructor short-leg test fixture retains its aggregate-only model.
- Health progression uses a separate random stream seeded from the journey seed. No UI actions draw from either random stream. The JSON file is validated before departure; invalid definitions fail rather than silently removing health rules.

## Data and limitations

`data/health_conditions.json` defines dysentery, cholera, typhoid fever, measles, exhaustion, broken arms, broken legs, snakebite and wounds. A provisional 3% base party-level onset roll per elapsed day is modified by rations, rest and exposure; it selects a living person without a current condition. Explicit events can add another condition. Rest advances recovery twice as quickly; recovery removes the condition without resetting accumulated health loss. Mild/bad/serious severity multiplies daily strain. Its conditional roll follows BASIC's ration branch; applying it to named conditions is our adaptation. Care can reduce severity.

**These daily odds, strain values, recovery durations, care effects and category thresholds are original game tuning.** They are neither recovered 1985 algorithms nor medically/historically validated disease models. No claim is made that illness or fractures follow these durations in life. Weather exposure and unsafe-water encounters now have effects, but historical transmission, continuous water supplies, contagion and authentic period treatment remain unmodeled. Daily ration/rest/speed tuning remains provisional.

The evidence for cumulative party condition alongside named personal illness/injury and death comes from Bouchard's [design account](https://www.philipbouchard.com/oregon-trail/imagining-design.html) and [account of human characters](https://www.philipbouchard.com/oregon-trail/including-humans.html). These explain the design but do not supply exact probability or recovery formulas. The original BASIC routine remains a separate reference; it does not establish these named conditions or individual records.

## Verification

`tests/test_health.gd` checks JSON rejection, independent named health, distinct identities despite duplicate names, onset and recovery history, fatal illness, irreversible death, survivor food demand, no-survivor loss, deterministic replay, automatic interruption, acknowledgements, roster selection, modal pause and restart cleanup. Rendered capture uses deliberately injected cases to show a healthy traveler, injuries, illness and a deceased member together; this is a UI test fixture, not a recorded natural run. Other suites retain route, crossing, store and legacy regression coverage.
