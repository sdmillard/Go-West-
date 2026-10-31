"""Verify and summarize the actual-engine dog usefulness archive. No game-rule changes."""
import collections, hashlib, json, math
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
raw_path=Path(sys.argv[1]) if len(sys.argv)>1 else root/'.tools/dog-usefulness-03.json'
out_path=Path(sys.argv[2]) if len(sys.argv)>2 else root/'docs/dog-usefulness-results-03.json'
x=json.loads(raw_path.read_text(encoding='utf-8'))
assert x['errors']==[] and x['settings']['version']==3
assert x['settings']['journey_wait_seconds']==0
assert len(x['controlled'])==800 and len(x['journeys'])==96
for path,wanted in x['sources'].items():
 actual=hashlib.sha256((root/path).read_text(encoding='utf-8').replace('\r','').encode()).hexdigest()
 assert actual==wanted, f'Changed audit source: {path}'
keys=set()
for r in x['controlled']:
 key=(r['seed'],r['region'],r['wait'],r['arm'])
 assert key not in keys;keys.add(key)
 assert r['seed'] in range(790000,790040)
 assert r['day']==1 and r['hunts']==1
 assert all(math.isfinite(float(r[k])) for k in ['food_units','dog_food_units','raw_meat_lb'])
for seed in range(790000,790040):
 for region in ['woodland','plains','highcountry','sagebrush','forest']:
  for wait in [False,True]:
   for arm in ['none','hunt']:assert (seed,region,wait,arm) in keys
result={'version':3,'raw_sha256':hashlib.sha256(raw_path.read_bytes()).hexdigest(),'rules':x['rules'],'settings':x['settings'],'sources':x['sources'],'controlled':{},'journeys':{},'profession_arrivals':{},'errors':[]}
for wait in [False,True]:
 pairs=collections.defaultdict(dict)
 for r in x['controlled']:
  if r['wait']==wait:pairs[r['seed'],r['region']][r['arm']]=r
 deltas=[p['hunt']['food_units']-p['none']['food_units'] for p in pairs.values()]
 result['controlled']['wait8' if wait else 'quick']={'pairs':len(pairs),'net_remaining_food_delta_units':round(sum(deltas),6),'mean_net_food_delta_units':round(sum(deltas)/len(pairs),6),'positive_pairs':sum(v>1e-6 for v in deltas),'raw_meat_gain_lb':sum(p['hunt']['raw_meat_lb']-p['none']['raw_meat_lb'] for p in pairs.values()),'rabbit_meat_lb':sum(p['hunt']['rabbit_lb'] for p in pairs.values()),'empty_searches_helped':sum(p['hunt']['located_game'] for p in pairs.values()),'dog_food_units':round(sum(p['hunt']['dog_food_units'] for p in pairs.values()),6),'note':'Net remaining inventory already charges dog meals; do not subtract dog_food_units again.'}
jkeys={(r['profession'],r['month'],r['seed'],r['arm']) for r in x['journeys']}
assert len(jkeys)==96
for profession in ['farmer','banker']:
 for month in [4,5]:
  for seed in range(791000,791008):
   for arm in ['none','hunt','watch']:assert (profession,month,seed,arm) in jkeys
for arm in ['none','hunt','watch']:
 rows=[r for r in x['journeys'] if r['arm']==arm]
 assert len(rows)==32 and all(r['save_ok'] for r in rows)
 states=dict(collections.Counter(r['status'] for r in rows))
 totals={k:round(sum(r[k] for r in rows),6) for k in ['day','dog_food_units','dog_days','rabbit_lb','located_game','warnings','horse_thieves','hunts','assisted_hunts','fit_hunt_days','fit_watch_days','dog_crossing_losses','dog_injuries','mounts','people']}
 result['journeys'][arm]={'n':32,'outcomes':states,'totals':totals,'dogs_alive_at_end':sum(r['dog_alive'] for r in rows),'mean_dog_food_units':round(totals['dog_food_units']/32,6),'theft_encounters_per_100_journey_days':round(totals['horse_thieves']/totals['day']*100,6)}
 for profession in ['farmer','banker']:
  rs=[r for r in rows if r['profession']==profession]
  result['profession_arrivals'][profession+'_'+arm]={'n':len(rs),'arrived':sum(r['status']=='arrived' for r in rs)}
result['limits']=['One declared automated policy; not optimal play or a general survival verdict.','Same eight seed clusters reused across professions and months; 96 rows are not 96 independent trials.','Trips diverge in duration, mortality, supplies and event eligibility; pooled theft totals are descriptive.','Main journey hunts use immediate shots with 65% aim; no artificial dog wait.','No dog-specific extra rest days, replacement purchases, detached dog outings, skin sales or zero-ammunition dog-only hunting strategy.','Human travel/rest/resupply/care/foraging/preservation rules are unchanged; no balance tuning.','Controlled cells share the same forty seed clusters across five regions; report as matched cases, not independent mortality samples.','Archived versions01/02 and pilot are excluded from primary totals.']
out_path.write_bytes((json.dumps(result,indent=2)+'\n').encode())
print('PASS dog usefulness: 800 controlled cells, 96 journeys, paired coverage, source hashes and saves verified')
for arm,v in result['journeys'].items():print(arm,v['outcomes'],v['totals']['dog_food_units'],v['totals']['horse_thieves'])
