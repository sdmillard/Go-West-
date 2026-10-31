extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func packers():
 var game=Sim.new(57,"classic",true)
 game.depart("banker",["A","B","C","D","E"],5,{"wagon":0,"oxen":0,"mules":3,"pack_saddles":3,"food":70,"clothing":5})
 return game
func run():
 var game=packers()
 var rules: Dictionary=game.provisions.data.mounts
 var plan: Dictionary=game.mount_plan()
 check(plan.mode=="packing","Fixture is a pack train")
 check(game.Mounts.wear(rules,plan,"plains",0,0,0.4)==0,"Light cautious work on good grazing can maintain condition")
 check(game.Mounts.wear(rules,plan,"plains",0,0,1.0)>0,"Full loads still cost condition")
 check(game.Mounts.wear(rules,plan,"plains",0,1,0.4)>0,"Faster pack travel costs condition too")
 check(game.Mounts.wear(rules,plan,"sagebrush",1,0,0.4)>0,"Poor forage still strains lightly loaded animals")
 check(game.Mounts.wear(rules,plan,"plains",2,0,0.4)>0,"Seasonal/weather strain cannot be erased by light loads")
 var double_plan: Dictionary=game.Mounts.plan(rules,{"vehicle":"foot","party_size":5,"horses":3,"saddles":3,"double_up":true})
 check(game.Mounts.wear(rules,double_plan,"plains",0,0,0.1)>=rules.doubled_wear,"Doubling remains strenuous even with little baggage")
 for index in range(12):game._tick_mounts(false,true)
 check(game.Mounts.condition(game.state)==100 and game.state.mules==3,"Sustained light summer work does not force an exhaustion breakdown")
 game.state.horses=5
 game.state.saddles=5
 game.state.saddlebags=5
 game.state.food=0
 game._tick_mounts(false,true)
 check(game.mount_plan().mode=="mounted" and game.state.horse_health==100,"Moderate riding on good grazing can maintain condition with light baggage")
 game.state.horse_health=60
 game._tick_mounts(true,false)
 check(game.state.horse_health==64,"Good-season rest still recovers four condition")
 game.state.day=200 # November, measured from the declared May departure.
 game.state.horse_health=60
 game._tick_mounts(true,false)
 check(game.calendar().month==11 and game.state.horse_health==62,"Winter rest uses seasonal recovery instead of summer grazing")
 game.state.horse_health=60
 game._tick_mounts(false,true)
 check(game.state.horse_health<60,"Working through winter still wears a light pack train")
 var data: Dictionary=game.provisions.data.duplicate(true)
 for invalid in [-0.1,0,1,"light"]:
  var bad: Dictionary=data.duplicate(true)
  bad.mounts.light_work_load=invalid
  check(not game.provisions.load_data(bad),"Malformed load threshold rejects")
 check(game.provisions.load_data(data),"Valid data restores after rejection")
 var store=Store.new()
 var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-total-balance-save-v1.json"))
 var restored=store.restore(legacy)
 check(restored!=null,"A genuine immediately preceding packer save migrates")
 if restored!=null:
  check(restored.state==store.upgraded_state(legacy.state) and str(restored.rng.state)==legacy.random,"Migration preserves actual stock, supplies, time, condition and random stream")
  var clone=store.restore(JSON.parse_string(JSON.stringify(store.capture(restored))))
  restored._tick_mounts(false,true);clone._tick_mounts(false,true)
  check(store.capture(restored)==store.capture(clone),"Loaded animal work follows the same deterministic transition")
 print("Animal work balance: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
