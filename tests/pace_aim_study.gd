extends "res://tests/full_trail_balance.gd"
## Development sensitivity only; unchanged live game rules and actual mouse-hunt simulation.
func run():
	adaptive=true
	hunting_study=true
	var path: String="res://docs/pace-aim-study-01.json"
	if FileAccess.file_exists(path):printerr("Archive already exists");quit(1);return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	var variants: Array=[]
	for team in [4,6]:
		for pace in [0,1]:
			for accuracy in [0.35,0.65,0.9]:
				for profession in ["farmer","carpenter","banker"]:variants.append({"team":team,"pace":pace,"accuracy":accuracy,"profession":profession})
	for variant in variants:
		for seed_value in range(110,114):
			var game=Simulation.new(seed_value,"classic",true)
			var cart: Dictionary={}
			for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
			cart.oxen=variant.team
			if not game.depart(variant.profession,["A","B","C","D","E"],5,cart):errors.append(game.departure_error);continue
			var policy: Dictionary={"id":"food_study","pace":variant.pace,"rations":1,"rest":true,"hunt":true,"accuracy":variant.accuracy,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true,"rest_below":55}
			var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
			var aim:=RandomNumberGenerator.new()
			aim.seed=seed_value ^ 0x41494d
			var outcome: String="action_limit"
			var idle:=0
			for step in range(2400):
				if game.state.status!="traveling":outcome=game.state.status;break
				if game.state.day>=365:outcome="year_limit";break
				var day: int=game.state.day
				var mile: int=game.state.miles
				if not act(game,policy,aim,count):outcome="policy_blocked";errors.append(outcome);break
				idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
				if idle>32:errors.append("policy_stalled");break
				if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
				if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count():errors.append("invariant");break
			if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append(store.error)
			rows.append({"profession":variant.profession,"team":variant.team,"pace":variant.pace,"accuracy":variant.accuracy,"seed":seed_value,"outcome":outcome,"days":game.state.day,"survivors":game.state.party_size,"counts":count})
			await process_frame
		print("Team%d pace%d aim%.2f %s: %d runs, %d errors" % [variant.team,variant.pace,variant.accuracy,variant.profession,rows.size(),errors.size()])
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":rows,"errors":errors,"note":"144 development journeys, May ordinary seeded volunteers, three capitals, four/six oxen, cautious/steady, 35/65/90percent scripted aiming, seeds110..113. Current live food value and health hauling. Rest55, mixed rations, salted preservation with dry fallback and spare-ox slaughter. Script observes animal positions, cannot measure real player's aiming skill. Final saves validated."},"\t"));file.close()
	quit(0 if errors.is_empty() and rows.size()==144 else 1)
