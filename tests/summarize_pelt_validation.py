"""Verify final pelt tests, rendered preview and meat-only replay compatibility."""
from pathlib import Path
import copy,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding="utf-8-sig"))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 runtime="472de106380ce85c78ae450581293ceded04f538"
 log=(ROOT/".tools/pelts-final-tests-03.log").read_text()
 assert len(re.findall(r"^Godot Engine",log,re.M))==91 and "Pelts and trade skins: 70 checks, 0 failures" in log and not re.search(r"ERROR:|FAIL:",log)
 assert not re.search(r"ERROR:|FAIL:",(ROOT/".tools/pelts-optout-parity-02.log").read_text())
 assert not (ROOT/".tools/pelts-preview-errors.log").read_text().strip()
 p=ROOT/".tools/hunting-pelts-optout-parity-02.json";d=read(p)
 assert not d["errors"] and len(d["runs"])==4 and d["seed_start"]==545000 and d["seeds"]==4 and d["months"]==[5]
 for k,v in {"outfit_profile":"standard","livestock_arm":"none","farmer_mastery":"skilled","player_accuracy":.65,"pace":1,"reserve_meals":2,"motion_policy":"mobile","camp_work_policy":"support","fishing_policy":"support","stock_policy":"aware","feeding_policy":"fodder"}.items():assert d[k]==v,k
 oldname="hunting-bounded-survival-planning65-standard-none-01.json";op=ROOT/".tools"/oldname
 published=read(ROOT/"docs/bounded-survival-summary-01.json")
 assert sha(op)==next(a["sha256"] for a in published["archives"] if a["file"]==oldname)
 old={r["seed"]:r for r in read(op)["runs"] if r["month"]==5}
 result={"runtime":runtime,"test_suites":91,"focused_checks":70,"errors":0,"optout_journeys":4,"cases":[],"diagnostic_inventory_empty_slots_normalized":0,"source_hashes":d["source_hashes"],"rules_signature":d["rules_signature"],"screenshot_sha256":sha(ROOT/"docs/pelt-recovery.png"),"legacy_fixture_sha256":sha(ROOT/"tests/fixtures/pre-pelts-save-v1.json"),"limits":["First slice covers optional recovery on player-led hunts, not automatic companion skinning or personal heirlooms.","Prices, raw/prepared masses, 60lb batch and one preparation day are authored estimates; no full tanning/weather-quality simulation.","Four opt-out replays establish compatibility in those cases, not a survival benefit from harvesting skins.","A diagnostic quote may include three newly defined zero-count inventory slots; all previous outcomes/counters match after removing only those zero slots."]}
 for r in d["runs"]:
  canonical=copy.deepcopy(r)
  inventory=canonical["counts"].get("first_unavailable",{}).get("quote",{}).get("inventory",{})
  for item in ["bison_hide","deer_hide","rabbit_pelt"]:
   if inventory.get(item)==0:
    del inventory[item];result["diagnostic_inventory_empty_slots_normalized"]+=1
  for key,value in old[r["seed"]].items():assert canonical.get(key)==value,(r["seed"],key)
  result["cases"].append({k:r[k] for k in ["seed","outcome","days","original_present","cash","food"]})
 for name,digest in d["source_hashes"].items():
  assert sha(ROOT/name)==digest,name
  assert subprocess.check_output(["git","show",runtime+":"+name],cwd=ROOT).replace(b"\r\n",b"\n")== (ROOT/name).read_bytes().replace(b"\r\n",b"\n"),name
 copy_path=ROOT/".tools/pelts-validation-archives"/p.name;copy_path.parent.mkdir(exist_ok=True)
 if copy_path.exists():assert copy_path.read_bytes()==p.read_bytes()
 else:copy_path.write_bytes(p.read_bytes())
 result["optout_report_sha256"]=sha(p)
 rules=read(ROOT/"data/provisions.json")["pelts"]
 result["goods"]=rules["goods"];result["raw_batch_lb"]=rules["raw_batch_lb"]
 (ROOT/"docs/pelts-validation-01.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
 print("All91 suites/70 focused checks pass. Four opt-out journeys preserve every prior field apart from documented empty diagnostic slots; source/archive hashes and rendered preview verified.")
if __name__=="__main__":main()
