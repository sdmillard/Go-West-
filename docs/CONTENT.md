# Event content contract

Edit `data/events.json`, then restart the game. This is a bundled content array; external pack discovery is future work. JSON content is declarative and cannot execute GDScript.

Every event requires a unique nonempty `id`, `title`, `text`, `category`, `trigger` and a nonempty `choices` array. The loader validates the entire array before play; a failed file leaves no partially usable catalog and the UI shows an error.

| Field | Values / meaning |
| --- | --- |
| `category` | `historical` or `absurd` |
| `trigger` | `day`, `mile`, or `random` |
| `at` | Nonnegative numeric threshold, required for day/mile |
| `choices[].label` | Button text |
| `choices[].result` | Journal entry after applying choice |
| `choices[].requires` | Optional object: minimum food/health/money/fuel/wheels/axles/tongues |
| `choices[].effects` | Optional object of supported effects |
| `choices[].complete` | Optional boolean; completes the route if still alive |
| `choices[].risk` | Optional probability, effects and text for a mishap |

Effects use numeric deltas for `food`, `health`, `money`, `fuel`, `wheels`, `axles` and `tongues`. Inventory is converted to integers and floored at zero; money preserves cents. `parts` is a derived summary, not an allowed effect or requirement. Health is capped at 100. Use integer inventory deltas in authored content. `days` is an integer delay from 0 to 30; every delayed day consumes food and applies travel health costs, without mileage or additional random rolls. Death takes precedence over completion.

`item` adds a string ID once to inventory. `vehicle` accepts `wagon` or `corolla`. These are extension hooks; speed, fuel logic and item behavior are currently in the engine. Unknown effect keys fail validation. Content authors should pair costs with `requires` when insufficient resources must block an option; an unguarded negative delta otherwise clamps to zero.

The survival pass also allows `medicine` (care/repair kits), `oxen`, `clothing`, `bullets` and `ox_health` numeric effects/requirements. Team condition is capped at 100. Player journeys distribute `health` effects over living members and derive party condition afterward; the legacy fixture remains aggregate-only. Supply effects record actual deltas before elapsed-day rations, so a loss cannot exceed the inventory that existed.

```json
{
  "id": "shared_supplies",
  "category": "historical",
  "trigger": "day",
  "at": 3,
  "title": "An offer on the trail",
  "text": "Another wagon offers a sack of flour.",
  "choices": [
    {
      "label": "Buy 20 lb for $5",
      "requires": {"money": 5},
      "effects": {"money": -5, "food": 20},
      "result": "You pack the flour beneath the canvas."
    },
    {"label": "Decline", "effects": {}, "result": "You wish the travelers well."}
  ]
}
```

Add this object to the existing array. This example is fictional historical-style writing, not a documented historical incident.

Risk example: `"risk": {"probability": 0.2, "effects": {"food": -10}, "text": "A sack tears."}`. Its probability must be between 0 and 1. The ordinary choice effects and journal result apply first; then the optional mishap applies.

## Scheduling

The player corridor now comes from `data/route.json`. Its landmark arrivals have generated route actions (leave/cross/rest), separate from this encounter schema. The old `kansas_river` completion event is excluded from the extended player route and retained only for the legacy first-leg regression fixture. Real route crossing/arrival does not complete the chapter until the Platte endpoint. See `HISTORICAL_ACCURACY.md`.

Historical threshold events are checked in file order after a travel/rest day and after resolving an encounter. An eligible historical event takes priority over a rare roll. Due historical events remain eligible until displayed. An event is marked seen when presented and cannot recur.

Absurd events must use `random`. Classic cannot schedule or roll them. In Unhinged mode the engine makes a single roll in `[0,1)` on a day without a due historical event. A value below `0.01` selects uniformly among unseen absurd events. With three available examples, each has a 1/300 chance on the first eligible day. The chance is per eligible day, **not per journey**. Resolving an encounter or spending time through a choice does not create bonus rolls.

The engine owns RNG, state, eligibility and effects. The UI owns presentation and calls `travel`, `rest`, `configure` and `choose`. `roll_absurd(roll)` accepts an explicit roll for boundary tests; normal play uses the private seeded RNG. `_present` is an internal helper used only by the scheduler and example integration tests. Keep preview/cheat calls out of normal play so Classic remains isolated.

## Recurring survival content

`data/trail_events.json` is a second validated catalog with seventeen repeatable historical-style encounters. The engine uses a separate seeded survival stream, the configured eligible-day chance, positive integer `weight`, optional weather eligibility and per-event cooldowns. The optional `onset_effects` apply exactly once when presented. An event-level `condition` selects a living named member and records its onset. `{person}` is replaced by that name; breakdown `{part}` becomes wheel, axle or tongue, with the matching spare requirement generated by the engine.

Choices may use `rest: true` to make their elapsed days resting days. `service: "repair"` is the typed spare-replacement hook; `service: "defend"` labels a resource/risk choice. `risk.condition` adds a supported personal condition if its probability roll succeeds. Condition IDs and service names are enumerated, not executable code. Medical/trade menus are generated by engine actions rather than arbitrary JSON scripts.

The fracture encounter can supply validated `condition_choices` of `broken_arm`/`broken_leg`; `{injury}` is replaced by the selected condition's name. In health definitions, optional integer `from_year` gates automatic illness candidates by the simulation calendar. Injury definitions are excluded from spontaneous illness rolls and enter through encounters instead. Explicit `begin_condition` calls remain available to deterministic development scenarios; normal play should use the scheduler and eligibility rules.

Normal `travel`/`rest` can roll a recurring event after higher-priority health/arrival/authored events. Resolving a choice, delayed days, trading or finishing a hunt do not grant bonus recurring rolls. Weather and health still advance on each elapsed day. `seen` does not suppress the repeatable catalog: `survival.last_events` controls its cooldowns. See `BASIC_SURVIVAL_BENCHMARK.md` for the origin and limits of the weights.

## Hunting

`data/hunting.json` defines the validated activity rules and weighted habitat pools. See [HUNTING.md](HUNTING.md) for mechanics, evidence boundaries and authoring limits. Animal indices are generated encounter identities; multiple animals can share a species. Food values represent usable meat, not carcass weight.

## Provisions and persistent records

`data/provisions.json` defines estimated cargo masses, the departure guideline, ration weights, load response and fresh-meat lifetime. Evidence and limits are in [FOOD_AND_SURVIVAL.md](FOOD_AND_SURVIVAL.md). Gameplay JSON changes alter the save fingerprint; current saves require matching rules. Save and memorial schemas live in their independent store modules; see [SAVES_AND_GRAVESTONES.md](SAVES_AND_GRAVESTONES.md).

## Full route

Route kinds include `fort` and `destination`. Every current node has exactly one outgoing road except the final destination; unsupported branches are rejected. `terrain` and `hunting_region` select authored regional models. Post bulk offers use `trade_bulk`/`bulk_food_cents`; Barlow uses `toll_dollars`/`toll_per_ox`, and `descent` enables the controlled/hurried Laurel Hill choices. Effects and probabilities are authored tuning, not historical measurements. Mileage `source_table_rows` are extraction IDs; `source_rows` are numeric contributions. Keep authored subdivisions labeled. See `ROUTE_EXPANSION.md`, `PALMER_DISTANCE_TABLE.json` and `art/WESTERN_REFERENCES.md`.
