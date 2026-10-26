extends SceneTree
const Plain=preload("res://tests/dairy_balance_observer.gd")
const Trace=preload("res://tests/scurvy_trace_observer.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
 var plain=Plain.new(535000,"classic",true);var traced=Trace.new(535000,"classic",true)
 for g in [plain,traced]:
  check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":200,"clothing":5,"dried_produce":8}),"Trace fixture departs")
  g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear"
  g.party_health.begin_condition(0,"scurvy",0,3)
 for day in range(9):
  plain.pending={};traced.pending={};plain.rest_in_camp();traced.rest_in_camp()
  check(Save.new().capture(plain)==Save.new().capture(traced),"Daily nutrition trace preserves saved state and RNG")
 check(traced.nutrition_trace.size()==9,"One record per actual day")
 check(traced.nutrition_trace[0].meal.vitamin>=traced.nutrition_trace[0].vitamin_target,"Actual dried produce meal is recorded")
 check(traced.nutrition_trace[0].before[0].scurvy[0].elapsed==0 and traced.nutrition_trace[0].after[0].scurvy[0].elapsed==2,"Resting treated patient gets actual recovery progress")
 print("Scurvy trace: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
