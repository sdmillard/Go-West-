extends RefCounted
## Pure simulation: no UI nodes, wall-clock time, input, or global RNG.
const Catalog = preload("res://simulation/event_catalog.gd")
const Outfitting = preload("res://simulation/outfitting.gd")
const Route = preload("res://simulation/route_catalog.gd")
const PartyHealth = preload("res://simulation/party_health.gd")
const Survival = preload("res://simulation/survival_rules.gd")
const CacheSupport=preload("res://simulation/wagon_cache.gd")
const Remains=preload("res://simulation/remains.gd")
var wagon_cache: Dictionary={}
const MAX_TRAVELERS := 32
const PARTY_CAPACITY := 5
var recruitment=preload("res://simulation/party_recruitment.gd").new()
var social=preload("res://simulation/party_social.gd").new()
var context=preload("res://simulation/trail_context.gd").new()
var combat=preload("res://simulation/combat.gd").new()
var crime=preload("res://simulation/crime_system.gd").new()
var news=preload("res://simulation/trail_news.gd").new()
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
## cost of a wreck when running the Cascades instead of portaging.
const RIVER := {"miles": 15, "portage_days": 2, "portage_risk": 0.3, "wreck": {"food": -60, "clothing": -1, "health": -15}}
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
var hunting = preload("res://simulation/hunting.gd").new()
var hunting_outings := 0
var hunt: Dictionary = {}
var supply_history: Array[Dictionary] = []
var provisions = preload("res://simulation/provisions.gd").new()

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
	state.party = cleaned
	party_health.start(cleaned, int(state.seed))
	characters.start(int(state.seed),cleaned.size())
	if not customization.is_empty():characters.profiles.assign(customization.profiles.duplicate(true))
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
	state.bullets = int(cart.get("bullet_boxes", 0)) * 20
	state.parts = state.wheels + state.axles + state.tongues
	state.pace = 0
	state.rations = 2
	state.status = "traveling"
	for key in customization.get("contracts",{}):
		var terms: Dictionary=customization.contracts[key]
		characters.start_contract(self,int(key),int(terms.wage_cents),int(terms.interval_days))
	journal.append("Departed %s 1, 1848 as a %s. Party: %s." % [str(month), profession, ", ".join(cleaned)])
	journal.append("Supplies cost $%.2f. Cash remaining: $%.2f." % [float(quote.total_cents) / 100.0, state.money])
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

func _arrive_landmark() -> void:
	route_path = travelled_path().duplicate()
	state.landmark = state.next_landmark
	route_path.append(state.landmark)
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
		state.river_stage = "high" if rng.randf() < survival.river_high_chance(int(calendar().month), node.get("river_source","rain")) or survival.wet_ground >= 4 else "low"
		description += river_conditions()
		if node.has("ferry_dollars"):
			# Ferrymen on the snow-fed rivers charged by the current: high water could double the fare.
			var fare: float=float(node.get("ferry_high_dollars",node.ferry_dollars)) if state.river_stage=="high" else float(node.ferry_dollars)
			options.append({"label": "Hire the ferry · $%.2f, 1 day" % fare,
				"action": "cross", "method": "ferry", "requires": {"money": fare}, "effects": {"money": -fare, "days": 1}})
		options.append({"label": "Attempt a ford · 1 day, risk to supplies", "action": "cross", "method": "ford", "effects": {"days": 1}, "risk": 0.65 if state.river_stage == "high" else 0.08})
		options.append({"label": "Prepare and float · 1 day, risk to supplies", "action": "cross", "method": "float", "effects": {"days": 1}, "risk": 0.35 if state.river_stage == "high" else 0.2})
		if state.vehicle=="foot":
			options=options.filter(func(option):return option.get("method","")=="ferry")
			options.append({"label":"Swim across with packs · 1 day, high injury / supply-loss risk","action":"cross","method":"swim","effects":{"days":1},"risk":swimming_risk()})
	else:
		for index in range(node.next.size()):
			var road: Dictionary = node.next[index]
			var leave := {"label": road.get("label", "Continue toward " + route.nodes[road.to].name), "action": "leave"}
			if index > 0:
				leave["edge"] = index
			if road.has("effects"):
				leave["effects"] = road.effects.duplicate()
			options.append(leave)
	if node.get("descent",false):
		options[0] = {"label":"Lower wagons carefully · 2 days", "action":"leave", "effects":{"days":2}}
		if state.vehicle=="foot":options[0]={"label":"Descend carefully on foot · 1 day","action":"leave","effects":{"days":1}}
		else:options.insert(1,{"label":"Hurry the descent · 1 day, cargo/injury risk", "action":"leave", "effects":{"days":1}, "descent_risk":0.25})
	if node.get("portage",false):
		options[0] = {"label":"Portage around the rapids · %d days" % int(RIVER.portage_days), "action":"leave", "effects":{"days":int(RIVER.portage_days)}}
		options.insert(1,{"label":"Run the rapids · 1 day, risk of wreck", "action":"leave", "effects":{"days":1}, "portage_risk":float(RIVER.portage_risk)})
	if node.has("toll_dollars"):
		var toll := (0.0 if state.vehicle=="foot" else float(node.toll_dollars)) + float(node.get("toll_per_ox",0)) * int(state.oxen)
		options[0].label = "Pay Barlow toll · $%.2f, then continue" % toll
		if state.vehicle=="foot":options[0].label="Continue on foot · no wagon toll" if toll==0 else "Pay stock toll · $%.2f" % toll
		options[0]["requires"] = {"money":toll}
		options[0]["effects"] = {"money":-toll}
	# A post's store counter opens from the STORE button beside the stop, not from this menu.
	if node.has("advice"):
		options.append({"label":"Read trail notes", "action":"notes"})
	if node.id == "fort_kearny" and int(calendar().month) < 6 and int(calendar().year) == 1848:
		description += "\nYou arrive before June; construction has not yet begun."
	options.append_array(context.activity_choices(self))
	options.append({"label": "Rest here · 1 day, food consumed", "action": "rest"})
	pending = {"id": "stop_" + node.id, "landmark": node.id, "title": node.name, "text": description, "choices": options}

func _choose_landmark(index: int) -> bool:
	refresh_stop_offers()
	var choice: Dictionary = pending.choices[index]
	if choice.action=="leave" and not characters.departure_candidates(self).is_empty():return open_departure_review()
	if choice.action == "trade":
		return open_trade()
	if choice.action == "notes":
		pending.text = route.nodes[state.landmark].text + "\n\n" + choice.get("text",route.nodes[state.landmark].get("advice",""))
		# Word of the party travels with everyone on the road; travelers camped here repeat what has reached them.
		if crime.refuses(self,str(state.landmark)):pending.text+="\n\nTalk around the fires: "+crime.news_text(self,str(state.landmark))
		return true
	if choice.action == "activity":
		context.record.activities.append(choice.activity)
		if context.data.activities[choice.activity].kind=="prepare":context.record.prepared.append(choice.activity)
		_apply(choice.effects,"injuries",choice.get("rest",false))
		journal.append("Day %d · %s" % [state.day,choice.result])
		if state.status=="traveling":
			_update_river_stage()
			pending.text+="\n\n"+choice.result+(" Crossing preparation is complete; water still poses a risk." if context.data.activities[choice.activity].kind=="prepare" else " The team benefits from better grazing.")
		return true
	if choice.action == "rest":
		_tick_day(true)
		_update_river_stage()
		journal.append("Day %d · Rested at %s." % [state.day, route.nodes[state.landmark].name])
		crime.check_pursuit(self)
		return true
	last_crossing = {}
	if choice.action == "cross":
		last_crossing = {"method": choice.method, "place": route.nodes[state.landmark].name, "mishap": false, "lost": false, "stage": state.river_stage}
	_apply(choice.get("effects", {}), "injuries", choice.get("rest", false))
	if state.status == "traveling" and choice.has("portage_risk") and rng.randf() < float(choice.portage_risk):
		var wreck_food: int = state.food
		_apply(RIVER.wreck,"near drowning")
		journal.append("Day %d · The raft breaks up in the Cascades. Lost %d lb food; the party is half drowned." % [state.day,wreck_food-int(state.food)])
	if state.status == "traveling" and choice.has("descent_risk") and rng.randf() < choice.descent_risk:
		var descent_food_before: int = state.food
		var descent_wheels_before: int = state.wheels
		_apply({"food":-20,"wheels":-1,"health":-8},"descent injuries")
		journal.append("Day %d · A wagon slips on Laurel Hill. Lost %d lb food and %d spare wheel(s); the party suffers injuries." % [state.day,descent_food_before-int(state.food),descent_wheels_before-int(state.wheels)])
	# Track accident damage separately from the day's rations and ordinary strain.
	var food_before: int = state.food
	var health_before: int = state.health
	var clothing_before: int = state.clothing
	if state.status == "traveling" and choice.has("risk") and rng.randf() < float(choice.risk)*context.crossing_factor(state.landmark):
		_apply({"food": -30, "health": -15, "clothing": -1}, "crossing injuries")
		last_crossing.mishap = true
	if not last_crossing.is_empty():
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

func crossing_summary(result: Dictionary) -> String:
	var method: String = {"ford": "fording", "float": "floating", "ferry": "ferry", "seized": "working the taken ferry","swim":"swimming with packs","wade":"wading with packs"}.get(result.method,str(result.method))
	var text := "%s · %s. " % [result.place, method]
	if result.mishap:
		text += "Crossing mishap! Cargo washes away. Lost %d lb food and %d clothing set(s); the party suffered injuries. " % [result.food_lost, result.get("clothing_lost", 0)]
	else:
		text += "No cargo lost. "
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
	if not _can_act():
		return false
	if walking_overloaded():return true
	var on_river: bool = state.extended_route and current_edge().get("hazard","") == "river"
	if state.extended_route and not on_river and state.vehicle!="foot" and (state.oxen == 0 or state.ox_health == 0):
		pending = {"id": "no_team", "title": "No team to pull the wagon", "text": "Trade for an ox, rest a worn team, or abandon the wagon through Provisions / Cargo.", "choices": [{"label": "Return to camp", "effects": {}, "result": "The wagon stays in camp."}]}
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
		_tick_day(false, not on_river)
		if state.status != "traveling":
			return true
		if walking_overloaded():return true
		if on_river:distance=maxi(1,roundi((int(RIVER.miles)+rng.randi_range(-2,2))*float(survival.weather.speed)))
		elif state.vehicle=="foot":distance=walking_distance()
		else:distance = maxi(1, roundi(distance * survival.movement_factor(state.oxen, state.ox_health, state.fatigue, 0, state.terrain, int(calendar().month), context.region(self)) * provisions.movement_factor(provisions.cargo(state),int(state.oxen))))
		distance = mini(distance, state.leg_length - state.leg_miles)
		state.leg_miles += distance
		state.miles += distance
		if state.vehicle=="foot" and not wagon_cache.is_empty():wagon_cache.found=false
	else:
		state.miles = mini(DESTINATION, state.miles + distance)
		_tick_day(false)
	journal.append("Day %d · Traveled to mile %d. Food remaining: %d units." % [state.day, state.miles, state.food])
	if state.status == "traveling" and not crime.check_pursuit(self):
		_schedule_event()
	return true

func rest() -> bool:
	if not _can_act():
		return false
	_tick_day(true)
	journal.append("Day %d · Rested in camp. Food remaining: %d units." % [state.day, state.food])
	if state.status == "traveling" and not crime.check_pursuit(self):
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
	if pending.is_empty() or index < 0 or index >= pending.choices.size() or state.status != "traveling":
		return false
	var choice: Dictionary = pending.choices[index]
	if pending.get("recruit_menu",false) or pending.get("dismiss_menu",false):return recruitment.can_choose(self,index)
	if pending.get("crime_menu",false):return crime.can_choose(self,str(choice.get("crime_command","")))
	if pending.get("attack_menu",false):return int(choice.get("attack_target",-1))<0 or (crime.attack_ready(self,int(choice.attack_target)) and (choice.get("unarmed",false) or state.bullets>0))
	if pending.get("remains_menu",false):return Remains.can_choose(self,str(choice.get("remains_command","")),int(choice.get("remains_id",0)),int(choice.get("member",-1)))
	if choice.get("care",0)==12 and not context.local_care(self):return false
	if choice.get("method","")=="ferry" and crime.ferry_refused(self,str(state.landmark)):return false
	if not context.can_trade(choice) or not crime.can_trade(self,choice) or (choice.has("activity") and choice.activity in context.record.activities):return false
	for key in choice.get("requires", {}):
		if state.get(key, 0) < choice.requires[key]:
			return false
	return true

func choose(index: int) -> bool:
	if not can_choose(index):
		return false
	if pending.get("recruit_menu",false) or pending.get("dismiss_menu",false):return recruitment.choose(self,index)
	if pending.get("crime_menu",false):return crime.choose(self,str(pending.choices[index].crime_command))
	if pending.get("attack_menu",false):return crime.choose_attack(self,index)
	if pending.get("remains_menu",false):return Remains.choose(self,index)
	if pending.get("service_menu", false):
		return _choose_service(index)
	if pending.has("landmark"):
		return _choose_landmark(index)
	var choice: Dictionary = pending.choices[index]
	var member_id: int = pending.get("member_id", 0)
	var fight_id: String=pending.id
	var friendly: bool=pending.get("friendly",false)
	var hit:=false
	if friendly:
		journal.append("The riders proved friendly. Any ammunition or time spent was still used.")
	_apply(choice.get("effects", {}), "injuries", choice.get("rest", false))
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

func _can_act() -> bool:
	return pending.is_empty() and state.status == "traveling" and hunt.is_empty()

func _tick_day(resting: bool, team_working: bool = false) -> void:
	var sick_before: bool=characters.has_sick(self)
	state.day += 1
	if state.extended_route:
		var climate: Dictionary=context.region(self).duplicate()
		climate.id=context.region_id(self)
		survival.advance(int(calendar().month), state.terrain, climate)
		state.weather = survival.weather.label
		state.fatigue = clampi(int(state.fatigue) + (2 + int(state.pace) * 2 if team_working else (-14 if resting else -6)), 0, 100)
		if not team_working and current_edge().get("hazard","")!="waterless":
			state.ox_health = mini(100, int(state.ox_health) + (int(seasonal_pressure().rest_ox_recovery) if resting else mini(2,int(seasonal_pressure().rest_ox_recovery))))
		elif state.vehicle!="foot":
			var strain: int=int(context.region(self).strain)+int(seasonal_pressure().working_strain)
			if context.region_id(self) in ["plains","sagebrush"] and int(calendar().month) in [7,8,9]:strain+=1
			strain+=int(survival.weather.get("ox_strain",0))
			if current_edge().get("hazard","")=="waterless":strain+=int(WATERLESS.ox_strain)
			state.ox_health=maxi(0,int(state.ox_health)-strain)
	if state.extended_route:
		var spoiled := provisions.spoil(int(state.day), int(state.food))
		if spoiled > 0:
			state.food -= spoiled
			journal.append("Day %d · Discarded %d ration-lb spoiled meat." % [state.day, spoiled])
			supply_history.append({"day":state.day,"event":"spoilage","changes":{"food":-spoiled}})
		Remains.spoil(self)
	var needed: int = (int(provisions.data.rations_lb[state.rations]) if state.extended_route else RATION_LB[state.rations]) * state.party_size
	# Those chosen to eat human meat are fed from it first; nobody else is ever served it.
	if state.extended_route:needed-=Remains.serve(self)
	var fed: bool = state.food >= needed
	var eaten := mini(int(state.food), needed)
	if state.extended_route:
		# Count vitamin-C produce actually consumed, never merely carried or fresh meat.
		var produce_eaten: float = provisions.remove(eaten)
		party_health.days_without_fresh = 0 if produce_eaten >= state.party_size * float(provisions.data.foraging.vitamin_c_lb_per_person) else party_health.days_without_fresh + 1
	state.food = maxi(0, state.food - needed)
	if not fed:
		_change_health(-maxi(1, ceili(18.0 * (1.0 - float(eaten) / maxi(1, needed)))) if state.extended_route else -18, "lack of food")
	elif resting:
		_change_health(int(survival.data.rest_recovery[state.rations]) if state.extended_route else 7, "ill health")
	else:
		_change_health([ -3, 0, 1 ][state.rations] - [0, 1, 4][state.pace], "exhaustion")
	if not party_health.members.is_empty():
		var storm_damage: int=int(seasonal_pressure().storm_damage) if state.extended_route else 0
		if storm_damage>0:_change_health(-storm_damage,"winter exposure")
		# No water and little grass: animals get no recovery and people go thirsty.
		if state.extended_route and current_edge().get("hazard","")=="waterless":_change_health(-int(WATERLESS.thirst),"thirst")
		var unprotected: int = maxi(0, int(state.party_size) - int(state.clothing))
		if unprotected > 0 and int(survival.weather.exposure) > 0:
			var exposed := 0
			for member in party_health.members:
				if party_health.is_active(member) and exposed < unprotected:
					party_health.affect(member, -int(survival.weather.exposure), state.day, "exposure")
					exposed += 1
		var nutrition: int = state.rations if fed else 0
		var risk_multiplier: float = [2.0, 1.3, 0.7][nutrition] * (0.6 if resting else 1.0) * (1.4 if unprotected and survival.weather.exposure else 1.0) * float(survival.weather.get("illness_risk",1.0))
		party_health.tick(state.day, resting, risk_multiplier, nutrition, int(calendar().year), int(calendar().month) if state.extended_route else 0, context.region_id(self) if state.extended_route else "", party_health.days_without_fresh)
		_collect_health_events()
		state.health = party_health.average_health()
		state.party_size = party_health.living_count()
	_check_health()
	if state.extended_route:social.tick(self,resting,fed)
	characters.daily(self,resting,team_working,sick_before)
	if state.extended_route:crime.check_betrayal(self)
	if state.extended_route:
		journal.append("Day %d · %s. Team condition %s; %s." % [state.day, state.weather, PartyHealth.condition_label(state.ox_health).to_lower(), "working" if team_working else "resting"])

func _check_health() -> void:
	state.health = clampi(state.health, 0, 100)
	if state.health == 0:
		state.status = "lost"
		if state.loss_reason.is_empty():
			state.loss_reason = "No one in the party can continue. Consult the party records for their last days."
		pending = {}
		if party_health.members.any(func(member):return member.get("departed",false)):state.loss_reason="No travelers remain with the wagon. Departures and deaths are recorded separately in View Party."

func _apply(effects: Dictionary, health_cause: String = "injuries", resting: bool = false) -> void:
	var before := state.duplicate(true)
	for key in effects:
		if key == "item":
			if effects[key] not in state.items:
				state.items.append(effects[key])
		elif key == "vehicle":
			state.vehicle = effects[key]
		elif key == "money":
			state.money = maxf(0.0, snappedf(float(state.money) + float(effects[key]), 0.01))
		elif key == "health":
			_change_health(int(effects[key]), health_cause)
		elif key != "days":
			state[key] = maxi(0, int(state[key] + effects[key]))
	if state.extended_route and effects.has("food") and state.food < before.food:
		provisions.remove(int(before.food) - int(state.food))
	if effects.has("wheels") or effects.has("axles") or effects.has("tongues"):
		state.parts = state.wheels + state.axles + state.tongues
	state.ox_health = clampi(int(state.ox_health), 0, 100)
	if state.extended_route:
		var changes: Dictionary = {}
		var lines: Array[String] = []
		for key in ["food", "money", "bullets", "medicine", "clothing", "oxen", "wheels", "axles", "tongues", "salt"]:
			var delta := float(state[key]) - float(before[key])
			if key=="money":delta=roundi(delta*100)/100.0
			if not is_zero_approx(delta):
				changes[key] = delta
				var name: String = {"food": "Food (lb)", "money": "Cash ($)", "medicine": "Care kits"}.get(key, str(key).capitalize())
				lines.append("%s %+.2f" % [name, delta] if key == "money" else "%s %+d" % [name, int(delta)])
		if not changes.is_empty():
			supply_history.append({"day": state.day, "event": pending.get("id", "trail"), "changes": changes})
			journal.append("Day %d · Supplies: %s. Daily rations counted separately." % [state.day, "; ".join(lines)])
	# Delay is ordinary elapsed time: it consumes rations and cannot revive a lost party.
	for day in range(int(effects.get("days", 0))):
		if state.status != "traveling":
			break
		_tick_day(resting)
	_check_health()

func _schedule_event(allow_random: bool = true) -> void:
	if not health_events.is_empty():
		pending = {"id": "party_health", "title": "News from your party", "text": "\n".join(health_events),
			"choices": [{"label": "Acknowledge", "result": "The party takes stock before continuing.", "effects": {}}]}
		health_events.clear()
		return
	if state.extended_route and state.leg_miles >= state.leg_length:
		_arrive_landmark()
		return
	# Deterministic thresholds take priority; unshown due events remain queued by eligibility.
	for event in catalog.events:
		if state.extended_route and event.id == "kansas_river":
			continue # Legacy first-leg fixture only; researched route owns river stops.
		if event.id in seen or event.category != "historical":
			continue
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
		if state.vehicle=="foot" and event.id in ["breakdown","wagon_fire","swamped_load"]:continue
		if state.oxen==0 and event.id=="ox_injury":continue
		if state.oxen<2 and event.id=="stampede":continue
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
		elif content.id=="breakdown" and characters.available(self,"Carpentry") and choice.get("effects",{}).get("days",0)>1:
			var original_days: int=choice.effects.days
			var days: int=maxi(1,int(choice.effects.days)-int(characters.benefits.carpentry_days_saved))
			choice.effects.days=days
			choice.label=choice.label.replace("%d days" % original_days,"%d day(s)" % days)+" · carpenter"
			choice.result="The repair is complete after %d day(s), with a companion's carpentry." % days
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
	return state.extended_route and state.status == "traveling" and hunt.is_empty() and (pending.is_empty() or pending.has("landmark"))

func _service_menu(title: String, text: String, options: Array) -> bool:
	if not can_service():
		return false
	service_return = pending.duplicate(true)
	options.append({"label": "Back to the trail", "effects": {}, "result": ""})
	pending = {"id": "trail_service", "service_menu": true, "title": title, "text": text, "choices": options}
	return true

## Read-only seasonal offer. Empty searches still cost a day; river legs cannot be foraged.
func forage_offer() -> Dictionary:
	var rules: Dictionary = provisions.data.foraging
	var season: float = rules.months[int(calendar().month)-1]
	var factor: float = season * float(rules.regions.get(context.region_id(self),0))
	var workers := 0.0
	for member in party_health.members:
		if party_health.is_active(member) and not member.conditions.any(func(c): return c.id == "broken_leg"):
			workers += member.health / 100.0
	var blocked: bool = current_edge().get("hazard", "") in ["river", "waterless"] or survival.weather.id in ["blizzard", "snow"]
	return {"available": factor > 0 and workers > 0 and not blocked, "factor": factor, "workers": workers}

func open_forage() -> bool:
	var offer := forage_offer()
	var options: Array = []
	if offer.available:
		options.append({"label":"Search for greens and berries · 1 day and meals", "foraging":true, "effects":{"days":1}, "result":""})
	return _service_menu("Foraging", "Gather seasonal greens and berries nearby. Yield depends on the season, region and healthy walkers; a search may find little. This supplements meals rather than replacing staple provisions. Produce spoils in three days and provides vitamin C only when eaten. No gathering on waterless or rafting legs, in snow, or outside the growing season." + (" Nothing suitable is available here now." if not offer.available else ""), options)

func _gather_forage(offer: Dictionary) -> void:
	if state.status != "traveling": return
	var rules: Dictionary = provisions.data.foraging
	var pounds := mini(int(rules.maximum_lb), floori(rng.randi_range(int(rules.lb_per_worker[0]),int(rules.lb_per_worker[1])) * float(offer.workers) * float(offer.factor)))
	var room := maxf(0, provisions.storage_capacity(state) - provisions.cargo(state))
	pounds = mini(pounds, floori(room))
	var units: int = provisions.add_produce(pounds,int(state.day))
	state.food += units
	var report := "Foraged %d lb of greens and berries (%d food units)." % [units * int(rules.mass_ratio),units] if units > 0 else "The search yielded no usable food within your carrying room."
	journal.append("Day %d · %s" % [state.day,report])
	health_events.append(report)

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
	var rumor: String=crime.news_text(self,str(state.landmark)) if at_post else ""
	var terms: String=("The first trade costs a day and meals; further trades at this stop take no extra time." if days>0 else "You have spent the day here already; further trades take no extra time.")
	if not at_post:
		var markup: int=roundi((float(context.data.passing_price_markup)-1.0)*100.0)
		terms=("Their camp is off the road: the first trade costs a day and meals, and further trades while they are nearby take no extra time." if days>0 else "You are camped with them already; further trades take no extra time.")+" Their prices run %d%% above the posts." % markup
	return _service_menu("Trading post" if at_post else "Passing traders", "Stock and buying demand are limited. Regional prices apply. "+terms+(" Your trading companion negotiated 5% off cash purchases." if characters.available(self,"Trading") else "")+(" "+rumor if not rumor.is_empty() else ""), options)

func _at_post() -> bool:
	return not pending.is_empty() and pending.has("landmark") and route.nodes[state.landmark].get("trade_bulk",false)

## Every trade on offer here: a buy and a sell choice per lot (plus barter with passing traders), priced and stock-limited.
## A post sells staple food by the 200 lb barrel-and-sack lot. The first transaction of a visit carries its day.
func _trade_options(offer: Dictionary,at_post: bool) -> Array:
	var options: Array = []
	var lots: Array = survival.data.trade_lots.duplicate(true)
	for lot in lots:
		lot.buy_cents=roundi(float(lot.buy_cents)*float(offer.price))
	if at_post:
		lots[0].amount = 200
		lots[0].label = "200 lb staple food"
		lots[0].buy_cents = route.nodes[state.landmark].get("bulk_food_cents",6000)
		lots[0].sell_cents = 2000
	if characters.available(self,"Trading"):
		for lot in lots:lot.buy_cents=maxi(1,roundi(lot.buy_cents*characters.benefits.trade_buy_factor))
	var days: int=context.trade_days(offer)
	var when: String=", 1 day" if days>0 else ""
	for lot in lots:
		if lot.item == "salt":continue # Preserve the existing barter offer order.
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
	return {"name":name,"kind":"post","key":str(offer.key),"rows":rows,"days":context.trade_days(offer),"money_cents":roundi(float(state.money)*100.0),"purse_cents":-1,"rumor":crime.news_text(self,str(state.landmark)),"discount":characters.available(self,"Trading")}

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
	return {"name":"Passing traders","kind":"traders","key":str(offer.key),"mood":goods.mood,"late_food":late,"rows":rows,"days":context.trade_days(offer),"money_cents":roundi(float(state.money)*100.0),"purse_cents":_purse_left(str(offer.key),int(goods.purse_cents)),"rumor":"","discount":characters.available(self,"Trading")}

## ASK FOR NEWS at an open counter: what the post, the traders or the family have heard. Takes no time.
func ask_news(venue: String="") -> Dictionary:
	var counter: Dictionary=trade_counter(venue)
	if counter.is_empty():return {}
	return news.report(self,str(counter.kind),str(state.landmark) if counter.kind=="post" else str(counter.key))

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
		var sell_cents: int=roundi(float(lot.sell_cents)*float(goods.need.get(item,1.0)))
		rows.append(_counter_row(lot,maxi(1,buy_cents),sell_cents,can_buy,can_sell,buy_key,sell_key,goods.stock.has(item),goods.wants.has(item)))
		rows[-1]["premium"]=float(goods.need.get(item,1.0))
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
	var after: Dictionary=state.duplicate()
	for item in effects:after[item]=int(after.get(item,0))+int(effects[item])
	result.cargo_lb=provisions.cargo(state)
	result.capacity_lb=provisions.capacity(state)
	result.cargo_after_lb=provisions.cargo(after)
	result.capacity_after_lb=provisions.capacity(after)
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
		context.record.spent[key]=ceili(float(used)/int(row.amount))
		crime.consume_trade({"market_key":key,"effects":{row.item:n}})
		lines.append(("bought %d %s" if n>0 else "sold %d %s") % [absi(n),_unit_name(row.item,absi(n))])
	if quote.net_cents>0 and store.purse_cents>=0:
		var purse_key: String=str(store.key)+"|purse|units"
		context.record.spent[purse_key]=int(context.record.spent.get(purse_key,0))+int(quote.net_cents)
	if store.days>0:context.record.spent[str(store.key)+"|visit"]=1
	var effects: Dictionary=quote.effects.duplicate()
	effects["money"]=quote.net_cents/100.0
	effects["days"]=quote.days
	journal.append("Day %d · %s: %s." % [state.day,{"post":"At "+str(store.name),"traders":"Traded with passing traders","camp":"Traded with an emigrant family"}[store.kind],", ".join(lines)])
	_apply(effects)
	refresh_stop_offers()
	if quote.days>0:_update_river_stage()
	return true

## How a counter quantity reads in the journal and on the store screen.
static func _unit_name(item: String,n: int) -> String:
	var names: Dictionary={"food":["lb of food","lb of food"],"salt":["lb of salt","lb of salt"],"bullets":["bullet","bullets"],"medicine":["care kit","care kits"],"clothing":["clothing set","clothing sets"],"oxen":["ox","oxen"],"wheels":["wheel","wheels"],"axles":["axle","axles"],"tongues":["tongue","tongues"]}
	return names.get(item,[item,item])[0 if n==1 else 1]

func open_crime() -> bool:
	if pending.get("crime_menu",false):return true
	if not crime.eligible(self):return false
	service_return=pending.duplicate(true)
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
	options.append({"label":"Share news of the road · once per camp","market_key":place+"|news","stock_limit":1,"effects":{},"result":camp_news()})
	if not _service_menu("An emigrant camp","An emigrant family is camped near the road and is glad of company. Their food in the wagon: %d lb. Trading and news cost no time; nursing takes a day." % crime.food_left(self,place),options):return false
	pending["camp"]=place
	return true

## What a family met on the road heard at the posts behind it: which posts ahead already know of the party.
func camp_news() -> String:
	var warned: Array=crime.venues().filter(func(place):return crime.mile(self,place)>int(state.miles) and crime.refuses(self,place)).map(func(place):return route.nodes[place].name)
	if warned.is_empty():return "Swapped news with an emigrant family. They heard no talk of your party at the posts they passed."
	return "Swapped news with an emigrant family. Word of your party has already reached %s." % ", ".join(warned)

func open_care() -> bool:
	var options: Array = []
	for member in party_health.members:
		if not party_health.is_active(member) or (member.conditions.is_empty() and member.health >= 100):
			continue
		options.append({"label": "Care for %s · 1 kit, 1 day" % member.name, "member_id": member.id, "care": 6, "requires": {"medicine": 1}, "effects": {"medicine": -1, "days": 1}, "result": "Used care supplies for " + member.name + "."})
		if context.local_care(self) and not crime.refuses(self,str(state.landmark)) and not crime.closed(str(state.landmark)):options.append({"label": "Seek local care for %s · $20, 1 day" % member.name, "member_id": member.id, "care": 12, "requires": {"money": 20}, "effects": {"money": -20, "days": 1}, "result": "Paid $20 for medical attention for " + member.name + "."})
	if characters.available(self,"Caregiving"):
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
	if choice.get("departure_review",false):
		pending=service_return.duplicate(true)
		service_return={}
		_depart(departure_plan(),"")
		return true
	var forage: Dictionary = forage_offer() if choice.get("foraging",false) else {}
	if choice.get("foraging",false) and not forage.available: return false
	crime.consume_trade(choice)
	context.consume(choice)
	if choice.has("care"):
		var member: Dictionary = party_health.members[int(choice.member_id)]
		party_health.affect(member, int(choice.care)+int(choice.get("care_bonus",0)), state.day, "care")
		for active in member.conditions:
			active.elapsed += 2+int(choice.get("recovery_bonus",0))
			active.severity = maxi(1, int(active.get("severity", 1)) - 1)
		member.history.append("Day %d · Received care." % state.day)
		characters.care(self,int(choice.member_id))
		state.health = party_health.average_health()
	_apply(choice.effects, "injuries", choice.has("care"))
	if choice.get("foraging",false): _gather_forage(forage)
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
func _depart(plan: Array,fled_reason: String) -> void:
	for transfer in plan:
		var member: Dictionary=party_health.members[transfer.id]
		provisions.remove(transfer.food)
		state.food-=transfer.food
		state.clothing-=transfer.clothing
		state["departed_gear_lb"]=int(state.get("departed_gear_lb",0))+transfer.gear_lb
		member["departed"]=true
		member["departure_day"]=int(state.day)
		member["departure_place"]=state.landmark
		member["departure_supplies"]={"food":transfer.food,"clothing":transfer.clothing,"gear_lb":transfer.gear_lb}
		if not fled_reason.is_empty():member["fled"]=true
		var text: String="%s %s %s with %d ration-lb food, %d clothing set(s), and %d lb personal gear." % [member.name,"fled "+fled_reason+", near" if not fled_reason.is_empty() else "left at",route.nodes[state.landmark].name,transfer.food,transfer.clothing,transfer.gear_lb]
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
		elif option.get("method", "") == "float":
			option.risk = 0.35 if state.river_stage == "high" else 0.2
		elif option.get("method", "") == "seized":
			option.risk = crime.seized_risk(self,str(state.landmark))

func start_hunt() -> bool:
	if not _can_act() or not state.extended_route or state.bullets < 1:
		return false
	_tick_day(false)
	if state.status != "traveling":
		return false
	hunting_outings += 1
	hunt = hunting.begin(int(state.seed), hunting_outings, int(state.miles), route.nodes[state.landmark].get("hunting_region","plains"))
	hunt.day = state.day
	journal.append("Day %d · Stopped to hunt. One day passes; rations consumed." % state.day)
	return true

func hunt_shot(target: int) -> bool:
	if hunt.is_empty() or hunt.ended or hunt.reload > 0 or state.bullets < 1 or hunt.shots >= hunting.data.shot_limit or target < -1 or target >= hunt.animals.size():
		return false
	if target in hunt.targets or (target >= 0 and hunt.animals[target].escaped):
		return false
	state.bullets -= 1
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
	if hunt.shots >= hunting.data.shot_limit or state.bullets == 0:
		hunt.ended = true
		hunt.message += " Return to camp."
	return true

func advance_hunt(delta: float) -> void:
	if not hunt.is_empty() and is_finite(delta) and delta > 0:
		hunting.tick(hunt, delta)

func hunt_fire_at(point: Vector2) -> bool:
	if hunt.is_empty() or not point.is_finite():
		return false
	var accepted := hunt_shot(hunting.target_at(hunt, point))
	if accepted:
		hunt.aim = point
	return accepted

func move_hunter(point: Vector2) -> void:
	if not hunt.is_empty() and not hunt.ended and point.is_finite():
		hunt.destination = point.clamp(Vector2(8, 65), Vector2(424, 143))

func hauling_capacity(action: String="hunt") -> int:
	var pounds:=0.0
	for member in party_health.members:
		if characters.willing(int(member.id),action):
			pounds+=float(hunting.data.carry_per_person_lb)*provisions.Carrying.factor(member)
	return mini(int(hunting.data.carry_limit),floori(pounds))
func hunting_capacity() -> int:
	return hauling_capacity("hunt")
func hunt_recovery() -> Dictionary:
	if hunt.is_empty():return {}
	var carried:=mini(mini(hunting_capacity(),int(hunt.meat)),maxi(0,floori(provisions.storage_capacity(state)-provisions.cargo(state))))
	return {"mass":carried,"food":provisions.meat_units(carried),"left":int(hunt.meat)-carried}
func finish_hunt() -> bool:
	if hunt.is_empty():return false
	var recovered:=hunt_recovery()
	state.food+=provisions.add_meat(int(recovered.mass),int(state.day))
	journal.append("Day %d · Hunting: %d shots, %d lb meat obtained, %d lb carried, %d food units (hauling limit %d lb)." % [state.day,hunt.shots,hunt.meat,recovered.mass,recovered.food,hunting_capacity()])
	journal.append("%s · %d lb left behind. %s" % [hunt.region_label,recovered.left,hunt.message])
	hunt={}
	_schedule_event(false)
	return true

func walking_distance() -> int:
	var load:=provisions.cargo(state)/maxf(1,provisions.capacity(state))
	var burden:=clampf(1.0-maxf(0,load-0.5)*0.5,0.25,1.0)
	var terrain:=0.8 if state.terrain=="mountains" else (0.9 if state.terrain=="forest" else 1.0)
	return maxi(1,roundi(float(provisions.data.walking.miles_per_day)*[1.0,1.15,1.3][state.pace]*float(seasonal_pressure().travel)*float(survival.weather.speed)*terrain*burden*(1.0-float(state.fatigue)/300.0)))
func walking_overloaded() -> bool:
	if state.vehicle!="foot" or provisions.cargo(state)<=provisions.capacity(state):return false
	pending={"id":"packs_too_heavy","title":"Too much to carry","text":"Your packs exceed the surviving party's carry limit. Return to camp to drop supplies, or preserve fresh meat through Camp > Preserve meat before walking on.","choices":[{"label":"Return to camp","effects":{},"result":"The party reorganizes its packs."}]}
	return true
func pack_quote(cart: Dictionary,from_cache: bool=false) -> Dictionary:return CacheSupport.quote(self,cart,from_cache)
func abandon_wagon(cart: Dictionary) -> bool:return CacheSupport.pack(self,cart,false)
func repack_wagon_cache(cart: Dictionary) -> bool:return CacheSupport.pack(self,cart,true)
func recover_wagon() -> bool:return CacheSupport.recover(self)

func ox_slaughter_offer(by_hand: bool = false) -> Dictionary:
	var rules: Dictionary = provisions.data.ox_slaughter
	if not can_service() or state.oxen <= rules.minimum_team or (not by_hand and state.bullets < rules.bullets):return {}
	# Team condition is a coarse proxy for the selected animal, not its live weight.
	var factor := float(rules.minimum_yield_factor)+(1.0-float(rules.minimum_yield_factor))*float(state.ox_health)/100.0
	return {"meat":floori(float(rules.usable_meat_lb)*factor),"remaining":int(state.oxen)-1,"bullets":0 if by_hand else int(rules.bullets),"by_hand":by_hand,"injury_chance":float(rules.hand_injury_chance) if by_hand else 0.0}

func slaughter_ox(by_hand: bool = false) -> bool:
	var offer := ox_slaughter_offer(by_hand)
	if offer.is_empty():return false
	state.oxen-=1
	state.bullets-=int(offer.bullets)
	state.food+=provisions.add_meat(int(offer.meat),int(state.day)+1)
	# At-camp meat is available for today's meals. All usable meat is recovered,
	# even if it overloads the wagon; the hunting retrieval cap does not apply.

	supply_history.append({"day":int(state.day)+1,"event":"slaughter_ox","changes":{"oxen":-1,"bullets":-int(offer.bullets),"food":provisions.meat_units(int(offer.meat))}})
	journal.append("Day %d · Slaughtered one ox at camp: %d lb usable fresh meat, %d bullet(s), %d oxen remain. All meat recovered; meals and spoilage still apply." % [int(state.day)+1,offer.meat,offer.bullets,offer.remaining])
	if by_hand:
		journal.append("Used the household hand tools instead of ammunition.")
		if rng.randf() < offer.injury_chance:
			var living: Array = party_health.members.filter(func(member):return party_health.is_active(member))
			var worker: Dictionary = living[rng.randi_range(0,living.size()-1)]
			if not party_health.begin_condition(int(worker.id),"wound",int(state.day)+1):
				for condition in worker.conditions:
					if condition.id == "wound":condition.severity=mini(3,int(condition.severity)+1)
				worker.history.append("Day %d · Butchering aggravated an existing wound." % (int(state.day)+1))
			_collect_health_events()
			journal.append("%s was injured while butchering the ox by hand." % worker.name)
	_tick_day(false)
	_update_river_stage()
	if state.status == "traveling" and pending.is_empty():_schedule_event(false)
	return true

func preservation_offer(salted: bool = false) -> Dictionary:
	if not can_service():return {}
	var plan: Dictionary=provisions.preservation_plan(int(state.day),int(state.food),int(provisions.data.rations_lb[state.rations])*int(state.party_size))
	var input: int=plan.input
	if input < 1:return {}
	var salt := ceili(float(plan.mass)*float(provisions.data.preservation.salt_per_food_lb)) if salted else 0
	if state.salt < salt:return {}
	return {"input":input,"mass":plan.mass,"salt":salt,"kept":floori(input*float(provisions.data.preservation.salted_retained_food if salted else provisions.data.preservation.retained_food)),"days":int(provisions.data.preservation.salted_days if salted else provisions.data.preservation.days)}

func preserve_meat(salted: bool = false) -> bool:
	var offer := preservation_offer(salted)
	if offer.is_empty():return false
	_tick_day(false) # Meals and spoilage happen before processing; never rescue spoiled meat.
	if state.status != "traveling":return true
	var input: int=mini(int(offer.input),provisions.processable())
	while salted and input>0 and ceili(provisions.fresh_mass(input)*float(provisions.data.preservation.salt_per_food_lb))>int(state.salt):input-=1
	var result := provisions.preserve(input,int(state.day),salted)
	state.food-=int(result.lost)
	state.salt-=int(result.salt)
	supply_history.append({"day":state.day,"event":"preservation","changes":{"food":-int(result.lost),"salt":-int(result.salt)},"processed":result.input,"processed_mass_lb":result.mass,"retained":result.kept,"dried_weight_lb":result.weight,"expires":result.expires})
	journal.append("Day %d · %s: %.1f lb fresh meat became %d food units dried food (%.1f lb cargo); %d lb salt used. Processing lost %d ration-lb. Keeps up to %d days after today." % [state.day,"Salt-assisted drying" if salted else "Drying meat",result.mass,result.kept,result.weight,result.salt,result.lost,offer.days])
	_update_river_stage()
	if pending.is_empty():_schedule_event(false)
	return true

func discard_supply(item: String, amount: int) -> bool:
	if not can_service() or item not in provisions.data.weights_lb or amount <= 0 or amount > int(state.get(item, 0)):
		return false
	_apply({item: -amount})
	journal.append("Day %d · Left %d %s behind to lighten the wagon." % [state.day, amount, item])
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
	if not pending.has("landmark") or pending.landmark!=state.landmark or not crime.scenes.has(state.landmark):
		return
	for choice in pending.choices:
		if choice.get("method","")=="ferry" and crime.ferry_refused(self,str(state.landmark)):
			choice.label="The ferry crew will not carry your party"
	if crime.passage(str(state.landmark)) and crime.scenes[state.landmark].kind=="ferry" and not pending.choices.any(func(choice):return choice.get("method","")=="seized"):
		# Appended so the stop's existing choice indices never shift.
		pending.choices.append({"label":"Cross on the taken ferry, without its crew · 1 day, risk to supplies","action":"cross","method":"seized","effects":{"days":1},"risk":crime.seized_risk(self,str(state.landmark))})

func _refresh_toll_offer() -> void:
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
	var toll := snappedf((0.0 if state.vehicle=="foot" else float(node.toll_dollars)) + float(node.get("toll_per_ox",0)) * int(state.oxen),0.01)
	for choice in pending.choices:
		if choice.get("action","") == "leave":
			choice.label = "Pay Barlow toll · $%.2f, then continue" % toll
			if state.vehicle=="foot":choice.label="Continue on foot · no wagon toll" if toll==0 else "Pay stock toll · $%.2f" % toll
			choice["requires"] = {"money":toll}
			choice["effects"] = {"money":-toll}


func seasonal_pressure() -> Dictionary:
	return survival.seasonal(int(calendar().month),str(state.terrain),context.region(self))

func season_notice(days_ahead: int=0) -> String:
	if not state.extended_route:return ""
	var date: Dictionary=Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_dict(calendar()))+maxi(0,days_ahead)*86400)
	var month: int=int(date.month)
	if month in survival.data.seasonal.winter_months:return "Winter: slow roads and poor grazing. Clothes reduce, but do not erase, blizzard exposure."
	if month in [9,10]:return "Autumn: mountain snow is approaching. Longer stops risk worse roads and grazing."
	if month in [3,4] and seasonal_pressure().upland:return "Spring: snow can still slow upland travel."
	return ""


func current_party_slots() -> Array:
	return recruitment.slots(self)

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
	if state.vehicle!="foot" or content.get("choices",[]).size()<2:return
	if content.get("id","")=="ox_injury":
		content.text="An ox travelling with your party injures its leg. You are on foot; there is no wagon to pull. The animal's condition will matter if you hitch the wagon again."
		content.choices[0].label="Rest the herd · 1 day"
		content.choices[0].result="You stop walking and give the oxen time to recover."
		content.choices[1].label="Keep walking with the oxen"
		content.choices[1].result="You continue on foot with the injured ox."
	elif content.get("id","")=="wandering_ox":
		content.text="One animal is missing when you count the oxen travelling alongside your party."
		content.choices[1].result="You keep walking with fewer oxen."


func discard_supplies(cart: Dictionary) -> bool:
	var plan: Dictionary=preload("res://simulation/discard_plan.gd").quote(self,cart)
	if not plan.valid:return false
	for item in cart:
		if int(cart[item])>0:discard_supply(item,int(cart[item]))
	return true
