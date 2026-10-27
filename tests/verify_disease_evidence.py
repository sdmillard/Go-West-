"""Recheck published diagnostic evidence without asserting its flaws are desired rules."""
from pathlib import Path
import hashlib,itertools,json
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
report=read(ROOT/"docs/disease-evidence-audit-01.json")
raw_path=ROOT/report["raw_archive"];raw=read(raw_path)
assert sha(raw_path)==report["raw_sha256"]
assert not raw["errors"] and raw["rules"]==report["rules"]
assert raw["source_hashes"]==report["source_hashes"]
for file,digest in report["source_hashes"].items():assert sha(ROOT/file)==digest,file
assert report["courses"]==[{k:v for k,v in row.items() if k!="trace"} for row in raw["courses"]]
assert len(raw["courses"])==36 and {(r["condition"],r["severity"],r["policy"]) for r in raw["courses"]}==set(itertools.product(["smallpox","pneumonia","measles"],[1,2,3],["travel","rest","nurse","caregiver"]))
for r in raw["courses"]:
 assert [t["day"] for t in r["trace"]]==list(range(1,r["calendar_days"]+1))
 assert r["outcome"] in ["dead","recovered"] and 0<=r["terminal_health"]<=100
for field in ["injury_shield","open_wound_risk"]:assert report[field]==raw[field]
print("Verified36 diagnostic cases, all daily traces, published findings, source hashes and raw archive.")
