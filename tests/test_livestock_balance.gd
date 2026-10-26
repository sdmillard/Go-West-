extends SceneTree
const Plain=preload("res://simulation/trail_engine.gd")
const Observer=preload("res://tests/livestock_balance_observer.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func make_game(script,stock: bool):
 var g=script.new(310900,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500,"clothing":5,"bullet_boxes":2,"horses":1,"saddles":1}
 if stock:cart.merge({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":120},true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,cart),"Observer fixture departs")
 g.survival.forced_weather="clear";g.survival.data.event_chance=0;g.party_health.daily_onset_chance=0
 return g
func _initialize():call_deferred("run")
func run():
 var save=Save.new()
 for stock in [false,true]:
  var plain=make_game(Plain,stock);var observed=make_game(Observer,stock)
  for day in range(20):
   plain.pending={};observed.pending={}
   if day%3==0:plain.rest_in_camp();observed.rest_in_camp()
   else:plain.travel();observed.travel()
   check(save.capture(plain)==save.capture(observed),"Read-only observation preserves actual state, food and random streams")
  check(observed.audit.days==observed.state.day,"All actual days observed")
  check(observed.livestock.audit.food_generated>=observed.provisions.dairy_eaten,"Dairy eaten cannot exceed generated food")
  if stock:
   check(observed.livestock.audit.food_generated>0 and observed.provisions.dairy_eaten>0,"Actual livestock production and eating are observed")
  else:check(observed.livestock.audit.herd_days==0 and observed.provisions.dairy_eaten==0,"No phantom livestock benefit without animals")
 var g=make_game(Observer,true)
 g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 check(g.post_checkout({"poultry_feed":40}),"Actual stock purchase succeeds")
 check(g.purchases.size()==1 and g.purchases[0].cart.poultry_feed==40,"Actual purchase amount and cash are observed")
 var campaign=load("res://tests/livestock_balance_campaign.gd").new()
 campaign.stock_policy="aware";campaign.livestock_arm="mixed";campaign.camp_policy="support";campaign.fishing_policy="support"
 g.pending={}
 var note: Dictionary=campaign.plan_jobs(g)
 check(campaign.chore_reserved.size()==2,"Mixed herd reserves two real helpers when available")
 check(campaign.chore_reserved.all(func(id):return g.camp_tasks.job(id).job=="rest"),"Caretakers are unassigned from competing tasks")
 check(note.foragers.size()>=1,"Caretaker strategy preserves a forager")
 campaign.livestock_arm="none"
 var bare=make_game(Observer,false)
 campaign.plan_jobs(bare)
 check(campaign.chore_reserved.is_empty(),"Aware policy is inert without livestock")
 campaign.free()
 var existing=load("res://tests/livestock_balance_campaign.gd").new()
 var aware=load("res://tests/livestock_balance_campaign.gd").new()
 existing.stock_policy="existing";aware.stock_policy="aware"
 for driver in [existing,aware]:driver.motion_policy="mobile";driver.camp_policy="support";driver.fishing_policy="support";driver.travel_pace=1
 var left=make_game(Observer,false);var right=make_game(Observer,false)
 var left_aim:=RandomNumberGenerator.new();left_aim.seed=310900
 var right_aim:=RandomNumberGenerator.new();right_aim.seed=310900
 var left_count: Dictionary=existing.count_template();var right_count: Dictionary=aware.count_template()
 for step in range(60):
  if left.state.status!="traveling" or right.state.status!="traveling":break
  var a: bool=existing.act(left,existing.policy("foot"),left_aim,left_count)
  var b: bool=aware.act(right,aware.policy("foot"),right_aim,right_count)
  check(a==b and save.capture(left)==save.capture(right),"No-stock policies remain action-for-action identical")
 existing.free();aware.free()
 print("Livestock balance observers: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
