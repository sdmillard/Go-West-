# Exact table food and actual daily animal care

October 25, 2026. First correction following the [livestock realism audit](LIVESTOCK_REALISM_AUDIT.md). Milk and egg calorie densities and animal production rates are unchanged. Feeding ecology, winter condition loss and the stacked linear production penalties are still pending.

## Player behavior

Every milk or egg lot keeps its edible weight, actual calories and expiry until eaten. A 626-calorie milk serving contributes 0.626 of the existing 1,000-calorie food unit, even if it cannot fill a whole unit by itself. One goat and two goats no longer create different calories through daily rounding. Milk and eggs retain separate expiry dates.

Meals first preserve the existing shared fruit/greens serving, then use perishable table products and the remaining ordinary provisions. If a whole inventory unit is only partly needed, its uneaten portion remains physical food. For example, drinking 626 calories of milk can leave 0.626 unit of the final staple serving for later. The portion retains its source weight, expiry and remaining vitamin value; it is neither free food nor a permanent calorie credit. Partial meat can spoil and partial dried fruit retains its dry mass and vitamin value.

Today’s products can feed the party before packing. Uneaten products and portions count toward cargo. Excess is left behind with a journal entry; expired products are recorded separately. The inventory food table and livestock panel show table food and partial portions, and the main food count includes them. The low-food forecast uses exact carried portions and their expiry, without promising future milk, hunting or gathering.

Partial ordinary servings live with the table-product ledger and follow the party, as milk/eggs already did. They can be discarded from Supplies > Livestock. They are not separately priced, sold, assigned to field trips or converted into drying inputs. Existing whole-unit food trading, hunting conversion and ordinary inventory limits remain intact. This avoids a project-wide switch to fractional inventory counts.

Standing companion orders no longer reserve livestock-care labor while traveling. Actual camp jobs, active nurses and their patients, the leader’s care action and real hunting absences still compete with animal care. A companion whose planned job falls back to rest can help, subject to the existing health/availability rules. The care-time allowances themselves are unchanged estimates.

## Compatibility and validation

Two authentic prior-rule saves were generated before edits, using ordinary outfitting/rest actions. `tests/fixtures/pre-exact-table-meals.json` contains a dairy outfit with already-rounded table batches and a single-hen outfit with a raw egg. Their original rule fingerprint is `96f62de645481bd6421bce320de1afcfcd7e2d3dec70483a49ab31dbdd33c4c5`.

Migration retains existing whole food, cash, rounded batches, raw products, animal records and random streams. It does not reconstruct calories already lost or created by the old rounding rule. Future milk/eggs use exact serving. Fractional product mass is canonicalized to twelve decimal places and calories to nine for stable JSON round trips; precision loss is far below a useful serving.

The new `tests/test_table_meals.gd` covers tiny/large servings, repeated meals, shortages, produce priority, partial meat and dried fruit, separate expiry, cargo overflow, forecast purity, real versus idle work, nurse/patient exclusion, corrupt calorie rejection and genuine old saves. Existing livestock and read-only study observers were updated for fractional product production/consumption; historical campaign archives remain unchanged.

The prior [13-case report](livestock-realism-audit-01.json) remains a frozen description of old rules, not current behavior. Its original diagnostic must be run at its recorded source snapshot to reproduce those totals. The new regression suite verifies corrections rather than preserving those defects. New survival comparisons should use fresh, source-stamped reports.


## Frozen publication results

Runtime `9ed0a35042455aca4f201db24ab1ed35330c4fa9` passed all **79 Godot suites**, including **102 exact-meal checks**, 185 livestock checks and 120 observer/parity checks. Twelve mixed-livestock journeys (two seeds, May/July, farmer/carpenter/banker, shared horse, mobile travel, stock-aware decisions) completed with zero selected state, save or policy errors. Their source hashes were checked against the frozen files. These are integration checks, not evidence that farmer balance is solved.

[Validation record](table-food-validation-01.json) contains rules, source revision and SHA-256 hashes for the complete local log, raw journey archive and authentic prior-rule fixtures. Earlier preflight runs remain excluded. Hunting recovery now includes partial catch portions in packed food and keeps them separate from meat actually eaten.
