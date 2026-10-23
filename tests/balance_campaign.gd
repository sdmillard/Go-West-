extends "res://tests/outlaw_journeys.gd"
## Phase 7 matrix, public actions only. Development seeds 100..119; reserve 1000..1019.
const ROSTERS=["ordinary","mixed_paid","fragile","selected"]
func signatures() -> Dictionary:
	var result: Dictionary={}
	for source in DirAccess.get_files_at("res://simulation"):
		if source.ends_with(".gd"):result["simulation/"+source]=FileAccess.get_sha256("res://simulation/"+source)
	for source in ["tests/balance_campaign.gd","tests/full_trail_balance.gd","tests/outlaw_journeys.gd"]:result[source]=FileAccess.get_sha256("res://"+source)
	return result
const POLICIES=["dry","salt","no_hunt","theft","robbery","already_dead","predation"]
func run():
	adaptive=true
	hunting_study=true
	var profession: String="farmer"
	var label: String="development-01"
	var seeds:=20
	var seed_start:=100
	var rest_below:=55
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--profession="):profession=argument.trim_prefix("--profession=")
		if argument.begins_with("--label="):label=argument.trim_prefix("--label=").validate_filename()
		if argument.begins_with("--seeds="):seeds=clampi(int(argument.trim_prefix("--seeds=")),1,20)
		if argument.begins_with("--seed-start="):seed_start=int(argument.trim_prefix("--seed-start="))
		if argument.begins_with("--rest-below="):rest_below=int(argument.trim_prefix("--rest-below="))
	var path: String="res://docs/balance-"+label+"-"+profession+".json"
	if profession not in ["farmer","carpenter","banker"] or FileAccess.file_exists(path):
		printerr("Choose a profession and an unused archive label");quit(1);return
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	var started:=Time.get_ticks_msec()
	var frozen_rules: String=store.fingerprint()
	var frozen_sources: Dictionary=signatures()
	for month in [3,5,8]:
		for roster in ROSTERS:
			for strategy in POLICIES:
				for seed_value in range(seed_start,seed_start+seeds):
					var game=Simulation.new(seed_value,"classic",true)
					var cart: Dictionary={}
					for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
					var people=preload("res://simulation/party_character.gd").new()
					people.start(seed_value,5)
					var terms: Dictionary={}
					for person in people.profiles.slice(1):
						if roster=="fragile":person.flaws=["Frail"]
						if roster=="selected":person.specials=["Loyal","Veteran","Hardy"];person.flaws=["Slow Healer"]
						if roster=="mixed_paid" and person.id<=2:
							person.specials=["Mercenary"]
							terms[str(person.id)]={"wage_cents":people.wage_quote(person).daily_cents*7,"interval_days":7}
					var identity: Dictionary={"profession":profession,"month":month,"roster":roster,"strategy":strategy,"seed":seed_value}
					if not game.depart(profession,["A","B","C","D","E"],month,cart,{"profiles":people.profiles.duplicate(true),"contracts":terms}):
						errors.append({"run":identity,"error":game.departure_error});continue
					var policy: Dictionary={"id":strategy,"pace":0,"rations":1,"rest":true,"hunt":strategy!="no_hunt","accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"dry" if strategy=="dry" else "salt","slaughter":true,"rest_below":rest_below}
					if strategy=="no_hunt":policy.preserve=""
					var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
					var aim:=RandomNumberGenerator.new()
					aim.seed=seed_value ^ 0x41494d
					var acts: Dictionary={"crime":0,"attack":false}
					var paid:=0
					var idle:=0
					var outcome: String="action_limit"
					var curve: Array=[]
					var next_sample:=0
					for step in range(2400):
						if game.state.status!="traveling":outcome=game.state.status;break
						if game.state.day>=365:outcome="year_limit";break
						for person in game.characters.profiles.slice(1):
							if person.contract.is_empty() or not game.party_health.is_active(game.party_health.members[person.id]):continue
							var due: int=person.contract.arrears_cents
							if due>0 and game.state.money>=due/100.0+10 and game.characters.pay_wages(game,person.id):paid+=due
						var day: int=game.state.day
						var mile: int=game.state.miles
						var okay:=true
						var available: bool=game.pending.is_empty() or game.pending.has("landmark")
						if game.pending.get("crime_menu",false):okay=settle_crime(game)
						elif game.pending.get("remains_menu",false) or game.pending.get("attack_menu",false):okay=game.choose(game.pending.choices.size()-1)
						elif available and strategy in ["theft","robbery"] and acts.crime<3 and game.crime.eligible(game) and game.crime.transient(game.crime.target(game)):
							acts.crime+=1
							okay=game.open_crime() and pick(game,"crime_command",strategy)
						elif available and strategy=="predation" and not acts.attack and day>=20 and game.state.party_size>=3 and game.state.bullets>0:
							acts.attack=true
							var target: int=game.party_health.members.filter(func(member):return member.id>0 and game.party_health.is_active(member)).back().id
							okay=game.open_attack(target) and game.choose(0)
						elif available and strategy in ["already_dead","predation"] and Remains.here(game).any(func(item):return item.state in ["lying","carried"]):okay=eat_the_dead(game,strategy=="predation")
						else:okay=act(game,policy,aim,count)
						if not okay:
							outcome="policy_blocked";errors.append({"run":identity,"error":outcome,"pending":game.pending.get("id","")});break
						idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
						if idle>32:outcome="policy_stalled";errors.append({"run":identity,"error":outcome});break
						if game.state.miles>mile:count.travel_days+=1
						if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
						if game.state.food<0 or game.state.money<0 or game.state.bullets<0 or game.state.salt<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health() or int(game.state.get("remains_lb",0))!=Remains.weight(game) or game.provisions.tracked_food(game.state.food)>game.state.food or not game.error.is_empty():
							outcome="invariant_failed";errors.append({"run":identity,"error":outcome});break
						if (seed_value==seed_start and step%80==0) or game.pending.get("crime_menu",false) or game.pending.get("remains_menu",false):
							if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:
								outcome="save_failed";errors.append({"run":identity,"error":store.error});break
						if game.state.day>=next_sample:
							curve.append([game.state.day,game.state.miles,game.state.food,game.state.money,game.state.bullets,game.state.party_size]);next_sample=game.state.day+30
					if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":identity,"error":"final save: "+store.error})
					var record: Dictionary=game.crime.record
					var row: Dictionary=identity.duplicate()
					var causes: Array=[]
					var departures:=0
					for member in game.party_health.members:
						if not member.alive:causes.append(member.cause)
						if member.get("departed",false):departures+=1
					row.merge({"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"death_causes":causes,"departures":departures,"cash":game.state.money,"food":game.state.food,"bullets":game.state.bullets,"oxen":game.state.oxen,"health":game.party_health.members.map(func(member):return member.health),"wages_paid_cents":paid,"wages_owed_cents":game.characters.due_total(),"counts":count,"curve":curve,"incidents":record.incidents.map(func(item):return [item.action,item.attempt,item.resolution,item.food,item.cash_cents]),"attacks":record.attacks.map(func(item):return item.attempt),"bodies":record.remains.map(func(item):return item.state),"tales":game.crime.tales(game).size(),"loss_reason":game.state.loss_reason})
					rows.append(row)
					await process_frame
				print("%s month%d %s %s: %d runs, %d errors, %.1fs" % [profession,month,roster,strategy,rows.size(),errors.size(),(Time.get_ticks_msec()-started)/1000.0])
	if frozen_rules!=store.fingerprint() or frozen_sources!=signatures():errors.append({"error":"Rule/source files changed while campaign ran"})
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":frozen_rules,"source_hashes":frozen_sources,"seed_start":seed_start,"seed_count":seeds,"rest_below":rest_below,"runs":rows,"errors":errors,"seconds":(Time.get_ticks_msec()-started)/1000.0},"\t"));file.close()
	print("Campaign shard: %d journeys, %d errors" % [rows.size(),errors.size()])
	quit(0 if rows.size()==84*seeds and errors.is_empty() else 1)
