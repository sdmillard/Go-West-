# Companion foundation

The later [party framework](PARTY_FRAMEWORK.md) adds fractional trust, boundaries, relationship setup, special-trait hooks and explicit mercenary agreements. The text below records the original foundation; its implementation scope and save schema are extended by that document.

This is a deliberately small first pass, before crime or departures. The first named traveler is the player/leader. Their values come from player decisions; no moral personality is assigned to them. Each of the other four travelers has two traits: Cautious or Bold, and Compassionate or Pragmatic. The four companions receive distinct Hunting, Carpentry, Caregiving and Trading backgrounds. Generation is repeatable from the journey seed using a separate local generator; existing weather, illness and event random streams are untouched.

Backgrounds currently describe experience only. They do not modify hunting yield, medicine, repairs, prices or survival odds. Trust is a relationship with the leader, starting at 50 and bounded to 0–100. It is not mood, health, loyalty to another companion, or willingness to participate. Those other systems are not implemented in this pass.

## Existing decisions with reactions

| Decision | Reaction |
| --- | --- |
| Spend a rest day while someone has a current illness or injury | Living Compassionate companions gain 1 trust. |
| Travel at grueling pace while someone has a current illness or injury | Living Cautious or Compassionate companions lose 2 trust. |
| Arrange actual kit or local medical care | The living companion receiving care and living Compassionate companions gain 2 trust. |
| Choose armed defense against hostile bandits/riders | Living Bold companions gain 1 trust; living Cautious companions lose 1. Friendly riders do not count. |

Other personalities do not receive an automatic opposite reaction. Pragmatic companions do not object to care or rest merely to create disagreement. Party health is evaluated before a day's progression, so a recovery that day does not erase the reason for the decision. Reactions occur only for actual actions, not opening menus or rejected offers. The same reaction type cannot change trust more than once per day. Care and rest can each produce a reaction on the same day.

The journal explains reactions and trust changes. View Party shows traits, background, trust and the last twelve concrete memories alongside existing health records. Dead travelers retain their records and stop reacting. A memory records the actual trust change, including a zero change at a trust limit.

## Save compatibility

An additive `characters` collection stores profiles, trust and bounded memories, with validation on load. Saves without this collection receive deterministic starting profiles and neutral trust, with no invented memories or replay of past decisions. Existing health records, supplies and random streams are preserved. Survival JSON rules and their signature are unchanged because this pass adds no survival modifiers.

## Scope boundary and validation

No departures, refusals, family links, interpersonal bonds, ages, needs simulation, autonomous behavior, crimes, crime experience, witness network or cannibalism have been added. No new tuning bonus depends on trust. Those decisions can be made after this foundation is played and reviewed.

The dedicated test suite covers deterministic profiles, distinct backgrounds, actual rest/travel/care/defense reactions, friendly encounters, dead travelers, duplicate prevention, memory limits, trust clamping, exact save round trips, older saves, malformed records and the party screen. Across eight seeds and 35 policy steps each (280 matched steps), enabling characters produces identical survival state, pending offers, individual health and all three existing random streams. This checks noninterference; it is not a new full-journey balance study. Native party screen capture: `companion-personality.png`.
