# Creation specials and one optional flaw

The later [expanded catalog](CHARACTER_CATALOG.md) adds twelve flaw choices and sixteen specials while retaining the two-plus-one creation rule. The two original flaws below remain supported.

Each companion may start with **two specials**, or **three by taking one flaw**. Zero or one flaw is allowed. The leader's identity remains defined by the player's decisions. Temperament, values, background and relationship do not consume special slots.

Mercenary counts as a special, so Loyal + Mercenary uses the normal allowance. Loyal + Mercenary + Veteran requires a flaw. No new companion can select all four specials. Flaws do not lower wages directly; selected background/personality/special premiums continue to determine an acceptable agreement.

The initial flaws are authored gameplay tradeoffs:

| Flaw | Individual effect |
| --- | --- |
| Frail | All negative health changes are multiplied by 1.25 and rounded up in magnitude. This includes illness, hunger, exposure and injuries. A loss of 4 becomes 5; a loss of 1 becomes 2. |
| Slow Healer | Positive health changes from rest, care and other sources are halved and rounded down, with a minimum positive gain of 1. A gain of 6 becomes 3. Condition recovery timers remain unchanged. |

The modifiers apply only to the affected companion, through the shared health-change function. Departed and dead travelers receive no changes. The party screen explains the selected flaw beside their specials. These are initial balancing values, not historical medical claims or a completed survival balance study.

The editor shows the optional flaw, its consequences and the current special count. At the limit, unused specials are disabled; chosen ones remain removable. Removing a special frees a slot. Removing the flaw is blocked while its third slot is in use, so the player must choose which extra special to drop. Changing the flaw to the other available flaw is allowed during preparation. Companion switching, store/back navigation and new-journey reset retain or clear the proper independent draft.

The engine independently rejects over-budget creation, extra/unknown/duplicate/malformed flaws and leader flaws before spending resources. Flaws are an optional validated character field; older saves without it mean no flaw. Health references the restored character roster, so no duplicate health-only flaw field can drift out of sync. Existing saved characters keep their valid specials even if they exceed the new **creation** allowance. No trait acquisition or flaw removal during travel is implemented.

Validation: 28 party-setup checks and 27 dedicated flaw checks pass, alongside the full regression suite. Coverage includes actual editor interactions, direct departure validation, effects on personal health, round-trip saves and effects after restore. `party-flaws.png` was rendered and visually inspected at native resolution.

Earlier specialist/economy reports predate this creation rule. The optional `tests/specialist_balance.gd` now writes `flaw-budget-balance.json` and adds Slow Healer to its paid Loyal/Veteran cohort to fund the third special; that additional flaw makes it a different experiment from the archived reports. No new 540-journey balance run is claimed for this feature.

