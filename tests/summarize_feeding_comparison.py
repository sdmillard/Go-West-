"""Validate every frozen cohort/archive before reporting matched feeding outcomes."""
from pathlib import Path
import collections, datetime, hashlib, json, statistics, subprocess
ROOT=Path(__file__).resolve().parents[1]
TOOLS=ROOT/'.tools'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def median(xs): return round(statistics.median(xs),3) if xs else None
def mean(xs): return round(statistics.mean(xs),3) if xs else None
def rounded(x): return round(x,6)
def audit(r): return r['feeding_comparison']['audit']
def first_short(r):
    rows=[s for s in r['feeding_comparison']['samples'] if float(s['meal']['needed'])-float(s['meal']['eaten'])>1e-9]
    return min(rows,key=lambda s:s['day']) if rows else None

def summarize(rows):
    arrivals=[r for r in rows if r['outcome']=='arrived']
    need=sum(audit(r)['meal_requested'] for r in rows)
    herd_days=sum(audit(r)['herd_days'] for r in rows)
    shorts=[first_short(r) for r in rows if first_short(r)]
    first_deaths=[r for r in rows if r['livestock']['deaths']]
    return dict(runs=len(rows),arrivals=len(arrivals),five_present_arrivals=sum(r['original_present']==5 for r in arrivals),
        five_alive_arrivals=sum(r['original_survived']==5 for r in arrivals),outcomes=dict(collections.Counter(r['outcome'] for r in rows)),
        median_arrival_days=median([r['days'] for r in arrivals]),median_final_miles=median([r['miles'] for r in rows]),
        mean_original_survived=mean([r['original_survived'] for r in rows]),
        median_short_days=median([audit(r)['short_days'] for r in rows]),
        unmet_main_meal_pct=round(100*sum(audit(r)['meal_short'] for r in rows)/need,3) if need else 0,
        mean_main_meals_requested=mean([audit(r)['meal_requested'] for r in rows]),
        median_first_short_day=median([s['day'] for s in shorts]),median_cash_first_short=median([s['cash'] for s in shorts]),
        first_short_regions=dict(collections.Counter(s['region'] for s in shorts)),
        first_short_months=dict(collections.Counter((datetime.date(1848,r['month'],1)+datetime.timedelta(days=first_short(r)['day'])).month for r in rows if first_short(r))),
        mean_dairy_generated=mean([audit(r)['food_generated'] for r in rows]),mean_dairy_eaten=mean([audit(r)['dairy_eaten'] for r in rows]),
        mean_dairy_spoiled=mean([audit(r)['raw_dairy_spoiled_kcal']/1000 for r in rows]),
        mean_dairy_left=mean([audit(r)['dairy_left_kcal']/1000 for r in rows]),
        mean_portions_spoiled=mean([audit(r)['portion_spoiled_kcal']/1000 for r in rows]),
        mean_grain_lb_used=mean([audit(r)['grain_lb'] for r in rows]),mean_fodder_lb_used=mean([audit(r)['fodder_lb'] for r in rows]),
        mean_shared_food_units=mean([audit(r)['scraps_kcal']/1000 for r in rows]),
        mean_dairy_eaten_minus_shared_food=mean([audit(r)['dairy_eaten']-audit(r)['scraps_kcal']/1000 for r in rows]),
        care_short_pct=round(100*sum(audit(r)['care_short_days'] for r in rows)/herd_days,3) if herd_days else 0,
        mean_condition_losses=mean([sum(audit(r)['condition_losses'].values()) for r in rows]),
        condition_losses=dict(sum((collections.Counter(audit(r)['condition_losses']) for r in rows),collections.Counter())),
        crossing_losses=dict(sum((collections.Counter(audit(r)['crossing_losses']) for r in rows),collections.Counter())),
        butchered=dict(sum((collections.Counter(audit(r)['butchered']) for r in rows),collections.Counter())),
        mean_slaughter_food_added=mean([sum(e['changes'].get('food',0) for e in r['livestock']['slaughter']) for r in rows]),
        mean_grain_lb_bought=mean([sum(p['cart'].get('poultry_feed',0)*.25 for p in r['livestock']['purchases']) for r in rows]),
        mean_fodder_lb_bought=mean([sum(p['cart'].get('livestock_fodder',0) for p in r['livestock']['purchases']) for r in rows]),
        fodder_buying_journeys=sum(any(p['cart'].get('livestock_fodder',0)>0 for p in r['livestock']['purchases']) for r in rows),
        mean_final_cash=mean([r['cash'] for r in rows]),
        median_rest_days=median([r['audit']['rest_days'] for r in rows]),median_stationary_days=median([r['motion']['stationary_days'] for r in rows]),
        median_progress_days=median([r['motion']['distance_progress_days'] for r in rows]),
        mean_leader_hunts=mean([r['counts']['hunts'] for r in rows]),mean_outrider_food_returned=mean([r['field']['returned_catch_units'] for r in rows]),
        mean_foraged_units=mean([r['camp_forage']['leader_food']+r['camp_forage']['shared_food'] for r in rows]),
        mean_companion_fishing_units=mean([sum(x.get('food',0) for x in r['fishing']['companions']) for r in rows]),
        median_scurvy_person_days=median([r['audit']['scurvy_person_days'] for r in rows]),
        death_causes=dict(collections.Counter(c for r in rows for c in r['death_causes'])),
        journeys_with_recorded_main_deaths=len(first_deaths),
        shortage_before_recorded_main_death=sum(first_short(r) is not None and first_short(r)['day']<=min(d['day'] for d in r['livestock']['deaths']) for r in first_deaths))

def paired(a,b):
    def key(r):return r['phase'],r['outfit_profile'],r['arm'],r['month'],r['seed']
    left={key(r):r for r in a};right={key(r):r for r in b}
    assert left.keys()==right.keys()
    both=[(left[k],right[k]) for k in left if left[k]['outcome']==right[k]['outcome']=='arrived']
    return dict(pairs=len(left),both_arrive=len(both),left_only_arrives=sum(left[k]['outcome']=='arrived' and right[k]['outcome']!='arrived' for k in left),
        right_only_arrives=sum(right[k]['outcome']=='arrived' and left[k]['outcome']!='arrived' for k in left),
        median_arrival_day_change=median([y['days']-x['days'] for x,y in both]),
        median_dairy_eaten_change=median([audit(right[k])['dairy_eaten']-audit(left[k])['dairy_eaten'] for k in left]),
        median_short_days_change=median([audit(right[k])['short_days']-audit(left[k])['short_days'] for k in left]))

def main():
    manifest=json.loads((TOOLS/'feeding-comparison-manifest-02.json').read_text(encoding='utf-8'))
    entries=manifest['entries'];assert len(entries)==52 and len({e['label'] for e in entries})==52
    expected={(phase,version,outfit,arm,'fixed') for phase in ['development','confirmation'] for version in ['old','new'] for outfit in ['standard','lean'] for arm in ['none','goats','cow','hens','mixed']}
    expected|={(phase,'new',outfit,arm,'fodder') for phase in ['development','confirmation'] for outfit in ['standard','lean'] for arm in ['goats','cow','mixed']}
    assert {(e['phase'],e['runtime'],e['outfit'],e['arm'],e['feeding_policy']) for e in entries}==expected
    rows=[];frozen={};signatures={};archives=[]
    for e in entries:
        target=TOOLS/e['filename'];receipt=json.loads((TOOLS/('receipt-'+e['label']+'.json')).read_text(encoding='utf-8-sig'))
        origin=Path(receipt['origin']);assert sha(target)==receipt['sha256']
        if origin.exists():assert sha(origin)==receipt['sha256']
        report=json.loads(target.read_text(encoding='utf-8'));assert not report['errors'] and len(report['runs'])==12
        assert report['runtime_label']==e['runtime'] and report['feeding_policy']==e['feeding_policy'] and report['livestock_arm']==e['arm']
        assert report['seed_start']==e['seed_start']==(385000 if e['phase']=='development' else 395000) and report['seeds']==6
        assert report['outfit_profile']==e['outfit'] and report['stock_policy']=='aware'
        for name,value in {'professions':['farmer'],'months':[5,7],'equipment':['shared'],'methods':['foot'],'pace':1,'reserve_meals':2,'player_accuracy':.65,'fishing_policy':'support','camp_work_policy':'support','motion_policy':'mobile','comparison_policy_version':1}.items():assert report[name]==value,(e['label'],name,report[name])
        if e['runtime'] not in frozen:frozen[e['runtime']]=report['source_hashes'];signatures[e['runtime']]=report['rules_signature']
        assert report['source_hashes']==frozen[e['runtime']] and report['rules_signature']==signatures[e['runtime']]
        assert {(r['month'],r['seed']) for r in report['runs']}=={(month,seed) for month in [5,7] for seed in range(e['seed_start'],e['seed_start']+6)}
        for row in report['runs']:
            assert row['profession']=='farmer' and row['equipment']=='shared' and row['method']=='foot'
            assert round(row['opening_cash']*100)+row['opening_cost_cents']==67500
            assert row['outfit'].get('livestock_fodder',0)==0
            assert abs(audit(row)['meal_requested']-audit(row)['meal_eaten']-audit(row)['meal_short'])<1e-5
            assert audit(row)['food_generated']+1e-5>=audit(row)['dairy_eaten']>=0
            assert row['counts'].get('fodder_lb_bought',0)==sum(p['cart'].get('livestock_fodder',0) for p in row['livestock']['purchases'])
            if e['feeding_policy']=='fixed':assert not row['counts'].get('fodder_lb_bought',0)
            rows.append(dict(row,phase=e['phase'],runtime=e['runtime'],outfit_profile=e['outfit'],arm=e['arm'],feeding_policy=e['feeding_policy']))
        archives.append(dict(label=e['label'],filename=e['filename'],sha256=receipt['sha256'],origin=str(origin.relative_to(ROOT)).replace('\\','/')))
    assert len(rows)==624
    for version,files in frozen.items():
        tree=ROOT/manifest['trees'][version]
        for name,digest in files.items():
            if (tree/name).exists():assert sha(tree/name)==digest,(version,name)
            ref=manifest['old_gameplay'] if version=='old' else manifest['new_gameplay']
            blob=subprocess.check_output(['git','show',ref+':'+name],cwd=ROOT)
            lf=blob.replace(b'\r\n',b'\n')
            assert digest in {hashlib.sha256(b).hexdigest() for b in [blob,lf,lf.replace(b'\n',b'\r\n')]},(version,name,'Git snapshot')
    common=['feeding_compare_stock.gd','feeding_compare_observer.gd','feeding_compare_campaign.gd','test_feeding_comparison.gd','livestock_balance_campaign.gd','fishing_campaign.gd','mobile_camp_campaign.gd','coordinated_camp_campaign.gd','hunting_balance_campaign.gd','current_journey_policy.gd']
    for name in common:assert frozen['old']['tests/'+name]==frozen['new']['tests/'+name],name
    for version,ref in [('old',manifest['old_gameplay']),('new',manifest['new_gameplay'])]:
        tree=ROOT/manifest['trees'][version]
        for name in subprocess.check_output(['git','ls-tree','-r','--name-only',ref,'simulation','data'],cwd=ROOT,text=True).splitlines():
            if (tree/name).exists():assert (tree/name).read_bytes().replace(b'\r',b'')==subprocess.check_output(['git','show',ref+':'+name],cwd=ROOT).replace(b'\r',b''),name
    def select(**terms):return [r for r in rows if all(r[k]==v for k,v in terms.items())]
    # Negative control: no livestock means no changed ordinary decisions or outcomes.
    controls=0
    for phase in ['development','confirmation']:
        for outfit in ['standard','lean']:
            old=select(phase=phase,outfit_profile=outfit,arm='none',runtime='old');new=select(phase=phase,outfit_profile=outfit,arm='none',runtime='new')
            bykey={(r['month'],r['seed']):r for r in new}
            for a in old:
                b=bykey[a['month'],a['seed']]
                for field in ['outcome','days','miles','original_present','original_survived','cash','food','counts','audit','field','camp_work','camp_forage','motion','route','curve']:
                    assert a[field]==b[field],('No-stock control differs',phase,outfit,a['month'],a['seed'],field)
                controls+=1
    # Matching carts/costs for each comparison (ignore only the new zero-valued fodder key).
    for phase in ['development','confirmation']:
        for arm in ['none','goats','cow','hens','mixed']:
            old=select(phase=phase,arm=arm,runtime='old');new=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed')
            bykey={(r['outfit_profile'],r['month'],r['seed']):r for r in new}
            for a in old:
                b=bykey[a['outfit_profile'],a['month'],a['seed']]
                c=dict(b['outfit']);c.pop('livestock_fodder',None)
                assert a['outfit']==c and a['opening_cash']==b['opening_cash'] and a['opening_cost_cents']==b['opening_cost_cents']
    summary={'date':'2026-10-26','amendment':2,'excluded_matrix':'manifest-01: interrupted egg-boundary diagnostics; no outcomes pooled','study_commit':manifest['study_commit'],'gameplay':{'old':manifest['old_gameplay'],'new':manifest['new_gameplay']},'rules':signatures,'journeys':len(rows),'reports':len(entries),'errors':0,'no_stock_controls_identical':controls,'primary':{},'secondary':{},'cells':{},'archives':archives,'common_source_hashes':{name:frozen['old']['tests/'+name] for name in common},'limitations':['Six underlying seeds per phase repeat over settings; not 624 independent worlds.','Main-camp meal totals exclude detached actors, whose hunting/return/death records are reported separately.','Older grain-shortage counters and current maintenance-shortage counters are not compared.','Paired arrival times exclude pairs where either journey does not arrive.','Scripted policies retain earlier ration/reserve/caretaker limitations; fodder is a secondary decision change, not an isolated rule effect.']}
    for phase in ['development','confirmation']:
        summary['primary'][phase]={}
        for arm in ['none','goats','cow','hens','mixed']:
            old=select(phase=phase,arm=arm,runtime='old');new=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed')
            summary['primary'][phase][arm]={'old':summarize(old),'new':summarize(new),'paired':paired(old,new)}
        summary['secondary'][phase]={}
        for arm in ['goats','cow','mixed']:
            fixed=select(phase=phase,arm=arm,runtime='new',feeding_policy='fixed');fodder=select(phase=phase,arm=arm,runtime='new',feeding_policy='fodder')
            bykey={(r['outfit_profile'],r['month'],r['seed']):r for r in fodder}
            for a in fixed:
                b=bykey[a['outfit_profile'],a['month'],a['seed']]
                for field in ['outfit','opening_cash','opening_cost_cents']:assert a[field]==b[field]
            summary['secondary'][phase][arm]={'fixed':summarize(fixed),'fodder':summarize(fodder),'paired':paired(fixed,fodder)}
        for version in ['old','new']:
            for policy in ['fixed','fodder']:
                for arm in ['none','goats','cow','hens','mixed']:
                    for outfit in ['standard','lean']:
                        for month in [5,7]:
                            cell=select(phase=phase,runtime=version,feeding_policy=policy,arm=arm,outfit_profile=outfit,month=month)
                            if cell:summary['cells']['|'.join(map(str,[phase,version,policy,arm,outfit,month]))]=summarize(cell)
    path=ROOT/'docs/feeding-comparison-summary-01.json';path.write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    for phase in ['development','confirmation']:
        for arm,c in summary['primary'][phase].items():print(phase,arm,'old/new arrivals',c['old']['arrivals'],c['new']['arrivals'],'dairy eaten',c['old']['mean_dairy_eaten'],c['new']['mean_dairy_eaten'])
        for arm,c in summary['secondary'][phase].items():print(phase,arm,'new fixed/fodder arrivals',c['fixed']['arrivals'],c['fodder']['arrivals'],'fodder bought',c['fodder']['mean_fodder_lb_bought'])
    print('Verified',len(rows),'journeys;',controls,'identical no-stock controls; all archive/source hashes match')
if __name__=='__main__':main()
