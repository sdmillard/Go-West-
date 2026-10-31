extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party():
 var g=Sim.new(566102,"classic",true)
 g.characters.start(566102,5)
 var custom: Dictionary={"profiles":g.characters.profiles.duplicate(true),"contracts":{},"keepsakes":[true,true,true,true,true]}
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":250,"clothing":5,"bullet_boxes":5,"medicine":5},custom),"Income fixture departs with chosen personal goods")
 g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear";g.survival.data.event_chance=0
 return g
func stop(g,id: String="independence"):
 g.state.landmark=id;g.state.next_landmark=id;g._arrive_landmark(true,false)
func run():
 var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_income.json"))
 check(preload("res://simulation/trail_income.gd").valid_rules(rules),"Authored income rules validate")
 var invalid: Dictionary=rules.duplicate(true);invalid.jobs.labor.cents=-1
 check(not preload("res://simulation/trail_income.gd").valid_rules(invalid),"Negative wage rejects")
 invalid=rules.duplicate(true);invalid.keepsake.weight_lb=0
 check(not preload("res://simulation/trail_income.gd").valid_rules(invalid),"Weightless keepsake rejects")
 var g=party();stop(g)
 check(g.income.record.keepsakes.size()==5 and g.state.keepsake_0==1,"Each selected owner gets exactly one item")
 var cargo: float=g.provisions.cargo(g.state)
 var empty: Dictionary=g.state.duplicate()
 for item in g.income.all_keys():empty.erase(item)
 check(is_equal_approx(cargo,snappedf(g.provisions.cargo(empty)+1.25,0.1)),"Five keepsakes count their actual weight")
 var snapshot: Dictionary=Save.new().capture(g)
 var restored=Save.new().restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(restored!=null and Save.new().capture(restored)==snapshot,"Keepsake ownership and work ledger round-trip exactly")
 check(not g.counter_quote({"keepsake_1":-1}).valid,"A companion's item cannot sell without consent")
 g.characters.profiles[1].trust=49
 check(not g.income.consent(g,1,true),"Unwilling companion cannot be forced to consent")
 g.characters.profiles[1].trust=50
 check(g.income.consent(g,1,true),"Present trusting owner can explicitly consent")
 check(g.counter_quote({"keepsake_1":-1}).valid,"Consented item becomes sellable")
 check(g.income.consent(g,1,false) and not g.counter_quote({"keepsake_1":-1}).valid,"Consent can be withdrawn before sale")
 check(g.income.consent(g,1,true),"Owner can consent again")
 var money: float=g.state.money
 check(g.counter_checkout({"keepsake_0":-1,"keepsake_1":-1}) and is_equal_approx(g.state.money-money,4.0),"Actual counter pays exact keepsake proceeds")
 restored=Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
 check(restored!=null and restored.state.keepsake_0==0 and restored.income.record==g.income.record,"Sold goods and consent persist in a real save")
 check(not g.counter_quote({"keepsake_0":-1}).valid,"A sold keepsake cannot be sold twice")
 g.state.status="arrived"
 check(g.income.points(g)==300,"Only remaining carried keepsakes score on arrival")
 g.state.status="traveling"
 check(g.income.points(g)==0,"No arrival points before Oregon")
 g.party_health.members[2].alive=false;g.state.status="traveling"
 check(g.counter_quote({"keepsake_2":-1}).valid,"Deceased owner belongings can be sold as estate goods")
 g.state.status="arrived"
 check(g.income.points(g)==300,"Retained memorial keepsakes still score")
 g=party();stop(g)
 var before: Dictionary=Save.new().capture(g);var q: Dictionary=g.income.quote(g,0,"labor")
 check(q.valid and q.cents==100 and q.days==1 and q.meals==15,"Work preview gives wage, time and full party meals")
 check(Save.new().capture(g)==before,"Preview changes no state or random streams")
 check(not g.income.work(g,99,"labor") and Save.new().capture(g)==before,"Invalid worker rejected atomically")
 var day: int=g.state.day;var food: int=g.state.food;money=g.state.money
 check(g.income.work(g,0,"labor"),"Leader can do a real paid day")
 check(g.state.day==day+1 and g.state.miles==0 and is_equal_approx(g.state.money-money,1.0) and g.state.food==food-15,"Work spends a calendar day/meals and pays one dollar without travel")
 check(not g.camp_tasks.enabled(),"Working once does not enable standing camp assignments")
 check(g.income.record.work.independence==1 and g.camp_tasks.day_plan.is_empty() and g.income.worker==-1,"Work quota settles once and no transient worker remains")
 check(g.supply_history.any(func(h):return h.event=="settlement_wages"),"Work payment enters supply history")
 for index in range(5):check(g.income.work(g,0,"labor"),"Remaining finite work day settles")
 check(not g.income.quote(g,0,"labor").valid,"Local work is exhausted across all job types")
 restored=Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
 check(restored!=null and not restored.income.quote(restored,0,"labor").valid,"Reload does not refresh work")
 g=party();stop(g)
 g.characters.profiles[1].specials=["Mercenary"]
 var rate: int=g.characters.wage_quote(g.characters.profiles[1]).daily_cents
 check(g.characters.start_contract(g,1,rate,1) and g.characters.set_auto_pay(g,1,true),"Work/autopay fixture agrees a real daily wage")
 g.state.money=0
 check(g.income.work(g,0,"labor") and g.characters.profiles[1].contract.arrears_cents==0 and is_equal_approx(g.state.money,1-rate/100.0),"Today's employment funds today's automatic companion wage")
 g=party();stop(g,"ash_hollow")
 check(g.income.offers(g).is_empty(),"A trail landmark is not a settlement job market")
 stop(g,"fort_kearny")
 check(g.income.offers(g).is_empty(),"Early Kearny has no construction jobs before June")
 g.state.departure_month=6
 check(not g.income.offers(g).is_empty(),"Kearny work opens in construction season")
 g=party();stop(g)
 g.party_health.members[1].health=30
 check(not g.income.quote(g,1,"labor").valid,"Poorly conditioned worker cannot be hired")
 g.party_health.members[1].health=80;g.party_health.members[1]["away"]=true
 check(not g.income.quote(g,1,"labor").valid,"Away worker cannot also earn at the post")
 g.party_health.members[1].erase("away")
 g.characters.profiles[1].skill="Carpentry"
 check(g.income.quote(g,1,"carpentry").valid and g.income.quote(g,1,"carpentry").cents==150,"Relevant background unlocks skilled work")
 g.characters.profiles[2].skill="Hunting"
 check(not g.income.quote(g,2,"carpentry").valid,"Skilled rate requires the background")
 g.party_health.members[0].health=60
 check(g.camp_tasks.assign(g,1,"nurse",0),"Nursing fixture can be assigned")
 check(not g.income.quote(g,0,"labor").valid,"Nursed leader is locked to rest")
 var kits: int=g.state.medicine
 check(g.income.work(g,1,"carpentry") and g.state.medicine==kits,"Paid worker does not also spend a kit nursing")
 check(g.camp_tasks.job(1).job=="nurse","One work day preserves standing camp orders for future days")
 g=party();g.pending={}
 check(g.abandon_wagon({"food":20,"clothing":5,"bullets":20,"keepsake_0":1}),"Actual packing accepts a selected personal object")
 check(g.state.keepsake_0==1 and g.wagon_cache.inventory.keepsake_0==0 and g.wagon_cache.inventory.keepsake_1==1,"Packing separates people-owned goods without duplication")
 snapshot=Save.new().capture(g)
 restored=Save.new().restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(restored!=null and restored.income.record==g.income.record,"Cached ownership survives saving")
 var bad: Dictionary=snapshot.duplicate(true);bad.wagon_cache.inventory.keepsake_0=1
 check(Save.new().restore(bad)==null,"Duplicate unique object across wagon and packs rejects")
 bad=snapshot.duplicate(true);bad.state.keepsake_0=0.5
 check(Save.new().restore(bad)==null,"Fractional keepsake rejects")
 bad=snapshot.duplicate(true);bad.income.keepsakes.erase("0")
 check(Save.new().restore(bad)==null,"Physical object without ownership rejects")
 bad=snapshot.duplicate(true);bad.income.keepsakes["0"].consent="yes"
 check(Save.new().restore(bad)==null,"Malformed permission rejects")
 bad=snapshot.duplicate(true);bad.state.keepsake_32=1
 check(Save.new().restore(bad)==null,"Unknown owner item rejects")
 bad=snapshot.duplicate(true);bad.income.work={"independence":100}
 check(Save.new().restore(bad)==null,"Invalid work ledger rejects")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-income-save-v1.json"))
 restored=Save.new().restore(old)
 check(restored!=null and restored.state==Save.new().upgraded_state(old.state) and restored.income.record.keepsakes.is_empty(),"Genuine previous save retains state and receives no invented valuables")
 g=party();stop(g);g._depart(g.plan_for([1]),"")
 check(g.state.keepsake_1==0 and g.state.keepsake_0==1,"Departing companion takes only their own carried keepsake")
 var screen=load("res://ui/main.gd").new();root.add_child(screen);await process_frame
 check(screen.departure_view.customization().keepsakes==[true,true,true,true,true],"Creation includes each traveler's optional keepsake")
 screen.game=party();stop(screen.game);screen.departure_view.hide();screen._refresh()
 check(screen.place_actions.get_children().any(func(b):return b.text=="FIND WORK"),"Work appears as a local action below the scene")
 screen.income_window.open(screen.game,"work");await process_frame
 check(screen.income_window.worker_choices.size()==5,"Work window uses one compact roster row per traveler")
 check(screen.income_window.commit_button.disabled,"An empty crew cannot commit a paid day")
 var selection=screen.income_window.worker_choices[0]
 selection.select(1);selection.item_selected.emit(1)
 day=screen.game.state.day;screen.income_window.commit_button.pressed.emit()
 check(screen.game.state.day==day+1,"Visible crew button commits exactly one paid day")
 screen.income_window.hide();screen.queue_free();await process_frame
 print("Trail income: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
