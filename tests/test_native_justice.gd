extends SceneTree
## Native households as crime targets: their own people and stock, refusals, kin pursuit and the household's council.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Wanted=preload("res://simulation/wanted_system.gd")
const SITES=["platte","fort_hall","grande_ronde","umatilla","deschutes","the_dalles","columbia_raft"]
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):
		profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
		profile.trust=80
	return game
func at(game,place: String):
	game.state.next_landmark=place
	game._arrive_landmark()
	game.state.miles=int(game.route.node_miles()[place])
	return game
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func offers(game,command: String) -> bool:
	return game.pending.get("choices",[]).any(func(choice):return choice.get("crime_command","")==command)
func roundtrip(game,label: String) -> void:
	var store=Store.new()
	var snapshot: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null,label+" restores")
	if copy!=null:check(store.capture(copy)==snapshot,label+" restores exactly")
## The household at a visit, with its odds set for a deterministic test.
func visit(site: String,odds: Dictionary={}):
	var game=at(outfit(),site)
	for key in odds:game.crime.scenes["native:"+site][key]=odds[key]
	return game
func wait_hearing(game) -> void:
	for step in range(3):
		if game.crime.incident().get("stage","")=="custody":pick(game,"wait")
func run() -> void:
	# Every visit has its own household, met only there.
	var game=outfit()
	check(game.crime.local_places(game,game.pending).all(func(place):return not place.begins_with("native:")),"No household is met away from its visit")
	for site in SITES:
		game=at(outfit(),site)
		var place: String="native:"+site
		check(place in game.crime.local_places(game,game.pending),"The %s household can be targeted at its visit" % site)
		var keeper: Array=game.crime.local_targets(game).filter(func(person):return person.uid==game.crime.owner_id(place))
		check(keeper.size()==1 and keeper[0].name==game.native_encounters.data.sites[site].contact.label,"The %s contact keeps their own identity as a target" % site)
		check(game.crime.stocked(game,place)==(site not in ["deschutes","columbia_raft"]),"Only households with provisions or horses can be robbed (%s)" % site)
	check(game.crime.food_left(game,"native:umatilla")==80 and game.crime.food_left(game,"native:grande_ronde")==0,"A household holds exactly its visit's preserved provisions")
	check(game.RobberyDemand.stock(at(outfit(),"grande_ronde"),"native:grande_ronde").get("horses",0)==int(game.context.data.horse_traders.grande_ronde.horses),"The Nez Perce household's horses are the herd sold there")
	game=at(outfit(),"deschutes")
	check(game.open_crime("native:deschutes") and not offers(game,"theft") and not offers(game,"robbery") and offers(game,"shoot") and offers(game,"assault"),"The river pilot can only be attacked; there is nothing to take")
	# A quiet theft takes real stock, which the household can no longer sell; nobody knows who took it.
	game=visit("platte",{"theft_success":1.0})
	check(game.open_crime("native:platte"),"The Pawnee household opens from VILLAINY")
	check(game.steal({"food":50}),"A theft of 50 lb of provisions starts")
	pick(game,"take")
	pick(game,"finish")
	check(game.crime.food_left(game,"native:platte")==30,"Stolen provisions leave the household's stores")
	var parcel: Dictionary=game.native_encounters.offer_at("platte","provisions")
	check(not game.native_encounters.available(game,"platte",parcel),"Too little is left to sell a 40-unit parcel")
	check(game.native_encounters.refusal(game,"platte").is_empty(),"An unseen theft does not tell the household who did it")
	roundtrip(game,"An unseen household theft")
	# Food sold first is no longer there to steal.
	game=at(outfit(),"umatilla")
	game.native_encounters.record["umatilla"]={"heard":false,"first_trade_day":int(game.state.day),"purchases":{"provisions":1},"guide_day":-1,"guide_loads":0}
	check(game.crime.food_left(game,"native:umatilla")==40,"Provisions sold are no longer in the household's stores")
	# A noticed theft: the household turns the party away from everything it offers.
	game=visit("platte",{"theft_success":0.0,"escape_capture":0.0,"escape_injury":0.0})
	game.open_crime("native:platte")
	game.steal({"food":20})
	pick(game,"flee")
	pick(game,"finish")
	check(not game.native_encounters.refusal(game,"platte").is_empty(),"A household that saw the theft refuses the party")
	game.pending=game.service_return.duplicate(true) if not game.service_return.is_empty() else game.pending
	check(game.open_native_contacts() and game.pending.choices.size()==1 and game.pending.choices[0].native_command=="back","The household's visit offers nothing but the way back")
	game.choose(0)
	check(not game.crime.record.reports.is_empty() and game.crime.record.reports.back().origin=="native:platte","Word of the theft leaves with the household")
	roundtrip(game,"A refused household")
	# A dead pilot guides nobody, and a dead portage organizer's crew carries nothing.
	game=visit("deschutes",{"shot_hit":1.0,"shot_fatal":1.0,"escape_capture":0.0,"escape_injury":0.0})
	game.native_encounters.record["deschutes"]={"heard":false,"first_trade_day":-1,"purchases":{},"guide_day":-1,"guide_loads":0,"story":{"step":"contract","work_day":-1,"agreement_until":int(game.state.day)+2,"agreement_loads":maxi(1,game.wagon_count()),"agreement_closed":false}}
	game.state.travel_direction="west"
	var guided: bool=game.native_encounters.Story.active_guide(game.native_encounters,game)
	game.open_local_attack(game.crime.owner_id("native:deschutes"))
	pick(game,"shoot")
	check(game.crime.owner("native:deschutes").health==0,"The pilot is killed")
	check(guided and not game.native_encounters.Story.active_guide(game.native_encounters,game) and game.native_encounters.guidance_factor(game)==1.0,"A dead pilot's agreement gives no guidance")
	check(game.native_encounters.refusal(game,"deschutes").contains("dead"),"Nobody of a dead pilot's household deals with the party")
	pick(game,"flee")
	pick(game,"finish")
	roundtrip(game,"A killed pilot")
	game=visit("columbia_raft",{"shot_hit":1.0,"shot_fatal":1.0,"escape_capture":0.0,"escape_injury":0.0})
	game.state.travel_direction="west"
	game.open_local_attack(game.crime.owner_id("native:columbia_raft"))
	pick(game,"shoot")
	pick(game,"flee")
	pick(game,"finish")
	game.state.next_landmark="columbia_raft"
	game._arrive_landmark()
	check(not game.pending.get("choices",[]).any(func(choice):return choice.get("native_portage",false)) and not game.native_encounters.can_portage(game),"A dead organizer's crew offers no portage")
	# Caught in a theft: the household's council next day wants the goods' worth twice over.
	game=visit("platte",{"theft_success":0.0,"escape_capture":1.0})
	game.open_crime("native:platte")
	game.steal({"food":20})
	pick(game,"take")
	var money_before: float=game.state.money
	pick(game,"flee")
	var current: Dictionary=game.crime.incident()
	check(current.get("stage","")=="custody" and current.custody.authority=="council" and current.custody.hearing_day==int(current.custody.day)+1,"A household's kin hold the party for their council the next day")
	check(game.pending.text.contains("twice over"),"The council's terms are shown before the hearing")
	roundtrip(game,"Held by a household")
	for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=1.0
	wait_hearing(game)
	current=game.crime.record.incidents.back()
	check(current.get("sentence",{}).get("kind","")=="returned" and current.sentence.authority=="council","A council answers a theft with repayment")
	check(int(current.sentence.cents)==mini(roundi(money_before*100),maxi(Wanted.value_of(game,current)*2,500)),"The repayment is the goods' worth twice over, in cash first")
	check(game.state.status=="traveling","A repaid theft does not end the journey")
	check(game.crime.Wanted.settled(game.crime).has("incident:%d" % current.id),"A returned theft is answered for everyone")
	roundtrip(game,"A council repayment")
	# Caught after an attack: a heavier price, and no household in that country will deal with the party.
	game=visit("umatilla",{"shot_hit":1.0,"shot_fatal":0.0,"escape_capture":1.0})
	for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=1.0
	game.open_local_attack(game.crime.owner_id("native:umatilla"))
	pick(game,"shoot")
	pick(game,"flee")
	wait_hearing(game)
	current=game.crime.record.incidents.back()
	check(current.get("sentence",{}).get("kind","")=="driven_out","A council answers an attack by driving the party out")
	check(game.native_encounters.refusal(game,"the_dalles").contains("drove") and game.native_encounters.refusal(game,"grande_ronde").contains("drove"),"Households in the same country turn the party away")
	check(game.native_encounters.refusal(game,"fort_hall").is_empty(),"Households in another country have not been told")
	check(not game.crime.Wanted.settled(game.crime).has("incident:%d" % current.id) and game.crime.Wanted.settled(game.crime,true).has("incident:%d" % current.id),"Paying a council does not settle an attack with anyone else")
	roundtrip(game,"Driven out by a council")
	# A killing: the family chooses the price or the killer's life.
	for life in [0.0,1.0]:
		game=visit("the_dalles",{"shot_hit":1.0,"shot_fatal":1.0,"escape_capture":1.0})
		for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=1.0
		game.crime.detention_data.council.life_chance=life
		game.crime.detention_data.council.unpaid_life_step=0.0
		game.crime.detention_data.council.surrender_step=0.0
		game.open_local_attack(game.crime.owner_id("native:the_dalles"))
		pick(game,"shoot")
		pick(game,"flee")
		check(game.pending.text.contains("killer's life"),"The family's choice is shown before the hearing")
		wait_hearing(game)
		current=game.crime.record.incidents.back()
		if life==0.0:
			check(current.sentence.kind=="price" and game.state.status=="traveling" and int(current.sentence.cents)+Wanted.value_of(game,{"cash_cents":0,"food":current.sentence.goods.get("food",0)})>0,"A family may accept a heavy price")
			check(not game.native_encounters.refusal(game,"umatilla").is_empty(),"Paying for a killing still drives the party out")
		else:
			check(current.sentence.kind=="life" and game.state.status=="lost" and game.state.loss_reason.contains("life"),"A family may take the killer's life, ending the journey")
		roundtrip(game,"A council killing (%s)" % ("life" if life>0 else "price"))
	# Kin ride after a party that got away, and bring it before the council.
	game=visit("fort_hall",{"compliance":1.0,"escape_capture":0.0,"escape_injury":0.0})
	game.open_crime("native:fort_hall")
	game.crime.choose(game,"robbery")
	pick(game,"take")
	pick(game,"flee")
	pick(game,"finish")
	check(game.crime.pursuer(game)=="native:fort_hall","The household's kin may ride after the party")
	game.crime.scenes["native:fort_hall"].pursuit.daily=1.0
	game.pending={}
	check(game.crime.check_pursuit(game) and game.crime.incident().stage=="standoff" and game.pending.text.contains("Men of the household"),"Kin who catch up force a standoff")
	roundtrip(game,"Kin pursuit")
	pick(game,"surrender")
	check(game.crime.incident().get("custody",{}).get("authority","")=="council","Surrendering to kin brings the council")
	for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=1.0
	wait_hearing(game)
	current=game.crime.record.incidents.back()
	check(current.sentence.kind=="driven_out" and current.sentence.charges==["incident:%d" % (current.id-1)],"The council hears the robbery it rode after")
	roundtrip(game,"After the council")
	# The household's people and stock are real and persistent; a council never hears another's case.
	game=visit("the_dalles",{"theft_success":0.0,"escape_capture":0.0,"escape_injury":0.0})
	game.open_crime("native:the_dalles")
	game.steal({"food":10})
	pick(game,"flee")
	pick(game,"finish")
	var copy=Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
	check(copy!=null and copy.crime.service("native:the_dalles").alarmed and not copy.native_encounters.refusal(copy,"the_dalles").is_empty(),"What a household saw survives a save")
	var store=Store.new()
	var bad: Dictionary=store.capture(game)
	bad.crime.record.services["native:the_dalles"].alarmed=false
	check(store.restore(bad)==null,"A save cannot make a household forget what it saw")
	bad=store.capture(game)
	bad.crime.record.services["native:the_dalles"].cash_cents=500
	check(store.restore(bad)==null,"A save cannot give a household a cash box")
	print("Native justice: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
