extends "res://tests/full_trail_balance.gd"
## Isolate study decisions, never the game's medical or recovery rules.
const RemainsAudit=preload("res://simulation/remains.gd")
const ARMS=[{"id":"reference","rest_below":70,"care_below":55},{"id":"later_rest","rest_below":55,"care_below":55},{"id":"earlier_care","rest_below":70,"care_below":70},{"id":"combined","rest_below":55,"care_below":70}]
func run() -> void:
	adaptive=true
	hunting_study=true
	var label: String="rest-care-diagnostic-01"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=").validate_filename()
	var path: String="res://docs/"+label+".json"
	if FileAccess.file_exists(path):printerr("Choose a new archive label");quit(1);return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	for arm in ARMS:
		for profession in ["farmer","carpenter"]:
			for month in [4,5]:
				for method in ["dry","salt"]:
					for seed_value in range(4):
						var game=Simulation.new(seed_value,"classic",true)
						var cart: Dictionary={}
						for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
						if not game.depart(profession,["A","B","C","D","E"],month,cart):errors.append({"error":game.departure_error});continue
						var policy: Dictionary={"id":arm.id,"rest_below":arm.rest_below,"care_below":arm.care_below,"pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":method,"slaughter":false}
						var aim:=RandomNumberGenerator.new()
						aim.seed=seed_value ^ 0x41494d
						var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
						var outcome: String="action_limit"
						var idle:=0
						var trajectory: Array=[]
						var last_sample: int=-15
						for step in range(2400):
							if game.state.status!="traveling":outcome=game.state.status;break
							if game.state.day>=365:outcome="out_of_time";break
							var day: int=game.state.day
							var miles: int=game.state.miles
							if not act(game,policy,aim,count):outcome="policy_blocked";errors.append({"arm":arm.id,"profession":profession,"month":month,"method":method,"seed":seed_value,"error":outcome});break
							if game.state.miles>miles:count.travel_days+=1
							if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
							idle=idle+1 if game.state.day==day and game.state.miles==miles else 0
							if idle>32:outcome="policy_stalled";errors.append({"arm":arm.id,"error":outcome});break
							if game.state.day-last_sample>=15:
								trajectory.append({"day":game.state.day,"miles":game.state.miles,"food":game.state.food,"cash":game.state.money,"worst_health":game.party_health.members.filter(func(m):return game.party_health.is_active(m)).map(func(m):return m.health).min(),"party":game.state.party_size,"ox_health":game.state.ox_health})
								last_sample=game.state.day
							if game.state.food<0 or game.state.money<0 or game.state.salt<0 or game.state.party_size!=game.party_health.living_count() or int(game.state.get("remains_lb",0))!=RemainsAudit.weight(game) or not game.error.is_empty():errors.append({"arm":arm.id,"error":"state invariant"});outcome="invariant_failed";break
							if step%80==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"arm":arm.id,"error":"save round trip","detail":store.error});outcome="save_failed";break
						if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"arm":arm.id,"error":"final save","detail":store.error})
						var deaths: Array=[]
						for member in game.party_health.members:
							if not member.alive:deaths.append({"cause":member.cause,"day":member.death_day})
						rows.append({"arm":arm.id,"profession":profession,"month":month,"method":method,"seed":seed_value,"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"cash":game.state.money,"food":game.state.food,"kits_remaining":game.state.medicine,"deaths":deaths,"departures":game.party_health.members.filter(func(m):return m.get("departed",false)).size(),"counts":count,"trajectory":trajectory})
					print("%s %s month%d %s complete" % [arm.id,profession,month,method])
					await process_frame
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"arms":ARMS,"runs":rows,"errors":errors,"policy":"128 journeys: four study decision policies x two capitals x April/May x drying/salt x seeds0-3. Six oxen and current suggested cargo; default seed-matched unpaid parties; same adaptive cautious public-action policy and 65% scripted aim. Only rest-health trigger (70 or55) and care-health trigger (55 or70) differ. Fatigue and oxen rest triggers, all recovery rules, food/care costs, care interval, disease/weather and trade policy unchanged. Rest trigger counts can overlap. No game-rule overrides. Small development diagnostic, not held-out historical calibration."},"\t"))
	file.close()
	print("Rest/care diagnostic: %d journeys, %d selected errors" % [rows.size(),errors.size()])
	for error in errors:printerr("ERROR: "+JSON.stringify(error))
	quit(0 if errors.is_empty() and rows.size()==128 else 1)
