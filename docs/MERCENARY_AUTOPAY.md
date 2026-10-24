# Automatic mercenary wages

Each mercenary has an optional AUTO-PAY WAGES checkbox in the pre-departure editor and their Party character sheet. It defaults off, including in existing saves, and is stored separately for each contract.

When enabled, the game attempts to pay the full amount owed from available cash each day. Enabling it during a journey also attempts to settle current arrears immediately. Payment does not advance time or prepay a future bill. Wage rates and agreed intervals are unchanged.

If cash cannot cover the full debt, it remains owed; the existing missed-payment and trust rules still apply. The game retries on later days. Multiple eligible contracts draw from the shared purse in party order. Absent wagon guards cannot be paid remotely. The manual payment button remains available.

The saved setting is an optional boolean contract field; older contracts remain valid and manual. No JSON rule files or rules fingerprint changed. Cash settlement now uses integer cents before converting to the saved dollar amount, avoiding floating-point drift across save/load.

Validation at implementation checkpoint 07635fe: all 63 Godot suites passed in an isolated checkout, including 40 auto-pay checks. The same sources completed 24 store and 20 outlaw integration journeys with zero reported errors. Native pre-departure and Party screens were inspected and the Party screen shown to Spencer. Evidence remains in ignored .tools/autopay-* files. Actual player saves and the three preexisting debug pilot files were preserved.

Companion assignments remain proposed; see [implementation stages](COMPANION_TASKS_IMPLEMENTATION.md).
