"""Summarize source-frozen reports without pooling different protocols or invalid runs."""
import argparse
import collections
import json
import statistics
from pathlib import Path

def summarize(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    if data["errors"]:
        raise ValueError(f"{path}: campaign has errors: {data['errors']}")
    runs = data["runs"]
    expected = len(data["professions"]) * len(data["modes"]) * len(data["months"]) * len(data["strategies"]) * data["seed_count"]
    keys = [(r["profession"], r["mode"], r["month"], r["strategy"], r["seed"]) for r in runs]
    if len(runs) != expected or len(set(keys)) != expected:
        raise ValueError(f"{path}: incomplete or duplicate cohort")
    if not data.get("source_hashes") or not data.get("rules_signature"):
        raise ValueError(f"{path}: no frozen-source identity")
    cells = collections.defaultdict(list)
    for row in runs:
        cells[(row["mode"], row["profession"], row["month"], row["strategy"])].append(row)
    results = []
    for (mode, profession, month, strategy), rows in sorted(cells.items()):
        arrivals = [r for r in rows if r["outcome"] == "arrived"]
        results.append(dict(mode=mode, profession=profession, month=month, strategy=strategy,
            n=len(rows), arrivals=len(arrivals),
            intact=sum(r["outcome"] == "arrived" and r["original_present"] == 5 for r in rows),
            median_arrival_days=statistics.median(r["days"] for r in arrivals) if arrivals else None,
            median_progress=statistics.median(r["miles"] for r in rows),
            mean_moving_miles=round(statistics.mean(r["miles_per_moving_day"] for r in rows), 2),
            underfed_days=sum(r["audit"]["underfed_days"] for r in rows),
            scurvy_cases=sum(r["scurvy_cases"] for r in rows),
            animal_breakdowns=sum(r["breakdowns"] for r in rows),
            hunts=sum(r["counts"]["hunts"] for r in rows),
            rests=sum(r["counts"]["rests"] for r in rows),
            outcomes=dict(collections.Counter(r["outcome"] for r in rows))))
    return dict(report=str(path.name), rules_signature=data["rules_signature"], source_hashes=data["source_hashes"],
        configuration={k: data[k] for k in ("seed_start","seed_count","accuracy","stress","months","modes","strategies","professions")},
        journeys=len(runs), errors=0, cells=results)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Choose an unused output archive")
    reports = [summarize(path) for path in args.reports]
    # Each report retains its own protocol, source identity and cell counts.
    args.output.write_text(json.dumps(dict(reports=reports), indent=2) + "\n", encoding="utf-8")
    for report in reports:
        print(report["report"], report["journeys"], "journeys; zero selected errors")
if __name__ == "__main__":
    main()
