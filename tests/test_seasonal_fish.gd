extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Model=preload("res://simulation/fishing.gd")
const Food=preload("res://simulation/provisions.gd")
const Store=preload("res://simulation/save_store.gd")
class MixedCamp extends "res://simulation/fishing.gd":
 func begin(_seed: int,_outing: int,_offer: Dictionary,_month: int) -> Dictionary:
  return {"casts":[{"bite":true,"mass":0.5,"kcal_per_lb":800.0},{"bite":true,"mass":1.0,"kcal_per_lb":400.0}]}
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party(seed_value: int=293001):
 var g=Sim.new(seed_value,"classic",true)
 g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":300,"clothing":5,"bullet_boxes":1,"salt":5})
 g.pending={};g.state.landmark="elm_grove";g.state.next_landmark="wakarusa";g.state.leg_length=20;g.state.leg_miles=20;g.state.miles=53
 g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
 return g
func run():
 var model=Model.new();var food=Food.new()
 check(food.meat_units(1.0,4490.0,false)==4 and food.meat_units(1.0,4500.0,false)==5,"Ordinary .49 down / .50 up rounding")
 check(food.meat_units(1.0,490.0,false)==0 and food.meat_units(1.0,500.0,false)==1,"Fishing has no hidden minimum-one unit")
 check(food.meat_units(1.0,490.0)==1,"Legacy generic meat keeps its existing minimum")
 var route=preload("res://simulation/route_catalog.gd").new()
 for site in model.data.sites:
  check(route.nodes.has(site) and route.nodes[site].kind=="river","Fish profile maps to a real river stop")
 for month in range(1,13):
  for site in model.data.sites:
   check(not model.pool(site,month).is_empty(),"Resident species remain available across seasons")
   if site in ["wakarusa","kansas_river","big_blue","south_platte","north_platte","green_river","greenwood_cutoff"]:
    check(not model.pool(site,month).any(func(f):return f.id=="chinook"),"No salmon east of the Columbia basin")
 check(not model.pool("snake_river",1).any(func(f):return f.id=="chinook") and model.pool("snake_river",9).any(func(f):return f.id=="chinook"),"Lower Snake salmon follows authored run season")
 check(not model.pool("john_day",10).any(func(f):return f.id=="chinook") and model.pool("john_day",5).any(func(f):return f.id=="chinook"),"John Day uses its spring profile")
 check(model.pool("unknown",6).is_empty() and model.pool("wakarusa",0).is_empty(),"Unknown sites and invalid months have no pool")
 var warm:=0;var cold:=0
 for seed_value in range(100):
  for month in [1,7]:
   var activity: Dictionary=model.begin(seed_value,1,{"casts":6,"site":"wakarusa"},month)
   for cast in activity.casts:
    if cast.bite:
     if month==1:cold+=1
     else:warm+=1
    var species: Dictionary=model.data.species[cast.species]
    check(cast.whole_lb>=species.whole_lb[0] and cast.whole_lb<=species.large_lb[1],"Whole catch stays inside configured size distribution")
    check(is_equal_approx(cast.mass,cast.whole_lb*species.edible_fraction) and cast.mass<=cast.whole_lb,"Edible flesh is extracted once from whole weight")
 check(warm>cold,"Warm-water prairie catch chance is lower in winter")
 for edit in ["unknown_species","short_months","bad_fraction","bad_weight"]:
  var invalid: Dictionary=model.data.duplicate(true)
  if edit=="unknown_species":invalid.profiles.prairie.species["made_up"]={"weight":1,"months":[1,1,1,1,1,1,1,1,1,1,1,1]}
  if edit=="short_months":invalid.profiles.prairie.monthly_bite_factor=[1]
  if edit=="bad_fraction":invalid.species.redband.edible_fraction=1.2
  if edit=="bad_weight":invalid.species.redband.whole_lb=[2,1]
  check(not Model.new().load_data(invalid),"Reject malformed seasonal profile")
 var g=party()
 check(g.start_fishing("foot"),"Fractional mixed-catch fixture launches")
 g.hunt.casts=[{"wait":1.0,"bite":true,"mass":0.875,"whole_lb":1.75,"label":"test fish","species":"fixture","kcal_per_lb":560.0},{"wait":1.0,"bite":true,"mass":0.875,"whole_lb":1.75,"label":"test fish","species":"fixture","kcal_per_lb":560.0}]
 for i in range(2):g.fishing_click();g.advance_fishing(1.0);g.fishing_click()
 check(is_equal_approx(g.hunt.meat,1.75) and "You caught a test fish!" in g.hunt.message,"Catch popup names fish and whole weight without truncating edible catch")
 check(g.hunt_recovery().food==1 and is_equal_approx(g.hunt_recovery().mass,1.75),"Aggregate two sub-half-unit fish before rounding")
 check(g.finish_fishing() and is_equal_approx(g.last_hunt_recovery.retrieved_kcal,980.0) and g.last_hunt_recovery.eaten_food+g.last_hunt_recovery.food==1,"Actual meal settlement rounds the combined calories once")
 for seed_value in range(293010,293030):
  g=party(seed_value);g.configure(1,0)
  check(g.start_fishing("foot"),"Real seasonal outing starts")
  while not g.hunt.ended:
   if g.hunt.phase in ["ready","bite"]:g.fishing_click()
   g.advance_fishing(0.1)
  check(g.finish_fishing(),"Real seasonal catch settles")
  var saved: Dictionary=Store.new().capture(g)
  var loaded=Store.new().restore(JSON.parse_string(JSON.stringify(saved)))
  check(loaded!=null and Store.new().capture(loaded)==saved,"Fractional fish mass survives exact JSON round trip")
 g=party();g.fishing=MixedCamp.new();g.fishing.data.worker_hook_chance=1.0
 var delivered: Dictionary=g.fishing.camp_catch(g,1)
 check(delivered.food==1 and is_equal_approx(delivered.mass,1.5) and is_equal_approx(delivered.retrieved_kcal,800.0),"Companion mixes species calories and rounds once")
 var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-seasonal-fish-v5.json"))
 var old=Store.new().restore(previous)
 check(old!=null,"Authentic pre-seasonal save loads")
 if old!=null:
  check(old.state==Store.new().upgraded_state(previous.state) and old.provisions.fresh==Store.new().normalize(previous.fresh) and old.field_outings.snapshot()==Store.new().normalize(previous.field_outings) and str(old.rng.state)==previous.random,"Old fish quantities, weight, away stock and random stream remain unchanged")
 print("Seasonal fish: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
