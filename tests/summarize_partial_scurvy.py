"""Verify the focused treatment change and eight diagnostic integration replays."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 baseline=read(ROOT/"docs/scurvy-trace-summary-01.json")
 result={"runtime":"a27064d","previous":"c324b68","journeys":8,"purpose":"Repeated diagnostic integration cases, not new independent survival evidence.","errors":0,"cases":[],"archives":[],"source_hashes":None}
 for arm in ["none","goats"]:
  name="hunting-partial-scurvy-standard-"+arm+"-01.json";path=ROOT/".tools"/name;d=read(path)
  oldname="hunting-scurvy-trace-standard-"+arm+"-01.json";oldpath=ROOT/".tools"/oldname
  assert digest(oldpath)==next(a["sha256"] for a in baseline["archives"] if a["file"]==oldname)
  old=read(oldpath);assert d["rules_signature"]==old["rules_signature"] and not d["errors"] and len(d["runs"])==4 and d["seed_start"]==525000 and d["seeds"]==4 and d["months"]==[5]
  for k in ["outfit_profile","livestock_arm","farmer_mastery","player_accuracy","pace","reserve_meals","motion_policy","camp_work_policy","feeding_policy","stock_policy","fishing_policy"]:assert d[k]==old[k],k
  assert not re.search(r"ERROR:|FAIL:",(ROOT/".tools"/("partial-scurvy-"+arm+"-01.log")).read_text())
  if result["source_hashes"] is None:result["source_hashes"]=d["source_hashes"]
  assert result["source_hashes"]==d["source_hashes"]
  originals={r["seed"]:r for r in old["runs"]}
  for r in d["runs"]:
   o=originals[r["seed"]]
   for k in ["outfit","opening_cash","opening_cost_cents"]:assert r[k]==o[k]
   traces=r["nutrition_trace"];assert len(traces)==r["days"]
   partial=[t["day"] for t in traces if 0<t["meal"]["vitamin"]<t["vitamin_target"] and any(p["active"] and p["scurvy"] for p in t["before"])]
   result["cases"].append({"arm":arm,"seed":r["seed"],"before":{k:o[k] for k in ["outcome","days","original_present"]},"after":{k:r[k] for k in ["outcome","days","original_present"]},"partial_treatment_days":partial})
  copy=ROOT/".tools/partial-scurvy-archives"/name;copy.parent.mkdir(exist_ok=True)
  if copy.exists():assert copy.read_bytes()==path.read_bytes()
  else:copy.write_bytes(path.read_bytes())
  result["archives"].append({"file":name,"sha256":digest(path)})
 for name,sha in result["source_hashes"].items():
  assert digest(ROOT/name)==sha,name
  assert subprocess.check_output(["git","show",result["runtime"]+":"+name],cwd=ROOT).replace(b"\r\n",b"\n")== (ROOT/name).read_bytes().replace(b"\r\n",b"\n"),name
 log=(ROOT/".tools/partial-scurvy-full-tests.log").read_text();assert len(re.findall(r"^Godot Engine",log,re.M))==89 and "Partial scurvy treatment: 25 checks, 0 failures" in log and not re.search(r"ERROR:|FAIL:",log)
 result["test_suites"]=89
 assert all(c["before"]==c["after"] for c in result["cases"])
 (ROOT/"docs/partial-scurvy-validation-01.json").write_text(json.dumps(result,indent=2)+"\n")
 print("All 89 suites pass; eight complete integration replays/archives verified. Arrival outcomes, days and survivors unchanged; no partial-treatment days in this narrow replay set.")
if __name__=="__main__":main()
