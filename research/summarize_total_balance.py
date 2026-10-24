"""Validate complete frozen cohorts, compare matching scenarios, and publish a compact audit."""
import argparse, collections, hashlib, itertools, json, statistics
from pathlib import Path
IDENTITIES={
 "broad":("profession","month","roster","strategy","seed"),
 "mount":("profession","mode","month","strategy","seed"),
 "emergency":("mode","health_case","distance","month","seed"),
}
def aggregate(rows,kind):
 wins=[r for r in rows if r["outcome"]==("reached_help" if kind=="emergency" else "arrived")]
 return dict(n=len(rows),successes=len(wins),intact=sum(r["original_present"]==5 for r in wins),
  outcomes=dict(collections.Counter(r["outcome"] for r in rows)),
  median_success_days=statistics.median(r["days"] for r in wins) if wins else None,
  deaths=dict(collections.Counter(c for r in rows for c in r["death_causes"])),
  underfed_days=sum(r["audit"]["underfed_days"] for r in rows),
  working_days=sum(r["audit"]["working_days"] for r in rows),
  rest_days=sum(r["audit"]["rest_days"] for r in rows),
  other_days=sum(r["audit"]["other_days"] for r in rows),
  hunts=sum(r["counts"]["hunts"] for r in rows),
  animal_breakdowns=sum(r.get("breakdowns",0) for r in rows),
  wages_paid_cents=sum(r.get("wages_paid_cents",0) for r in rows),
  wages_owed_cents=sum(r.get("wages_owed_cents",0) for r in rows),
  departures=sum(r.get("departures",0) for r in rows),
  wanted_encounters=sum(r.get("wanted_encounters",0) for r in rows),
  scurvy_cases=sum(r.get("scurvy_cases",0) for r in rows))
def cohort(root,spec):
 kind=spec["kind"];fields=IDENTITIES[kind];rows=[];archives=[];frozen=None;settings_seen=None
 for relative in spec["files"]:
  path=root/relative
  data=json.loads(path.read_text(encoding="utf-8-sig"))
  if data["errors"]:raise ValueError(f"{path}: campaign errors")
  if not data.get("source_hashes") or not data.get("rules_signature"):raise ValueError(f"{path}: no source identity")
  identity={k:data[k] for k in ("rules_signature","source_hashes","seed_start","seed_count")}
  if frozen is not None and identity!=frozen:raise ValueError(f"{path}: source/seed mismatch within cohort")
  frozen=identity
  run_settings={k:data[k] for k in ("settings","accuracy","stress","rest_below","protocol") if k in data}
  if settings_seen is not None and settings_seen!=run_settings:raise ValueError("Settings differ within cohort")
  settings_seen=run_settings
  rows.extend(data["runs"])
  archives.append(dict(path=relative,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
 keys=[tuple(r[f] for f in fields) for r in rows]
 expected=set(itertools.product(*(spec["dimensions"][f] for f in fields)))
 if len(keys)!=len(set(keys)) or set(keys)!=expected:raise ValueError(f'{spec["id"]}: missing, duplicate or unexpected cases')
 for r in rows:
  if r["outcome"] in ("policy_stalled","policy_blocked","invariant_failed","save_failed","action_limit"):raise ValueError("Invalid outcome")
  if r["audit"]["days"]!=r["days"]:raise ValueError("Day accounting mismatch")
  if r["audit"]["working_days"]+r["audit"]["rest_days"]+r["audit"]["other_days"]!=r["days"]:raise ValueError("Daily action accounting mismatch")
 dimensions={}
 for field in fields:
  if field=="seed":continue
  dimensions[field]={str(v):aggregate([r for r in rows if r[field]==v],kind) for v in spec["dimensions"][field]}
 cells=[]
 for key,group in itertools.groupby(sorted(rows,key=lambda r:tuple(r[f] for f in fields[:-1])),lambda r:tuple(r[f] for f in fields[:-1])):
  cells.append(dict(zip(fields[:-1],key))|aggregate(list(group),kind))
 compact=[]
 for r in rows:
  item={k:r[k] for k in fields}
  for field in ("outcome","days","original_present","survivors","cash","food","death_causes","audit","counts","departures","wages_paid_cents","wages_owed_cents","recruited","wanted_encounters","sentences","scurvy_cases","miles_per_moving_day","breakdowns","route"):
   if field in r:item[field]=r[field]
  if kind=="emergency":
   fixture=dict(r["initial_fixture"]);fixture.pop("rules")
   item["initial_fixture_sha256"]=hashlib.sha256(json.dumps(fixture,sort_keys=True,separators=(",",":")).encode()).hexdigest()
  compact.append(item)
 return dict(id=spec["id"],kind=kind,archives=archives,frozen=frozen,
  settings={k:data[k] for k in ("settings","accuracy","stress","rest_below","protocol") if k in data},
  total=aggregate(rows,kind),by_dimension=dimensions,cells=cells,runs=compact)
def build(root,protocol):
 result={s["id"]:cohort(root,s) for s in protocol["cohorts"]}
 pairs=[]
 for first,second in protocol["comparisons"]:
  a,b=result[first],result[second];fields=IDENTITIES[a["kind"]]
  if a["kind"]!=b["kind"] or a["settings"]!=b["settings"]:raise ValueError("Different comparison policy/settings")
  aa={tuple(r[f] for f in fields):r for r in a["runs"]};bb={tuple(r[f] for f in fields):r for r in b["runs"]}
  if set(aa)!=set(bb):raise ValueError("Unmatched scenario keys")
  common=("tests/current_journey_policy.gd","tests/full_trail_balance.gd","tests/balance_observer.gd")
  for f in common:
   if a["frozen"]["source_hashes"][f]!=b["frozen"]["source_hashes"][f]:raise ValueError("Different decision or observer sources")
  if a["kind"]=="emergency" and any(aa[k]["initial_fixture_sha256"]!=bb[k]["initial_fixture_sha256"] for k in aa):raise ValueError("Different initial emergency fixtures")
  target="reached_help" if a["kind"]=="emergency" else "arrived"
  pairs.append(dict(before=first,after=second,matched_cases=len(aa),
   both_succeed=sum(aa[k]["outcome"]==target and bb[k]["outcome"]==target for k in aa),
   before_only=sum(aa[k]["outcome"]==target and bb[k]["outcome"]!=target for k in aa),
   after_only=sum(aa[k]["outcome"]!=target and bb[k]["outcome"]==target for k in aa)))
 for first,second in protocol["frozen_validation"]:
  a,b=result[first],result[second]
  for field in ("rules_signature","source_hashes"):
   if a["frozen"][field]!=b["frozen"][field]:raise ValueError("Validation sources differ from development")
 return dict(protocol=protocol,cohorts=result,comparisons=pairs,total_runs=sum(c["total"]["n"] for c in result.values()),errors=[])
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("protocol",type=Path);p.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[1]);p.add_argument("--output",type=Path,required=True)
 args=p.parse_args()
 if args.output.exists():p.error("Choose an unused archive")
 result=build(args.root,json.loads(args.protocol.read_text()))
 blocks={}
 for key,cohort_data in result["cohorts"].items():
  token="__SCENARIOS_"+key+"__"
  blocks[token]=cohort_data["runs"]
  cohort_data["runs"]=token
 encoded=json.dumps(result,indent=1)
 for token,rows in blocks.items():
  block="["+chr(10)+(","+chr(10)).join(json.dumps(r,separators=(",",":")) for r in rows)+chr(10)+"]"
  encoded=encoded.replace(json.dumps(token),block)
 # Validate the final serialization too, rather than trusting marker substitution.
 published=json.loads(encoded)
 for key,cohort_data in published["cohorts"].items():
  if cohort_data["runs"]!=blocks["__SCENARIOS_"+key+"__"]:raise ValueError("Scenario serialization changed")
 args.output.write_text(encoded+chr(10),encoding="utf-8")
 print(result["total_runs"],"complete frozen scenarios; zero selected errors")
if __name__=="__main__":main()
