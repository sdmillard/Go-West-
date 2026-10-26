# Mixed feeding and livestock condition

October 26, 2026. Follows [exact table meals](TABLE_FOOD_AND_CARE.md) and the [realism audit](LIVESTOCK_REALISM_AUDIT.md). The milk/egg potential yields, calorie densities, animal purchase prices, starting money and suggested outfit are unchanged. This corrects how feeding and condition limit those yields.

## In the game

Hens now share a finite opportunity to scratch for seeds/insects at camp. Flock size does not multiply that resource. Travel, habitat and season limit access. Hens use carried grain for the remaining ration, and can share actual leftover partial food portions when the setting is on in **Supplies > Livestock**. Sharing consumes those calories and their mass: meals never generate free scraps. It protects the party's current ration and reserves vitamin-bearing fruit/greens portions for people. The switch is optional; older saves default to sharing unless changed.

Cows and goats now have separate grazing/browse availability by route region. Buy **Dairy fodder** during initial outfitting or at open bulk post counters to cover poor forage. It costs an estimated two cents per pound, is stocked finitely, and adds its real carried weight. Fodder is used automatically to fill household dairy animals' ration gaps; it does not add hauling capacity or feed the existing draft/mount systems. Grain, fodder and leftover portions are shown in the inventory/livestock windows. Whole feed quantities and partial scoops can be discarded there.

Feed is consumed exactly, with physical partial scoops retained. A quarter-pound grain purchase remains a quarter pound; using part does not charge for another complete scoop next day. Fractional fodder pounds likewise remain available and count toward cargo. These supplies follow the party under the existing livestock/grain rule; they are not field-trip or wagon-cache allocations. Detached actors do not inherit them.

The livestock panel shows estimated travel-day feed coverage, expected resource use, season/daylight and a waterless-road warning. These are previews, not guaranteed future output. Unavailable labor still limits milk/egg collection under the preceding care fix.

## Avoiding the capacity collapse

Body condition from **50 through 100 (Fair and Good)** has full production capacity. Below Fair, the curve falls smoothly through 40% at condition 20 and zero at zero; no adjacent point changes capacity by more than two percentage points. Fair condition is not treated as incapacitation.

Current intake first supports maintenance; available surplus limits production. Condition reflects accumulated hardship. Food, water, condition, collection and hen diet quality constrain output through the strongest limit, instead of multiplying a chain of overlapping stress percentages. Season, habitat and feeding time also cap the same natural-feed opportunity, rather than multiplying the same scarcity several times. Lactation stage and hen daylight remain separate biological effects.

Tiny maintenance deficits accumulate fractional condition wear. They are not rounded up to one lost point every day. In the controlled test, fifty days at intake 0.69 against the authored 0.70 maintenance level cost only a few condition points, not fifty. Full feeding can repay fractional strain and restore condition. Severe starvation, thirst, heat/blizzards or grueling work can still cause losses; the current daily strain takes the strongest of those effects rather than repeatedly adding overlapping labels.

Winter reduces natural feed and hen laying opportunity. It no longer directly subtracts condition simply because the month is cold. Fed animals can maintain condition in clear winter weather; unsupported grazing-only animals can still weaken. This does not make blizzards or waterless roads safe.

## Authored quantities and evidence limits

| Quantity | Current allowance | Status |
|---|---:|---|
| Cow full forage ration | 25 lb/day | Nominal dry-feed equivalent for a modest milk animal, not an animal-size model. |
| Goat full forage ration | 3 lb/day | Nominal dry-feed equivalent; actual browse quality matters. |
| Hen full ration | 0.25 lb/day | Poultry feed-equivalent allowance; not a complete diet specification. |
| Hen scratching pool | Up to 0.5 lb/day for the entire flock | Authored resource cap, reduced by access/season. No promise that a specific camp supplies this amount. |
| Shared leftovers | At most 0.05 actual lb/person/day | Actual available partial portions only, with human ration/vitamin protections. |
| Hen feed energy equivalence | 1,500 kcal/lb | Coarse grain-equivalent accounting; scraps use their saved actual calories and weight. |
| Maintenance / full-production intake | 0.70 / 0.95 of nominal ration | Calibration thresholds, not measured clinical cutoffs. |
| Grain-only laying capacity | 75% before daylight/other limits | Acknowledges that grain alone is not a complete laying diet; no separate mineral/protein disease model. |
| Fodder | $0.02/lb; 500 lb per bulk post stock | Explicit retail estimates, not a verified 1848 hay quotation. Suggested purchase remains zero. |

Regional forage values and time budgets are estimates. For example, the Snake River region offers more usable browse for goats than grass for cows; the model does not identify particular edible plant species or assume all sagebrush is safe feed. It has no forage depletion map, measured pasture acreage, animal body-size genetics, breeding, shelter inventory or mineral supplementation system. Hay uses carried pounds with a simplified forage-equivalence assumption; water content and digestibility are not simulated in detail. Grain calories maintaining condition in this model do not establish a nutritionally complete real-world ration.

The existing [source ledger](LIVESTOCK_REALISM_AUDIT.md) remains the evidence basis. [OSU hen feeding](https://extension.oregonstate.edu/catalog/pnw-477-how-feed-your-laying-hens) and [FAO feed resources](https://www.fao.org/4/y5169e/y5169e04.htm) support mixed, finite food sources rather than grain-only dependence or unlimited scraps. [Merck goat nutrition](https://www.merckvetmanual.com/management-and-nutrition/preventative-health-care-and-husbandry-of-goats/nutrition-of-goats), [OSU family dairy guidance](https://extension.oregonstate.edu/catalog/em-9011-owning-dairy-cow-or-goat) and [UC dairy husbandry](https://ucanr.edu/site/small-acreage-landowners/dairy-animals) support forage-based diets, lactation demands and attention to water/condition. They do not validate our precise resource caps, retail price or health thresholds. Modern smallholding/heritage yields remain accepted proxies, with the limitations recorded in the audit; win rates did not set these production rates.

## Compatibility and verification

An authentic pre-change save was generated before edits using ordinary outfitting and a camp day. `tests/fixtures/pre-mixed-feeding.json` retains old fingerprint `ebbe3e71835760dcfcf370a51c7399baff3bc9d800d9afd73e0e596231572cd6`. Migration preserves existing supplies, animals, exact food portions and random streams, and grants no fodder, grain or condition. Optional sharing/fractional-wear and feed-remainder records are saved and validated; old records without them remain valid.

`tests/test_livestock_feeding.gd` covers actual Fair-versus-Good production, every condition point and neighboring thresholds, fractional chronic strain, clear-winter feeding over fifty days, limited scratching across flock sizes, real scrap calorie/mass consumption, human/vitamin protection, exact feed remainders, pure previews, habitat differences, actual store/drop pathways, corrupt saves and genuine migration. It is included in test.ps1. Journey checks are integration smoke tests; a new matched survival balance experiment remains separate.
