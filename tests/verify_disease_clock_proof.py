"""Verify the corrected controlled-course evidence against archived actual daily traces."""
from pathlib import Path
import hashlib,itertools,json
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
r=read(ROOT/"docs/disease-clock-proof-02.json");raw=read(ROOT/r["raw_archive"])
assert sha(ROOT/r["raw_archive"])==r["raw_sha256"] and not raw["errors"]
assert r["rules"]==raw["rules"] and r["source_hashes"]==raw["source_hashes"]
for file,digest in r["source_hashes"].items():assert sha(ROOT/file)==digest,file
assert r["courses"]==[{k:v for k,v in c.items() if k!="trace"} for c in raw["courses"]]
assert len(r["courses"])==36 and {(c["condition"],c["severity"],c["policy"]) for c in r["courses"]}==set(itertools.product(["smallpox","pneumonia","measles"],[1,2,3],["travel","rest","nurse","caregiver"]))
for c in raw["courses"]:
 assert [t["day"] for t in c["trace"]]==list(range(1,c["calendar_days"]+1))
 if c["outcome"]=="recovered":assert c["calendar_days"]=={"smallpox":21,"pneumonia":14,"measles":10}[c["condition"]]
 if c["severity"]==1:assert c["outcome"]=="recovered"
assert r["injury_shield"]["wounded_exposed"] and r["injury_shield"]["healthy_exposed"]
assert all(x["risk"]>0 for x in r["open_wound_risk"] if x["day"] in [8,11])
print("Verified36 corrected courses, all daily traces, injury susceptibility, open-wound risk and source/archive hashes.")
