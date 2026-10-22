# Personality, relationships, specials and wages

This extends the small companion foundation without adding crime encounters, recruitment, departures or autonomous betrayal. Specials, family ties and wage agreements are explicit choices, not randomly imposed on an existing party. The later [departure customization screen](PARTY_SETUP.md) exposes them before setting out. Hiring during the journey remains deferred.

The later [companion consequences](COMPANION_CONSEQUENCES.md) implement refusal, warned settlement departures and character schema 3. The original framework below is extended by those rules.

## Trust and boundaries

Trust now supports half points, including in saves, journal entries and the party screen. **Loyal** halves ordinary negative trust changes. Positive changes are unchanged. Forbidden actions bypass the reduction, even when high trust makes the companion reluctantly willing. Trust remains bounded to 0–100; memories record the actual change after clamping. Duplicate reactions of the same kind on the same day remain suppressed.

Profiles contain three disjoint action lists: approved, disapproved and forbidden. The initial supported framework actions are robbery, murder, cannibalism and missed wages. Compassionate companions initially forbid robbery, murder and cannibalism; Pragmatic companions initially forbid murder. These are authored character rules, not historical findings. Existing care/rest/defense reactions remain as documented in PARTY_CHARACTERS.md.

The pure `response(index, action)` query returns neutral, approved, disapproved, forbidden, or reluctant. A forbidden action is reluctantly acceptable at trust 80 by default. `react_to_action` is for an action that actually happened: approved gives +2, disapproved −2, and forbidden/reluctant −12. No criminal act is implemented or executed by querying this framework. A future encounter must use the query to implement participation/refusal and call the reaction hook only for the actual decision.

The default breaking threshold is 20. Betrayal requires an explicit `can_betray` capacity and trust at or below 10; low trust alone never creates that capacity. These currently produce informational warnings only. No one departs, betrays or removes supplies in this pass.

## Relationships and specials

- Fellow traveler: starting trust 50.
- Friend: starting trust 60; breaking/betrayal thresholds are reduced by 5.
- Family: starting trust 70; those thresholds are reduced by 10, giving greater attachment.
- The player is the first traveler, with the self relationship and no assigned moral traits.

`set_relationship` is a setup hook: it works only on day zero before memories or a contract exist. It cannot refill trust during the journey. Relationships currently describe a companion's relationship to the leader, not a complete network among every traveler.

Supported special identifiers are Loyal, Mercenary, Veteran and Cannibal. Loyal has the trust effect above. Mercenary enables an explicit wage agreement. Cannibal removes only that person's cannibalism objection in the framework; other companions still react independently, and no public reputation is altered. Veteran now supplies the bounded combat reduction documented in BACKGROUND_BENEFITS.md. Skill progression remains deferred. No cannibalism activity or food yield is added.

## Mercenary contract

An explicit `start_contract(game, index, wage_cents, interval_days)` agreement defines wages and an interval. There is no default price or historical wage claim. Agreement itself charges nothing; the first bill is due after the agreed interval. The active contract cannot be overwritten to erase debt. Currency is tracked in integer cents.

The later departure editor introduces an individual daily wage quote based on background, personality and selected specials, with a maximum seven-day payment interval. The offer must meet that quote in both the editor and `start_contract`. Previously saved agreements retain their original terms. See PARTY_SETUP.md for the provisional contributions; no skill progression has been added.

On a due day the full installment becomes owed, and the journal explains it. Automatic travel and a multi-day camp rest stop when a new bill appears. View Party shows the terms and debt and offers **Pay wages owed**. The entire due day is available to pay: a missed-payment penalty applies when another ordinary day passes with any balance outstanding.

- Every seven on-time paid contract days: +2 trust, independent of payment frequency.
- First missed installment: −2 trust.
- Later missed installments: −4 trust.
- Full overdue settlement: +1 trust at most once per seven days, retaining the record of previous misses.
- Partial payments reduce debt/cash but grant no trust reward until the balance is fully cleared.

Loyal halves those negative wage penalties while preserving the full debt. If missed wages are explicitly a forbidden action for that person, the penalty is full strength. Payments cannot exceed debt, create negative cash, count twice, or act as advance gifts for trust. Settlement takes no extra day and remains available to surviving companions after arrival. Dead companions stop accruing new wages; existing records are retained. Contract expiry, renegotiation, dismissal and consequences beyond trust are deferred.

## Compatibility and tests

Character schema version 2 validates specials, relationships, noncontradictory boundaries, ordered thresholds, half-point trust/memories and contract fields. Earlier character records are validated using their original schema, then upgraded without changing existing trust/memories or inventing relationships, specials or debts. Saves predating characters still receive neutral profiles. Stripping the schema tag from a current framework record does not silently reset progress. Survival JSON fingerprints and existing random streams are unchanged.

The dedicated framework suite covers Loyal fractions and forbidden exceptions, pure previews, thresholds, relationship setup, individual special exceptions, on-time/late/partial/unaffordable payments, repeated checks, overdue round trips, older saves, malformed records, actual wage UI, due-date interruption and final settlement. The earlier 315 character checks continue to cover basic reactions and matched survival steps. Native integration capture: `party-framework.png`. This is framework validation, not a new full-journey balance study with mercenary parties.

