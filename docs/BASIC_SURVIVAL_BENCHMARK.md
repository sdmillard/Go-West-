# BASIC survival benchmark — October 22, 2026

**Full-route update:** [Route expansion](ROUTE_EXPANSION.md) now connects Oregon City and supersedes the opening-only movement tuning below. Archived chapter outcomes remain useful snapshots, not whole-trail predictions.

**Current food/load update:** see [Food and survival baseline](FOOD_AND_SURVIVAL.md) for the 800 lb suggested outfit, total cargo, variable hunting yields and fresh-meat spoilage. Earlier balance numbers below are archived observations.

This records the initial foundation pass. The subsequent [source-grounded balance pass](BALANCE_PASS_01.md) updates nominal paces, rest/ration recovery, injury onset and cholera chronology, with raw before/after experiments. Use that record for those newer values.

The implementation order is now: establish the survival mechanics in the existing opening chapter, tune them together, then extend the researched route to Oregon. The playable road still ends at the Platte corridor, 317 reported guide miles. This pass adds functional counterparts of BASIC's survival systems; it does not claim numerical or presentation parity with an original executable.

## What can be played

**Options** opens hunting, trading and care. It is available in camp and at unresolved landmarks; hunting is available only between landmarks. Activities stop automatic travel. Buying, selling, bartering and giving care have explicit costs, consume one day of rations per transaction and return to the unresolved stop when appropriate. Backing out costs nothing. A scrolling service window keeps offers readable and its Back to Trail control stays available.

**Hunting** now uses habitat-dependent encounters, original pixel animals, a movable hunter, cover, fleeing game and reloading. Left-click fires; right-click walks. Outings cost one day and up to five bullets; zero-game outings are possible. At most 100 lb returns. Current bison/deer/cottontail usable-food ranges are 200–450/42–85/1–2 lb before carrying limits, with source context and explicit tuning limits. See [hunting mechanics and evidence](HUNTING.md) for source limits and balance results. This replaces the earlier fixed 70/40/10 lb targets. Returning twice cannot duplicate meat or time. Mouse aiming replaces BASIC's timed typing.

**Weather** changes each elapsed day, including waiting, care and transactions. Clear weather, rain, heavy rain, fog, hail, cold and blizzard affect progress or exposure. Rain, hail, snow and fog also appear over the original landscape. Monthly cold chances and a mountain modifier provide seasonal/terrain variation; these are authored scenarios, not an authenticated 1848 climate reconstruction. Recent wet ground influences river stages; waiting can change stage/risk through weather without granting a free stage reroll.

**Clothing, oxen and load now matter.** Insufficient clothing exposes living individuals to weather strain. Team size, condition, fatigue, food load and terrain modify progress. Travel builds fatigue; rest reduces it and improves team condition. A lame ox reduces working condition; losing an ox reduces team size. A team with no animals or zero working condition cannot travel, but camp activities remain accessible for recovery or replacement. Mountain movement can be configured in route-node terrain; no western mountain geography has been added yet.

**Care supplies** are optional opening purchases at $5 per kit. Kits represent general care/repair supplies, not a verified period medicine or a guaranteed cure. A kit and a day support a selected traveler; paid medical attention costs $20 and a day. Care improves that person's reserve, reduces condition severity and advances recovery. Illness can still worsen or kill; dead members cannot be revived. Medical-service availability is an abstraction pending historical placement, not a claim that every camp had a physician.

**Mild, bad and serious conditions** now use severity factors. For spontaneous onset, ration-dependent severity branching follows the inspected BASIC routine at labels 6300–6360; daily onset odds, disease-specific strain, recovery durations and care effects remain our tuning. Rations, rest and unprotected exposure affect onset risk. This is a daily, named-person adaptation, not BASIC's shared medical-supply/fatality system.

## BASIC coverage and deliberate adaptations

Read alongside `CLASSIC_MECHANICS_AUDIT.md`, which preserves the pre-implementation audit and program line labels.

| BASIC system | Current counterpart | Difference requiring honesty |
| --- | --- | --- |
| Starting purchases and constrained cash | Eight typed supply categories, budgets, exact-cent quotes | Later-game profession budgets and observed store prices; $5 kits are new tuning. |
| Food, three rations and starvation | Living-party ration demand, individual nutrition strain and fatal lack of food | Pounds and daily time instead of food-expenditure units/two-week turns. |
| Animal investment and reduced travel speed | Ox count, condition, fatigue, load and weather/terrain factors | Explicit inventory and recoverable condition replace the spending/quality variable. |
| Fort resupply at reduced purchasing power | Passing-wagon buy/sell/barter services; trail buying prices are 1.5 times opening prices | Continuous service access is provisional; actual forts and service availability await route/history work. |
| Hunting and ammunition | Mouse aiming, misses, limited shots, carried meat, actual bullet consumption | One bullet minimum and a later-classic 100 lb carry limit replace the BASIC 40-bullet prerequisite and food-dollar yields. |
| Illness severity and nutrition | Named individual conditions, BASIC-derived ration/severity branching | Onset/progression/care are daily gameplay tuning, not historical medical models. |
| Medical supplies and $20 doctor | Kits and explicit paid attention for a selected living person | No automatic unaffordable-doctor death. Declining care leaves the condition to progress. |
| Breakdown and repairs | Recurring random wheel/axle/tongue failures with the correct spare, kit repair or slower free repair | Delays consume days/rations rather than subtracting distance already traveled. |
| Lame/wandering ox | Condition loss or missing-animal count, search/leave decisions | Condition can improve with rest; no permanently reduced spending variable. |
| Broken arm and lost companion | Named injury/search events and personal history | All companions can be selected; no hardcoded daughter/son role. |
| Unsafe water | Time to find a spring versus risk of a named illness | No continuous water-volume/contamination network yet. |
| Heavy rain, fog, hail and cold | Daily weather plus eligible recurring losses/delays and clothing protection | Weather probabilities are not verified historical climate statistics. |
| Fire, swamping and damaged supplies | Recurring resource loss events, animated river mishaps, clothing loss at crossings | Each loss is clamped to actual stock and recorded; numbers differ from BASIC expenditure units. |
| Bandits and separate rider tactics | Resource-constrained robbery choices and four rider tactics, with uncertain intentions | No ethnic identity assigned to threats. Defense is a resource/risk decision; mouse skill is used in hunting. These game-inspired rates are not historical claims and are not represented as features retained by the 1985 designer. |
| Snakebite and animal encounters | Individual snakebite condition, care/rest decisions; food-store protection using ammunition | No claim that generic kits cure envenomation; no routine fatal wolf attacks. |
| Assistance | Repeatable help/provisions event | Contextual original writing, not a claim about a particular diary incident. |
| Mountain delays, snow and exposure | Terrain speed modifier, cold/snow, damage/search systems and clothing consequences | Route-node terrain support is tested; the western route and its specific passes remain unbuilt by design. |
| Cause-specific death and winter risk | Personal death day/cause/history, surviving food demand, no-survivor loss, seasonal exposure | Arbitrary calendar instant-death and the old funeral questionnaire are replaced by simulation consequences and inspectable personal records. |
| Final turn and Oregon arrival | Stop clipping and chapter-end state | Still only the opening corridor; final Oregon arrival and proportional partial-day accounting belong to later route completion. |

The sixteen selector categories in the audit are represented in `data/trail_events.json`, plus riders as a seventeenth encounter. The event scheduler uses a provisional 18% eligible-day roll, source-inspired relative weights, weather eligibility and a five-day per-event cooldown. It does **not** make every day equivalent to a BASIC fortnight. Repeatable events use their cooldown history rather than the one-time authored-event `seen` list. Scripted day-two wheel trouble remains as an introductory encounter.

Immediate and chosen supply effects record actual clamped changes in `supply_history` and the visible journal, separate from the day's ordinary rations. Personal effects remain in individual histories. Crossings now include actual clothing loss in their outcome record and summary.

## Next tuning pass

Play and measure food/ammunition replenishment, event cadence, medical costs, illness severity/recovery, spare use, fatigue recovery, travel speed, exposure and river-stage changes across departure months and professions. Do not add the rest of the trail as a way to hide unfinished mechanics. Research service availability and climate/terrain data as actual route locations are introduced. Historical accuracy continues to override arbitrary classic abstractions where evidence conflicts.

## Validation and limits

The full suite passes: 3,185 simulation checks, 26 route checks, 69 art checks, 46 headless motion checks, 30 health checks, 112 survival checks and zero UI failures. Sixty seeded player journeys use public actions to hunt, rest and resolve affordable encounters; the 1,000 old short-leg regressions remain unchanged. The test policy assumes accurate mouse shots; it is not evidence of casual-player difficulty or final balance.

Survival checks exercise data rejection, actual weather movement/exposure, livestock, terrain, rain-linked river decisions, landmark-safe resupply, affordability, care/severity, ammunition, carrying limits, duplicate-action guards, replacement oxen, all seventeen encounter categories and every choice branch, clamped loss history, cooldowns, and actual UI signals/mouse hit handling. Graphical captures show the store, hunting, rain and trade service. These are integration tests with deterministic scenarios, not an exhaustive manual playthrough or proof of historical fidelity.
