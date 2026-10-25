"""Summarize matched camp-work archives without pooling older policy versions."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
from statistics import mean, median

KEY = ("phase", "profession", "month", "equipment", "method", "seed")
POLICIES = {"off", "support", "coordinated"}

def summarize(paths):
    inputs, rows, seen, settings = [], [], set(), None
    sources = rules = None
    for path in paths:
        raw = path.read_bytes()
        data = json.loads(raw)
        if data["errors"]:
            raise ValueError(f"{path}: unresolved errors")
        expected = len(data["professions"])*len(data["months"])*len(data["equipment"])*len(data["methods"])*data["seeds"]
        if len(data["runs"]) != expected:
            raise ValueError(f"{path}: incomplete campaign")
        current = {k:data[k] for k in ("reserve_meals", "player_accuracy", "pace", "outfit_profile", "camp_policy_version")}
        if settings is None:
            settings, sources, rules = current, data["source_hashes"], data["rules_signature"]
        if current != settings or data["source_hashes"] != sources or data["rules_signature"] != rules:
            raise ValueError(f"{path}: incompatible source, rules or policy settings")
        policy = data["camp_work_policy"]
        if policy not in POLICIES:
            raise ValueError(f"{path}: unknown policy")
        phase = "validation" if "validation" in path.name else "development"
        inputs.append(dict(path=path.name, sha256=hashlib.sha256(raw).hexdigest(), phase=phase, policy=policy, runs=expected))
        for row in data["runs"]:
            row = dict(row, phase=phase, policy=policy)
            key = tuple(row[k] for k in KEY)
            if (policy, key) in seen:
                raise ValueError(f"Duplicate row {policy}, {key}")
            seen.add((policy, key))
            rows.append(row)
    baseline = {tuple(r[k] for k in KEY):r for r in rows if r["policy"] == "off"}
    for row in rows:
        key = tuple(row[k] for k in KEY)
        if any((policy, key) not in seen for policy in POLICIES):
            raise ValueError(f"Missing matched policy for {key}")
    groups = defaultdict(list)
    for row in rows:
        groups[tuple(row[k] for k in ("phase", "policy", "profession", "method"))].append(row)
    summaries = []
    for key, group in sorted(groups.items()):
        arrived = [r for r in group if r["outcome"] == "arrived"]
        pairs, differences = Counter(), []
        for row in group:
            other = baseline[tuple(row[k] for k in KEY)]
            a, b = row["outcome"] == "arrived", other["outcome"] == "arrived"
            pairs["both_arrived" if a and b else "policy_only" if a else "off_only" if b else "neither_arrived"] += 1
            if a and b:
                differences.append(row["days"]-other["days"])
        total = lambda section, name: sum(r[section].get(name, 0) for r in group)
        averages = {name:round(mean(r["audit"][name] for r in group), 2) for name in ("underfed_days", "scurvy_person_days", "rest_days")}
        summaries.append(dict(zip(("phase", "policy", "profession", "method"), key)) | dict(
            runs=len(group), arrivals=len(arrived),
            reunited_intact_arrivals=sum(r["original_present"] == 5 for r in arrived),
            intact_arrivals=sum(r["original_survived"] == 5 for r in arrived),
            median_arrival_days=median(r["days"] for r in arrived) if arrived else None,
            mean_original_survivors=round(mean(r["original_survived"] for r in group), 2),
            mean_journey_days=round(mean(r["days"] for r in group), 2),
            underfed_days_per_100=round(100*sum(r["audit"]["underfed_days"] for r in group)/max(1,sum(r["days"] for r in group)),2),
            paired_arrivals=dict(pairs), median_day_difference_when_both_arrive=median(differences) if differences else None,
            outcomes=dict(Counter(r["outcome"] for r in group)), averages=averages,
            camp_work={name:total("camp_work", name) for name in group[0]["camp_work"]},
            forage={name:round(total("camp_forage", name), 2) for name in group[0]["camp_forage"]},
            total_spoilage_food_units=sum(r["spoilage_food_units"] for r in group),
            field={name:total("field", name) for name in ("days_away", "deaths", "mount_losses", "returned_catch_units")},
            counts={name:total("counts", name) for name in ("hunts", "dispatches", "meat_food_units", "field_meal_units")}))
    return dict(inputs=inputs, total_runs=len(rows), settings=settings, rules_signature=rules,
                source_hashes=sources, groups=summaries,
                caveats=["Six reused world seeds per phase, not independent observations per strategy.",
                         "Shared forage harvest includes the leader on explicit forage days.",
                         "Processed, retained and spoiled food are food units, not physical pounds.",
                         "Coordinated policy changes leader actions as well as assignments.",
                         "Arrival time differences compare only matched pairs where both arrive."])

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("archives", nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    result = summarize(args.archives)
    args.output.write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(f"Summarized {result['total_runs']} journeys from {len(result['inputs'])} archives")
