extends "res://tests/full_trail_balance.gd"
## Small integration sample of generated personalities, not an economy balance cohort.
func _initialize():call_deferred("run")
func run():
	adaptive=true
	hunting_study=true
	var rows: Array=[]
	var errors: Array=[]
	var policy: Dictionary={"id":"generated","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true}
	var store=Store.new()
	for seed_value in range(12):
		var game=Simulation.new(seed_value,"classic",true)
		var characters=preload("res://simulation/party_character.gd").new()
		characters.start(seed_value,5)
		var names: Array=["LEADER"]
		var terms: Dictionary={}
		for index in range(1,5):
			var offer: Dictionary=characters.generate_candidate(seed_value,index,"random")
			offer.profile.id=index
			characters.profiles[index]=offer.profile
			names.append(offer.name.get_slice(" ",0))
			if not offer.terms.is_empty():terms[str(index)]=offer.terms
		var initial: Array=characters.profiles.duplicate(true)
		var cart: Dictionary={}
		for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
		if not game.depart("banker",names,[3,5,8][seed_value%3],cart,{"profiles":initial,"contracts":terms}):
			errors.append({"seed":seed_value,"error":game.departure_error})
			continue
		var aim:=RandomNumberGenerator.new()
		aim.seed=seed_value ^ 0x41494d
		var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
		var outcome: String="limit"
		for step in range(2400):
			if game.state.status!="traveling":
				outcome=game.state.status
				break
			if game.state.day>=365:break
			for person in game.characters.profiles.slice(1):
				if not game.party_health.is_active(game.party_health.members[person.id]) or person.contract.is_empty():continue
				var due: int=person.contract.arrears_cents
				if due>0 and game.state.money>=due/100.0+10:game.characters.pay_wages(game,person.id)
			if not act(game,policy,aim,count):
				outcome="policy_blocked"
				break
			if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health():
				errors.append({"seed":seed_value,"day":game.state.day,"error":"state invariant"})
				break
			if step%50==0:
				var snapshot: Dictionary=store.capture(game)
				if not snapshot.is_empty() and store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null:
					errors.append({"seed":seed_value,"day":game.state.day,"error":"save round trip"})
					break
		var snapshot: Dictionary=store.capture(game)
		if snapshot.is_empty() or store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null:errors.append({"seed":seed_value,"error":"final save"})
		rows.append({"seed":seed_value,"month":[3,5,8][seed_value%3],"outcome":outcome,"days":game.state.day,"survivors":game.state.party_size,"departures":game.party_health.members.filter(func(member):return member.get("departed",false)).size(),"initial_profiles":initial,"final_profiles":game.characters.profiles,"cash":game.state.money})
	var file=FileAccess.open("res://docs/generated-party-journeys.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"policy":"Twelve seeded generated parties; banker, suggested outfit, three departure months, existing cautious salted-hunt policy with65% center aim. Full wages paid if $10 cash remains. Real traits, flaws, disease, rest, health, helpers and warned departures; saves checked every50actions and at finish. This is an integration smoke sample, not a tuned balance study or historical mortality model.","runs":rows,"errors":errors},"\t"))
	file.close()
	print("Generated parties: %d journeys; %d arrived; %d errors" % [rows.size(),rows.filter(func(row):return row.outcome=="arrived").size(),errors.size()])
	quit(0 if rows.size()==12 and errors.is_empty() else 1)
