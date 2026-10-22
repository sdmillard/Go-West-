"""Summarize matched final-rule journeys, preserving earlier experiment archives."""
from pathlib import Path
import json
import re
from statistics import mean

root = Path(__file__).resolve().parents[1]
names = ['economy-v2-preservation.json', 'economy-v2-holdout-preservation.json']
data = [json.loads((root / 'docs' / name).read_text(encoding='utf-8')) for name in names]
assert all(len(d['runs']) == 1800 and not d['errors'] for d in data)
assert data[0]['rules_signature'] == data[1]['rules_signature']
assert [d['seed_range'] for d in data] == [[0, 19], [20, 39]]

lines = ['# Economy, hunting and preservation balance', '',
         'October 22, 2026. This pass implements affordable starting staples, revised trail funds, drying and optional salt-assisted preservation. It preserves the earlier [2,700-journey diagnosis](FULL_TRAIL_BALANCE.md) as an archived comparison.', '',
         '## What the sources establish', '',
         '- The inspected 1978 BASIC listing uses a $700 post-wagon spending budget and food expenditure units, not pounds. Labels 2660–2690 reward a skilled hunt with 52–58 units; labels 2750–2860 consume 13/18/23 per nominal fortnight. Successful hunting therefore covers roughly two to four turns. No per-batch meat-expiry ledger appears in that listing. These formulas cannot be copied directly into a daily pound-based game.',
         '- The supplied 1985 manual gives banker/carpenter/farmer budgets of $2,500/$1,000/$400 and says hunting costs a day. Those are classic difficulty settings, not evidence for the real wealth of those occupations. [Bouchard](https://www.philipbouchard.com/oregon-trail/hunting.html) explains the 100-lb return cap as a hauling/wastefulness decision; it remains in our game.',
         '- [Palmer’s 1847 guide](https://www.gutenberg.org/cache/epub/46906/pg46906-images.html#NECESSARY_OUTFITS_FOR_EMIGRANTS), pp258–262 of the1906 reprint, recommends substantial provisions. Five weighed staple categories total340 lb/adult, before other foods; salt also appears in the list. It quotes Hall/Boise emergency flour at $20/100 lb. These are source context, not a price for our entire mixed-food pool.',
         '- The [BLM education guide](https://www.blm.gov/sites/blm.gov/files/learn_interp_nhotic_edguide.pdf), PDFp24, contrasts $2/100 lb Independence flour with $20 Boise flour. PDFp29 includes a later recollection of dried buffalo provisions for an1845 journey. [Marcy’s1859 guide](https://www.gutenberg.org/cache/epub/23066/pg23066-images.html), chapterV, describes preservation by drying without requiring salt. That later source supports plausibility, not exact1848 labor or storage parameters.',
         '- [NPS](https://www.nps.gov/articles/000/traveling-emigrant-trails.htm) gives an1850 outfit/year-of-support estimate of $800–1,200. It includes more than our post-wagon cash and postdates1848. It supplies broad scale only. None of these references authenticates exact occupation budgets, our6-cent blended food price,10-cent salt price or preservation yields.', '',
         'Provenance, local source hashes and date limits are in [the source ledger](../research/ECONOMY_PRESERVATION_SOURCES.json). No modern inflation conversion is used for in-game dollars.', '',
         '## Shipped economy', '',
         '| Item | Before | Now |', '| --- | ---: | ---: |',
         '| Farmer trail funds | $400 | $600 |',
         '| Carpenter trail funds | $1,000 | $900 |',
         '| Banker trail funds | $2,500 | $1,400 |',
         '| Opening mixed staples | $0.20/lb | $0.06/lb |',
         '| Suggested food | 800 lb | 1,700 lb |',
         '| Suggested care kits | 0 | 2 |',
         '| Suggested salt | unavailable | 10 lb at $0.10/lb |',
         '| Suggested cart total | $380 | $333 |',
         '| Farmer cash after that cart | $20 | $267 |', '',
         'Wagon and basic household gear are already owned; the store now says so. The budgets are authored cash-on-hand difficulty levels, not annual wages or full historical outfit prices. The blended staple price is deliberately above the cited2-cent flour example and below mountain scarcity prices. Other old prices are not certified as a reconstructed market. Hall/Boise remain $40/200-lb lots, other bulk posts $60/200lb, passing wagons $15/50lb; all transactions still cost a day and meals. Salt resupply is $2/10lb with $0.50 resale, also a day. No profitable buy/sell loop is introduced.', '',
         'The suggested cart weighs2,359 lb against the2,500-lb guideline; bulk food adds real load and slows progress. It gives113 upper-bound filling-ration party-days for five adult-equivalent travelers, or170 at meager rations, before losses/spoilage/delays. It is a large departure reserve, not a whole-road guarantee.', '',
         '## Preservation in play', '',
         'After hunting, open **Options → Provisions / Cargo**. The menu previews the batch, retained meals, salt and one-day cost. Drying works without salt. Salt is an optional improvement, purchased at departure or through trading; it is real carried inventory.', '',
         '| Authored rule | Dry | Salt-assisted dry |',
         '| --- | ---: | ---: |',
         '| Processing | One camp day, up to100 lb after meals | Same |',
         '| Retained food value | 80% | 90% |',
         '| Salt consumed | None | Rounded up from5% of fresh input |',
         '| Storage after processing day | Up to21 trail days | Up to30 trail days |',
         '| Physical dried mass | 35% of retained ration-equivalent weight | Same |', '',
         'Those numbers are explicit game tuning, not a period recipe, food-safety instruction or measured nutrition model. The day’s weather, meals, fatigue and illness still advance. Fresh meat that expires that morning cannot be rescued. Work does not grant people a free rest day; livestock get their normal non-travel recovery. There is no fuel inventory or weather-specific drying failure yet. Preservation does not recover meat left at the hunting site or bypass the100-lb carry limit.', '',
         'Food now displays **LB EQ**: staple-equivalent ration pounds. Removing water reduces physical cargo without throwing away the same fraction of meal value. Processing loss separately reduces food value. Example: with100 fresh pounds and five people on filling rations, the processing day eats15;85 remain. Drying retains68 ration-lb weighing23.8 actual cargo pounds; salt-assisted drying spends5 lb salt and retains76 ration-lb weighing26.6lb. The rest of the food pool is unchanged. This avoids charging travelers three physical pounds of dried meat for the same meals as three pounds of fresh provisions.', '',
         'Sooner-expiring tracked food is consumed first. Both fresh and preserved leftovers can spoil. Discards, losses, salt transactions and processing are journaled. The menu separates staples, fresh food, preserved food and salt. New saves retain batch type/expiry and cargo behavior. Verified pre-update saves retain cash, supplies, people, time and RNG, with zero salt added; existing pending quotes are retained, future offers use current prices.', '',
         '## Matched journey results', '',
         '3,600 final-rule journeys: ten strategies × three professions × March/May/August departures × forty seeds. Seeds0–19 were the development sample;20–39 were checked afterward without retuning. No-hunt is a control; each aiming level has fresh-only, drying and salt-assisted variants. All use the same suggested cart, steady pace, public engine actions, actual hunting geometry, care/rest and resupply. The mixed-ration policy eats2 lb/person/day when well and3 if any living traveler has a condition or health below80 internally. It rests below70 worst individual health or above50 fatigue when fed. Aim is scripted35/65/90% center aiming, not a measured human accuracy.', '',
         'Preservation is attempted before other camp tasks when a usable fresh batch remains. Salt mode attempts resupply before hunting if under5 lb, with at least$12 cash, and otherwise falls back to unsalted drying. Repeated hunting, preservation, buying and care all cost their real days/meals. Scripted routes and reused seeds make these paired comparisons, not independent historical mortality trials.', '',
         'Farmer results below count **at least one survivor arriving**; intact means all five arrive. Every cell covers60 journeys per sample, across the three months.', '',
         '| Strategy | Seeds0–19 arrivals | Seeds20–39 arrivals | Combined arrivals | Combined intact | Mean days among arrivals |',
         '| --- | ---: | ---: | ---: | ---: | ---: |']
for profile in ['no_hunt','hunt_35_fresh','hunt_35_dry','hunt_35_salt','hunt_65_fresh','hunt_65_dry','hunt_65_salt','hunt_90_fresh','hunt_90_dry','hunt_90_salt']:
    groups = [[r for r in d['runs'] if r['profession']=='farmer' and r['profile']==profile] for d in data]
    arrivals = [[r for r in group if r['outcome']=='arrived'] for group in groups]
    joined = sum(arrivals, [])
    lines.append(f"| {profile} | {len(arrivals[0])}/60 | {len(arrivals[1])}/60 | {len(joined)}/120 | {sum(r['survivors']==5 for r in joined)}/120 | {mean(r['days'] for r in joined):.1f} |")
lines += ['', 'Across both samples at65%-aim, preserving meat produces a viable farmer policy: fresh-only21/120, drying96/120, salt-assisted102/120 arrivals. Salt does not guarantee a better result in each individual journey: its purchase days, cash and stock compete with other needs. No-hunt also remains winnable at32/120. These are tested strategies, not optimal play.', '',
          'Affluent parties usually resupply before they need to hunt, and remain easier. The farmer preservation strategy often takes roughly eight to nine months and loses companions. This proves a playable survival path under the present rules; it is not an historically calibrated duration or casualty distribution. Regional winter dangers, shorter/less wasteful policies and human hunting remain important follow-up work.', '',
          '## Checks and reproduction', '',
          '- Full regression suite passes after the feature, including simulation, route, art, UI, motion, health, survival, hunting, provisions, save replay/migration, graves and full-road journeys. The new preservation suite has48 passing checks, including actual UI button use, store-row geometry, salt resupply, mass/food accounting, expiry, rejected actions, save continuation and old-save migration.',
          '- Both1,800-journey samples report zero selected invariant/setup errors. This does not turn a simulated loss into a software failure or certify all mechanics/history.',
          '- Rendered store and preservation controls were inspected at native resolution. No human playtest is claimed.', '',
          'Use the bundled Godot console with `--headless --path . --script tests/full_trail_balance.gd -- --preservation --label=economy-v2`; repeat with `--seed-start=20 --label=economy-v2-holdout`. Set project-local APPDATA as in `test.ps1`. Run `tests/write_economy_report.py` to regenerate this report. Keep earlier raw archives rather than overwriting them.', '',
          '- [Development1,800 journeys](economy-v2-preservation.json)',
          '- [Held-out1,800 journeys](economy-v2-holdout-preservation.json)',
          '- [Rendered store](economy-store.png)',
          '- [Preservation choices](preservation-options.png)', '',
          f"Rules signature: `{data[0]['rules_signature']}`.", '']
report = '\n'.join(lines).replace('PDFp','PDF p').replace('chapterV','chapter V')
# Keep file targets, code, fingerprints and strategy identifiers verbatim.
parts = re.split(r'(`[^`]*`|\]\([^)]+\)|\| hunt_[^|]+\|)', report)
for index in range(0,len(parts),2):
    parts[index] = re.sub(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])',' ',parts[index])
(root/'docs/ECONOMY_AND_PRESERVATION.md').write_text(''.join(parts),encoding='utf-8')
print('Wrote final-rule economy/preservation report for 3,600 journeys.')
