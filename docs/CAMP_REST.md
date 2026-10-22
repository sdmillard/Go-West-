# Choosing camp rest duration

Click **Camp**, type a whole number from **1 to 30**, then click **Rest** or press Enter. Cancel spends no time or supplies. The **Rest here** choice at a landmark opens the same prompt; resting preserves the stop's choices.

The prompt quotes meals using the living party size and current ration setting. This is a meal estimate, not a guarantee: fresh food can spoil, and daily events can change the party or its supplies.

Each day runs the existing simulation independently, including meals, spoilage, weather, recovery, illness, deaths and team recovery. The wagon stays in place. Rest stops early for an encounter, new party health news, a death, the end of the journey, or a newly triggered food warning. The report and journal record the actual days completed out of those requested. Acknowledging a food warning allows the player to make a new rest decision; it does not automatically resume the interrupted plan.

No advance rest plan is stored in saves. Confirmation resolves the selected days immediately, stopping at the first interruption. Existing saves and daily rest rules are unchanged. Thirty days is an interface limit for one decision, not a historical claim or a restriction on total rest over a journey.

`tests/test_camp_rest.gd` checks the real input and confirmation path, invalid values, cancellation, dialog bounds, ordinary-day equivalence including random state, food interruption, historical events, landmark rest, individual and whole-party deaths, and refusal to rest through unresolved events. The full regression suite also exercises the updated camp interaction. Original native screenshots: `camp-rest.png` and `camp-rest-result.png`.
