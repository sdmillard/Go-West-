"""Summarize archived engine experiments; no historical estimates or game tuning."""
import json
from collections import Counter
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]
datasets = [json.loads((ROOT / 'docs' / name).read_text(encoding='utf-8')) for name in (
    'full-trail-balance.json', 'full-trail-balance-adaptive.json', 'full-trail-balance-hunting.json')]
assert len({data['rules_signature'] for data in datasets}) == 1
assert [len(data['runs']) for data in datasets] == [720, 720, 1260]
assert all(not data['errors'] for data in datasets)

lines = ['# Full-trail mechanics and balance experiment', '', '**Archived diagnosis:** These 2,700 journeys precede the economy/preservation changes. See [the current comparison](ECONOMY_AND_PRESERVATION.md) for updated rules and outcomes.', '', 'October 22, 2026. **Observation pass: no game rules or prices changed.**', '',
         '2,700 scripted journeys through the real engine, across the 1,938-guide-mile road to Oregon City. Three professions, March/May/August departures, and the current suggested $380 outfit: six oxen, 800 lb food, five clothing sets, 200 bullets, one of each spare, no care kits. Farmer starts with $20 left, carpenter $620, banker $2,120. These profession budgets are game difficulty settings, not historical class income estimates.', '',
         'Each policy group reuses seeds 0–19 (baseline/adaptive) or 0–9 (hunting study). These are paired, correlated scenarios, not 2,700 independent human players or an estimate of emigrant mortality. All scenarios use classic mode. Poor outcomes are retained rather than asserted to be test failures.', '',
         '## Starting-outfit comparison', '',
         'Each cell covers 60 journeys (20 seeds × three departure months). Arrived means at least one traveler reached Oregon, not that all five survived. Adaptive holds $10 when buying food, hunts below 90 lb instead of 45 lb, and sells supplies if blocked at the toll. Both use steady pace with rest, unless the profile says otherwise.', '',
         '| Strategy | Profession | Baseline arrived | Adaptive arrived | Baseline policy blocks | Adaptive policy blocks |',
         '| --- | --- | ---: | ---: | ---: | ---: |']
for profile in ('cautious', 'meager', 'grueling', 'no_hunting'):
    for profession in ('farmer', 'carpenter', 'banker'):
        groups = [[r for r in data['runs'] if r['profile'] == profile and r['profession'] == profession] for data in datasets[:2]]
        counts = [Counter(r['outcome'] for r in group) for group in groups]
        lines.append(f"| {profile} | {profession} | {counts[0]['arrived']}/60 | {counts[1]['arrived']}/60 | {counts[0]['policy_blocked']} | {counts[1]['policy_blocked']} |")
lines += ['',
          '- Cautious means filling rations, steady pace, rest below 70 average condition or above 50 fatigue when fed; meager uses two rather than three pounds/person/day. Grueling means fastest pace and no voluntary rest, not a sensible mixed-pace strategy.',
          '- Every farmer journey failed under these policies, including hunting. This establishes a serious starting-economy/food-loop problem to investigate; it does not prove every outfit or strategy is unwinnable.',
          '- Baseline carpenter blocks were at the Barlow toll. Selling supplies through the existing trade menu removes those blocks. They were policy failures, not game deaths or proof of a softlock.',
          '- Unbroken grueling travel killed all parties, typically in about a month. The daily exhaustion rule is strong; temporary bursts with recovery remain untested.',
          '- Wealth lets bankers buy their way through without hunting. Hunting is currently optional for rich parties and insufficient to rescue these poor parties.', '',
          '## Hunting, individual care, and rations', '',
          'The second study adds 1,260 journeys: three professions × three months × ten seeds × fourteen strategies. Twelve hunting strategies combine two ration sizes, 35/65/90% center-aim probability and hunt thresholds of 45/90 lb; two otherwise matching strategies never hunt. The hunter uses actual visible targets, cover, ammunition, reload, flight/escape and 30-second clock, chooses the largest visible yield, and attempts movement along the lower clearing when obstructed. It has no route-finding or human reaction delays. A miss aims at (0,0). These percentages are scripted aiming assumptions, not measured hit rates.', '',
          'This study watches the worst living individual rather than party-average condition. Every three days at most, it offers a kit or paid care for a condition below 55 internal health, if affordable with the $10 reserve. Rations, remaining survivors, illness progression, weather, team recovery, food costs and spoilage stay active. Healthcare changes the strategy, so compare hunting variants within this study rather than attributing differences from the first batch solely to hunting.', '',
          'Each row below covers 30 journeys. Meat and spoilage are mean pounds per journey, including failures. Spoilage records only fresh hunted food. Death causes are the engine’s final damaging cause, not a complete causal diagnosis.', '',
          '| Profession | Strategy | Arrived | Mean days until end | Hunts | Meat carried | Spoiled | Mean care actions |',
          '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for profession in ('farmer', 'carpenter', 'banker'):
    for profile in ('no_hunt_r2','hunt_65_r2_below45','hunt_65_r2_below90','no_hunt_r3','hunt_65_r3_below45','hunt_65_r3_below90'):
        group = [r for r in datasets[2]['runs'] if r['profession'] == profession and r['profile'] == profile]
        arrived = sum(r['outcome'] == 'arrived' for r in group)
        values = [mean(r[key] for r in group) for key in ('days','hunts','meat_carried','spoiled_lb','care')]
        lines.append(f"| {profession} | {profile} | {arrived}/30 | " + ' | '.join(f'{value:.1f}' for value in values) + ' |')
lines += ['',
          '`r2` means two lb/person/day; `r3` means three. `below45/90` is total food stock before the outing, not a fresh-meat target.', '',
          'The main hunting issue is usable food over time, not merely accuracy. For example, the 65%-aim, filling-ration farmer policy hunting below 90 lb brought back roughly 1,113 lb over a journey but spoiled roughly 764 lb. It still lost every party. Hunting extends some journeys while consuming additional days and meals. Improving aim alone did not produce a farmer arrival at any tested skill level. Largest-animal-first targeting also wastes meat; preservation, smaller selective kills, return limits and food demand need to be considered together.', '',
          'The fresh ledger already feeds hunted meat before staples. The two-day fresh window and 100-lb return cap are authored abstractions. No smoking/drying/salting action currently exists. Do not use this experiment as evidence for historical shelf life or historical hunting success.', '',
          '## Mechanics coverage and limits', '',
          '| Mechanic | Evidence in this pass | Remaining question |',
          '| --- | --- | --- |',
          '| Profession, starting shop, cash, freight | Same valid suggested cart for all budgets; actual public departure; focused provisions tests | Alternative affordable outfits, lighter teams and freight choices |',
          '| Food, rations, starvation, spoilage | Whole journeys with partial-food penalties, fresh-first ledger and survivor-sized meals; provisions tests | Preservation and period food composition; reasonable low-budget survival |',
          '| Hunting | Matched no-hunt controls, three aim levels, two timing thresholds, two rations; live cover/motion/reload/escape; 218 focused hunting checks | Human play, varied shot selection, smarter movement, additional animals |',
          '| Individual illness, injury, death, care | Worst-individual policy, paid/kit care when affordable, actual illness rolls and deaths; 30 health checks and survival scenarios | Care prioritization, serious-case treatment cost, disease-specific calibration |',
          '| Weather, clothing, exposure | Daily weather and season remain active; focused heavy-rain/blizzard/clothing scenarios | Historical regional climate and winter mountain hazards; no reconstructed 1848 weather |',
          '| Oxen, fatigue, load, terrain, rest | Live travel modifiers and recovery; zero-team replacement policy; controlled survival cases | Mixed pace, smaller-team purchases, realistic grazing availability |',
          '| Repairs and repeatable events | Live encounters; focused suite explicitly resolves every branch of all 17 repeatable event definitions with adequate resources | Narrative/historical review; mechanical presence does not authenticate an encounter |',
          '| Rivers and mishap history | Ferry if affordable; otherwise high-water float/low-water ford; real clamped losses; focused motion/crossing checks | Waiting strategies, site hydrology, drowning, additional route methods |',
          '| Trading, Barlow toll, Laurel descent | Actual transactions with days/meals, cash reserve and toll sale recovery; safe descent in journeys; forced risky descent checks | Better resupply targets and prices, preservation economy; hurry decision policy |',
          '| Route, time, arrival | All 36 stops reachable; natural full-road journeys; no routing loops or 365-day limits in archived batches | Northern shortcuts, Walla Walla and Columbia transport remain unimplemented |',
          '| Save/load, old-save migration | 149 save checks plus full-trail replay comparisons | Human interruption/recovery and final release testing |',
          '| Deaths, grave writing and later reading | 11 grave checks; health deaths occur naturally in journeys | No UI playthrough or human memorial-writing assessment in this pass |',
          '| UI, art, animation | Existing UI/art/motion integration checks rerun | Headless success cannot establish readability, timing, audio or enjoyment |',
          '| Absurd mode | Existing seeded simulation checks rerun | Intentionally excluded from classic survival tuning |', '',
          'The full existing suite passed: 3,185 simulation; 85 route; 167 art; zero UI failures; 46 headless motion; 30 health; 122 survival; 218 hunting; 15 provisions; 149 saves; 11 graves; 1,627 full-trail checks. The experiment additionally checks departure validity, nonnegative food/cash/party size and engine error state; all three batches reported zero such errors. These are selected invariants, not proof of complete correctness.', '',
          '## Next balance work', '',
          '1. Make a defensible low-budget food/resupply strategy viable. Review the $380 suggested cart, ongoing food costs, hunting days/returns and preservation together; avoid merely multiplying meat yields.',
          '2. Compare targeted care and rest against food/cash spent, using individual outcomes and survivors, not arrival alone.',
          '3. Test temporary hard pace with recovery, alternative legal outfits and regional/late-season hazards. Keep rich no-hunt runs as a control.',
          '4. Then play the interface. Automated aiming and event selection cannot determine whether these choices are enjoyable or clear.', '',
          '## Reproduction and raw results', '',
          'From the project folder, use the bundled Godot console executable with `--headless --path . --script tests/full_trail_balance.gd`. Repeat with `-- --adaptive` and `-- --hunting`. Use a project-local APPDATA as in `test.ps1`. Then run `tests/write_full_trail_balance.py` to rebuild this summary. The experiment is intentionally separate from the regular regression suite: bad balance is evidence, not a reason to demand every simulated party survive.', '',
          '- [Baseline 720 journeys](full-trail-balance.json)',
          '- [Adaptive 720 journeys](full-trail-balance-adaptive.json)',
          '- [Hunting/care 1,260 journeys](full-trail-balance-hunting.json)', '',
          f"Rules signature: `{datasets[0]['rules_signature']}`. No simulation rules, historical assertions, prices or player saves were changed by this pass.", '']
(ROOT / 'docs' / 'FULL_TRAIL_BALANCE.md').write_text('\n'.join(lines), encoding='utf-8')
print('Wrote full-trail mechanics and balance report for 2,700 journeys.')
