extends SceneTree
const Driver=preload("res://tests/income_followup_campaign.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func setup(driver):
 var g=driver.make_study_game(566920)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":250,"clothing":5,"bullet_boxes":5}),"Follow-up fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear";g.use_income=true
 return g
func run():
 var driver=Driver.new();driver.income_arm="combined";driver.mastery="skilled"
 var g=setup(driver);g.configure(1,1);g.state.money=0
 check(g.start_hunt({"members":[0,1,2,3,4],"kit":"wagon","bullets":5}),"Follow-up uses an actual leader hunt")
 g.hunt.animals=[{"kind":1,"escaped":false,"x":180.0,"y":116.0,"direction":1,"meat":53,"kcal_per_lb":550},{"kind":1,"escaped":false,"x":210.0,"y":116.0,"direction":1,"meat":53,"kcal_per_lb":550}];g.hunt.targets=[];g.hunt.meat=0
 check(g.hunt_shot(0),"First controlled deer taken")
 g.advance_hunt(float(g.hunting.data.reload_seconds)+0.01)
 check(g.hunt_shot(1),"Second controlled deer taken")
 g.state.food=0;g.hunt.field.inventory.food=0;g.provisions.fresh.clear()
 check(not g.skin_selection().is_empty(),"Known recoverable meat can cover preparation despite empty pre-hunt stock")
 check(g.finish_hunt() and g.state.deer_hide>0 and g.last_hunt_recovery.preparation_food_units>0,"Real harvest feeds the additional preparation day")
 check(Save.new().restore(Save.new().capture(g))!=null,"Follow-up recovery is a real valid game state")
 g=setup(driver);g.state.day=200;g.state.money=0
 for item in g.income.all_keys():g.state[item]=0
 g._arrive_landmark(true,false)
 check(int(g.calendar().month)>=10,"Employment fixture is past September")
 var count: Dictionary=driver.count_template()
 check(driver.counter_visit(g,driver.policy("foot"),count),"Test strategy considers offered work after September")
 check(g.income_days.size()==1 and g.state.money>0,"Late employment really pays and spends a day")
 driver.free()
 print("Income follow-up: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
