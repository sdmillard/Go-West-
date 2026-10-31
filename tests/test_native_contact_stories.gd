extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Story=preload("res://simulation/native_contact_story.gd")
var checks:=0;var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func _initialize():call_deferred("run")
func party():
 var g=Sim.new(57,"classic",true)
 check(g.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,{"oxen":6,"food":500,"clothing":5,"bullet_boxes":2}),"Contact fixture departs")
 g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 return g
func stop(g,id: String):
 g.route_path=g.route.main_path_to(id)
 g.state.landmark=id;g.state.next_landmark=id;g.state.leg_miles=0;g.state.leg_length=0;g.state.miles=int(g.route.node_miles()[id]);g._arrive_landmark(true,false)
func command(g,cmd: String,id: String="") -> bool:
 for i in range(g.pending.get("choices",[]).size()):
  var c: Dictionary=g.pending.choices[i]
  if c.get("native_command","")==cmd and (id.is_empty() or c.get("native_offer","")==id):return g.choose(i)
 return false
func visit(g,site: String):stop(g,site);g.open_native_contacts();command(g,"contact")
func snapshot(g):return Save.new().capture(g)
func restored(g):return Save.new().restore(JSON.parse_string(JSON.stringify(snapshot(g))))
func run():
 var g=party();visit(g,"fort_hall")
 var state: Dictionary=g.state.duplicate(true);var stream: int=g.rng.state
 check(command(g,"story","ask") and g.state==state and g.rng.state==stream,"Hearing a contact's terms costs no time, money or RNG")
 check(restored(g)!=null,"An open contact offer saves")
 var offer: Dictionary=g.native_encounters.offer_at("fort_hall","provisions")
 var price: int=g.native_encounters.price(g,offer)
 var cash: float=g.state.money;var food: int=g.state.food;var day: int=g.state.day
 var wages: int=Story.wages(g,Story.action(g.native_encounters,"fort_hall","work"))
 check(command(g,"story","work") and g.state.day==day+1 and is_equal_approx(g.state.money,cash+wages/100.0),"Agreed work pays its quoted wage and advances one day")
 check(g.state.food==food-15 and g.income.workers.is_empty() and g.income.worker==-1,"Work consumes normal party meals and releases the worker")
 check(Story.state(g.native_encounters,"fort_hall").work_day==g.state.day,"Contact records the work day")
 check(g.native_encounters.price(g,offer)<price and Story.standing(g.native_encounters,"platte")==0,"Better terms apply only to this household")
 check(command(g,"story","settle") and not command(g,"story","work"),"Completed agreement cannot produce another paid day")
 check(restored(g)!=null,"Completed contact history survives saving")
 command(g,"back");stop(g,"snake_river");stop(g,"fort_hall");g.open_native_contacts();command(g,"contact")
 check(Story.state(g.native_encounters,"fort_hall").step=="complete" and g.pending.text.contains("recognizes"),"A return visit remembers the same contact")
 var corrupt: Dictionary=snapshot(g);corrupt.native_contacts.fort_hall.story.step="invented"
 check(Save.new().restore(corrupt)==null,"Unknown saved contact stage is rejected")
 corrupt=snapshot(g);corrupt.native_contacts.fort_hall.story.work_day=g.state.day+1
 check(Save.new().restore(corrupt)==null,"Future work completion is rejected")
 corrupt=snapshot(g);corrupt.pending.choices[0].effects={"money":999}
 check(Save.new().restore(corrupt)==null,"Serialized contact menu cannot carry forged rewards")
 var barter=party();visit(barter,"fort_hall");command(barter,"story","ask")
 food=barter.state.food;day=barter.state.day;cash=barter.state.money
 check(command(barter,"story","barter") and barter.state.clothing==4 and barter.state.food==food+40 and barter.state.day==day and barter.state.money==cash,"Barter exchanges one real clothing set for the stated food without an extra day")
 check(barter.native_encounters.contact("fort_hall").purchases.provisions==1 and restored(barter)!=null,"Barter draws from the same saved household stock")
 check(not command(barter,"story","barter"),"Barter cannot be repeated")
 var empty=party();visit(empty,"fort_hall");command(empty,"story","ask");empty.state.clothing=0
 var unchanged: Dictionary=snapshot(empty)
 check(not command(empty,"story","barter") and snapshot(empty)==unchanged,"Missing barter goods reject without changing contact standing")
 var exhausted=party();visit(exhausted,"fort_hall");command(exhausted,"overview");command(exhausted,"trade","provisions");command(exhausted,"trade","provisions");command(exhausted,"contact");command(exhausted,"story","ask")
 check(not command(exhausted,"story","barter"),"Barter cannot create provisions after the shared stock is sold")
 var sick=party();visit(sick,"fort_hall");command(sick,"story","ask");sick.party_health.members[0].health=39
 unchanged=snapshot(sick)
 check(not command(sick,"story","work") and snapshot(sick)==unchanged,"A poor-health worker cannot accept local labor")
 sick.party_health.members[0].health=60
 check(command(sick,"story","work"),"A fit fair-health traveler can do the work")
 var nursed=party();nursed.party_health.members[0].health=50;nursed.state.medicine=3;nursed.characters.profiles[1].trust=80
 check(nursed.camp_tasks.assign(nursed,1,"nurse",0),"Leader nursing fixture is assigned")
 visit(nursed,"fort_hall");command(nursed,"story","ask")
 check(not command(nursed,"story","work"),"A nursed leader remains locked to rest")
 var declined=party();visit(declined,"fort_hall");command(declined,"story","ask");day=declined.state.day
 check(command(declined,"story","decline") and declined.state.day==day and Story.standing(declined.native_encounters,"fort_hall")==0,"Declining an ordinary job is free and does not cause hostility")
 command(declined,"overview");check(command(declined,"trade","provisions"),"Normal trade remains available after declining work")
 var pilot=party();visit(pilot,"deschutes");command(pilot,"story","listen")
 check(command(pilot,"story","refuse") and pilot.native_encounters.guidance_factor(pilot)==1,"The dispute affects this pilot's willingness to help")
 command(pilot,"overview")
 check(not command(pilot,"guidance"),"The refusing pilot does not sell ordinary assistance")
 command(pilot,"back")
 check(pilot.pending.get("landmark","")=="deschutes" and pilot.pending.choices.any(func(c):return c.has("method")),"Ordinary river choices remain available after the local dispute")
 pilot.open_native_contacts();command(pilot,"contact");day=pilot.state.day;cash=pilot.state.money
 check(command(pilot,"story","apologize") and pilot.state.day==day+1 and pilot.state.money==cash,"Reconciliation requires real unpaid work and time")
 day=pilot.state.day;cash=pilot.state.money
 check(command(pilot,"story","contract") and pilot.state.day==day+1 and pilot.state.money==cash-2,"The short guide agreement charges its displayed fee and arrangement day")
 check(pilot.native_encounters.guidance_factor(pilot)<1 and restored(pilot)!=null,"Booked guide assistance is active and saves")
 check(not command(pilot,"story","renew"),"An active agreement cannot be charged twice")
 command(pilot,"back");pilot._tick_day(true)
 check(pilot.native_encounters.guidance_factor(pilot)<1,"Unlike the day booking, the short agreement survives an overnight delay")
 pilot._tick_day(true);check(pilot.native_encounters.guidance_factor(pilot)<1,"Third booked day remains covered")
 pilot._tick_day(true);check(pilot.native_encounters.guidance_factor(pilot)==1,"Coverage expires after the third booked day")
 pilot.open_native_contacts();command(pilot,"contact");cash=pilot.state.money
 check(command(pilot,"story","renew") and pilot.state.money==cash-2,"An expired agreement can be renewed only with another fee and day")
 command(pilot,"back");check(pilot.turn_direction("east"),"Guide fixture turns east")
 check(Story.state(pilot.native_encounters,"deschutes").agreement_closed and pilot.native_encounters.guidance_factor(pilot)==1,"An eastward turn permanently closes the westbound agreement")
 pilot.turn_direction("west");check(pilot.native_encounters.guidance_factor(pilot)==1,"Turning west again cannot revive the closed agreement")
 var arrived=party();visit(arrived,"deschutes");command(arrived,"story","listen");cash=arrived.state.money;day=arrived.state.day
 check(command(arrived,"story","pay") and arrived.state.money==cash-1 and arrived.state.day==day,"Paying helpers is the disclosed alternative to a labor day")
 command(arrived,"story","contract");command(arrived,"back");stop(arrived,"the_dalles")
 check(Story.state(arrived.native_encounters,"deschutes").agreement_closed and restored(arrived)!=null,"Arrival at The Dalles closes and saves the agreed destination")
 stop(arrived,"deschutes");check(arrived.native_encounters.guidance_factor(arrived)==1,"Returning cannot reactivate an arrived guide agreement")
 var seller=party();visit(seller,"the_dalles");command(seller,"story","ask")
 check(not command(seller,"story","repair"),"Carpentry work requires an actual suitable background")
 seller.state.departure_month=12
 check(not command(seller,"story","pack"),"Seasonal packing work is unavailable in winter")
 seller.state.departure_month=5
 check(command(seller,"story","pack") and command(seller,"story","introduce") and seller.pending.get("recruit_site","")=="native:the_dalles","Work leads to the existing companion opportunity")
 seller.recruitment.rules.find_chance=1
 check(seller.choose(0) and seller.pending.text.contains("provision seller introduced"),"The candidate screen explains the personal introduction")
 var person: Dictionary=seller.recruitment.candidate(seller).duplicate(true)
 check(restored(seller)!=null,"Introduced candidate and contact history save together")
 seller.choose(1);seller.choose(seller.pending.choices.size()-1);seller.open_native_contacts();command(seller,"contact")
 check(Story.state(seller.native_encounters,"the_dalles").step=="introduced" and not command(seller,"story","introduce"),"An introduction cannot reroll a declined companion")
 var convoy=party();stop(convoy,"independence");convoy.context.record.spent["post:independence|visit"]=1
 check(convoy.counter_checkout({"wagon":1}) and convoy.wagon_count()==2,"Guide convoy fixture buys a second wagon")
 visit(convoy,"deschutes");command(convoy,"story","listen");command(convoy,"story","pay");cash=convoy.state.money
 check(command(convoy,"story","contract") and convoy.state.money==cash-4 and Story.state(convoy.native_encounters,"deschutes").agreement_loads==2,"Short guide fee and booking cover both actual wagonloads")
 check(restored(convoy)!=null,"A multi-wagon guide agreement saves")
 var successor=party();successor.party_health.kill(successor.party_health.members[0],0,"test accident");successor.state.party_size=4;successor.state.health=successor.party_health.average_health()
 visit(successor,"the_dalles");command(successor,"story","ask");successor.characters.profiles[1].skill="Carpentry"
 check(command(successor,"story","repair") and Story.state(successor.native_encounters,"the_dalles").work_day==successor.state.day,"The current successor leader can use their actual Carpentry background")
 var old: Dictionary=snapshot(party());old.rules="aae71de2f7668723072bcfe7aa737bc6e8397e84f2298a6a222f7a02164c4ffb"
 var migrated=Save.new().restore(old)
 check(migrated!=null and migrated.native_encounters.record.is_empty(),"Previous Native-encounter saves migrate without invented dealings")
 var rules: Dictionary=g.native_encounters.data.duplicate(true)
 rules.sites.fort_hall.contact.stages.offer.choices[0].effects={"money":999}
 check(not preload("res://simulation/native_encounters.gd").new().load_data(rules),"Authored contact actions cannot supply arbitrary effects")
 print("Local contact stories: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
