"""Validate and summarize the frozen generic-fishing audit; no game simulation."""
from pathlib import Path
from itertools import product
from collections import defaultdict,Counter
from statistics import mean,median
import json,hashlib,argparse,math
POLICIES=("off","leader","support")
def summarize(folder,development_start=205000,validation_start=215000,pattern="hunting-fishing-audit-*-01.json",yield_name="fishing-yield-audit-01.json"):
 archives=sorted(folder.glob(pattern))
 if len(archives)!=6:raise ValueError("Expected six full-route archives")
 rows=[];manifest=[];rules=None;sources=None;settings=None;seen=set()
 for path in archives:
  raw=path.read_bytes();d=json.loads(raw)
  if d["errors"] or len(d["runs"])!=24:raise ValueError("Failed/incomplete journey archive")
  phase="validation" if "validation" in path.name else "development"
  if d["seed_start"]!={"development":development_start,"validation":validation_start}[phase] or d["seeds"]!=4:raise ValueError("Unexpected seed cohort")
  policy=d["fishing_policy"]
  if policy not in POLICIES:raise ValueError("Unknown fishing strategy")
  current={key:d[key] for key in ("pace","outfit_profile","months","professions","equipment","methods","reserve_meals","player_accuracy","camp_work_policy","motion_policy","fishing_policy_version","fishing_hook_accuracy","fishing_repeat_rule")}
  if settings is None:settings=current;rules=d["rules_signature"];sources=d["source_hashes"]
  if current!=settings or rules!=d["rules_signature"] or sources!=d["source_hashes"]:raise ValueError("Settings or sources changed")
  actual={(r["profession"],r["month"],r["seed"]) for r in d["runs"]}
  expected=set(product(d["professions"],d["months"],range(d["seed_start"],d["seed_start"]+d["seeds"])))
  if actual!=expected:raise ValueError("Unexpected or missing declared worlds")
  for row in d["runs"]:
   local=(phase,policy,row["profession"],row["month"],row["seed"])
   if local in seen:raise ValueError("Duplicate world")
   seen.add(local);rows.append(dict(row,phase=phase,fishing_policy=policy))
  manifest.append(dict(path=path.name,sha256=hashlib.sha256(raw).hexdigest(),runs=24))
 baseline={(r["phase"],r["profession"],r["month"],r["seed"]):r for r in rows if r["fishing_policy"]=="off"}
 groups=defaultdict(list)
 for row in rows:
  key=(row["phase"],row["profession"],row["month"],row["seed"])
  if key not in baseline:raise ValueError("Missing paired baseline")
  b=baseline[key]
  if row["outfit"]!=b["outfit"] or row["opening_cost_cents"]!=b["opening_cost_cents"] or row["opening_cash"]!=b["opening_cash"]:raise ValueError("Starting resources differ")
  groups[row["phase"],row["fishing_policy"],row["profession"]].append(row)
 results=[]
 for (phase,policy,profession),data in sorted(groups.items()):
  if len(data)!=8:raise ValueError("Expected eight worlds per profession/policy/phase")
  days=[];pairs=Counter()
  leader=[trip for r in data for trip in r["fishing"]["leader"]]
  helpers=[trip for r in data for trip in r["fishing"]["companions"]]
  for r in data:
   b=baseline[phase,profession,r["month"],r["seed"]]
   a1,a0=r["outcome"]=="arrived",b["outcome"]=="arrived"
   pairs["both_arrived" if a1 and a0 else "fishing_only" if a1 else "baseline_only" if a0 else "neither"]+=1
   if a1 and a0:days.append(r["days"]-b["days"])
  results.append(dict(phase=phase,policy=policy,profession=profession,runs=8,arrivals=sum(r["outcome"]=="arrived" for r in data),outcomes=dict(Counter(r["outcome"] for r in data)),paired_outcomes=dict(pairs),paired_arrival_day_changes=days,median_paired_arrival_day_change=median(days) if days else None,
   mean_original_survivors=round(mean(r["original_survived"] for r in data),3),median_miles=median(r["miles"] for r in data),underfed_days=sum(r["audit"]["underfed_days"] for r in data),hunting_shots=sum(r["counts"]["shots"]+r["field"]["shots"] for r in data),leader_hunts=sum(r["counts"]["hunts"] for r in data),stationary_days=sum(r["motion"]["stationary_days"] for r in data),end_cash=[r["cash"] for r in data],
   leader_fishing_days=len(leader),leader_caught_edible_lb=sum(r["caught_edible_lb"] for r in leader),leader_retrieved_lb=sum(r["retrieved"] for r in leader),leader_meal_food_units=sum(r["eaten_food"] for r in leader),leader_packed_food_units=sum(r["food"] for r in leader),leader_party_food_delta=sum(r["party_food_delta"] for r in leader),leader_left_lb=round(sum(r["left"] for r in leader),3),
   companion_fishing_days=len(helpers),companion_returned_edible_lb=sum(r["mass"] for r in helpers),companion_returned_food_units=sum(r["food"] for r in helpers),
   sampled_access={key:sum(r["counts"][key] for r in data) for key in ("fishing_access_walk_days","fishing_access_horse_only_days","fishing_water_but_no_horse_days","fishing_blocked_weather_days")}))
 p=folder/yield_name;raw=p.read_bytes();d=json.loads(raw)
 if d["errors"] or len(d["runs"])!=1800 or d["rules_signature"]!=rules or d["source_hashes"]!=sources:raise ValueError("Yield audit incompatible/incomplete")
 manifest.append(dict(path=p.name,sha256=hashlib.sha256(raw).hexdigest(),runs=1800))
 cells=defaultdict(list)
 for row in d["runs"]:cells[row["distance"],row["ration"],row["leader_health"]].append(row)
 yields=[]
 for (distance,ration,health),data in sorted(cells.items()):
  if len(data)!=100 or {r["seed"] for r in data}!=set(range(225000,225100)):raise ValueError("Incomplete yield cell")
  energy=sum(r["retrieved_kcal"] for r in data)
  generated=sum(r.get("generated_food",max(1,math.floor(r["retrieved_kcal"]/1000+0.5)) if r["retrieved"]>0 else 0) for r in data)
  yields.append(dict(distance=distance,ration=ration,health=health,trips=100,mean_casts=round(mean(r["casts_used"] for r in data),3),mean_caught_edible_lb=round(mean(r["caught_edible_lb"] for r in data),3),mean_retrieved_lb=round(mean(r["retrieved"] for r in data),3),mean_generated_food_units=generated/100,mean_party_food_delta=round(mean(r["party_food_delta"] for r in data),3),mean_packed_food_units=round(mean(r["food"] for r in data),3),zero_catch_trips=sum(r["caught_edible_lb"]==0 for r in data),rounding_energy_bias_pct=round(100*(generated*1000-energy)/energy,3) if energy else None))
 return dict(full_journeys=len(rows),controlled_trips=1800,settings=settings,rules_signature=rules,source_hashes=sources,inputs=manifest,groups=results,yield_cells=yields,caveat="Use the archived rules signature for the actual fish profiles. These bounded scripts are not optimal human strategies. Party food delta includes meals and other camp work. Historical generic reports lack generated_food; only those legacy rows use the old minimum-one reconstruction.")
if __name__=="__main__":
 p=argparse.ArgumentParser();p.add_argument("--folder",type=Path,default=Path(".tools"));p.add_argument("--output",type=Path,required=True);p.add_argument("--development-start",type=int,default=205000);p.add_argument("--validation-start",type=int,default=215000);p.add_argument("--pattern",default="hunting-fishing-audit-*-01.json");p.add_argument("--yield-name",default="fishing-yield-audit-01.json");a=p.parse_args()
 result=summarize(a.folder,a.development_start,a.validation_start,a.pattern,a.yield_name);a.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8");print("Summarized",result["full_journeys"],"journeys and",result["controlled_trips"],"controlled trips")
 for r in result["groups"]:print(r["phase"],r["policy"],r["profession"],"arrivals",r["arrivals"],"underfed",r["underfed_days"],"leader days",r["leader_fishing_days"],"helper food",r["companion_returned_food_units"])
 for r in result["yield_cells"]:
  if r["health"]==100:print("YIELD",r)
