extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
 var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/hen-egg-boundary-v1.json"))
 check(original.livestock.animals.any(func(a):return a.egg_progress==1),"Real failing journey fixture contains the rounded egg boundary")
 var store=Save.new();var g=store.restore(original)
 check(g!=null,"Actual day-76 save loads after narrowly scoped cycle repair")
 if g==null:quit(1);return
 check(g.state==store.normalize(original.state) and g.provisions.fresh==store.normalize(original.fresh),"Repair does not alter supplies, cash, time, or existing fresh batches")
 check(g.livestock.record.products==store.normalize(original.livestock.products),"Loading does not grant an egg or any other table food")
 check(str(g.rng.state)==original.random and str(g.party_health.rng.state)==original.health_random and str(g.survival.rng.state)==original.survival_random,"Repair preserves every saved random stream")
 check(g.livestock.record.animals.all(func(a):return a.egg_progress<1),"Repaired cycle remains below the laying threshold")
 check(Save.new().restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null,"Repaired game re-saves and loads under current rules")
 g.survival.forced_weather="clear";g.party_health.daily_onset_chance=0
 for day in range(120):
  g.pending={};g._tick_day(true)
  var capture: Dictionary=Save.new().capture(g)
  check(Save.new().restore(JSON.parse_string(JSON.stringify(capture)))!=null,"Repeated laying boundaries stay valid through actual daily meals and JSON saves")
  check(g.livestock.record.animals.all(func(a):return a.egg_progress>=0 and a.egg_progress<1),"Every retained cycle remains bounded")
  if g.state.status!="traveling":break
 # Isolate laying over a whole calendar, including long-lived fed winter hens.
 var cycle=Sim.new(355902,"classic",true)
 check(cycle.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":20,"clothing":5,"hens":3,"poultry_feed":2000}),"Year-long laying fixture departs")
 cycle.pending={};cycle.survival.weather=cycle.survival.data.weather.filter(func(w):return w.id=="clear")[0].duplicate(true)
 for day in range(365):
  cycle.state.day+=1;cycle.livestock.tick(cycle,true,false)
  var animals: Array=JSON.parse_string(JSON.stringify(cycle.livestock.record.animals))
  check(animals.all(func(a):return a.egg_progress>=0 and a.egg_progress<1),"Serialized laying progress remains below one across the complete calendar")
  if day%7==0:check(Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(cycle))))!=null,"Weekly full saves survive the year-long controlled laying cycle")
 for value in [-0.01,1.0000001,2.0]:
  var bad: Dictionary=original.duplicate(true);bad.livestock.animals[0].egg_progress=value
  check(Save.new().restore(bad)==null,"Repair rejects genuinely out-of-range legacy egg progress")
 var current: Dictionary=Save.new().capture(g)
 if not current.livestock.animals.is_empty():
  current.livestock.animals[0].egg_progress=1
  check(Save.new().restore(current)==null,"Current rules do not accept forged completed cycles")
 print("Egg progress save boundary: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
