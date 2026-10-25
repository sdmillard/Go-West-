"""Summarize frozen hunting archives, retaining cohort definitions and input digests."""
import argparse
from collections import defaultdict, Counter
import hashlib
import json
from pathlib import Path
from statistics import mean, median

def summarize(paths):
    inputs, records, seen = [], [], set()
    for path in paths:
        raw = path.read_bytes()
        data = json.loads(raw)
        if data["errors"]:
            raise ValueError(f"{path}: campaign errors must be resolved, not hidden")
        expected = len(data["professions"])*len(data["months"])*len(data["equipment"])*len(data["methods"])*data["seeds"]
        if len(data["runs"]) != expected:
            raise ValueError(f"{path}: incomplete matrix")
        inputs.append({"path":path.name,"sha256":hashlib.sha256(raw).hexdigest(),"rules":data["rules_signature"],"sources":data["source_hashes"],"runs":len(data["runs"])})
        phase = "validation" if "validation" in path.name else "development"
        for row in data["runs"]:
            item = dict(row,phase=phase,reserve_meals=data["reserve_meals"],accuracy=data["player_accuracy"])
            key = tuple(item[k] for k in ("phase","reserve_meals","accuracy","profession","month","equipment","method","seed"))
            if key in seen:
                raise ValueError(f"Duplicate cohort row {key}")
            seen.add(key)
            records.append(item)
    if len({i["rules"] for i in inputs}) != 1 or any(i["sources"] != inputs[0]["sources"] for i in inputs):
        raise ValueError("Source/rule fingerprints differ across final archives")
    groups = defaultdict(list)
    for row in records:
        groups[tuple(row[k] for k in ("phase","reserve_meals","accuracy","profession","equipment","method"))].append(row)
    result = []
    baselines = {tuple(r[k] for k in ("phase","reserve_meals","accuracy","profession","month","equipment","seed")):r for r in records if r["method"]=="legacy"}
    for key, rows in sorted(groups.items()):
        identity = dict(zip(("phase","reserve_meals","accuracy","profession","equipment","method"),key))
        arrived = [r for r in rows if r["outcome"]=="arrived"]
        pairs = Counter()
        day_changes = []
        for row in rows:
            baseline = baselines[tuple(row[k] for k in ("phase","reserve_meals","accuracy","profession","month","equipment","seed"))]
            a,b = row["outcome"]=="arrived",baseline["outcome"]=="arrived"
            pairs["both_arrived" if a and b else "method_only" if a else "baseline_only" if b else "neither_arrived"] += 1
            if a and b:day_changes.append(row["days"]-baseline["days"])
        count = lambda name: sum(r["counts"].get(name,0) for r in rows)
        hunts = count("hunts")
        delivered = count("meat_food_units")+count("field_meal_units")+sum(r["field"]["returned_catch_units"] for r in rows)
        result.append(dict(identity,runs=len(rows),arrivals=len(arrived),
            intact_arrivals=sum(r["original_survived"]==5 for r in arrived),
            reunited_intact=sum(r["original_present"]==5 for r in arrived),
            arrival_days_median=median(r["days"] for r in arrived) if arrived else None,
            day_difference_when_both_arrive=median(day_changes) if day_changes else None,
            paired_arrivals=dict(pairs),outcomes=dict(Counter(r["outcome"] for r in rows)),
            mean_original_survivors=round(mean(r["original_survived"] for r in rows),3),
            mean_hungry_days=round(mean(r["audit"]["underfed_days"] for r in rows),3),
            hungry_days_per_100=round(100*sum(r["audit"]["underfed_days"] for r in rows)/max(1,sum(r["days"] for r in rows)),3),
            mean_hunts=round(hunts/len(rows),3),empty_hunt_fraction=round(count("empty_hunts")/hunts,3) if hunts else None,
            main_delivered_hunt_food=delivered,mean_main_spoilage=round(mean(r["spoilage_food_units"] for r in rows),3),
            field_dispatches=count("dispatches"),field_days=sum(r["field"]["days_away"] for r in rows),
            field_mount_losses=sum(r["field"]["mount_losses"] for r in rows),field_deaths=sum(r["field"]["deaths"] for r in rows),
            field_food_returned=sum(r["field"]["returned_catch_units"] for r in rows),
            method_counts={m:count("method_"+m) for m in ("foot","ride","heavy","lead","wagon")},
            hunt_unavailable=count("hunt_unavailable"),mounted_fallbacks=count("mounted_foot_fallback"),
            wagon_fallbacks=count("wagon_foot_fallback"),outrider_fallbacks=count("outrider_foot_fallback")))
    return {"inputs":inputs,"total_runs":len(records),"groups":result}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs",nargs="+",type=Path)
    parser.add_argument("--output",required=True,type=Path)
    args=parser.parse_args()
    if args.output.exists():raise ValueError("Choose an unused output path")
    report=summarize(args.inputs)
    args.output.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(f"{report['total_runs']} complete journeys; {len(report['groups'])} cohort summaries")
    for row in report["groups"]:
        if row["phase"]=="validation" and row["reserve_meals"]==2 and row["accuracy"]==0.65 and row["equipment"]=="practical":
            print(row["profession"],row["method"],f"{row['arrivals']}/{row['runs']}",row["intact_arrivals"],row["arrival_days_median"],row["mean_hungry_days"])
if __name__=="__main__":main()
