extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func make_game(cart: Dictionary={}):
 var g=Sim.new(445901,"classic",true)
 var supplies: Dictionary={"oxen":4,"food":100,"clothing":5,"dairy_cows":1,"goats":1}
 supplies.merge(cart,true)
 check(g.depart("banker",["A","B","C","D","E"],5,supplies),"Shared pasture fixture departs")
 g.pending={};g.survival.forced_weather="clear";g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0
 return g
func set_month(g,month: int):
 var year:=1849 if month<5 else 1848
 g.state.day=int((Time.get_unix_time_from_datetime_string("%d-%02d-01T00:00:00" % [year,month])-Time.get_unix_time_from_datetime_string("1848-05-01T00:00:00"))/86400)
func run():
 var g=make_game()
 for month in range(1,13):
  set_month(g,month)
  for region in ["woodland","plains","highcountry","sagebrush","forest"]:
   for id in g.route.nodes:
    if g.route.nodes[id].get("hunting_region","")==region and not g.route.nodes[id].next.is_empty():
     g.state.landmark=id;g.state.next_landmark=g.route.nodes[id].next[0].to;g.state.leg_miles=1;break
   var edge: Dictionary=g.current_edge();var original: Variant=edge.get("hazard")
   for waterless in [false,true]:
    if waterless:edge["hazard"]="waterless"
    else:edge.erase("hazard")
    var before: Dictionary=Store.new().capture(g)
    var p: Dictionary=g.pasture_assessment();var o: Dictionary=g.livestock.outlook(g,true)
    check(Store.new().capture(g)==before,"Shared pasture and feeding previews preserve state and RNG")
    var season: Dictionary=g.seasonal_pressure()
    var old_base: int=int(g.context.region(g).strain)+int(season.working_strain)+int(g.survival.weather.get("ox_strain",0))+(3 if waterless else 0)
    var old_dry: int=1 if region in ["plains","sagebrush"] and month in [7,8,9] else 0
    check(p.base_work_strain==old_base and p.ox_work_strain==old_base+old_dry,"Shared assessment preserves established ox/mount work pressures")
    check(p.ox_rest_recovery==(0 if waterless else int(season.rest_ox_recovery)),"Shared assessment preserves ox recovery and waterless denial")
    for kind in ["dairy_cows","goats"]:
     var expected: float=0 if waterless else minf(float(g.livestock.data.months[month-1]),float(g.livestock.data.feeding.habitats[region][kind]))
     var n: Dictionary=o.feeding.animals[kind]
     check(is_equal_approx(float(n.budget.natural_dm_lb)/float(n.budget.capacity_dm_lb),expected),"Dairy animals use the same season/location/water assessment")
    check((p.grass==0 and p.browse==0) if waterless else p.grass>0,"Waterless applies to both grass and browse")
   if original==null:edge.erase("hazard")
   else:edge.hazard=original
 # A selected meadow benefits dairy animals on the actual paid day; it is not a permanent flag.
 g=make_game({"wagon":0,"oxen":0,"mules":3,"pack_saddles":3,"food":70})
 g.state.next_landmark="grande_ronde";g._arrive_landmark()
 var ordinary: Dictionary=g.livestock.outlook(g,true)
 var index: int=-1
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].get("action","")=="activity":index=i
 check(index>=0,"Dairy/pack travelers can use named grazing without oxen")
 if index>=0:
  check(not g.pending.choices[index].effects.has("ox_health"),"No phantom ox condition bonus is created for an oxless party")
  var day: int=g.state.day;var remaining: int=g.livestock.record.animals[0].remaining
  check(g.choose(index) and g.state.day==day+1,"Grazing takes its existing day and daily meals")
  var improved: Dictionary=g.livestock.last.feeding.animals.dairy_cows
  check(improved.budget.natural_dm_lb>ordinary.feeding.animals.dairy_cows.budget.natural_dm_lb,"Actual meadow day improves available grass for the cow")
  check(g.livestock.record.animals[0].remaining==remaining-1,"Grazing performs one real livestock tick")
  check(not g.grazing_activity and not g.pasture_assessment().better_camp,"Better-camp availability ends with the activity")
  check(not g.can_choose(index),"The same named activity cannot be farmed repeatedly")
  var saved: Dictionary=Store.new().capture(g);var copy=Store.new().restore(JSON.parse_string(JSON.stringify(saved)))
  check(copy!=null and not copy.grazing_activity and Store.new().capture(copy)==saved,"Grazing result and used activity reload without persistent bonus")
 # Better pasture never erases the cold-season availability cap.
 set_month(g,1);g.grazing_activity=true
 var winter: Dictionary=g.pasture_assessment()
 check(winter.grass==g.livestock.data.months[0] and winter.grass<1,"Winter scarcity still limits a better grazing camp")
 g.grazing_activity=false
 for kind in ["oxen","horses","mules","dairy_cows","goats"]:g.state[kind]=0
 g.state.hens=6
 check(not g.context.activity_choices(g).any(func(c):return c.get("action","")=="activity"),"A hen-only party does not receive a grazing-animal action")
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-shared-pasture.json"))
 for name in fixtures:
  var old: Dictionary=fixtures[name];var restored=Store.new().restore(old)
  check(restored!=null,"Prior livestock/team save loads: "+name)
  if restored!=null:
   check(restored.state==Store.new().upgraded_state(old.state) and restored.livestock.record==Store.new().normalize(old.livestock),"Migration changes no livestock, resources or choices")
   check(str(restored.rng.state)==old.random and not restored.grazing_activity,"Migration keeps RNG and grants no active grazing bonus")
 print("Shared pasture: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
