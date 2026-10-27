"""Validate the frozen 96-case crew/craft comparison and publish compact evidence."""
from pathlib import Path
from copy import deepcopy
import argparse,collections,datetime,hashlib,itertools,json,statistics
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def median(xs):return statistics.median(xs) if xs else None
def date(r):return (datetime.date(1848,r["month"],1)+datetime.timedelta(days=r["days"])).isoformat()
def ledger(r):
 e=r["earnings"];out=collections.Counter()
 for sale in e["sales"]:
  out["sale_days"]+=sale["days"]
  for g in sale["goods"]:
   kind="keepsakes" if g["item"].startswith("keepsake_") else "craft" if g["item"] in ["buckskin","buckskin_gloves"] else "pelts"
   out[kind+"_cents"]+=g["cents"];out[g["item"]+"_sold"]+=g["quantity"]
 for ev in e["events"]:
  if ev["event"]=="settlement_wages":out["work_cents"]+=round(ev["changes"]["money"]*100);out["worker_days"]+=1
  if ev["event"]=="wages":out["contract_paid_cents"]-=round(ev["changes"]["money"]*100)
  if ev["event"]=="leathercraft":
   out["craft_worker_days"]+=1
   for item,n in ev["changes"].items():
    if n>0:out[item+"_made"]+=n
 out["work_days"]=len(e["crew_days"])
 out["work_meals"]=sum(x["eaten"] for x in e["crew_days"])
 craft_days={x["day"] for x in e["events"] if x["event"]=="leathercraft"}
 wage_days={x["day"] for x in e["crew_days"]}
 sale_days={x["day"] for x in e["sales"] if x["days"]}
 out["craft_calendar_days"]=len(craft_days);out["craft_work_overlap_days"]=len(craft_days&wage_days)
 out["earning_unique_days"]=len(craft_days|wage_days|sale_days)
 out["earning_unique_meals"]=sum(x["eaten"] for x in e["days"] if x["day"] in craft_days|wage_days|sale_days)
 for d in e["crew_days"]:
  for w in d["workers"]:out["wage_floor_uplift_cents"]+=max(0,w["cents"]-JOBS[w["job"]]["cents"])
 for p in e["pelt_recoveries"]:
  out["pelt_preparation_days"]+=p["recovery"].get("preparation_days",0)
  out["pelt_preparation_meals"]+=p["recovery"].get("preparation_food_units",0)
  out["raw_haul_displaced_lb"]+=p["raw_haul_displaced_lb"]
 out["gross_cents"]=sum(out[k+"_cents"] for k in ["keepsakes","pelts","craft","work"])
 out["arrears_cents"]=e["final_contract"].get("arrears_cents",0)
 out["missed_wages"]=e["final_contract"].get("misses",0)
 return dict(out)
JOBS=read(ROOT/"data/trail_income.json")["jobs"]
SITES=read(ROOT/"data/trail_income.json")["sites"]
CRAFT=read(ROOT/"data/leathercraft.json")
def check_row(r):
 e=r["earnings"];days=e["days"];events=e["events"];crew=e["crew_days"]
 assert len(days)==r["days"]==r["audit"]["days"]==sum(r["motion"]["actions"].values())
 assert len({x["day"] for x in days})==len(days)
 assert round(r["opening_cash"]*100)+r["opening_cost_cents"]==67500
 assert r["outcome"] in ["arrived","lost","year_limit"]
 audit=r["feeding_comparison"]["audit"]
 assert abs(audit["meal_requested"]-audit["meal_eaten"]-audit["meal_short"])<1e-5
 spoil=r["preservation_audit"];assert spoil["classification_errors"]==0
 assert sum(spoil[k] for k in ["raw_meat_spoiled","dried_meat_spoiled","produce_spoiled","other_spoiled"])==r["spoilage_food_units"]
 receipts=[x for x in events if x["event"]=="settlement_wages"]
 assert len(crew)==r["motion"]["actions"].get("settlement_work",0)
 assert len(receipts)==sum(e["work_record"].values())==sum(len(x["workers"]) for x in crew)
 places=collections.Counter()
 for d in crew:
  assert d["valid"] and d["cents"]==sum(x["cents"] for x in d["workers"])
  assert d["requested"]==d["meals"] and 0<=d["eaten"]<=d["requested"]+1e-6
  assert len({w["id"] for w in d["workers"]})==len(d["workers"])<=SITES[d["place"]]["workers_per_day"]
  used=collections.Counter(w["job"] for w in d["workers"])
  for job,n in used.items():assert n<=JOBS[job]["openings"]
  for w in d["workers"]:
   assert w["cents"]==max(JOBS[w["job"]]["cents"],w["market_cents"])
   matching=[x for x in receipts if x["day"]==d["day"] and x["worker"]==w["id"]]
   assert len(matching)==1 and matching[0]["job"]==w["job"] and round(matching[0]["changes"]["money"]*100)==w["cents"]
   places[d["place"]]+=1
 assert dict(places)==e["work_record"]
 for site,n in places.items():assert n<=SITES[site]["days"]
 available=collections.Counter()
 for p in e["pelt_recoveries"]:available.update(p["recovery"].get("pelts",{}))
 recipes=[{s["input"]:-1,s["output"]:s["amount"]} for recipe in CRAFT["recipes"].values() for s in recipe["steps"]]
 used_pairs=set()
 for ev in events:
  if ev["event"]!="leathercraft":continue
  assert ev["changes"] in recipes
  pair=(ev["day"],ev["worker"]);assert pair not in used_pairs;used_pairs.add(pair)
  assert not any(x["day"]==ev["day"] and x["worker"]==ev["worker"] for x in receipts)
  for k,v in ev["changes"].items():available[k]+=v;assert available[k]>=0
 for sale in e["sales"]:
  for g in sale["goods"]:
   assert g["quantity"]>0 and g["cents"]>0
   if g["item"] in CRAFT["goods"]:available[g["item"]]-=g["quantity"];assert available[g["item"]]>=0
 for item,n in e["final_goods"].items():assert 0<=n<=available[item]
 if r["income_arm"]=="off":assert not crew and not e["sales"] and not e["pelt_recoveries"] and not used_pairs
 if r["income_arm"]!="craft":assert not used_pairs
 if r["contract_arm"]=="free":assert not e["final_contract"] and not any(x["event"]=="wages" for x in events)
 else:
  c=e["final_contract"];opening=e["opening"]["profiles"][2]["contract"]
  assert c["wage_cents"]==opening["wage_cents"] and c["interval_days"]==7 and c["auto_pay"]
  paid=-sum(round(x["changes"]["money"]*100) for x in events if x["event"]=="wages")
  assert paid+c["arrears_cents"]==max(0,c["last_due_day"]//7)*c["wage_cents"]

def negative_checks(rows):
 r=next(r for r in rows if r["income_arm"]=="craft" and r["contract_arm"]=="free" and r["earnings"]["crew_days"] and any(e["event"]=="leathercraft" for e in r["earnings"]["events"]))
 def reject(original,change):
  bad=deepcopy(original);change(bad)
  try:check_row(bad)
  except AssertionError:return
  raise AssertionError("Accounting verifier accepted deliberately corrupt evidence")
 reject(r,lambda r:r["earnings"]["days"].append(r["earnings"]["days"][0]))
 reject(r,lambda r:r["earnings"]["events"].remove(next(e for e in r["earnings"]["events"] if e["event"]=="settlement_wages")))
 reject(r,lambda r:r["earnings"]["crew_days"][0]["workers"][0].update(cents=99999))
 reject(r,lambda r:next(e for e in r["earnings"]["events"] if e["event"]=="leathercraft").update(changes={"deer_hide":-1,"buckskin_gloves":4}))
 reject(r,lambda r:r["earnings"]["events"].append(deepcopy(next(e for e in r["earnings"]["events"] if e["event"]=="leathercraft"))))
 reject(r,lambda r:r["earnings"]["final_goods"].update(buckskin_gloves=99999))
 hired=next(r for r in rows if r["contract_arm"]=="hired")
 reject(hired,lambda r:r["earnings"]["final_contract"].update(arrears_cents=r["earnings"]["final_contract"]["arrears_cents"]+1))
 return 7

def summarize(rows):
 ledgers=[ledger(r) for r in rows];arr=[r for r in rows if r["outcome"]=="arrived"]
 totals=collections.Counter()
 for x in ledgers:totals.update(x)
 return {"runs":len(rows),"arrivals":len(arr),"four_original_arrivals":sum(r["original_present"]>=4 for r in arr),"five_original_arrivals":sum(r["original_present"]==5 for r in arr),"before_october":sum(date(r)<"1848-10-01" for r in arr),"short_units":round(sum(r["livestock"]["short_units"] for r in rows),3),"food_deaths":sum("lack of food" in d["cause"] for r in rows for d in r["livestock"]["deaths"]),"median_gross_cents":median([x["gross_cents"] for x in ledgers]),"median_contract_paid_cents":median([x.get("contract_paid_cents",0) for x in ledgers]),"median_work_cents":median([x.get("work_cents",0) for x in ledgers]),"cases_working":sum(x["work_days"]>0 for x in ledgers),"cases_crafting":sum(x.get("craft_worker_days",0)>0 for x in ledgers),"cases_selling_craft":sum(x.get("craft_cents",0)>0 for x in ledgers),"totals":dict(totals)}
def main():
 parser=argparse.ArgumentParser();parser.add_argument("--check",action="store_true");args=parser.parse_args()
 rows=[];archives=[];sources=None;rules=None
 for contract,stock,arm in itertools.product(["free","hired"],["none","goats"],["off","crew","craft"]):
  label=f"crew-craft-01-{contract}-{stock}-{arm}"
  p=ROOT/".tools"/f"hunting-{label}.json";receipt=read(ROOT/".tools/crew-craft-archives"/f"receipt-{label}.json")
  d=read(p);copy=ROOT/".tools/crew-craft-archives"/receipt["file"]
  assert sha(p)==sha(copy)==receipt["sha256"]
  assert not any(x in (ROOT/".tools"/f"{label}.log").read_text(encoding="utf-8-sig") for x in ["SCRIPT ERROR:","ERROR:","FAIL:"])
  assert not d["errors"] and len(d["runs"])==8
  for key,value in {"seed_start":571000,"seeds":4,"months":[4,5],"income_arm":arm,"contract_arm":contract,"livestock_arm":stock,"crew_craft_policy_version":1,"farmer_mastery":"skilled","player_accuracy":.65,"pace":1,"motion_policy":"mobile","camp_work_policy":"support","fishing_policy":"support","stock_policy":"aware","feeding_policy":"fodder"}.items():assert d[key]==value,(label,key)
  if sources is None:sources=d["source_hashes"];rules=d["rules_signature"]
  assert sources==d["source_hashes"] and rules==d["rules_signature"]
  assert {(r["seed"],r["month"]) for r in d["runs"]}==set(itertools.product(range(571000,571004),[4,5]))
  archives.append(receipt)
  for raw in d["runs"]:
   r=dict(raw,stock=stock,income_arm=arm,contract_arm=contract);check_row(r);rows.append(r)
 for file,expected in sources.items():assert sha(ROOT/file)==expected,file
 for contract,stock,seed,month in itertools.product(["free","hired"],["none","goats"],range(571000,571004),[4,5]):
  group=[r for r in rows if (r["contract_arm"],r["stock"],r["seed"],r["month"])==(contract,stock,seed,month)]
  assert len(group)==3 and len({json.dumps(r["earnings"]["opening"],sort_keys=True) for r in group})==1
 negative_count=negative_checks(rows)
 output={"negative_accounting_checks":negative_count,"protocol_sha256":sha(ROOT/"docs/CREW_CRAFT_PROTOCOL.md"),"protocol":"docs/CREW_CRAFT_PROTOCOL.md","rules_signature":rules,"source_hashes":sources,"archives":archives,"summaries":{},"cases":[]}
 for contract in ["all","free","hired"]:
  for arm in ["off","crew","craft"]:
   output["summaries"][contract+"/"+arm]=summarize([r for r in rows if r["income_arm"]==arm and (contract=="all" or r["contract_arm"]==contract)])
 output["pairs"]={}
 for contract in ["all","free","hired"]:
  for base,arm in [("off","crew"),("off","craft"),("crew","craft")]:
   candidates=[r for r in rows if r["income_arm"]==base and (contract=="all" or r["contract_arm"]==contract)]
   pairs=[]
   for a in candidates:
    b=next(r for r in rows if r["income_arm"]==arm and (r["contract_arm"],r["stock"],r["seed"],r["month"])==(a["contract_arm"],a["stock"],a["seed"],a["month"]))
    pairs.append((a,b))
   shared=[b["days"]-a["days"] for a,b in pairs if a["outcome"]==b["outcome"]=="arrived"]
   output["pairs"][contract+"/"+base+"->"+arm]={"pairs":len(pairs),"arrival_gains":sum(a["outcome"]!="arrived" and b["outcome"]=="arrived" for a,b in pairs),"arrival_losses":sum(a["outcome"]=="arrived" and b["outcome"]!="arrived" for a,b in pairs),"shared_arrivals":len(shared),"shared_arrival_day_delta_median":median(shared),"shared_arrival_day_delta_range":[min(shared),max(shared)] if shared else [],"food_deficit_delta":round(sum(b["livestock"]["short_units"]-a["livestock"]["short_units"] for a,b in pairs),3)}
 for contract,stock,arm in itertools.product(["free","hired"],["none","goats"],["off","crew","craft"]):
  output["summaries"][contract+"/"+stock+"/"+arm]=summarize([r for r in rows if (r["contract_arm"],r["stock"],r["income_arm"])==(contract,stock,arm)])
 for r in rows:
  output["cases"].append({k:r[k] for k in ["seed","month","stock","income_arm","contract_arm","outcome","days","original_present","original_survived","cash","food","counts"]}|{"date":date(r),"income":ledger(r),"short_units":r["livestock"]["short_units"],"first_short":r["livestock"]["first_short"],"death_causes":r["death_causes"],"final_goods":r["earnings"]["final_goods"],"final_artisan":r["earnings"]["final_artisan"],"final_contract":r["earnings"]["final_contract"]})
 target=ROOT/"docs/crew-craft-results-01.json"
 if args.check:assert read(target)==output,"Published report differs from verified raw evidence"
 else:
  assert not target.exists(),"Refusing to overwrite published results"
  target.write_bytes((json.dumps(output,indent=2)+"\n").encode("utf-8"))
 print(json.dumps(output["summaries"],indent=2));print("Verified 96 journeys, 32 matched triplets; raw archive and source hashes match.")
if __name__=="__main__":main()
