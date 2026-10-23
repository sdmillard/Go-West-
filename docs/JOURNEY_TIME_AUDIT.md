# Journey-policy stall and elapsed-day audit

October 22, 2026. Follow-up to [food costs and survival](HISTORICAL_COST_AND_SURVIVAL_AUDIT.md). No game prices, rates, supplies or save rules change in this pass. The five-cent food decision remains in place. The changes are to the automated journey policy and its measurements.

## The capped baseline was a menu loop

The archived six-cent diagnostic had one action-limit outcome: farmer, April departure, four oxen, drying, seed0. It reached the Barlow toll at mile 1848 with five people, $3.30 and 39 food units on day 244. Its reported 2,113 trades did not represent 2,113 real sales.

The fundraising policy assumed fixed menu positions were sales. When no trader was available, position 1 was actually **Back to the trail**. The policy chose it, reported a trade and opened the same menu again without advancing time. This was a study-policy defect; it did not prove the player was unable to continue.

The shared policy now examines effects and requirements before selling. Cash must increase and a real good must leave inventory. If no trader is present, the policy chooses the actual wait action, consuming a day and meals. A refusal or no saleable goods is reported as a policy block. Back is never a trade. The regression covers absent traders on the original date, a real sale, and inability to sell anything.

An [explicit replay of the former setup](historical-policy-cap-replay.json) uses the former six-cent *departure quote only*, with the current policy. It advances through six real waiting days instead of looping, makes 10 actual sales over the journey, and loses the party to starvation on day 254. A wait can have a genuine survival cost. This result fixes the simulation's accounting; it does not turn a cash/food crisis into a free escape or establish that a human could not do better. The replay script records its setup override, rather than attributing it to the current live price.

## Current-rules diagnostic and time budget

[Diagnostic 03](historical-diagnostic-03.json) repeats the 108 five-cent setups from diagnostic 02 with the corrected policy and detailed elapsed-day categories. It has 99 arrivals, seven losses and two year-limit outcomes, with no selected invariant/setup/save/policy errors and no changed arrival/survivor outcomes versus diagnostic 02. The original six-cent capped case is outside this current-price sample; it is checked separately above.

Every elapsed day is assigned to its originating action, and the category totals reconcile to the final date for every run. Multi-day encounter consequences are included in that encounter. This measures time charged by an action; it is not a claim about what travelers did during every hour of the day. Consecutive menu actions that fail to advance time or distance now trip an explicit guard after 33 actions instead of being silently counted as a long journey.

Farmer means, twelve runs per method, including losses and year limits:

| Strategy | Total days | Moving days | Explicit rest | Hunting | Preservation | Trades | Encounter consequences |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| No hunting | 187.2 | 130.2 | 23.0 | 0 | 0 | 4.3 | 15.6 |
| Drying | 243.6 | 134.7 | 39.4 | 20.2 | 10.5 | 4.3 | 20.0 |
| Salt strategy | 237.0 | 135.2 | 36.5 | 18.1 | 10.2 | 4.6 | 17.8 |

Other days belong to crossings, stop work and related choices. The complete per-action totals, processing batch sizes, regular snapshots and landmark dates are in the raw archive. Rest here means explicit rest actions; other non-travel work can also help livestock recover. These policies and surviving parties diverge, so the differences between rows are not isolated causal effects of preservation.

Across the sample, 248 preservation batches were processed. Only eight were smaller than30 food units. Average farmer batch sizes were 64.0 units for drying and 64.8 for the salt strategy. Making tiny batches free would therefore address little of this particular policy's overhead. The 30-unit boundary is an analytical cutoff, not a proposed historical rule.

## Decision and next investigation

Retain the current processing-day and movement rules for now. The stronger leads are how the policy chooses rest, when it uses care, and how hunting effort interacts with illness, cash shortages and late-season exposure. Increasing travel speed or removing processing costs before isolating those factors would hide the cause of the long journeys.

Meat value versus physical weight remains an explicit abstraction to investigate separately. This pass does not certify nutrition equivalence or introduce a new nutrition system. Hard outcomes remain legitimate when resources, timing and consequences explain them.

## Validation and reproduction

- All 30 suites in `test.ps1` passed, including 10 new journey-policy regression checks.
- Diagnostic 03 has 108 rows, no selected errors, unchanged live-rule fingerprint, matched setup keys and exact elapsed-day reconciliation.
- The former capped setup terminates with a real survival outcome instead of an action-limit loop.
- New scripts include Godot UID files. Existing art work and real player saves were untouched.

Use the isolated APPDATA convention in `test.ps1`. For another diagnostic archive, run Godot headless with `--script tests/historical_diagnostic.gd -- --label=historical-diagnostic-04`. Existing labels are refused. `tests/replay_policy_cap.gd` reproduces the special former-price setup and also refuses to overwrite its archive; preserve that report before a deliberate rerun. Old reports remain records of their earlier policy and rules.

The [rest and care decision study](REST_AND_CARE_AUDIT.md) now separates health, animal-condition and fatigue triggers and compares four study policies without changing live recovery rules.
