extends SceneTree
const Driver=preload("res://tests/crew_craft_campaign.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func setup(driver):
 var g=driver.make_study_game(570901)
 check(g.depart("farmer",["A","B","C","D","E"],5,driver.starting_cart(g,"foot","shared")),"Real study departure accepts legal backgrounds and contracts")
 return g
func run():
 var d=Driver.new();d.mastery="skilled";d.camp_policy="support";d.motion_policy="mobile"
 var snapshots: Array=[]
 for arm in ["off","crew","craft"]:
  d.income_arm=arm
  var g=setup(d);snapshots.append(Save.new().capture(g))
 check(snapshots[0]==snapshots[1] and snapshots[1]==snapshots[2],"All three arms have identical starting save, cash, skills and equipment")
 d.contract_arm="hired";d.income_arm="craft"
 var g=setup(d)
 var rate: int=g.characters.wage_quote(g.characters.profiles[2]).daily_cents
 check(g.characters.profiles[2].contract.wage_cents==rate*7 and g.characters.profiles[2].contract.auto_pay,"Hired cell uses real market rate and automatic weekly wages")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear"
 for m in g.party_health.members:m.health=100;m.conditions=[]
 g.state.health=100;g.state.deer_hide=1
 check(g.camp_tasks.assign(g,2,"tan_leather"),"Artisan can receive an actual standing craft order")
 g._arrive_landmark(true,false)
 var q: Dictionary=g.income.crew_quote(g,{"0":"labor","1":"carpentry"})
 var food: int=g.state.food;var day: int=g.state.day;var cash: float=g.state.money
 g.crew_launch=q.duplicate(true)
 check(g.income.work_crew(g,{"0":"labor","1":"carpentry"}),"Two real workers earn in one day")
 check(g.state.day==day+1 and g.state.food==food-q.meals,"Crew pays one party meal and consumes one calendar day")
 check(is_equal_approx(g.state.money,cash+q.cents/100.0),"Actual earned cash matches the full crew quote")
 check(g.state.deer_hide==0 and g.state.hide_scraped==1,"Unemployed artisan progresses while crew works")
 check(g.crew_days.size()==1 and g.crew_days[0].workers.size()==2,"Observer records two worker-days but one meal-day")
 q=g.income.crew_quote(g,{"2":"leatherwork"});g.crew_launch=q.duplicate(true)
 check(g.income.work_crew(g,{"2":"leatherwork"}) and g.state.hide_scraped==1 and int(g.state.get("hide_softened",0))==0,"Employed artisan cannot simultaneously craft")
 g.pending={}
 check(g.leathercraft.work(g,2,"tan_leather") and g.leathercraft.work(g,2,"tan_leather"),"Remaining actual dressing steps finish")
 check(g.leathercraft.work(g,2,"make_gloves") and g.leathercraft.work(g,2,"make_gloves") and g.state.buckskin_gloves==4,"Five worker-days yield four real glove pairs")
 check(g.supply_history.filter(func(e):return e.event=="leathercraft").size()==5,"Exactly five craft receipts, with no paid double work")
 check(g.supply_history.filter(func(e):return e.event=="settlement_wages").size()==3,"Three wage receipts are separate from two workdays")
 g._arrive_landmark(true,false)
 q=g.counter_quote({"buckskin_gloves":-4})
 check(q.valid and g.counter_checkout({"buckskin_gloves":-4}),"Craft output sells through a real counter")
 check(g.trade_sales.size()==1 and g.trade_sales[0].goods[0].quantity==4 and g.trade_sales[0].goods[0].cents==300,"Observer records actual glove sale, not hypothetical hide value")
 check(g.supply_history.any(func(e):return e.event=="wages"),"Elapsed integration days charge the actual weekly contract")
 check(Save.new().restore(Save.new().capture(g))!=null,"Integrated employment/craft/contract state restores")
 d.free()
 print("Crew/craft audit: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
