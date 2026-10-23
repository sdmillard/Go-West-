"""Summarize archived public-action campaign shards without changing game rules."""
import collections
import json
import statistics
import sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
label=sys.argv[1]
shards=[json.loads((root/'docs'/f'balance-{label}-{p}.json').read_text()) for p in ['farmer','carpenter','banker']]
if len({s['rules_signature'] for s in shards})!=1 or any(s['source_hashes']!=shards[0]['source_hashes'] for s in shards):
    raise SystemExit('Refusing to pool different rule or source versions')
rows=[r for s in shards for r in s['runs']]
errors=[e for s in shards for e in s['errors']]
def aggregate(group):
    arrived=[r for r in group if r['outcome']=='arrived']
    return {'n':len(group),'arrived':len(arrived),'intact':sum(r['survivors']==5 for r in arrived),'outcomes':dict(collections.Counter(r['outcome'] for r in group)),'deaths':sum(len(r['death_causes']) for r in group),'departures':sum(r['departures'] for r in group),'captured':sum(any(i[2] in ['captured','surrendered'] for i in r['incidents']) for r in group),'mean_days':round(statistics.mean(r['days'] for r in group),2),'mean_empty_food_action_days':round(statistics.mean(r['counts']['empty_food_days'] for r in group),2),'mean_hunts':round(statistics.mean(r['counts']['hunts'] for r in group),2),'wages_paid_cents':sum(r['wages_paid_cents'] for r in group),'wages_owed_cents':sum(r['wages_owed_cents'] for r in group),'death_causes':dict(collections.Counter(c for r in group for c in r['death_causes']))}
result={'label':label,'rules_signature':shards[0]['rules_signature'],'source_hashes':shards[0]['source_hashes'],'seed_start':shards[0]['seed_start'],'seed_count':shards[0]['seed_count'],'total':aggregate(rows),'errors':errors}
for dimension in ['profession','month','roster','strategy']:
    result['by_'+dimension]={str(v):aggregate([r for r in rows if r[dimension]==v]) for v in sorted({r[dimension] for r in rows})}
result['lawful_by_capital']={p:aggregate([r for r in rows if r['profession']==p and r['strategy'] in ['dry','salt']]) for p in ['farmer','carpenter','banker']}
result['timely_ordinary_lawful']={p:aggregate([r for r in rows if r['profession']==p and r['month']==5 and r['roster']=='ordinary' and r['strategy'] in ['dry','salt']]) for p in ['farmer','carpenter','banker']}
output=root/'docs'/(sys.argv[2] if len(sys.argv)>2 else f'balance-{label}-summary.json')
if output.exists():raise SystemExit('Refusing to overwrite archived summary')
output.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'total':result['total'],'lawful_by_capital':result['lawful_by_capital'],'timely_ordinary_lawful':result['timely_ordinary_lawful'],'errors':errors},indent=2))
