"""Validate diagnostic replays against published mastery outcomes and summarize treatment."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def main():
 result={"journeys":8,"new_independent_journeys":0,"purpose":"Diagnostic replays of existing standard-May confirmation cases, not new balance evidence.","source_hashes":None,"rules_signature":None,"archives":[],"cases":[],"errors":0}
 for arm in ["none","goats"]:
  name="hunting-scurvy-trace-standard-"+arm+"-01.json";p=ROOT/".tools"/name
  d=read(p);assert not d["errors"] and len(d["runs"])==4 and d["seed_start"]==525000 and d["seeds"]==4 and d["months"]==[5]
  assert d["farmer_mastery"]=="skilled" and d["player_accuracy"]==.65 and d["nutrition_trace_version"]==1
  assert not re.search(r"ERROR:|FAIL:",(ROOT/".tools"/("scurvy-trace-"+arm+"-01.log")).read_text())
  if result["source_hashes"] is None:result["source_hashes"]=d["source_hashes"];result["rules_signature"]=d["rules_signature"]
  assert d["source_hashes"]==result["source_hashes"] and d["rules_signature"]==result["rules_signature"]
  old=read(ROOT/".tools"/("hunting-farmer-mastery-planning65-confirmation-standard-"+arm+"-02.json"));key={r["seed"]:r for r in old["runs"] if r["month"]==5}
  for r in d["runs"]:
   for k,v in key[r["seed"]].items():assert r[k]==v,(arm,r["seed"],k)
   trace=r["nutrition_trace"];assert len(trace)==r["days"] and [t["day"] for t in trace]==list(range(1,r["days"]+1))
   sick=[t for t in trace if any(m["active"] and m["scurvy"] for m in t["before"])]
   adequate=lambda t:t["meal"]["vitamin"]>=t["vitamin_target"]
   case={"arm":arm,"seed":r["seed"],"outcome":r["outcome"],"days":r["days"],"scurvy_days":len(sick),"adequately_treated_scurvy_days":sum(adequate(t) for t in sick),"partial_produce_scurvy_days":sum(0<t["meal"]["vitamin"]<t["vitamin_target"] for t in sick),"all_adequate_vitamin_days":sum(adequate(t) for t in trace),"produce_held_but_zero_served_days":sum(t["stock_before"]["units"]>0 and t["meal"]["vitamin"]==0 for t in trace),"events":[]}
   for t in trace:
    for before,after in zip(t["before"],t["after"]):
     event=None
     if not before["scurvy"] and after["scurvy"]:event="onset"
     if before["scurvy"] and not after["scurvy"]:event="cleared"
     if before["active"] and not after["active"] and after["cause"]=="scurvy":event="death"
     if event:case["events"].append({"event":event,"day":t["day"],"member":after["id"],"health":after["health"],"scurvy":after["scurvy"]})
   result["cases"].append(case)
  archive=ROOT/".tools/scurvy-trace-archives"/name;archive.parent.mkdir(exist_ok=True)
  if archive.exists():assert archive.read_bytes()==p.read_bytes()
  else:archive.write_bytes(p.read_bytes())
  result["archives"].append({"file":name,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()})
 for name,digest in result["source_hashes"].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
 for name in subprocess.check_output(["git","ls-tree","-r","--name-only","03c2b4b","simulation","data"],cwd=ROOT,text=True).splitlines():assert subprocess.check_output(["git","show","03c2b4b:"+name],cwd=ROOT).replace(b"\r\n",b"\n")== (ROOT/name).read_bytes().replace(b"\r\n",b"\n"),name
 log=(ROOT/".tools/scurvy-audit-full-tests.log").read_text();assert len(re.findall(r"^Godot Engine",log,re.M))==88 and "Scurvy trace: 14 checks, 0 failures" in log and not re.search(r"ERROR:|FAIL:",log)
 result["test_suites"]=88
 (ROOT/"docs/scurvy-trace-summary-01.json").write_text(json.dumps(result,indent=2)+"\n")
 for c in result["cases"]:print(c["arm"],c["seed"],"scurvy days",c["scurvy_days"],"adequate treatment",c["adequately_treated_scurvy_days"],"held/ignored",c["produce_held_but_zero_served_days"])
 print("All eight replays match every previously published journey field; gameplay unchanged; 88 suites pass.")
if __name__=="__main__":main()
