"""Accept every declared current-rule journey before summarizing the bounded pass."""
from pathlib import Path
import datetime,hashlib,itertools,json,re,statistics,subprocess
from summarize_farmer_mastery import summarize as base_summary,paired
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def date(r):return datetime.date(1848,r["month"],1)+datetime.timedelta(days=r["days"])
def summary(rows):
 s=base_summary(rows)
 arrivals=[r for r in rows if r["outcome"]=="arrived"]
 s["arrivals_before_october"]=sum(date(r)<datetime.date(1848,10,1) for r in arrivals)
 s["three_originals_before_october"]=sum(date(r)<datetime.date(1848,10,1) and r["original_present"]>=3 for r in arrivals)
 s["three_originals_before_november"]=sum(date(r)<datetime.date(1848,11,1) and r["original_present"]>=3 for r in arrivals)
 s["mean_actions"]={action:round(statistics.mean(r["motion"]["actions"].get(action,0) for r in rows),3) for action in sorted({action for r in rows for action in r["motion"]["actions"]})}
 s["arrival_survivors"]=[{"seed":r["seed"],"month":r["month"],"outfit":r["outfit_profile"],"arm":r["arm"],"date":date(r).isoformat(),"days":r["days"],"present":r["original_present"]} for r in arrivals]
 return s

def main():
 m=read(ROOT/"docs/bounded-survival-manifest-01.json")
 assert m["journeys"]==96 and m["months"]==[4,5,7] and m["seed_start"]==545000 and m["seeds"]==4 and m["accuracy"]==.65
 assert {(e["variant"],e["outfit"],e["arm"]) for e in m["entries"]}==set(itertools.product(["baseline","planning65"],["standard","lean"],["none","goats"]))
 rows=[];sources=None;signature=None;archives=[]
 for e in m["entries"]:
  p=ROOT/".tools"/e["filename"];receipt=read(ROOT/".tools"/("receipt-"+e["label"]+".json"));d=read(p)
  assert sha(p)==receipt["sha256"]==sha(Path(receipt["copy"]))
  assert not re.search(r"ERROR:|FAIL:",Path(receipt["log"]).read_text())
  assert not d["errors"] and len(d["runs"])==12 and d["seed_start"]==545000 and d["seeds"]==4 and d["months"]==[4,5,7]
  for k,v in {"farmer_mastery":e["mastery"],"outfit_profile":e["outfit"],"livestock_arm":e["arm"],"player_accuracy":.65,"professions":["farmer"],"equipment":["shared"],"methods":["foot"],"pace":1,"reserve_meals":2,"motion_policy":"mobile","camp_work_policy":"support","fishing_policy":"support","stock_policy":"aware","feeding_policy":"fodder","mastery_policy_version":1}.items():assert d[k]==v,(e["label"],k)
  if sources is None:sources=d["source_hashes"];signature=d["rules_signature"]
  assert d["source_hashes"]==sources and d["rules_signature"]==signature
  assert {(r["seed"],r["month"]) for r in d["runs"]}==set(itertools.product(range(545000,545004),[4,5,7]))
  for r in d["runs"]:
   assert round(r["opening_cash"]*100)+r["opening_cost_cents"]==67500 and r["outfit"].get("livestock_fodder",0)==0
   assert sum(r["motion"]["actions"].values())==r["days"]
   a=r["feeding_comparison"]["audit"];spoil=r["preservation_audit"]
   assert abs(a["meal_requested"]-a["meal_eaten"]-a["meal_short"])<1e-5 and a["scraps_kcal"]==0
   assert spoil["classification_errors"]==0 and sum(spoil[k] for k in ["raw_meat_spoiled","dried_meat_spoiled","produce_spoiled","other_spoiled"])==r["spoilage_food_units"]
   assert r["camp_work"]["drying_batches"]<=spoil["drying_batches"]<=r["camp_work"]["drying_batches"]+r["counts"].get("preservations",0)+r["counts"].get("expert_preservations",0)
   assert spoil["units_retained"]<=spoil["units_processed"]
   rows.append(dict(r,variant=e["variant"],outfit_profile=e["outfit"],arm=e["arm"]))
  archives.append({"file":e["filename"],"sha256":receipt["sha256"],"archive":str(Path(receipt["copy"]).relative_to(ROOT)).replace("\\","/")})
 assert len(rows)==96
 for name,digest in sources.items():
  assert sha(ROOT/name)==digest,name
  assert subprocess.check_output(["git","show",m["gameplay"]+":"+name],cwd=ROOT).replace(b"\r\n",b"\n")== (ROOT/name).read_bytes().replace(b"\r\n",b"\n"),name
 def select(**terms):return [r for r in rows if all(r[k]==v for k,v in terms.items())]
 key=lambda r:(r["outfit_profile"],r["arm"],r["month"],r["seed"])
 left={key(r):r for r in select(variant="baseline")};right={key(r):r for r in select(variant="planning65")};assert left.keys()==right.keys()
 for k,r in left.items():
  for field in ["outfit","opening_cash","opening_cost_cents"]:assert r[field]==right[k][field]
 log=(ROOT/".tools/bounded-survival-tests.log").read_text();assert len(re.findall(r"^Godot Engine",log,re.M))==90 and "Vitamin reserves: 34 checks, 0 failures" in log and not re.search(r"ERROR:|FAIL:",log)
 out={"gameplay":m["gameplay"],"journeys":96,"reports":8,"errors":0,"test_suites":90,"source_hashes":sources,"rules_signature":signature,"primary":{},"cells":{},"paired":paired(list(left.values()),list(right.values())),"archives":archives,"cases":[],"limitations":["Four underlying seeds repeated over settings; not96 independent worlds.","Existing candidates, default party, shared horse and steady pace; no optimal-human-policy claim.","Stationary time means depend on survival exposure; activity totals do not establish causality.","No gameplay or policy tuning during this pass; prior studies and pilots are separate."]}
 both=[(r,right[k]) for k,r in left.items() if r["outcome"]==right[k]["outcome"]=="arrived"]
 out["paired"]["median_arrival_day_change_where_both_arrive"]=statistics.median(b["days"]-a["days"] for a,b in both) if both else None
 out["paired"]["both_arrival_pair_count"]=len(both)
 for variant in ["baseline","planning65"]:out["primary"][variant]=summary(select(variant=variant))
 for variant,outfit,arm,month in itertools.product(["baseline","planning65"],["standard","lean"],["none","goats"],[4,5,7]):out["cells"]["|".join(map(str,[variant,outfit,arm,month]))]=summary(select(variant=variant,outfit_profile=outfit,arm=arm,month=month))
 for r in rows:out["cases"].append({k:r[k] for k in ["variant","outfit_profile","arm","month","seed","outcome","days","miles","original_present","original_survived","cash","death_causes"]}|{"final_date":date(r).isoformat()})
 (ROOT/"docs/bounded-survival-summary-01.json").write_text(json.dumps(out,indent=2)+"\n")
 for v,r in out["primary"].items():print(v,"arrivals",r["arrivals"],"/48; timely3+",r["three_originals_before_october"],"; beforeNovember",r["arrivals_before_november"],"; four+",r["arrivals_four_or_more_originals"])
 print("Verified all96 journeys/eight reports, paired assets, frozen source, food reconciliation, archive hashes and90 suites.")
if __name__=="__main__":main()
