extends SceneTree
const Observer=preload("res://tests/income_balance_observer.gd")
const Base=preload("res://tests/dairy_balance_observer.gd")
const Driver=preload("res://tests/income_balance_campaign.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func setup(g):
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":250,"clothing":5,"bullet_boxes":5}),"Income comparison fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear"
func run():
 var off=Observer.new(566910,"classic",true);var on=Observer.new(566910,"classic",true);on.use_income=true
 setup(off);setup(on)
 check(Save.new().capture(off)==Save.new().capture(on),"Both arms start with identical resources, personal belongings and random streams")
 for day in range(4):
  off._tick_day(true,false,"rest");on._tick_day(true,false,"rest")
  check(Save.new().capture(off)==Save.new().capture(on),"Passive income measurements change no state or RNG")
 var driver=Driver.new();driver.mastery="skilled";driver.income_arm="combined"
 var g=driver.make_study_game(566911);setup(g)
 g.state.money=0;g._arrive_landmark(true,false)
 var count: Dictionary=driver.count_template();var p: Dictionary=driver.policy("foot")
 check(driver.counter_visit(g,p,count),"Combined strategy sells real held personal goods")
 check(g.income_sales.size()==1 and g.income_sales[0].goods.size()==5 and g.state.keepsake_0==0,"Sale observation counts actual unique goods")
 check(g.income_sales[0].days==g.income_sales[0].ticks.size(),"Sale-day meal trace reconciles with actual elapsed days")
 g=driver.make_study_game(566912);setup(g);g.state.money=0
 for item in g.income.all_keys():g.state[item]=0
 g._arrive_landmark(true,false);count=driver.count_template()
 check(driver.counter_visit(g,p,count),"Combined strategy takes eligible real work when short of cash")
 check(g.income_days.size()==1 and g.income_days[0].eaten>0 and g.state.money>0,"Work trace records a real meal and earned money")
 check(g.supply_history.filter(func(e):return e.event=="settlement_wages").size()==g.income_days.size(),"Work receipts reconcile to work days")
 var cached=Save.new().capture(g)
 check(Save.new().restore(cached)!=null,"Observed paid work remains a genuine valid save")
 g=driver.make_study_game(566913);setup(g);g.configure(1,1);g.state.money=0
 check(g.start_hunt({"members":[0,1,2,3,4],"kit":"wagon","bullets":5}),"Pelt policy fixture starts actual leader hunt")
 g.hunt.animals=[{"kind":1,"escaped":false,"x":180.0,"y":116.0,"direction":1,"meat":53,"kcal_per_lb":550}];g.hunt.targets=[];g.hunt.meat=0
 check(g.hunt_shot(0),"Controlled real kill supplies a skin")
 check(g.skin_selection().get("deer_hide",0)==1,"Positive estimated surplus can select an actual skin")
 check(g.finish_hunt() and g.pelt_recoveries.size()==1 and g.state.deer_hide==1,"Selected skin uses actual preparation and recovery")
 check(g.pelt_recoveries[0].recovery.preparation_days==1 and g.pelt_recoveries[0].recovery.preparation_food_units>0,"Pelt trace records real extra day and meals")
 check(Save.new().restore(Save.new().capture(g))!=null,"Observed pelt recovery remains a genuine save")
 driver.free()
 print("Income comparison: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
