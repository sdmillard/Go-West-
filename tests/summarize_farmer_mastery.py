"""Validate every fresh mastery cohort; unsuccessful candidates remain in the report."""
from pathlib import Path
import datetime,hashlib,itertools,json,re,statistics,subprocess
from summarize_dairy_balance import summarize as dairy_summary
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'.tools'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def avg(xs):return round(statistics.mean(xs),3) if xs else None
def summarize(rows):
 s=dairy_summary(rows)
 arrivals=[r for r in rows if r['outcome']=='arrived']
 s['arrivals_three_or_more_originals']=sum(r['original_present']>=3 for r in arrivals)
 s['arrivals_four_or_more_originals']=sum(r['original_present']>=4 for r in arrivals)
 dates=[datetime.date(1848,r['month'],1)+datetime.timedelta(days=r['days']) for r in arrivals]
 s['arrivals_before_november']=sum(d<datetime.date(1848,11,1) for d in dates)
 s['arrival_dates']=[d.isoformat() for d in dates]
 s['spoilage_by_type']={k:avg([r['preservation_audit'][k] for r in rows]) for k in ['raw_meat_spoiled','dried_meat_spoiled','produce_spoiled','other_spoiled']}
 s['mean_all_drying_batches']=avg([r['preservation_audit']['drying_batches'] for r in rows])
 s['mean_all_drying_units_retained']=avg([r['preservation_audit']['units_retained'] for r in rows])
 s['mean_companion_drying_batches']=avg([r['camp_work']['drying_batches'] for r in rows])
 s['mean_leader_drying_batches']=avg([r['preservation_audit']['drying_batches']-r['camp_work']['drying_batches'] for r in rows])
 s['mean_leader_preservation_attempts']=avg([r['counts'].get('preservations',0)+r['counts'].get('expert_preservations',0) for r in rows])
 s['mean_wagon_hunts']=avg([r['counts'].get('method_wagon',0) for r in rows])
 s['mean_foot_hunts']=avg([r['counts'].get('method_foot',0) for r in rows])
 s['mean_stationary_days']=avg([r['motion']['stationary_days'] for r in rows])
 s['mean_hunting_days']=avg([r['counts']['hunts'] for r in rows])
 s['mean_rest_days']=avg([r['motion']['actions'].get('rest',0) for r in rows])
 s['mean_all_shopping_visits']=avg([r['counts'].get('counter_visits',0)+r['counts'].get('expert_counter_visits',0) for r in rows])
 return s

def paired(left,right):
 key=lambda r:(r['outfit_profile'],r['arm'],r['month'],r['seed'])
 a={key(r):r for r in left};b={key(r):r for r in right};assert a.keys()==b.keys()
 return {'pairs':len(a),'both_arrive':sum(a[k]['outcome']==b[k]['outcome']=='arrived' for k in a),'baseline_only_arrives':sum(a[k]['outcome']=='arrived' and b[k]['outcome']!='arrived' for k in a),'candidate_only_arrives':sum(a[k]['outcome']!='arrived' and b[k]['outcome']=='arrived' for k in a)}

def main():
 m=read(ROOT/'docs/farmer-mastery-manifest-02.json');assert len(m['entries'])==32
 variants={'baseline':('baseline',.65),'rations':('rations',.65),'planning65':('skilled',.65),'skilled85':('skilled',.85)}
 expected=set(itertools.product(['development','confirmation'],variants,['standard','lean'],['none','goats']))
 assert {(e['phase'],e['variant'],e['outfit'],e['arm']) for e in m['entries']}==expected
 rows=[];frozen=None;signature=None;archives=[]
 for e in m['entries']:
  p=T/e['filename'];receipt=read(T/('receipt-'+e['label']+'.json'));assert sha(p)==receipt['sha256']==sha(Path(receipt['copy']))
  assert not re.search(r'ERROR:|FAIL:',Path(receipt['log']).read_text(encoding='utf-8'))
  d=read(p);assert not d['errors'] and len(d['runs'])==8
  assert d['seed_start']==e['seed_start']==(515000 if e['phase']=='development' else 525000) and d['seeds']==4 and d['months']==[5,7]
  assert d['farmer_mastery']==variants[e['variant']][0]==e['mastery'] and d['player_accuracy']==variants[e['variant']][1]==e['accuracy']
  for k,v in {'outfit_profile':e['outfit'],'livestock_arm':e['arm'],'professions':['farmer'],'equipment':['shared'],'methods':['foot'],'pace':1,'reserve_meals':2,'motion_policy':'mobile','camp_work_policy':'support','fishing_policy':'support','stock_policy':'aware','feeding_policy':'fodder','mastery_policy_version':1}.items():assert d[k]==v,(e['label'],k)
  if frozen is None:frozen=d['source_hashes'];signature=d['rules_signature']
  assert d['source_hashes']==frozen and d['rules_signature']==signature
  assert {(r['month'],r['seed']) for r in d['runs']}==set(itertools.product([5,7],range(e['seed_start'],e['seed_start']+4)))
  for r in d['runs']:
   assert round(r['opening_cash']*100)+r['opening_cost_cents']==67500 and r['outfit'].get('livestock_fodder',0)==0
   a=r['feeding_comparison']['audit'];spoil=r['preservation_audit']
   assert abs(a['meal_requested']-a['meal_eaten']-a['meal_short'])<1e-5 and a['scraps_kcal']==0
   assert spoil['classification_errors']==0 and sum(spoil[k] for k in ['raw_meat_spoiled','dried_meat_spoiled','produce_spoiled','other_spoiled'])==r['spoilage_food_units']
   assert r['camp_work']['drying_batches']<=spoil['drying_batches']<=r['camp_work']['drying_batches']+r['counts'].get('preservations',0)+r['counts'].get('expert_preservations',0)
   assert spoil['units_retained']<=spoil['units_processed']
   rows.append(dict(r,phase=e['phase'],variant=e['variant'],arm=e['arm'],outfit_profile=e['outfit']))
  archives.append({'file':e['filename'],'sha256':receipt['sha256'],'archive':str(Path(receipt['copy']).relative_to(ROOT)).replace('\\','/')})
 assert len(rows)==256
 for name,digest in frozen.items():
  assert sha(ROOT/name)==digest,name
  blob=subprocess.check_output(['git','show',m['study_commit']+':'+name],cwd=ROOT)
  assert blob.replace(b'\r\n',b'\n')==(ROOT/name).read_bytes().replace(b'\r\n',b'\n'),name
 for name in subprocess.check_output(['git','ls-tree','-r','--name-only',m['gameplay'],'simulation','data'],cwd=ROOT,text=True).splitlines():
  old=subprocess.check_output(['git','show',m['gameplay']+':'+name],cwd=ROOT).replace(b'\r',b'')
  if name=='simulation/trail_engine.gd':old=old.replace(b'camp_tasks.day_plan={"rest":{},"jobs":[],"action":"hunt"}',b'camp_tasks.day_plan={"rest":{},"jobs":[],"action":"hunt","leader":camp_tasks.leader_id(self),"leader_patient":-1}')
  assert old==(ROOT/name).read_bytes().replace(b'\r',b''),name
 def select(**terms):return [r for r in rows if all(r[k]==v for k,v in terms.items())]
 for phase,outfit,arm in itertools.product(['development','confirmation'],['standard','lean'],['none','goats']):
  base=select(phase=phase,outfit_profile=outfit,arm=arm,variant='baseline');keyed={(r['month'],r['seed']):r for r in base}
  for variant in ['rations','planning65','skilled85']:
   for r in select(phase=phase,outfit_profile=outfit,arm=arm,variant=variant):
    other=keyed[r['month'],r['seed']]
    for k in ['outfit','opening_cash','opening_cost_cents']:assert other[k]==r[k]
 log=(T/'farmer-mastery-tests.log').read_text(encoding='utf-8')
 assert len(re.findall(r'^Godot Engine',log,re.M))==87 and 'Farmer mastery strategy: 17 checks, 0 failures' in log and not re.search(r'ERROR:|FAIL:',log)
 result={'study_commit':m['study_commit'],'gameplay':m['gameplay'],'gameplay_amendment':'Complete wagon-hunt work roster; no balance-rule changes. All suffix-01 reports excluded.','journeys':256,'reports':32,'errors':0,'test_suites':87,'source_hashes':frozen,'rules_signature':signature,'primary':{},'cells':{},'paired':{},'archives':archives,'limits':['Four underlying seeds repeat across outfit/arm/month settings within each phase.','Development pilots are excluded; candidate code was frozen before fresh cohorts.','The 85% candidate changes hunting execution as well as planning; 65% planning controls for that.','Strategies are explicit candidates, not proof of an optimal human policy or universal winnability.','Initial outfit optimization, party trait selection and alternative route strategies are not searched.','All suffix-01 cohorts were excluded after a real dairy/wagon roster exception; the entire matrix restarted with fresh seeds under the repaired runtime.','Classified spoilage is main-camp food, excluding detached actors and separately tracked dairy products.']}
 for phase in ['development','confirmation']:
  result['primary'][phase]={variant:summarize(select(phase=phase,variant=variant)) for variant in ['baseline','rations','planning65','skilled85']}
  result['paired'][phase]={variant:paired(select(phase=phase,variant='baseline'),select(phase=phase,variant=variant)) for variant in ['rations','planning65','skilled85']}
  for variant,outfit,arm,month in itertools.product(['baseline','rations','planning65','skilled85'],['standard','lean'],['none','goats'],[5,7]):
   result['cells']['|'.join(map(str,[phase,variant,outfit,arm,month]))]=summarize(select(phase=phase,variant=variant,outfit_profile=outfit,arm=arm,month=month))
 (ROOT/'docs/farmer-mastery-summary-01.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 for phase in ['development','confirmation']:
  for variant,r in result['primary'][phase].items():print(phase,variant,'arrivals',r['arrivals'],'/32; four+',r['arrivals_four_or_more_originals'],'; before November',r['arrivals_before_november'],'; food spoilage',r['spoilage_by_type'])
 print('Verified all 256 journeys, 32 archives, identical starting resources, frozen gameplay and 87 suites.')
if __name__=='__main__':main()
