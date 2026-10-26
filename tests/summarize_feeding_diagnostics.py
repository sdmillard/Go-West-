"""Exploratory follow-ups: separate from the sealed 624-journey matrix."""
from pathlib import Path
import hashlib,json,statistics
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'.tools'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def audit(r):return r['feeding_comparison']['audit']
def main():
 result={'purpose':'Exploratory follow-ups after inspecting confirmation; not independent validation or pooled with the 624 journeys.','gameplay':'64318410e93cfc5ed28039436374921da5731c10','sharing':{},'archives':[]}
 modes={}
 for mode in ['on','off']:
  rows=[]
  for outfit in ['standard','lean']:
   name=f'hunting-feeding-sharing-{mode}-{outfit}-01.json';p=T/name
   d=json.loads(p.read_text());assert len(d['runs'])==12 and not d['errors']
   assert d['seed_start']==405000 and d['seeds']==6 and d['months']==[5,7]
   origin=T/'feeding-sharing-diagnostic/.tools'/name
   if origin.exists():assert digest(p)==digest(origin)
   for n,h in d['source_hashes'].items():
    source=T/'feeding-sharing-diagnostic'/n
    if source.exists():assert digest(source)==h,n
   for r in d['runs']:assert r['sharing_setting']==(mode=='on')
   rows+=d['runs'];result['archives'].append({'file':name,'sha256':digest(p),'source_hashes':d['source_hashes']})
  modes[mode]={(outfit,r['month'],r['seed']):r for outfit in ['standard','lean'] for r in json.loads((T/f'hunting-feeding-sharing-{mode}-{outfit}-01.json').read_text())['runs']}
  result['sharing'][mode]={'journeys':len(rows),'arrivals':sum(r['outcome']=='arrived' for r in rows),'mean_eggs_eaten_units':statistics.mean(audit(r)['dairy_eaten'] for r in rows),'mean_shared_human_food_units':statistics.mean(audit(r)['scraps_kcal']/1000 for r in rows),'mean_grain_used_lb':statistics.mean(audit(r)['grain_lb'] for r in rows),'mean_original_survived':statistics.mean(r['original_survived'] for r in rows)}
 assert modes['on'].keys()==modes['off'].keys()
 for k,a in modes['on'].items():
  b=modes['off'][k]
  for f in ['outfit','opening_cash','opening_cost_cents']:assert a[f]==b[f]
 p=T/'feeding-cap-probe-01.json';d=json.loads(p.read_text());assert len(d['rows'])==40
 origin=T/'feeding-sharing-diagnostic/.tools'/p.name
 if origin.exists():assert digest(p)==digest(origin)
 bykey={(r['month'],r['region'],r['initial_fodder_lb'],r['condition']):r for r in d['rows']}
 for k,r in bykey.items():
  other=bykey[k[:3]+(100 if k[3]==50 else 50,)]
  for f in ['cow_milk_lb','goat_milk_lb']:assert r[f]==other[f]
  if r['initial_fodder_lb']==100:assert r['cow_milk_lb']==8 and r['goat_milk_lb']==2
 result['forage_probes']=d;result['archives'].append({'file':p.name,'sha256':digest(p)})
 result['limitations']=['Sharing study uses fresh six seeds repeated across May/July and two outfits; exploratory only.','Probe outputs are authored model behavior, not historical yield measurements.','Main study and diagnostics do not justify increasing biological yield to meet a win-rate target.']
 (ROOT/'docs/feeding-exploratory-summary-01.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(result['sharing'],indent=2));print('Verified 48 exploratory journeys, 24 matched starting carts, and 40 controlled probes.')
if __name__=='__main__':main()
