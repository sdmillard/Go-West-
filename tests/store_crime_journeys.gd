extends "res://tests/full_trail_balance.gd"
## Actual arrival at the new venue, one chosen offense, then normal full-road policy.
func _initialize():call_deferred("run")
func crime_choice(game,command: String) -> bool:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("crime_command","")==command and game.can_choose(index):return game.choose(index)
	return false
func run():
	adaptive=true
	hunting_study=true
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	var policy: Dictionary={"id":"store","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true}
	for action in ["none","theft","robbery","shoot"]:
		for seed_value in range(6):
			var game=Simulation.new(seed_value,"classic",true)
			var cart: Dictionary={}
			for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
			game.depart("banker",["A","B","C","D","E"],[3,5,8][seed_value%3],cart)
			var aim:=RandomNumberGenerator.new()
			aim.seed=seed_value ^ 0x41494d
			var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
			var attempted:=false
			var outcome: String="limit"
			for step in range(2400):
				if game.state.status!="traveling":
					outcome=game.state.status
					break
				if game.state.day>=365:break
				var okay:=true
				if game.pending.get("crime_menu",false):
					var stage: String=game.crime.incident().get("stage","")
					okay=crime_choice(game,"take") if stage=="loot" else crime_choice(game,"flee" if stage=="escape" else "finish")
					if not okay and stage=="loot":okay=crime_choice(game,"flee")
				elif action!="none" and not attempted and game.pending.get("landmark","")=="fort_bridger":
					attempted=true
					okay=game.open_crime() and crime_choice(game,action)
				else:okay=act(game,policy,aim,count)
				if not okay:
					outcome="policy_blocked"
					errors.append({"seed":seed_value,"action":action,"error":"blocked policy"})
					break
				if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health():errors.append({"seed":seed_value,"action":action,"error":"state invariant"})
				if step%50==0 or game.pending.get("crime_menu",false):
					var snapshot: Dictionary=store.capture(game)
					if not snapshot.is_empty() and store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null:errors.append({"seed":seed_value,"action":action,"error":"save round trip"})
			if outcome=="limit":errors.append({"seed":seed_value,"action":action,"error":"journey limit"})
			if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"seed":seed_value,"action":action,"error":"final save"})
			rows.append({"seed":seed_value,"action":action,"attempted":attempted,"outcome":outcome,"days":game.state.day,"survivors":game.state.party_size,"cash":game.state.money,"incidents":game.crime.record.incidents,"deaths":game.party_health.members.filter(func(member):return not member.alive).size(),"departures":game.party_health.members.filter(func(member):return member.get("departed",false)).size()})
	var file=FileAccess.open("res://docs/first-store-journeys.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":rows,"errors":errors,"policy":"24 actual full-route journeys: 4 actions x6seeds; banker suggested outfit, March/May/August, existing cautious salted-hunt65% aim policy. At Fort Bridger attempt chosen action once, take reachable loot and try to escape, then resume normal survival decisions. Natural disease/weather and actual time, ammunition, injuries, death, stock and companion reactions apply. This integration sample is not the final survival balance campaign."},"\t"))
	file.close()
	print("Store journeys: %d runs, %d errors" % [rows.size(),errors.size()])
	quit(0 if rows.size()==24 and errors.is_empty() else 1)
