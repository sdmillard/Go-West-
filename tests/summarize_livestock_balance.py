"""Verify all declared reports before summarizing the paired farmer study."""
from pathlib import Path
import collections, hashlib, json, statistics
ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / ".tools/farmer-livestock-validation"
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def median(xs): return round(statistics.median(xs), 2) if xs else None
def mean(xs): return round(statistics.mean(xs), 2) if xs else None
def total(rows, getter): return sum(getter(r) for r in rows)
def summarize(rows):
    arrivals = [r for r in rows if r["outcome"] == "arrived"]
    herd_days = total(rows, lambda r: r["livestock"]["audit"]["herd_days"])
    need = total(rows, lambda r: r["livestock"]["needed_units"])
    return dict(runs=len(rows), arrivals=len(arrivals), all_five_present_arrivals=sum(r["original_present"] == 5 for r in arrivals),
        median_arrival_days=median([r["days"] for r in arrivals]), median_final_miles=median([r["miles"] for r in rows]),
        mean_original_survived=mean([r["original_survived"] for r in rows]), median_underfed_days=median([r["audit"]["underfed_days"] for r in rows]),
        unmet_food_pct=round(100*total(rows,lambda r:r["livestock"]["short_units"])/need,2) if need else 0,
        median_first_short_day=median([r["livestock"]["first_short"]["day"] for r in rows if r["livestock"]["first_short"]]),
        median_scurvy_person_days=median([r["audit"]["scurvy_person_days"] for r in rows]), median_rest_days=median([r["audit"]["rest_days"] for r in rows]),
        median_stationary_days=median([r["motion"]["stationary_days"] for r in rows]), median_progress_days=median([r["motion"]["distance_progress_days"] for r in rows]),
        mean_produced_food=mean([r["livestock"]["audit"]["food_generated"] for r in rows]), mean_dairy_food_eaten=mean([r["livestock"]["food_eaten"] for r in rows]),
        mean_dairy_food_spoiled=mean([r["livestock"]["food_spoiled"] for r in rows]), mean_food_left=mean([r["livestock"]["audit"]["food_left"] for r in rows]),
        mean_unconverted_spoiled_kcal=mean([r["livestock"]["audit"]["unconverted_spoiled_kcal"] for r in rows]),
        care_short_pct=round(100*total(rows,lambda r:r["livestock"]["audit"]["care_short_days"])/herd_days,2) if herd_days else 0,
        mean_feed_short_days=mean([r["livestock"]["audit"]["feed_short_days"] for r in rows]),
        mean_grain_lb_used=mean([r["livestock"]["audit"]["feed_quarters"]*.25 for r in rows]),
        mean_grain_lb_bought=mean([sum(int(p["cart"].get("poultry_feed",0)) for p in r["livestock"]["purchases"])*.25 for r in rows]),
        mean_grain_spent_dollars=mean([sum(-p["net_cents"] for p in r["livestock"]["purchases"] if p["cart"].get("poultry_feed",0)>0)/100 for r in rows]),
        mean_slaughter_food_added=mean([sum(int(e["changes"].get("food",0)) for e in r["livestock"]["slaughter"]) for r in rows]),
        mean_condition_losses=mean([sum(r["livestock"]["audit"]["condition_losses"].values()) for r in rows]),
        mean_crossing_losses=mean([sum(r["livestock"]["audit"]["crossing_losses"].values()) for r in rows]),
        mean_emergency_butcheries=mean([sum(r["livestock"]["audit"]["butchered"].values()) for r in rows]),
        mean_opening_cash=mean([r["opening_cash"] for r in rows]), mean_final_cash=mean([r["cash"] for r in rows]),
        mean_requested_food=mean([r["livestock"]["needed_units"] for r in rows]),
        mean_leader_hunts=mean([r["counts"]["hunts"] for r in rows]), mean_outrider_food_delivered=mean([r["field"]["returned_catch_units"] for r in rows]),
        death_causes=dict(collections.Counter(c for r in rows for c in r["death_causes"])),
        short_before_first_death=sum(bool(r["livestock"]["first_short"]) and bool(r["livestock"]["deaths"]) and r["livestock"]["first_short"]["day"] <= min(d["day"] for d in r["livestock"]["deaths"]) for r in rows),
        journeys_with_deaths=sum(bool(r["livestock"]["deaths"]) for r in rows))
def main():
    manifest = json.loads((ROOT/".tools/farmer-stock-manifest-01.json").read_text())
    expected={(phase,outfit,arm,policy) for phase in ["development","confirmation"] for outfit in ["standard","lean"] for arm in ["none","goats","cow","hens","mixed"] for policy in (["existing"] if arm=="none" else ["existing","aware"])}
    assert {(m["phase"],m["outfit"],m["arm"],m["policy"]) for m in manifest}==expected and len(manifest)==36
    all_rows=[]; frozen=None; signature=None; common=None
    for m in manifest:
        path=ROOT/".tools"/m["path"]; origin=Path(m["source"])
        assert sha(path)==sha(origin)==m["sha256"]
        report=json.loads(path.read_text());assert not report["errors"] and len(report["runs"])==12
        assert report["livestock_arm"]==m["arm"] and report["stock_policy"]==m["policy"] and report["outfit_profile"]==m["outfit"]
        start=311000 if m["phase"]=="development" else 321000
        assert report["seed_start"]==start and report["seeds"]==6
        assert {(r["month"],r["seed"]) for r in report["runs"]}=={(month,seed) for month in [5,7] for seed in range(start,start+6)}
        settings={k:report[k] for k in ["professions","months","equipment","methods","pace","player_accuracy","reserve_meals","fishing_policy","camp_work_policy","motion_policy","livestock_balance_policy_version"]}
        if frozen is None:frozen=report["source_hashes"];signature=report["rules_signature"];common=settings
        assert report["source_hashes"]==frozen and report["rules_signature"]==signature and settings==common
        for row in report["runs"]:
            assert row["profession"]=="farmer" and row["equipment"]=="shared" and row["method"]=="foot"
            assert round(row["opening_cash"]*100)+row["opening_cost_cents"]==67500
            assert int(row["counts"].get("grain_quarters_bought",0))==sum(int(p["cart"].get("poultry_feed",0)) for p in row["livestock"]["purchases"])
            row=dict(row,phase=m["phase"],outfit_profile=m["outfit"],arm=m["arm"],stock_policy=m["policy"]);all_rows.append(row)
    assert len(all_rows)==432
    for name,digest in frozen.items():assert sha(WORK/name)==digest,name
    # Every production rule and simulation file still matches the shipped livestock baseline.
    import subprocess
    for name in frozen:
        if name.startswith(("simulation/","data/")):
            shipped=subprocess.check_output(["git","show","f685292:"+name],cwd=ROOT)
            assert shipped.replace(b"\r",b"")==(WORK/name).read_bytes().replace(b"\r",b""),name
    baseline={(r["phase"],r["outfit_profile"],r["month"],r["seed"]):r for r in all_rows if r["arm"]=="none"}
    extras={"none":{},"goats":{"goats":2},"cow":{"dairy_cows":1},"hens":{"hens":6,"poultry_feed":200},"mixed":{"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200}}
    for r in all_rows:
        b=baseline[(r["phase"],r["outfit_profile"],r["month"],r["seed"])];cart=dict(b["outfit"]);cart.update(extras[r["arm"]]);assert r["outfit"]==cart
    groups=[];month_groups=[];pooled=[];pairs=[]
    for phase in ["development","confirmation"]:
        for arm in ["none","goats","cow","hens","mixed"]:
            for policy in (["existing"] if arm=="none" else ["existing","aware"]):
                rr=[r for r in all_rows if (r["phase"],r["arm"],r["stock_policy"])==(phase,arm,policy)]
                pooled.append(dict(phase=phase,arm=arm,policy=policy,**summarize(rr)))
                for outfit in ["standard","lean"]:
                    selected=[r for r in rr if r["outfit_profile"]==outfit]
                    groups.append(dict(phase=phase,outfit=outfit,arm=arm,policy=policy,**summarize(selected)))
                    for month in [5,7]:month_groups.append(dict(phase=phase,outfit=outfit,month=month,arm=arm,policy=policy,**summarize([r for r in selected if r["month"]==month])))
                if arm=="none":continue
                diff=collections.Counter();days=[]
                for r in rr:
                    b=baseline[(phase,r["outfit_profile"],r["month"],r["seed"])];a=r["outcome"]=="arrived";bb=b["outcome"]=="arrived"
                    diff["both_arrive" if a and bb else "gained_arrival" if a else "lost_arrival" if bb else "neither_arrives"]+=1
                    if a and bb:days.append(r["days"]-b["days"])
                pairs.append(dict(phase=phase,arm=arm,policy=policy,pairs=len(rr),**{k:diff[k] for k in ["both_arrive","gained_arrival","lost_arrival","neither_arrives"]},median_days_delta_for_both_arrivals=median(days)))
    out=dict(frozen_study_commit="affaad9",shipped_gameplay="f685292",journeys=432,rules_signature=signature,settings=common,archives=manifest,source_hashes=frozen,groups=groups,month_groups=month_groups,pooled=pooled,paired=pairs,caveats=["Six seeds per phase repeat across two months and two outfits; scenario counts are not independent seed counts.","No game rules or study decisions were tuned to either phase.","Care-aware bundles labor, grain resupply and emergency slaughter; differences do not isolate one action causally.","No replacement-animal buying or live-animal sale optimization. This is not an optimal-human-player evaluation.","Existing ration logic switches everyone to Filling if any active traveler is below 80 health or ill. Normal buying retains $20; emergency buying keeps $10 while a future toll remains. These decision rules can constrain survival independently of livestock.","Dairy units eaten are milk/eggs only; emergency meat is reported separately as gross food added.","Raw shortage/rest totals have unequal exposure when parties die earlier; travel-day differences use paired arrivals only.","Unmet food is for the main party's requested meals; offscreen hunting provisions/returns have separate field audit."])
    path=ROOT/"docs/farmer-livestock-balance-summary-01.json";path.write_text(json.dumps(out,indent=2)+"\n",encoding="utf-8")
    for r in pooled:print(r["phase"],r["arm"],r["policy"],str(r["arrivals"])+"/"+str(r["runs"]),"food eaten",r["mean_dairy_food_eaten"],"care short",r["care_short_pct"],"unmet food",r["unmet_food_pct"])
    print("Verified and summarized",len(all_rows),"journeys")
if __name__=="__main__":main()
