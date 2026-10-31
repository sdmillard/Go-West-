extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Nutrition=preload("res://simulation/ruminant_nutrition.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
 var g=Sim.new(425901,"classic",true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,{"oxen":4,"food":100,"clothing":5,"dairy_cows":1,"goats":1,"livestock_fodder":100}),"Energy fixture departs")
 g.pending={};var rules: Dictionary=g.livestock.data.feeding.ruminants
 check(Nutrition.valid(rules),"Species and hay calibration validates")
 var b: Dictionary=Nutrition.budget(rules,"dairy_cows",1,10,1,false,1)
 check(is_equal_approx(b.target_tdn_lb,11.5),"Cow calibration meets the independent OSU 10-lb milk energy anchor")
 check(b.capacity_dm_lb>=21.6 and b.capacity_dm_lb<=23,"Cow intake capacity is inside USDA low-yield DMI reference envelope")
 var larger: Dictionary=rules.duplicate(true);larger.animals.goats.body_lb=110
 b=Nutrition.budget(larger,"goats",1,4.5,1,false,1)
 check(absf(float(b.target_tdn_lb)-2.8)<0.03,"Goat coefficients approximate Langston's different 110-lb / 4.5-lb milk example")
 b=Nutrition.budget(rules,"dairy_cows",1,8,0,false,1)
 var fed: Dictionary=Nutrition.supplied(b,1,0.7)
 check(is_equal_approx(fed.hay_dm_lb,0.9) and is_equal_approx(fed.tdn_lb,0.495),"One physical hay pound supplies 0.9 dry pound and 0.495 TDN pound")
 check(fed.production==0 and fed.maintenance_coverage<1,"A small feed ration does not create milk before maintenance is met")
 var poor: Dictionary=rules.duplicate(true);poor.animals.dairy_cows.natural_tdn=0.45
 b=Nutrition.budget(poor,"dairy_cows",1,8,1,false,1)
 fed=Nutrition.supplied(b,b.fodder_needed_lb,0.7)
 check(b.fodder_needed_lb>0 and is_equal_approx(fed.production,1),"Richer hay can replace poor forage to support milk within rumen capacity")
 check(is_equal_approx(fed.natural_dm_eaten_lb+fed.hay_dm_lb,b.capacity_dm_lb),"Replacement does not add hay on top of a full rumen")
 check(fed.natural_dm_eaten_lb<b.natural_dm_lb,"Replaced forage is removed from energy accounting")
 var rich: Dictionary=rules.duplicate(true);rich.animals.dairy_cows.natural_tdn=0.65
 b=Nutrition.budget(rich,"dairy_cows",1,8,1,false,1)
 check(b.fodder_needed_lb==0,"Abundant rich pasture does not consume unnecessary hay")
 # Across plausible sizes, feed quality and demand, conservation and monotonicity hold.
 for kind in ["dairy_cows","goats"]:
  for size in [0.8,1.0,1.2]:
   for quality in [0.45,0.55,0.65]:
    var variant: Dictionary=rules.duplicate(true)
    variant.animals[kind].body_lb*=size;variant.animals[kind].natural_tdn=quality
    for potential in [0.0,0.5,1.0]:
     for working in [false,true]:
      var previous: float=-1
      for opportunity in [0.0,0.25,0.5,0.75,1.0]:
       b=Nutrition.budget(variant,kind,1,float(g.livestock.data.animals[kind].daily_lb)*potential,opportunity,working,1)
       fed=Nutrition.supplied(b,0,0.7)
       check(float(fed.production)>=previous-0.000000001,"Better forage opportunity cannot reduce milk energy")
       previous=fed.production
       for hay in [0.0,float(b.fodder_needed_lb)*0.5,float(b.fodder_needed_lb)]:
        fed=Nutrition.supplied(b,hay,0.7)
        check(fed.natural_dm_eaten_lb+fed.hay_dm_lb<=float(b.capacity_dm_lb)+0.000000001,"Natural and carried feed share finite intake capacity")
        check(is_equal_approx(fed.tdn_lb,float(fed.natural_dm_eaten_lb)*quality+float(fed.hay_dm_lb)*float(rules.hay_tdn)),"No extra energy appears during fodder replacement")
        check(fed.production>=0 and fed.production<=1 and fed.condition_intake>=0 and fed.condition_intake<=1,"Milk and maintenance coverage are bounded")
 # Same current milk demand used in preview, fodder and actual production; taper once.
 for animal in g.livestock.record.animals:animal.remaining=30;animal.condition=50
 var before: Dictionary=Save.new().capture(g);var offer: Dictionary=g.livestock.outlook(g,true).feeding
 check(Save.new().capture(g)==before,"Energy previews do not consume hay, age lactation, heal or advance RNG")
 check(offer.animals.dairy_cows.budget.milk_target_lb==4 and offer.animals.goats.budget.milk_target_lb==1,"Late lactation reduces both species' milk demand")
 g.livestock.tick(g,true,false)
 check(is_equal_approx(g.livestock.last.milk_lb,5),"Fair, adequately fed late-lactation animals produce their taper exactly once")
 check(g.livestock.record.animals.all(func(a):return a.remaining==29 and a.condition>=50),"Tick ages lactation once and adequate feed preserves Fair condition")
 # Tiny positive surplus must produce either a representable serving or none.
 for delta in [0.0,0.0000000000001,0.00000000001,0.000000001,0.0000001]:
  var tiny=Sim.new(425902,"classic",true)
  check(tiny.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":100,"clothing":5,"dairy_cows":1}),"Boundary fixture departs")
  tiny.pending={};tiny.livestock.data.feeding.ruminants.animals.dairy_cows.natural_tdn=(8.8+delta)/22.0
  tiny.livestock.tick(tiny,true,false)
  check(Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(tiny))))!=null,"Near-maintenance milk keeps JSON mass and energy consistent")
  check(tiny.livestock.record.products.all(func(p):return p.lb>0 and is_equal_approx(float(p.kcal)/float(p.lb),277)),"No zero-mass or distorted tiny milk product")
 var hard=Sim.new(425904,"classic",true)
 check(hard.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":100,"clothing":5,"dairy_cows":1,"livestock_fodder":100}),"Hard-travel feed fixture departs")
 hard.pending={};hard.state.pace=2
 hard.survival.weather=hard.survival.data.weather.filter(func(w):return w.id=="clear")[0].duplicate(true)
 hard.livestock.tick(hard,false,true)
 check(hard.livestock.record.animals[0].condition==100,"Adequate feed covers grueling maintenance without a second automatic work penalty")
 var exact: Dictionary=Save.new().capture(hard)
 var reloaded=Save.new().restore(JSON.parse_string(JSON.stringify(exact)))
 check(reloaded!=null and Save.new().capture(reloaded)==exact,"Recurring energy/feed history survives JSON without binary drift")
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-ruminant-energy.json"))
 for name in fixtures:
  var old: Dictionary=fixtures[name];var store=Save.new();var restored=store.restore(old)
  check(restored!=null,"Prior actual livestock save loads: "+name)
  if restored!=null:
   check(restored.state==store.upgraded_state(old.state) and restored.livestock.record==store.normalize(old.livestock),"Migration preserves stock, feed, portions, condition, choices and cash")
   check(str(restored.rng.state)==old.random and Save.new().restore(JSON.parse_string(JSON.stringify(store.capture(restored))))!=null,"Migrated save preserves RNG and current JSON validity")
 for key in ["hay_dry_matter","hay_tdn","travel_maintenance_bonus"]:
  var bad: Dictionary=rules.duplicate(true);bad[key]=-1
  check(not Nutrition.valid(bad),"Invalid hay/activity values rejected")
 var bad: Dictionary=rules.duplicate(true);bad.animals.goats.reference_body_lb=0
 check(not Nutrition.valid(bad),"Invalid reference size rejected")
 print("Ruminant nutrient budgets: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
