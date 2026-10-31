extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Model=preload("res://simulation/native_encounters.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0;var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func _initialize():call_deferred("run")
func party():
 var g=Sim.new(57,"classic",true)
 check(g.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,{"oxen":6,"food":500,"clothing":5,"bullet_boxes":2}),"Native encounter fixture departs")
 g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 return g
func stop(g,id: String):
 g.route_path=g.route.main_path_to(id)
 if id=="columbia_raft":g.route_path=g.route.main_path_to("the_dalles");g.route_path.append(id)
 g.state.landmark=id;g.state.next_landmark=id;g.state.leg_miles=0;g.state.leg_length=0;g.state.miles=int(g.route.node_miles()[id]);g._arrive_landmark(true,false)
func command(g,cmd: String,offer: String="") -> bool:
 for i in range(g.pending.get("choices",[]).size()):
  if g.pending.choices[i].get("native_command","")==cmd and (offer.is_empty() or g.pending.choices[i].get("native_offer","")==offer):return g.choose(i)
 return false
func saved(g):return Save.new().capture(g)
func restore(g):return Save.new().restore(JSON.parse_string(JSON.stringify(saved(g))))
func run():
 var model=Model.new()
 check(model.error.is_empty() and model.data.sites.size()==7,"Seven place-specific encounters load")
 for corruption in ["price","source","stock","effect","site"]:
  var v: Dictionary=model.data.duplicate(true)
  match corruption:
   "price":v.portage_cents_per_load=-1
   "source":v.sites.platte.sources=["javascript:alert(1)"]
   "stock":v.sites.platte.offers[0].lots=0
   "effect":v.sites.platte.offers[0].item="health"
   "site":v.sites.fort_hall.portage=true
  check(not Model.new().load_data(v),"Malformed encounter data rejected: "+corruption)
 var g=party();stop(g,"independence")
 check(not g.open_native_contacts(),"No generic Native menu appears at an unrelated stop")
 stop(g,"platte");var old: Dictionary=saved(g);var stream: int=g.rng.state
 check(g.open_native_contacts() and g.pending.title=="Pawnee trading families","Specific community appears at the Platte stop")
 check(command(g,"back") and saved(g)==old,"Opening and declining spends no time, resources or RNG")
 g.open_native_contacts();var day: int=g.state.day;var food: int=g.state.food;var cash: float=g.state.money
 command(g,"notes");var journal_size: int=g.journal.size();command(g,"notes")
 check(g.state.day==day and g.state.food==food and g.state.money==cash and g.rng.state==stream and g.journal.size()==journal_size,"Conversation is free, deterministic and does not farm duplicate rewards or logs")
 check(restore(g)!=null,"An open conversation saves")
 var amount: int=g.native_encounters.offer_at("platte","provisions").amount
 var cost: int=g.native_encounters.price(g,g.native_encounters.offer_at("platte","provisions"))
 check(command(g,"trade","provisions"),"Buy the local household's provisions")
 var meals: int=int(g.provisions.data.rations_lb[g.state.rations])*g.state.party_size
 check(g.state.day==day+1 and g.state.food==food+amount-meals and is_equal_approx(g.state.money,cash-cost/100.0),"First purchase charges quoted cash, one real day and party meals")
 day=g.state.day;food=g.state.food;cash=g.state.money
 check(command(g,"trade","provisions") and g.state.day==day and g.state.food==food+amount and g.state.money<cash,"Second parcel uses actual stock without a second visit day")
 check(not command(g,"trade","provisions"),"Household stock is finite")
 check(restore(g)!=null,"Used household stock round-trips")
 command(g,"back");g.open_native_contacts()
 check(not command(g,"trade","provisions"),"Reopening never replenishes household stock")
 var corrupt: Dictionary=saved(g);corrupt.native_contacts.platte.purchases.provisions=99
 check(Save.new().restore(corrupt)==null,"Overdrawn saved stock is rejected")
 corrupt=saved(g);corrupt.pending.choices[0].effects={"food":999}
 check(Save.new().restore(corrupt)==null,"Serialized Native commands cannot carry forged effects")
 corrupt=saved(g);corrupt.pending.native_site="fort_hall"
 check(Save.new().restore(corrupt)==null,"A saved visit cannot move to a different site")
 command(g,"back");stop(g,"umatilla");g.state.departure_month=3
 g.open_native_contacts()
 check(not command(g,"trade","fresh"),"Fresh produce is unavailable out of season")
 command(g,"back");g.state.departure_month=8;g.open_native_contacts()
 check(command(g,"trade","fresh") and g.provisions.fresh.any(func(b):return b.get("produce",false) or b.get("vitamin_c_lb",0)>0 or b.get("vitamin_c",false)),"Produce uses the existing physical food and vitamin system")
 check(restore(g)!=null,"Bought produce saves with normal expiry and nutrients")
 var guide=party();stop(guide,"deschutes");guide.open_native_contacts();day=guide.state.day;cash=guide.state.money
 check(command(guide,"guidance") and guide.state.day==day+1 and guide.state.money==cash-1,"A guide costs cash and one real day")
 check(guide.native_encounters.guidance_factor(guide)<1 and not command(guide,"guidance"),"Booked assistance applies without duplicate payment")
 check(restore(guide)!=null,"Paid guide booking saves")
 command(guide,"back");guide._tick_day(true)
 check(guide.native_encounters.guidance_factor(guide)==1,"A guide booking does not give permanent free assistance after waiting")
 var horses=party();stop(horses,"grande_ronde");horses.open_native_contacts()
 check(command(horses,"horses") and horses.pending.title==horses.context.data.horse_traders.grande_ronde.name,"Existing Nez Perce herd is reused")
 check(horses.pending.choices[0].market_key=="herders:grande_ronde|buy_horses","No duplicate horse inventory or price schedule is created")
 var portage=party();stop(portage,"columbia_raft");day=portage.state.day;cash=portage.state.money;food=portage.state.food
 check(portage.pending.choices.any(func(c):return c.get("native_portage",false)),"Paid portage is a normal Cascades choice")
 portage.open_native_contacts()
 check(restore(portage)!=null,"Portage discussion saves before committing")
 check(command(portage,"portage") and portage.state.day==day+1 and portage.state.next_landmark=="oregon_city" and portage.raft.is_empty(),"Paid portage advances one normal day and bypasses the rapids activity")
 check(portage.state.money==cash-3 and portage.state.food==food-meals,"Portage charges its actual quote and meals")
 check(not command(portage,"portage"),"Completed portage cannot settle twice")
 check(restore(portage)!=null,"Completed assisted portage saves on the onward route")
 var loaded=party();stop(loaded,"columbia_raft");loaded.open_native_contacts();loaded=restore(loaded)
 check(loaded!=null and command(loaded,"portage") and loaded.state.next_landmark=="oregon_city","Reloaded portage quotes remain payable after numeric JSON normalization")
 var convoy=party();stop(convoy,"independence");convoy.context.record.spent["post:independence|visit"]=1;convoy.counter_checkout({"wagon":1})
 stop(convoy,"columbia_raft");convoy.open_native_contacts();cash=convoy.state.money
 check(command(convoy,"portage") and convoy.state.money==cash-6,"Portage labor quote scales with two wagonloads")
 var poor=party();stop(poor,"the_dalles");poor.state.money=0;poor.open_native_contacts()
 var untouched: Dictionary=saved(poor)
 check(not command(poor,"trade","provisions") and saved(poor)==untouched,"Unaffordable purchases reject atomically")
 var elsewhere=party();stop(elsewhere,"fort_hall");elsewhere.open_native_contacts()
 var trade_index: int=elsewhere.pending.choices.find(elsewhere.pending.choices.filter(func(c):return c.get("native_command","")=="trade")[0])
 elsewhere.pending.choices[trade_index].native_offer="fresh"
 check(not elsewhere.can_choose(trade_index),"A different community's offer cannot be injected into the current visit")
 check(g.supply_history.any(func(r):return r.get("event","")=="native_trade"),"Purchases have auditable supply receipts")
 var recruits=party();stop(recruits,"the_dalles");recruits.recruitment.rules.find_chance=1
 recruits.open_native_contacts();day=recruits.state.day;food=recruits.state.food
 check(command(recruits,"recruit") and recruits.pending.get("recruit_site","")=="native:the_dalles","Community visit opens the normal recruitment system")
 check(restore(recruits)!=null,"Open community recruitment saves before searching")
 check(recruits.choose(0) and recruits.state.day==day+1 and recruits.state.food==food-meals,"Searching consumes one real day and meals")
 var candidate: Dictionary=recruits.recruitment.candidate(recruits).duplicate(true)
 check(not candidate.is_empty() and candidate.profile.appearance.heritage=="Wasco","Community recruitment supplies a local upbringing")
 var expected: Dictionary=recruits.characters.generate_candidate(int(recruits.state.seed),int("native:the_dalles".hash())%1000000,"stranger")
 expected.profile.appearance.heritage="Wasco"
 check(candidate==expected,"Local identity changes no skill, trait, wage or survival statistic")
 var found=restore(recruits)
 check(found!=null and found.recruitment.candidate(found)==Save.new().normalize(candidate),"Candidate and contract terms remain fixed across saves")
 check(recruits.choose(0) and recruits.party_health.members.size()==6 and recruits.state.party_size==6,"A willing recruit joins an already full starting party")
 check(recruits.characters.profiles[5].appearance.heritage=="Wasco" and recruits.recruitment.record.searches["native:the_dalles"].hired_id==5,"Joined traveler retains identity and immutable recruitment record")
 if not candidate.terms.is_empty():check(not recruits.characters.profiles[5].contract.is_empty(),"A paid recruit uses the existing wage contract")
 check(restore(recruits)!=null,"Expanded party from a community encounter saves")
 recruits.choose(recruits.pending.choices.size()-1);recruits.open_native_contacts();command(recruits,"recruit")
 check(recruits.pending.choices.size()==1,"Reopening a visit cannot recruit the same traveler twice")
 var nobody=party();stop(nobody,"platte");nobody.recruitment.rules.find_chance=0;nobody.open_native_contacts();command(nobody,"recruit");nobody.choose(0)
 check(nobody.recruitment.candidate(nobody).is_empty() and nobody.pending.choices.size()==1,"A community may have nobody seeking a party; failed searches cannot reroll")
 check(restore(nobody)!=null,"An unsuccessful local search saves")
 var refused=party();stop(refused,"umatilla");refused.recruitment.rules.find_chance=1;refused.open_native_contacts();command(refused,"recruit");refused.choose(0);refused.choose(1)
 check(refused.party_health.members.size()==5 and refused.recruitment.record.searches["native:umatilla"].declined and restore(refused)!=null,"Declining is permanent without adding a party member")
 var forged: Dictionary=saved(nobody);forged.pending.recruit_site="native:the_dalles"
 check(Save.new().restore(forged)==null,"A saved recruitment menu cannot move to a remote community")
 var legacy_search=party();stop(legacy_search,"fort_hall")
 legacy_search.recruitment.record.searches["post:fort_hall"]={"day":0,"candidate":{},"declined":false,"hired_id":-1}
 legacy_search.open_native_contacts();command(legacy_search,"recruit")
 check(legacy_search.pending.recruit_site=="post:fort_hall" and legacy_search.pending.choices.size()==1,"A previous post search is retained instead of granting another roll")
 var old_save: Dictionary=saved(party());old_save.rules="d6eb580d64e16e0e50f7d95d2bad71c041a1b6b47f3644b2c4356de446bd368c";old_save.erase("native_contacts")
 var legacy=Save.new().restore(old_save)
 check(legacy!=null and legacy.native_encounters.record.is_empty() and legacy.state.food==old_save.state.food,"Previous saves gain empty contacts without free goods or time changes")
 var view=preload("res://ui/main.tscn").instantiate();root.add_child(view);await process_frame
 view.game=party();stop(view.game,"the_dalles");view.departure_view.hide();view._refresh()
 check(view.place_actions.get_children().any(func(b):return "VISIT WASCO" in b.text),"Local visit action appears below the place picture")
 check(view.landscape.scene_id=="the_dalles","Arrival keeps the original landmark picture")
 var visual_state: Dictionary=saved(view.game)
 view._open_native_contacts()
 check(view.landscape.scene_id=="encounter_the_dalles","Wasco visit selects the approved encounter image")
 command(view.game,"notes");view._refresh()
 check(view.landscape.scene_id=="encounter_the_dalles","Conversation retains the encounter setting")
 command(view.game,"recruit");view._refresh()
 check(view.landscape.scene_id=="encounter_the_dalles","Community recruitment retains the encounter setting")
 var visit_copy=restore(view.game)
 check(visit_copy!=null,"An open encounter recruitment menu still saves")
 if visit_copy!=null:
  view.game=visit_copy;view._refresh()
  check(view.landscape.scene_id=="encounter_the_dalles","Restored recruitment reselects its encounter picture")
 view.game.choose(view.game.pending.choices.size()-1);view.service_window.hide();view._refresh()
 check(view.landscape.scene_id=="the_dalles" and view.game.state==Save.new().normalize(visual_state.state),"Closing the visit restores the landmark without changing the simulation")
 stop(view.game,"platte");view._open_native_contacts()
 check(view.landscape.scene_id=="platte","A visit without approved dedicated art retains its landmark")
 view.queue_free();await process_frame
 print("Native encounters: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
