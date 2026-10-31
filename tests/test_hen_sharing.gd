extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
 var g=Sim.new(415902,"classic",true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,{"oxen":4,"food":100,"clothing":5,"hens":6,"poultry_feed":20}),"New journey departs")
 g.pending={};g.survival.forced_weather="clear"
 g.livestock.record.products.append({"kind":"portion","lb":0.626,"kcal":626.0,"expires":10});g.livestock.product_mass(g)
 check(g.livestock.record.share_scraps==false,"New journeys keep edible portions for humans by default")
 var before: Dictionary=Save.new().capture(g)
 var forecast: Dictionary=g.livestock.outlook(g,true).feeding
 check(forecast.scraps_kcal==0 and forecast.grain_lb>0 and forecast.scratch_lb>0,"Off preserves edible food while grain and scratching remain available")
 check(Save.new().capture(g)==before,"Off preview changes no supplies or random streams")
 var energy: float=g.livestock.available_kcal()
 var grain: float=g.livestock.Feeding.available(g,"poultry_feed")
 g.livestock.tick(g,true,false)
 check(g.livestock.available_kcal()==energy and g.livestock.last.feeding.scraps_kcal==0,"Actual off day does not consume human portions")
 check(is_equal_approx(grain-g.livestock.Feeding.available(g,"poultry_feed"),g.livestock.last.feeding.grain_lb),"Actual grain supplement is charged exactly")
 check(g.livestock.set_scraps(g,true),"Player can opt in")
 before=Save.new().capture(g);forecast=g.livestock.outlook(g,true).feeding
 check(forecast.scraps_kcal>0 and Save.new().capture(g)==before,"Opt-in preview estimates real food without consuming it")
 energy=g.livestock.available_kcal();g.livestock.tick(g,true,false)
 check(is_equal_approx(energy+float(g.livestock.last.food)*1000.0-g.livestock.available_kcal(),g.livestock.last.feeding.scraps_kcal),"Opt-in removes exactly the edible calories fed")
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-sharing-default.json"))
 for name in fixtures:
  var old: Dictionary=fixtures[name];var store=Save.new();var restored=store.restore(old)
  check(restored!=null,"Actual old save loads: "+name)
  if restored==null:continue
  check(restored.livestock.record==store.normalize(old.livestock),"Migration preserves stored choice and actual food: "+name)
  check(restored.state==store.upgraded_state(old.state) and str(restored.rng.state)==old.random,"Migration preserves resources and random stream: "+name)
  var expected: bool=name!="sharing_off"
  check(restored.livestock.outlook(restored,true).feeding.scraps_kcal>0 if expected else restored.livestock.outlook(restored,true).feeding.scraps_kcal==0,"Old effective sharing choice survives: "+name)
  var round_trip=Save.new().restore(JSON.parse_string(JSON.stringify(store.capture(restored))))
  check(round_trip!=null and round_trip.livestock.record==restored.livestock.record,"Choice and food survive current JSON save: "+name)
 print("Hen food-sharing choice: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
