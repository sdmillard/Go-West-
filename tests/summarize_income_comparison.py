"""Verify all declared matched income cases before publishing their compact results."""
from pathlib import Path
import argparse,datetime,hashlib,itertools,json,re,statistics
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def med(values):return statistics.median(values) if values else None
def date(r):return (datetime.date(1848,r['month'],1)+datetime.timedelta(days=r['days'])).isoformat()
def money(v):return round(v,2)
def gross(r):
 totals={'keepsakes_cents':0,'pelts_cents':0,'work_cents':0,'work_days':len(r['income']['work_days']),'work_meals':sum(d['eaten'] for d in r['income']['work_days']),'sale_days':sum(s['days'] for s in r['income']['sales']),'sale_meals':sum(t['eaten'] for s in r['income']['sales'] for t in s['ticks']),'preparation_days':0,'preparation_meals':0,'raw_haul_displaced_lb':0,'goods_sold':{},'skins_prepared':{},'skin_decisions':r['income']['skin_decisions']}
 for sale in r['income']['sales']:
  for g in sale['goods']:
   totals['keepsakes_cents' if g['item'].startswith('keepsake_') else 'pelts_cents']+=g['cents']
   totals['goods_sold'][g['item']]=totals['goods_sold'].get(g['item'],0)+g['quantity']
 totals['work_cents']=round(sum(p['changes']['money'] for p in r['income']['work_payments'])*100)
 for p in r['income']['pelt_recoveries']:
  totals['preparation_days']+=p['recovery'].get('preparation_days',0);totals['preparation_meals']+=p['recovery'].get('preparation_food_units',0);totals['raw_haul_displaced_lb']+=p['raw_haul_displaced_lb']
  for item,n in p['recovery'].get('pelts',{}).items():totals['skins_prepared'][item]=totals['skins_prepared'].get(item,0)+n
 totals['gross_cents']=sum(totals[k] for k in ['keepsakes_cents','pelts_cents','work_cents'])
 return totals

def summary(rows):
 arrivals=[r for r in rows if r['outcome']=='arrived'];short=[r for r in rows if r['livestock']['first_short']]
 g=[gross(r) for r in rows]
 s={'runs':len(rows),'arrived':len(arrivals),'arrived_four_originals':sum(r['original_present']>=4 for r in arrivals),'arrived_five_originals':sum(r['original_present']==5 for r in arrivals),'arrived_before_october':sum(date(r)<'1848-10-01' for r in arrivals),'outcomes':{k:sum(r['outcome']==k for r in rows) for k in sorted({r['outcome'] for r in rows})},'shortage_cases':len(short),'short_meal_units':round(sum(r['livestock']['short_units'] for r in rows),3),'needed_meal_units':sum(r['livestock']['needed_units'] for r in rows),'median_first_short_day':med([r['livestock']['first_short']['day'] for r in short]),'median_first_short_cash':med([r['livestock']['first_short']['cash'] for r in short]),'median_terminal_cash':med([r['cash'] for r in rows]),'recorded_food_deaths':sum('lack of food' in d['cause'] for r in rows for d in r['livestock']['deaths']),'recorded_scurvy_deaths':sum('scurvy' in d['cause'] for r in rows for d in r['livestock']['deaths']),'income':{},'arrivals':[{'seed':r['seed'],'month':r['month'],'stock':r['stock'],'days':r['days'],'date':date(r),'original_present':r['original_present'],'cash':r['cash']} for r in arrivals]}
 for k in ['gross_cents','keepsakes_cents','pelts_cents','work_cents','work_days','work_meals','sale_days','sale_meals','preparation_days','preparation_meals','raw_haul_displaced_lb']:s['income'][k]=round(sum(x[k] for x in g),3)
 s['income']['cases_earning']=sum(x['gross_cents']>0 for x in g)
 s['income']['median_gross_cents']=med([x['gross_cents'] for x in g])
 for k in ['goods_sold','skins_prepared','skin_decisions']:
  s['income'][k]={key:sum(x[k].get(key,0) for x in g) for key in sorted({key for x in g for key in x[k]})}
 s['shortage_percent']=round(100*s['short_meal_units']/s['needed_meal_units'],4)
 return s

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--version',type=int,choices=[1,2],default=1);args=parser.parse_args();version=args.version
 m=read(ROOT/f'docs/income-comparison-manifest-{version:02d}.json')
 assert m['journeys']==32 and m['seed_start']==(567000 if version==1 else 568000) and m['seeds']==4 and m['months']==[4,5]
 assert {(e['arm'],e['stock']) for e in m['entries']}==set(itertools.product(['off','combined'],['none','goats']))
 rows=[];sources=None;rules=None;archives=[]
 for e in m['entries']:
  p=ROOT/'.tools'/e['filename'];receipt=read(ROOT/'.tools'/('receipt-'+e['label']+'.json'));d=read(p)
  assert sha(p)==receipt['sha256']==sha(Path(receipt['copy']))
  assert not re.search(r'SCRIPT ERROR:|ERROR:|FAIL:',Path(receipt['log']).read_text(encoding='utf-8-sig'))
  assert not d['errors'] and len(d['runs'])==8
  for k,v in {'seed_start':m['seed_start'],'seeds':4,'months':[4,5],'income_arm':e['arm'],'livestock_arm':e['stock'],'income_policy_version':version,'farmer_mastery':'skilled','outfit_profile':'standard','player_accuracy':.65,'professions':['farmer'],'equipment':['shared'],'methods':['foot'],'pace':1,'reserve_meals':2,'motion_policy':'mobile','camp_work_policy':'support','fishing_policy':'support','stock_policy':'aware','feeding_policy':'fodder'}.items():assert d[k]==v,(e['label'],k)
  if sources is None:sources=d['source_hashes'];rules=d['rules_signature']
  assert sources==d['source_hashes'] and rules==d['rules_signature']
  assert {(r['seed'],r['month']) for r in d['runs']}==set(itertools.product(range(m['seed_start'],m['seed_start']+4),[4,5]))
  for raw in d['runs']:
   r=dict(raw,stock=e['stock'],income_arm=e['arm'])
   assert round(r['opening_cash']*100)+r['opening_cost_cents']==67500
   assert r['audit']['days']==r['days']==sum(r['motion']['actions'].values())
   a=r['feeding_comparison']['audit'];spoil=r['preservation_audit']
   assert abs(a['meal_requested']-a['meal_eaten']-a['meal_short'])<1e-5
   assert spoil['classification_errors']==0
   assert sum(spoil[k] for k in ['raw_meat_spoiled','dried_meat_spoiled','produce_spoiled','other_spoiled'])==r['spoilage_food_units']
   assert r['outcome'] in ['arrived','lost','year_limit']
   i=r['income']
   assert len(i['work_days'])==len(i['work_payments'])==sum(i['record']['work'].values())==r['motion']['actions'].get('settlement_work',0)
   assert sorted(x['day'] for x in i['work_days'])==sorted(x['day'] for x in i['work_payments'])
   for day,payment in zip(i['work_days'],i['work_payments']):
    assert day['worker']==payment['worker'] and payment['changes']['money'] in [.75,1.0,1.5]
    assert abs(day['requested']-day['eaten']-day['short'])<1e-5
   for sale in i['sales']:
    assert sale['days']==len(sale['ticks'])
    for good in sale['goods']:assert good['quantity']>0 and good['cents']>0
   for recovery in i['pelt_recoveries']:assert recovery['quote']['valid'] and recovery['raw_haul_displaced_lb']>=0
   if e['arm']=='off':assert not i['sales'] and not i['work_days'] and not i['pelt_recoveries']
   rows.append(r)
  archives.append({'label':e['label'],'sha256':sha(p),'bytes':p.stat().st_size,'source_commit':receipt['source_commit']})
 assert len(rows)==32
 for path,expected in sources.items():assert sha(ROOT/path)==expected,('Frozen source changed',path)
 pairs=[]
 for seed,month,stock in itertools.product(range(m['seed_start'],m['seed_start']+4),[4,5],['none','goats']):
  pair={r['income_arm']:r for r in rows if (r['seed'],r['month'],r['stock'])==(seed,month,stock)}
  assert set(pair)=={'off','combined'}
  a,b=pair['off'],pair['combined'];assert (a['outfit'],a['opening_cash'],a['opening_cost_cents'])==(b['outfit'],b['opening_cash'],b['opening_cost_cents'])
  def compact(r):return {'outcome':r['outcome'],'days':r['days'],'date':date(r) if r['outcome']=='arrived' else None,'miles':r['miles'],'original_present':r['original_present'],'cash':r['cash'],'short_meal_units':round(r['livestock']['short_units'],3),'first_short':r['livestock']['first_short'],'income':gross(r)}
  pairs.append({'seed':seed,'month':month,'stock':stock,'off':compact(a),'combined':compact(b),'arrival_days_difference':b['days']-a['days'] if a['outcome']==b['outcome']=='arrived' else None})
 result={'gameplay':m['gameplay'],'rules_signature':rules,'source_hashes':sources,'archives':archives,'cases':32,'pairs':16,'independent_seed_worlds':4,'arms':{arm:summary([r for r in rows if r['income_arm']==arm]) for arm in ['off','combined']},'cells':{f'{arm}/{stock}/{month}':summary([r for r in rows if (r['income_arm'],r['stock'],r['month'])==(arm,stock,month)]) for arm,stock,month in itertools.product(['off','combined'],['none','goats'],[4,5])},'paired':pairs}
 out=ROOT/f'docs/income-comparison-summary-{version:02d}.json';out.write_bytes((json.dumps(result,indent=2,sort_keys=True)+'\n').encode('utf-8'))
 print(json.dumps({'cases':32,'pairs':16,'arms':result['arms']},indent=2))
if __name__=='__main__':main()
