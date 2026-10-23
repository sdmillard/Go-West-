extends "res://tests/full_trail_balance.gd"
## Historical diagnostic through existing public actions. No rule overrides or tuning.
const RemainsAudit=preload("res://simulation/remains.gd")
func point(game) -> Dictionary:
	return {"day":game.state.day,"miles":game.state.miles,"calendar":game.calendar(),"food":game.state.food,"cash":game.state.money,"bullets":game.state.bullets,"salt":game.state.salt,"oxen":game.state.oxen,"ox_health":game.state.ox_health,"fatigue":game.state.fatigue,"cargo":game.provisions.cargo(game.state),"party":game.state.party_size}
func run() -> void:
	adaptive=true
	hunting_study=true
	var seed_count:=2
	var label: String="historical-diagnostic-01"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):seed_count=clampi(int(argument.trim_prefix("--seeds=")),1,20)
		if argument.begins_with("--label="):label=argument.trim_prefix("--label=").validate_filename()
	var path: String="res://docs/"+label+".json"
	if FileAccess.file_exists(path):
		printerr("Refusing to overwrite an archived diagnostic; choose a new --label.")
		quit(1)
		return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	for profession in ["farmer","carpenter","banker"]:
		for month in [4,5]:
			for team in [4,6,8]:
				for method in ["no_hunt","dry","salt"]:
					for seed_value in range(seed_count):
						var game=Simulation.new(seed_value,"classic",true)
						var cart: Dictionary={}
						for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
						cart.oxen=team
						var name: String="%s month%d ox%d %s seed%d" % [profession,month,team,method,seed_value]
						if not game.depart(profession,["A","B","C","D","E"],month,cart):
							errors.append({"run":name,"error":game.departure_error})
							continue
						var policy: Dictionary={"id":method,"pace":0,"rations":1,"rest":true,"hunt":method!="no_hunt","accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"" if method=="no_hunt" else method,"slaughter":false}
						var aim:=RandomNumberGenerator.new()
						aim.seed=seed_value ^ 0x41494d
						var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
						var trace: Array=[point(game)]
						var stops: Dictionary={}
						var outcome: String="action_limit"
						var next_sample:=15
						var idle_steps:=0
						var day_costs: Dictionary={}
						var processing: Array=[]
						for step in range(2400):
							if game.pending.has("landmark") and not stops.has(game.state.landmark):stops[game.state.landmark]=point(game)
							if game.state.status!="traveling":
								outcome=game.state.status
								break
							if game.state.day>=365:
								outcome="out_of_time"
								break
							var day: int=game.state.day
							var miles: int=game.state.miles
							var before_count: Dictionary=count.duplicate()
							var was_event: bool=not game.pending.is_empty() and not game.pending.has("landmark")
							var history_size: int=game.supply_history.size()
							if not act(game,policy,aim,count):
								outcome="policy_blocked"
								errors.append({"run":name,"error":outcome,"pending":game.pending.get("id","")})
								break
							var category: String="encounter" if was_event else "crossing_or_stop"
							for key in ["activities","trade_waits","care","trades","rests","hunts","preservations"]:
								if int(count.get(key,0))>int(before_count.get(key,0)):category=key
							if game.state.miles>miles:category="travel"
							day_costs[category]=int(day_costs.get(category,0))+int(game.state.day)-day
							for entry in game.supply_history.slice(history_size):
								if entry.event=="preservation":processing.append({"day":entry.day,"processed":entry.processed,"retained":entry.retained})
							idle_steps=idle_steps+1 if game.state.day==day and game.state.miles==miles else 0
							if idle_steps>32:
								errors.append({"run":name,"error":"policy did not advance time or distance for 33 actions"})
								outcome="policy_stalled"
								break
							if game.state.miles>miles:count.travel_days+=1
							if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
							if game.state.day>=next_sample:
								trace.append(point(game))
								next_sample=int(game.state.day)+15
							if game.state.food<0 or game.state.money<0 or game.state.salt<0 or game.state.party_size!=game.party_health.living_count() or int(game.state.get("remains_lb",0))!=RemainsAudit.weight(game) or game.provisions.fresh_pounds(game.state.food)+game.provisions.preserved_pounds(game.state.food)>game.state.food or not game.error.is_empty():
								errors.append({"run":name,"error":"state invariant","day":game.state.day})
								outcome="invariant_failed"
								break
							if step%80==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:
								errors.append({"run":name,"error":"save round trip","detail":store.error})
								outcome="save_failed"
								break
						if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":name,"error":"final save","detail":store.error})
						var deaths: Array=[]
						var departures:=0
						for member in game.party_health.members:
							if not member.alive:deaths.append({"name":member.name,"cause":member.cause,"day":member.death_day})
							if member.get("departed",false):departures+=1
						var spoiled:=0
						for entry in game.supply_history:
							if entry.event=="spoilage":spoiled-=int(entry.changes.food)
						var row: Dictionary={"profession":profession,"month":month,"starting_oxen":team,"method":method,"seed":seed_value,"outcome":outcome,"final":point(game),"deaths":deaths,"departures":departures,"spoiled":spoiled,"landmarks":stops,"trace":trace,"counts":count,"days_by_action":day_costs,"processing":processing,"recent_journal":game.journal.slice(maxi(0,game.journal.size()-6))}
						rows.append(row)
						print("%s: %s day%d, %d survivors" % [name,outcome,game.state.day,game.state.party_size])
					await process_frame
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		printerr("Could not write diagnostic")
		quit(1)
		return
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"seed_count":seed_count,"runs":rows,"errors":errors,"policy":"Current suggested cargo; 4/6/8 purchased oxen; April/May 1 departures; three capitals; default seed-matched unpaid companions; no-hunt/dry/salt; existing adaptive cautious public-action policy with scripted 65% aim. Salt can fall back to drying. No slaughter, crime, peaceful-camp visits or replacement hires. Two ration units when well, three if any active traveler is ill or below 80 health. Every 80 actions and final saves round-tripped. No data overrides or tuning. Small diagnostic, not a representative historical or held-out cohort. Corrected effect-based toll fundraising; waiting is an actual day. Action categories include all days spent by the action, including resulting effects. Abort after33 consecutive actions without time/distance progress. Full policy in tests/full_trail_balance.gd."},"\t"))
	file.close()
	for error in errors:printerr("ERROR: "+JSON.stringify(error))
	print("Historical diagnostic: %d journeys, %d selected invariant/setup/save/policy errors" % [rows.size(),errors.size()])
	quit(0 if errors.is_empty() and rows.size()==54*seed_count else 1)
