"""Verify identical emergency fixtures and publish compact matched evidence."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
FIELDS = ("mode","health_case","distance","month","seed")
def load(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    if data["errors"]:
        raise ValueError(f"{path}: campaign errors")
    rows = {tuple(row[k] for k in FIELDS): row for row in data["runs"]}
    if len(rows) != len(data["runs"]) or len(rows) != 4*3*3*2*data["seed_count"]:
        raise ValueError(f"{path}: missing or duplicate cases")
    return data, rows
def compare(before_path, after_path):
    before, a = load(before_path)
    after, b = load(after_path)
    if set(a) != set(b):
        raise ValueError("Seed/configuration keys differ")
    pairs = []
    groups = collections.defaultdict(list)
    for key in sorted(a):
        first, second = a[key], b[key]
        original = dict(first["initial_fixture"])
        changed = dict(second["initial_fixture"])
        original.pop("rules")
        changed.pop("rules")
        if original != changed:
            raise ValueError(f"Initial state differs for {key}")
        digest = hashlib.sha256(json.dumps(original,sort_keys=True,separators=(",",":")).encode()).hexdigest()
        pair = dict(zip(FIELDS,key))
        pair["initial_fixture_sha256"] = digest
        for label, row in (("before",first),("after",second)):
            pair[label] = {k:v for k,v in row.items() if k not in FIELDS and k != "initial_fixture"}
        pairs.append(pair)
        groups[key[:4]].append(pair)
    cells = []
    for key, rows in sorted(groups.items()):
        cell = dict(zip(FIELDS[:4],key))
        cell["n"] = len(rows)
        for label in ("before","after"):
            cell[label] = dict(reached_help=sum(r[label]["outcome"]=="reached_help" for r in rows),
                intact=sum(r[label]["outcome"]=="reached_help" and r[label]["original_present"]==5 for r in rows),
                deaths=sum(len(r[label]["death_causes"]) for r in rows),
                outcomes=dict(collections.Counter(r[label]["outcome"] for r in rows)))
        cells.append(cell)
    return dict(protocol=after["protocol"],matched_pairs=len(pairs),errors=[],
        before={k:before[k] for k in ("rules_signature","source_hashes","seed_start","seed_count")},
        after={k:after[k] for k in ("rules_signature","source_hashes","seed_start","seed_count")},
        initial_fixtures="Every initial save matched exactly after removing only the rules fingerprint. Full snapshots remain in ignored raw evidence; per-case hashes are published here.",
        cells=cells,pairs=pairs)
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before",type=Path)
    parser.add_argument("after",type=Path)
    parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    if args.output.exists():parser.error("Choose an unused archive name")
    data=compare(args.before,args.after)
    args.output.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")
    print(data["matched_pairs"],"matched pairs; identical initial fixtures; zero selected errors")
if __name__=="__main__":main()
