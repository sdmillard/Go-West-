extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Stock=preload("res://simulation/livestock.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func game(cart: Dictionary={"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200}):
 var g=Sim.new(301002,"classic",true)
 var outfit: Dictionary={"oxen":6,"food":500,"clothing":5,"bullet_boxes":2}
 outfit.merge(cart,true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,outfit),"Livestock outfit departs")
 g.pending={};g.survival.forced_weather="clear";g.party_health.daily_onset_chance=0
 return g
func copy(g):return Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
func _initialize():call_deferred("run")
func run():
 var g=game()
 check(g.livestock.record.animals.size()==8,"Individual milk animals and hens initialized")
 check(is_equal_approx(Stock.cargo(g.state),30),"Six hens and coop have real cargo mass")
 var before: int=g.state.food
 check(g.rest_in_camp(),"Rest day produces livestock food")
 check(g.livestock.last.milk_lb>9 and g.livestock.last.food>=2,"Plausible dairy output converted to food")
 check(g.state.food==before+int(g.livestock.last.food)-15,"Production shares actual meals, not an extra day")
 check(g.state.poultry_feed==194,"Hens eat quarter-pound feed per day")
 check(g.livestock.record.animals[0].remaining==179,"Lactation clock advances")
 check(g.livestock.last.eggs==0,"Partial eggs accumulate without daily rounding gifts")
 var restored=copy(g)
 check(restored!=null,"Production and teams round-trip through JSON")
 if restored!=null:
  check(Save.new().capture(restored)==Save.new().capture(g),"Exact individual condition and product stocks preserved")
 var calories: float=g.provisions.food_calories(1)
 check(calories==1000,"Food unit remains 1000 calories")
 g=game({"hens":1,"poultry_feed":100})
 var egg_units:=0
 for day in range(15):
  g.pending={};g._tick_day(true);egg_units+=int(g.livestock.last.get("food",0))
  check(g.livestock.valid(g.livestock.record,g.state),"Fractional eggs and products remain save-valid")
 check(egg_units==1,"Single hen's small eggs aggregate before food rounding")
 g=game({"hens":6})
 g._tick_day(true)
 check(g.livestock.last.food==0 and g.livestock.last.feed_quarters==0,"No grain means no free egg production")
 check(g.livestock.record.animals[0].condition<100,"Feed shortage harms actual hen condition")
 g=game({"dairy_cows":1})
 g.livestock.record.animals[0].remaining=0
 g._tick_day(true)
 check(g.livestock.last.food==0,"Dry cow gives no milk")
 g=game({"dairy_cows":1})
 g.livestock.set_care(g,false);g._tick_day(true)
 check(g.livestock.last.food==0,"Care can be stopped and suppresses milk")
 g=game({"dairy_cows":1})
 var summer: Dictionary=g.livestock.outlook(g)
 g.state.departure_month=12
 check(g.livestock.outlook(g).season<summer.season,"Winter reduces pasture and production")
 g=game({"dairy_cows":1})
 for member in g.party_health.members:member.health=40
 g._tick_day(true)
 check(g.livestock.last.food==0 and g.livestock.last.care_factor==0,"Incapacitated party has no free household labor")
 g=game({"dairy_cows":1})
 g.provisions.fresh.append({"pounds":3,"expires":5,"mass_ratio":3.0,"table_product":true});g.state.food+=3
 check(g.provisions.processable()==0,"Milk cannot be converted into dried meat")
 var old_mass: float=g.provisions.cargo(g.state)
 g.state.poultry_feed=4
 check(is_equal_approx(g.provisions.cargo(g.state)-old_mass,1.0),"Four grain units weigh one pound")
 g=game({"dairy_cows":1,"goats":1})
 var bullets: int=g.state.bullets
 check(g.livestock.butcher(g,"goats"),"A goat can be butchered")
 check(g.state.goats==0 and g.state.bullets==bullets-1 and g.state.day==1,"Butchery removes animal, bullet and day exactly once")
 check(not g.livestock.butcher(g,"goats"),"Cannot butcher a missing animal")
 check(copy(g)!=null,"Slaughter and remaining livestock save correctly")
 g=game({"hens":1})
 check(g.livestock.butcher_offer(g,"hens",true).injury_chance==0,"Normal chicken butchery does not inherit cattle hand risk")
 for key in ["milk_days","moving_care_hours"]:
  var bad: Dictionary=g.livestock.data.duplicate(true);bad[key]=-1
  check(not Stock.new().load_data(bad),"Invalid livestock rules rejected")
 var invalid: Dictionary=Save.new().capture(game())
 invalid.livestock.animals[0].condition=101
 check(Save.new().restore(invalid)==null,"Invalid individual condition rejected")
 invalid=Save.new().capture(game());invalid.livestock.animals[0].id=invalid.livestock.animals[1].id
 check(Save.new().restore(invalid)==null,"Duplicate animal IDs rejected")
 # Actual counter purchase must append healthy stock, preserving the old team.
 g=game({})
 g.team_conditions.record.oxen=[40,40,40,40,40,40];g.team_conditions.summarize(g)
 g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 var counter: Dictionary=g.post_store()
 check(not counter.is_empty(),"Reached actual open post counter")
 check(g.post_checkout({"oxen":2}),"Buy two spare oxen through the real store")
 check(g.team_conditions.record.oxen.size()==8 and g.team_conditions.record.oxen[6]>=95,"New shop oxen are healthy")
 check(g.team_conditions.record.oxen[0]<60,"Purchase does not heal old animals")
 g.pending={}
 check(g.team_conditions.select(g,[2,3,4,5,6,7]),"Swap two fresh reserves into working team")
 check(g.team_conditions.pulling(g.state)==6,"Six animals actually pull")
 check(not g.team_conditions.select(g,[0,1,2,3,4,5,6]),"No seven-ox selection")
 check(not g.team_conditions.select(g,[0,0]),"No duplicate animal selection")
 var reserve: int=g.team_conditions.record.oxen[0]
 var active: int=g.team_conditions.record.oxen[2]
 g._tick_day(false,true)
 check(g.team_conditions.record.oxen[0]>=reserve,"Spare ox avoids working wear")
 check(g.team_conditions.record.oxen[2]<=active,"Selected ox takes actual working wear")
 check(g.team_conditions.select(g,[6,7]),"Reduced emergency team can be chosen")
 check(g.provisions.capacity(g.state)==1250,"Two selected oxen reduce pulling capacity")
 check(copy(g)!=null,"Mixed conditions and chosen team survive JSON save")
 var saved: Dictionary=Save.new().capture(g);saved.team_conditions.oxen[0]=101
 check(Save.new().restore(saved)==null,"Corrupt team record rejected")
 check(g.team_conditions.select(g,[]),"All oxen may rest")
 check(g.travel() and g.pending.get("id","")=="no_team","Empty selected team cannot move the wagon")
 g.pending={};reserve=g.team_conditions.record.oxen[0];g._tick_day(true)
 check(g.team_conditions.record.oxen[0]>reserve,"An unhitched tired ox recovers")
 # Prior-source fixture upgrades all old animals at their existing condition.
 var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-livestock-v5.json"))
 var migrated=Save.new().restore(prior)
 check(migrated!=null,"Genuine previous-source save loads")
 if migrated!=null:
  check(migrated.state.food==prior.state.food and migrated.state.money==prior.state.money and migrated.livestock.record.animals.is_empty(),"Migration gives no free food, cash or livestock")
  check(str(migrated.rng.state)==prior.random,"Migration preserves random stream")
 # Full packs do not prevent drinking milk at camp before hauling the remainder.
 g=game({"dairy_cows":1});g.state.vehicle="foot";g.state.food=125
 g.state["household_gear_lb"]=75;g.state.clothing=0;g.state.bullets=0
 var food_before: int=g.state.food
 g._tick_day(true)
 check(g.state.food==food_before+int(g.livestock.last.food)-15 and g.livestock.last.food>0,"Milk feeds today's meals even before there is pack space")
 g=game({"horses":1,"saddles":1})
 g.team_conditions.record.horses=[40];g.team_conditions.summarize(g)
 g._apply({"horses":1})
 check(g.team_conditions.record.horses==[40,100] and g.state.horse_health==70,"New horse has its own condition and does not heal the old horse")
 var outfit: Dictionary=g.field_outings.Outfit.quote(g,[0],"ride_horse_light",1,5)
 check(outfit.valid,"Healthy spare horse can be allocated to an outing")
 g.field_outings.Outfit.reserve(g,outfit)
 check(outfit.condition==100 and g.team_conditions.record.horses==[40],"Outing reserves the selected horse's actual condition")
 g.field_outings.Outfit.restore_stock(g,outfit.stock,90,outfit.animal_conditions,outfit.condition_base)
 check(g.team_conditions.record.horses==[40,90],"Returned horse retains wear without changing the resting horse")
 for kind in ["dairy_cows","goats","hens"]:
  g=game({kind:1})
  var snap: Dictionary=Save.new().capture(g)
  var rand_before: String=str(g.rng.state)
  for i in range(10):g.livestock.outlook(g);g.livestock.rows(g,"review");g.team_conditions.snapshot(g)
  check(Save.new().capture(g)==snap and str(g.rng.state)==rand_before,"Livestock previews do not mutate state or randomness")
 g=game({"dairy_cows":1,"goats":1,"hens":6})
 var ferry: Dictionary={"method":"ferry","mishap":true}
 g.livestock.cross(g,ferry)
 check(g.livestock.record.animals.size()==8,"Crewing a paid ferry does not add stock losses")
 var lost:=0
 for seed_value in range(40):
  g=game({"dairy_cows":1,"goats":1,"hens":6});g.state.seed=seed_value
  var crossing: Dictionary={"method":"ford","mishap":true}
  g.livestock.cross(g,crossing)
  lost+=crossing.livestock_lost.size()
  check(g.livestock.valid(g.livestock.record,g.state),"Real crossing losses keep individual records synchronized")
 check(lost>0,"Crossing mishaps can lose livestock")
 # Real window, its care switch and per-animal working selection.
 var panel=preload("res://ui/livestock_view.gd").new();root.add_child(panel);await process_frame
 g=game();panel.open(g)
 check(panel.visible and panel.rows.get_child_count()>10,"Livestock ledger opens with real controls")
 var selected_before: int=g.team_conditions.record.working.size()
 for child in panel.rows.get_children():
  if child is CheckBox and child.text.begins_with("OX 1 "):
   child.button_pressed=false;break
 check(g.team_conditions.record.working.size()==selected_before-1,"Actual ledger checkbox unhitches an ox")
 panel.queue_free();await process_frame
 print("Livestock / individual teams: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)

