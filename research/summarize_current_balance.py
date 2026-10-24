"""Summarize frozen current-mechanics shards. Never pool different games/policies."""
import argparse, collections, datetime as dt, json, statistics
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('label');p.add_argument('--allow-errors',action='store_true');args=p.parse_args()
shards=[json.loads((root/'docs'/f'balance-{args.label}-{capital}.json').read_text(encoding='utf-8-sig')) for capital in ('farmer','carpenter','banker')]
for field in ('rules_signature','source_hashes','settings','months','rosters','strategies','seed_start','seed_count','rest_below'):
 if any(s[field]!=shards[0][field] for s in shards):raise SystemExit('Refusing to pool unmatched '+field)
rows=[r for s in shards for r in s['runs']];errors=[e for s in shards for e in s['errors']]
if errors and not args.allow_errors:raise SystemExit(f'{len(errors)} technical errors: this is not a clean balance sample')
def mean(xs):return round(statistics.mean(xs),3) if xs else None
def aggregate(group):
 arrivals=[r for r in group if r['outcome']=='arrived']
 return {'n':len(group),'arrived':len(arrivals),'original_intact':sum(r['original_present']==5 for r in arrivals),'current_full_party':sum(r['survivors']==5 for r in arrivals),'outcomes':dict(collections.Counter(r['outcome'] for r in group)),'deaths':sum(len(r['death_causes']) for r in group),'departures':sum(r['departures'] for r in group),'recruited':sum(r['recruited'] for r in group),'mean_elapsed_days':mean([r['days'] for r in group]),'arrival_days':{'mean':mean([r['days'] for r in arrivals]),'min':min((r['days'] for r in arrivals),default=None),'max':max((r['days'] for r in arrivals),default=None)},'mean_underfed_days':mean([r['audit']['underfed_days'] for r in group]),'mean_scurvy_person_days':mean([r['audit']['scurvy_person_days'] for r in group]),'scurvy_cases':sum(r['scurvy_cases'] for r in group),'mean_hunts':mean([r['counts']['hunts'] for r in group]),'mean_preservations':mean([r['counts']['preservations'] for r in group]),'mean_forages':mean([r['counts'].get('forages',0) for r in group]),'mean_counter_visits':mean([r['counts'].get('counter_visits',0) for r in group]),'mean_vitamin_days':mean([r['audit']['vitamin_days'] for r in group]),'wages_paid_cents':sum(r['wages_paid_cents'] for r in group),'wages_owed_cents':sum(r['wages_owed_cents'] for r in group),'wanted_encounters':sum(r['wanted_encounters'] for r in group),'sentences':dict(collections.Counter(s for r in group for s in r['sentences'])),'death_causes':dict(collections.Counter(c for r in group for c in r['death_causes']))}
result={k:shards[0][k] for k in ('rules_signature','source_hashes','settings','seed_start','seed_count','months','rosters','strategies','rest_below')}
result.update(label=args.label,total=aggregate(rows),errors=errors)
for dimension in ('profession','month','roster','strategy'):
 result['by_'+dimension]={str(v):aggregate([r for r in rows if r[dimension]==v]) for v in sorted({r[dimension] for r in rows})}
result['timely_ordinary']={c:{s:aggregate([r for r in rows if r['profession']==c and r['month']==5 and r['roster']=='ordinary' and r['strategy']==s]) for s in shards[0]['strategies']} for c in ('farmer','carpenter','banker')}
result['cells']={'|'.join(map(str,key)):aggregate([r for r in rows if (r['profession'],r['month'],r['roster'],r['strategy'])==key]) for key in sorted({(r['profession'],r['month'],r['roster'],r['strategy']) for r in rows})}
result['seed_cluster_arrivals']={str(seed):aggregate([r for r in rows if r['seed']==seed]) for seed in sorted({r['seed'] for r in rows})}
paired={}
for strategy in shards[0]['strategies']:
 if strategy=='legacy':continue
 indexed={(r['profession'],r['month'],r['roster'],r['seed']):r for r in rows if r['strategy']==strategy}
 both=[(r,indexed[(r['profession'],r['month'],r['roster'],r['seed'])]) for r in rows if r['strategy']=='legacy']
 paired[strategy]={'pairs':len(both),'current_only_arrived':sum(a['outcome']!='arrived' and b['outcome']=='arrived' for a,b in both),'legacy_only_arrived':sum(a['outcome']=='arrived' and b['outcome']!='arrived' for a,b in both),'both_arrived':sum(a['outcome']=='arrived' and b['outcome']=='arrived' for a,b in both)}
result['paired_to_legacy']=paired
output=root/'docs'/f'balance-{args.label}-summary.json'
if output.exists():raise SystemExit('Refusing to overwrite archived summary')
output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'label':args.label,'total':result['total'],'timely_ordinary':result['timely_ordinary'],'errors':errors},indent=2))
