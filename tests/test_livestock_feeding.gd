extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Feed=preload("res://simulation/livestock_feeding.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func game(stock: Dictionary={}):
 var g=Sim.new(350011,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500,"clothing":5,"bullet_boxes":1}
 cart.merge(stock,true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,cart),"Feeding fixture departs")
 g.pending={};g.survival.forced_weather="clear";g.survival.weather=g.survival.data.weather.filter(func(w):return w.id=="clear")[0].duplicate(true);g.party_health.daily_onset_chance=0
 return g
func copy(g):return Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
func tick(g,resting: bool=true,working: bool=false):
 g.state.day+=1;g.livestock.tick(g,resting,working)
func run():
 var g=game({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200,"livestock_fodder":50})
 check(g.livestock.data.size()>0 and Feed.valid(g.livestock.data),"Authored feeding rules validate")
 var before: Dictionary=Save.new().capture(g)
 for i in range(10):g.livestock.outlook(g,true);g.livestock.outlook(g)
 check(Save.new().capture(g)==before,"Repeated feeding previews preserve all food, feed, condition and random streams")
 for health in range(50,101):check(Feed.capacity(g.livestock.data,health)==1,"All fair/good conditions retain full body capacity")
 var last:=0.0
 for health in range(0,101):
  var factor: float=Feed.capacity(g.livestock.data,health)
  check(factor>=last and factor>=0 and factor<=1,"Body capacity is bounded and monotonic")
  if health>0:check(factor-last<=0.021,"Adjacent condition points cannot cause a capacity cliff")
  last=factor
 for h in [19,20,21,49,50,51,79,80,81]:
  check(Feed.condition(g.livestock.data,h,1.0,false,"clear",true,false,1)>=h,"Adequately fed resting animals can recover across condition boundaries")
 # Tiny maintenance gaps accumulate fractional wear instead of rounding to one point/day.
 var condition:=100;var carry:=0.0
 for day in range(50):
  var settled: Dictionary=Feed.settle(g.livestock.data,condition,carry,0.69,false,"clear",true,false,1)
  condition=int(settled.condition);carry=float(settled.strain_carry)
 check(condition>=95 and condition<100,"Fifty tiny deficits cost a few condition points, not fifty")
 var recovered: Dictionary=Feed.settle(g.livestock.data,condition,carry,1.0,false,"clear",true,false,1)
 check(recovered.condition>condition and recovered.strain_carry==0,"Adequate surplus feed can repay fractional strain")
 var good=game({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200})
 var fair=game({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200})
 for animal in fair.livestock.record.animals:animal.condition=50
 for day in range(3):
  tick(good,false,true);tick(fair,false,true)
  check(good.livestock.last.milk_lb==fair.livestock.last.milk_lb and good.livestock.last.eggs==fair.livestock.last.eggs,"Actual fed fair animals produce as much as good animals on the same travel day")
 # Plain grain covers maintenance calories without asserting a complete laying diet.
 g=game({"hens":6,"poultry_feed":500});g.state.day=245
 for day in range(55):
  tick(g)
  check(g.state.hens==6 and g.livestock.record.animals.all(func(a):return a.condition==100),"Fed winter hens do not lose condition just because of the month")
 check(g.livestock.last.feeding.animals.hens.quality<1,"Limited winter scratching leaves grain-only diet quality below full laying potential")
 # Feed, not calendar, drives ruminant deficits; carried fodder fills winter shortfalls.
 g=game({"dairy_cows":1,"goats":1,"livestock_fodder":1500});g.state.day=245
 var fodder: float=Feed.available(g,"livestock_fodder")
 var consumed:=0.0
 for day in range(50):
  tick(g);consumed+=float(g.livestock.last.feeding.fodder_lb)
  check(g.state.dairy_cows==1 and g.state.goats==1 and g.livestock.record.animals.all(func(a):return a.condition==100),"Fed resting milk animals survive fifty winter days without automatic decline")
  check(g.livestock.valid(g.livestock.record,g.state),"Daily fractional fodder and products remain valid")
 check(is_equal_approx(fodder-Feed.available(g,"livestock_fodder"),consumed),"Fodder consumption conserves full and partial physical pounds")
 check(copy(g)!=null,"Long winter feed state survives a real JSON save")
 g=game({"dairy_cows":1,"goats":1});g.state.day=245;tick(g)
 check(g.livestock.record.animals.all(func(a):return a.condition<100),"Winter animals without enough grazing or fodder still lose condition")
 check(g.livestock.last.food==0,"Maintenance shortfalls suppress milk surplus")
 check(copy(g)!=null and g.livestock.record.animals.any(func(a):return a.has("strain_carry")),"Fractional condition strain survives a genuine JSON round-trip")
 g=game({"hens":1});tick(g)
 check(g.livestock.last.feeding.animals.hens.intake==1 and g.livestock.record.animals[0].condition==100,"One hen can meet a spring camp ration by scratching without grain")
 g=game({"hens":24});var large: Dictionary=g.livestock.outlook(g,true).feeding
 check(large.scratch_lb<=g.livestock.data.feeding.scratch_lb and large.animals.hens.intake<0.7,"A larger flock shares finite scratching rather than creating food per hen")
 # Explicit opt-in shares real edible portions; no synthetic waste is generated by meals.
 g=game({"hens":6,"poultry_feed":200});g.livestock.set_scraps(g,true)
 g.livestock.record.products.append({"kind":"portion","kcal":626.0,"lb":0.626,"expires":100,"vitamin_c_lb":0.0});g.livestock.product_mass(g)
 var energy: float=g.livestock.available_kcal()
 var grain: float=Feed.available(g,"poultry_feed")
 tick(g)
 check(g.livestock.last.feeding.scraps_kcal>0 and g.livestock.last.feeding.scraps_lb<=0.25,"Shared portions are bounded by actual leftovers and party size")
 check(is_equal_approx(energy-g.livestock.available_kcal(),g.livestock.last.feeding.scraps_kcal),"The calories fed to hens leave human food exactly once")
 check(is_equal_approx(grain-Feed.available(g,"poultry_feed"),g.livestock.last.feeding.grain_lb),"Partial grain scoops retain unused feed, without rounding gifts or waste")
 check(float(g.state.get("poultry_feed_remainder_lb",0))>0 and copy(g)!=null,"Partial grain mass survives JSON saving")
 g=game({"hens":6});g.livestock.set_scraps(g,true);g.state.food=0
 g.livestock.record.products.append({"kind":"portion","kcal":626.0,"lb":0.626,"expires":100});g.livestock.product_mass(g)
 tick(g)
 check(g.livestock.last.feeding.scraps_kcal==0 and g.livestock.available_kcal()==626,"Sharing cannot consume the party's current ration during a shortage")
 g=game({"hens":6,"poultry_feed":200});g.livestock.set_scraps(g,false)
 g.livestock.record.products.append({"kind":"portion","kcal":626.0,"lb":0.626,"expires":100});g.livestock.product_mass(g);tick(g)
 check(g.livestock.last.feeding.scraps_kcal==0,"Players can turn sharing off")
 g=game({"hens":6,"poultry_feed":200});g.livestock.set_scraps(g,true)
 g.livestock.record.products.append({"kind":"portion","kcal":626.0,"lb":0.8764,"expires":100,"vitamin_c_lb":1.2});g.livestock.product_mass(g);tick(g)
 check(g.livestock.last.feeding.scraps_kcal==0,"Vitamin-bearing fruit/greens portions remain reserved for humans")
 # Habitats distinguish usable cow pasture and goat browse without multiplying stress labels.
 g=game({"dairy_cows":1,"goats":1})
 g.state.landmark="fort_boise";g.state.next_landmark="fort_boise"
 var o: Dictionary=g.livestock.outlook(g,true)
 check(o.feeding.animals.goats.natural>o.feeding.animals.dairy_cows.natural,"Snake country offers a different browse/grazing balance")
 o.season=0.85
 var limited: Dictionary=Feed.plan(g,o,true,false)
 check(is_equal_approx(limited.animals.goats.budget.natural_dm_lb/limited.animals.goats.budget.capacity_dm_lb,0.85),"Season and habitat cap the same forage opportunity without multiplying it down twice")
 check(Feed.condition(g.livestock.data,80,0.0,true,"heat",false,true,2)==74,"One severe deprivation is not added repeatedly as food, water, weather and work damage")
 # Actual fitting/store/drop pathways support fodder without imaginary capacity.
 g=game({"livestock_fodder":25})
 var mass: float=g.provisions.cargo(g.state);g.state.livestock_fodder=0
 check(is_equal_approx(mass-g.provisions.cargo(g.state),25),"A purchased 25 lb of fodder adds 25 actual cargo pounds")
 g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 check(g.post_checkout({"livestock_fodder":25}),"Open post counter sells actual fodder")
 check(copy(g)!=null,"Fodder purchases and finite market stock survive saving")
 g.pending={};var day: int=g.state.day
 check(g.livestock.drop_feed(g,"livestock_fodder",10) and g.state.livestock_fodder==15 and g.state.day==day,"Discard fodder by actual pounds without advancing time")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-mixed-feeding.json"))
 var restored=Save.new().restore(old)
 check(restored!=null,"Authentic prior feeding save loads")
 if restored!=null:
  check(restored.state==Save.new().normalize(old.state) and restored.livestock.record==Save.new().normalize(old.livestock),"Migration grants no fodder or grain and preserves actual animals/portions")
  check(str(restored.rng.state)==old.random and copy(restored)!=null,"Migration preserves RNG and re-saves with current rules")
 for bad_key in ["scratch_lb","maintenance_fraction"]:
  var bad: Dictionary=g.livestock.data.duplicate(true);bad.feeding[bad_key]=-1
  check(not Feed.valid(bad),"Invalid feeding quantities rejected")
 var bad_save: Dictionary=Save.new().capture(g);bad_save.state.poultry_feed_remainder_lb=0.25
 check(Save.new().restore(bad_save)==null,"A fake extra full scoop disguised as a remainder is rejected")
 print("Mixed livestock feeding: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
func _initialize():call_deferred("run")
