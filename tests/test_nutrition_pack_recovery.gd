extends SceneTree
const Health=preload("res://simulation/party_health.gd")
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func run():
 var health=Health.new()
 health.start(["A"],57)
 health.daily_onset_chance=0
 health.scurvy={}
 health.members[0].health=20
 health.begin_condition(0,"scurvy",0,3)
 health.tick(1,false,1,2,1848,6,"plains",0)
 check(health.members[0].health==20 and health.members[0].conditions[0].elapsed==1,"Vitamin-C meals stop scurvy deterioration before recovery is complete")
 health.tick(2,false,1,2,1848,6,"plains",30)
 check(health.members[0].health==14 and health.members[0].conditions[0].elapsed==1,"Missing the vitamin-C meal resumes damage and pauses recovery")
 for day in range(3,16):health.tick(day,false,1,2,1848,6,"plains",0)
 check(health.members[0].alive and health.members[0].conditions.is_empty(),"Sustained nutritional treatment allows a weak severe case to recover")
 health.start(["A"],57);health.daily_onset_chance=0;health.scurvy={}
 health.begin_condition(0,"dysentery",0,1)
 var before: int=health.members[0].health
 health.tick(1,false,1,2,1848,6,"plains",0)
 check(health.members[0].health==before-6,"Produce does not erase unrelated disease damage")
 var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json"))
 for invalid in [-1,3,0.5,"zero"]:
  var bad: Dictionary=rules.duplicate(true)
  for c in bad.conditions:
   if c.id=="scurvy":c.fed_daily_damage=invalid
  check(not health.load_data(bad),"Malformed nutritional damage rejects")
 var game=Sim.new(57,"classic",true)
 check(game.depart("banker",["A","B","C","D","E"],5,{"wagon":0,"food":60,"clothing":5,"bullet_boxes":1,"medicine":1,"salt":1}),"Walking outfit is legal at actual starting health")
 for member in game.party_health.members:member.health=60
 game.state.health=60
 game.state.food=0
 check(is_equal_approx(game.provisions.capacity(game.state),200),"Moderate illness still leaves pack capacity for meals")
 check(game.hunting_capacity()==200,"Retrieval uses the same health factor with its separate fifty-pound baseline")
 var mass: float=game.provisions.cargo(game.state)
 check(mass==110 and is_equal_approx(game.provisions.capacity(game.state)-mass,90),"Real gear stays counted; relief gives food room without a second health modifier")
 game.party_health.begin_condition(1,"broken_leg",0)
 check(is_equal_approx(game.provisions.capacity(game.state),160),"A broken leg still removes a carrier completely")
 var previous:=0.0
 for h in range(101):
  for member in game.party_health.members:member.conditions=[];member.health=h;member.alive=h>0
  game.state.health=h
  var capacity: float=game.provisions.capacity(game.state)
  check(capacity>=previous and capacity<=200,"Pack capacity decreases continuously toward no capacity as health falls")
  previous=capacity
 var store=Store.new()
 var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-nutrition-pack-save-v1.json"))
 var restored=store.restore(legacy)
 check(restored!=null and restored.state==store.normalize(legacy.state) and str(restored.rng.state)==legacy.random,"A genuine prior save keeps supplies, health, day and random stream")
 if restored!=null:
  for member in restored.party_health.members:member.health=60
  restored.state.health=60
  var clone=store.restore(JSON.parse_string(JSON.stringify(store.capture(restored))))
  check(clone!=null and is_equal_approx(clone.provisions.capacity(clone.state),200),"Adjusted capacity derives from live restored people")
 var horse_sync: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-recovery-horse-sync-save-v1.json"))
 var synced=store.restore(horse_sync)
 check(synced!=null and synced.state==store.normalize(horse_sync.state) and str(synced.rng.state)==horse_sync.random,"The concurrent horse-update save migrates without resetting a journey")
 var pack_rules: Dictionary=game.provisions.data.duplicate(true)
 for invalid in [null,[],[[0,0],[20,0.5],[50,0.9],[80,1],[100,1]],[[0,0],[20,0.8],[50,0.5],[80,1],[100,1]],[[0,0],[20,-1],[50,0.75],[80,1],[100,1]],[[0,0],[20,"soft"],[50,0.75],[80,1],[100,1]]]:
  var bad: Dictionary=pack_rules.duplicate(true)
  bad.walking.health_load_curve=invalid
  check(not game.provisions.load_data(bad),"Malformed carrying curve rejects")
 print("Nutrition and pack recovery: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
