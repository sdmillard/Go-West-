"""Validate and summarize matched moving-camp archives."""
import argparse
from collections import defaultdict, Counter
import hashlib
import json
from pathlib import Path
from statistics import mean, median

POLICIES = ("serial", "parallel", "mobile")

def summarize(paths):
    records, inputs, seen = [], [], set()
    sources = rules = settings = None
    for path in paths:
        raw = path.read_bytes()
        data = json.loads(raw)
        expected = len(data["professions"])*len(data["months"])*len(data["methods"])*len(data["equipment"])*data["seeds"]
        if data["errors"] or len(data["runs"]) != expected:
            raise ValueError(f"{path}: errors or incomplete campaign")
        current = {k:data[k] for k in ("reserve_meals", "player_accuracy", "pace", "outfit_profile", "motion_policy_version")}
        if settings is None:
            settings, sources, rules = current, data["source_hashes"], data["rules_signature"]
        if settings != current or sources != data["source_hashes"] or rules != data["rules_signature"]:
            raise ValueError("Incompatible settings/sources/rules")
        policy = data["motion_policy"]
        if policy not in POLICIES or data["methods"] != ["foot"] or data["equipment"] != ["shared"]:
            raise ValueError("Unexpected strategy or starting equipment")
        phase = "validation" if "validation" in path.name else "development"
        inputs.append(dict(path=path.name, sha256=hashlib.sha256(raw).hexdigest(), phase=phase, policy=policy, runs=expected))
        expected_keys = {(prof, month, seed) for prof in data["professions"] for month in data["months"] for seed in range(data["seed_start"], data["seed_start"]+data["seeds"])}
        actual = set()
        for row in data["runs"]:
            local = (row["profession"], row["month"], row["seed"])
            key = (phase, policy)+local
            if key in seen or local not in expected_keys:
                raise ValueError("Duplicate/unexpected campaign row")
            seen.add(key); actual.add(local)
            records.append(dict(row, phase=phase, policy=policy))
        if actual != expected_keys:
            raise ValueError("Incomplete declared cohort")
    baseline = {(r["phase"],r["profession"],r["month"],r["seed"]):r for r in records if r["policy"]=="serial"}
    groups = defaultdict(list)
    for row in records:
        local = (row["profession"],row["month"],row["seed"])
        if any((row["phase"],policy)+local not in seen for policy in POLICIES):
            raise ValueError("Missing matched strategy")
        base = baseline[(row["phase"],)+local]
        if row["outfit"] != base["outfit"] or row["opening_cost_cents"] != base["opening_cost_cents"]:
            raise ValueError("Starting resources/cost differ between strategies")
        groups[(row["phase"],row["policy"],row["profession"])].append(row)
    results = []
    for key, rows in sorted(groups.items()):
        pairs, days, stops, progress = Counter(), [], [], []
        for row in rows:
            base = baseline[(row["phase"],row["profession"],row["month"],row["seed"])]
            a,b = row["outcome"]=="arrived",base["outcome"]=="arrived"
            pairs["both_arrived" if a and b else "strategy_only" if a else "serial_only" if b else "neither_arrived"] += 1
            if a and b:
                days.append(row["days"]-base["days"])
                stops.append(row["motion"]["stationary_days"]-base["motion"]["stationary_days"])
                progress.append(row["motion"]["distance_progress_days"]-base["motion"]["distance_progress_days"])
        results.append(dict(zip(("phase","policy","profession"),key)) | dict(
            runs=len(rows), arrivals=sum(r["outcome"]=="arrived" for r in rows),
            intact_arrivals=sum(r["outcome"]=="arrived" and r["original_present"]==5 for r in rows),
            outcomes=dict(Counter(r["outcome"] for r in rows)), paired_arrivals=dict(pairs),
            paired_day_changes=days, median_paired_day_change=median(days) if days else None,
            paired_stationary_changes=stops, median_paired_stationary_change=median(stops) if stops else None,
            paired_progress_day_changes=progress,
            mean_original_survivors=round(mean(r["original_survived"] for r in rows),2),
            mean_underfed_days=round(mean(r["audit"]["underfed_days"] for r in rows),2),
            motion_totals={name:sum(r["motion"][name] for r in rows) for name in rows[0]["motion"] if name!="actions"},
            actions=dict(sum((Counter(r["motion"]["actions"]) for r in rows),Counter())),
            camp_work={name:sum(r["camp_work"][name] for r in rows) for name in rows[0]["camp_work"]},
            dispatches=sum(r["counts"].get("proactive_dispatches",0) for r in rows),
            field_deaths=sum(r["field"]["deaths"] for r in rows),
            returned_catch_food=sum(r["field"]["returned_catch_units"] for r in rows)))
    return dict(total_runs=len(records), inputs=inputs, settings=settings, rules_signature=rules, source_hashes=sources, groups=results)

if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("archives",nargs="+",type=Path)
    p.add_argument("--output",required=True,type=Path)
    a=p.parse_args()
    result=summarize(a.archives)
    a.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(f"Summarized {result['total_runs']} journeys")
