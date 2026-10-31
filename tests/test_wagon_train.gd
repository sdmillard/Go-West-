extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0;var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func _initialize():call_deferred("run")
func game():
 var g=Sim.new(57,"classic",true)
 check(g.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,{"oxen":6,"food":500,"clothing":5,"bullet_boxes":2}),"Start with five")
 g.state.money=10000;g.survival.data.event_chance=0;g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
 return g
func stop(g,id: String):
 g.route_path=g.route.main_path_to(id);g.state.landmark=id;g.state.next_landmark=id;g.state.leg_miles=0;g.state.leg_length=0;g.state.miles=int(g.route.node_miles()[id]);g._arrive_landmark(true,false)
 g.context.record.spent["post:"+id+"|visit"]=1
func roundtrip(g):return Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
func recruit(g,index: int):
 var key: String="passing:train_test_%d" % index
 var person: Dictionary=g.characters.generate_candidate(int(g.state.seed),index,"stranger")
 g.recruitment.record.searches[key]={"day":int(g.state.day),"candidate":person,"declined":false,"hired_id":-1}
 g.recruitment.hire(g,key)
func run():
 var g=game();stop(g,"independence")
 check(g.wagon_count()==1 and g.state.party_size==5,"One wagon and five starting travelers")
 var food: int=g.state.food;var money: float=g.state.money
 var quote: Dictionary=g.counter_quote({"wagon":1})
 check(quote.valid and quote.net_cents<0,"A second wagon is sold at the normal store price")
 check(g.counter_checkout({"wagon":1}) and g.wagon_count()==2,"Buy additional wagon while owning the first")
 check(g.state.money<money and g.state.food==food,"Wagon costs cash and creates no free food")
 check(g.state.wagon_train[0].team.size()==3 and g.state.wagon_train[1].team.size()==3,"Six oxen are divided into independent three-animal teams")
 check(g.provisions.capacity(g.state)==3750 and g.provisions.storage_capacity(g.state)==5000,"Separate teams limit working capacity while two frames supply storage")
 check(g.Train.ready(g).is_empty() and roundtrip(g)!=null,"A ready two-wagon train saves")
 var first: Dictionary=g.state.wagon_train[0]
 var second: Dictionary=g.state.wagon_train[1]
 check(not g.Train.assign(g,1,int(first.driver),second.team),"A driver cannot handle two wagons")
 check(not g.Train.assign(g,1,int(second.driver),first.team),"An ox cannot pull two wagons")
 check(g.Train.assign(g,1,-1,second.team) and not g.Train.ready(g).is_empty(),"Unassigned driver blocks train readiness")
 g.pending={};var day: int=g.state.day;var miles: int=g.state.miles
 check(g.travel() and g.state.miles==miles and g.state.day==day and g.pending.id=="train_unready","Driver shortage blocks travel without charging a day")
 g.pending={};check(g.Train.auto_assign(g),"Available companion can take the missing driving job")
 stop(g,"fort_laramie")
 check(g.counter_checkout({"oxen":2}),"Buy more oxen separately")
 g.Train.auto_assign(g)
 check(g.state.wagon_train.all(func(w):return w.team.size()==4) and g.provisions.capacity(g.state)==5000,"Four oxen per wagon restore normal pulling capacity")
 var healthy: int=g.Train.condition(g,g.state.wagon_train[1])
 for id in g.state.wagon_train[0].team:g.team_conditions.record.oxen[id]=30
 g.team_conditions.summarize(g)
 check(g.Train.condition(g,g.state.wagon_train[0])==30 and g.Train.condition(g,g.state.wagon_train[1])==healthy,"Each wagon retains its actual animal condition")
 check(g.Train.speed(g)<1.0,"The weaker team limits train pace")
 check(roundtrip(g)!=null,"Unequal ox teams round-trip without averaging away condition")
 var corrupt: Dictionary=Save.new().capture(g);corrupt.state.wagon_train[1].driver=corrupt.state.wagon_train[0].driver
 check(Save.new().restore(corrupt)==null,"Duplicate saved drivers rejected")
 corrupt=Save.new().capture(g);corrupt.state.wagon_train[1].team[0]=corrupt.state.wagon_train[0].team[0]
 check(Save.new().restore(corrupt)==null,"Duplicate saved draft animals rejected")
 var big=game()
 for index in range(31):recruit(big,index)
 check(big.state.party_size==36 and big.current_party_slots().size()==36,"Recruitment can exceed five slots and the former32-person archive bound")
 check(roundtrip(big)!=null,"Large roster, generated contracts and relationships save")
 big.pending={};big.state.food=10000
 var before: int=big.state.food
 big._tick_day(true)
 check(before-int(big.state.food)==36*int(big.provisions.data.rations_lb[big.state.rations]),"Every present traveler consumes a normal ration")
 var poor=game();poor.state.oxen=1;poor.team_conditions.sync(poor);stop(poor,"independence")
 check(not poor.counter_quote({"wagon":1}).valid,"Cannot add a wagon with no separate draft animal")
 check(poor.counter_quote({"wagon":1,"oxen":1}).valid,"Buying the needed ox in the same basket is supported")
 var no_driver=game();stop(no_driver,"independence")
 for id in range(1,5):no_driver.party_health.members[id]["away"]=true
 no_driver.state.party_size=1;no_driver.state.health=no_driver.party_health.average_health()
 check(not no_driver.counter_quote({"wagon":1}).valid,"Away companions cannot count as available drivers")
 for invalid in ["not an array",{},[null],[{"id":0,"driver":9999,"team":[],"condition":100}],g.state.wagon_train.duplicate(true)]:
  var malformed: Dictionary=Save.new().capture(g)
  malformed.state.wagon_train=invalid
  if invalid is Array and invalid.size()==2:malformed.state.next_wagon_id=0
  check(Save.new().restore(malformed)==null,"Malformed wagon ledger is rejected without crashing")
 var hiring=game();stop(hiring,"independence");hiring.recruitment.rules.find_chance=1.0
 hiring.open_companions()
 for i in range(hiring.pending.choices.size()):
  if hiring.pending.choices[i].get("recruit_command","")=="search":hiring.choose(i);break
 for i in range(hiring.pending.choices.size()):
  if hiring.pending.choices[i].get("recruit_command","")=="accept":hiring.choose(i);break
 check(hiring.state.party_size==6 and roundtrip(hiring)!=null,"Actual search and acceptance adds a sixth traveler without a vacancy")
 g._apply({"wheels":1})
 check(g.camp_repair.queue(g,"wheels") and g.state.wagon_train.filter(func(w):return w.condition==0).size()==1,"A breakdown belongs to one specific wagon")
 check(roundtrip(g)!=null,"Broken frame and repair identity save together")
 check(g.camp_repair.fit_spare(g) and g.state.wagon_train.all(func(w):return w.condition==100),"Fitting a spare repairs the affected frame")
 var sale_food: int=g.state.food
 check(g.counter_checkout({"wagon":-1}) and g.wagon_count()==1 and g.state.food==sale_food,"Selling an extra wagon keeps the party and shared provisions")
 check(roundtrip(g)!=null,"Reduced train saves")
 var convoy=game();stop(convoy,"independence");convoy.counter_checkout({"wagon":1});convoy._set_next_leg();convoy.pending={}
 var pack: Dictionary={"food":20,"clothing":5,"bullets":10}
 check(convoy.abandon_wagon(pack) and convoy.wagon_count()==0 and convoy.wagon_cache.wagons.size()==2,"Packing for foot travel caches both wagons")
 check(roundtrip(convoy)!=null,"Cached train, individual oxen and foot party save")
 convoy.pending={};convoy.inspect_cached_wagon()
 check(convoy.wagon_count()==2 and convoy.wagon_cache.is_empty() and convoy.state.wagon_train.map(func(w):return w.id)==[0,1] and roundtrip(convoy)!=null,"Recovering the cache restores exactly the two owned frames")
 var driver_loss=game();stop(driver_loss,"independence");driver_loss.counter_checkout({"wagon":1})
 var lost_driver: int=driver_loss.state.wagon_train[1].driver
 driver_loss.party_health.kill(driver_loss.party_health.members[lost_driver],int(driver_loss.state.day),"test injury");driver_loss._collect_health_events()
 driver_loss.state.party_size=driver_loss.party_health.living_count();driver_loss.state.health=driver_loss.party_health.average_health()
 check(not driver_loss.Train.ready(driver_loss).is_empty(),"A dead driver leaves their wagon unable to travel")
 check(driver_loss.Train.auto_assign(driver_loss) and driver_loss.Train.ready(driver_loss).is_empty(),"A surviving spare can take over driving")
 stop(big,"independence");big.provisions.data.replacement_wagon.stock_per_post=8
 check(big.counter_checkout({"wagon":5}) and big.wagon_count()==6,"A recruited party can own more than five wagons when stock, cash and draft animals permit")
 check(roundtrip(big)!=null,"Six-wagon train saves")
 var before_quote: Dictionary=Save.new().capture(big)
 big.counter_quote({"wagon":-1})
 check(Save.new().capture(big)==before_quote,"Train purchase/sale preview is read-only")
 var stranded=game();stop(stranded,"independence");stranded.counter_checkout({"wagon":1});stranded.pending={};stranded._set_next_leg()
 var keep_food: int=stranded.state.food;var keep_oxen: int=stranded.state.oxen
 check(stranded.Train.discard(stranded,1) and stranded.wagon_count()==1,"An unwanted extra frame can be left behind without abandoning the whole train")
 check(stranded.state.food==keep_food and stranded.state.oxen==keep_oxen and roundtrip(stranded)!=null,"Leaving an empty frame keeps provisions and animals, with a valid save")
 check(not stranded.Train.discard(stranded,0),"The final wagon uses the existing packing/abandonment flow")
 var broken_drop=game();stop(broken_drop,"independence");broken_drop.counter_checkout({"wagon":1});broken_drop.camp_repair.queue(broken_drop,"axles")
 var broken_index: int=broken_drop.state.wagon_train.find(broken_drop.state.wagon_train.filter(func(w):return w.condition==0).front())
 check(broken_drop.Train.discard(broken_drop,broken_index) and broken_drop.camp_repair.work.is_empty() and roundtrip(broken_drop)!=null,"Leaving the damaged frame removes its repair obligation without repairing other wagons")
 var river=game();stop(river,"independence");river.counter_checkout({"wagon":1});stop(river,"kansas_river")
 var ferry: Dictionary=river.pending.choices.filter(func(c):return c.get("method","")=="ferry").front()
 var node: Dictionary=river.route.nodes.kansas_river
 var expected: float=float(node.get("ferry_high_dollars",node.ferry_dollars)) if river.state.river_stage=="high" else float(node.ferry_dollars)
 check(ferry.requires.money==expected*2,"Ferry quote charges for each wagon")
 for i in range(river.pending.choices.size()):
  if river.pending.choices[i].get("method","")=="ford":
   river.pending.choices[i].risk=1.0;river.choose(i);break
 check(river.crossing_history[-1].wagons.size()==2 and river.crossing_history[-1].food_lost==60,"Each wagon gets its own crossing risk and recorded loss")
 check(roundtrip(river)!=null,"Multi-wagon crossing outcome saves")
 var footsteps=game();footsteps.pending={};footsteps.state.food=0
 footsteps._apply({"vehicle":"foot"})
 stop(footsteps,"independence");footsteps.counter_checkout({"wagon":1,"oxen":1})
 check(footsteps.wagon_count()==1 and roundtrip(footsteps)!=null,"Walking parties can still buy a replacement first wagon")
 var nursing=game();stop(nursing,"independence");nursing.counter_checkout({"wagon":1});nursing.state.medicine=1
 var patient: int=nursing.state.wagon_train[0].driver
 nursing.party_health.members[patient].health=60;nursing.state.health=nursing.party_health.average_health()
 check(nursing.camp_tasks.assign(nursing,3,"nurse",patient) and not nursing.Train.ready(nursing).is_empty(),"A funded nursing patient cannot also drive a wagon")
 nursing.camp_tasks.assign(nursing,3,"rest")
 check(nursing.Train.ready(nursing).is_empty(),"Ending nursing makes the driver available again")
 var late_death=game();stop(late_death,"independence");late_death.counter_checkout({"wagon":1});late_death.pending={};late_death._set_next_leg()
 late_death.state.pace=2
 var fragile: int=late_death.state.wagon_train[0].driver
 late_death.party_health.members[fragile].health=1;late_death.state.health=late_death.party_health.average_health()
 var departure_day: int=late_death.state.day;var departure_mile: int=late_death.state.miles
 check(late_death.travel() and late_death.state.day==departure_day+1 and late_death.state.miles==departure_mile and not late_death.party_health.members[fragile].alive,"Driver death during the day charges time/meals but grants no unmanned travel miles")
 var view=preload("res://ui/wagon_train_view.gd").new();root.add_child(view);await process_frame
 view.open(g)
 check(view.visible and view.rows.get_child_count()==1,"Wagon ledger lists each wagon")
 var selector: OptionButton=view.rows.get_child(0).get_child(1)
 selector.item_selected.emit(0)
 check(g.state.wagon_train[0].driver==-1,"Choosing Unassigned in the UI really releases the driver")
 var interaction=game();stop(interaction,"independence");interaction.counter_checkout({"wagon":1});view.open(interaction)
 var original_first: Array=interaction.state.wagon_train[0].team.duplicate()
 var removed: int=interaction.state.wagon_train[1].team[0]
 var menu: PopupMenu=view.rows.get_child(1).get_child(2).get_popup()
 menu.id_pressed.emit(removed)
 check(removed not in interaction.state.wagon_train[1].team and interaction.state.wagon_train[0].team==original_first,"The second wagon's ox menu edits its own team without disturbing the first")
 view.hide();view.queue_free()
 print("Wagon trains: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
