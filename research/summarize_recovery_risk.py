"""Publish the recovery/risk audit, retaining the shared provenance checks."""
import argparse, datetime, json, statistics
from pathlib import Path
from summarize_total_balance import build
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[1])
 p.add_argument("--output",type=Path,required=True)
 args=p.parse_args()
 if args.output.exists():p.error("Choose an unused archive")
 protocol=json.loads((args.root/"research/RECOVERY_AND_RISK_PROTOCOL.json").read_text(encoding="utf-8"))
 result=build(args.root,protocol)
 for cohort in result["cohorts"].values():
  if cohort["kind"]!="broad":continue
  for row in cohort["runs"]:
   date=datetime.datetime(1848,row["month"],1)+datetime.timedelta(days=row["days"])
   row["end_date"]=date.strftime("%Y-%m-%d")
  cohort["total"]["arrivals_by_september_1848"]=sum(r["outcome"]=="arrived" and r["end_date"]<"1848-10-01" for r in cohort["runs"])
 result["style_comparisons"]=[]
 for first,second in (("cautious","traveler"),("cautious","bold")):
  a,b=[result["cohorts"][key+"_validation"] for key in (first,second)]
  if a["frozen"]!=b["frozen"]:raise ValueError("Style comparison uses different source/seed identity")
  keys=("profession","month","roster","seed")
  aa={tuple(r[k] for k in keys):r for r in a["runs"]}
  bb={tuple(r[k] for k in keys):r for r in b["runs"]}
  if set(aa)!=set(bb):raise ValueError("Different style scenarios")
  both=[(aa[k],bb[k]) for k in aa if aa[k]["outcome"]==bb[k]["outcome"]=="arrived"]
  result["style_comparisons"].append(dict(first=first,second=second,n=len(aa),both_arrive=len(both),
   first_only_arrives=sum(aa[k]["outcome"]=="arrived" and bb[k]["outcome"]!="arrived" for k in aa),
   second_only_arrives=sum(bb[k]["outcome"]=="arrived" and aa[k]["outcome"]!="arrived" for k in aa),
   second_faster_in_both=sum(y["days"]<x["days"] for x,y in both),
   median_day_delta_among_both=statistics.median(y["days"]-x["days"] for x,y in both)))
 if "cautious_combined" in result["cohorts"]:
  result["combined_replay_equivalence"]={}
  fields=("profession","month","roster","seed")
  for style in ("cautious","traveler","bold"):
   a,b=[result["cohorts"][style+suffix] for suffix in ("_validation","_combined")]
   aa={tuple(r[k] for k in fields):r for r in a["runs"]}
   bb={tuple(r[k] for k in fields):r for r in b["runs"]}
   if set(aa)!=set(bb) or a["settings"]!=b["settings"]:raise ValueError("Different replay configuration")
   result["combined_replay_equivalence"][style]=dict(n=len(aa),identical_scenarios=sum(aa[k]==bb[k] for k in aa),changed_outcomes=sum(aa[k]["outcome"]!=bb[k]["outcome"] for k in aa))
 # Keep each scenario independently readable without expanding every numeric row.
 blocks={}
 for key,c in result["cohorts"].items():
  token="__RUNS_"+key+"__";blocks[token]=c["runs"];c["runs"]=token
 encoded=json.dumps(result,indent=1)
 for token,rows in blocks.items():
  encoded=encoded.replace(json.dumps(token),"["+chr(10)+(","+chr(10)).join(json.dumps(r,separators=(",",":")) for r in rows)+chr(10)+"]")
 check=json.loads(encoded)
 for key,c in check["cohorts"].items():
  if c["runs"]!=blocks["__RUNS_"+key+"__"]:raise ValueError("Serialization changed")
 args.output.write_bytes((encoded+chr(10)).encode("utf-8"))
 print(check["total_runs"],"source-frozen cases; zero selected errors")
if __name__=="__main__":main()
