# Companion relationships

October 23, 2026. This is a bounded first social layer, with authored gameplay rates rather than a historical relationship model. It covers the four adult companions; the existing relationship and trust toward the player remain separate.

## Before departure

Select **PARTY RELATIONSHIPS** beside Enter the Store. Each of the six companion pairs can start unrelated, family, friends, partners/spouses or rivals. The screen shows the same seeded starting bonds the journey would otherwise generate. Explicitly choosing all unrelated is preserved. Changing names does not reassign the pairs. Each companion can have only one partner, including a declared partner relationship with the leader. **Allow new romances on the trail** can be disabled without deleting existing partnerships.

EDIT still controls each companion's relationship with the leader, temperament, values, background, traits and wages. The peer editor and character sheet close each other; entering the store retains the complete draft. Invalid setups are rejected before committing supplies or random state.

## During the journey

Every seven days active pairs have a small social update. Starting bonds set initial closeness; compatible values usually improve it, opposed values strain it, and hunger or resting with illness can affect it. This first model samples conditions on the update day, rather than simulating individual conversations or accumulating every meal over the week. A separate date-keyed seeded stream leaves existing travel, disease and crime random streams alone.

Closeness can create friendship or rivalry, repair a rivalry, weaken a friendship, or lead close unpaired companions to fall in love. Severe sustained conflict can separate partners. Family remains family even when relations sour. Existing partners and known family connections are excluded from new romance. A survivor can form a new partnership after a former partner dies or leaves, retaining a record of the old relationship. No age, orientation, attraction preferences, affairs, marriages, children or recruitment mechanics are added here.

View Party shows each companion's feelings toward the others and a recent social memory. Major transitions are announced and recorded in the dated journal; each pair retains eight recent memories in saves.

## Departures

Extreme hostility toward an active companion can produce the same advance warning and settlement departure review as lost trust or unpaid wages. Existing settlement/notice restrictions still apply. Active partners appear together in a departure plan, even when only one independently wants to leave. The review explicitly warns about the additional departure and shows both people's belongings. Canceling spends no time and leaves them present; resolving the underlying cause before confirmation removes that reason to leave. Dead or absent partners do not join a departure.

This joint-planning rule covers warned settlement departures. Immediate flight after violence and betrayal retain their existing safety/consequence rules; a spouse can flee a threatening incident without being forced to take a murderer along. Leader relationships still use the existing trust/attachment model.

## Saves and tests

Social state is separate from the existing sparse bonds used by combat and witnesses. Save validation checks all six pair ids, bounded closeness, dated memories and the romance preference. Pre-update saves preserve their exact existing bonds and initialize feelings from those bonds on the load day, without inventing past social events. The previous master rules fingerprint migrates without repricing supplies.

Tests cover setup/UI, invalid bonds, duplicate partners, unchanged inspection/RNG, deterministic updates, friendship, romance, rivalry, separation, kinship and existing partnerships, bereavement, joint departure review/cancellation/supply transfers, persistence and malformed data. Social rates and their effect on survival require the later combined balance campaign.
