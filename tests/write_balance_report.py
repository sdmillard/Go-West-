"""Format the real-engine before/after experiments; no simulation lives here."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
archive_path = ROOT / 'docs/balance-results.json'
archive = json.loads(archive_path.read_text()) if archive_path.exists() else {}

def experiment(label):
    path = ROOT / f'.tools/balance-{label}.json'
    return json.loads(path.read_text()) if path.exists() else archive[label]

before = experiment('before')
after = experiment('after')

def totals(experiment, profile):
    rows = [row for row in experiment['groups'] if row['profile'] == profile]
    return {key: sum(row.get(key, 0) for row in rows) for key in (
        'runs', 'arrived', 'intact', 'days', 'travel_days', 'travel_miles',
        'survivors', 'hunts', 'rest', 'care', 'lost', 'unfinished')}

def row(label, values):
    count = values['runs']
    moving = values['travel_miles'] / max(1, values['travel_days'])
    return (f"| {label} | {values['arrived']}/{count} | {values['intact']}/{count} | "
            f"{values['days']/count:.1f} | {moving:.1f} | "
            f"{values['hunts']/count:.1f} | {values['rest']/count:.1f} |")

text = """# First source-grounded balance pass — October 22, 2026

The user's direction is to use BASIC and historical numbers as a starting point, tune the connected systems, then finish the route. This pass calibrates opening-chapter movement and corrects ration/recovery and condition-onset relationships. It does not fit arbitrary historical death percentages.

## Anchors and their limits

| Evidence | Supported use | What it cannot establish |
| --- | --- | --- |
| 1978 BASIC labels 2860 and 6480: `200 + (A-220)/5 + 10*RND`, with A 200–300 and two-week turns | Roughly 14–16 nominal miles/day before setbacks, by arithmetic; illness, nutrition and animals should matter | Not 1985 source, a daily clinical model, or a pounds-per-day ration table |
| BASIC 2810: 13/18/23 food-expenditure units per fortnight; 6300–6360 severity branching | Ration trade-offs and conditional mild/bad/serious illness; keep units explicit | No valid direct conversion from these expenditure units to our 1/2/3 lb rates |
| [NPS travel interpretation](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm): broad 12–15 miles/day, 4–6 months | A reasonable movement envelope to compare with actual engine output | Not a measured 317-mile cohort, or an exact definition of moving versus elapsed days |
| [Palmer's 1847 outfit advice](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), 1906 reprint pp. 258–261 | Recommends four yoke (eight oxen), about 2,500 lb starting load, and adult provisions including 200 lb flour, 30 lb pilot bread, 75 lb bacon, 10 lb rice and 25 lb sugar, plus other supplies | One guide's recommendations, not universal requirements; bushels cannot silently become pounds. Its medical advice is not adopted |
| [NPS overland-wagon interpretation](https://www.nps.gov/jeff/planyourvisit/overland-wagon.htm) | Broad 2,500 lb supply guideline and 10–15 miles/day across several decades | Not a specific wagon capacity, total-load estimate or economy for our 1848 party |
| [NPS Red Vermillion account](https://www.nps.gov/places/red-vermillion-vieux-crossing-1849-cholera-cemetery-and-vieux-family-cemetery.htm) and [Altonen's thesis abstract](https://pdxscholar.library.pdx.edu/open_access_etds/4305/) | Distinguish the 1849 epidemic from earlier intestinal illnesses | No 1848 incidence denominator or daily mortality probability. The thesis abstract is an initial research lead, not proof of zero possible cases |

The cached BASIC and Palmer source identities are recorded in existing manifests. The new source/limit map is `research/BALANCE_REFERENCES.json`. BASIC comparisons are source-audited arithmetic; the original BASIC executable was not run in this experiment.

## Changes made

- Player-route nominal paces become 16/20/24 miles/day, before weather, terrain, team, fatigue, load and landmark clipping. Old 12/18/24 values remain only in the isolated legacy regression fixture. These nominal numbers are tuning chosen to bring observed movement into a plausible range, not a historical three-speed table.
- Rest recovery depends on rations: 3/5/7 internal points for bare/meager/filling when fed. This removes identical healing on unequal meals; these point amounts are game tuning, not measured physiology. An initial 1/4/7 trial made a fixed bare-ration strategy spiral into excessive waiting; it was rejected rather than described as historical truth.
- Spontaneous nutrition-linked onset chooses illnesses only. Broken limbs, wounds and bites arise from accidents/encounters. The fracture encounter can produce a broken arm or leg; its impact severity does not come from the ration/illness formula.
- Automatic cholera onset starts in 1849 as a conservative epidemic chronology rule. Dysentery and other eligible conditions remain possible in 1848. Cholera stays in the data for later dates and explicitly injected test scenarios. This models epidemic context; it is not a claim that every possible 1848 illness called cholera has been ruled out.
- Ration and Camp tooltips explain that low food reduces recovery. New pace/recovery tables and chronology/accident checks are validated.

## Experiment

The harness calls the actual public engine actions and uses seeds 0–19, March/May/August departures, and farmer/banker budgets. Each run starts with six oxen, 600 lb food, five clothing sets, 200 bullets, three spares and two care kits. All policies hunt below 120 lb when they have ammunition, with a separate seeded **65% per-shot hit model**. They resolve the first affordable encounter choice. This is a deterministic comparison of specified policies, not a human playtest or historical population.

Cautious: steady/filling, inspect the weakest person, rest as needed, care for a sick member when resources allow. Grueling: grueling/filling, no voluntary rest or care. Bare: steady/bare with rest/care. Meager: steady/meager with rest/care. No rest: steady/filling with no voluntary rest or care. Event delays and hunts can still rest the team. Step limit: 600 decisions. All figures refer to the current opening chapter, not the full trail.

Before has 480 runs (four policies); after has 600 (the same four, plus meager). Each policy below has 120 runs. Paired comparisons use the same seeds, months, budgets and aim model, but changed simulation rules naturally change the subsequent random sequence.

### Results

Arrived means at least one survivor reached the chapter end; intact means all five arrived. Days average all runs; moving miles/day uses actual miles advanced divided by moving days, including short clipped arrival days. Hunting/rest columns are mean counts of explicit actions, not all elapsed delay days.

| Policy/version | Arrived | Intact | Mean elapsed days | Miles/moving day | Hunts | Rest days |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
"""
labels = [('cautious', 'Cautious'), ('grueling', 'Grueling'),
          ('bare_rations', 'Bare'), ('meager_rations', 'Meager'), ('no_rest', 'No rest')]
for profile, label in labels:
    old = totals(before, profile)
    if old['runs']:
        text += row(label + ' before', old) + '\n'
    text += row(label + ' after', totals(after, profile)) + '\n'

text += """
### Interpretation

The tuned cautious movement is within the broad NPS travel envelope; elapsed chapter duration still includes dense early river stops and other delays. Do not extrapolate that calendar average directly to an entire trail whose stop spacing and terrain differ.

Fixed bare rations now impose substantial time, illness and personal-survival costs rather than gaining the same camp recovery cheaply. A player can switch rations; the fixed-policy experiment intentionally does not. Prepared steady travelers without voluntary rest also survived this short corridor: that does not establish that rest is useless over a full journey, and we did not invent extra deaths to force a desired success percentage. Grueling travel remains a deliberately punishing policy in these tests, not an estimate of actual emigrant mortality.

## What remains uncalibrated

- Aggregate food pounds conceal nutritional composition, adult/child differences, spoilage and hunting versus dried staples. The current 600 lb default provisions only the opening slice. Five adults would need 1,700 lb from just the five weighed staples above, before the other items; this arithmetic is not a complete five-person load recommendation. Do not call the current cart a researched full-trail outfit.
- Actual total carried load is not yet tracked: only a simple food-weight modifier exists. The 2,500 lb guideline does not validate our load factor, inventory weights, six-ox suggestion, or minimum two-ox departure check. Those need an explicit load/outfit model.
- Historical food prices differ by item, place and year. Classic profession budgets, bulk-food prices and universally available trade/medical services remain abstractions. They were not silently recalibrated from later 1849/1850 examples.
- Weather probabilities are not reconstructed climate. Current disease incidence, care benefit, recovery periods, predator/robbery frequencies and river-loss chances are not historical rate estimates. Whole-trail death counts across many years cannot be assigned as this chapter's daily odds.
- Hunting always offers the same targets and carrying potential; regional animal availability, encounter scarcity and preservation still need work. The 65% shot model only makes this experiment less idealized than perfect-hit regression tests.

Next: investigate explicit outfit/load composition, location-dependent service and game availability, and historical climate context. Preserve the source/gameplay distinction while tuning those connections, then extend the route.

Raw grouped results are in `balance-results.json`. Reproduce a current run with `godot --headless --path . --script tests/balance_report.gd -- --label=after`; format it with the companion Python utility, which falls back to the archived baseline if the old `.tools` experiment is absent. The before numbers are frozen results from the pre-calibration code, not a rerun of that old engine by the final script. The `.tools` files are ignored development output. Automated correctness tests remain separate from this balance experiment.
"""
(ROOT / 'docs/BALANCE_PASS_01.md').write_text(text, encoding='utf-8')
(ROOT / 'docs/balance-results.json').write_text(json.dumps(
    {'before': before, 'after': after}, indent=2), encoding='utf-8')
print('Wrote docs/BALANCE_PASS_01.md and grouped balance-results.json')
