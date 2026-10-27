"""Verify exact same-hide checkpoint pairs without pooling prior journey studies."""
from pathlib import Path
from copy import deepcopy
import argparse,collections,hashlib,itertools,json,statistics
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def median(x):return statistics.median(x) if x else None
RECIPES=read(ROOT/"data/leathercraft.json")
ITEMS=["deer_hide","bison_hide","rabbit_pelt"]+list(RECIPES["goods"])
def validate_branch(row,b):
 checkpoint=row["checkpoint"];snapshot=checkpoint["save"]
 assert b["start_sha256"]==checkpoint["save_sha256"]
 assert not any(b["harvested_after_fork"].values())
 assert b["outcome"] in ["arrived","lost","year_limit"]
 days=b["days_after_fork"]
 assert [x["day"] for x in days]==list(range(checkpoint["day"]+1,b["days"]+1))
 assert all(0<=x["eaten"]<=x["requested"]+1e-6 for x in days)
 assert b["cash"]>=0 and b["food"]>=0 and b["days"]>=checkpoint["day"]
 inventories=[snapshot["state"],snapshot.get("wagon_cache",{}).get("inventory",{})]
 inventories += [trip.get("camp",{}).get("inventory",{}) for trip in snapshot["field_outings"]["trips"]]
 available=collections.Counter({k:sum(inv.get(k,0) for inv in inventories) for k in ITEMS})
 valid_changes=[{step["input"]:-1,step["output"]:step["amount"]} for recipe in RECIPES["recipes"].values() for step in recipe["steps"]]
 used=set();paid={(x["day"],x["worker"]) for x in b["events"] if x["event"]=="settlement_wages"}
 for ev in b["events"]:
  assert checkpoint["day"]<ev["day"]<=b["days"]
  if ev["event"]!="leathercraft":continue
  assert b["arm"]=="craft" and ev["changes"] in valid_changes
  pair=(ev["day"],ev["worker"]);assert pair not in paid|used;used.add(pair)
  for k,v in ev["changes"].items():available[k]+=v;assert available[k]>=0
 for sale in b["sales"]:
  assert checkpoint["day"]<=sale["day"]<=b["days"] and sale["days"]>=0
  for g in sale["goods"]:
   assert g["quantity"]>0 and g["cents"]>0
   if g["item"] in ITEMS:available[g["item"]]-=g["quantity"];assert available[g["item"]]>=0
 for k,n in b["final_goods"].items():assert 0<=n<=available[k]
 contract=b["final_contract"]
 paid_cents=-sum(round(e["changes"]["money"]*100) for e in b["events"] if e["event"]=="wages")
 if row["contract"]=="free":assert not contract and paid_cents==0
 else:
  before=snapshot["characters"][2]["contract"]
  assert contract["wage_cents"]==before["wage_cents"] and contract["interval_days"]==before["interval_days"]==7
  newly_due=max(0,(contract["last_due_day"]-max(0,before["last_due_day"]))//7)*contract["wage_cents"]
  assert paid_cents+contract["arrears_cents"]==before["arrears_cents"]+newly_due

def ledger(b):
 t=collections.Counter()
 for sale in b["sales"]:
  t["sale_days"]+=sale["days"]
  for g in sale["goods"]:
   kind="keepsakes" if g["item"].startswith("keepsake_") else "finished" if g["item"] in RECIPES["goods"] else "pelts"
   t[kind+"_cents"]+=g["cents"];t[g["item"]+"_sold"]+=g["quantity"]
 for ev in b["events"]:
  if ev["event"]=="settlement_wages":t["work_cents"]+=round(ev["changes"]["money"]*100);t["worker_days"]+=1
  if ev["event"]=="wages":t["contract_paid_cents"]-=round(ev["changes"]["money"]*100)
  if ev["event"]=="leathercraft":
   t["craft_worker_days"]+=1
   for k,v in ev["changes"].items():
    if v>0:t[k+"_made"]+=v
 t["gross_cents"]=sum(t[k+"_cents"] for k in ["keepsakes","finished","pelts","work"])
 t["meal_units"]=sum(x["eaten"] for x in b["days_after_fork"])
 t["short_units"]=sum(max(0,x["requested"]-x["eaten"]) for x in b["days_after_fork"])
 t["elapsed_days"]=len(b["days_after_fork"])
 return dict(t)
def summarize(rows):
 result={"roots":len(rows),"opportunities":sum(bool(r["branches"]) for r in rows),"arms":{}}
 forks=[r for r in rows if r["branches"]]
 for arm in ["crew","craft"]:
  bs=[next(b for b in r["branches"] if b["arm"]==arm) for r in forks]
  totals=collections.Counter()
  for b in bs:totals.update(ledger(b))
  result["arms"][arm]={"n":len(bs),"arrived":sum(b["outcome"]=="arrived" for b in bs),"four_original_arrivals":sum(b["outcome"]=="arrived" and b["original_present"]>=4 for b in bs),"cases_crafting":sum(any(e["event"]=="leathercraft" for e in b["events"]) for b in bs),"cases_selling_finished":sum(ledger(b).get("finished_cents",0)>0 for b in bs),"totals":dict(totals)}
 pairs=[(r["branches"][0],r["branches"][1]) for r in forks]
 shared=[b["days"]-a["days"] for a,b in pairs if a["outcome"]==b["outcome"]=="arrived"]
 result["paired"]={"arrival_gains":sum(a["outcome"]!="arrived" and b["outcome"]=="arrived" for a,b in pairs),"arrival_losses":sum(a["outcome"]=="arrived" and b["outcome"]!="arrived" for a,b in pairs),"shared_arrivals":len(shared),"shared_arrival_days_median":median(shared),"shared_arrival_days_range":[min(shared),max(shared)] if shared else [],"craft_minus_raw_gross_median_cents":median([ledger(b)["gross_cents"]-ledger(a)["gross_cents"] for a,b in pairs]),"craft_minus_raw_elapsed_days_median":median([b["days"]-a["days"] for a,b in pairs])}
 return result

def main():
 parser=argparse.ArgumentParser();parser.add_argument("--check",action="store_true");args=parser.parse_args()
 p=ROOT/".tools/fixed-hide-01.json";d=read(p);receipt=read(ROOT/".tools/fixed-hide-archives/receipt-01.json")
 assert sha(p)==sha(ROOT/".tools/fixed-hide-archives/fixed-hide-01.json")==receipt["sha256"]
 assert not d["errors"] and d["seed_start"]==572000 and d["seeds"]==4 and len(d["rows"])==32
 assert not any(x in (ROOT/".tools/fixed-hide-confirmation-01.log").read_text(encoding="utf-8-sig") for x in ["SCRIPT ERROR:","ERROR:","FAIL:"])
 for file,digest in d["source_hashes"].items():assert sha(ROOT/file)==digest,file
 rows=d["rows"]
 assert {(r["contract"],r["stock"],r["month"],r["seed"]) for r in rows}==set(itertools.product(["free","hired"],["none","goats"],[4,5],range(572000,572004)))
 for r in rows:
  if not r["checkpoint"]:assert not r["branches"] and r["root_outcome"] in ["lost","arrived","year_limit"];continue
  assert r["root_outcome"]=="forked" and [b["arm"] for b in r["branches"]]==["crew","craft"]
  snapshot=r["checkpoint"]["save"]
  assert snapshot["state"]["seed"]==r["seed"] and snapshot["state"]["deer_hide"]==r["checkpoint"]["deer_hide"]>0
  assert sum(x["recovery"].get("pelts",{}).get("deer_hide",0) for x in r["root_hides_recovered"])>=r["checkpoint"]["deer_hide"]
  for b in r["branches"]:validate_branch(r,b)
 first=next(r for r in rows if r["branches"]);base=first["branches"][0]
 mutations=[lambda b:b.update(start_sha256="wrong"),lambda b:b["harvested_after_fork"].update(deer_hide=1),lambda b:b["days_after_fork"].append(b["days_after_fork"][0]),lambda b:b["final_goods"].update(buckskin_gloves=99999)]
 for mutate in mutations:
  bad=deepcopy(base);mutate(bad)
  try:validate_branch(first,bad)
  except AssertionError:continue
  raise AssertionError("Corrupt fixed-hide evidence accepted")
 output={"protocol":"docs/FIXED_HIDE_PROTOCOL.md","protocol_sha256":sha(ROOT/"docs/FIXED_HIDE_PROTOCOL.md"),"receipt":receipt,"rules":d["rules"],"source_hashes":d["source_hashes"],"negative_checks":len(mutations),"summaries":{},"cases":[]}
 for contract in ["all","free","hired"]:
  output["summaries"][contract]=summarize([r for r in rows if contract=="all" or r["contract"]==contract])
 for contract,stock in itertools.product(["free","hired"],["none","goats"]):output["summaries"][contract+"/"+stock]=summarize([r for r in rows if (r["contract"],r["stock"])==(contract,stock)])
 for r in rows:
  c={k:r[k] for k in ["seed","month","stock","contract","root_outcome","root_days"]};c["checkpoint"]={k:v for k,v in r["checkpoint"].items() if k!="save"}
  c["branches"]=[{k:b[k] for k in ["arm","start_sha256","harvested_after_fork","outcome","days","miles","original_present","cash","food","final_goods","final_contract","death_causes"]}|{"ledger":ledger(b),"craft_events":[e for e in b["events"] if e["event"]=="leathercraft"]} for b in r["branches"]];output["cases"].append(c)
 target=ROOT/"docs/fixed-hide-results-01.json"
 if args.check:assert read(target)==output
 else:
  assert not target.exists(),"Refusing to overwrite published results"
  target.write_bytes((json.dumps(output,indent=2)+"\n").encode("utf-8"))
 print(json.dumps(output["summaries"],indent=2));print("Verified 32 root cases, every eligible same-save pair, zero new hides, recipe stock and contract accounting.")
if __name__=="__main__":main()
