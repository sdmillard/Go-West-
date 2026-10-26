extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Base=preload("res://tests/dairy_balance_observer.gd")
const Driver=preload("res://tests/farmer_mastery_campaign.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func setup(g):
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":200,"clothing":5,"salt":10}),"Mastery quote fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
func run():
 var driver=Driver.new()
 var plain=Base.new(489989,"classic",true);var observed=driver.make_study_game(489989)
 setup(plain);setup(observed)
 for g in [plain,observed]:
  g.state.food+=g.provisions.add_meat(100,0,700)
  g.provisions.fresh.append({"pounds":5,"expires":2,"vitamin_c":true,"mass_ratio":4.0});g.state.food+=5
 for day in range(5):
  plain.pending={};observed.pending={}
  plain.rest_in_camp();observed.rest_in_camp()
  check(Save.new().capture(plain)==Save.new().capture(observed),"Spoilage classification changes no actual food, health, cash or RNG")
 var audit: Dictionary=observed.provisions.preservation_audit
 check(audit.classification_errors==0 and audit.raw_meat_spoiled>0 and audit.produce_spoiled>0,"Expired raw meat and produce classified separately")
 check(audit.raw_meat_spoiled+audit.produce_spoiled+audit.dried_meat_spoiled+audit.other_spoiled==observed.provisions.spoiled_units,"Classified spoilage equals actual total")
 var g=Sim.new(489988,"classic",true);setup(g)
 g.party_health.members[0].health=79
 driver.mastery="rations"
 var p: Dictionary=driver.policy("foot")
 check(not p.adaptive_rations and driver.ration(g)==1,"A merely Fair traveler does not automatically force Filling in ration variant")
 driver.mastery="baseline";check(driver.policy("foot").get("adaptive_rations",true),"Default baseline keeps its earlier ration behavior")
 driver.mastery="skilled";g.state.food=1000
 check(driver.ration(g)==2,"Well-supplied skilled party uses Filling for prevention and recovery")
 g.state.food=20;check(driver.ration(g)==1,"Skilled party economizes when supplies are low")
 var quotes: Dictionary=Save.new().capture(g);driver.plan_jobs(g)
 check(g.state.food==quotes.state.food and g.state.day==quotes.state.day and str(g.rng.state)==quotes.random,"Task assignment grants no food, time or lucky draw")
 g.state.money=100;g.state.food=100;g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 var before: int=g.state.day;var count: Dictionary=driver.count_template()
 check(driver.counter_visit(g,driver.policy("foot"),count),"Skilled traveler buys supplies before entering uplands")
 check(g.state.money>=0 and g.state.food>100 and g.state.day<=before+1,"Resupply respects cash and at most one ordinary visit day")
 driver.free()
 print("Farmer mastery strategy: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
