# Feeding revision: declared survival comparison

October 26, 2026. Freeze gameplay, source-identical common observer/policy files and this protocol before matrix outcomes. Do not tune gameplay or decisions between development and confirmation. This is a farmer survival/bottleneck study, not historical certification.

## Sources and cohorts

Old runtime: `bcd3e6e1619634c1e886ae74eb64e73dee190daf` (exact table meals, before mixed feeding). New runtime: `0daa47e97d23ba0aa8d1e2ff1f313720bc7e9a5a` (mixed feeding). Separate isolated checkouts retain their own unchanged simulation/data. Identical `feeding_compare_{stock,observer,campaign}.gd` and parity test are installed in both. Version-local underlying engine sources and rule fingerprints are intentionally different. Common driver source hashes and all inherited decision-policy sources must match.

Primary: five livestock arms (none, two goats, cow, six hens + 50 lb grain, cow/goat/six hens + 50 lb grain), both runtimes, standard/lean outfits, May/July, six development seeds and six confirmation seeds. Existing stock-aware decisions are fixed on both versions. No initial fodder and no fodder purchases in the primary comparison. This measures new feeding/condition behavior under matched choices rather than confounding it with a new shopping strategy.

Secondary: new runtime only, goat/cow/mixed arms, both outfits/months and both seed phases, with the predeclared fodder-shopping policy below. Compare it with each matching new fixed-policy scenario. It cannot be attributed to game rules alone.

Development seeds **365000–365005**; confirmation **375000–375005**. Primary 480 + secondary 144 = **624 journeys / 52 reports of 12**. Six underlying seeds repeat across settings per phase; these are paired scenarios, not 624 independent worlds. Seed 355901 is excluded for parity/setup checks; all prior pilot/study seeds and reports are excluded. Run all declared cells without choosing a favorable subset. Confirmation settings stay frozen after development.

## Shared decisions and money

Farmer, $675 total starting assets/cash including purchased wagon, same default five travelers. Standard six oxen/1,700 staple units or lean four oxen/1,200, shared riding horse/saddle/bags and 20 dried-produce units. Animal/feed purchases use original funds and real cargo; suggested supplies/capital/prices are unchanged. Steady pace, existing adaptive rations, 65% aiming, two-meal threshold, mobile outriders, support camp jobs and shared-stop fishing. Existing bounded health-rest rules apply. No forced week-long waits. Ordinary produce/medicine/food decisions are unchanged. The inherited policy can still choose Filling when any traveler is below 80 or ill, and retains $20 normal/$10 emergency reserves; these are limitations to examine, not evidence that gameplay is optimal.

Both versions use the existing stock-aware care reservation, grain-buying and emergency slaughter choices. Shared overload handling recognizes actual carried animal feed and partial scoops, without inventing supplies on the old runtime. No-stock control journeys must have matching outcomes, paths, timing and ordinary action counts across versions; normalize only new zero-valued outfit keys when comparing carts.

Secondary fodder policy: after ordinary food/medicine/produce and existing grain-buying opportunities, at an open bulk post fill ten days of the current travel-preview forage deficit when fewer than three days are held, only if natural intake is below the full-production threshold. Keep $20, respect actual finite stock/storage, add no opening fodder or cash. When forced to walk, discard animal feed before other cargo. No live-animal sale/replacement optimization is added. These rules are declared before outcomes.

## Measurement and acceptance

Common observers read actual engine meals and product ledgers: food requested/eaten/short, dairy eaten, grain/fodder used (including partial scoops), real leftover portions fed, product expiry and packing losses, care, condition/crossing/slaughter losses, purchases, scurvy, deaths and location/time. Version-specific old grain-only versus new maintenance-shortage counters are not treated as the same measure. Time comparisons use paired arrivals only; earlier deaths are not quicker completion.

Report arrival and original party survival, shortages before first death, cash at shortage, production versus dairy actually eaten, hunting and delivered outrider catch, foraging/fishing, rest/stationary/progress days, disease and season. Preserve complete cells, failures, source hashes, rule signatures and exact budgets. No state/save/policy/source errors may be silently dropped. If a blocker requires a policy/instrumentation fix, label the prior diagnostics, amend/freeze the protocol and restart affected cohorts with fresh seeds before claiming confirmation.

Verify observer parity on both runtimes against each plain engine. Run current test.ps1 before handback. Raw archives remain in ignored .tools; publish compact summaries/provenance/limitations. Hash-verify complete parent copies against isolated originals before deleting temporary checkouts. Retain manifest and failed diagnostics separately. No survival rates were used to set animal yields.


## Amendment 02: egg-boundary save correction and complete restart

The first matrix is excluded in full. It archived 35 accepted reports (420 journeys), then the new-runtime standard hen report encountered one day-76 journey with periodic and final save errors. Its binary egg progress was 0.99999999999999956; JSON serialized it as 1.0 and strict validation rejected it. That failed 12-journey report is retained separately with the original 35 and manifest-01. No survival conclusion is drawn from the interrupted matrix or its already-completed confirmation cells.

Canonicalize egg progress to twelve decimals before laying and canonicalize its remainder. Apply the same numeric correction to the old feeding control, so serialization stability is shared rather than confounded with feeding. The old gameplay baseline is now `8c9987474b85c8148f925db690494a2b9dbb7d7f` (bcd3e6e plus the shared precision correction and observers). The new baseline is `64318410e93cfc5ed28039436374921da5731c10` (new feeding plus precision correction and targeted repair of affected older saves). No production rates, nutrition parameters, prices or decisions were retuned.

Restart **all 624 journeys**, with development seeds **385000–385005** and confirmation **395000–395005**. Original cohort sizes, settings, budgets and policies remain unchanged. Manifest-02 and distinct report suffix -02 prevent overwriting diagnostics. Common study sources still derive from 3fd4222 and match byte-for-byte; runtime roots are recorded in the manifest. A generated actual failing save and year-long controlled laying regression verify the correction before restart. Old legacy saves rounded exactly to 1.0 recover a nearly-complete pending cycle without granting food, healing or cash.
