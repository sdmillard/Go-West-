extends "res://tests/full_trail_balance.gd"
## Development-only sensitivity; per-instance overrides never edit the live JSON rules.
func run():
	adaptive=true
	hunting_study=true
	var path: String="res://docs/food-decisions-01.json"
	if FileAccess.file_exists(path):printerr("Archive already exists");quit(1);return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	for value in [0.35,0.5,0.65]:
		for threshold in [45,90,150]:
			for month in [4,5]:
				for seed_value in range(100,110):
					var game=Simulation.new(seed_value,"classic",true)
					game.provisions.data.meat_food_per_lb=value
					var cart: Dictionary={}
					for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
					if not game.depart("farmer",["A","B","C","D","E"],month,cart):errors.append(game.departure_error);continue
					var policy: Dictionary={"id":"food_study","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":threshold,"adaptive_rations":true,"preserve":"salt","slaughter":true,"rest_below":55}
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
					rows.append({"food_per_meat_lb":value,"hunt_below":threshold,"month":month,"seed":seed_value,"outcome":outcome,"days":game.state.day,"survivors":game.state.party_size,"counts":count})
					await process_frame
			print("Food value %.2f threshold%d: %d runs, %d errors" % [value,threshold,rows.size(),errors.size()])
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":rows,"errors":errors,"note":"Development-only per-instance meat value overrides .35/.5/.65; no JSON rules edited. Farmer suggested six-ox cart; April/May; seeds100..109. Salted preservation with dry fallback, spare ox slaughter allowed, rest below55, 65% scripted aim. Compare food reserve targets45/90/150. Save validation only, not replay parity for overridden rules."},"\t"));file.close()
	quit(0 if errors.is_empty() and rows.size()==180 else 1)
