extends "res://tests/outlaw_journeys.gd"
## Explicit perturbed starting states; actual actions thereafter. Not ordinary win-rate evidence.
const CASES=["reference","four_ox","zero_ammo","zero_ox_walk","foot","broken_leg","low_health","closed_store","refusers","all_depart","spoiled_human","fort_robbery"]
func trim_packs(game) -> bool:
	if game.pending.get("id","")=="packs_too_heavy":return game.choose(0)
	if not game.pending.is_empty():return false
	if game.state.vehicle!="foot" or game.provisions.cargo(game.state)<=game.provisions.capacity(game.state):return false
	for key in ["wheels","axles","tongues","salt","bullets","clothing","medicine","food"]:
		if game.state[key]>0:
			var excess: float=game.provisions.cargo(game.state)-game.provisions.capacity(game.state)
			return game.discard_supply(key,mini(int(game.state[key]),maxi(1,ceili(excess/float(game.provisions.data.weights_lb[key])))))
	return game.rest()
func walk_out(game) -> bool:
	var pack: Dictionary={"clothing":mini(3,int(game.state.clothing)),"bullets":mini(10,int(game.state.bullets)),"medicine":mini(1,int(game.state.medicine)),"salt":mini(1,int(game.state.salt))}
	var quote: Dictionary=game.pack_quote(pack)
	if not quote.has("capacity_lb"):return false
	pack.food=mini(int(game.state.food),maxi(0,floori(float(quote.capacity_lb)-float(quote.cargo_lb))-5))
	return game.abandon_wagon(pack)
func run():
	adaptive=true
	hunting_study=true
	var path: String="res://docs/emergency-journeys-02.json"
	if FileAccess.file_exists(path):printerr("Archive already exists");quit(1);return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	for scenario in CASES:
		for profession in ["farmer","carpenter","banker"]:
			for seed_value in range(110,114):
				var game=Simulation.new(seed_value,"classic",true)
				var cart: Dictionary={}
				for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
				if scenario=="four_ox":cart.oxen=4
				if not game.depart(profession,["A","B","C","D","E"],5,cart):errors.append(game.departure_error);continue
				if scenario=="zero_ammo":game.state.bullets=0
				if scenario=="zero_ox_walk":game.state.oxen=0
				if scenario=="low_health":
					for member in game.party_health.members:member.health=35
				if scenario=="broken_leg":game.party_health.begin_condition(1,"broken_leg",0)
				if scenario=="all_depart":
					for person in game.characters.profiles.slice(1):person.trust=0;game.characters.review_exit(game,person)
				game.state.health=game.party_health.average_health()
				var prepared:=true
				if scenario in ["foot","zero_ox_walk"]:prepared=walk_out(game)
				if scenario in ["refusers","spoiled_human"]:
					for person in game.characters.profiles.slice(1):person.boundaries=game.characters.catalog.boundaries("Compassionate");person.trust=50
					game.party_health.kill(game.party_health.members[4],0,"cholera")
					game._collect_health_events();game.state.party_size=game.party_health.living_count();game.state.health=game.party_health.average_health()
					prepared=game.open_remains() and pick(game,"remains_command","butcher_open")
					if scenario=="refusers" and game.pending.get("remains_menu",false):pick(game,"remains_command","eat",0)
					if game.pending.get("remains_menu",false):pick(game,"remains_command","back")
				if not prepared:errors.append({"scenario":scenario,"seed":seed_value,"error":"preparation failed"})
				var policy: Dictionary={"id":scenario,"pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true,"rest_below":55}
				var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
				var aim:=RandomNumberGenerator.new();aim.seed=seed_value ^ 0x41494d
				var attempted:=false
				var outcome: String="action_limit"
				var idle:=0
				for step in range(2400):
					if game.state.status!="traveling":outcome=game.state.status;break
					if game.state.day>=365:outcome="year_limit";break
					var day: int=game.state.day
					var mile: int=game.state.miles
					var okay:=true
					if game.pending.get("crime_menu",false):okay=settle_crime(game)
					elif trim_packs(game):pass
					elif scenario in ["closed_store","fort_robbery"] and not attempted and game.pending.get("landmark","")==("fort_bridger" if scenario=="closed_store" else "fort_kearny") and game.crime.eligible(game):
						attempted=true;okay=game.open_crime() and pick(game,"crime_command","shoot" if scenario=="closed_store" else "robbery")
					else:okay=act(game,policy,aim,count)
					if not okay:outcome="policy_blocked";errors.append({"scenario":scenario,"seed":seed_value,"error":outcome});break
					idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
					if idle>32:outcome="policy_stalled";errors.append({"scenario":scenario,"seed":seed_value,"error":outcome});break
					if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
					if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health() or int(game.state.get("remains_lb",0))!=Remains.weight(game):errors.append({"scenario":scenario,"seed":seed_value,"error":"state invariant"});break
					if step%80==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"scenario":scenario,"seed":seed_value,"error":store.error});break
				if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"scenario":scenario,"seed":seed_value,"error":"final save: "+store.error})
				rows.append({"scenario":scenario,"profession":profession,"seed":seed_value,"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"deaths":game.party_health.members.filter(func(member):return not member.alive).size(),"departures":game.party_health.members.filter(func(member):return member.get("departed",false)).size(),"vehicle":game.state.vehicle,"counts":count,"crime_attempted":attempted,"human_food_left":Remains.human_pounds(game)})
				await process_frame
		print("Emergency %s: %d journeys, %d errors" % [scenario,rows.size(),errors.size()])
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":rows,"errors":errors,"note":"144 development stress journeys:12 explicit fixture scenarios x3capitals x4seeds110..113, May. Perturbed starting supplies/health/trust/death are fixture assumptions, never ordinary probability evidence. Thereafter public actions only, including packing/walking, drops, crime and processing remains. Closed-store/fort incidents attempted only after actual arrival; report whether reached. Spoiled human meat is left unserved; refusers never receive it automatically. Same cautious salted-hunt policy, rest55. Final and every80-action save validation."},"\t"));file.close()
	quit(0 if errors.is_empty() and rows.size()==144 else 1)
