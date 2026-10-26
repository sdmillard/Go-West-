extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func game():
 var g=Sim.new(340011,"classic",true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,{"oxen":4,"food":100,"clothing":5,"bullet_boxes":1}),"Meal fixture departs")
 g.pending={};g.survival.forced_weather="clear";g.party_health.daily_onset_chance=0
 return g
func milk(g,kcal: float,expires: int=2) -> void:
 g.livestock.record.products.append({"kind":"milk","lb":kcal/313.0,"kcal":kcal,"expires":expires})
 g.livestock.product_mass(g)
func energy(g) -> float:return int(g.state.food)*1000.0+g.livestock.available_kcal()
func copy(g):return Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
func _initialize():call_deferred("run")
func run():
 for amount in [71.5,626.0,1252.0,2842.0,20000.0]:
  var g=game();milk(g,amount)
  var before:=energy(g)
  var mass: float=g.provisions.cargo(g.state)
  var result: Dictionary=g.livestock.meal(g,15)
  check(is_equal_approx(before-energy(g),15000.0),"Meals conserve energy across tiny/large dairy servings")
  check(is_equal_approx(result.eaten,15.0),"Table food and staples fill exactly one meal")
  check(g.provisions.cargo(g.state)<mass,"Actual eaten mass leaves cargo")
  check(g.livestock.valid(g.livestock.record,g.state),"Partial portions are valid food stocks")
  var restored=copy(g)
  check(restored!=null,"Fractional portions survive JSON saving")
  if restored!=null:check(Save.new().capture(restored)==Save.new().capture(g),"Exact food, weight and expiry survive JSON")
 var g=game();milk(g,626)
 var start:=energy(g)
 g.livestock.meal(g,15)
 check(g.state.food==85 and g.livestock.record.products.size()==1,"One partly eaten staple remains after drinking small milk serving")
 check(is_equal_approx(g.livestock.record.products[0].kcal,626) and is_equal_approx(g.livestock.record.products[0].lb,0.626),"Uneaten staple has its actual calories and physical mass")
 g.livestock.meal(g,15)
 check(is_equal_approx(start-energy(g),30000),"Retained portion feeds the next meal without creating calories")
 g=game();g.state.food=0;milk(g,626)
 g._tick_day(true)
 check(is_equal_approx(g.livestock.last_meal.eaten,0.626),"A sub-unit drink actually feeds a food-short party")
 check(is_equal_approx(g.state.hunger_days,0.958),"Hunger uses fractional calories rather than treating small milk as zero")
 check(copy(g)!=null,"Partial shortfall saves")
 # Force final serving to be perishable meat, preserving both its expiry and its mass ratio.
 g=game();g.state.food=15;g.provisions.fresh.assign([{"pounds":15,"expires":2,"mass_ratio":2.0}]);milk(g,626)
 g.livestock.meal(g,15)
 var portion: Dictionary=g.livestock.record.products[0]
 check(portion.expires==2 and is_equal_approx(portion.lb,1.252),"Uneaten meat keeps original expiry and mass ratio")
 g.state.day=2;g.livestock.tick(g,true,false)
 check(g.livestock.record.products.is_empty(),"Partial meat spoils rather than becoming permanent calorie credit")
 g=game();g.state.food=0;milk(g,626,1)
 g.livestock.record.products.append({"kind":"egg","lb":0.11,"kcal":71.5,"expires":14});g.livestock.product_mass(g)
 g._tick_day(true)
 check(is_equal_approx(g.livestock.last_meal.eaten,0.0715),"Expired milk does not spoil a separately dated edible egg")
 # Preserve vitamin-C priority even when there is enough milk to fill the meal.
 g=game();g.provisions.add_produce(40,0);g.state.food+=10;milk(g,20000)
 var before:=energy(g)
 var result: Dictionary=g.livestock.meal(g,15)
 check(result.vitamin>=5*float(g.provisions.data.foraging.vitamin_c_lb_per_person),"A shared produce serving still precedes milk")
 check(is_equal_approx(before-energy(g),15000),"Produce and milk share the same calorie budget")
 # A split dried-fruit unit keeps its retained vitamin value as well as its dry mass.
 g=game();g.state.food=15
 preload("res://simulation/produce_trade.gd").add(g.provisions,"dried_produce",15,0)
 var dry: Dictionary=g.provisions.fresh[0].duplicate()
 milk(g,626)
 var target: float=5*float(g.provisions.data.foraging.vitamin_c_lb_per_person)
 result=g.livestock.meal(g,15,target)
 portion=g.livestock.record.products[0]
 check(is_equal_approx(portion.lb,0.626*float(dry.mass_ratio)),"Partial dried fruit retains dry physical mass")
 check(is_equal_approx(portion.vitamin_c_lb,0.626*float(dry.vitamin_c_per_unit)),"Partial dried fruit retains its remaining vitamin value")
 check(g.livestock.valid(g.livestock.record,g.state) and copy(g)!=null,"Nutrient-bearing partial portions remain save-valid")
 # Multiple small milks must conserve energy over repeated meals, not merely one rounding boundary.
 g=game();var initial:=energy(g)
 for day in range(12):
  milk(g,626)
  result=g.livestock.meal(g,3)
  check(is_equal_approx(initial+(day+1)*626-energy(g),(day+1)*3000),"Recurring small servings conserve calories over repeated meals")
 # Real work, not standing assignments, controls care availability.
 g=game();g.state.dairy_cows=1;g.state.goats=1;g.livestock.sync(g)
 for id in range(1,5):check(g.camp_tasks.assign(g,id,"forage"),"Assign standing camp chore")
 check(is_equal_approx(g.livestock.outlook(g).care_factor,1),"Idle standing orders do not withhold travel-day care")
 g.camp_tasks.begin(g,"rest")
 check(g.livestock.outlook(g,true).care_factor<1,"Actual camp jobs still compete with animal care")
 g.camp_tasks.day_plan={"action":"rest","leader":0,"rest":{0:true,1:false,2:true,3:true,4:true},"jobs":[{"member":1,"job":"nurse","patient":0}]}
 check(g.livestock.workers(g)==3,"Actual nurse and patient cannot also tend livestock")
 g.camp_tasks.day_plan={"action":"care","leader":0,"leader_patient":2,"rest":{},"jobs":[]}
 check(g.livestock.workers(g)==3,"Leader providing care and patient cannot also tend livestock")
 # Forecasting uses the same portion/expiry service, without changing the real journey.
 g=game();g.state.food=14;milk(g,1000,3)
 var snapshot: Dictionary=Save.new().capture(g)
 check(preload("res://simulation/table_meals.gd").forecast(g)==1,"Forecast counts milk already carried with whole staples")
 check(Save.new().capture(g)==snapshot,"Forecast preserves live supplies, products and random streams")
 g.state.food=0;g.livestock.record.products[0].kcal=15000;g.livestock.record.products[0].lb=15000.0/313;g.livestock.record.products[0].expires=1;g.livestock.product_mass(g)
 check(preload("res://simulation/table_meals.gd").forecast(g)==0,"Forecast does not promise food that expires before tomorrow's meal")
 # Authentic pre-change saves retain already-rounded food; no retroactive yield correction.
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-exact-table-meals.json"))
 for key in fixtures:
  var old: Dictionary=fixtures[key];var restored=Save.new().restore(old)
  check(restored!=null,"Genuine prior-rule save migrates")
  if restored==null:continue
  check(restored.state.food==old.state.food and restored.state.money==old.state.money,"Migration neither grants nor removes existing whole supplies/cash")
  check(Save.new().normalize(restored.provisions.fresh)==Save.new().normalize(old.fresh) and Save.new().normalize(restored.livestock.record)==Save.new().normalize(old.livestock),"Existing rounded batches and raw eggs preserved")
  check(str(restored.rng.state)==old.random and str(restored.party_health.rng.state)==old.health_random,"Migration preserves random streams")
  check(copy(restored)!=null,"Migrated save saves and loads under current rules")
 g=game();milk(g,626);g.state.vehicle="foot";g.state.food=1000
 var old_kcal: float=g.livestock.available_kcal()
 g.livestock.pack(g)
 check(g.livestock.available_kcal()==0 and old_kcal>0,"Uneaten table food is discarded when no pack room remains")
 check(g.livestock.valid(g.livestock.record,g.state),"Packing leaves valid mass accounting")
 g=game();milk(g,626)
 var invalid: Dictionary=Save.new().capture(g);invalid.livestock.products[0].kcal=-1
 check(Save.new().restore(invalid)==null,"Invalid saved table calories rejected")
 print("Exact table meals: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
