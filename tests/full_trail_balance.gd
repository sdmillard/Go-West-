extends SceneTree
## Repeatable development experiment through public engine actions. No game rules changed.
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
const JourneyTrade=preload("res://tests/journey_trade_policy.gd")
const PROFILES = [
	{"id":"cautious", "pace":0, "rations":2, "rest":true, "hunt":true},
	{"id":"meager", "pace":0, "rations":1, "rest":true, "hunt":true},
	{"id":"grueling", "pace":2, "rations":2, "rest":false, "hunt":true},
	{"id":"no_hunting", "pace":0, "rations":2, "rest":true, "hunt":false}
]
var adaptive := false
var hunting_study := false

func hunt_outing(game, profile: Dictionary, aim: RandomNumberGenerator, count: Dictionary) -> bool:
	if not game.start_hunt():return game.state.status != "traveling"
	count.hunts += 1
	var before_food: int = game.state.food
	var before_bullets: int = game.state.bullets
	if hunting_study:
		# Choose visible animals by meat yield; reposition along the lower clearing
		# when cover obstructs a shot. Movement itself still collides with cover.
		for tick in range(120):
			if game.hunt.ended or game.state.bullets == 0:break
			var target := -1
			var best := -1
			var obstructed := -1
			for index in range(game.hunt.animals.size()):
				if index in game.hunt.targets or game.hunt.animals[index].escaped:continue
				var point: Vector2 = game.hunting.bounds(game.hunt,index).get_center()
				if game.hunting.target_at(game.hunt,point) == index:
					if game.hunt.animals[index].meat > best:
						target=index
						best=game.hunt.animals[index].meat
				else:obstructed=index
			if target >= 0 and game.hunt.reload <= 0:
				var point: Vector2 = game.hunting.bounds(game.hunt,target).get_center() if aim.randf() < profile.accuracy else Vector2(0,0)
				game.hunt_fire_at(point)
			elif target < 0 and obstructed >= 0:
				game.move_hunter(Vector2(game.hunting.bounds(game.hunt,obstructed).get_center().x,140))
			game.advance_hunt(0.25)
	else:
		for shot in range(5):
			if game.hunt.ended:break
			var target := -1
			for index in range(game.hunt.animals.size()):
				if index not in game.hunt.targets and not game.hunt.animals[index].escaped:
					target = index
					break
			if target < 0:break
			var point: Vector2 = game.hunting.bounds(game.hunt,target).get_center() if aim.randf() < 0.65 else Vector2(0,0)
			game.hunt_fire_at(point)
			game.advance_hunt(1.5)
	count.shots += before_bullets-int(game.state.bullets)
	count.meat_obtained += int(game.hunt.meat)
	if game.hunt.meat == 0:count.empty_hunts+=1
	var finished: bool = game.finish_hunt()
	var recovered: Dictionary=game.last_hunt_recovery
	count.meat_carried += int(recovered.get("mass",0))
	count["meat_food_units"]=int(count.get("meat_food_units",0))+int(game.state.food)-before_food
	return finished

func _initialize() -> void:
	call_deferred("run")

func _try_care(game,count: Dictionary,below: int=55) -> bool:
	var wanted: int=6 if game.state.medicine>0 else 12
	if not game.open_care():return false
	for index in range(game.pending.choices.size()):
		var choice: Dictionary=game.pending.choices[index]
		if choice.get("care",0)!=wanted or not game.can_choose(index):continue
		var member: Dictionary=game.party_health.members[choice.member_id]
		if game.party_health.is_active(member) and not member.conditions.is_empty() and member.health<below:
			count.care+=1
			count.last_care=game.state.day
			return game.choose(index)
	game.choose(game.pending.choices.size()-1)
	return not game.pending.is_empty() and not game.pending.has("landmark")

func act(game, profile: Dictionary, aim: RandomNumberGenerator, count: Dictionary) -> bool:
	var ration: int = profile.rations
	var resupply_below := 90
	var hunt_below: int = profile.get("hunt_below",90 if adaptive else 45)
	if game.state.vehicle == "foot":
		var food_mass: float = game.state.food-game.provisions.tracked_food(game.state.food)+game.provisions.tracked_mass(game.state.food)
		var food_room: float = game.provisions.capacity(game.state)-(game.provisions.cargo(game.state)-food_mass)
		resupply_below=maxi(1,mini(30,floori(food_room*0.5)))
		hunt_below=mini(hunt_below,resupply_below)
	if profile.get("adaptive_rations",false):
		for member in game.party_health.members:
			if game.party_health.is_active(member) and (not member.conditions.is_empty() or member.health < 80):ration=2
	game.configure(profile.pace, ration)
	if not game.pending.is_empty():
		if game.pending.has("landmark"):
			if hunting_study and game.state.day-count.last_care>=3 and _try_care(game,count,int(profile.get("care_below",55))):return true
			for index in range(game.pending.choices.size()):
				var choice: Dictionary=game.pending.choices[index]
				if choice.get("action","")!="activity" or not game.can_choose(index):continue
				var kind: String=game.context.data.activities[choice.activity].kind
				if (kind=="graze" and game.state.ox_health<85) or (kind=="prepare" and game.state.river_stage=="high" and game.state.medicine>1):
					count["activities"]=int(count.get("activities",0))+1
					return game.choose(index)
		if game.state.vehicle != "foot" and game.pending.has("landmark") and game.route.nodes[game.state.landmark].get("trade_bulk",false) and game.state.food < 900:
			var cost: float = game.route.nodes[game.state.landmark].get("bulk_food_cents",6000) / 100.0
			if game.state.money >= cost + (10 if adaptive else 0):
				if game.open_trade():
					count.trades += 1
					if game.pending.choices[0].effects.get("food",0)>0 and game.can_choose(0):return game.choose(0)
					game.choose(game.pending.choices.size()-1)
					if not game.pending.is_empty() and not game.pending.has("landmark"):return true
		# Prefer a ferry; otherwise float at high water, ford at low water.
		if game.pending.has("landmark") and game.route.nodes[game.state.landmark].kind == "river":
			for method in ["ferry", "float" if game.state.river_stage == "high" else "ford"]:
				for index in range(game.pending.choices.size()):
					if game.pending.choices[index].get("method","") == method and game.can_choose(index):
						return game.choose(index)
		for index in range(game.pending.choices.size()):
			if game.pending.choices[index].get("action","") not in ["notes","trade","rest"] and game.can_choose(index):
				return game.choose(index)
		# A player can raise toll money through the same service menu.
		if adaptive and game.pending.has("landmark") and game.route.nodes[game.state.landmark].has("toll_dollars"):
			return JourneyTrade.raise_toll_money(game,count)
		# An unresolved choice is a policy block, not a death or arrival.
		return false
	if game.state.oxen == 0 and game.state.vehicle != "foot":
		if game.open_trade():
			if game.pending.title=="No traders nearby":return game.choose(0)
			var index := 8 if game.state.money >= 30 else 18
			if game.can_choose(index):return game.choose(index)
			game.choose(game.pending.choices.size()-1)
			if not game.pending.is_empty() and not game.pending.has("landmark"):return true
		return game.rest()
	if profile.get("preserve","") != "":
		var salted: bool = profile.preserve == "salt" and not game.preservation_offer(true).is_empty()
		if not game.preservation_offer(salted).is_empty():
			count.preservations+=1
			return game.preserve_meat(salted)
	if profile.get("slaughter",false) and game.state.oxen > int(profile.get("slaughter_team_floor",1)) and game.state.food < 90 and not game.ox_slaughter_offer().is_empty():
		count.oxen_slaughtered+=1
		return game.slaughter_ox()
	if game.state.food < resupply_below and game.state.money >= (25 if adaptive else 15):
		if game.open_trade():
			# Traders who refuse the party offer only the way back.
			if game.pending.title!="No traders nearby" and game.pending.choices[0].get("effects",{}).get("food",0)>0 and game.can_choose(0):
				count.trades += 1
				return game.choose(0)
			game.choose(game.pending.choices.size()-1)
			if not game.pending.is_empty() and not game.pending.has("landmark"):return true
	if hunting_study and game.state.day-count.last_care >= 3 and _try_care(game,count,int(profile.get("care_below",55))):return true
	if profile.hunt and game.state.food < hunt_below and game.state.bullets > 0:
		if profile.get("preserve","") == "salt" and game.state.salt < 5 and game.state.money >= 12:
			if game.open_trade():
				for index in range(game.pending.choices.size()):
					if game.pending.choices[index].get("effects",{}).get("salt",0) > 0 and game.can_choose(index):
						count.trades+=1
						return game.choose(index)
				game.choose(game.pending.choices.size()-1)
				if not game.pending.is_empty() and not game.pending.has("landmark"):return true
		return hunt_outing(game,profile,aim,count)
	var worst: int = game.state.health
	if hunting_study:
		for member in game.party_health.members:
			if game.party_health.is_active(member):worst=mini(worst,int(member.health))
	if profile.rest and (worst < int(profile.get("rest_below",70)) or game.state.fatigue > 50 or (game.state.vehicle!="foot" and game.state.ox_health<65)) and game.state.food >= game.state.party_size * (ration+1):
		for reason in ["health","fatigue","oxen"]:
			var triggered: bool=worst<int(profile.get("rest_below",70)) if reason=="health" else (game.state.fatigue>50 if reason=="fatigue" else game.state.vehicle!="foot" and game.state.ox_health<65)
			if triggered:count["rest_"+reason]=int(count.get("rest_"+reason,0))+1
		count.rests += 1
		return game.rest()
	return game.travel()

func run() -> void:
	adaptive = "--adaptive" in OS.get_cmdline_user_args()
	hunting_study = "--hunting" in OS.get_cmdline_user_args()
	var mixed := "--mixed" in OS.get_cmdline_user_args()
	var preserving := "--preservation" in OS.get_cmdline_user_args()
	var oxen_study := "--oxen" in OS.get_cmdline_user_args()
	if oxen_study:preserving=true
	if preserving:mixed=true
	if mixed:hunting_study=true
	if hunting_study:adaptive=true
	var profiles: Array = PROFILES.duplicate(true)
	var seed_count := 20
	var seed_start := 0
	if hunting_study:
		seed_count=10
		profiles=[]
		for ration in [1,2]:
			for accuracy in [0.35,0.65,0.9]:
				for threshold in [45,90]:
					profiles.append({"id":"hunt_%d_r%d_below%d" % [int(accuracy*100),ration+1,threshold],"pace":0,"rations":ration,"rest":true,"hunt":true,"accuracy":accuracy,"hunt_below":threshold})
			profiles.append({"id":"no_hunt_r%d" % (ration+1),"pace":0,"rations":ration,"rest":true,"hunt":false,"accuracy":0.0})
	if mixed:
		seed_count=20
		profiles=[]
		for use_hunt in [true,false]:
			profiles.append({"id":"mixed_hunt" if use_hunt else "mixed_no_hunt","pace":0,"rations":1,"rest":true,"hunt":use_hunt,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true})
	if preserving:
		profiles=[{"id":"no_hunt","pace":0,"rations":1,"rest":true,"hunt":false,"accuracy":0.0,"adaptive_rations":true}]
		for accuracy in [0.35,0.65,0.9]:
			for method in ["","dry","salt"]:
				profiles.append({"id":"hunt_%d_%s" % [int(accuracy*100),"fresh" if method.is_empty() else method],"pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":accuracy,"hunt_below":45,"adaptive_rations":true,"preserve":method})
	if oxen_study:
		profiles=[]
		for slaughter in [false,true]:
			profiles.append({"id":"spare_ox" if slaughter else "hunting_preserve","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":slaughter})
	var label := "full-trail-balance"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):label=argument.trim_prefix("--label=").validate_filename()
		if argument.begins_with("--seed-start="):seed_start=int(argument.trim_prefix("--seed-start="))
	var runs: Array = []
	var errors: Array = []
	var store = Store.new()
	for profile in profiles:
		for profession in ["farmer","carpenter","banker"]:
			for month in [3,5,8]:
				var arrived := 0
				for seed_value in range(seed_start,seed_start+seed_count):
					var game = Simulation.new(seed_value,"classic",true)
					var cart: Dictionary = {}
					for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
					if not game.depart(profession,["A","B","C","D","E"],month,cart):
						errors.append(game.departure_error)
						continue
					var aim := RandomNumberGenerator.new()
					aim.seed = seed_value ^ 0x41494d
					var count := {"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
					var outcome := "limit"
					for step in range(2400):
						if game.state.status != "traveling":
							outcome = game.state.status
							break
						if game.state.day >= 365:break
						var day: int = game.state.day
						var miles: int = game.state.miles
						if not act(game,profile,aim,count):
							outcome = "policy_blocked"
							break
						if game.state.miles > miles:count.travel_days+=1
						if game.state.day > day and game.state.food == 0:count.empty_food_days+=game.state.day-day
						if game.state.food < 0 or game.state.money < -0.001 or game.state.party_size < 0 or game.state.salt < 0 or game.provisions.cargo(game.state) < 0 or game.provisions.fresh_pounds(game.state.food)+game.provisions.preserved_pounds(game.state.food)>game.state.food or not game.error.is_empty():
							errors.append({"profile":profile.id,"profession":profession,"month":month,"seed":seed_value,"error":game.error})
							break
					if outcome == "arrived":arrived+=1
					var deaths: Array = []
					for member in game.party_health.members:
						if not member.alive:deaths.append({"cause":member.cause,"day":member.death_day})
					var spoiled := 0
					for entry in game.supply_history:
						if entry.event == "spoilage":spoiled-=int(entry.changes.food)
					var row := {"profile":profile.id,"profession":profession,"month":month,"seed":seed_value,"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"food":game.state.food,"money":game.state.money,"bullets":game.state.bullets,"landmark":game.state.landmark,"pending":game.pending.get("id",""),"deaths":deaths,"spoiled_lb":spoiled,"calendar":game.calendar()}
					row.merge(count)
					if outcome != "arrived":row["recent_journal"]=game.journal.slice(maxi(0,game.journal.size()-6))
					runs.append(row)
				print("%s %s month %d: %d/%d arrived" % [profile.id,profession,month,arrived,seed_count])
				await process_frame
	var file := FileAccess.open("res://docs/" + label + ("-oxen" if oxen_study else ("-preservation" if preserving else ("-mixed" if mixed else ("-hunting" if hunting_study else ("-adaptive" if adaptive else ""))))) + ".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"route_miles":1938,"seed_range":[seed_start,seed_start+seed_count-1],"profiles":profiles,"adaptive":adaptive,"hunting_study":hunting_study,"mixed_rations":mixed,"preservation_study":preserving,"oxen_study":oxen_study,"outfit":"Current suggested cart for every profession; see outfitting_rules for exact quantities/prices/budgets.","party_benefit_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/party_benefits.json")),"combat_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json")),"context_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_context.json")),"survival_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json")),"provisions_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/provisions.json")),"outfitting_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/outfitting.json")),"policy":"Bulk buy below 900 lb when affordable; passing-wagon buy below 90; hunt below 45 (adaptive: 90, hunting study: profile threshold); rest below 70 health or above 50 fatigue only with food. Adaptive holds $10 when buying food and sells supplies if blocked at toll. Hunting study watches worst individual health and provides care below 55 if an active condition and kit/cash available, at least 3 days apart; $10 cash reserve. Other batches no paid care. First affordable event choice; ferry or stage-appropriate crossing. Mixed/preservation profiles use two lb when well, three if any living traveler has a condition or internal health below 80. Preservation profiles process leftover fresh meat before buying/care; salt mode falls back to unsalted drying and attempts a salt purchase before hunting below five lb salt when cash >= $12. Spare-ox profile shoots one spare animal below90 food before buying food, then preserves using the same rules; retains one ox by policy (the game allows zero), never buys animals solely for food and never uses hand tools. Stop at 365 days/2400 actions or unresolvable choice.","hunting":"Baseline/adaptive: 65% center aim, stationary hunter, actual cover/reload/escape. Hunting study: 35/65/90% center aim, visible highest-meat target, lower-clearing movement when obstructed, 0.25s live ticks. Misses go to (0,0). Scripted skill assumptions, not measured player skill or pathfinding.","runs":runs,"errors":errors},"\t"))
	print("Full trail balance: %d journeys; %d invariant/setup errors" % [runs.size(),errors.size()])
	quit(0 if errors.is_empty() and runs.size()==profiles.size()*9*seed_count else 1)



