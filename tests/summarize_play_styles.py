"""Summarize tests/play_style_baseline.gd output: one table per play style and profession.

Usage: python tests/summarize_play_styles.py .tools/play-style-*.json [--markdown]
"""
import collections
import json
import statistics
import sys


def load(paths):
    rows, errors = [], []
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
        rows += data["runs"]
        errors += data["errors"]
    return rows, errors


def median(values):
    return statistics.median(values) if values else 0


def summarize(rows, key):
    groups = collections.OrderedDict()
    for row in rows:
        groups.setdefault(key(row), []).append(row)
    table = []
    for name, group in groups.items():
        arrived = [r for r in group if r["outcome"] == "arrived"]
        lost = [r for r in group if r["outcome"] == "lost"]
        leader_deaths = [r for r in lost if not r["leader_alive"]]
        custody = [r for r in lost if "custody" in r["loss_reason"] or "prison" in r["loss_reason"].lower() or "hang" in r["loss_reason"].lower()]
        deaths = sum(len(r["deaths"]) for r in group)
        fights = [f for r in group for f in r["fights"]]
        crossings = [c for r in group for c in r["crossings"]]
        table.append({
            "group": name,
            "n": len(group),
            "arrived": len(arrived),
            "arrival_day_median": median([r["days"] for r in arrived]),
            "arrival_months": dict(collections.Counter(r["arrival_month"] for r in arrived)),
            "survivors_on_arrival": round(statistics.mean([r["survivors"] for r in arrived]), 2) if arrived else 0,
            "lost_leader_died": len(leader_deaths),
            "lost_custody": len(custody),
            "lost_other": len(lost) - len(leader_deaths) - len(custody),
            "year_limit": sum(r["outcome"] == "year_limit" for r in group),
            "deaths_per_journey": round(deaths / len(group), 2),
            "leader_death_causes": dict(collections.Counter(r["deaths"][0]["cause"] for r in leader_deaths if r["deaths"] and r["deaths"][0]["id"] == 0)),
            "all_death_causes": dict(collections.Counter(d["cause"] for r in group for d in r["deaths"]).most_common(6)),
            "median_miles_if_lost": median([r["miles"] for r in lost]),
            "start_cash": round(median([r["start_cash"] for r in group]), 2),
            "end_cash_median_arrived": round(median([r["end_cash"] for r in arrived]), 2),
            "min_cash_median": round(median([r["min_cash"] for r in group]), 2),
            "empty_food_days_median": median([r["counts"]["empty_food_days"] for r in group]),
            "underfed_days_median": median([r["audit"].get("underfed_days", 0) for r in group]),
            "scurvy_person_days_median": median([r["audit"].get("scurvy_person_days", 0) for r in group]),
            "hunts_median": median([r["counts"]["hunts"] for r in group]),
            "rest_days_median": median([r["audit"].get("rest_days", 0) for r in group]),
            "travel_days_median": median([r["counts"]["travel_days"] for r in group]),
            "fights": len(fights),
            "fight_outcomes": dict(collections.Counter(f["outcome"] for f in fights)),
            "bandit_events": sum(r["events"].get("bandits", 0) for r in group),
            "crossings": len(crossings),
            "crossing_mishaps": sum(bool(c["mishap"]) for c in crossings),
            "crossing_methods": dict(collections.Counter(c["method"] for c in crossings)),
            "crimes": dict(collections.Counter(c.split(":")[0] + ":" + c.split(":")[2] for r in group for c in r["crimes"]).most_common(8)),
            "sentences": dict(collections.Counter(s for r in group for s in r["sentences"])),
        })
    return table


def markdown(table, columns):
    lines = ["| " + " | ".join(c for c, _ in columns) + " |", "|" + "---|" * len(columns)]
    for row in table:
        lines.append("| " + " | ".join(str(fn(row)) for _, fn in columns) + " |")
    return "\n".join(lines)


def main():
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    rows, errors = load(paths)
    by_style = summarize(rows, lambda r: r["style"])
    by_both = summarize(rows, lambda r: r["style"] + " / " + r["profession"])
    if "--markdown" in sys.argv:
        cols = [
            ("Style", lambda r: r["group"]),
            ("Arrived", lambda r: f'{r["arrived"]}/{r["n"]}'),
            ("Median days", lambda r: r["arrival_day_median"]),
            ("Survivors at arrival", lambda r: r["survivors_on_arrival"]),
            ("Leader died", lambda r: r["lost_leader_died"]),
            ("Custody", lambda r: r["lost_custody"]),
            ("Other loss", lambda r: r["lost_other"]),
            ("Out of time", lambda r: r["year_limit"]),
            ("Deaths/journey", lambda r: r["deaths_per_journey"]),
            ("Starving days", lambda r: r["empty_food_days_median"]),
            ("Cash at arrival", lambda r: r["end_cash_median_arrived"]),
        ]
        print(markdown(by_style, cols))
        print()
        print(markdown(by_both, cols))
    else:
        print(json.dumps({"by_style": by_style, "by_style_profession": by_both, "errors": errors}, indent=1))


if __name__ == "__main__":
    main()
