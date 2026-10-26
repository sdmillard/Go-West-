"""Verify final frozen dairy experiments; retain compact provenance, not win-rate claims."""
from pathlib import Path
import hashlib,itertools,json,re
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'.tools'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def main():
 log=(T/'ruminant-energy-final-tests.log').read_text(encoding='utf-8')
 assert len(re.findall(r'^Godot Engine',log,re.M))==84 and 'Ruminant nutrient budgets: 5446 checks, 0 failures' in log
 assert not re.search(r'SCRIPT ERROR:|ERROR:|FAIL:',log)
 p=T/'ruminant-sensitivity-03.json';d=load(p);assert len(d['rows'])==1728 and not d['failures']
 for n,h in d['source_hashes'].items():assert sha(ROOT/n)==h,n
 expected=set(itertools.product(['dairy_cows','goats'],[.8,1.,1.2],[.45,.55,.65],[.25,.5,.75,1.],[False,True],[0,30,180],[0,100],[50,100]))
 actual=set()
 for r in d['rows']:
  kind=r['kind'];base=1000 if kind=='dairy_cows' else 100;ceiling=8 if kind=='dairy_cows' else 2;density=277 if kind=='dairy_cows' else 313
  actual.add((kind,r['body_lb']/base,r['natural_tdn'],r['opportunity'],r['moving'],r['remaining'],r['hay_held_lb'],r['starting_condition']))
  n=r['nutrition'];b=n['budget']
  assert -1e-9<=r['hay_used_lb']<=r['hay_held_lb']+1e-9
  assert n['natural_dm_eaten_lb']+n['hay_dm_lb']<=b['capacity_dm_lb']+1e-8
  assert abs(n['tdn_lb']-n['natural_dm_eaten_lb']*r['natural_tdn']-n['hay_dm_lb']*.55)<1e-8
  assert r['milk_lb']<=ceiling*min(r['remaining']/60,1)+1e-8
  assert abs(r['milk_kcal']-r['milk_lb']*density)<1e-6
  if r['remaining']==0 or n['production']==0:assert r['milk_lb']==0
  # Preview's charged whole-unit counter is zero until commitment; physical forecasts agree.
  assert r['preview_matches']==(r['hay_used_lb']==0)
 assert actual==expected
 p_context=T/'ruminant-default-context-01.json';context=load(p_context);assert len(context['rows'])==40
 for key,path in [('stock_sha256','simulation/livestock.gd'),('feeding_sha256','simulation/livestock_feeding.gd'),('nutrition_sha256','simulation/ruminant_nutrition.gd'),('data_sha256','data/livestock.json')]:assert context[key]==sha(ROOT/path)
 bykey={(r['month'],r['region'],r['initial_fodder_lb'],r['condition']):r for r in context['rows']}
 for key,r in bykey.items():
  other=bykey[key[:3]+(100 if key[3]==50 else 50,)]
  for field in ['cow_milk_lb','goat_milk_lb']:assert r[field]==other[field]
  if r['initial_fodder_lb']==100:assert r['cow_milk_lb']==8 and r['goat_milk_lb']==2
 reports=[]
 for outfit,arm in itertools.product(['standard','lean'],['cow','goats','mixed']):
  p_report=T/f'hunting-ruminant-energy-smoke-{outfit}-{arm}-02.json';report=load(p_report)
  assert len(report['runs'])==4 and not report['errors']
  assert report['seed_start']==435000 and report['seeds']==2 and report['months']==[5,7]
  assert report['outfit_profile']==outfit and report['livestock_arm']==arm and report['feeding_policy']=='fodder'
  for n,h in report['source_hashes'].items():assert sha(ROOT/n)==h,n
  reports.append({'file':p_report.name,'sha256':sha(p_report),'journeys':4,'rules_signature':report['rules_signature'],'source_hashes':report['source_hashes'],'fodder_lb_bought':sum(r['counts'].get('fodder_lb_bought',0) for r in report['runs'])})
 summary={'test_suites':84,'focused_nutrient_checks':5446,'test_log':'.tools/ruminant-energy-final-tests.log','runtime':'ae977ce0da27e836e47d34afdcb18f0953a34a3e','purpose':'Isolated nutrient sensitivity and selected journey integration; not historical measurements or a matched survival comparison.','excluded':'Preflight sensitivity01/02, smoke01, preliminary suite logs. Final inputs frozen after numerical/work corrections.','sensitivity':{'file':p.name,'sha256':sha(p),'cases':len(d['rows']),'failures':0,'source_hashes':d['source_hashes'],'preview_note':'The full dictionary differs when committed whole hay units are charged; preview reserves physical amounts without consuming them.'},'default_context':{'file':p_context.name,'sha256':sha(p_context),'cases':40,'unfed_fair_good_equal':True,'ample_hay_restores_ceiling':True,'rows':[{'month':r['month'],'region':r['region'],'cow_milk_lb':r['cow_milk_lb'],'goat_milk_lb':r['goat_milk_lb']} for r in context['rows'] if r['condition']==100 and r['initial_fodder_lb']==0]},'integration':{'journeys':24,'errors':0,'reports':reports},'limits':['Body sizes, nutrient coefficients and travel increments are explicit proxy assumptions.','Habitat/month caps still approximate quantity; natural nutrient quality remains species-specific and constant.','Protein/minerals, temporary body-reserve milk and local herd competition are not simulated.','Raw experiments stay in local ignored .tools; reproduction requires frozen runtime and scripts.']}
 (ROOT/'docs/ruminant-energy-validation-01.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
 print('Verified 1728 isolated ticks, 40 default-context probes, 24 journeys; all final source/archive hashes match.')
 print('Fodder purchased:',sum(r['fodder_lb_bought'] for r in reports),'lb')
if __name__=='__main__':main()
