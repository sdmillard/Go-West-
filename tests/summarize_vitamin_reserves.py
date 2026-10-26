"""Validate all final gradual-reserve integration cases, including losses."""
from pathlib import Path
import collections,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 old_manifest=read(ROOT/"docs/partial-scurvy-validation-01.json")
 out={"runtime":"52f3a04b18e1e3ddb209373d62021b489a947dfb","journeys":16,"reports":4,"errors":0,"fresh_underlying_seeds":4,"limitations":["Eight cases replay prior diagnostic seeds; eight fresh cases repeat four seeds across stock arms.","Standard-May planning65 only; no universal win-rate, route or profession balance claim.","Initial ratio2/suffix01 and preliminary ratio8/suffix02 are excluded in full, including successes.","Ratio8 is authored and evidence-informed, not an assay of generic fruit or a clinical nutrient model."],"source_hashes":None,"archives":[],"cases":[],"daily_reserve_checks":0}
 for phase in ["replay","fresh"]:
  for arm in ["none","goats"]:
   name="hunting-vitamin-reserve-"+phase+"-"+arm+"-03.json";p=ROOT/".tools"/name;d=read(p)
   assert not d["errors"] and len(d["runs"])==4 and d["seed_start"]==(525000 if phase=="replay" else 535200) and d["seeds"]==4 and d["months"]==[5]
   for k,v in {"outfit_profile":"standard","livestock_arm":arm,"farmer_mastery":"skilled","player_accuracy":.65,"pace":1,"reserve_meals":2,"motion_policy":"mobile","camp_work_policy":"support","feeding_policy":"fodder","stock_policy":"aware","fishing_policy":"support"}.items():assert d[k]==v,k
   assert not re.search(r"ERROR:|FAIL:",(ROOT/".tools"/("vitamin-reserve-"+phase+"-"+arm+"-03.log")).read_text())
   if out["source_hashes"] is None:out["source_hashes"]=d["source_hashes"];out["rules_signature"]=d["rules_signature"]
   assert out["source_hashes"]==d["source_hashes"] and out["rules_signature"]==d["rules_signature"]
   prior={}
   if phase=="replay":
    oldname="hunting-partial-scurvy-standard-"+arm+"-01.json";op=ROOT/".tools"/oldname
    assert sha(op)==next(a["sha256"] for a in old_manifest["archives"] if a["file"]==oldname)
    prior={r["seed"]:r for r in read(op)["runs"]}
   for r in d["runs"]:
    assert round(r["opening_cash"]*100)+r["opening_cost_cents"]==67500
    trace=r["nutrition_trace"];assert len(trace)==r["days"] and [t["day"] for t in trace]==list(range(1,r["days"]+1))
    for t in trace:
     coverage=max(0,min(1,t["meal"]["vitamin"]/t["vitamin_target"]))
     change=1000-8*int(coverage*1000+0.5)
     for before,after in zip(t["before"],t["after"]):
      if not before["active"] or not after["active"]:continue
      assert after["reserve_debt_milli"]==max(0,min(100000000,before["reserve_debt_milli"]+change)),(phase,arm,r["seed"],t["day"])
      out["daily_reserve_checks"]+=1
    row={"phase":phase,"arm":arm,"seed":r["seed"],"outcome":r["outcome"],"days":r["days"],"original_present":r["original_present"],"scurvy_deaths":r["death_causes"].count("scurvy"),"scurvy_person_days":r["audit"]["scurvy_person_days"]}
    if prior:
     o=prior[r["seed"]]
     for k in ["outfit","opening_cash","opening_cost_cents"]:assert r[k]==o[k]
     row["prior"]={k:o[k] for k in ["outcome","days","original_present"]}
    out["cases"].append(row)
   copy=ROOT/".tools/vitamin-reserve-archives"/name;copy.parent.mkdir(exist_ok=True)
   if copy.exists():assert copy.read_bytes()==p.read_bytes()
   else:copy.write_bytes(p.read_bytes())
   out["archives"].append({"file":name,"sha256":sha(p)})
 for name,digest in out["source_hashes"].items():
  assert sha(ROOT/name)==digest,name
  assert subprocess.check_output(["git","show",out["runtime"]+":"+name],cwd=ROOT).replace(b"\r\n",b"\n")== (ROOT/name).read_bytes().replace(b"\r\n",b"\n"),name
 log=(ROOT/".tools/vitamin-reserve-final-tests-03.log").read_text();assert len(re.findall(r"^Godot Engine",log,re.M))==90 and "Vitamin reserves: 34 checks, 0 failures" in log and not re.search(r"ERROR:|FAIL:",log)
 out["test_suites"]=90
 out["totals"]={}
 for phase in ["replay","fresh"]:
  rows=[r for r in out["cases"] if r["phase"]==phase]
  out["totals"][phase]={"journeys":len(rows),"arrivals":sum(r["outcome"]=="arrived" for r in rows),"four_original_arrivals":sum(r["outcome"]=="arrived" and r["original_present"]>=4 for r in rows),"scurvy_deaths":sum(r["scurvy_deaths"] for r in rows)}
 (ROOT/"docs/vitamin-reserve-validation-03.json").write_text(json.dumps(out,indent=2)+"\n")
 print("Verified 16 journeys, four archives,",out["daily_reserve_checks"],"daily reserve transitions and 90 suites.")
 print(out["totals"])
if __name__=="__main__":main()
