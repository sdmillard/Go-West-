extends SceneTree
const Health=preload("res://simulation/party_health.gd")
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func patient():
 var h=Health.new();h.start(["A"],77);h.members[0].health=100;h.daily_onset_chance=0;h.scurvy={};h.begin_condition(0,"scurvy",0,1)
 return h
func run():
 var h=patient()
 for day in range(1,5):h.tick(day,false,1,2,1848,5,"plains",60,{},0.25)
 check(h.members[0].conditions[0].elapsed==1,"Four quarter-covered meals earn one full recovery step")
 check(h.members[0].health==94,"Partial treatment reduces four days of scurvy harm from eight to six")
 h=patient();h.members[0].conditions[0].severity=3
 h.tick(1,false,1,2,1848,5,"plains",60,{},0.25)
 check(h.members[0].health==96 and h.members[0].conditions[0].nutrition_damage_milli==500,"Half-point harm remainder is retained")
 h.tick(2,false,1,2,1848,5,"plains",60,{},0.25)
 check(h.members[0].health==91 and h.members[0].conditions[0].nutrition_damage_milli==0,"Repeated fractional harm is not rounded away")
 h=patient();h.tick(1,true,1,2,1848,5,"plains",60,{},0.25)
 check(h.members[0].conditions[0].elapsed==0 and h.members[0].conditions[0].nutrition_progress_milli==500,"Rest doubles proportional recovery")
 h.tick(2,false,1,2,1848,5,"plains",60,{},0.0)
 check(h.members[0].conditions[0].nutrition_progress_milli==500 and h.members[0].conditions[0].elapsed==0,"No-produce day preserves prior progress without advancing it")
 h=patient()
 for day in range(1,15):h.tick(day,false,1,2,1848,5,"plains",0,{},1.0)
 check(h.members[0].conditions.is_empty() and h.members[0].health==100,"Full treatment still clears after fourteen working steps without scurvy damage")
 h=patient();h.begin_condition(0,"dysentery",0,1);h.tick(1,false,1,2,1848,5,"plains",0,{},1.0)
 check(h.members[0].health==94,"Vitamin coverage does not reduce unrelated dysentery damage")
 var g=Sim.new(77,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":200,"clothing":5,"dried_produce":2}),"Partial meal fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear";g.party_health.begin_condition(0,"scurvy",0,1)
 check(g.rest_in_camp(),"Partial actual shared meal settles")
 var c: Dictionary=g.party_health.members[0].conditions[0]
 check(c.treatment_coverage_milli==800 and c.elapsed==1 and c.nutrition_progress_milli==600,"Two dried baskets for five people earn eighty percent treatment")
 check(g.party_health.days_without_fresh>0,"This focused change does not silently change prevention onset rules")
 var detail: String=g.party_health.description(0)
 check(detail.contains("Treatment progress: 1.6 / 14") and detail.contains("80%"),"Health details show fractional progress and actual meal coverage")
 var store=Save.new();var snapshot: Dictionary=store.capture(g);var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(copy!=null and store.capture(copy)==snapshot,"Partial treatment and harm remainders survive exact save/load")
 for key in ["nutrition_progress_milli","nutrition_damage_milli","treatment_coverage_milli"]:
  for invalid in [-1,0.5,1001]:
   var bad: Dictionary=snapshot.duplicate(true);bad.party[0].conditions[0][key]=invalid
   check(store.restore(bad)==null,"Malformed treatment state rejects: "+key)
 var old: Dictionary=snapshot.duplicate(true)
 for key in ["nutrition_progress_milli","nutrition_damage_milli","treatment_coverage_milli"]:old.party[0].conditions[0].erase(key)
 check(store.restore(old)!=null,"Existing saves without optional treatment fields still load")
 check(not Health.valid_treatment({"id":"dysentery","nutrition_progress_milli":100}),"Unrelated illness cannot carry scurvy treatment state")
 print("Partial scurvy treatment: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)

