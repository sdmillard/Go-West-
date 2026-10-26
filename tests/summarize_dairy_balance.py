"""Validate the complete frozen calibrated-dairy comparison before publishing outcomes."""
from pathlib import Path
import collections,hashlib,itertools,json,re,statistics,subprocess
from summarize_feeding_comparison import summarize as base_summary, paired, audit
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'.tools'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def average(xs):return round(statistics.mean(xs),3) if xs else None
def summarize(rows):
 s=base_summary(rows)
 s['mean_road_feed_cost_dollars']={kind:average([r['dairy_balance']['feed_spent_cents'][kind]/100 for r in rows]) for kind in ['poultry_feed','livestock_fodder']}
 s['condition']={}
 for kind in ['dairy_cows','goats','hens']:
  days=sum(audit(r)['animal_days'].get(kind,0) for r in rows)
  points=sum(audit(r)['condition_points'].get(kind,0) for r in rows)
  poor=sum(audit(r)['poor_animal_days'].get(kind,0) for r in rows)
  s['condition'][kind]={'animal_days':days,'mean_alive_condition':round(points/days,3) if days else None,'poor_animal_day_pct':round(100*poor/days,3) if days else None}
 s['named_grazing_visits']=sum(len(r['dairy_balance']['grazing_activities']) for r in rows)
 s['mean_milk_lb_generated_rounded_daily']=average([audit(r)['milk_lb'] for r in rows])
 s['mean_eggs_generated']=average([audit(r)['eggs'] for r in rows])

 hunts=sum(r['counts']['hunts'] for r in rows)
 s['mean_spoilage_food_units']=average([r['spoilage_food_units'] for r in rows])
 s['mean_preservations']=average([r['counts'].get('preservations',0) for r in rows])
 s['mean_companion_drying_batches']=average([r['camp_work']['drying_batches'] for r in rows])
 s['mean_companion_food_retained']=average([r['camp_work']['food_retained'] for r in rows])
 s['mean_proactive_dispatches']=average([r['counts'].get('proactive_dispatches',0) for r in rows])
 s['empty_hunt_pct']=round(100*sum(r['counts'].get('empty_hunts',0) for r in rows)/hunts,3) if hunts else None
 s['legacy_hunt_packed_units_per_attempt']=round(sum(r['counts'].get('meat_food_units',0) for r in rows)/hunts,3) if hunts else None
 s['legacy_hunt_meal_units_per_attempt']=round(sum(r['counts'].get('field_meal_units',0) for r in rows)/hunts,3) if hunts else None
 s['mean_opening_cash']=average([r['opening_cash'] for r in rows])
 s['mean_produce_units_bought']=average([sum(max(0,p['cart'].get('produce',0))+max(0,p['cart'].get('dried_produce',0)) for p in r['livestock']['purchases']) for r in rows])
 s['dairy_units_eaten_per_herd_day']=round(sum(audit(r)['dairy_eaten'] for r in rows)/sum(audit(r)['herd_days'] for r in rows),6) if sum(audit(r)['herd_days'] for r in rows) else None
 return s

def main():
 m=read(T/'dairy-balance-manifest-02.json');entries=m['entries'];assert len(entries)==52 and len({e['label'] for e in entries})==52
 expected={(phase,version,outfit,arm,'fixed') for phase,version,outfit,arm in itertools.product(['development','confirmation'],['old','new'],['standard','lean'],['none','goats','cow','hens','mixed'])}
 expected|={(phase,'new',outfit,arm,'fodder') for phase,outfit,arm in itertools.product(['development','confirmation'],['standard','lean'],['goats','cow','mixed'])}
 assert {(e['phase'],e['runtime'],e['outfit'],e['arm'],e['feeding_policy']) for e in entries}==expected
 rows=[];frozen={};signatures={};archives=[]
 for e in entries:
  p=T/e['filename'];receipt=read(T/('receipt-'+e['label']+'.json'));assert sha(p)==receipt['sha256']
  origin=Path(receipt['origin'])
  if origin.exists():assert sha(origin)==receipt['sha256']
  d=read(p);assert not d['errors'] and len(d['runs'])==12
  assert d['runtime_label']==e['runtime'] and d['feeding_policy']==e['feeding_policy'] and d['livestock_arm']==e['arm'] and d['outfit_profile']==e['outfit']
  assert d['seed_start']==e['seed_start']==(475000 if e['phase']=='development' else 485000) and d['seeds']==6
  settings={'professions':['farmer'],'months':[5,7],'equipment':['shared'],'methods':['foot'],'pace':1,'reserve_meals':2,'player_accuracy':.65,'fishing_policy':'support','camp_work_policy':'support','motion_policy':'mobile','stock_policy':'aware','dairy_balance_version':1}
  for k,v in settings.items():assert d[k]==v,(e['label'],k)
  if e['runtime'] not in frozen:frozen[e['runtime']]=d['source_hashes'];signatures[e['runtime']]=d['rules_signature']
  assert frozen[e['runtime']]==d['source_hashes'] and signatures[e['runtime']]==d['rules_signature']
  assert {(r['month'],r['seed']) for r in d['runs']}==set(itertools.product([5,7],range(e['seed_start'],e['seed_start']+6)))
  for r in d['runs']:
   assert round(r['opening_cash']*100)+r['opening_cost_cents']==67500 and r['outfit'].get('livestock_fodder',0)==0
   assert abs(audit(r)['meal_requested']-audit(r)['meal_eaten']-audit(r)['meal_short'])<1e-5
   assert audit(r)['food_generated']+1e-5>=audit(r)['dairy_eaten']>=0
   assert r['counts'].get('fodder_lb_bought',0)==sum(p['cart'].get('livestock_fodder',0) for p in r['livestock']['purchases'])
   if e['feeding_policy']=='fixed':assert not r['counts'].get('fodder_lb_bought',0)
   if e['runtime']=='new':assert audit(r)['scraps_kcal']==0
   for kind in ['poultry_feed','livestock_fodder']:
    assert r['dairy_balance']['feed_spent_cents'][kind]==sum(p['feed'].get(kind,{}).get('cents',0) for p in r['dairy_balance']['feed_purchases'])
    assert sum(p['feed'].get(kind,{}).get('units',0) for p in r['dairy_balance']['feed_purchases'])==sum(max(0,p['cart'].get(kind,0)) for p in r['livestock']['purchases'])
   for kind,days in audit(r)['animal_days'].items():
    assert 0<=audit(r)['condition_points'][kind]<=100*days and 0<=audit(r)['poor_animal_days'].get(kind,0)<=days
   rows.append(dict(r,phase=e['phase'],runtime=e['runtime'],outfit_profile=e['outfit'],arm=e['arm'],feeding_policy=e['feeding_policy']))
  archives.append({'label':e['label'],'file':e['filename'],'sha256':receipt['sha256'],'original':str(origin.relative_to(ROOT)).replace('\\','/')})
 assert len(rows)==624
 # Independently tie all recorded sources back to frozen Git snapshots, allowing checkout newlines.
 for version,files in frozen.items():
  ref=m['old_instrumented'] if version=='old' else m['study_commit'];tree=ROOT/m['trees'][version]
  for name,digest in files.items():
   p=tree/name
   if p.exists():assert sha(p)==digest,(version,name)
   blob=subprocess.check_output(['git','show',ref+':'+name],cwd=ROOT);lf=blob.replace(b'\r\n',b'\n')
   variants=[blob,lf,lf.replace(b'\n',b'\r\n'),lf[:-1]+b'\r\n' if lf.endswith(b'\n') else lf]
   assert digest in {hashlib.sha256(b).hexdigest() for b in variants},(version,name,'snapshot hash')
 common=['feeding_compare_stock.gd','feeding_compare_observer.gd','feeding_compare_campaign.gd','test_feeding_comparison.gd','dairy_balance_stock.gd','dairy_balance_observer.gd','dairy_balance_campaign.gd','test_dairy_balance.gd','livestock_balance_campaign.gd','fishing_campaign.gd','mobile_camp_campaign.gd','coordinated_camp_campaign.gd','hunting_balance_campaign.gd','current_journey_policy.gd']
 for n in common:assert frozen['old']['tests/'+n]==frozen['new']['tests/'+n],n
 for version,ref in [('old',m['old_gameplay']),('new',m['new_gameplay'])]:
  code_ref=m['old_instrumented'] if version=='old' else m['study_commit']
  for n in subprocess.check_output(['git','ls-tree','-r','--name-only',ref,'simulation','data'],cwd=ROOT,text=True).splitlines():
   assert subprocess.check_output(['git','show',ref+':'+n],cwd=ROOT).replace(b'\r',b'')==subprocess.check_output(['git','show',code_ref+':'+n],cwd=ROOT).replace(b'\r',b''),n
 def select(**terms):return [r for r in rows if all(r[k]==v for k,v in terms.items())]
 controls=0
 for phase,outfit in itertools.product(['development','confirmation'],['standard','lean']):
  a=select(phase=phase,outfit_profile=outfit,arm='none',runtime='old');b=select(phase=phase,outfit_profile=outfit,arm='none',runtime='new')
  keyed={(r['month'],r['seed']):r for r in b}
  for x in a:
   y=keyed[x['month'],x['seed']]
   for k in ['outcome','days','miles','original_present','original_survived','cash','food','counts','audit','field','camp_work','camp_forage','motion','route','curve']:
    assert x[k]==y[k],('no-stock',phase,outfit,x['seed'],k)
   controls+=1
 # Matched old/new and secondary initial resources; no policy gets an opening grant.
 for phase in ['development','confirmation']:
  for arm in ['none','goats','cow','hens','mixed']:
   left=select(phase=phase,arm=arm,runtime='old');right=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed')
   keyed={(r['outfit_profile'],r['month'],r['seed']):r for r in right}
   for x in left:
    y=keyed[x['outfit_profile'],x['month'],x['seed']]
    for k in ['outfit','opening_cash','opening_cost_cents']:assert x[k]==y[k]
  for arm in ['goats','cow','mixed']:
   left=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed');right=select(phase=phase,arm=arm,runtime='new',feeding_policy='fodder')
   keyed={(r['outfit_profile'],r['month'],r['seed']):r for r in right}
   for x in left:
    y=keyed[x['outfit_profile'],x['month'],x['seed']]
    for k in ['outfit','opening_cash','opening_cost_cents']:assert x[k]==y[k]
 log=(T/'dairy-balance-publication-tests.log').read_text(encoding='utf-8')
 assert len(re.findall(r'^Godot Engine',log,re.M))==86 and not re.search(r'SCRIPT ERROR:|ERROR:|FAIL:',log)
 for version in ['old','new']:
  log=(T/f'dairy-balance-{version}-parity-01.log').read_text(encoding='utf-8')
  assert 'Dairy balance observers: 72 checks, 0 failures' in log and not re.search(r'ERROR:|FAIL:',log)
 result={'date':'2026-10-26','amendment':2,'excluded':'Manifest01 first three batches: missing output directories, no archived reports; all excluded.','protocol_commit':m['protocol_commit'],'study_commit':m['study_commit'],'old_gameplay':m['old_gameplay'],'old_instrumented':m['old_instrumented'],'new_gameplay':m['new_gameplay'],'reports':52,'journeys':624,'errors':0,'test_suites':86,'identical_no_stock_pairs':controls,'rules':signatures,'primary':{},'secondary':{},'cells':{},'archives':archives,'common_source_hashes':{n:frozen['old']['tests/'+n] for n in common},'limitations':['Six underlying seeds per phase repeat across settings; not 624 independent worlds.','Changes are a package, including sharing default, nutrient model and shared pasture; not an isolated energy-model effect.','Main-camp food excludes detached actors.','Alive-animal condition is exposure/survivor-weighted; inspect deaths and animal-days alongside it.','Paired travel times include only pairs where both arrive.','Ordinary policy retains earlier ration, cash-reserve and late-dispatch limitations; no new targeted grazing strategy.']}
 for phase in ['development','confirmation']:
  result['primary'][phase]={}
  for arm in ['none','goats','cow','hens','mixed']:
   a=select(phase=phase,arm=arm,runtime='old');b=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed')
   result['primary'][phase][arm]={'old':summarize(a),'new':summarize(b),'paired':paired(a,b)}
  result['secondary'][phase]={}
  for arm in ['goats','cow','mixed']:
   a=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed');b=select(phase=phase,arm=arm,runtime='new',feeding_policy='fodder')
   result['secondary'][phase][arm]={'fixed':summarize(a),'fodder':summarize(b),'paired':paired(a,b)}
  for version,policy,arm,outfit,month in itertools.product(['old','new'],['fixed','fodder'],['none','goats','cow','hens','mixed'],['standard','lean'],[5,7]):
   cell=select(phase=phase,runtime=version,feeding_policy=policy,arm=arm,outfit_profile=outfit,month=month)
   if cell:result['cells']['|'.join(map(str,[phase,version,policy,arm,outfit,month]))]=summarize(cell)
 p=ROOT/'docs/dairy-balance-summary-01.json';p.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 for phase in ['development','confirmation']:
  for arm,c in result['primary'][phase].items():print(phase,arm,'arrivals',c['old']['arrivals'],'->',c['new']['arrivals'],'dairy eaten',c['old']['mean_dairy_eaten'],'->',c['new']['mean_dairy_eaten'])
  for arm,c in result['secondary'][phase].items():print(phase,arm,'fixed/hay arrivals',c['fixed']['arrivals'],c['fodder']['arrivals'],'hay cost',c['fodder']['mean_road_feed_cost_dollars']['livestock_fodder'])
 print('Verified 624 journeys / 52 reports;',controls,'identical no-stock pairs; 86 suites; both observer parities.')
if __name__=='__main__':main()
