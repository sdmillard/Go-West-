# Partial scurvy treatment and visible progress

October 26, 2026. This records treatment runtimea27064d; [subsequent gradual reserves](VITAMIN_RESERVES.md) also update prevention. Small servings of fruit and greens now help an existing scurvy patient, instead of receiving zero recovery credit below the shared threshold.

Actual shared meal vitamin value is compared with the existing party target and capped at full coverage. Recovery and scurvy damage interpolate between the existing unfed and fully fed endpoints. At 50% coverage, a working day earns half a recovery step and half the untreated scurvy damage; a resting day earns one recovery step. Four quarter-covered working meals add up to a full step. Tiny progress and damage fractions accumulate rather than disappearing through daily rounding. No-produce days preserve prior recovery progress but do not advance it. Full coverage still stops scurvy's own damage and retains the existing 14-step recovery period.

Open a traveler's health details to see **Treatment progress** and **Last meal's vitamin-C coverage**. These are recovery steps, not a promise of a fixed number of calendar days. Other illnesses and starvation can still harm a treated patient.

This applies to actual main-party meals and wagon guards' own meals. Existing saves without treatment fractions still load; new fractional progress, pending damage and last coverage save exactly and are validated on load. No food, labor or medicine is created.

This is a focused authored treatment improvement, not a calibrated physiological nutrient-store model. The existing produce-weight target, 25% dried-produce vitamin retention, shared distribution, shop stocks, prices and **prevention/onset counter** are unchanged. It does not make one berry a full treatment or guarantee survival without continued food access. Partial intake can now help recovery from existing scurvy; partial intake has not yet been incorporated into the prevention model. The earlier [diagnosis](SCURVY_TREATMENT_AUDIT.md) remains a record of the preceding rules.

## Validation

All **89 Godot suites** pass. The new **25 checks** cover actual partial shared meals, fractional recovery and damage, resting, no-produce interruptions, full treatment, unaffected dysentery, readable status, exact save/load, older records and malformed state rejection. Existing guard/save tests also pass.

Eight integration journeys replay the same standard-May farmer cases as the audit, under the same resources and decisions: seeds525000-525003, no-stock/two-goat arms, planning65. All report/log errors are zero; frozen source and archive hashes match. Arrivals, days and survivor counts are unchanged in this narrow set: five arrivals total across both arms. None of its sick days included a partial serving, so this replay does not measure the new rule's survival benefit. The controlled actual-meal checks exercise that correction. Food access and the time budget remain open; no new farmer win-rate claim.

[Compact verification](partial-scurvy-validation-01.json), verifier `tests/summarize_partial_scurvy.py`, runtime `a27064d`; raw local `.tools/hunting-partial-scurvy-standard-{none,goats}-01.json`, separate copies `.tools/partial-scurvy-archives/`, log `.tools/partial-scurvy-full-tests.log`. The raw integration cases are repeats, not independent new balance cases. Test with `./test.ps1`, then run `python -B tests/summarize_partial_scurvy.py` where the archived reports are present.
