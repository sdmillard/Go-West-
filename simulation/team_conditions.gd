extends RefCounted
## Stable array slots are the animals' ledger numbers. Purchases append healthy animals.
const KINDS=["oxen","horses","mules"]
var record: Dictionary={"oxen":[],"horses":[],"mules":[],"working":[],"custom":false}
static func pulling(s: Dictionary) -> int:return mini(int(s.get("oxen",0)),int(s.get("working_oxen",mini(6,int(s.get("oxen",0))))))
func mean(values: Array) -> int:
 return 100 if values.is_empty() else roundi(float(values.reduce(func(n,a):return n+int(a),0))/values.size())
func ox_average() -> int:return mean(record.working.map(func(i):return record.oxen[int(i)]))
func horse_average() -> int:return mean(record.horses+record.mules)
func start_legacy(game) -> void:
 for kind in KINDS:
  record[kind]=[]
  for i in range(int(game.state.get(kind,0))):record[kind].append(int(game.state.get("ox_health" if kind=="oxen" else "horse_health",100)))
 record.working=range(mini(6,record.oxen.size()));record.custom=false
 summarize(game)
func sync(game) -> void:
 for kind in KINDS:
  var n: int=int(game.state.get(kind,0))
  while record[kind].size()>n:record[kind].pop_back()
  while record[kind].size()<n:record[kind].append(100)
 record.working=record.working.filter(func(i):return int(i)<record.oxen.size())
 if not record.custom:record.working=range(mini(6,record.oxen.size()))
 summarize(game)
func summarize(game) -> void:
 if not record.oxen.is_empty():game.state.ox_health=ox_average()
 if record.custom:game.state["working_oxen"]=record.working.size()
 else:game.state.erase("working_oxen")
 if not (record.horses.is_empty() and record.mules.is_empty()) and (game.state.has("horse_health") or horse_average()!=100):game.state["horse_health"]=horse_average()
func settle(game,single_ox: bool=false,working_day: bool=false,recovery: int=-1) -> void:
 var ox_delta: int=int(game.state.ox_health)-ox_average()
 if recovery>=0:ox_delta=recovery
 var horse_delta: int=int(game.state.get("horse_health",100))-horse_average()
 if single_ox and ox_delta<0 and not record.working.is_empty():
  var i: int=record.working[0];record.oxen[i]=maxi(0,int(record.oxen[i])+ox_delta)
 else:
  for i in range(record.oxen.size()):
   if not working_day or i in record.working:record.oxen[i]=clampi(int(record.oxen[i])+ox_delta,0,100)
   elif int(game.pasture_assessment().ox_rest_recovery)>0:record.oxen[i]=mini(100,int(record.oxen[i])+1)
 for kind in ["horses","mules"]:
  for i in range(record[kind].size()):record[kind][i]=clampi(int(record[kind][i])+horse_delta,0,100)
 sync(game)
func select(game,selection: Array) -> bool:
 if not game.can_service() or selection.size()>6:return false
 var seen: Array=[]
 for i in selection:
  if not (i is int or i is float) or not is_finite(i) or i!=floor(i) or i<0 or i>=record.oxen.size() or i in seen:return false
  seen.append(int(i))
 record.working=seen;record.custom=true;summarize(game);return true
func valid(v: Variant,s: Dictionary) -> bool:
 if not v is Dictionary or v.size()!=5 or not v.get("custom") is bool or not v.get("working") is Array or v.working.size()>6:return false
 for kind in KINDS:
  if not v.get(kind) is Array or v[kind].size()!=int(s.get(kind,0)) or v[kind].size()>1000:return false
  for condition in v[kind]:
   if not (condition is int or condition is float) or not is_finite(condition) or condition!=floor(condition) or condition<0 or condition>100:return false
 var seen: Array=[]
 for i in v.working:
  if not (i is int or i is float) or not is_finite(i) or i!=floor(i) or i<0 or i>=v.oxen.size() or int(i) in seen:return false
  seen.append(int(i))
 if not v.custom and seen!=range(mini(6,v.oxen.size())):return false
 var old: Dictionary=record;record=v
 var ok: bool=(record.oxen.is_empty() or ox_average()==int(s.ox_health)) and (record.horses.is_empty() and record.mules.is_empty() or horse_average()==int(s.get("horse_health",100)))
 if s.has("working_oxen") and (not (s.working_oxen is int or s.working_oxen is float) or s.working_oxen!=v.working.size()):ok=false
 if v.custom and not s.has("working_oxen"):ok=false
 record=old;return ok
func snapshot(game) -> Dictionary:
 if valid(record,game.state):return record.duplicate(true)
 # Scripted legacy fixtures can explicitly replace aggregate condition/counts. Capture a consistent uniform upgrade without mutating their state.
 var fresh: Dictionary={"oxen":[],"horses":[],"mules":[],"working":range(mini(6,int(game.state.oxen))),"custom":false}
 for kind in KINDS:
  for i in range(int(game.state.get(kind,0))):fresh[kind].append(int(game.state.get("ox_health" if kind=="oxen" else "horse_health",100)))
 return fresh
