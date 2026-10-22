# Customize the party before departure

The preparation screen keeps names, profession and departure month on the left. The right panel selects one of the four companions and edits temperament, values, background, relationship to the leader and special traits. Scroll within the panel to reach specials and wage terms. The leader remains the first named traveler; player decisions define their values.

Choose from eight temperaments, eight value systems, four existing backgrounds and thirteen relationships to the leader. The [full catalog](CHARACTER_CATALOG.md) documents each effect, starting trust and attachment. Generate a Companion can create an independent draft and wage offer for the selected traveler. Values determine the initial forbidden-action boundaries as described in PARTY_FRAMEWORK.md. Starting profiles carry no fictional memories or prior debt. [Background benefits and Veteran's combat reduction](BACKGROUND_BENEFITS.md) now apply when a companion is fit enough to help. Hovering backgrounds/specials explains their effects and limitations.

Choose up to two of sixteen specials per companion. One optional flaw grants exactly one additional slot, for a maximum of three specials. See [creation limits and flaws](PARTY_FLAWS.md). Mercenary enables an explicit dollar wage and interval of 1–7 days. New agreements require the companion's individual daily quote times the payment interval. The quote is shown with its breakdown and updates when background, values or specials change. Both direct contract creation and simulation departure reject unacceptable offers. Previously saved agreements are honored as written. Wages are not charged at the store: the first bill comes due after the selected number of journey days. Subsequent payment, debt and trust rules use the existing framework and View Party payment button.

## Historically scaled wage demands

See [the wage and purchasing-power audit](HISTORICAL_ECONOMY.md) for sources, limitations and matched journeys. Cash bases per journey day are Hunting 40¢, Carpentry 90¢, Caregiving 50¢ and Trading 60¢. Compassionate subtracts 5¢, Pragmatic adds 5¢, Loyal adds 10¢ and Veteran adds 20¢. The daily cash figure assumes party food; the editor also shows its 30-day equivalent. Minimum selectable quotes range from 35¢ to $1.25/day. These are historically scaled game agreements, not documented wages for each trait.

The initial offer defaults to a week at that character's minimum. Caregiving + Compassionate + Loyal quotes 55¢/day, or $2.75 every five days. Cannibal, Cautious/Bold and relationships do not change quotes. Existing agreements remain fixed; lowering a quote in setup preserves any higher offer until the player lowers it. The exact cash and interval rules and benefits remain as described above.

Switching companions or visiting/backtracking from the store preserves every draft and the supply cart. Draft editing spends no cash or time and consumes no simulation random rolls. Departure validates the entire customization and purchase before committing; invalid profiles or terms cannot charge supplies. Committed profiles are independent copies, survive save/load and remain fixed for that journey. New Journey resets the drafts.

The existing four-argument simulation departure API remains compatible; an optional fifth customization dictionary accepts validated profiles and mercenary terms. The store now shows the average weekly wage commitment and first due day before purchase. [Companion consequences](COMPANION_CONSEQUENCES.md) extend this with refusal, warned settlement departures and a compatible schema update. Recruitment during travel, editable crime preferences, changing family relationships during a journey and betrayal execution remain deferred.

The dedicated setup suite exercises actual companion switching, store/back navigation, draft isolation, family/friend trust, exact wage cents, atomic rejection, actual departure, save/load and New Journey reset. Native screen capture: `party-customization.png`.



