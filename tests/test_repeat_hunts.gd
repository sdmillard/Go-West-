extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
class FixedField extends "res://simulation/field_outings.gd":
 func hunting_plan(_game,_trip: Dictionary) -> Dictionary:
  return {"animals":[{"meat":50}],"search_factor":1.0,"shot_limit":5}
class AuditedField extends "res://tests/hunt_balance_outings.gd":
 func hunting_plan(_game,_trip: Dictionary) -> Dictionary:
  return {"animals":[{"meat":5},{"meat":3}],"search_factor":1.0,"shot_limit":5}
class Draws extends RefCounted:
 var values: Array=[]
 func randf() -> float:return float(values.pop_front()) if not values.is_empty() else 0.99
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party(fixed: bool=true,ammo: int=15):
 var g=Sim.new(7611,"classic",true)
 g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":1,"saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10})
 g.pending={};g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 if fixed:g.field_outings=FixedField.new()
 for p in g.characters.profiles:
  if int(p.id)>0:p.trust=80;p.boundaries.forbidden=[]
 check(g.field_outings.start(g,1,"ride_horse",3,ammo),"Actual companion and supplies reserved")
 return g
func run():
 var g=party();var trip: Dictionary=g.field_outings.record.trips[0]
 var random=Draws.new();random.values=[0.99,0.99,0.01]
 check(g.field_outings._hunt(g,trip,random),"A hunting day settles")
 check(trip.camp.inventory.bullets==13 and trip.camp.inventory.food>12,"A missed first shot can be followed by a successful second shot")
 check(g.field_outings.Outfit.mass(g,[trip.camp.guards[0]],trip.kit,trip.camp.inventory,trip.camp.fresh,trip.stock,"ride")<=g.field_outings.Outfit.capacity(g,[trip.camp.guards[0]],trip.kit,trip.stock,"ride"),"Catch and packed supplies fit real riding capacity")
 g=party();trip=g.field_outings.record.trips[0];g.field_outings.rules.hit_chance=0;g.field_outings.rules.hunter_bonus=0;g.field_outings.rules.miss_escape_chance=0
 random=Draws.new()
 for day in range(1,4):
  g.state.day=day
  var ammo: int=trip.camp.inventory.bullets
  g.field_outings._hunt(g,trip,random)
  check(trip.camp.inventory.bullets==ammo-5,"Each hunting day gets its own bounded shots")
 check(trip.camp.inventory.bullets==0 and not g.field_outings._hunt(g,trip,random),"Empty ammunition cannot create another shot")
 g=party(true,2);trip=g.field_outings.record.trips[0];g.field_outings.rules.hit_chance=0;g.field_outings.rules.hunter_bonus=0;g.field_outings.rules.miss_escape_chance=0
 g.field_outings._hunt(g,trip,random)
 check(trip.camp.inventory.bullets==0,"Short ammunition caps retries without going negative")
 g=party();trip=g.field_outings.record.trips[0];g.field_outings.rules.hit_chance=0;g.field_outings.rules.hunter_bonus=0;g.field_outings.rules.miss_escape_chance=1
 g.field_outings._hunt(g,trip,random)
 check(trip.camp.inventory.bullets==14,"An escaped animal cannot be shot at again")
 g=party();trip=g.field_outings.record.trips[0];g.field_outings.rules.hit_chance=1;g.field_outings.rules.hunter_bonus=0;random.values=[0]
 g.field_outings._hunt(g,trip,random)
 check(trip.camp.inventory.bullets==14,"A killed animal is removed rather than harvested repeatedly")
 g=party(false);trip=g.field_outings.record.trips[0]
 for key in g.hunting.data.regions:g.hunting.data.regions[key].empty_chance=1.0
 var before: int=trip.camp.inventory.bullets
 check(g.field_outings._hunt(g,trip,random) and trip.camp.inventory.bullets==before,"An empty search takes work but no bullets")
 for seed_value in range(100):
  g.state.seed=seed_value
  var saved: Dictionary=Save.new().capture(g)
  var plan: Dictionary=g.field_outings.hunting_plan(g,trip)
  check(plan.animals.is_empty() and Save.new().capture(g)==saved,"Encounter preview changes no saved state or RNG")
 g=party();g.field_outings=AuditedField.new()
 check(g.field_outings.start(g,2,"foot",1,5),"Actual second hunter uses the field audit")
 trip=g.field_outings.record.trips[0]
 g.field_outings.rules.hit_chance=10;random.values=[0,0]
 g.field_outings._hunt(g,trip,random)
 check(g.field_outings.audit.shots==2 and g.field_outings.audit.meat_food==5 and is_equal_approx(g.field_outings.audit.meat_lb,8.0),"Mixed meat batches keep exact physical mass rather than the last animal's conversion ratio")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-repeat-hunt-v5.json"))
 var restored=Save.new().restore(old)
 check(restored!=null,"Genuine previous-rule active trip loads")
 if restored!=null:
  check(Save.new().capture(restored).field_outings==Save.new().normalize(old.field_outings) and str(restored.rng.state)==old.random,"Migration preserves trips, ammunition and random streams")
 print("Companion repeat shots: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
