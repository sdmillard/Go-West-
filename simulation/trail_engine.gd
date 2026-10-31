extends RefCounted
## Pure simulation: no UI nodes, wall-clock time, input, or global RNG.
const Catalog = preload("res://simulation/event_catalog.gd")
const ProfessionSkill = preload("res://simulation/profession_skill.gd")
const Outfitting = preload("res://simulation/outfitting.gd")
const Route = preload("res://simulation/route_catalog.gd")
const PartyHealth = preload("res://simulation/party_health.gd")
const Survival = preload("res://simulation/survival_rules.gd")
const Pelts=preload("res://simulation/pelts.gd")
const Produce=preload("res://simulation/produce_trade.gd")
const Direction=preload("res://simulation/travel_direction.gd")
const RobberyDemand=preload("res://simulation/robbery_demand.gd")
const Guards=preload("res://simulation/wagon_guards.gd")
const CacheSupport=preload("res://simulation/wagon_cache.gd")
const Remains=preload("res://simulation/remains.gd")
const Mounts=preload("res://simulation/mounts.gd")
const Armory=preload("res://simulation/armory.gd")
const Cabins=preload("res://simulation/cabins.gd")
const Scoring=preload("res://simulation/scoring.gd")
const Pasture=preload("res://simulation/pasture.gd")
## Scoped to the synchronous grazing activity, never a saved ongoing bonus.
var grazing_activity: bool=false
var field_outings=preload("res://simulation/field_outings.gd").new()
var camp_repair=preload("res://simulation/camp_repair.gd").new()
var camp_tasks=preload("res://simulation/camp_tasks.gd").new()
var wagon_cache: Dictionary={}
const MAX_TRAVELERS := 1000000 # File-size validation bounds records; there is no gameplay roster cap.
const PARTY_CAPACITY := 5 # Starting party only.
const Train=preload("res://simulation/wagon_train.gd")
var native_encounters=preload("res://simulation/native_encounters.gd").new()
var recruitment=preload("res://simulation/party_recruitment.gd").new()
var social=preload("res://simulation/party_social.gd").new()
var leathercraft=preload("res://simulation/leathercraft.gd").new()
var income=preload("res://simulation/trail_income.gd").new()
var context=preload("res://simulation/trail_context.gd").new()
var combat=preload("res://simulation/combat.gd").new()
var crime=preload("res://simulation/crime_system.gd").new()
var news=preload("res://simulation/trail_news.gd").new()
## The last fragment of news a camp menu question drew (shown beside the camp picture; not saved).
var last_news: String=""
const DESTINATION := 102
const ABSURD_CHANCE := 0.01
const PACE_MILES = [12, 18, 24]
const RATION_LB = [1, 2, 3]
var catalog = Catalog.new()
var rng := RandomNumberGenerator.new()
var state: Dictionary
var pending: Dictionary = {}
var seen: Array = []
var journal: Array[String] = []
var error := ""
var outfitter = Outfitting.new()
var departure_error := ""
## Authored placeholder costs of a waterless leg (Palmer: "No water and but little grass between").
const WATERLESS := {"ox_strain": 3, "thirst": 1}
## Placeholder trouble on an unsettled road: trail events twice as likely,
## and these encounters three times as likely among them.
const UNREST := {"chance_factor": 2.0, "weight_factor": 3, "events": ["riders", "bandits"]}
## Placeholder river travel: raft or boat miles per day before wind, and the
## portage time. Interactive Cascades consequences live in data/rafting.json.
const RIVER := {"miles":15,"portage_days":2}
var route = Route.new()
# Stops reached so far, in order, from the start; records which road was taken.
var route_path: Array = []
var last_crossing: Dictionary = {}
var crossing_history: Array[Dictionary] = []
var party_health = PartyHealth.new()
var characters=preload("res://simulation/party_character.gd").new()
var health_events: Array[String] = []
var survival = Survival.new()
var trail_events = Catalog.new()
var service_return: Dictionary = {}
var team_conditions=preload("res://simulation/team_conditions.gd").new()
var rafting=preload("res://simulation/rafting.gd").new()
var raft: Dictionary={}
var rafting_history: Array[Dictionary]=[]
var last_rafting: Dictionary={}
var dogs=preload("res://simulation/working_dog.gd").new()
var livestock=preload("res://simulation/livestock.gd").new()
var fishing=preload("res://simulation/fishing.gd").new()
var hunting = preload("res://simulation/hunting.gd").new()
var hunting_outings := 0
var last_hunt_recovery: Dictionary = {}
var hunt: Dictionary = {}
var supply_history: Array[Dictionary] = []
var provisions = preload("res://simulation/provisions.gd").new()
var tactical = preload("res://simulation/tactical_combat.gd").new()
var tactical_session: Dictionary = {}
var last_tactical: Dictionary = {}

## setup=false retains the original pre-outfitted short-leg fixture for scripted simulations.
## The player interface always passes setup=true and must call depart before travel.
func _init(seed_value: int = 1848, mode: String = "classic", setup: bool = false, end_at: String = "") -> void:
	provisions.carriers=party_health.members
	party_health.character_profiles=characters.profiles
	party_health.character_catalog=characters.catalog
	rng.seed = seed_value
	crime.start(seed_value)
	state = {"day": 0, "miles": 0, "food": 180, "health": 85, "money": 60,
		"parts": 2, "fuel": 0, "vehicle": "wagon", "items": [], "pace": 1,
		"rations": 1, "party_size": 5, "mode": "unhinged" if mode == "unhinged" else "classic",
		"status": "traveling", "seed": seed_value}
	state.merge({"party": ["SPENCER", "SAM", "JORDAN", "RILEY", "MORGAN"],
		"profession": "", "departure_month": 5, "oxen": 6, "clothing": 0,
		"bullets": 0, "wheels": 2, "axles": 0, "tongues": 0,
		"extended_route": setup, "landmark": "independence", "leg_miles": 0, "leg_length": 0, "next_landmark": "", "river_stage": ""})
	state.merge({"medicine": 0, "salt":0, "ox_health": 100, "fatigue": 0, "weather": "Clear", "terrain": "plains", "loss_reason": ""})
	for item in provisions.data.pelts.goods:state[item]=0
	if setup and not end_at.is_empty() and not route.truncate_at(end_at):
		error = "Unknown route endpoint."
		state.status = "error"
		return
	if setup:
		state.status = "outfitting"
		for key in ["food", "money", "parts", "oxen", "wheels", "axles", "tongues"]:
			state[key] = 0
	if not catalog.load_file():
		error = catalog.error
		state.status = "error"
	if not outfitter.error.is_empty():
		error = outfitter.error
		state.status = "error"
	if not route.error.is_empty():
		error = route.error
		state.status = "error"
	elif setup:
		route_path = [state.landmark]
		_set_next_leg()
	if not combat.error.is_empty():
		error=combat.error
		state.status="error"
	if not RobberyDemand.valid_rules(RobberyDemand.data):
		error="Invalid robbery demand rules."
		state.status="error"
	if not crime.error.is_empty():
		error=crime.error
		state.status="error"
	if not social.error.is_empty():
		error=social.error
		state.status="error"
	if not context.error.is_empty():
		error=context.error
		state.status="error"
	if not provisions.error.is_empty():
		error = provisions.error
		state.status = "error"
	if not native_encounters.error.is_empty():
		error=native_encounters.error;state.status="error"
	if not Armory.valid_rules(Armory.data):
		error="Invalid weapon rules.";state.status="error"
	if not Cabins.valid_rules(Cabins.data,route if end_at.is_empty() else null) or not Scoring.valid_rules(Scoring.data):
		error="Invalid cabin, settling or scoring rules.";state.status="error"
	for place in native_encounters.data.get("sites",{}):
		if end_at.is_empty() and not route.nodes.has(place):error="Unknown Native encounter location.";state.status="error"
	if not rafting.error.is_empty():
		error=rafting.error
		state.status="error"
	if not dogs.error.is_empty():
		error=dogs.error
		state.status="error"
	if not livestock.error.is_empty():
		error=livestock.error
		state.status="error"
	if not fishing.error.is_empty():
		error=fishing.error
		state.status="error"
	if not hunting.error.is_empty():
		error = hunting.error
		state.status = "error"
	if not party_health.error.is_empty():
		error = party_health.error
		state.status = "error"
	if not characters.error.is_empty():
		error=characters.error
		state.status="error"
	if not trail_events.load_file("res://data/trail_events.json", true) or not survival.error.is_empty():
		error = trail_events.error if not trail_events.error.is_empty() else survival.error
		state.status = "error"
	journal.append("Independence, 1848. Outfit your wagon." if setup else "May 1, 1848 · Independence. Five travelers, one wagon, a long road.")

func depart(profession: String, names: Array, month: int, cart: Dictionary, customization: Dictionary={}) -> bool:
	departure_error = ""
	if state.status != "outfitting":
		departure_error = "This journey has already departed."
		return false
	if names.size() != 5 or month < 3 or month > 8:
		departure_error = "Choose five travelers and a March–August departure."
		return false
	var cleaned: Array[String] = []
	for entry in names:
		if not entry is String or entry.strip_edges().is_empty() or entry.strip_edges().length() > 14:
			departure_error = "Give each traveler a name (1–14 characters)."
			return false
		cleaned.append(entry.strip_edges())
	var quote: Dictionary = outfitter.quote(profession, cart)
	if not quote.valid:
		departure_error = quote.message
		return false
	# Commit only after every input validates. Rejected purchases change no state or RNG.
	if not customization.is_empty() and not characters.valid_setup(customization):
		departure_error="Check companion details and mercenary wage agreements."
		return false
	if customization.has("keepsakes") and not income.valid_setup(customization.keepsakes,cleaned.size()):
		departure_error="Check personal keepsakes."
		return false
	state.party = cleaned
	party_health.start(cleaned, int(state.seed))
	characters.start(int(state.seed),cleaned.size())
	if not customization.is_empty():characters.profiles.assign(customization.profiles.duplicate(true))
	income.start(self,customization.get("keepsakes",[]))
	crime.bind_party(self)
	crime.make_bonds(self)
	if customization.has("bonds"):crime.record.bonds=customization.bonds.duplicate(true)
	social.start(self,customization.get("romance",true))
	survival.start(int(state.seed))
	state.profession = profession
	state.departure_month = month
	state.money = float(quote.remaining_cents) / 100.0
	for key in ["oxen", "food", "clothing", "wheels", "axles", "tongues", "medicine", "salt"]:
		state[key] = int(cart.get(key, 0))
	for key in livestock.GOODS:
		if int(cart.get(key,0))>0:state[key]=int(cart[key])
	livestock.sync(self)
	if int(cart.get("dog",0))>0:dogs.acquire(self,false)
	for key in Mounts.KEYS:
		if int(cart.get(key,0))>0:state[key]=int(cart[key])
	# Everyone brings their own rifle and knife; bought arms come on top.
	Armory.home_kit(state,cleaned.size())
	for key in Armory.KEYS:state[key]=Armory.count(state,key)+int(cart.get(key,0))
	team_conditions.start_legacy(self)
	if not quote.wagon:
		# Packers leave without a wagon: only personal gear travels with them, and no wheel can crack.
		state.vehicle="foot"
		seen.append("muddy_trail")
		state["household_gear_lb"]=float(provisions.data.walking.personal_gear_lb_per_person)*cleaned.size()
	for item in Produce.ITEMS:
		Produce.add(provisions,item,int(cart.get(item,0)),0)
		state.food+=int(cart.get(item,0))
	state.bullets = int(cart.get("bullet_boxes", 0)) * 20
	state.parts = state.wheels + state.axles + state.tongues
	state.pace = 0
	state.rations = 2
	state.status = "traveling"
	for key in customization.get("contracts",{}):
		var terms: Dictionary=customization.contracts[key]
		characters.start_contract(self,int(key),int(terms.wage_cents),int(terms.interval_days))
		if terms.get("auto_pay",false):characters.set_auto_pay(self,int(key),true)
	journal.append("Departed %s 1, 1848 as a %s. Party: %s." % [str(month), profession, ", ".join(cleaned)])
	journal.append("Supplies cost $%.2f. Cash remaining: $%.2f." % [float(quote.total_cents) / 100.0, state.money])
	if not quote.wagon:journal.append("Left Independence without a wagon, as packers: %s." % Mounts.describe(mount_plan()))
	return true

func calendar() -> Dictionary:
	var start := "1848-%02d-01T00:00:00" % state.departure_month
	return Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_string(start)) + state.day * 86400)

## Guide miles of the whole journey along the road chosen so far, then the main road.
func destination() -> int:
	if not state.extended_route:
		return DESTINATION
	if not route.nodes.has(state.landmark):
		return route.total_miles
	if state.next_landmark == "" or state.next_landmark == state.landmark or not route.nodes.has(state.next_landmark):
		return int(state.miles) + route.remaining(state.landmark)
	return int(state.miles) - int(state.leg_miles) + int(state.leg_length) + route.remaining(state.next_landmark)

## Stops reached so far. A party placed directly at a stop (scenario fixtures)
## without a matching history is treated as having come by the main road.
func travelled_path() -> Array:
	if not route_path.is_empty() and route_path[-1] == state.landmark and route.valid_path(route_path):
		return route_path
	var main: Array = route.main_path_to(str(state.landmark))
	return main if not main.is_empty() else route_path

## The road the party is on between stops, or {} at a stop.
func current_edge() -> Dictionary:
	if state.next_landmark == state.landmark:
		return {}
	return route.edge_between(state.landmark, state.next_landmark)

func _set_next_leg(edge_index: int = 0) -> void:
	if Direction.heading(self)=="east":
		Direction.next_east(self)
		return
	var node: Dictionary = route.nodes[state.landmark]
	state.terrain = node.get("terrain", "plains")
	if node.next.is_empty():
		state.next_landmark = ""
		state.status = "arrived"
		return
	var edge: Dictionary = node.next[clampi(edge_index, 0, node.next.size() - 1)]
	state.next_landmark = edge.to
	state.leg_length = int(edge.miles)
	state.leg_miles = 0
	state.river_stage = ""

func _arrive_landmark(revisit: bool=false,roll_stage: bool=true) -> void:
	if state.landmark!="deschutes":native_encounters.Story.end_guide(native_encounters,self,"arrival at "+str(state.landmark))
	var approach: String=str(pending.get("approach_direction",Direction.heading(self))) if revisit else Direction.heading(self)
	route_path=travelled_path().duplicate()
	if not revisit:
		state.landmark=state.next_landmark
		route_path.append(state.landmark)
	else:
		state.next_landmark=state.landmark
		state.leg_miles=0
		state.leg_length=0
	var node: Dictionary = route.nodes[state.landmark]
	journal.append("Day %d · Reached %s. Guide mileage: %d." % [state.day, node.name, state.miles])
	if node.kind in ["chapter_end", "destination"]:
		state.status = "arrived"
		state.next_landmark = ""
		return
	var options: Array = []
	var description: String = node.text
	if node.kind == "river":
		# Assigned play conditions, not measured/reconstructed weather for a day in 1848.
		# Snow-fed rivers run high in the June melt; rain-fed ones with spring rains.
		if roll_stage or state.river_stage=="":
			state.river_stage = "high" if rng.randf() < survival.river_high_chance(int(calendar().month), node.get("river_source","rain")) or survival.wet_ground >= 4 else "low"
		description += river_conditions()
		if node.has("ferry_dollars"):
			# Ferrymen on the snow-fed rivers charged by the current: high water could double the fare.
			var fare: float=(float(node.get("ferry_high_dollars",node.ferry_dollars)) if state.river_stage=="high" else float(node.ferry_dollars))*maxi(1,Train.count(state))+float(livestock.data.ferry_head_cents)/100.0*(livestock.count(state,"dairy_cows")+livestock.count(state,"goats"))
			options.append({"label": "Hire the ferry · $%.2f, 1 day" % fare,
				"action": "cross", "method": "ferry", "requires": {"money": fare}, "effects": {"money": -fare, "days": 1}})
		options.append({"label": "Attempt a ford · 1 day, risk to supplies", "action": "cross", "method": "ford", "effects": {"days": 1}, "risk": 0.65 if state.river_stage == "high" else 0.08})
		options.append({"label": "Prepare and float · 1 day, risk to supplies", "action": "cross", "method": "float", "effects": {"days": 1}, "risk": 0.35 if state.river_stage == "high" else 0.2})
		if state.vehicle=="foot":
			options=options.filter(func(option):return option.get("method","")=="ferry")
			if Mounts.animals(state)>0:options.append(horse_crossing())
			else:options.append({"label":"Swim across with packs · 1 day, high injury / supply-loss risk","action":"cross","method":"swim","effects":{"days":1},"risk":swimming_risk()})
	else:
		for index in range(node.next.size()):
			var road: Dictionary = node.next[index]
			var leave := {"label": road.get("label", "Continue toward " + route.nodes[road.to].name), "action": "leave"}
			if index > 0:
				leave["edge"] = index
			if road.has("effects"):
				leave["effects"] = road.effects.duplicate()
			if route.nodes[road.to].has("wagon_closed_months"):
				leave["seasonal_road"]=road.to
				leave.label+=" · snowbound to wagons %s" % closed_months_text(road.to)
			# No raft is launched on a frozen river.
			if road.get("hazard","")=="river":
				leave["river_leg"]=true
				if river_frozen():leave.label+=" · the river is frozen"
				elif not river_winter().is_empty():leave.label+=" · winter wind and cold"
			options.append(leave)
	if node.get("descent",false):
		options[0] = {"label":"Lower wagons carefully · 2 days", "action":"leave", "effects":{"days":2}}
		if state.vehicle=="foot":options[0]={"label":"Descend carefully on foot · 1 day","action":"leave","effects":{"days":1}}
		else:options.insert(1,{"label":"Hurry the descent · 1 day, cargo/injury risk", "action":"leave", "effects":{"days":1}, "descent_risk":0.25})
	if node.get("portage",false):
		description="Six miles of rapids. Most parties portaged, often with Chinookan help. Running risks cargo, injuries and drowning."
		options[0] = {"label":"Portage around the rapids · %d days" % int(RIVER.portage_days), "action":"leave", "effects":{"days":int(RIVER.portage_days)}}
		options.insert(1,{"label":"Run the rapids · steer the raft · 1 day"+(" · icy water" if not river_winter().is_empty() else ""), "action":"leave", "effects":{"days":1}, "rafting":true})
	if node.has("toll_dollars"):
		var toll := (0.0 if state.vehicle=="foot" else float(node.toll_dollars)*Train.count(state)) + float(node.get("toll_per_ox",0)) * (int(state.oxen)+livestock.count(state,"dairy_cows")+livestock.count(state,"goats"))
		options[0].label = "Pay Barlow toll · $%.2f, then continue" % toll
		if state.vehicle=="foot":options[0].label="Continue on foot · no wagon toll" if toll==0 else "Pay stock toll · $%.2f" % toll
		options[0]["requires"] = {"money":toll}
		options[0]["effects"] = {"money":-toll}
	# A post's store counter opens from the STORE button beside the stop, not from this menu.
	if node.has("advice"):
		options.append({"label":"Read trail notes", "action":"notes"})
	if node.id == "fort_kearny" and int(calendar().month) < 6 and int(calendar().year) == 1848:
		description += "\nYou arrive before June; construction has not yet begun."
	if node.id=="columbia_raft" and Direction.heading(self)=="west" and native_encounters.refusal(self,"columbia_raft").is_empty():options.append(native_encounters.portage_choice(self))
	options.append_array(context.activity_choices(self))
	if context.data.horse_traders.has(node.id):options.append({"label":"Trade for horses with the %s" % context.data.horse_traders[node.id].name,"action":"trade","horse_traders":true})
	options.append({"label": "Rest here · 1 day, food consumed", "action": "rest"})
	pending = {"id": "stop_" + node.id, "landmark": node.id, "title": node.name, "text": description, "choices": options}
	Direction.adapt_stop(self,pending,approach)

func _choose_landmark(index: int) -> bool:
	refresh_stop_offers()
	var choice: Dictionary = pending.choices[index]
	var support_factor: float=crossing_support_factor()
	if choice.action=="leave" and not characters.departure_candidates(self).is_empty():return open_departure_review()
	if choice.action == "trade" and choice.get("horse_traders",false):
		return open_horse_traders()
	if choice.action == "trade":
		return open_trade()
	if choice.action == "notes":
		pending.text = route.nodes[state.landmark].text + "\n\n" + choice.get("text",route.nodes[state.landmark].get("advice",""))
		# Word of the party travels with everyone on the road; travelers camped here repeat what has reached them.
		if not crime.talk(self,str(state.landmark)).is_empty():pending.text+="\n\nTalk around the fires: "+crime.talk(self,str(state.landmark))
		return true
	if choice.action == "activity":
		context.record.activities.append(choice.activity)
		if context.data.activities[choice.activity].kind=="prepare":context.record.prepared.append(choice.activity)
		grazing_activity=context.data.activities[choice.activity].kind=="graze"
		_apply(choice.effects,"injuries",choice.get("rest",false))
		grazing_activity=false
		journal.append("Day %d · %s" % [state.day,choice.result])
		if state.status=="traveling":
			_update_river_stage()
			pending.text+="\n\n"+choice.result+(" Crossing preparation is complete; water still poses a risk." if context.data.activities[choice.activity].kind=="prepare" else " The animals spent a day at the grazing camp.")
		return true
	if choice.action == "rest":
		_tick_day(true,false,"rest")
		_update_river_stage()
		journal.append("Day %d · Rested at %s." % [state.day, route.nodes[state.landmark].name])
		if not crime.check_pursuit(self):crime.check_wanted(self)
		return true
	if choice.get("rafting",false) or choice.has("portage_risk"):
		return start_rafting()
	last_crossing = {}
	if choice.action == "cross":
		last_crossing = {"method": choice.method, "place": route.nodes[state.landmark].name, "mishap": false, "lost": false, "stage": state.river_stage}
	if choice.get("native_portage",false):journal.append("Day %d · Hired Upper Chinookan crews for %d wagonload(s), $%.2f. Portage labor and time are paid; the rapids are bypassed." % [state.day,maxi(1,wagon_count()),-float(choice.effects.money)])
	if choice.get("native_portage",false):native_encounters.Story.redeem_portage(native_encounters,self)
	_apply(choice.get("effects", {}), "injuries", choice.get("rest", false))
	if state.status == "traveling" and choice.has("descent_risk") and rng.randf() < choice.descent_risk:
		var descent_food_before: int = state.food
		var descent_wheels_before: int = state.wheels
		_apply({"food":-20,"wheels":-1,"health":-8},"descent injuries")
		journal.append("Day %d · A wagon slips on Laurel Hill. Lost %d lb food and %d spare wheel(s); the party suffers injuries." % [state.day,descent_food_before-int(state.food),descent_wheels_before-int(state.wheels)])
	# Track accident damage separately from the day's rations and ordinary strain.
	var food_before: int = state.food
	var health_before: int = state.health
	var clothing_before: int = state.clothing
	if state.status=="traveling" and choice.has("risk") and Train.count(state)>1:
		_train_crossing(choice,support_factor)
	elif state.status == "traveling" and choice.has("risk") and rng.randf() < float(choice.risk)*support_factor:
		_apply({"food": -30, "health": -15, "clothing": -1}, "crossing injuries")
		last_crossing.mishap = true
		# Swimming stock in high water: the current takes an animal.
		if choice.method=="horses" and last_crossing.stage=="high" and Mounts.animals(state)>0:
			var kind: String="mules" if Mounts.count(state,"mules")>0 and (Mounts.count(state,"horses")==0 or rng.randf()<0.4) else "horses"
			state[kind]=int(state[kind])-1
			team_conditions.sync(self)
			last_crossing["animal_lost"]=kind
	if not last_crossing.is_empty():
		livestock.cross(self,last_crossing)
		dogs.cross(self,last_crossing)
		last_crossing.merge({"day": state.day, "landmark": state.landmark,
			"food_lost": food_before - int(state.food),
			"clothing_lost": clothing_before - int(state.clothing),
			"health_lost": maxi(0, health_before - int(state.health)), "lost": state.status == "lost"}, true)
		last_crossing["summary"] = crossing_summary(last_crossing)
		crossing_history.append(last_crossing.duplicate(true))
		journal.append("Day %d · %s" % [state.day, last_crossing.summary])
	if state.status != "traveling":
		if not last_crossing.is_empty():
			last_crossing.lost = true
		pending = {}
		return true
	if not last_crossing.is_empty():
		journal.append("Crossed %s by %s." % [last_crossing.place, last_crossing.method])
	journal.append("Leaving " + route.nodes[state.landmark].name + ".")
	pending = {}
	_set_next_leg(int(choice.get("edge", 0)))
	if int(choice.get("edge", 0)) > 0:
		journal.append("Day %d · Took the road toward %s." % [state.day, route.nodes[state.next_landmark].name])
	_schedule_event(false)
	return true

func crossing_support_factor() -> float:
	return minf(context.crossing_factor(str(state.landmark)),native_encounters.guidance_factor(self))

func _train_crossing(choice: Dictionary,support_factor: float=1.0) -> void:
	last_crossing["wagons"]=[]
	for wagon in state.wagon_train:
		var mishap: bool=rng.randf()<float(choice.risk)*support_factor
		last_crossing.wagons.append({"wagon":int(wagon.id),"driver":int(wagon.driver),"mishap":mishap})
		if not mishap:continue
		last_crossing.mishap=true
		_apply({"food":-30,"clothing":-1},"crossing injuries")
		var driver: Dictionary=party_health.members[int(wagon.driver)]
		if party_health.is_active(driver):party_health.affect(driver,-15,int(state.day),"crossing injuries")
	_collect_health_events()
	state.health=party_health.average_health();state.party_size=party_health.living_count()
	_check_health()

func crossing_summary(result: Dictionary) -> String:
	var method: String = {"ford": "fording", "float": "floating", "ferry": "ferry", "seized": "working the taken ferry","swim":"swimming with packs","wade":"wading with packs","horses":"swimming the horses" if result.get("stage","")=="high" else "fording with the horses"}.get(result.method,str(result.method))
	var text := "%s · %s. " % [result.place, method]
	if result.mishap:
		text += "Crossing mishap! Cargo washes away. Lost %d lb food and %d clothing set(s); the party suffered injuries. " % [result.food_lost, result.get("clothing_lost", 0)]
		if result.has("animal_lost"):text += "A %s was swept downstream and drowned. " % ("mule" if result.animal_lost=="mules" else "horse")
	else:
		text += "No cargo lost. "
	if result.has("wagons"):text += "%d of %d wagons had mishaps. " % [result.wagons.filter(func(w):return w.mishap).size(),result.wagons.size()]
	if result.has("dog_lost"):text += "%s was lost in the river. " % result.dog_lost
	text += "The journey ended during this crossing." if result.lost else "The party reached the far bank."
	return text

func party_condition() -> String:
	return PartyHealth.condition_label(state.health)

func _change_health(delta: int, cause: String) -> void:
	if party_health.members.is_empty():
		state.health = clampi(int(state.health) + delta, 0, 100)
	else:
		party_health.affect_all(delta, state.day, cause)
		_collect_health_events()
		state.health = party_health.average_health()
		state.party_size = party_health.living_count()

func _collect_health_events() -> void:
	for entry in party_health.notices:
		journal.append(entry)
		health_events.append(entry)
	party_health.notices.clear()
	Remains.sync(self)

func configure(pace: int, rations: int) -> void:
	if _can_act():
		state.pace = clampi(pace, 0, 2)
		state.rations = clampi(rations, 0, 2)

func travel() -> bool:
	if _can_act() and not Train.ready(self).is_empty():
		pending={"id":"train_unready","title":"Reorganize the wagon train","text":Train.ready(self),"choices":[{"label":"Return to camp","effects":{},"result":"The train remains stopped."}]}
		return true
	if camp_repair.blocked(self):return false
	if _can_act() and field_outings.warn(self):return true
	if not _can_act():
		return false
	if walking_overloaded():return true
	if state.extended_route and Direction.heading(self)=="east" and state.leg_miles==0:
		if travelled_path().size()<2:Direction.end_east(self)
		else:_arrive_landmark(true)
		return true
	var on_river: bool = state.extended_route and current_edge().get("hazard","") == "river"
	if state.extended_route and not on_river and state.vehicle!="foot" and (team_conditions.pulling(state) == 0 or state.ox_health == 0):
		pending = {"id": "no_team", "title": "No team to pull the wagon", "text": "Trade for an ox, rest a worn team, or abandon the wagon through Provisions / Cargo.", "choices": [{"label": "Return to camp", "effects": {}, "result": "The wagon stays in camp."}]}
		return true
	var snow: Dictionary=snow_country()
	if not snow.is_empty() and rng.randf()<float(snow.get("snowbound_chance",0)):
		_tick_day(false,false)
		if state.status=="traveling":journal.append("Day %d · Snowbound near %s: drifts block the road and the party makes no miles." % [state.day,route.nodes[snow.place].name])
		return true
	# Winter on the Columbia: wind and running ice pin the raft to the shore, and the cold wears on everyone afloat.
	var river_cold: Dictionary=river_winter() if on_river else {}
	if not river_cold.is_empty():
		_change_health(-int(river_cold.chill_damage),"cold on the river")
		if state.status!="traveling":return true
		var pinned: float=float(river_cold.ice_bound_chance if river_frozen() else river_cold.windbound_chance)
		if rng.randf()<pinned:
			_tick_day(false,false)
			if state.status=="traveling":journal.append("Day %d · %s pins the raft to the shore; the party makes no miles." % [state.day,"Running ice" if river_frozen() else "A hard east wind"])
			return true
	var pace_miles: int = int(survival.data.pace_miles[state.pace]) if state.extended_route else PACE_MILES[state.pace]
	var distance: int = pace_miles + rng.randi_range(-2, 2)
	if state.vehicle == "corolla":
		if state.fuel > 0:
			distance = 30
			state.fuel -= 1
		else:
			state.vehicle = "wagon"
			journal.append("The Corolla is out of fuel. You unhitch the wagon and continue with oxen.")
	if state.extended_route:
		# On the river the current carries the party; the team rides or is driven alongside.
		field_outings.moving=true
		_tick_day(false, not on_river)
		field_outings.moving=false
		if state.status != "traveling":
			return true
		if walking_overloaded():return true
		if not Train.ready(self).is_empty():
			pending={"id":"train_unready","title":"Reorganize the wagon train","text":Train.ready(self),"choices":[{"label":"Return to camp","effects":{},"result":"The train remains stopped."}]}
			return true
		if on_river:distance=maxi(1,roundi((int(RIVER.miles)+rng.randi_range(-2,2))*float(survival.weather.speed)))
		elif state.vehicle=="foot":distance=walking_distance()
		elif Train.count(state)>1:distance=maxi(1,roundi(distance*Train.speed(self)))
		else:distance = maxi(1, roundi(distance * survival.movement_factor(team_conditions.pulling(state), state.ox_health, state.fatigue, 0, state.terrain, int(calendar().month), context.region(self)) * provisions.movement_factor(provisions.cargo(state),team_conditions.pulling(state))))
		var east: bool=Direction.heading(self)=="east"
		distance=mini(distance,int(state.leg_miles) if east else int(state.leg_length)-int(state.leg_miles))
		distance=Direction.clamp_at_cache(self,distance)
		distance=field_outings.clamp_distance(self,distance)
		state.leg_miles+=-distance if east else distance
		state.miles+=-distance if east else distance
		if state.has("trail_history"):Direction.remember(self)
		if east and state.leg_miles==0:state["east_arrival"]=true
		if not wagon_cache.is_empty():wagon_cache.found=false
		field_outings.resolve_returns(self)
	else:
		state.miles = mini(DESTINATION, state.miles + distance)
		_tick_day(false)
	journal.append("Day %d · Traveled to mile %d. Food remaining: %d units." % [state.day, state.miles, state.food])
	if state.status == "traveling" and not crime.check_pursuit(self) and not crime.check_wanted(self):
		if not field_outings.camp_notice(self) and not Direction.cache_notice(self):_schedule_event()
	return true

func rest() -> bool:
	if not _can_act():
		return false
	_tick_day(true,false,"rest")
	journal.append("Day %d · Rested in camp. Food remaining: %d units." % [state.day, state.food])
	if state.status == "traveling" and not crime.check_pursuit(self) and not crime.check_wanted(self):
		_schedule_event()
	return true

func rest_in_camp() -> bool:
	# A stopped landmark keeps its crossing/trading choices after a rest day.
	if pending.has("landmark"):
		for index in range(pending.choices.size()):
			if pending.choices[index].get("action", "") == "rest":
				return choose(index)
		return false
	return rest()

func can_choose(index: int) -> bool:
	if not raft.is_empty() or pending.is_empty() or index < 0 or index >= pending.choices.size() or state.status != "traveling":
		return false
	var choice: Dictionary = pending.choices[index]
	if choice.has("bandit_payment") and (pending.id!="bandits" or not combat.BanditDemand.valid_choice(choice) or (choice.get("bandit_wagon",false) and state.vehicle!="wagon")):return false
	if pending.get("native_menu",false):return native_encounters.can_choose(self,index)
	if choice.has("native_portage") and not native_encounters.valid_portage(self,choice):return false
	if pending.get("recruit_menu",false) or pending.get("dismiss_menu",false):return recruitment.can_choose(self,index)
	if pending.get("crime_menu",false):return crime.can_choose(self,str(choice.get("crime_command","")))
	if pending.get("riders_menu",false):return crime.Wanted.can_choose_rider(self,index)
	if pending.get("attack_menu",false):return int(choice.get("attack_target",-1))<0 or (crime.attack_ready(self,int(choice.attack_target)) and (choice.get("unarmed",false) or can_fire()))
	if pending.get("remains_menu",false):return Remains.can_choose(self,str(choice.get("remains_command","")),int(choice.get("remains_id",0)),int(choice.get("member",-1)))
	if camp_repair.blocked(self) and choice.get("action","") in ["leave","cross"]:return false
	if choice.has("camp_repair_part") and (state.vehicle!="wagon" or not camp_repair.work.is_empty()):return false
	if choice.get("care",0)==12 and not context.local_care(self):return false
	if choice.get("action","")=="cross" and not Train.ready(self).is_empty():return false
	if choice.has("seasonal_road") and road_closed(str(choice.seasonal_road)):return false
	if (choice.get("river_leg",false) or choice.get("rafting",false)) and river_frozen():return false
	if choice.get("method","")=="ferry" and crime.ferry_refused(self,str(state.landmark)):return false
	if not context.can_trade(choice) or not crime.can_trade(self,choice) or (choice.has("activity") and choice.activity in context.record.activities):return false
	for key in choice.get("requires", {}):
		if state.get(key, 0) < choice.requires[key]:
			return false
	return true

func choose(index: int) -> bool:
	if not tactical_session.is_empty():
		tactical_session = {}
	if pending.get("outing_warning",false):return field_outings.choose_warning(self,index)
	if not can_choose(index):
		return false
	var outward: Dictionary=pending.choices[index]
	var flight: bool=outward.get("crime_command","") in ["flee","ride","breakout"]
	var boundary: bool=outward.get("action","")=="cross" or (outward.get("action","")=="leave" and route.nodes[state.landmark].next.size()>1)
	if (outward.get("action","") in ["leave","cross"] or flight) and field_outings.warn(self,flight,boundary):return true
	if pending.get("native_menu",false):return native_encounters.choose(self,index)
	if pending.get("recruit_menu",false) or pending.get("dismiss_menu",false):return recruitment.choose(self,index)
	if pending.get("crime_menu",false):return crime.choose(self,str(pending.choices[index].crime_command))
	if pending.get("riders_menu",false):return crime.Wanted.choose_rider(self,index)
	if pending.get("attack_menu",false):return crime.choose_attack(self,index)
	if pending.get("remains_menu",false):return Remains.choose(self,index)
	if pending.get("service_menu", false):
		return _choose_service(index)
	if pending.has("landmark"):
		field_outings.moving=outward.get("action","") in ["leave","cross"]
		var chosen: bool=_choose_landmark(index)
		field_outings.moving=false
		field_outings.resolve_returns(self)
		return chosen
	var choice: Dictionary = pending.choices[index]
	if choice.has("carcass_meat"):return _butcher_carcass(choice)
	if choice.get("camp_repair_part","") in camp_repair.PARTS:
		if not camp_repair.queue(self,str(choice.camp_repair_part)):return false
		pending={}
		return true
	var member_id: int = pending.get("member_id", 0)
	var fight_id: String=pending.id
	var friendly: bool=pending.get("friendly",false)
	var hit:=false
	if friendly:
		journal.append("The riders proved friendly. Any ammunition or time spent was still used.")
	_apply(choice.get("effects", {}), "injuries", choice.get("rest", false))
	if choice.get("bandit_payment",false):combat.BanditDemand.finish(self,choice)
	journal.append(choice.result)
	if choice.has("risk") and rng.randf() < choice.risk.probability:
		hit=true
		_apply(choice.risk.effects)
		journal.append(choice.risk.text)
		if choice.risk.has("victim_damage"):
			var victim: Dictionary=party_health.members[member_id]
			if victim.alive:
				victim.history.append("Day %d · Hit during an armed confrontation." % state.day)
				party_health.affect(victim,-int(choice.risk.victim_damage),state.day,"confrontation injuries")
		if choice.risk.has("condition"):
			var severity: int=choice.risk.get("severity",1)
			if not party_health.begin_condition(member_id, choice.risk.condition, state.day,severity):
				for active in party_health.members[member_id].conditions:
					if active.id==choice.risk.condition:active.severity=maxi(active.severity,severity)
		_collect_health_events()
		if not party_health.members.is_empty():
			state.health=party_health.average_health()
			state.party_size=party_health.living_count()
	if choice.has("combat"):
		var outcome: String="friendly" if friendly else (("fatal" if not party_health.members[member_id].alive else "injured") if hit else ("won" if choice.combat=="defend" else "deterred"))
		combat.history.append({"day":int(state.day),"event":fight_id,"tactic":choice.combat,"outcome":outcome,"victim":member_id,"risk":float(choice.get("quoted_risk",choice.risk.probability))})
		if not friendly and choice.combat=="defend":characters.defense(self)
		journal.append("Day %d · Defense outcome: %s. %s" % [state.day,outcome,(party_health.members[member_id].name+(" died during this encounter." if outcome=="fatal" else " was wounded; inspect their condition.")) if hit else ("The riders were friendly." if friendly else "No traveler was injured in this confrontation.")])
	pending = {}
	_check_health()
	if state.status == "traveling":
		if choice.get("complete", false):
			state.status = "arrived"
		else:
			_schedule_event(false)
	return true

func wagon_count() -> int:return Train.count(state)

func _can_act() -> bool:
	return pending.is_empty() and state.status == "traveling" and hunt.is_empty() and raft.is_empty()

func _tick_day(resting: bool, team_working: bool = false, camp_action: String = "") -> void:
	if not team_conditions.valid(team_conditions.record,state):team_conditions.start_legacy(self)
	state.erase("camp_watch_day")
	state.erase("camp_watch_member")
	var wagon_hunt: bool=camp_action=="hunt" and hunt.get("field",{}).get("kit","")=="wagon"
	if not (camp_action=="leathercraft" and leathercraft.worker!=camp_tasks.leader_id(self)) and not (camp_action=="settlement_work" and not income.is_working(camp_tasks.leader_id(self))) and not wagon_hunt and (not resting or (not camp_action.is_empty() and camp_action!="rest")):camp_tasks.end_leader_nursing(self)
	if state.extended_route and not camp_action.is_empty():camp_tasks.begin(self,camp_action)
	var sick_before: bool=characters.has_sick(self)
	state.day += 1
	if not camp_tasks.day_plan.is_empty():camp_tasks.prepare(self)
	if state.extended_route:
		var climate: Dictionary=context.region(self).duplicate()
		climate.id=context.region_id(self)
		survival.advance(int(calendar().month), state.terrain, climate)
		state.weather = survival.weather.label
		# Riders tire more slowly than walkers or wagon drivers.
		var riding: bool=team_working and Mounts.mounted(mount_plan())
		state.fatigue = clampi(int(state.fatigue) + ((1 + int(state.pace) if riding else 2 + int(state.pace) * 2) if team_working else (-14 if resting else -6)), 0, 100)
		# Standing watch over the stock costs sleep every night.
		if not camp_tasks.enabled() and state.get("night_guard",false) and Mounts.animals(state)>0:state.fatigue=mini(100,int(state.fatigue)+int(provisions.data.mounts.guard_fatigue))
		var pasture: Dictionary=pasture_assessment()
		if not team_working and not pasture.waterless:
			state.ox_health=mini(100,int(state.ox_health)+(int(pasture.ox_rest_recovery) if resting else mini(2,int(pasture.ox_rest_recovery))))
		elif state.vehicle!="foot":
			state.ox_health=maxi(0,int(state.ox_health)-int(pasture.ox_work_strain))
		_tick_mounts(resting,team_working)
		team_conditions.settle(self,false,team_working and state.vehicle!="foot",(int(pasture.ox_rest_recovery) if resting else mini(2,int(pasture.ox_rest_recovery))) if not team_working and not pasture.waterless else -1)
		_snow_starvation()
	if state.extended_route:
		var spoiled := provisions.spoil(int(state.day), int(state.food))
		if spoiled > 0:
			state.food -= spoiled
			journal.append("Day %d · Discarded %d ration-lb spoiled meat." % [state.day, spoiled])
			supply_history.append({"day":state.day,"event":"spoilage","changes":{"food":-spoiled}})
		Remains.spoil(self)
		livestock.tick(self,resting,team_working)
	var needed: int = (int(provisions.data.rations_lb[state.rations]) if state.extended_route else RATION_LB[state.rations]) * state.party_size
	# Those chosen to eat human meat are fed from it first; nobody else is ever served it.
	if state.extended_route:needed-=Remains.serve(self)
	var fed: bool = state.food >= needed
	var eaten: float = mini(int(state.food), needed)
	var vitamin_coverage: float=-1.0
	if state.extended_route:
		# Count vitamin-C produce actually consumed, never merely carried or fresh meat.
		var field_before: int=provisions.fresh.filter(func(b):return b.get("_hunt_meal",false)).reduce(func(n,b):return n+int(b.pounds),0)
		var loose: int=int(state.get("camp_greens_lb",0))
		if int(state.get("camp_greens_expires",0))<=int(state.day):loose=0
		if state.has("camp_greens_lb"):
			state.camp_greens_lb=0
			state.camp_greens_expires=0
		var meal: Dictionary=livestock.meal(self,needed,float(loose))
		eaten=float(meal.eaten);fed=eaten>=needed-0.000000001
		var produce_eaten: float=float(meal.vitamin)
		vitamin_coverage=clampf(produce_eaten/maxf(0.000001,state.party_size*float(provisions.data.foraging.vitamin_c_lb_per_person)),0.0,1.0)
		if not hunt.is_empty():hunt["_meal_food"]=field_before-provisions.fresh.filter(func(b):return b.get("_hunt_meal",false)).reduce(func(n,b):return n+int(b.pounds),0)-float(meal.get("hunt_fraction",0))
		party_health.feed_vitamins(vitamin_coverage)
	if not state.extended_route:state.food = maxi(0, state.food - needed)
	if state.extended_route:
		dogs.tick(self,resting,team_working,camp_action=="hunt" and hunt.has("dog"))
		livestock.pack(self)
	var recovered_food: bool=provisions.Shortfall.tick(self,eaten,needed) if state.extended_route else true
	if not fed:
		if not state.extended_route:_change_health(-18,"lack of food")
	elif not camp_tasks.day_plan.is_empty():
		for member in party_health.members:
			if not party_health.is_active(member):continue
			var rests: bool=camp_tasks.day_plan.rest.get(int(member.id),false)
			var change: int=int(survival.data.rest_recovery[state.rations]) if rests else [-3,0,1][state.rations]-[0,1,4][state.pace]
			party_health.affect(member,change if recovered_food else mini(0,change),state.day,"ill health" if rests else "exhaustion")
	elif resting:
		if recovered_food:_change_health(int(survival.data.rest_recovery[state.rations]) if state.extended_route else 7,"ill health")
	else:
		var change: int=[-3,0,1][state.rations]-[0,1,4][state.pace]
		_change_health(change if recovered_food else mini(0,change),"exhaustion")
	if not party_health.members.is_empty():
		# A finished cabin keeps out the storms and the cold, and the winter sickness that comes with them.
		var sheltered: bool=Cabins.sheltered(self)
		var storm_damage: int=int(seasonal_pressure().storm_damage) if state.extended_route and not sheltered else 0
		if storm_damage>0:_change_health(-storm_damage,"winter exposure")
		# No water and little grass: animals get no recovery and people go thirsty.
		if state.extended_route and current_edge().get("hazard","")=="waterless":_change_health(-int(WATERLESS.thirst),"thirst")
		var unprotected: int = maxi(0, int(state.party_size) - int(state.clothing))
		if sheltered:unprotected=0
		if unprotected > 0 and int(survival.weather.exposure) > 0:
			var exposed := 0
			for member in party_health.members:
				if party_health.is_active(member) and exposed < unprotected:
					party_health.affect(member, -int(survival.weather.exposure), state.day, "exposure")
					exposed += 1
		var nutrition: int = state.rations if fed else 0
		var risk_multiplier: float = [2.0, 1.3, 0.7][nutrition] * (0.6 if resting else 1.0) * (1.4 if unprotected and survival.weather.exposure else 1.0) * float(survival.weather.get("illness_risk",1.0))
		if sheltered and int(calendar().month) in survival.data.seasonal.winter_months:risk_multiplier*=float(Cabins.data.winter_illness_factor)
		party_health.tick(state.day, resting, risk_multiplier, nutrition, int(calendar().year), int(calendar().month) if state.extended_route else 0, context.region_id(self) if state.extended_route else "", party_health.days_without_fresh,camp_tasks.day_plan.get("rest",{}),vitamin_coverage)
		_collect_health_events()
		state.health = party_health.average_health()
		state.party_size = party_health.living_count()
	_check_health()
	var camp_rest: Dictionary=camp_tasks.day_plan.get("rest",{}).duplicate()
	if state.extended_route and not camp_tasks.day_plan.is_empty():camp_tasks.finish(self)
	if state.extended_route and camp_rest.is_empty():camp_tasks.other_day_watch(self)
	if state.extended_route:social.tick(self,resting,fed)
	if state.extended_route:Guards.tick(self)
	if state.extended_route:field_outings.tick(self)
	characters.daily(self,resting,team_working,sick_before,camp_rest)
	if state.extended_route:crime.check_betrayal(self)
	if state.extended_route:
		journal.append("Day %d · %s. Team condition %s; %s." % [state.day, state.weather, PartyHealth.condition_label(state.ox_health).to_lower(), "working" if team_working else "resting"])

## Saddle and pack animals wear down while they carry and recover in camp or when only led.
func _tick_mounts(resting: bool,team_working: bool) -> void:
	if Mounts.animals(state)==0:return
	var rules: Dictionary=provisions.data.mounts
	var plan: Dictionary=mount_plan()
	var pasture: Dictionary=pasture_assessment()
	var waterless: bool=pasture.waterless
	if team_working and not Mounts.mounted(plan) and plan.mode!="packing":return
	if not team_working:
		if not waterless:state["horse_health"]=mini(100,Mounts.condition(state)+(mini(int(rules.rest_recovery),int(pasture.ox_rest_recovery)) if resting else 1))
		return
	var base: int=pasture.base_work_strain
	var load_ratio: float=provisions.load_profile(state).ratio
	var strain: int=Mounts.wear(rules,plan,context.region_id(self),base,int(state.pace),load_ratio)
	state["horse_health"]=maxi(0,Mounts.condition(state)-strain)
	if state.horse_health==0:Mounts.breakdown(self)
func mount_plan() -> Dictionary:return Mounts.plan(provisions.data.mounts,state)
## Someone stands watch over the horses and mules each night. Costs no time.
func set_night_guard(on: bool) -> bool:
	if Mounts.animals(state)==0 and on:return false
	state["night_guard"]=on
	journal.append("Day %d · %s" % [state.day,"Someone will stand watch over the stock each night." if on else "No more night watch over the stock."])
	return true
## Two riders to a saddled animal when there are too few saddles. Costs no time.
func set_double_up(on: bool) -> bool:
	if Mounts.animals(state)==0 and on:return false
	state["double_up"]=on
	journal.append("Day %d · %s" % [state.day,"Riders will double up on the saddled animals." if on else "No more doubling up; those without a saddle walk."])
	return true

func _check_health() -> void:
	state.health = clampi(state.health, 0, 100)
	# The leader is the player. When they die the journey ends, whoever else is left.
	var leader: Dictionary=party_health.members[0] if not party_health.members.is_empty() else {}
	if state.status=="traveling" and state.extended_route and not leader.is_empty() and not leader.alive and not state.get("leader_succession",false):
		state.status="lost"
		state.loss_reason="%s, the party's leader, died of %s. The journey is over." % [leader.name,leader.cause]
		pending={}
		return
	if state.health == 0:
		state.status = "lost"
		if state.loss_reason.is_empty():
			state.loss_reason = "No one in the party can continue. Consult the party records for their last days."
		pending = {}
		if party_health.members.any(func(member):return member.get("departed",false)):state.loss_reason="No travelers remain with the wagon. Departures and deaths are recorded separately in View Party."

func _apply(effects: Dictionary, health_cause: String = "injuries", resting: bool = false, camp_action: String = "") -> void:
	if team_conditions.record.oxen.size()!=int(state.oxen):team_conditions.start_legacy(self)
	var before := state.duplicate(true)
	for key in effects:
		if key == "item":
			if effects[key] not in state.items:
				state.items.append(effects[key])
		elif key == "vehicle":
			state.vehicle = effects[key]
			if state.vehicle=="foot" and state.has("wagon_train"):state.wagon_train=[];state.erase("repair_wagon_id")
		elif key == "money":
			state.money = maxf(0.0, snappedf(float(state.money) + float(effects[key]), 0.01))
		elif key == "health":
			_change_health(int(effects[key]), health_cause)
		elif key != "days":
			state[key] = maxi(0, int(state.get(key, 100 if key == "horse_health" else 0) + effects[key]))
	if state.extended_route and effects.has("food") and state.food < before.food:
		provisions.remove(int(before.food) - int(state.food))
	if effects.has("wheels") or effects.has("axles") or effects.has("tongues"):
		state.parts = state.wheels + state.axles + state.tongues
	state.ox_health = clampi(int(state.ox_health), 0, 100)
	if state.has("horse_health"):state.horse_health = clampi(int(state.horse_health), 0, 100)
	if state.extended_route:
		var changes: Dictionary = {}
		var lines: Array[String] = []
		for key in ["food", "money", "bullets", "medicine", "clothing", "oxen", "wheels", "axles", "tongues", "salt"]+Mounts.KEYS+livestock.GOODS+provisions.data.pelts.goods.keys()+income.all_keys()+leathercraft.items():
			var delta := float(state.get(key,0)) - float(before.get(key,0))
			if key=="money":delta=roundi(delta*100)/100.0
			if not is_zero_approx(delta):
				changes[key] = delta
				var name: String = {"food": "Food (lb)", "money": "Cash ($)", "medicine": "Care kits"}.get(key, str(key).capitalize())
				lines.append("%s %+.2f" % [name, delta] if key == "money" else "%s %+d" % [name, int(delta)])
		if not changes.is_empty():
			supply_history.append({"day": state.day, "event": pending.get("id", "trail"), "changes": changes})
			journal.append("Day %d · Supplies: %s. Daily rations counted separately." % [state.day, "; ".join(lines)])
	team_conditions.settle(self,pending.get("id","")=="ox_injury")
	livestock.sync(self)
	# Delay is ordinary elapsed time: it consumes rations and cannot revive a lost party.
	for day in range(int(effects.get("days", 0))):
		if state.status != "traveling":
			break
		_tick_day(resting,false,camp_action)
	_check_health()

func _schedule_event(allow_random: bool = true) -> void:
	if not health_events.is_empty():
		pending = {"id": "party_health", "title": "News from your party", "text": "\n".join(health_events),
			"choices": [{"label": "Acknowledge", "result": "The party takes stock before continuing.", "effects": {}}]}
		health_events.clear()
		return
	if state.extended_route and state.get("east_arrival",false):
		state.erase("east_arrival")
		_arrive_landmark(true)
		return
	if state.extended_route and Direction.heading(self)=="west" and state.leg_miles >= state.leg_length:
		_arrive_landmark()
		return
	# Deterministic thresholds take priority; unshown due events remain queued by eligibility.
	for event in catalog.events:
		if state.extended_route and event.id == "kansas_river":
			continue # Legacy first-leg fixture only; researched route owns river stops.
		if event.id in seen or event.category != "historical":
			continue
		# A cracked wheel needs a wagon; it waits until the party has one again.
		if state.vehicle=="foot" and event.id=="muddy_trail":continue
		if (event.trigger == "day" and state.day >= event.at) or (event.trigger == "mile" and state.miles >= event.at):
			_present(event)
			return
	if allow_random and state.mode == "unhinged":
		var event := roll_absurd(rng.randf())
		if not event.is_empty():
			_present(event)
	if allow_random and state.extended_route and pending.is_empty() and survival.rng.randf() < survival.data.event_chance * (float(UNREST.chance_factor) if current_edge().get("hazard","")=="unrest" else 1.0):
		_roll_trail_event()

func roll_absurd(roll: float) -> Dictionary:
	# One Bernoulli roll per travel/rest day; uniform among unseen examples.
	if state.mode != "unhinged" or roll < 0.0 or roll >= ABSURD_CHANCE:
		return {}
	var candidates: Array = []
	for event in catalog.events:
		if event.category == "absurd" and event.id not in seen:
			candidates.append(event)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

func _present(event: Dictionary) -> void:
	pending = event.duplicate(true)
	seen.append(event.id)
	journal.append("Encounter · " + event.title)

func _roll_trail_event() -> void:
	var candidates: Array = []
	var weight := 0
	for event in trail_events.events:
		if camp_repair.blocked(self) and event.id=="breakdown":continue
		if state.vehicle=="foot" and event.id in ["breakdown","wagon_fire","swamped_load","hail_damage"]:continue
		if state.oxen==0 and event.id=="ox_injury":continue
		if state.oxen<2 and event.id=="stampede":continue
		if event.id=="horse_thieves" and Mounts.animals(state)==0:continue
		if current_edge().get("hazard","")=="river" and event.id in ["breakdown","ox_injury","wandering_ox","stampede"]:continue
		# Encounters tied to a kind of road happen only on that road.
		if event.has("hazard") and current_edge().get("hazard","")!=event.hazard:continue
		if not survival.eligible(event, state.day) or (event.id == "wandering_ox" and state.oxen == 0):
			continue
		var weighted: Dictionary=event
		# Unsettled country (the Cayuse War detour): more trouble on the road.
		if current_edge().get("hazard","")=="unrest" and event.id in UNREST.events:
			weighted=event.duplicate(true)
			weighted.weight=int(event.weight)*int(UNREST.weight_factor)
		# A night guard on the picket line keeps most horse thieves away.
		if event.id=="horse_thieves" and camp_tasks.stock_guarded(self):
			weighted=weighted.duplicate(true)
			# Thieves give a soldier's watch a wider berth.
			weighted.weight=maxi(1,int(weighted.weight)/(int(provisions.data.mounts.guard_factor)*(int(characters.benefits.soldier_guard_factor) if characters.available(self,"Soldiering") else 1)))
		if event.id=="horse_thieves" and dogs.ready("watch"):
			weighted=weighted.duplicate(true)
			weighted.weight=maxi(1,int(float(weighted.weight)/float(dogs.data.theft_weight_factor)))
		candidates.append(weighted)
		weight += int(weighted.weight)
	if weight == 0:
		return
	var roll: int = survival.rng.randi_range(1, weight)
	for event in candidates:
		roll -= int(event.weight)
		if roll <= 0:
			_present_trail_event(event)
			return

func _present_trail_event(event: Dictionary) -> void:
	var content := event.duplicate(true)
	adapt_travel_event(content)
	var living: Array[int] = []
	for member in party_health.members:
		if party_health.is_active(member):
			living.append(int(member.id))
	if living.is_empty():
		return
	var member_id: int = living[survival.rng.randi_range(0, living.size() - 1)]
	var part: String = ["wheels", "axles", "tongues"][survival.rng.randi_range(0, 2)]
	var singular: String = {"wheels": "wheel", "axles": "axle", "tongues": "tongue"}[part]
	content.text = content.text.replace("{person}", party_health.members[member_id].name).replace("{part}", singular)
	content.member_id = member_id
	if content.has("condition_choices"):
		content.condition = content.condition_choices[survival.rng.randi_range(0, content.condition_choices.size() - 1)]
		content.text = content.text.replace("{injury}", str(party_health.conditions[content.condition].name).to_lower())
	dogs.warn(self,content)
	combat.prepare(self,content)
	if content.id == "riders" and survival.rng.randf() < 0.5:
		# Intentions are a separate hidden draw, not an ethnic identity.
		for option in content.choices:
			if option.has("risk"):
				option.risk.probability = 0.0
		content["friendly"] = true
	for choice in content.choices:
		choice.label = choice.label.replace("{part}", singular)
		if choice.get("service", "") == "repair":
			choice["requires"] = {part: 1}
			choice["effects"] = {part: -1}
		elif content.id=="breakdown" and not camp_tasks.enabled() and characters.available(self,"Carpentry") and choice.get("effects",{}).get("days",0)>1:
			var original_days: int=choice.effects.days
			var days: int=maxi(1,int(choice.effects.days)-int(characters.benefits.carpentry_days_saved))
			choice.effects.days=days
			choice.label=choice.label.replace("%d days" % original_days,"%d day(s)" % days)+" · carpenter"
			choice.result="The repair is complete after %d day(s), with a companion's carpentry." % days
	if content.id=="breakdown":
		content.choices.append({"label":"Make camp and assign a repair crew","camp_repair_part":part,"effects":{},"result":"Stopped to organize the repair."})
	if content.has("condition"):
		var severity: int = party_health.roll_severity(state.rations) if party_health.conditions[content.condition].kind == "illness" else 1
		party_health.begin_condition(member_id, content.condition, state.day, severity)
		# The event itself is the interruption; preserve the personal/journal entry
		# without making a second notification of the same onset.
		for entry in party_health.notices:
			journal.append(entry)
		party_health.notices.clear()
	# Attribute immediate losses to this event before committing them.
	pending = content
	_apply(content.get("onset_effects", {}))
	if state.status != "traveling":
		return
	pending = content
	survival.last_events[content.id] = state.day
	journal.append("Day %d · %s. %s" % [state.day, content.title, content.text])

func can_service() -> bool:
	return state.extended_route and state.status == "traveling" and hunt.is_empty() and raft.is_empty() and (pending.is_empty() or pending.has("landmark"))

func _service_menu(title: String, text: String, options: Array) -> bool:
	if not can_service():
		return false
	service_return = pending.duplicate(true)
	options.append({"label": "Back to the trail", "effects": {}, "result": ""})
	pending = {"id": "trail_service", "service_menu": true, "title": title, "text": text, "choices": options}
	return true

## Read-only seasonal offer. Empty searches still cost a day; river legs cannot be foraged.
func forage_offer(companion: bool=false) -> Dictionary:
	var rules: Dictionary = provisions.data.foraging
	var season: float = rules.months[int(calendar().month)-1]
	var factor: float = season * float(rules.regions.get(context.region_id(self),0))
	var workers := 0.0
	for member in party_health.members:
		if party_health.is_active(member) and not member.conditions.any(func(c): return c.id == "broken_leg") and (companion or not camp_tasks.enabled() or int(member.id)==camp_tasks.leader_id(self)):
			workers += member.health / 100.0 * (float(ProfessionSkill.stockman(self).get("forage_worker_factor",1.0)) if int(member.id)==0 else 1.0)
	var blocked: bool = current_edge().get("hazard", "") in ["river", "waterless"] or survival.weather.id in ["blizzard", "snow"]
	return {"available": factor > 0 and workers > 0 and not blocked, "factor": factor, "workers": workers}

func open_forage() -> bool:
	var offer := forage_offer()
	var options: Array = []
	if offer.available:
		options.append({"label":"Search for greens and berries · 1 day and meals", "foraging":true, "effects":{"days":1}, "result":""})
	return _service_menu("Foraging", "Gather seasonal greens and berries nearby. Yield depends on the season, region and healthy walkers; a search may find little. This supplements meals rather than replacing staple provisions. Produce spoils in three days and provides vitamin C only when eaten. No gathering on waterless or rafting legs, in snow, or outside the growing season." + (" Nothing suitable is available here now." if not offer.available else ""), options)

func _gather_forage(offer: Dictionary, shared: bool=false) -> void:
	if state.status != "traveling": return
	var rules: Dictionary = provisions.data.foraging
	var pounds := mini(int(rules.maximum_lb), floori(rng.randi_range(int(rules.lb_per_worker[0]),int(rules.lb_per_worker[1])) * float(offer.workers) * float(offer.factor)))
	var room := maxf(0, provisions.storage_capacity(state) - provisions.cargo(state))
	pounds = mini(pounds, floori(room))
	if shared or camp_tasks.enabled():
		pounds+=int(state.get("camp_greens_lb",0))
		state.camp_greens_lb=pounds % int(rules.mass_ratio)
		state.camp_greens_expires=int(state.day)+int(rules.fresh_days)+1 if state.camp_greens_lb>0 else 0
	var units: int = provisions.add_produce(pounds,int(state.day))
	state.food += units
	var report := "Foraged %d lb of greens and berries (%d food units)." % [units * int(rules.mass_ratio),units] if units > 0 else ("Gathered %d lb greens for vitamin-C meals (less than one food unit)." % int(state.get("camp_greens_lb",0)) if int(state.get("camp_greens_lb",0))>0 else "The search yielded no usable food within your carrying room.")
	journal.append("Day %d · %s" % [state.day,report])
	if not shared:health_events.append(report)

func open_trade() -> bool:
	if not can_service():return false
	var offer: Dictionary=context.market(self)
	if offer.post and crime.closed(str(state.landmark)):return _service_menu("The store is closed","After the incident, the remaining staff will not trade with your party.",[])
	if offer.post and crime.refuses(self,str(state.landmark)):return _service_menu("The post will not trade",crime.news_text(self,str(state.landmark)),[])
	if offer.available and not offer.post and crime.closed(str(offer.key)):return _service_menu("The traders will not deal with you","These are the traders your party robbed. They keep their rifles close and will not trade.",[])
	if offer.available and not offer.post and crime.refuses(self,str(offer.key)):return _service_menu("The traders will not deal with you",crime.news_text(self,str(offer.key)),[])
	if not offer.available:
		return _service_menu("No traders nearby","No trading party is available today. Waiting costs a day and meals; another trader may not arrive immediately.",[{"label":"Wait and watch for traders · 1 day","effects":{"days":1},"result":"Waited for passing traders. Check again or continue along the road."}])
	var at_post: bool=_at_post()
	var options: Array=_trade_options(offer,at_post)
	for choice in options:choice.erase("lot")
	var days: int=context.trade_days(offer)
	var rumor: String=crime.talk(self,str(state.landmark)) if at_post else ""
	var terms: String=("The first trade costs a day and meals; further trades at this stop take no extra time." if days>0 else "You have spent the day here already; further trades take no extra time.")
	if not at_post:
		var markup: int=roundi((float(context.data.passing_price_markup)-1.0)*100.0)
		terms=("Their camp is off the road: the first trade costs a day and meals, and further trades while they are nearby take no extra time." if days>0 else "You are camped with them already; further trades take no extra time.")+" Their prices run %d%% above the posts." % markup
	return _service_menu("Trading post" if at_post else "Passing traders", "Stock and buying demand are limited. Regional prices apply. "+terms+((" As a merchant you bargain 5% off cash purchases." if ProfessionSkill.background(self)=="Trading" else " Your trading companion negotiated 5% off cash purchases.") if characters.available(self,"Trading") else "")+(" "+rumor if not rumor.is_empty() else ""), options)

## A herd's few horses, each for clothing, ammunition, a footsore ox or coin. The first trade costs the visit's day.
func open_horse_traders() -> bool:
	var herd: Dictionary=context.data.horse_traders.get(str(state.landmark),{})
	if herd.is_empty() or not can_service():return false
	# The herd belongs to a household; one the party wronged will not trade.
	if native_encounters.data.sites.has(str(state.landmark)) and not native_encounters.refusal(self,str(state.landmark)).is_empty():return _service_menu(context.data.horse_traders[str(state.landmark)].name.capitalize(),native_encounters.refusal(self,str(state.landmark)),[])
	var key: String="herders:"+str(state.landmark)
	var days: int=0 if context.record.spent.has(key+"|visit") else 1
	var left: int=int(herd.horses)-int(context.record.spent.get(key+"|buy_horses",0))
	var options: Array=[]
	for offer in herd.offers:
		var agreed_label: String=offer.label
		var effects: Dictionary={"horses":1,"days":days}
		var requires: Dictionary={}
		for item in offer.give:
			var amount: float=float(offer.give[item])
			if item=="money" and state.landmark=="grande_ronde" and native_encounters.Story.standing(native_encounters,"grande_ronde")>0:
				amount=snappedf(amount*0.95,0.01)
				agreed_label="Pay $%.2f in coin for a horse · agreed price" % amount
			requires[item]=amount
			effects[item]=-amount
		var choice: Dictionary={"label":"%s%s · %d left" % [agreed_label," · 1 day" if days>0 else "",maxi(0,left)],"requires":requires,"effects":effects,"market_key":key+"|buy_horses","stock_limit":int(herd.horses),"result":agreed_label.replace("Trade","Traded").replace("Pay","Paid")+"."}
		if days>0:choice["visit_key"]=key+"|visit"
		options.append(choice)
	return _service_menu(str(herd.name),str(herd.text)+("\nThe first trade costs a day and meals; more trades here take no extra time." if days>0 else ""),options)

func _at_post() -> bool:
	return not pending.is_empty() and pending.has("landmark") and route.nodes[state.landmark].get("trade_bulk",false)

## Every trade on offer here: a buy and a sell choice per lot (plus barter with passing traders), priced and stock-limited.
## A post sells staple food by the 200 lb barrel-and-sack lot. The first transaction of a visit carries its day.
func _trade_options(offer: Dictionary,at_post: bool) -> Array:
	var options: Array = []
	var lots: Array = survival.data.trade_lots.duplicate(true)
	# Where goods cost more to buy, they fetch a little more too; the trader's markup is theirs alone.
	var region_price: float=float(context.region(self).price)
	for lot in lots:
		lot.buy_cents=roundi(float(lot.buy_cents)*float(offer.price))
		lot.sell_cents=roundi(float(lot.sell_cents)*region_price)
	if at_post:
		lots[0].amount = 200
		lots[0].label = "200 lb staple food"
		lots[0].buy_cents = route.nodes[state.landmark].get("bulk_food_cents",6000)
		lots[0].sell_cents = roundi(2000*region_price)
	if characters.available(self,"Trading"):
		for lot in lots:lot.buy_cents=maxi(1,roundi(lot.buy_cents*characters.benefits.trade_buy_factor))
	if at_post and int(lots[0].sell_cents)>=int(lots[0].buy_cents):lots[0].sell_cents=floori(float(lots[0].buy_cents)*0.5)
	# Resale cap: nothing sells for as much as it costs at the same counter.
	for lot in lots:
		if int(lot.sell_cents)>=int(lot.buy_cents):lot.sell_cents=floori(float(lot.buy_cents)*0.5)
	var days: int=context.trade_days(offer)
	var when: String=", 1 day" if days>0 else ""
	for lot in lots:
		if lot.item == "salt" or lot.item in Mounts.KEYS or lot.item in Armory.KEYS:continue # Preserve the existing barter offer order.
		var cost := float(lot.buy_cents) / 100.0
		var payment := float(lot.sell_cents) / 100.0
		options.append({"label": "Buy %s · $%.2f%s" % [lot.label, cost, when], "lot": lot, "requires": {"money": cost}, "effects": {"money": -cost, lot.item: lot.amount, "days": days}, "result": "Bought " + lot.label + "."})
		options.append({"label": "Sell %s · $%.2f%s" % [lot.label, payment, when], "lot": lot, "requires": {lot.item: lot.amount}, "effects": {"money": payment, lot.item: -lot.amount, "days": days}, "result": "Sold " + lot.label + "."})
	if not at_post:
		options.append({"label": "Trade 1 clothing set for 40 lb food" + when.replace(",", " ·"), "requires": {"clothing": 1}, "effects": {"clothing": -1, "food": 40, "days": days}, "result": "Traded a clothing set for food."})
		options.append({"label": "Trade 30 lb food for 1 care kit" + when.replace(",", " ·"), "requires": {"food": 30}, "effects": {"food": -30, "medicine": 1, "days": days}, "result": "Traded food for a care kit."})
		options.append({"label": "Trade 100 lb food for 1 ox" + when.replace(",", " ·"), "requires": {"food": 100}, "effects": {"food": -100, "oxen": 1, "days": days}, "result": "Traded food for an ox."})
	for lot in lots:
		if lot.item != "salt":continue
		options.append({"label":"Buy %s · $%.2f%s" % [lot.label,lot.buy_cents/100.0,when],"lot":lot,"requires":{"money":lot.buy_cents/100.0},"effects":{"money":-lot.buy_cents/100.0,"salt":lot.amount,"days":days},"result":"Bought salt for preserving meat."})
		options.append({"label":"Sell %s · $%.2f%s" % [lot.label,lot.sell_cents/100.0,when],"lot":lot,"requires":{"salt":lot.amount},"effects":{"money":lot.sell_cents/100.0,"salt":-lot.amount,"days":days},"result":"Sold salt."})
	# Horses, mules and tack, then arms, come last, after every older offer.
	for lot in lots:
		if lot.item not in Mounts.KEYS and lot.item not in Armory.KEYS:continue
		options.append({"label":"Buy %s · $%.2f%s" % [lot.label,lot.buy_cents/100.0,when],"lot":lot,"requires":{"money":lot.buy_cents/100.0},"effects":{"money":-lot.buy_cents/100.0,lot.item:lot.amount,"days":days},"result":"Bought "+lot.label+"."})
		options.append({"label":"Sell %s · $%.2f%s" % [lot.label,lot.sell_cents/100.0,when],"lot":lot,"requires":{lot.item:lot.amount},"effects":{"money":lot.sell_cents/100.0,lot.item:-lot.amount,"days":days},"result":"Sold "+lot.label+"."})
	if days>0:
		for choice in options:choice["visit_key"]=offer.key+"|visit"
	context.decorate(self,options,offer)
	return options

## The post's store counter: per item, its unit price, how many units the post can still sell or buy, and what the party holds.
## Goods move by the unit (a pound of food, a single bullet); prices are the lot prices divided out. Empty unless the party
## is stopped at an open trading post that will deal with it.
func post_store() -> Dictionary:
	if not can_service() or not _at_post():return {}
	var offer: Dictionary=context.market(self)
	if crime.closed(str(state.landmark)) or crime.refuses(self,str(state.landmark)):return {}
	var rows: Array=[]
	for pair in _lot_pairs(offer,true):
		var buy: Dictionary=pair[0]
		var sell: Dictionary=pair[1]
		var lot: Dictionary=buy.lot
		var amount: int=int(lot.amount)
		var can_buy: int=int(buy.stock_limit)*amount-_units_used(buy.market_key,amount) if crime.can_trade(self,buy) else 0
		if lot.item=="food":can_buy=mini(can_buy,crime.food_left(self,str(state.landmark)))
		var can_sell: int=int(sell.stock_limit)*amount-_units_used(sell.market_key,amount) if crime.can_trade(self,sell) else 0
		rows.append(_counter_row(lot,int(lot.buy_cents),int(lot.sell_cents),can_buy,can_sell,buy.market_key,sell.market_key,true,true))
	var name: String=str(route.nodes[state.landmark].get("name",state.landmark))
	rows.append_array(Produce.rows(self,str(offer.key),"post"))
	rows.append_array(Pelts.rows(self,str(offer.key),"post"))
	rows.append_array(income.rows(self,str(offer.key),"post"))
	rows.append_array(leathercraft.rows(self,str(offer.key),"post"))
	rows.append_array(livestock.rows(self,str(offer.key)))
	var wagon_row: Dictionary=provisions.WagonTrade.row(self,str(offer.key))
	if state.vehicle=="foot":rows.push_front(wagon_row)
	else:rows.append(wagon_row)
	return {"name":name,"kind":"post","key":str(offer.key),"rows":rows,"days":context.trade_days(offer),"money_cents":roundi(float(state.money)*100.0),"purse_cents":-1,"rumor":crime.talk(self,str(state.landmark)),"discount":characters.available(self,"Trading")}

## The trading counter where the party can trade by the unit: a post's store, a passing trading party, or (venue "camp")
## the emigrant family camped nearby. A party met on the road sells only what it carries and buys only what it wants,
## at its own prices, and pays out of its own purse. Empty when nobody here will trade.
func trade_counter(venue: String="") -> Dictionary:
	if venue=="camp":return _camp_counter()
	if _at_post():return post_store()
	if not can_service():return {}
	var offer: Dictionary=context.market(self)
	if not offer.available or offer.post or crime.closed(str(offer.key)) or crime.refuses(self,str(offer.key)):return {}
	var goods: Dictionary=context.barter_goods(self,str(offer.key))
	var rules: Dictionary=context.data.passing_goods
	var late: bool=int(calendar().month)>=int(rules.late_food_month)
	var rows: Array=[]
	for pair in _lot_pairs(offer,false):
		var buy: Dictionary=pair[0]
		var sell: Dictionary=pair[1]
		var lot: Dictionary=buy.lot
		var item: String=lot.item
		var amount: int=int(lot.amount)
		# Food runs dear once the season turns toward winter.
		var buy_cents: int=roundi(float(lot.buy_cents)*float(goods.buy)*(float(rules.late_food_factor) if item=="food" and late else 1.0))
		var can_buy: int=int(goods.stock.get(item,0))-_units_used(buy.market_key,amount) if crime.can_trade(self,buy) else 0
		if item=="food":can_buy=mini(can_buy,crime.food_left(self,str(offer.key)))
		var can_sell: int=int(goods.wants.get(item,0))-_units_used(sell.market_key,amount) if crime.can_trade(self,sell) else 0
		rows.append(_counter_row(lot,maxi(1,buy_cents),roundi(float(lot.sell_cents)*float(goods.sell)),can_buy,can_sell,buy.market_key,sell.market_key,goods.stock.has(item),goods.wants.has(item)))
	rows.append_array(Produce.rows(self,str(offer.key),"traders"))
	rows.append_array(Pelts.rows(self,str(offer.key),"traders"))
	rows.append_array(income.rows(self,str(offer.key),"traders"))
	rows.append_array(leathercraft.rows(self,str(offer.key),"traders"))
	return {"name":"Passing traders","kind":"traders","key":str(offer.key),"mood":goods.mood,"late_food":late,"rows":rows,"days":context.trade_days(offer),"money_cents":roundi(float(state.money)*100.0),"purse_cents":_purse_left(str(offer.key),int(goods.purse_cents)),"rumor":"","discount":characters.available(self,"Trading")}

## How freely the people at a counter talk: a passing party's mood, a family's reluctance to part with things; a post's clerk is fair.
func news_temper(counter: Dictionary) -> String:
	if counter.kind=="traders":return str(counter.mood)
	if counter.kind=="camp":
		var reluctance: float=float(context.camp_goods(self,str(counter.key)).reluctance)
		return "generous" if reluctance<1.2 else ("fair" if reluctance<1.4 else "stingy")
	return "fair"

## How many more times the people at an open counter will answer ASK FOR NEWS.
func news_left(venue: String="") -> int:
	var counter: Dictionary=trade_counter(venue)
	if counter.is_empty():return 0
	return maxi(0,int(news.data.asks[news_temper(counter)])-int(context.record.spent.get(str(counter.key)+"|asked",0)))

## ASK FOR NEWS: one fragment of what the post, the traders or the family have heard, or "" when they will say no more.
## Takes no time; each answer uses one of the asks their temper allows.
func ask_news(venue: String="") -> String:
	if news_left(venue)<=0:return ""
	var counter: Dictionary=trade_counter(venue)
	var told: Array=news.fragments(self,str(counter.kind),str(state.landmark) if counter.kind=="post" else str(counter.key))
	if told.is_empty():return ""
	var key: String=str(counter.key)+"|asked"
	var asked: int=int(context.record.spent.get(key,0))
	context.record.spent[key]=asked+1
	return news.pick(told,"%d|%s" % [int(state.seed),str(counter.key)],asked)

## The emigrant family's spare goods: not traders, so whatever they happen to have, priced by what each thing is worth to them.
## They part with goods reluctantly and pay well for what they are short of. Trading with them takes no time.
func _camp_counter() -> Dictionary:
	var place: String=crime.camp(self)
	var open: bool=can_service() or (pending.get("service_menu",false) and pending.get("camp","")==place)
	if place.is_empty() or not open or crime.record.services.has(place) or crime.refuses(self,place):return {}
	var goods: Dictionary=context.camp_goods(self,place)
	var price: float=float(context.region(self).price)
	var rows: Array=[]
	for lot in survival.data.trade_lots:
		var item: String=lot.item
		var amount: int=int(lot.amount)
		var buy_key: String=place+"|buy_"+item
		var sell_key: String=place+"|sell_"+item
		var can_buy: int=int(goods.stock.get(item,0))-_units_used(buy_key,amount)
		if item=="food":can_buy=mini(can_buy,crime.food_left(self,place))
		var can_sell: int=int(goods.wants.get(item,0))-_units_used(sell_key,amount)
		var buy_cents: int=roundi(float(lot.buy_cents)*price*float(goods.reluctance))
		var sell_cents: int=mini(roundi(float(lot.sell_cents)*price*float(goods.need.get(item,1.0))),maxi(1,buy_cents)-1)
		rows.append(_counter_row(lot,maxi(1,buy_cents),sell_cents,can_buy,can_sell,buy_key,sell_key,goods.stock.has(item),goods.wants.has(item)))
		rows[-1]["premium"]=float(goods.need.get(item,1.0))
	rows.append_array(Produce.rows(self,place,"camp"))
	return {"name":"Emigrant camp","kind":"camp","key":place,"needs":goods.need.keys(),"rows":rows,"days":0,"money_cents":roundi(float(state.money)*100.0),"purse_cents":_purse_left(place,int(goods.purse_cents)),"rumor":"","discount":false}

func _counter_row(lot: Dictionary,buy_cents: int,sell_cents: int,can_buy: int,can_sell: int,buy_key: String,sell_key: String,sells: bool,buys: bool) -> Dictionary:
	var held: int=int(state.get(lot.item,0))
	return {"item":lot.item,"label":lot.label,"amount":int(lot.amount),"buy_cents":buy_cents,"sell_cents":sell_cents,"can_buy":maxi(0,can_buy),"can_sell":maxi(0,mini(can_sell,held)),"held":held,"buy_key":buy_key,"sell_key":sell_key,"sells":sells,"buys":buys}

## Cash a party met on the road still has to pay out, after what it has already paid this party.
func _purse_left(key: String,purse_cents: int) -> int:
	return maxi(0,purse_cents-int(context.record.spent.get(key+"|purse|units",0)))

## The buy and sell choice for each lot on offer here, paired; barter-only choices are left out.
func _lot_pairs(offer: Dictionary,at_post: bool) -> Array:
	var lots: Array=_trade_options(offer,at_post).filter(func(choice):return choice.has("lot"))
	var pairs: Array=[]
	for i in range(0,lots.size(),2):pairs.append([lots[i],lots[i+1]])
	return pairs

## Units of a counter's stock (or buying demand) already used: whole lots from the lot menu, or single units from the counter.
func _units_used(key: String,amount: int) -> int:
	return int(context.record.spent.get(key+"|units",int(context.record.spent.get(key,0))*amount))

## Price a basket at the post: positive counts buy, negative counts sell, in units (pounds of food, single bullets). Read-only.
func robbery_quote(basket: Dictionary) -> Dictionary:return RobberyDemand.quote(self,basket)
func demand_robbery(basket: Dictionary) -> bool:return RobberyDemand.start(self,basket)
## A quiet theft from a store, commissary, trading party or camp: pick the goods; taking more is likelier to be noticed.
func theft_quote(basket: Dictionary) -> Dictionary:return RobberyDemand.quote(self,basket,"","theft")
func steal(basket: Dictionary) -> bool:return RobberyDemand.start(self,basket,"theft")

func wagon_sale_quote(cart: Dictionary,keep_oxen: int=-1) -> Dictionary:return provisions.WagonTrade.sale_quote(self,cart,keep_oxen)
func sell_wagon(cart: Dictionary,keep_oxen: int=-1) -> bool:return provisions.WagonTrade.sell(self,cart,keep_oxen)

func post_quote(cart: Dictionary) -> Dictionary:
	return counter_quote(cart)

func post_checkout(cart: Dictionary) -> bool:
	return counter_checkout(cart)

## Price a basket at the trading counter here: positive counts buy, negative counts sell, in units. Read-only.
## Selling more than buying is paid in cash only as far as the other side's purse allows; a post's purse is unlimited.
func counter_quote(cart: Dictionary,venue: String="") -> Dictionary:
	var store: Dictionary=trade_counter(venue)
	var result: Dictionary={"valid":false,"message":"Nobody here is open for trade.","net_cents":0,"days":int(store.get("days",0)),"effects":{}}
	if store.is_empty():return result
	var effects: Dictionary={}
	var moved:=0
	for row in store.rows:
		var count: Variant=cart.get(row.item,0)
		if not (count is int or count is float) or count!=floor(count):
			result.message="Check the quantity of %s." % row.item
			return result
		var n: int=int(count)
		if n>row.can_buy or -n>row.can_sell:
			result.message=("They cannot sell that much %s." if n>0 else "They will not buy that much %s.") % row.item
			return result
		if n==0:continue
		moved+=absi(n)
		result.net_cents+=-roundi(float(n*int(row.buy_cents))/int(row.amount)) if n>0 else roundi(float(-n*int(row.sell_cents))/int(row.amount))
		effects[row.item]=n
	for key in cart:
		if not store.rows.any(func(row):return row.item==key):
			result.message="Unknown goods: %s." % str(key)
			return result
	result.effects=effects
	var after: Dictionary=Produce.model_after(self,effects)
	if not after.valid:
		result.message=after.get("message","That basket has invalid goods, drivers or draft teams.")
		return result
	if int(effects.get("wagon",0))<0 and camp_repair.blocked(self):
		result.message="Repair the damaged wagon before selling frames from this train."
		return result
	if moved==0:
		result.message="Choose goods to buy or sell."
	elif store.money_cents+result.net_cents<0:
		result.message="You cannot afford that."
	elif store.purse_cents>=0 and result.net_cents>store.purse_cents:
		result.message="They have only $%.2f in cash. Take more of their goods for the rest." % (store.purse_cents/100.0)
	else:
		result.valid=true
		result.message="Settle up · %s" % ("1 day and meals" if result.days>0 else "no extra time")
	# What the wagon (or the packs) would weigh after this basket, so the party can see the load before settling.
	result.cargo_lb=provisions.cargo(state)
	result.capacity_lb=provisions.capacity(state)
	result.cargo_after_lb=after.cargo
	result.capacity_after_lb=provisions.capacity(after.inventory)
	return result

## Settle a basket at the counter as one visit: stock and demand move by the unit, and the visit's day is charged once.
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
	var quote: Dictionary=counter_quote(cart,venue)
	if not quote.valid:return false
	var store: Dictionary=trade_counter(venue)
	var lines: Array[String]=[]
	for row in store.rows:
		var n: int=int(cart.get(row.item,0))
		if n==0:continue
		var key: String=row.buy_key if n>0 else row.sell_key
		# The unit ledger keeps exact amounts; the lot count rounds up so the lot menu never sells stock the counter took.
		var used: int=_units_used(key,int(row.amount))+absi(n)
		context.record.spent[key+"|units"]=used
		if row.item not in Produce.ITEMS and row.item not in livestock.GOODS and row.item!="wagon" and row.item not in provisions.data.pelts.goods and not leathercraft.is_good(row.item):context.record.spent[key]=ceili(float(used)/int(row.amount))
		crime.consume_trade({"market_key":key,"effects":{row.item:n}})
		lines.append(("bought %d %s" if n>0 else "sold %d %s") % [absi(n),_unit_name(row.item,absi(n))])
	if quote.net_cents>0 and store.purse_cents>=0:
		var purse_key: String=str(store.key)+"|purse|units"
		context.record.spent[purse_key]=int(context.record.spent.get(purse_key,0))+int(quote.net_cents)
	if store.days>0:context.record.spent[str(store.key)+"|visit"]=1
	var effects: Dictionary=quote.effects.duplicate()
	Produce.commit(self,effects)
	effects["money"]=quote.net_cents/100.0
	effects["days"]=quote.days
	journal.append("Day %d · %s: %s." % [state.day,{"post":"At "+str(store.name),"traders":"Traded with passing traders","camp":"Traded with an emigrant family"}[store.kind],", ".join(lines)])
	_apply(effects)
	livestock.sync(self)
	refresh_stop_offers()
	if quote.days>0:_update_river_stage()
	return true

## How a counter quantity reads in the journal and on the store screen.
static func _unit_name(item: String,n: int) -> String:
	if preload("res://simulation/trail_income.gd").is_keepsake(item):return "personal keepsake"
	var names: Dictionary={"buckskin":["dressed buckskin","dressed buckskins"],"buckskin_gloves":["pair of buckskin gloves","pairs of buckskin gloves"],"bison_hide":["bison hide","bison hides"],"deer_hide":["deer hide","deer hides"],"rabbit_pelt":["rabbit pelt","rabbit pelts"],"food":["lb of food","lb of food"],"salt":["lb of salt","lb of salt"],"bullets":["bullet","bullets"],"medicine":["care kit","care kits"],"clothing":["clothing set","clothing sets"],"oxen":["ox","oxen"],"wheels":["wheel","wheels"],"axles":["axle","axles"],"tongues":["tongue","tongues"],"horses":["horse","horses"],"mules":["mule","mules"],"saddles":["saddle","saddles"],"pack_saddles":["pack saddle","pack saddles"],"saddlebags":["pair of saddlebags","pairs of saddlebags"]}
	names.merge(Armory.NAMES)
	return names.get(item,[item,item])[0 if n==1 else 1]

## The crime preview for this stop's target, or (place) one chosen from crime.local_places, as VILLAINY > STEAL lists them.
func open_crime(place: String="") -> bool:
	if pending.get("crime_menu",false):return true
	# A household is picked by name from VILLAINY; it is never the stop's default target.
	if place.is_empty() and not crime.eligible(self):return false
	if not place.is_empty() and (not can_service() or place not in crime.local_places(self,pending)):return false
	service_return=pending.duplicate(true)
	if not place.is_empty():pending={"crime_menu":true,"crime_place":place}
	pending=crime.menu(self)
	return true

## A peaceful visit to the emigrant family camped near the road today, if any. They trade a little food for ammunition,
## help nurse one traveler and pass on news of the posts ahead. A family the party wronged, or one that has heard it named, turns it away.
func open_camp() -> bool:
	var place: String=crime.camp(self)
	if place.is_empty() or not can_service():return false
	var rules: Dictionary=context.data.emigrant_camp
	if crime.record.services.has(place):return _service_menu("An emigrant camp","The family your party wronged keeps its rifles close and will not let you near.",[])
	if crime.refuses(self,place):return _service_menu("An emigrant camp",crime.news_text(self,place),[])
	var options: Array=[]
	var lots: int=int(rules.barter_lots)
	var left: int=lots-int(context.record.spent.get(place+"|barter_food",0))
	# Their spare goods open on the trading counter; the fixed bullets-for-food offer stays for the study policies.
	options.append({"label":"Trade goods with them · no time","counter":"camp","effects":{},"result":""})
	options.append({"label":"Trade %d bullets for %d lb of their food · %d offer(s) left" % [int(rules.barter_bullets),int(rules.barter_food),maxi(0,left)],"market_key":place+"|barter_food","stock_limit":lots,"requires":{"bullets":int(rules.barter_bullets)},"effects":{"bullets":-int(rules.barter_bullets),"food":int(rules.barter_food)},"result":"Traded ammunition for food with an emigrant family.","policy_only":true})
	for member in party_health.members:
		if party_health.is_active(member) and (not member.conditions.is_empty() or member.health<100):
			options.append({"label":"Ask their help nursing %s · 1 day, once per camp" % member.name,"member_id":member.id,"care":int(rules.care),"market_key":place+"|care","stock_limit":1,"effects":{"days":1},"result":"An emigrant family helped nurse %s." % member.name})
	# Asking for news uses the same questions as a counter's ASK FOR NEWS: as many as the family's temper allows.
	var counter: Dictionary=trade_counter("camp")
	if not counter.is_empty():options.append({"label":news_label("camp"),"news":"camp","market_key":place+"|asked","stock_limit":int(news.data.asks[news_temper(counter)]),"effects":{},"result":""})
	if not _service_menu("An emigrant camp","An emigrant family is camped near the road and is glad of company. Their food in the wagon: %d lb. Trading and news cost no time; nursing takes a day." % crime.food_left(self,place),options):return false
	pending["camp"]=place
	return true

## What a family met on the road heard at the posts behind it: which posts ahead already know of the party.
func camp_news() -> String:
	var warned: Array=crime.venues().filter(func(place):return not crime.household(place) and crime.mile(self,place)>int(state.miles) and crime.refuses(self,place)).map(func(place):return route.nodes[place].name)
	if warned.is_empty():return "We didn't hear any talk about you folks at the posts we passed."
	return "Folks at %s have already heard about you. I'd watch yourselves there." % " and ".join(warned.map(func(name):return news.spoken(name)))

func news_label(venue: String) -> String:
	var left: int=news_left(venue)
	return "Ask for news · %d question(s) left" % left if left>0 else "Ask for news · they have told you all they care to"

func open_care() -> bool:
	var options: Array = []
	for member in party_health.members:
		if not party_health.is_active(member) or (member.conditions.is_empty() and member.health >= 100):
			continue
		options.append({"label": "Care for %s · 1 kit, 1 day" % member.name, "member_id": member.id, "care": 6, "requires": {"medicine": 1}, "effects": {"medicine": -1, "days": 1}, "result": "Used care supplies for " + member.name + "."})
		if context.local_care(self) and not crime.refuses(self,str(state.landmark)) and not crime.closed(str(state.landmark)):options.append({"label": "Seek local care for %s · $20, 1 day" % member.name, "member_id": member.id, "care": 12, "requires": {"money": 20}, "effects": {"money": -20, "days": 1}, "result": "Paid $20 for medical attention for " + member.name + "."})
	if not camp_tasks.enabled() and characters.available(self,"Caregiving"):
		for option in options:
			option.care_bonus=int(characters.benefits.care_health_bonus)
			option.recovery_bonus=int(characters.benefits.care_recovery_bonus)
			option.label+=" · caregiver +%d health" % option.care_bonus
	if context.local_care(self) and crime.closed(str(state.landmark)):return _service_menu("Care for the party", "Use your own kits anywhere. After the incident, nobody at this post will help your party.", options)
	if context.local_care(self) and crime.refuses(self,str(state.landmark)):return _service_menu("Care for the party", "Use your own kits anywhere. "+crime.news_text(self,str(state.landmark)), options)
	return _service_menu("Care for the party", "Use your own kits anywhere. Paid local help is available at this post." if context.local_care(self) else "No local medical help here. Use your own kits and rest; paid help is offered only while stopped at selected supply posts.", options)

func _choose_service(index: int) -> bool:
	var choice: Dictionary = pending.choices[index]
	# The trading counter is its own screen; choosing it here changes nothing.
	if choice.has("counter"):return true
	# A question for the family: one fragment of news, shown beside their picture; the menu stays open.
	if choice.has("news"):
		last_news=ask_news(str(choice.news))
		choice.label=news_label(str(choice.news))
		return true
	if choice.get("departure_review",false):
		pending=service_return.duplicate(true)
		service_return={}
		_depart(departure_plan(),"")
		return true
	var forage: Dictionary = forage_offer() if choice.get("foraging",false) else {}
	if choice.get("foraging",false) and not forage.available: return false
	crime.consume_trade(choice)
	context.consume(choice)
	if choice.has("care") and camp_tasks.enabled():
		camp_tasks.end_leader_nursing(self)
		camp_tasks.begin(self,"care",int(choice.member_id))
	if choice.has("care"):
		var member: Dictionary = party_health.members[int(choice.member_id)]
		if party_health.dress_wound(int(choice.member_id),int(state.day)+1):
			party_health._record(member,int(state.day),"%s's wound was cleaned and bandaged." % member.name)
		party_health.affect(member, int(choice.care)+int(choice.get("care_bonus",0)), state.day, "care")
		for active in member.conditions:
			party_health.support_condition(active,2+int(choice.get("recovery_bonus",0)))
		member.history.append("Day %d · Received care." % state.day)
		characters.care(self,int(choice.member_id))
		state.health = party_health.average_health()
	_apply(choice.effects, "injuries", choice.has("care"),"care" if choice.has("care") else ("forage" if choice.get("foraging",false) else ""))
	if choice.get("foraging",false) and not camp_tasks.enabled(): _gather_forage(forage)
	if not choice.result.is_empty():
		journal.append("Day %d · %s" % [state.day, choice.result])
	pending = service_return if state.status == "traveling" else {}
	service_return = {}
	refresh_stop_offers()
	if int(choice.effects.get("days", 0)) > 0:
		_update_river_stage()
	if state.status == "traveling" and pending.is_empty():
		_schedule_event(false)
	return true

## Thieves take up to two animals, horses before mules; the recovery choices match what was taken.
func _adapt_horse_thieves(content: Dictionary) -> void:
	var kind: String="horses" if Mounts.count(state,"horses")>0 else "mules"
	var taken: int=mini(2,Mounts.count(state,kind))
	var words: String={"horses":["horse","horses"],"mules":["mule","mules"]}[kind][0 if taken==1 else 1]
	content.text=content.text.replace("{stock}",("a %s" % words) if taken==1 else "two "+words)
	content.onset_effects={kind:-taken}
	for choice in content.choices:
		for key in ["label","result"]:choice[key]=str(choice[key]).replace("{stock}",words)
		if choice.effects.has("horses"):
			choice.effects[kind]=mini(taken,int(choice.effects.horses))
			if kind!="horses":choice.effects.erase("horses")
	# With one animal gone, the short search and the long chase come to the same thing.
	if taken==1:content.choices=content.choices.filter(func(choice):return int(choice.effects.get("days",0))!=1)

## Stock cross by the water: they ford in low water and swim in high. One choice, set by the stage.
func horse_crossing() -> Dictionary:
	var high: bool=state.river_stage=="high"
	return {"label":("Swim the horses across · 1 day, risk to stock and supplies" if high else "Ford with the horses · 1 day, small risk to supplies"),"action":"cross","method":"horses","effects":{"days":1},"risk":horse_crossing_risk()}
func horse_crossing_risk() -> float:
	# Authored gameplay odds: animals take a ford well, and swim better than people with packs.
	return 0.4 if state.river_stage == "high" else 0.08

func swimming_risk() -> float:
	# Authored gameplay odds, higher than either wagon option at the same stage.
	return 0.8 if state.river_stage == "high" else 0.3

func departure_plan() -> Array[Dictionary]:return plan_for(social.departure_group(self,characters.departure_candidates(self)))
## Each leaving companion takes an equal share of a few days' food and a clothing set, never the wagon, stock, cash, ammunition or kits.
func plan_for(candidates: Array) -> Array[Dictionary]:
	var plan: Array[Dictionary]=[]
	if candidates.is_empty():return plan
	var food_budget: int=mini(int(state.food),candidates.size()*int(characters.benefits.food_days_on_departure)*int(provisions.data.rations_lb[state.rations]))
	var clothing_budget: int=mini(int(state.clothing),candidates.size())
	for index in range(candidates.size()):
		plan.append({"id":candidates[index],"food":int(food_budget/candidates.size())+(1 if index<food_budget%candidates.size() else 0),"clothing":1 if index<clothing_budget else 0,"gear_lb":int(provisions.data.walking.personal_gear_lb_per_person)})
	return plan

## Settlement departures (no reason) or immediate flight from the road (with the reason).
func _depart(plan: Array,fled_reason: String,verb: String="fled ") -> void:
	for transfer in plan:
		var member: Dictionary=party_health.members[transfer.id]
		provisions.remove(transfer.food)
		state.food-=transfer.food
		state.clothing-=transfer.clothing
		state["departed_gear_lb"]=int(state.get("departed_gear_lb",0))+transfer.gear_lb
		if state.has("household_gear_lb"):state.household_gear_lb=maxi(0,int(state.household_gear_lb)-int(transfer.gear_lb))
		var keepsake: String=income.key(int(member.id))
		if int(state.get(keepsake,0))>0:
			state[keepsake]=0
			journal.append("%s took their personal keepsake." % member.name)
		member["departed"]=true
		member["departure_day"]=int(state.day)
		member["departure_place"]=state.landmark
		member["departure_supplies"]={"food":transfer.food,"clothing":transfer.clothing,"gear_lb":transfer.gear_lb}
		if not fled_reason.is_empty():member["fled"]=true
		var text: String="%s %s %s with %d ration-lb food, %d clothing set(s), and %d lb personal gear." % [member.name,verb+fled_reason+", near" if not fled_reason.is_empty() else "left at",route.nodes[state.landmark].name,transfer.food,transfer.clothing,transfer.gear_lb]
		member.history.append("Day %d · %s" % [state.day,text])
		journal.append("Day %d · %s" % [state.day,text])
		health_events.append(text)
		supply_history.append({"day":int(state.day),"event":"companion_departure","changes":{"food":-transfer.food,"clothing":-transfer.clothing}})
	state.party_size=party_health.living_count()
	state.health=party_health.average_health()
	Remains.sync(self)
	_check_health()
## Companions who leave at once after violence, wherever the party is.
func flee(ids: Array,reason: String) -> void:
	var active: Array=ids.filter(func(id):return party_health.is_active(party_health.members[id]))
	if not active.is_empty():_depart(plan_for(active),reason)
## Companions a court takes from the party go with the clothes they wear and nothing from the wagon.
func imprison(ids: Array,where: String) -> void:
	var plan: Array=[]
	for id in ids:
		if party_health.is_active(party_health.members[id]):plan.append({"id":id,"food":0,"clothing":0,"gear_lb":int(provisions.data.walking.personal_gear_lb_per_person)})
	if not plan.is_empty():_depart(plan,where,"was sent ")
func open_attack(target: int) -> bool:
	if not crime.can_attack(self,target):return false
	service_return=pending.duplicate(true)
	pending=crime.attack_menu(self,target)
	return true

## The dead within reach: here, or carried with the party.
func open_remains() -> bool:
	if not can_service() or not Remains.within_reach(self):return false
	service_return=pending.duplicate(true)
	pending=Remains.menu(self)
	return true

func open_departure_review() -> bool:
	var plan:=departure_plan()
	if plan.is_empty():return false
	var lines: Array[String]=["These companions intend to leave here. You can return to the stop and settle wages through View Party before deciding. No day passes for this review."]
	var candidates: Array=characters.departure_candidates(self)
	for transfer in plan:
		if int(transfer.id) not in candidates:
			lines.append("%s will leave with their partner; they will not separate." % party_health.members[int(transfer.id)].name)
		lines.append("%s: %d ration-lb food, %d clothing set(s), %d lb personal gear." % [party_health.members[transfer.id].name,transfer.food,transfer.clothing,transfer.gear_lb])
	lines.append("They take no wagon, oxen, communal cash, ammunition or care kits. Unpaid wages stay recorded. On foot, fewer travelers also means less carrying capacity.")
	return _service_menu("Companions intend to leave","\n".join(lines),[{"label":"Acknowledge departures and remain at this stop","departure_review":true,"effects":{},"result":"Reviewed companion departures."}])

func river_conditions() -> String:
	if state.vehicle == "foot" and Mounts.animals(state)>0:
		return "\nThe river is up: the animals will have to swim, and the current can take one." if state.river_stage == "high" else "\nThe water is low enough for the animals to ford."
	if state.vehicle == "foot":
		return "\nHigh water and a swift current make swimming extremely dangerous." if state.river_stage == "high" else "\nSwimming with packs risks injury and lost supplies, even in low water."
	return "\nHigh water and a swift current make fording dangerous." if state.river_stage == "high" else "\nLow water makes fording more practical, though mishaps remain possible."

func upgrade_foot_crossing(menu: Dictionary) -> void:
	# Pending offers from saves made before swimming was introduced.
	if state.vehicle != "foot":
		return
	for option in menu.get("choices", []):
		if option.get("method", "") == "wade":
			option.method = "swim"
			option.label = "Swim across with packs · 1 day, high injury / supply-loss risk"
			option.risk = swimming_risk()
			menu.text = route.nodes[state.landmark].text + river_conditions()

func _update_river_stage() -> void:
	if not pending.has("landmark") or route.nodes[state.landmark].kind != "river":
		return
	if survival.wet_ground >= 4:
		state.river_stage = "high"
	elif survival.wet_ground == 0:
		state.river_stage = "low"
	pending.text = route.nodes[state.landmark].text + river_conditions()
	for option in pending.choices:
		if option.get("method", "") == "ford":
			option.risk = 0.65 if state.river_stage == "high" else 0.08
		elif option.get("method", "") == "swim":
			option.risk = swimming_risk()
		elif option.get("method", "") == "horses":
			option.merge(horse_crossing(),true)
		elif option.get("method", "") == "float":
			option.risk = 0.35 if state.river_stage == "high" else 0.2
		elif option.get("method", "") == "seized":
			option.risk = crime.seized_risk(self,str(state.landmark))

func start_hunt(outfit: Dictionary={}) -> bool:
	if not _can_act() or not state.extended_route or (not can_hunt_with_gun() and not dogs.ready("hunt")):
		return false
	var field: Dictionary={}
	if not outfit.is_empty():
		field=hunt_outfit_quote(outfit.get("members",[]),str(outfit.get("kit","foot")),int(outfit.get("bullets",5)),str(outfit.get("return_mode","ride")))
		if not field.get("valid",false):return false
		if field.kit!="wagon" and not camp_tasks.enabled():
			for person in party_health.members:
				if int(person.id)!=camp_tasks.leader_id(self) and party_health.is_active(person):camp_tasks.assign(self,int(person.id),"hunt_help" if int(person.id) in field.members else "rest")
	# Settle the day after the outing: today's successful catch can feed today's camp.
	last_hunt_recovery={}
	if field.is_empty() or field.kit!="wagon":camp_tasks.end_leader_nursing(self)
	camp_tasks.begin(self,"hunt")
	hunting_outings += 1
	hunt = hunting.begin(int(state.seed), hunting_outings, int(state.miles), route.nodes[state.landmark].get("hunting_region","plains"),not field.is_empty() and field.kit=="wagon",float(field.get("search_factor",1.0)))
	dogs.begin_hunt(self)
	if camp_tasks.enabled():hunt["_camp_helpers"]=camp_tasks.day_plan.get("jobs",[]).filter(func(j):return j.job=="hunt_help").map(func(j):return int(j.member))
	if not field.is_empty():
		field["condition"]=Mounts.condition(state)
		hunt["field"]=field
		hunt["_camp_helpers"]=field.members.filter(func(id):return int(id)!=camp_tasks.leader_id(self))
		for job in camp_tasks.day_plan.get("jobs",[]):
			if job.job=="hunt_help" and int(job.member) not in field.members:camp_tasks.day_plan.rest[job.member]=true
		if not camp_tasks.day_plan.is_empty():camp_tasks.day_plan.jobs=camp_tasks.day_plan.jobs.filter(func(job):return job.job!="hunt_help" or int(job.member) in field.members)
		# Everyone who actually leaves on the selected hunt works that day, including
		# a weak but willing helper whose standing camp job would otherwise fall back to rest.
		for id in field.members:
			if not camp_tasks.day_plan.is_empty():camp_tasks.day_plan.rest[int(id)]=false
		if field.kit=="wagon":
			hunt["_camp_helpers"]=field.crew.filter(func(id):return int(id)!=camp_tasks.leader_id(self))
			camp_tasks.day_plan={"rest":{},"jobs":[],"action":"hunt","leader":camp_tasks.leader_id(self),"leader_patient":-1}
			for person in party_health.members:
				if party_health.is_active(person):camp_tasks.day_plan.rest[int(person.id)]=false
		field_outings.Outfit.reserve(self,field)
	hunt.day = state.day+1
	journal.append("Day %d · Set out to hunt. The outing will take one day, including meals at camp." % (state.day+1))
	return true

func fishing_offer() -> Dictionary:
	return fishing.access(self)
func fishing_quote(kit: String) -> Dictionary:
	return fishing.quote(self,kit)
func start_fishing(kit: String) -> bool:
	var offer: Dictionary=fishing_quote(kit)
	if not offer.get("valid",false):return false
	service_return=pending.duplicate(true)
	pending={}
	camp_tasks.end_leader_nursing(self)
	camp_tasks.begin(self,"fish")
	hunting_outings+=1
	offer["condition"]=Mounts.condition(state)
	hunt=fishing.begin(int(state.seed),hunting_outings,offer,int(calendar().month))
	field_outings.Outfit.reserve(self,offer)
	last_hunt_recovery={}
	journal.append("Day %d · Set out to fish at %s, %.0f road miles away; one day including travel and meals." % [state.day+1,offer.site_name,offer.distance])
	return true
func fishing_click() -> bool:
	return fishing.click(hunt) if hunt.get("activity","")=="fish" else false
func advance_fishing(delta: float) -> void:
	if hunt.get("activity","")=="fish":fishing.tick(hunt,delta)
func finish_fishing() -> bool:
	if hunt.get("activity","")!="fish":return false
	var return_menu: Dictionary=service_return.duplicate(true)
	service_return={}
	var result: bool=finish_hunt()
	if result and pending.is_empty() and state.status=="traveling":pending=return_menu
	return result

func hunt_outfit_quote(members: Array,kit: String,bullets: int,return_mode: String="ride") -> Dictionary:
	var leader: int=-1
	for person in party_health.members:
		if party_health.is_active(person):leader=int(person.id);break
	if leader<0 or leader not in members:return {"valid":false,"message":"The leader must join the player hunt."}
	for id in members:
		if kit!="wagon" and int(id)!=leader and camp_tasks.enabled() and camp_tasks.job(int(id)).job!="hunt_help":return {"valid":false,"message":"Assign additional companions to Help leader hunt first."}
	return field_outings.Outfit.quote(self,members,kit,1,bullets,return_mode)
func hunt_ammo() -> int:
	return int(hunt.field.inventory.bullets) if hunt.has("field") and hunt.field.kit!="wagon" else int(state.bullets)

func hunt_shot(target: int) -> bool:
	if hunt.is_empty() or hunt.get("activity","")=="fish" or hunt.ended or hunt.reload > 0 or hunt_ammo() < 1 or Armory.long_guns(state)==0 or hunt.shots >= hunting.data.shot_limit or target < -1 or target >= hunt.animals.size():
		return false
	if target in hunt.targets or (target >= 0 and hunt.animals[target].escaped):
		return false
	if hunt.has("field") and hunt.field.kit!="wagon":hunt.field.inventory.bullets-=1
	else:state.bullets -= 1
	hunt.shots += 1
	hunt.reload = hunting.data.reload_seconds*(characters.benefits.hunter_reload_factor if characters.available(self,"Hunting") else 1.0)
	hunt.flash = 0.12
	hunt.message = "Missed. The animals scatter."
	if target >= 0:
		hunt.targets.append(target)
		var species: Dictionary = hunting.data.species[hunt.animals[target].kind]
		var meat: int = hunt.animals[target].get("meat", species.meat)
		hunt.meat += meat
		hunt.message = "%s: %d lb usable meat." % [species.label, meat]
	if hunt.shots >= hunting.data.shot_limit or hunt_ammo() == 0:
		hunt.ended = true
		hunt.message += " Return to camp."
	return true

func advance_hunt(delta: float) -> void:
	if not hunt.is_empty() and hunt.get("activity","")!="fish" and is_finite(delta) and delta > 0:
		hunting.tick(hunt, delta)
		dogs.hunt_step(self)

func hunt_fire_at(point: Vector2) -> bool:
	if hunt.is_empty() or hunt.get("activity","")=="fish" or not point.is_finite():
		return false
	var accepted := hunt_shot(hunting.target_at(hunt, point))
	if accepted:
		hunt.aim = point
	return accepted

func move_hunter(point: Vector2) -> void:
	if not hunt.is_empty() and hunt.get("activity","")!="fish" and not hunt.ended and point.is_finite():
		hunt.destination = point.clamp(Vector2(8, 120), Vector2(424, 146))

func hauling_capacity(action: String="hunt") -> int:
	var pounds:=0.0
	for member in party_health.members:
		if characters.willing(int(member.id),action) and (action!="hunt" or not camp_tasks.excludes_helper(self,int(member.id))):
			pounds+=float(hunting.data.carry_per_person_lb)*provisions.Carrying.factor(member,provisions.data.walking.health_load_curve)
	return mini(int(hunting.data.carry_limit),floori(pounds))
func hunting_capacity() -> int:
	if hunt.has("field"):
		if hunt.field.kit=="wagon":return maxi(0,floori(provisions.storage_capacity(state)-provisions.cargo(state)))
		return maxi(0,floori(field_outings.Outfit.capacity(self,hunt.field.members,hunt.field.kit,hunt.field.stock,str(hunt.field.get("return_mode","ride")))-float(hunt.field.pack_lb)))
	return hauling_capacity("hunt")
## Pre-settlement space estimate; last_hunt_recovery records actual meals and loads after settlement.
func hunt_recovery() -> Dictionary:
	if hunt.is_empty():return {}
	var is_fish: bool=hunt.get("activity","")=="fish"
	var amount: float=float(hunt.meat) if is_fish else float(int(hunt.meat))
	var carried: float=minf(minf(float(hunting_capacity()),amount),maxf(0,provisions.storage_capacity(state)-provisions.cargo(state)))
	return {"mass":carried,"food":provisions.meat_units(carried,hunt_calorie_density(),not is_fish),"left":amount-carried}
func hunt_calorie_density() -> float:
	var mass:=0.0;var energy:=0.0
	for index in hunt.get("targets",[]):
		var animal: Dictionary=hunt.animals[index]
		var weight: float=float(animal.meat) if animal.has("meat") else float(hunting.data.species[int(animal.kind)].meat)
		var density: float=float(animal.get("kcal_per_lb",provisions.data.food_energy.generic_meat_kcal_per_lb))
		mass+=weight;energy+=weight*density
	return energy/mass if mass>0 else float(provisions.data.food_energy.generic_meat_kcal_per_lb)
func pelt_quote(cart: Dictionary) -> Dictionary:return Pelts.quote(self,cart)
func finish_hunt(pelt_cart: Dictionary={}) -> bool:
	if hunt.is_empty():return false
	var skins: Dictionary={"selected":0,"raw_lb":0.0,"days":0}
	if not pelt_cart.is_empty():
		skins=pelt_quote(pelt_cart)
		if not skins.valid:return false
	if hunt.get("activity","")!="fish":dogs.finish_hunt(self)
	var outing: Dictionary=hunt.duplicate(true)
	if hunt.has("field"):
		for key in hunt.field.inventory:state[key]=int(state.get(key,0))+int(hunt.field.inventory[key])
		provisions.fresh.append_array(hunt.field.fresh.duplicate(true))
	# Retrieval work remains limited by health and willing helpers, but eating at camp
	# does not require the meat to fit into tomorrow's walking packs first.
	var is_fish: bool=hunt.get("activity","")=="fish"
	var retrieved: float=minf(float(hunting_capacity()),float(hunt.meat)) if is_fish else float(mini(hunting_capacity(),int(hunt.meat)))
	retrieved=minf(retrieved,maxf(0,hunting_capacity()-float(skins.raw_lb)))
	if skins.selected>0:state["_raw_hides_lb"]=float(skins.raw_lb)
	var density: float=hunt_calorie_density()
	var units: int=provisions.add_meat(retrieved,int(state.day)+1,density,not is_fish)
	if units>0:provisions.fresh.back()["_hunt_meal"]=true
	state.food+=units
	_tick_day(false,hunt.has("field") and hunt.field.kit=="wagon",str(hunt.get("activity","hunt")))
	if hunt.has("field") and hunt.field.kit!="wagon":
		var field: Dictionary=hunt.field
		var return_mode: String=str(field.get("return_mode","ride"))
		var load: float=field_outings.Outfit.mass(self,field.members,field.kit,field.inventory,field.fresh,field.stock,return_mode)+retrieved+float(skins.raw_lb)
		var profile: Dictionary=field_outings.Outfit.load_profile(self,field.members,field.kit,load,field.stock,return_mode)
		var wear: int=field_outings.Outfit.wear(self,field.kit,field.members.size(),context.region_id(self),profile.ratio,field.stock,return_mode)
		var condition: int=maxi(0,int(field.condition)-wear)
		if condition==0 and Mounts.animals(field.stock)>0:
			var kind: String=profile.worst_kind
			if kind not in Mounts.ANIMALS or int(field.stock[kind])<1:kind="horses" if int(field.stock.horses)>0 else "mules"
			field.stock[kind]-=1;condition=int(provisions.data.mounts.breakdown_condition) if Mounts.animals(field.stock)>0 else 0
			journal.append("An outing animal gave out under its load and was lost. Its surviving tack returned.")
			health_events.append("An outing animal gave out. Rest the animals or bring back a lighter load.")
		field_outings.Outfit.restore_stock(self,field.stock,condition,field.get("animal_conditions",{}),int(field.get("condition_base",100)))
	var remaining: int=0
	var ratio: float=float(retrieved)/units if units>0 else 1.0
	var batch: Dictionary={}
	for piece in provisions.fresh:
		if piece.get("_hunt_meal",false):remaining+=int(piece.pounds);batch=piece.duplicate(true)
	var eaten: float=float(hunt.get("_meal_food",0))
	var partial_mass: float=float(livestock.hunt_portion.get("lb",0))
	var partial_food: float=float(livestock.hunt_portion.get("kcal",0))/float(provisions.data.food_energy.unit_kcal)
	var other_loss: float=maxf(0,units-remaining-eaten-partial_food)
	# Remove the temporary catch to measure the actual space left after meals/illness.
	provisions.fresh=provisions.fresh.filter(func(piece):return not piece.get("_hunt_meal",false))
	state.food-=remaining
	var room: float=maxf(0,provisions.storage_capacity(state)-provisions.cargo(state))
	var keep: int=mini(remaining,maxi(0,floori(minf(room,maxf(0,hunting_capacity()-(0.0 if hunt.get("field",{}).get("kit","")=="wagon" else float(skins.raw_lb))))/ratio)))
	if keep>0:
		batch.erase("_hunt_meal")
		batch.pounds=keep
		provisions.fresh.append(batch)
		state.food+=keep
	last_hunt_recovery={"mass":keep*ratio+partial_mass,"food":keep+partial_food,"generated_food":units,"eaten_mass":eaten*ratio,"eaten_food":eaten,"retrieved":retrieved,"retrieved_kcal":provisions.meat_calories(retrieved,density),"kcal_per_lb":density,"other_loss":other_loss*ratio,"left":maxf(0,float(outing.meat)-(eaten+keep+partial_food+other_loss)*ratio)}
	journal.append((("Day %d · Fishing: %d casts, %.2f lb edible fish obtained;" if outing.get("activity","")=="fish" else "Day %d · Hunting: %d shots, %d lb obtained;")+" %.1f lb eaten at camp, %.1f lb packed (%.2f food units); %.1f lb left behind.") % [state.day,outing.shots,outing.meat,last_hunt_recovery.eaten_mass,last_hunt_recovery.mass,last_hunt_recovery.food,last_hunt_recovery.left])
	if is_fish and not outing.get("catch_log",[]).is_empty():journal.append("Fish caught: "+", ".join(outing.catch_log.map(func(f):return "%s %.2f lb whole" % [f.label,f.whole_lb])))
	hunt={}
	if skins.selected>0:
		var preparation_start: int=state.day
		if state.status=="traveling":_tick_day(false,false,"skins")
		state.erase("_raw_hides_lb")
		var packed: Dictionary={};var left: Dictionary={}
		for item in pelt_cart:
			var mass: float=provisions.data.pelts.goods[item].weight_lb
			var room_for_skins: float=maxf(0,provisions.storage_capacity(state)-provisions.cargo(state))
			var n: int=mini(int(pelt_cart[item]),floori(room_for_skins/mass)) if state.status=="traveling" else 0
			state[item]=int(state.get(item,0))+n;packed[item]=n;left[item]=int(pelt_cart[item])-n
		last_hunt_recovery["pelts"]=packed;last_hunt_recovery["pelts_left"]=left;last_hunt_recovery["preparation_days"]=int(state.day)-preparation_start
		last_hunt_recovery["preparation_food_units"]=float(livestock.last_meal.get("eaten",0)) if state.day>preparation_start else 0.0
		journal.append("Day %d - Prepared rough trade skins: %s. Preparation costs a camp day and meals; skins exceeding the surviving party's cargo space were left behind." % [state.day,str(packed)])
		supply_history.append({"day":state.day,"event":"prepared_pelts","changes":packed.duplicate(true),"left":left})
	_schedule_event(false)
	return true

func walking_distance() -> int:
	var plan: Dictionary=mount_plan()
	var burden: float=Mounts.speed_factor(plan,provisions.load_profile(state))
	var terrain:=0.8 if state.terrain=="mountains" else (0.9 if state.terrain=="forest" else 1.0)
	var base: float=float(provisions.data.walking.miles_per_day)*[1.0,1.15,1.3][state.pace]
	if plan.mode=="packing":base=float(provisions.data.walking.packing_miles_per_day)*[1.0,1.15,1.3][state.pace]
	if Mounts.mounted(plan):base=Mounts.base_miles(provisions.data.mounts,Mounts.condition(state),int(state.pace))
	return maxi(1,roundi(base*float(seasonal_pressure().travel)*float(survival.weather.speed)*terrain*burden*(1.0-float(state.fatigue)/300.0)))
func walking_overloaded() -> bool:
	if state.vehicle!="foot" or provisions.cargo(state)<=provisions.storage_capacity(state):return false
	pending={"id":"packs_too_heavy","title":"Too much to carry","text":"Your packs exceed the surviving party's carry limit. Return to camp to drop supplies, or preserve fresh meat through Camp > Preserve meat before walking on.","choices":[{"label":"Return to camp","effects":{},"result":"The party reorganizes its packs."}]}
	return true
func pack_quote(cart: Dictionary,from_cache: bool=false,guard_ids: Array=[]) -> Dictionary:return CacheSupport.quote(self,cart,from_cache,guard_ids)
func abandon_wagon(cart: Dictionary,guard_ids: Array=[]) -> bool:return CacheSupport.pack(self,cart,false,guard_ids)
func repack_wagon_cache(cart: Dictionary) -> bool:return CacheSupport.pack(self,cart,true)
func recover_wagon() -> bool:return CacheSupport.recover(self)

func ox_slaughter_offer(by_hand: bool = false) -> Dictionary:
	var rules: Dictionary = provisions.data.ox_slaughter
	if not can_service() or state.oxen <= rules.minimum_team or (not by_hand and state.bullets < rules.bullets):return {}
	# Team condition is a coarse proxy for the selected animal, not its live weight.
	var factor := float(rules.minimum_yield_factor)+(1.0-float(rules.minimum_yield_factor))*float(state.ox_health)/100.0
	return {"meat":floori(float(rules.usable_meat_lb)*factor*_butcher_factor()),"remaining":int(state.oxen)-1,"bullets":0 if by_hand else int(rules.bullets),"by_hand":by_hand,"injury_chance":float(rules.hand_injury_chance) if by_hand and ProfessionSkill.stockman(self).is_empty() else 0.0}
## A farmer leader butchers stock cleanly: more usable meat and no hand injury.
func _butcher_factor() -> float:return float(ProfessionSkill.stockman(self).get("butcher_meat_factor",1.0))

func _butcher_by_hand(offer: Dictionary,animal: String) -> void:
	journal.append("Used the household hand tools instead of ammunition.")
	if rng.randf() < offer.injury_chance:
		var living: Array = party_health.members.filter(func(member):return party_health.is_active(member))
		var worker: Dictionary = living[rng.randi_range(0,living.size()-1)]
		if not party_health.begin_condition(int(worker.id),"wound",int(state.day)+1):
			for condition in worker.conditions:
				if condition.id == "wound":condition.severity=mini(3,int(condition.severity)+1)
			worker.history.append("Day %d · Butchering aggravated an existing wound." % (int(state.day)+1))
		_collect_health_events()
		journal.append("%s was injured while butchering the %s by hand." % [worker.name,animal])

## Butchering a horse or mule at camp: less meat than an ox, scaled by the animals' condition.
## Starving packers really did eat their stock. Uses the ox rules for bullets and hand injury.
func mount_slaughter_offer(kind: String,by_hand: bool = false) -> Dictionary:
	var rules: Dictionary = provisions.data.ox_slaughter
	if kind not in Mounts.ANIMALS or not can_service() or Mounts.count(state,kind)<1 or (not by_hand and state.bullets < rules.bullets):return {}
	var meat_lb: float=float(provisions.data.mounts[{"horses":"horse","mules":"mule"}[kind]].meat_lb)
	var factor := float(rules.minimum_yield_factor)+(1.0-float(rules.minimum_yield_factor))*float(Mounts.condition(state))/100.0
	return {"kind":kind,"meat":floori(meat_lb*factor*_butcher_factor()),"remaining":Mounts.count(state,kind)-1,"bullets":0 if by_hand else int(rules.bullets),"by_hand":by_hand,"injury_chance":float(rules.hand_injury_chance) if by_hand and ProfessionSkill.stockman(self).is_empty() else 0.0}

func slaughter_mount(kind: String,by_hand: bool = false) -> bool:
	var offer := mount_slaughter_offer(kind,by_hand)
	if offer.is_empty():return false
	var name: String={"horses":"horse","mules":"mule"}[kind]
	state[kind]=int(state[kind])-1
	team_conditions.sync(self)
	state.bullets-=int(offer.bullets)
	state.food+=provisions.add_meat(int(offer.meat),int(state.day)+1)
	supply_history.append({"day":int(state.day)+1,"event":"slaughter_"+name,"changes":{kind:-1,"bullets":-int(offer.bullets),"food":provisions.meat_units(int(offer.meat))}})
	journal.append("Day %d · Butchered a %s at camp: %d lb usable fresh meat, %d bullet(s), %d %s remain." % [int(state.day)+1,name,offer.meat,offer.bullets,offer.remaining,kind])
	if by_hand:_butcher_by_hand(offer,name)
	_tick_day(false)
	_update_river_stage()
	return true

func slaughter_ox(by_hand: bool = false) -> bool:
	var offer := ox_slaughter_offer(by_hand)
	if offer.is_empty():return false
	state.oxen-=1
	team_conditions.sync(self)
	state.bullets-=int(offer.bullets)
	state.food+=provisions.add_meat(int(offer.meat),int(state.day)+1)
	# At-camp meat is available for today's meals. All usable meat is recovered,
	# even if it overloads the wagon; the hunting retrieval cap does not apply.

	supply_history.append({"day":int(state.day)+1,"event":"slaughter_ox","changes":{"oxen":-1,"bullets":-int(offer.bullets),"food":provisions.meat_units(int(offer.meat))}})
	journal.append("Day %d · Slaughtered one ox at camp: %d lb usable fresh meat, %d bullet(s), %d oxen remain. All meat recovered; meals and spoilage still apply." % [int(state.day)+1,offer.meat,offer.bullets,offer.remaining])
	if by_hand:_butcher_by_hand(offer,"ox")
	_tick_day(false)
	_update_river_stage()
	if state.status == "traveling" and pending.is_empty():_schedule_event(false)
	return true

func preservation_offer(salted: bool = false, workday: bool=false) -> Dictionary:
	if not workday and not can_service():return {}
	var plan: Dictionary=provisions.preservation_plan(int(state.day),int(state.food),int(provisions.data.rations_lb[state.rations])*int(state.party_size),int(state.party_size))
	var input: int=plan.input
	if input < 1:return {}
	var salt := ceili(float(plan.mass)*float(provisions.data.preservation.salt_per_food_lb)) if salted else 0
	if state.salt < salt:return {}
	return {"input":input,"mass":plan.mass,"salt":salt,"kept":floori(input*float(provisions.data.preservation.salted_retained_food if salted else provisions.data.preservation.retained_food)),"days":int(provisions.data.preservation.salted_days if salted else provisions.data.preservation.days)}

func preserve_meat(salted: bool = false) -> bool:
	var offer := preservation_offer(salted)
	if offer.is_empty():return false
	_tick_day(false,false,"dry") # Meals and spoilage happen before processing; never rescue spoiled meat.
	if state.status != "traveling":return true
	var input: int=mini(int(offer.input),provisions.processable())
	while salted and input>0 and ceili(provisions.fresh_mass(input)*float(provisions.data.preservation.salt_per_food_lb))>int(state.salt):input-=1
	var result := provisions.preserve(input,int(state.day),salted)
	state.food-=int(result.lost)
	state.salt-=int(result.salt)
	supply_history.append({"day":state.day,"event":"preservation","changes":{"food":-int(result.lost),"salt":-int(result.salt)},"processed":result.input,"processed_mass_lb":result.mass,"retained":result.kept,"dried_weight_lb":result.weight,"expires":result.expires})
	journal.append("Day %d · %s: %.1f lb fresh meat became %d food units dried food (%.1f lb cargo); %d lb salt used. Food value retained. Keeps up to %d days after today." % [state.day,"Salt-assisted drying" if salted else "Drying meat",result.mass,result.kept,result.weight,result.salt,offer.days])
	_update_river_stage()
	if pending.is_empty():_schedule_event(false)
	return true

func discard_supply(item: String, amount: int) -> bool:
	if not can_service() or (item not in provisions.data.weights_lb and item not in Mounts.TACK and item!="camp_greens_lb") or amount <= 0 or amount > int(state.get(item, 0)):
		return false
	if item in Mounts.TACK and amount>Mounts.loose_tack(provisions.data.mounts,state)[item]:return false
	_apply({item: -amount})
	if item=="camp_greens_lb" and state.camp_greens_lb==0:state.camp_greens_expires=0
	journal.append("Day %d · Left %d %s behind to lighten the %s." % [state.day, amount, item, "wagon" if state.vehicle=="wagon" else "packs"])
	return true

func journey_summary() -> String:
	var survivors: Array[String] = []
	var remembered: Array[String] = []
	var departed: Array[String] = []
	for member in party_health.members:
		if member.get("departed",false):
			departed.append("%s (day %d)" % [member.name,member.departure_day])
		elif party_health.is_active(member):
			survivors.append(member.name)
		else:
			remembered.append("%s (day %d)" % [member.name,member.death_day])
	return "%d TRAVELERS FINISHED WITH THE PARTY\n%d days · %d reported guide miles\nSurvivors: %s\nDeaths: %s\nLeft party: %s\nFood %d lb · Cash $%.2f" % [survivors.size(),state.day,state.miles,", ".join(survivors),", ".join(remembered) if not remembered.is_empty() else "None",", ".join(departed) if not departed.is_empty() else "None",state.food,state.money]

## Stop choices that depend on what the party has done here: tolls, and a ferry crew it robbed or that has heard of it.
func refresh_stop_offers() -> void:
	_refresh_toll_offer()
	if not pending.has("landmark") or pending.landmark!=state.landmark:
		return
	for choice in pending.choices:
		if choice.get("method","")=="ferry" and route.nodes[state.landmark].has("ferry_dollars"):
			var node: Dictionary=route.nodes[state.landmark]
			var fare: float=(float(node.get("ferry_high_dollars",node.ferry_dollars)) if state.river_stage=="high" else float(node.ferry_dollars))*maxi(1,Train.count(state))+float(livestock.data.ferry_head_cents)/100.0*(livestock.count(state,"dairy_cows")+livestock.count(state,"goats"))
			choice.requires={"money":fare};choice.effects.money=-fare
			choice.label="Hire the ferry · $%.2f, 1 day" % fare
		if choice.get("method","")=="ferry" and crime.ferry_refused(self,str(state.landmark)):
			choice.label="The ferry crew will not carry your party"
	if not crime.scenes.has(state.landmark):
		return
	if crime.passage(str(state.landmark)) and crime.scenes[state.landmark].kind=="ferry" and not pending.choices.any(func(choice):return choice.get("method","")=="seized"):
		# Appended so the stop's existing choice indices never shift.
		pending.choices.append({"label":"Cross on the taken ferry, without its crew · 1 day, risk to supplies","action":"cross","method":"seized","effects":{"days":1},"risk":crime.seized_risk(self,str(state.landmark))})

func _refresh_toll_offer() -> void:
	if pending.get("retreat_without_crossing",false):return
	if not pending.has("landmark"):
		return
	var node: Dictionary = route.nodes[state.landmark]
	if not node.has("toll_dollars"):
		return
	if crime.passage(str(state.landmark)):
		for choice in pending.choices:
			if choice.get("action","") == "leave":
				choice.label = "Continue down the road · the toll was not paid"
				choice["requires"] = {}
				choice["effects"] = {}
		return
	var toll := snappedf((0.0 if state.vehicle=="foot" else float(node.toll_dollars)*Train.count(state)) + float(node.get("toll_per_ox",0)) * (int(state.oxen)+livestock.count(state,"dairy_cows")+livestock.count(state,"goats")),0.01)
	for choice in pending.choices:
		if choice.get("action","") == "leave":
			choice.label = "Pay Barlow toll · $%.2f, then continue" % toll
			if state.vehicle=="foot":choice.label="Continue on foot · no wagon toll" if toll==0 else "Pay stock toll · $%.2f" % toll
			choice["requires"] = {"money":toll}
			choice["effects"] = {"money":-toll}


func pasture_assessment() -> Dictionary:return Pasture.assess(self)

## High country where winter snow can block the road and starve animals: the stop just left or the one ahead.
func snow_country() -> Dictionary:
	if not state.extended_route:return {}
	var month: int=int(calendar().month)
	# Camped at a landmark below the pass (leg not begun) is a sheltered valley: safer, not safe.
	# No drifts stop the wagon there, but grazing is still poor, so animals lose a little each day.
	for place in [str(state.landmark),str(state.next_landmark)]:
		if route.nodes.has(place) and route.nodes[place].has("snow_country") and route.nodes[place].snow_country.months.any(func(m):return int(m)==month):
			var rules: Dictionary=route.nodes[place].snow_country.duplicate()
			rules["place"]=place
			if place!=str(state.landmark) and int(state.leg_miles)==0:
				rules["sheltered"]=true
				rules["snowbound_chance"]=0.0
				rules["animal_strain"]=int(rules.get("valley_strain",0))
			return rules
	return {}
## Deep snow: no grazing, so animals lose condition even in camp; worn-out animals die.
func _snow_starvation() -> void:
	var snow: Dictionary=snow_country()
	if snow.is_empty():return
	var strain: int=int(snow.get("animal_strain",0))
	if int(state.oxen)>0:
		state.ox_health=maxi(0,int(state.ox_health)-strain)
		team_conditions.settle(self)
		if int(state.ox_health)==0 and rng.randf()<float(snow.get("death_chance",0)):
			_apply({"oxen":-1})
			journal.append("Day %d · An ox, starved and worn out, died in the snow near %s." % [state.day,route.nodes[snow.place].name])
			_offer_carcass("ox",float(provisions.data.ox_slaughter.usable_meat_lb),str(snow.place))
	if Mounts.animals(state)>0:
		state["horse_health"]=maxi(0,Mounts.condition(state)-strain)
		team_conditions.settle(self)
		if Mounts.condition(state)==0 and rng.randf()<float(snow.get("death_chance",0)):
			var kind: String="mules" if int(state.get("mules",0))>0 else "horses"
			_apply({kind:-1})
			journal.append("Day %d · A %s starved in the snow near %s." % [state.day,"mule" if kind=="mules" else "horse",route.nodes[snow.place].name])
			var animal: String="mule" if kind=="mules" else "horse"
			_offer_carcass(animal,float(provisions.data.mounts[animal].meat_lb),str(snow.place))
## A starved animal is still meat: offer to butcher the carcass (no bullet needed) or leave it.
## The yield is the worn-out minimum, since the animal died at its lowest condition.
func _offer_carcass(animal: String,full_lb: float,place: String) -> void:
	if not pending.is_empty() or state.status!="traveling":
		journal.append("With no time to spare, the %s was left where it fell." % animal)
		return
	var meat: int=floori(full_lb*float(provisions.data.ox_slaughter.minimum_yield_factor)*_butcher_factor())
	pending={"id":"snow_carcass","category":"historical","title":"A %s died in the snow" % animal,
		"text":"The %s starved near %s. Its carcass is thin but still meat, and the cold will keep it." % [animal,route.nodes[place].name],
		"choices":[
			{"label":"Butcher the %s · 1 day, about %d lb of meat" % [animal,meat],"carcass_meat":meat,"carcass_animal":animal,"effects":{},"result":"You butcher the %s where it fell." % animal},
			{"label":"Leave it in the snow","effects":{},"result":"You leave the %s where it fell." % animal}]}
func _butcher_carcass(choice: Dictionary) -> bool:
	pending={}
	var meat: int=int(choice.carcass_meat)
	state.food+=provisions.add_meat(meat,int(state.day)+1)
	supply_history.append({"day":int(state.day)+1,"event":"butcher_carcass","changes":{"food":provisions.meat_units(meat)}})
	journal.append("Day %d · Butchered the dead %s: %d lb of thin meat. Meals and spoilage still apply." % [int(state.day)+1,str(choice.carcass_animal),meat])
	_tick_day(false)
	if state.status=="traveling" and pending.is_empty():_schedule_event(false)
	return true
## Snow shuts a mountain wagon road for the season; walkers and pack trains can still go around.
## The Columbia's winter: its rules when this month is a river winter, else {}.
func river_winter() -> Dictionary:
	var rules: Dictionary=route.nodes.get("columbia_raft",{}).get("river_winter",{})
	if not state.extended_route or rules.is_empty() or not rules.months.any(func(m):return int(m)==int(calendar().month)):return {}
	return rules
## Some winters are hard enough to freeze the lower Columbia (January 1847 at Vancouver). Each winter is hard or not
## for the whole journey, drawn from the seed apart from the game's dice, so waiting a day never changes it.
func hard_winter(year: int) -> bool:
	var rules: Dictionary=route.nodes.get("columbia_raft",{}).get("river_winter",{})
	if rules.is_empty():return false
	var dice:=RandomNumberGenerator.new()
	dice.seed=("%d|river_ice|%d" % [int(state.seed),year]).hash()
	return dice.randf()<float(rules.hard_winter_chance)
func river_frozen() -> bool:
	var rules: Dictionary=river_winter()
	return not rules.is_empty() and rules.frozen_months.any(func(m):return int(m)==int(calendar().month)) and hard_winter(int(calendar().year))
func road_closed(place: String) -> bool:
	return state.vehicle!="foot" and route.nodes.has(place) and route.nodes[place].get("wagon_closed_months",[]).any(func(m):return int(m)==int(calendar().month))
func closed_months_text(place: String) -> String:
	var months: Array=route.nodes[place].wagon_closed_months
	var names: Array=["January","February","March","April","May","June","July","August","September","October","November","December"]
	return "%s to %s" % [names[int(months[0])-1],names[int(months[-1])-1]]
func seasonal_pressure() -> Dictionary:
	return survival.seasonal(int(calendar().month),str(state.terrain),context.region(self))

func season_notice(days_ahead: int=0) -> String:
	if not state.extended_route:return ""
	var date: Dictionary=Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_dict(calendar()))+maxi(0,days_ahead)*86400)
	var month: int=int(date.month)
	for place in [str(state.landmark),str(state.next_landmark)]:
		if route.nodes.has(place) and route.nodes[place].has("snow_country") and route.nodes[place].snow_country.months.any(func(m):return int(m)==month):
			if place!=str(state.landmark) and int(state.leg_miles)==0:return "Winter below %s: the valley is sheltered but grass is poor, and the animals slowly weaken. Drifts on the climb can stop the wagon for days." % route.nodes[place].name
			return "Winter in snow country near %s: drifts can stop the wagon for days, and with no grass the animals weaken and can die." % route.nodes[place].name
	var river: Dictionary=route.nodes.get("columbia_raft",{}).get("river_winter",{})
	var near_river: bool=str(state.landmark) in ["the_dalles","columbia_raft"] and (int(state.leg_miles)==0 or current_edge().get("hazard","")=="river")
	if not river.is_empty() and near_river and river.months.any(func(m):return int(m)==month):
		if days_ahead==0 and river_frozen():return "The Columbia is frozen over. No raft can be launched until the ice breaks up, likely in March."
		return "Winter on the Columbia: east winds pin rafts to the shore, the cold wears on everyone afloat, and a wreck in icy water is deadlier. In a hard winter the river freezes over in January and February."
	if month in survival.data.seasonal.winter_months:return "Winter: slow roads and poor grazing. Clothes reduce, but do not erase, blizzard exposure."
	if month in [9,10]:
		var ahead: Array=[]
		for place in ["south_pass","blue_mountains","barlow_pass"]:
			if route.nodes.has(place) and place not in travelled_path():ahead.append(route.nodes[place].name)
		if not ahead.is_empty():return "Autumn: snow closes the high country from November (%s). Late parties risk snowbound days, starving animals and a shut Barlow road." % ", ".join(ahead)
	if month in [9,10]:return "Autumn: mountain snow is approaching. Longer stops risk worse roads and grazing."
	if month in [3,4] and seasonal_pressure().upland:return "Spring: snow can still slow upland travel."
	return ""


func current_party_slots() -> Array:
	return recruitment.slots(self)

func open_native_contacts() -> bool:return native_encounters.open(self)

func open_companions() -> bool:
	return recruitment.open(self)

func open_dismiss(target: int) -> bool:
	return recruitment.open_dismiss(self,target)


func open_local_attack(uid: String) -> bool:
	var people: Array=crime.local_targets(self).filter(func(person):return person.uid==uid)
	if people.is_empty():return false
	service_return=pending.duplicate(true)
	pending={"crime_menu":true,"crime_target":uid,"crime_place":people[0].place}
	pending=crime.menu(self)
	return true


func adapt_travel_event(content: Dictionary) -> void:
	if content.get("id","")=="horse_thieves":_adapt_horse_thieves(content)
	if state.vehicle!="foot" or content.get("choices",[]).size()<2:return
	_adapt_wagonless(content)
	if content.get("id","")=="ox_injury":
		content.text="An ox travelling with your party injures its leg. You are on foot; there is no wagon to pull. The animal's condition will matter if you hitch the wagon again."
		content.choices[0].label="Rest the herd · 1 day"
		content.choices[0].result="You stop walking and give the oxen time to recover."
		content.choices[1].label="Keep walking with the oxen"
		content.choices[1].result="You continue on foot with the injured ox."
	elif content.get("id","")=="wandering_ox":
		content.text="One animal is missing when you count the oxen travelling alongside your party."
		content.choices[1].result="You keep walking with fewer oxen."


## Without a wagon, encounters speak of the party, and "team strain" falls on whatever animals
## carry the party: saddle and pack animals first, else any herded oxen, else nobody.
func _adapt_wagonless(content: Dictionary) -> void:
	var animals: int=Mounts.animals(state)
	var words: Array=[["away from the wagon","away from camp"],["the wagons","the party"],["the wagon","the party"],["Defend the wagon","Defend the party"]]
	for pair in words:content.text=str(content.get("text","")).replace(pair[0],pair[1])
	for choice in content.get("choices",[]):
		for pair in words:
			choice.label=str(choice.get("label","")).replace(pair[0],pair[1])
			choice.result=str(choice.get("result","")).replace(pair[0],pair[1])
		for effects in [choice.get("effects",{}),choice.get("risk",{}).get("effects",{})]:
			if not effects.has("ox_health"):continue
			if animals>0:effects["horse_health"]=effects.ox_health
			if animals>0 or int(state.oxen)==0:effects.erase("ox_health")
		if animals>0:
			choice.label=choice.label.replace("team strain","horses strained")
			choice.result=choice.result.replace("the team is strained","the horses are blown")
		elif int(state.oxen)==0:
			choice.label=choice.label.replace(", team strain","")
			choice.result=choice.result.replace(", but the team is strained","")

func discard_supplies(cart: Dictionary) -> bool:
	var plan: Dictionary=preload("res://simulation/discard_plan.gd").quote(self,cart)
	if not plan.valid:return false
	for item in cart:
		if int(cart[item])>0:discard_supply(item,int(cart[item]))
	return true

func produce_drying_offer() -> Dictionary:return Produce.drying_offer(self)
func dry_produce() -> bool:return Produce.dry(self)

func turn_direction(to: String) -> bool:
	var changed: bool=Direction.turn(self,to)
	if changed and to=="east":native_encounters.Story.end_guide(native_encounters,self,"the party turned east")
	return changed

func inspect_cached_wagon() -> bool:return CacheSupport.inspect(self)

func set_lead_mounts(on: bool) -> bool:
	if not can_service() or state.vehicle!="foot" or Mounts.animals(state)==0:return false
	state["lead_mounts"]=on
	return true
func set_strenuous_load(on: bool) -> bool:
	if not can_service() or state.vehicle!="foot" or Mounts.animals(state)==0:return false
	state["strenuous_load"]=on
	return true

## Cascades prototype: launch is atomic; calendar time and consequences settle once on return.
func start_rafting() -> bool:
	if not can_service() or state.landmark!="columbia_raft" or not pending.has("landmark"):return false
	var candidate: Dictionary=rafting.begin(int(state.seed),int(state.day))
	if candidate.is_empty():return false
	raft=candidate
	pending={};last_rafting={}
	journal.append("Day %d · Launched into the Cascades. Steering determines collisions; portage was available before launching." % state.day)
	return true
func advance_rafting(delta: float,target: float) -> void:
	if not raft.is_empty():rafting.tick(raft,delta,target)
func finish_rafting() -> bool:
	if raft.is_empty() or not raft.ended:return false
	var session: Dictionary=raft.duplicate(true)
	var losses: Dictionary=rafting.losses(session)
	# Icy water drowns a wrecked crew more often.
	if not river_winter().is_empty():losses.drowning=bool(session.wrecked) and float(session.drowning_roll)<float(rafting.data.drowning_chance_on_wreck)*float(river_winter().wreck_drowning_factor)
	_tick_day(false,false,"raft")
	var impact_survivors: Array=party_health.members.filter(func(m):return party_health.is_active(m)).map(func(m):return int(m.id))
	var before_food: int=state.food;var before_clothes: int=state.clothing
	_apply({"food":-int(losses.food),"clothing":-int(losses.clothing)},"rafting injuries")
	var injured: int=-1;var drowned: int=-1
	if state.status=="traveling" and bool(losses.wrecked):_change_health(-int(rafting.data.wreck_health_loss),"near drowning")
	var living: Array=party_health.members.filter(func(m):return party_health.is_active(m))
	if not living.is_empty():
		var victim: Dictionary=living[int(session.victim_roll)%living.size()]
		if bool(losses.drowning):
			drowned=int(victim.id);party_health.kill(victim,int(state.day),"drowning in the Cascades")
		elif bool(losses.injury):
			injured=int(victim.id)
			party_health.affect(victim,-3*int(losses.hits),int(state.day),"rafting injuries")
			if party_health.is_active(victim):party_health.begin_condition(injured,"broken_arm" if int(losses.hits)>=3 else "wound",int(state.day),1)
	_change_health(0,"rafting injuries")
	_check_health()
	var deaths: Array=impact_survivors.filter(func(id):return not party_health.members[int(id)].alive)
	last_rafting={"deaths":deaths,"place":"columbia_raft","day":int(state.day),"hits":int(session.hits),"wrecked":bool(session.wrecked),"food_lost":before_food-int(state.food),"clothing_lost":before_clothes-int(state.clothing),"elapsed_ticks":int(session.ticks),"integrity":int(session.integrity),"injured":injured,"drowned":drowned}
	rafting_history.append(last_rafting.duplicate(true))
	var text: String="Cascades: %d impact(s), %d%% hull remaining. Lost %d food units and %d clothing set(s)." % [last_rafting.hits,last_rafting.integrity,last_rafting.food_lost,last_rafting.clothing_lost]
	if not deaths.is_empty():text+=" Lost: "+", ".join(deaths.map(func(id):return str(party_health.members[int(id)].name)))+"."
	if drowned>=0:text+=" %s drowned." % party_health.members[drowned].name
	elif injured>=0 and party_health.members[injured].alive:text+=" %s suffered rafting injuries." % party_health.members[injured].name
	journal.append("Day %d · %s" % [state.day,text])
	supply_history.append({"day":int(state.day),"event":"columbia_rapids","changes":{},"outcome":last_rafting.duplicate(true)})
	raft={};pending={}
	if state.status=="traveling":
		if bool(losses.wrecked):journal.append("The survivors make shore, salvage the remaining cargo and lash together a replacement raft.")
		journal.append("Leaving the Cascades for the lower Columbia and Willamette.")
		_set_next_leg();_schedule_event(false)
	return true
func upgrade_rafting_choice(menu: Dictionary) -> void:
	if menu.get("landmark","")!="columbia_raft":return
	for choice in menu.get("choices",[]):
		if choice.has("portage_risk"):
			choice.erase("portage_risk");choice["rafting"]=true
			choice.label="Run the rapids · steer the raft · 1 day"


## A shot needs both a ball and a gun to fire it.
func can_fire() -> bool:return int(state.bullets)>0 and Armory.firearms(state)>0
## Hunting takes a rifle or shotgun; a pistol is no hunting arm.
func can_hunt_with_gun() -> bool:return int(state.bullets)>0 and Armory.long_guns(state)>0
func start_tactical_combat(command: String = "") -> bool:
	if state.status != "traveling":
		return false
	if command.begins_with("trail"):
		var trail_cfg := _build_trail_tactical_config(command)
		if trail_cfg.is_empty():
			return false
		trail_cfg["combat_wins"] = combat.victories()
		trail_cfg["leader_veteran"] = ProfessionSkill.background(self) == "Soldiering"
		trail_cfg["leader_background"] = ProfessionSkill.background(self)
		Armory.equip(trail_cfg, state)
		tactical_session = tactical.start_session(trail_cfg)
		last_tactical = {}
		return not tactical_session.is_empty()
	if command == "shoot" and crime.incident().is_empty():
		if not crime.begin_tactical_shoot(self):
			return false
	var cfg: Dictionary = crime.build_tactical_config(self, command)
	if cfg.is_empty():
		return false
	cfg["combat_wins"] = combat.victories()
	cfg["leader_veteran"] = ProfessionSkill.background(self) == "Soldiering"
	cfg["leader_background"] = ProfessionSkill.background(self)
	Armory.equip(cfg, state, crime.Detention.prisoners(crime, crime.incident()))
	tactical_session = tactical.start_session(cfg)
	last_tactical = {}
	return not tactical_session.is_empty()


func _build_trail_tactical_config(command: String) -> Dictionary:
	var ev_id := String(pending.get("id", ""))
	if ev_id not in ["bandits", "riders", "cayuse_riders", "horse_thieves"]:
		return {}
	# Fighting always means the grid; a party out of balls chasing horse thieves fights with clubbed rifles.
	if bool(pending.get("friendly", false)) or (not can_fire() and ev_id != "horse_thieves"):
		return {}
	var choices: Array = pending.get("choices", [])
	var choice_idx := -1
	if command.begins_with("trail:"):
		choice_idx = int(command.substr(6))
	else:
		for i in range(choices.size()):
			var ch: Dictionary = choices[i]
			if ch.has("combat") or (ev_id == "horse_thieves" and ch.has("risk")):
				choice_idx = i
				break
	if choice_idx < 0 or choice_idx >= choices.size():
		return {}
	var choice: Dictionary = choices[choice_idx]
	if not (choice.has("combat") or (ev_id == "horse_thieves" and choice.has("risk"))):
		return {}
	var tactic := String(choice.get("combat", "defend"))
	var squad: Array = []
	for member in party_health.members:
		if not party_health.is_active(member):
			continue
		var mid := int(member.id)
		if mid != 0 and not bool(characters.willing(mid, "defend")):
			continue
		var profile: Dictionary = characters.profiles[mid] if mid < characters.profiles.size() else {}
		squad.append({
			"id": str(mid),
			"slot": mid,
			"name": String(member.name),
			"role": "leader" if mid == 0 else "companion",
			"health": int(member.health),
			"broken_leg": member.conditions.any(func(c): return c.id == "broken_leg"),
			"broken_arm": member.conditions.any(func(c): return c.id == "broken_arm"),
			"wound": member.conditions.any(func(c): return c.id == "wound"),
			"profile": profile,
		})
	if squad.is_empty():
		for member in party_health.members:
			if party_health.is_active(member):
				var mid := int(member.id)
				squad.append({
					"id": str(mid),
					"slot": mid,
					"name": String(member.name),
					"role": "leader",
					"health": int(member.health),
					"broken_leg": member.conditions.any(func(c): return c.id == "broken_leg"),
					"broken_arm": member.conditions.any(func(c): return c.id == "broken_arm"),
					"wound": member.conditions.any(func(c): return c.id == "wound"),
					"profile": characters.profiles[mid] if mid < characters.profiles.size() else {},
				})
				break
	if squad.is_empty():
		return {}

	var seed_val: int = int(state.seed) ^ (int(state.day) * 2654435761) ^ int(ev_id.hash()) ^ (choice_idx * 40503)
	var enemy_specs: Array = []
	match ev_id:
		"bandits":
			enemy_specs = [
				{"id": "bandit_0", "name": " Silas Pike", "role": "bandit_leader", "health": 100},
				{"id": "bandit_1", "name": "Red Harned", "role": "highwayman", "health": 95},
				{"id": "bandit_2", "name": "Crowley", "role": "outlaw", "health": 90},
			]
		"riders":
			enemy_specs = [
				{"id": "rider_0", "name": "Lead Rider", "role": "raider", "health": 100},
				{"id": "rider_1", "name": "Flank Rider", "role": "raider", "health": 95},
				{"id": "rider_2", "name": "Rear Rider", "role": "outlaw", "health": 90},
			]
		"cayuse_riders":
			enemy_specs = [
				{"id": "cayuse_0", "name": "Cayuse Scout", "role": "warrior", "health": 100},
				{"id": "cayuse_1", "name": "Cayuse Rider", "role": "warrior", "health": 95},
				{"id": "cayuse_2", "name": "Cayuse Marksman", "role": "scout", "health": 95},
			]
		"horse_thieves":
			enemy_specs = [
				{"id": "thief_0", "name": "Stock Rustler", "role": "rustler", "health": 95},
				{"id": "thief_1", "name": "Picket Thief", "role": "thief", "health": 90},
			]
	var AppearanceGen = preload("res://simulation/traveler_appearance.gd")
	var enemies: Array = []
	for spec in enemy_specs:
		var uid := String(spec.get("id", "enemy"))
		var h := absi(int((ev_id + ":" + uid + ":" + str(state.day)).hash()))
		enemies.append({
			"uid": uid,
			"id": uid,
			"name": String(spec.get("name", "Outlaw")).strip_edges(),
			"role": String(spec.get("role", "outlaw")),
			"health": int(spec.get("health", 95)),
			"soldier": false,
			"profile": {"appearance": AppearanceGen.generate(int(state.seed), h)},
		})

	var venue_kind := "emigrants" if tactic == "circle" else "traders"
	var place_name := "The Trail"
	if route.nodes.has(state.landmark):
		place_name = "Near " + String(route.nodes[state.landmark].get("name", "the Trail"))
	var custom_title := String(pending.get("title", "Trail Skirmish"))
	var custom_subtitle := "Wagon Circle Defense" if tactic == "circle" else "Roadside Skirmish"
	return {
		"seed": seed_val,
		"venue_kind": venue_kind,
		"place": ev_id,
		"place_name": place_name,
		"title": custom_title,
		"subtitle": custom_subtitle,
		"reason": ev_id,
		"command": command,
		"mode_source": "trail_event",
		"event_id": ev_id,
		"choice_index": choice_idx,
		"tactic": tactic,
		"bullets": int(state.bullets),
		"squad": squad,
		"enemies": enemies,
	}


## The event's own way out (flee, run, turn aside): a plain choice that costs time and no fight.
func _trail_escape_choice(choices: Array) -> Dictionary:
	for ch in choices:
		var fx: Dictionary = ch.get("effects", {})
		if int(fx.get("days", 0)) > 0 and not ch.has("combat") and not ch.has("risk") and not ch.has("requires"):
			return ch
	return {}


func tactical_step(action: Dictionary) -> Dictionary:
	if tactical_session.is_empty():
		return {}
	return tactical.step(tactical_session, action)


func finish_tactical_combat() -> bool:
	if tactical_session.is_empty() or not bool(tactical_session.get("resolved", false)):
		return false
	var session := tactical_session.duplicate(true)
	tactical_session = {}
	last_tactical = session
	if String(session.get("mode_source", "")) == "trail_event":
		_apply_trail_tactical_result(session)
	else:
		crime.apply_tactical_result(self, session)
	return true


func _apply_trail_tactical_result(session: Dictionary) -> void:
	var choices: Array = pending.get("choices", [])
	var idx := int(session.get("choice_index", 0))
	if idx < 0 or idx >= choices.size():
		pending = {}
		return
	var choice: Dictionary = choices[idx]
	var fight_id := String(session.get("event_id", pending.get("id", "")))
	var tactic := String(session.get("tactic", choice.get("combat", "defend")))
	var outcome_raw := String(session.get("outcome", "victory"))

	# 1. Deduct ammunition actually spent during the firefight.
	var spent := maxi(0, int(state.bullets) - int(session.get("bullets_left", state.bullets)))
	if spent > 0:
		_apply({"bullets": -spent})

	# 2. Apply non-bullet effects from the chosen option (days, and recovered horses on victory).
	var fx: Dictionary = choice.get("effects", {}).duplicate(true)
	fx.erase("bullets")
	if fight_id == "horse_thieves" and outcome_raw != "victory":
		fx.erase("horses")
		fx.erase("mules")
	if not fx.is_empty():
		_apply(fx, "injuries", bool(choice.get("rest", false)))

	# 3. Sync player unit HP losses and injuries back to party_health.
	var hit := false
	var fatal := false
	var primary_victim: int = clampi(int(pending.get("member_id", 0)), 0, maxi(0, party_health.members.size() - 1))
	var units: Array = session.get("units", [])
	for u in units:
		if String(u.get("team", "")) != "player":
			continue
		var slot := int(str(u.get("id", "-1")))
		if slot < 0 or slot >= party_health.members.size():
			continue
		var m: Dictionary = party_health.members[slot]
		if not party_health.is_active(m):
			continue
		var hp_after := clampi(int(u.get("health", m.health)), 0, 100)
		var hp_before := int(m.health)
		if hp_after <= 0:
			hit = true
			fatal = true
			primary_victim = slot
			m.history.append("Day %d · Killed during an armed confrontation." % state.day)
			party_health.kill(m, int(state.day), "confrontation injuries")
		elif hp_after < hp_before:
			if not fatal:
				primary_victim = slot
			hit = true
			m.history.append("Day %d · Hit during an armed confrontation." % state.day)
			party_health.affect(m, hp_after - hp_before, int(state.day), "confrontation injuries")
			if not m.alive:
				fatal = true
			else:
				if int(u.get("wounds_taken", 0)) > 0 or (hp_before - hp_after) >= 12:
					var sev := clampi(int(u.get("wound_severity", choice.get("risk", {}).get("severity", 2))), 1, 3)
					if not party_health.begin_condition(slot, "wound", int(state.day), sev):
						for active in m.conditions:
							if active.id == "wound":
								active.severity = maxi(int(active.severity), sev)
				if bool(u.get("new_broken_leg", false)):
					party_health.begin_condition(slot, "broken_leg", int(state.day), 2)
				if bool(u.get("new_broken_arm", false)):
					party_health.begin_condition(slot, "broken_arm", int(state.day), 2)
	if hit:
		_collect_health_events()
		if not party_health.members.is_empty():
			state.health = party_health.average_health()
			state.party_size = party_health.living_count()

	# 4. Handle outcome narrative & penalties on retreat/surrender/defeat.
	if outcome_raw == "victory":
		journal.append(String(choice.get("result", "The attackers are driven off.")))
	elif outcome_raw == "retreated":
		# Breaking off a fight costs at least what fleeing would have cost from the start.
		var escape: Dictionary = {} if fight_id == "horse_thieves" else _trail_escape_choice(choices)
		if not escape.is_empty():
			_apply(escape.get("effects", {}))
			journal.append(String(escape.get("result", "You pull the party back from the skirmish under fire.")))
		else:
			if int(state.oxen) > 0:
				_apply({"ox_health": -10})
			elif Mounts.animals(state) > 0:
				_apply({"horse_health": -10})
			if fight_id == "horse_thieves":
				journal.append("You pull back under fire; the thieves drive off the stolen stock.")
			else:
				journal.append("You pull the party back from the skirmish under fire.")
	else:
		if fight_id == "bandits" and choices.size() > 0 and bool(choices[0].get("bandit_payment", false)):
			_apply(choices[0].get("effects", {}))
			combat.BanditDemand.finish(self, choices[0])
			journal.append(String(choices[0].get("result", "The thieves take what they demanded.")))
		elif fight_id == "horse_thieves":
			journal.append("The thieves hold you off and escape with the stolen stock.")
		else:
			journal.append("You are forced to yield ground before the attackers move on.")

	# 5. Record in combat.history for bandits/riders/cayuse_riders and trigger companion defense hook.
	if choice.has("combat") and fight_id in ["bandits", "riders", "cayuse_riders"]:
		var hist_outcome: String = ("fatal" if fatal else "injured") if hit else ("won" if (tactic == "defend" and outcome_raw == "victory") else "deterred")
		var quoted_risk: float = clampf(float(choice.get("quoted_risk", choice.get("risk", {}).get("probability", 0.25))), 0.0, 1.0)
		combat.history.append({
			"day": int(state.day),
			"event": fight_id,
			"tactic": tactic if tactic in ["defend", "circle"] else "defend",
			"outcome": hist_outcome,
			"victim": primary_victim,
			"risk": quoted_risk,
		})
		if tactic == "defend" and outcome_raw == "victory":
			characters.defense(self)
		var v_name: String = String(party_health.members[primary_victim].name) if primary_victim < party_health.members.size() else "A traveler"
		journal.append("Day %d · Defense outcome: %s. %s" % [
			state.day,
			hist_outcome,
			(v_name + (" died during this encounter." if hist_outcome == "fatal" else " was wounded; inspect their condition.")) if hit else "No traveler was injured in this confrontation."
		])

	pending = {}
	_check_health()
	if state.status == "traveling":
		if bool(choice.get("complete", false)):
			state.status = "arrived"
		else:
			_schedule_event(false)


