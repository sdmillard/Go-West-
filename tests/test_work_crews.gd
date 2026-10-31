extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var g=Sim.new(569201,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":250,"clothing":5,"bullet_boxes":5,"medicine":5}),"Crew fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear";g._arrive_landmark(true,false)
 g.characters.profiles[1].skill="Carpentry"
 g.characters.profiles[2].specials=["Leatherworker"]
 return g
func run():
 var g=party();var roles: Dictionary={"0":"labor","1":"carpentry","2":"leatherwork"}
 check(not g.income.quote(g,0,"leatherwork").valid and g.income.quote(g,2,"leatherwork").valid,"Leather repair work requires the distinct specialty")
 var snapshot: Dictionary=Save.new().capture(g)
 var quote: Dictionary=g.income.crew_quote(g,roles)
 check(quote.valid and quote.workers.size()==3 and quote.cents==350 and quote.meals==15,"Crew preview totals three wages but one party meal/day")
 check(Save.new().capture(g)==snapshot,"Crew preview is state/RNG neutral")
 for invalid in [{"0":"labor","1":"labor","2":"labor"},{"0":"carpentry"},{"0":"labor","00":"care"},{"32":"labor"},{"0":"unknown"}]:
  check(not g.income.work_crew(g,invalid) and Save.new().capture(g)==snapshot,"Invalid entire crew is rejected atomically")
 var day: int=g.state.day;var food: int=g.state.food;var money: float=g.state.money
 check(g.income.work_crew(g,roles),"Three actual workers settle as one crew")
 check(g.state.day==day+1 and g.state.food==food-15 and is_equal_approx(g.state.money-money,3.5),"One elapsed day and meal yields exact aggregate payroll")
 check(g.income.record.work.independence==3 and g.income.workers.is_empty() and g.income.worker==-1,"Quota consumes three worker-days and transient crew clears")
 check(g.supply_history.filter(func(e):return e.event=="settlement_wages").size()==3,"Each worker has their own earnings receipt")
 var restored=Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
 check(restored!=null and restored.income.record.work.independence==3,"Crew earnings and demand round-trip")
 check(g.income.work_crew(g,roles) and not g.income.crew_quote(g,{"0":"labor"}).valid,"Shared total work allowance cannot be refreshed with more workers")
 g=party();g.state.landmark="fort_bridger";g.state.next_landmark="fort_bridger";g._arrive_landmark(true,false)
 check(not g.income.crew_quote(g,roles).valid,"Small post daily crew limit is enforced separately from total demand")
 g=party();g.party_health.members[4].health=60
 check(g.camp_tasks.assign(g,3,"nurse",4),"Nurse fixture assigns care")
 snapshot=Save.new().capture(g)
 check(not g.income.work_crew(g,{"0":"labor","4":"labor"}) and Save.new().capture(g)==snapshot,"A nursed patient blocks the whole proposed crew without partial wages")
 var kits: int=g.state.medicine
 check(g.income.work_crew(g,roles) and g.state.medicine==kits-1,"Nonworkers can still nurse during a crew day")
 g=party();g.party_health.members[0].health=60
 check(g.camp_tasks.assign(g,3,"nurse",0),"Leader's nurse can be reserved before a crew day")
 kits=g.state.medicine
 check(g.income.work_crew(g,{"1":"carpentry","2":"leatherwork"}) and g.state.medicine==kits-1 and g.camp_tasks.job(3).patient==0,"Unemployed leader can remain nursed while multiple companions earn wages")
 g=party();g.party_health.members[4].health=60;g.camp_tasks.assign(g,1,"nurse",4)
 kits=g.state.medicine
 check(g.income.work_crew(g,{"0":"labor","1":"carpentry"}) and g.state.medicine==kits,"An employed nurse cannot simultaneously spend a nursing kit")
 check(g.camp_tasks.job(1).job=="nurse","Paid work preserves the nurse's standing order for later days")
 g=party();g.characters.profiles[2].skill="Carpentry";g.characters.profiles[2].specials=["Leatherworker","Veteran","Mercenary"]
 var rate: int=g.characters.wage_quote(g.characters.profiles[2]).daily_cents
 var offer: Dictionary=g.income.quote(g,2,"leatherwork")
 check(rate>100 and offer.cents==rate,"A specialist's market quote raises an otherwise lower job offer")
 check(g.characters.start_contract(g,2,rate*7,7) and g.characters.set_auto_pay(g,2,true),"Real market-rate mercenary agreement starts")
 g.state.money=0
 for index in range(7):
  if index==6:g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
  check(g.income.work(g,2,"leatherwork"),"Hired specialist earns an actual paid day")
 check(g.characters.profiles[2].contract.arrears_cents==0 and is_zero_approx(g.state.money),"Seven market-rate work days fund the actual weekly automatic wage")
 g=party();g.characters.profiles[2].skill="Carpentry";g.characters.profiles[2].specials=["Leatherworker","Veteran","Mercenary"]
 rate=g.characters.wage_quote(g.characters.profiles[2]).daily_cents
 check(g.characters.start_contract(g,2,rate*14,7),"A deliberately generous private contract is valid")
 offer=g.income.quote(g,2,"leatherwork")
 check(offer.cents==rate and not offer.covers_contract,"Inflating a private contract cannot inflate local pay")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-work-crews-save-v1.json"))
 restored=Save.new().restore(old)
 check(restored!=null and restored.state==Save.new().upgraded_state(old.state) and restored.income.record==Save.new().normalize(old.income),"Actual prior paid-work save preserves cash, people and consumed demand")
 var screen=load("res://ui/main.gd").new();root.add_child(screen);await process_frame
 screen.game=party();screen.departure_view.hide();screen.income_window.open(screen.game,"work");await process_frame
 for id in [0,1,2]:
  var choice=screen.income_window.worker_choices[id];var target: String=roles[str(id)]
  for option in range(choice.item_count):
   if choice.get_item_metadata(option)==target:choice.select(option);choice.item_selected.emit(option)
 check(not screen.income_window.commit_button.disabled and screen.income_window.crew.size()==3,"Visible roster can select three different workers and roles")
 day=screen.game.state.day;screen.income_window.commit_button.pressed.emit()
 check(screen.game.state.day==day+1 and screen.game.income.record.work.independence==3,"Single visible commit settles all three workers in one day")
 check(screen.game.characters.SKILLS.has("Leatherworking") and not screen.departure_view.special_checks.has("Leatherworker"),"Leatherworking background replaces the selectable special")
 screen.income_window.hide();screen.queue_free();await process_frame
 print("Work crews: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
