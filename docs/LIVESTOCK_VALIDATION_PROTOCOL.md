# Livestock validation protocol

Freeze simulation, data and GDScript before final runs. Do not tune production to pilot outcomes.

- Run test.ps1: 77 suites, including original save fixtures, mounted outings, physical food mass and the focused livestock/individual-team checks.
- Run 24 store and 20 current-outlaw integration journeys using existing public-action policies. Individual ox injuries now affect one animal, so outcomes need not match the former shared-condition system.
- Run tests/livestock_journeys.gd: 36 declared development journeys, 3 professions, May/July, baseline / dairy mix / eight oxen, seeds 301010-301011. Budgets remain unchanged and extra stock is paid for. The existing steady survival policy is reused; its new wrapper can rotate the six fittest oxen below working condition 70 and discard excess grain when walking. No animal purchases, feed resupply or elective milk-animal slaughter are optimized. This is integration evidence, not proof of farmer balance.
- Validate current JSON round trips regularly and at journey end. Reject malformed animal IDs, counts, conditions, product mass/calories and team selections. Restore genuine pre-livestock and older fixtures without granting animals, food, health or money.
- Rebuild approved artwork with Aseprite and verify exact pixels, sheet geometry, palette, alpha and walking/water registration. Inspect native travel, camp, ledger and river scenes.
- Preserve full logs/reports in parent .tools. SHA-256 verify copies against isolated originals before cleanup. Compact results record source/rules fingerprints, starting outfits and costs, and complete declared cohorts.
