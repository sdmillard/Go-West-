extends RefCounted
## Versioned plain JSON; never instantiates serialized objects or executes save content.
const Simulation = preload("res://simulation/trail_engine.gd")
const FORMAT := "westward-probably"
const VERSION := 1
const DEFAULT_PATH := "user://journey.json"
const MAX_BYTES := 2097152
const RULE_FILES = ["outfitting", "route", "health_conditions", "survival_rules", "hunting", "provisions", "trail_events", "trail_context", "combat_rules", "party_benefits", "character_catalog", "crime_scenes", "social_rules", "appearance", "recruitment", "robbery_demands", "camp_tasks", "field_outings", "fishing"]
var error := ""
var rules_signature := ""
var load_note := ""

func fingerprint() -> String:
	if not rules_signature.is_empty():
		return rules_signature
	var text := FileAccess.get_file_as_string("res://data/events.json")
	for file in RULE_FILES:
		text += FileAccess.get_file_as_string("res://data/%s.json" % file)
	# Line endings depend on the checkout (Windows Git converts to CRLF); the rules do not.
	rules_signature = text.replace("\r", "").sha256_text()
	return rules_signature

func capture(game) -> Dictionary:
	if not game.state.extended_route or not game.hunt.is_empty() or game.state.status not in ["traveling", "arrived", "lost", "returned_east"]:
		return {}
	return normalize({"format": FORMAT, "version": VERSION, "rules": fingerprint(),
		"recruitment":game.recruitment.snapshot(),"social":game.social.snapshot(),"crime":game.crime.snapshot(),
		"camp_repair":game.camp_repair.work.duplicate(true),"field_outings":game.field_outings.snapshot(),"characters_version":5,"camp_tasks":game.camp_tasks.snapshot(),"characters":game.characters.profiles.duplicate(true),
		"combat_history":game.combat.history.duplicate(true),"context":game.context.record.duplicate(true),"route_end":game.route.end_id,"wagon_cache":game.wagon_cache.duplicate(true), "state":game.state.duplicate(true), "pending":game.pending.duplicate(true),
		"seen":game.seen.duplicate(), "journal":Array(game.journal),
		"last_crossing":game.last_crossing.duplicate(true), "crossing_history":game.crossing_history.duplicate(true),
		"supply_history":game.supply_history.duplicate(true), "service_return":game.service_return.duplicate(true),
		"party":game.party_health.members.duplicate(true), "health_events":Array(game.health_events),
		"fresh":game.provisions.fresh.duplicate(true), "outings":game.hunting_outings, "days_without_fresh":game.party_health.days_without_fresh, "route_path":game.travelled_path().duplicate(),
		"random":str(game.rng.state), "health_random":str(game.party_health.rng.state),
		"survival_random":str(game.survival.rng.state),
		"weather":game.survival.weather.duplicate(true), "wet_ground":game.survival.wet_ground,
		"last_events":game.survival.last_events.duplicate(true)})

func save_game(game, path: String = DEFAULT_PATH) -> bool:
	error = ""
	var snapshot := capture(game)
	if snapshot.is_empty():
		error = "Return from the outing or depart before saving."
		return false
	return write_document(snapshot, path)

func write_document(snapshot: Dictionary, path: String) -> bool:
	var text := JSON.stringify(snapshot)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		error = "The record is too large to save."
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		error = "Could not write the trail record."
		return false
	file.store_string(text)
	file.flush()
	var code := file.get_error()
	file.close()
	if code != OK:
		error = "Could not finish writing the trail record."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var backup := absolute + ".bak"
	var existed := FileAccess.file_exists(path)
	if existed:
		if FileAccess.file_exists(backup):
			if DirAccess.remove_absolute(backup) != OK:
				error = "Could not update the backup trail record."
				return false
		if DirAccess.rename_absolute(absolute, backup) != OK:
			error = "Could not preserve the previous trail record."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute) != OK:
		if existed:
			DirAccess.rename_absolute(backup, absolute)
		error = "Could not replace the trail record."
		return false
	return true

func load_game(path: String = DEFAULT_PATH) -> Dictionary:
	error = ""
	var result = read_game(path)
	if result != null:
		return {"game":result,"message":"Journey restored. Travel is paused." + (" " + load_note if not load_note.is_empty() else "")}
	var primary_error := error
	result = read_game(path + ".bak")
	if result != null:
		return {"game":result,"message":"The main record could not be read; restored its previous backup. Travel is paused."}
	error = primary_error
	return {}

func read_game(path: String):
	if not FileAccess.file_exists(path):
		error = "No saved journey was found."
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		error = "The trail record is unreadable or too large."
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		error = "The trail record is damaged (invalid JSON)."
		return null
	return restore(parser.data)

func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(value) and value >= low and value <= high
func strings(value: Variant, limit: int = 10000) -> bool:
	if not value is Array or value.size() > limit:
		return false
	for item in value:
		if not item is String or item.length() > 20000:
			return false
	return true

func valid_menu(menu: Dictionary, game, count: int=5) -> bool:
	if menu.get("outing_warning",false):
		if menu.get("id")!="outing_departure" or not menu.get("flight") is bool or not menu.get("resume") is Dictionary or menu.resume.has("outing_warning") or not menu.get("choices") is Array:return false
		var expected: Array=["leave","back"] if menu.flight else ["wait","leave","back"]
		if menu.choices.size()!=expected.size():return false
		for i in range(expected.size()):
			var choice: Variant=menu.choices[i]
			if not choice is Dictionary or choice.get("outing_choice")!=expected[i] or not choice.get("label") is String or not choice.get("effects") is Dictionary or not choice.effects.is_empty():return false
		return valid_menu(menu.resume,game,count)
	if menu.has("approach_direction") and (menu.approach_direction not in ["west","east"] or not menu.has("landmark")):return false
	if menu.has("retreat_without_crossing") and (menu.retreat_without_crossing!=true or not menu.has("landmark")):return false
	if menu.is_empty():
		return true
	if not menu.get("id") is String or not menu.get("title") is String or not menu.get("text") is String or not menu.get("choices") is Array or menu.choices.is_empty() or menu.choices.size() > 40:
		return false
	if menu.has("landmark") and not game.route.nodes.has(menu.landmark):
		return false
	for choice in menu.choices:
		if not choice is Dictionary or not choice.get("label") is String:
			return false
		if menu.get("recruit_menu",false) or menu.get("dismiss_menu",false):
			if not menu.get("service_menu",false) or choice.get("recruit_command","") not in ["search","accept","decline","dismiss","back"] or not choice.get("effects",{}) is Dictionary or not choice.get("effects",{}).is_empty():return false
		elif choice.has("recruit_command"):return false
		if choice.has("portage_risk") and (choice.get("action","")!="leave" or not (choice.portage_risk is int or choice.portage_risk is float) or not is_finite(float(choice.portage_risk)) or choice.portage_risk<0 or choice.portage_risk>1):return false
		if choice.has("edge") and (choice.get("action","")!="leave" or not menu.has("landmark") or not integer(choice.edge,1,game.route.nodes[menu.landmark].next.size()-1)):return false
		if menu.has("crime_menu") and (menu.crime_menu!=true or menu.id!="crime" or not menu.get("service_menu",false) or choice.get("crime_command","") not in game.crime.COMMANDS):return false
		if choice.has("camp_repair_part") and (menu.id!="breakdown" or choice.camp_repair_part not in ["wheels","axles","tongues"] or not choice.get("effects",{}) is Dictionary or not choice.get("effects",{}).is_empty()):return false
		if choice.has("crime_command") and not menu.get("crime_menu",false):return false
		if menu.has("attack_menu") and (menu.attack_menu!=true or menu.id!="attack" or not menu.get("service_menu",false) or not integer(choice.get("attack_target"),-1,count-1)):return false
		if choice.has("attack_target") and not menu.get("attack_menu",false):return false
		if menu.has("riders_menu") and (menu.riders_menu!=true or menu.id!="riders" or not menu.get("service_menu",false) or not integer(choice.get("rider_member"),-2,count-1)):return false
		if choice.has("rider_member") and not menu.get("riders_menu",false):return false
		if choice.has("unarmed") and (choice.unarmed != true or not menu.get("attack_menu",false) or int(choice.get("attack_target",-1)) < 0):return false
		if menu.has("remains_menu") and (menu.remains_menu!=true or menu.id!="remains" or not menu.get("service_menu",false) or choice.get("remains_command","") not in game.Remains.COMMANDS or not integer(choice.get("remains_id"),0,200) or not integer(choice.get("member",-1),-1,count-1)):return false
		if choice.has("remains_command") and not menu.get("remains_menu",false):return false
		if choice.has("action") and choice.action not in ["cross", "rest", "leave", "trade", "notes", "activity"]:
			return false
		if choice.has("activity") and (not choice.activity is String or not game.context.data.activities.has(choice.activity)):return false
		if choice.get("action","")=="activity" and (choice.get("activity","")!=menu.get("landmark","") or not game.context.data.activities.get(choice.get("activity",""),{}).has("kind") or not choice.get("result") is String):return false
		if choice.has("market_key")!=choice.has("stock_limit"):return false
		if choice.has("market_key") and (not choice.market_key is String or choice.market_key.length()>128 or not integer(choice.get("stock_limit"),1,8)):return false
		if choice.has("visit_key") and (not choice.visit_key is String or choice.visit_key.length()>128 or not choice.visit_key.ends_with("|visit") or not choice.has("effects") or int(choice.effects.get("days",0))!=1):return false
		if choice.has("text") and not choice.text is String:return false
		if choice.has("method") and choice.method not in ["ford", "float", "ferry", "seized", "swim", "wade", "horses"]:
			return false
		if not menu.has("landmark") and not choice.get("result") is String:
			return false
		if not valid_effects(choice.get("effects", {})) or not valid_effects(choice.get("requires", {})):
			return false
		for flag in ["complete", "rest"]:
			if choice.has(flag) and not choice[flag] is bool:
				return false
		if choice.has("bandit_payment") and (menu.id!="bandits" or choice!=menu.choices[0] or not game.combat.BanditDemand.valid_choice(choice)):return false
		if choice.has("bandit_wagon") and not choice.has("bandit_payment"):return false
		if choice.has("departure_review") and (not choice.departure_review is bool or not menu.get("service_menu",false)):return false
		if choice.get("combat","") not in ["","defend","circle"]:return false
		if choice.has("combat") and not choice.get("risk") is Dictionary:return false
		if choice.has("quoted_risk") and (not (choice.quoted_risk is int or choice.quoted_risk is float) or not is_finite(float(choice.quoted_risk)) or choice.quoted_risk<0 or choice.quoted_risk>1):return false
		if choice.has("foraging") and (choice.foraging != true or menu.get("title","") != "Foraging" or choice.get("effects",{}).size()!=1 or not integer(choice.get("effects",{}).get("days"),1,1)):return false
		if choice.has("care") and (not integer(choice.care,0,100) or not integer(choice.get("member_id"),0,count-1)):
			return false
		for bonus in ["care_bonus","recovery_bonus"]:
			if choice.has(bonus) and (not choice.has("care") or not integer(choice[bonus],0,40)):return false
		if choice.has("risk"):
			var risk = choice.risk
			if risk is Dictionary:
				if not valid_effects(risk.get("effects",{})) or not risk.get("text") is String:
					return false
				for field in ["victim_damage","severity"]:
					if risk.has(field) and not integer(risk[field],1 if field=="severity" else 0,3 if field=="severity" else 100):return false
				if risk.has("condition") and not game.party_health.conditions.has(risk.condition):
					return false
				risk = risk.get("probability")
			if not (risk is float or risk is int) or not is_finite(float(risk)) or risk < 0 or risk > 1:
				return false
	return true

func valid_effects(effects: Variant) -> bool:
	if not effects is Dictionary:
		return false
	for key in effects:
		if key not in ["food","health","money","fuel","wheels","axles","tongues","medicine","clothing","bullets","oxen","ox_health","horse_health","days","item","vehicle","salt","horses","mules","saddles","pack_saddles","saddlebags"]:
			return false
		var value = effects[key]
		if key in ["item","vehicle"]:
			if not value is String or value.length() > 100:
				return false
		elif not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 1000000:
			return false
		elif key == "days" and not integer(value,0,30):
			return false
	return true

func restore(value: Variant):
	load_note = ""
	error = "The trail record has invalid or incompatible data."
	if not value is Dictionary or value.get("format") != FORMAT or value.get("version") != VERSION:
		return null
	var migrated := false
	var economy_migrated := false
	if value.get("rules") != fingerprint():
		var migrations: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/save_migrations.json"))
		migrated = migrations is Dictionary and value.get("rules") in migrations.get("opening_route_v1",[])
		economy_migrated = migrations is Dictionary and value.get("rules") in migrations.get("economy_v1",[])
	if value.get("rules") != fingerprint() and not migrated and not economy_migrated:
		error = "This record uses different game rules. Keep it for the matching game version."
		return null
	if not migrated and not economy_migrated and (not value.has("context") or not value.has("combat_history")):return null
	if not value.get("state") is Dictionary:
		return null
	var s: Dictionary = value.state.duplicate(true)
	if (migrated or economy_migrated) and not s.has("salt"):s["salt"]=0
	# Saddle and pack animal keys are optional; records from before horses carry none.
	if not Simulation.Mounts.valid_state(s):return null
	if not integer(s.get("seed"), -2147483648, 2147483647) or s.get("extended_route") != true or s.get("status") not in ["traveling", "arrived", "lost", "returned_east"]:
		return null
	var game = Simulation.new(int(s.seed), str(s.get("mode", "classic")), s.extended_route, str(value.get("route_end","")))
	if not game.error.is_empty():
		return null
	for key in game.state:
		if not s.has(key):
			return null
		var expected = game.state[key]
		if expected is int and key != "money":
			if not integer(s[key], -2147483648 if key == "seed" else 0, 2147483647):
				return null
		elif expected is float or key == "money":
			if not (s[key] is int or s[key] is float) or not is_finite(float(s[key])) or s[key] < 0:
				return null
		elif expected is String and not s[key] is String:
			return null
	if s.mode not in ["classic", "unhinged"] or not integer(s.pace,0,2) or not integer(s.rations,0,2) or not integer(s.departure_month,3,8) or not integer(s.health,0,100) or not integer(s.ox_health,0,100) or not integer(s.fatigue,0,100) or not strings(s.party,Simulation.MAX_TRAVELERS) or s.party.size()<5 or not strings(s.items,100):
		return null
	if not Simulation.Direction.valid_state(s,game.route) or not game.provisions.Shortfall.valid_state(s):return null
	if s.has("household_gear_lb") and (not (s.household_gear_lb is int or s.household_gear_lb is float) or not is_finite(s.household_gear_lb) or s.household_gear_lb<0 or s.household_gear_lb>100000):return null
	if s.status=="returned_east" and (s.landmark!=game.route.start or s.miles!=0 or s.next_landmark!=""):return null
	if not game.route.nodes.has(s.landmark) or (s.next_landmark != "" and not game.route.nodes.has(s.next_landmark)) or not integer(s.day,0,100000) or not integer(s.miles,0,game.route.longest_miles) or s.leg_miles > s.leg_length:
		return null
	# Saves from before road choices were on the main road.
	var path: Variant=value.get("route_path",game.route.main_path_to(s.landmark))
	if not game.route.valid_path(path) or path[-1]!=s.landmark:return null
	if s.next_landmark!="" and s.next_landmark!=s.landmark and game.route.edge_between(s.landmark,s.next_landmark).is_empty():return null
	if not game.combat.valid(value.get("combat_history",[]),int(s.day),s.party.size()):return null
	if not game.context.valid_record(value.get("context",{"spent":{},"activities":[],"prepared":[]}),game.route):return null
	if not Simulation.CacheSupport.valid(value.get("wagon_cache",{}),game,int(s.day)):return null
	if not value.get("wagon_cache",{}).is_empty() and value.wagon_cache.mile>s.miles and not s.has("travel_direction"):return null
	for key in ["pending","service_return","last_crossing","last_events","weather"]:
		if not value.get(key) is Dictionary:
			return null
	if not valid_menu(value.pending, game,s.party.size()) or not valid_menu(value.service_return, game,s.party.size()):
		return null
	for key in ["random","health_random","survival_random"]:
		if not value.get(key) is String or not value[key].is_valid_int() or str(int(value[key])) != value[key]:
			return null
	for key in ["journal","health_events","seen"]:
		if not strings(value.get(key)):
			return null
	for key in ["crossing_history","supply_history","party","fresh"]:
		if not value.get(key) is Array:
			return null
		for entry in value[key]:
			if not entry is Dictionary:
				return null
	if not integer(value.get("outings"),0,100000) or not integer(value.get("wet_ground"),0,12) or not integer(value.get("days_without_fresh",0),0,100000):
		return null
	if s.extended_route and (value.party.size()<5 or value.party.size()>Simulation.MAX_TRAVELERS or value.party.size()!=s.party.size()):
		return null
	if s.status == "traveling" and s.next_landmark == "":
		return null
	var alive := 0
	var health := 0
	var departed:=0
	for index in range(value.party.size()):
		var member: Dictionary = value.party[index]
		if member.get("id") != index or not member.get("name") is String or not member.get("alive") is bool or not integer(member.get("health"),0,100) or not strings(member.get("history")) or not member.get("conditions") is Array or not member.get("cause") is String or not integer(member.get("death_day"),-1,int(s.day)):
			return null
		if member.has("away") and (member.away!=true or index==0 or not member.alive or member.get("departed",false) or member.get("guarding",false) or int(value.get("characters_version",0))<5):return null
		if member.has("guarding") and (member.guarding!=true or index==0 or not member.alive or member.get("departed",false)):return null
		if member.has("vitamin_days") and not integer(member.vitamin_days,0,100000):return null
		if index>=5 and not integer(member.get("joined_day"),0,int(s.day)):return null
		if index<5 and member.has("joined_day"):return null
		if member.alive != (member.health > 0):
			return null
		if member.has("departed"):
			if not member.departed is bool or not member.departed or index==0 or not member.alive or not integer(member.get("departure_day"),0,int(s.day)) or not game.route.nodes.has(member.get("departure_place","")) or not member.get("departure_supplies") is Dictionary:return null
			# Settlement departures happen at towns and forts; flight after violence happens anywhere.
			if member.has("guard_departure") and member.guard_departure!=true:return null
			if member.has("fled") and member.fled!=true:return null
			if member.has("dismissed") and (member.dismissed!=true or member.get("fled",false)):return null
			if not member.get("fled",false) and not member.get("dismissed",false) and not member.get("guard_departure",false) and game.route.nodes[member.departure_place].kind not in ["town","fort"]:return null
			var supplies: Dictionary=member.departure_supplies
			if supplies.size()!=3 or not integer(supplies.get("food"),0,120) or not integer(supplies.get("clothing"),0,1) or supplies.get("gear_lb")!=game.provisions.data.walking.personal_gear_lb_per_person:return null
			departed+=1
		elif member.has("departure_day") or member.has("departure_place") or member.has("departure_supplies") or member.has("fled") or member.has("dismissed") or member.has("guard_departure"):return null
		alive += 1 if game.party_health.is_active(member) else 0
		health += int(member.health) if game.party_health.is_active(member) else 0
		for condition in member.conditions:
			if not condition is Dictionary or not game.party_health.conditions.has(condition.get("id")) or not integer(condition.get("started_day"),0,int(s.day)) or not integer(condition.get("elapsed"),0,100000) or not integer(condition.get("severity"),1,3):
				return null
		if member.has("immune"):
			if not member.immune is Array:return null
			for id in member.immune:
				if not game.party_health.conditions.has(id) or not game.party_health.conditions[id].get("immunizing",false):return null
	if not Simulation.Guards.valid(value.get("wagon_cache",{}),game,int(s.day),value.party):return null
	if s.extended_route and (alive>Simulation.PARTY_CAPACITY or s.party_size != alive or s.health != (roundi(float(health) / alive) if alive else 0)):
		return null
	if not integer(s.get("departed_gear_lb",0),0,(s.party.size()-1)*int(game.provisions.data.walking.personal_gear_lb_per_person)) or s.get("departed_gear_lb",0)!=departed*int(game.provisions.data.walking.personal_gear_lb_per_person):return null
	if departed>0 and not integer(value.get("characters_version"),3,5):return null
	var fresh := 0
	for batch in value.fresh:
		if not batch is Dictionary:return null
		if not game.provisions.valid_nutrients(batch):return null
		if batch.has("preserved") and not batch.preserved is bool:return null
		if not game.provisions.valid_mass_ratio(batch):return null
		if not integer(batch.get("pounds"),1,1000000) or not integer(batch.get("expires"),int(s.day)+1,1000100):
			return null
		fresh += int(batch.pounds)
	if fresh > s.food:
		return null
	var weather_found := false
	for weather in game.survival.data.weather:
		if normalize(value.weather) == normalize(weather):
			weather_found = true
	if s.extended_route and not weather_found:
		return null
	for id in value.last_events:
		if not id is String or not integer(value.last_events[id],0,int(s.day)):
			return null
	game.state = normalize(s)
	if value.has("characters"):
		var characters_version: Variant=value.get("characters_version",1)
		if not integer(characters_version,1,5) or not game.characters.valid(value.characters,value.party.size(),int(s.day),int(characters_version)==1,int(characters_version)):return null
		game.characters.profiles.assign(normalize(value.characters))
		if int(characters_version)==1:game.characters.upgrade()
		elif int(characters_version)==2:
			for profile in game.characters.profiles:profile.exit_warning={}
	else:
		if value.has("characters_version"):return null
		# Add a neutral starting profile to older records without inventing past decisions.
		game.characters.start(int(s.seed),value.party.size())
		for profile in game.characters.profiles:profile.erase("appearance")
	if int(value.get("characters_version",1))>=4:
		if not game.camp_tasks.valid(value.get("camp_tasks"),game,value.party.size()):return null
		game.camp_tasks.assignments=normalize(value.camp_tasks)
	elif value.has("camp_tasks"):return null
	if not integer(s.get("camp_greens_lb",0),0,int(game.provisions.data.foraging.mass_ratio)-1):return null
	if s.get("camp_greens_lb",0)>0:
		if not integer(s.get("camp_greens_expires"),int(s.day)+1,int(s.day)+int(game.provisions.data.foraging.fresh_days)+1):return null
	elif s.get("camp_greens_expires",0)!=0:return null
	if not game.camp_repair.valid(value.get("camp_repair",{}),game):return null
	game.camp_repair.work=normalize(value.get("camp_repair",{}))
	if not game.camp_repair.work.is_empty() and s.vehicle!="wagon":return null
	if s.has("camp_watch_day")!=s.has("camp_watch_member"):return null
	if s.has("camp_watch_day") and (not integer(s.camp_watch_day,0,int(s.day)) or not integer(s.camp_watch_member,1,value.party.size()-1)):return null
	if int(value.get("characters_version",1))>=5:
		if not game.field_outings.valid(value.get("field_outings"),game,value.party,int(s.day)):return null
		game.field_outings.record=normalize(value.field_outings)
	elif value.has("field_outings"):return null
	game.combat.history.assign(normalize(value.get("combat_history",[])))
	game.context.record=normalize(value.get("context",{"spent":{},"activities":[],"prepared":[]}))
	game.wagon_cache=normalize(value.get("wagon_cache",{}))
	game.pending = normalize(value.pending.resume if value.pending.get("outing_warning",false) else value.pending)
	game.service_return = normalize(value.service_return)
	game.upgrade_foot_crossing(game.pending)
	game.upgrade_foot_crossing(game.service_return)
	game.seen = value.seen.duplicate()
	game.journal.assign(value.journal)
	game.health_events.assign(value.health_events)
	game.party_health.members.assign(normalize(value.party))
	game.provisions.fresh.assign(normalize(value.fresh))
	game.crossing_history.assign(normalize(value.crossing_history))
	game.supply_history.assign(normalize(value.supply_history))
	game.last_crossing = normalize(value.last_crossing)
	game.hunting_outings = int(value.outings)
	game.party_health.days_without_fresh = int(value.get("days_without_fresh",0))
	game.route_path = normalize(value.get("route_path",game.route.main_path_to(str(game.state.landmark))))
	game.rng.state = int(value.random)
	game.party_health.rng.state = int(value.health_random)
	game.survival.rng.state = int(value.survival_random)
	game.survival.weather = normalize(value.weather)
	game.survival.wet_ground = int(value.wet_ground)
	game.survival.last_events = normalize(value.last_events)
	if value.has("crime"):
		var crime: Variant=game.crime.upgrade(value.crime,game)
		if not game.crime.valid(crime,game):return null
		game.crime.record=normalize(crime.record)
		game.crime.rng.state=int(crime.random)
	elif migrated or economy_migrated:game.crime.bind_party(game)
	else:return null
	if value.has("social"):
		if not game.social.valid(value.social,int(s.day),value.party.size()):return null
		game.social.restore(normalize(value.social))
	elif economy_migrated or migrated:game.social.start(game)
	else:return null
	if value.has("recruitment"):
		if not game.recruitment.valid(value.recruitment,game):return null
		game.recruitment.restore(normalize(value.recruitment))
	elif value.party.size()!=5:return null
	if game.pending.get("id","") in ["ox_injury","wandering_ox"]:game.adapt_travel_event(game.pending)
	if game.pending.get("recruit_menu",false) or game.pending.get("dismiss_menu",false):
		if not game.recruitment.valid_open_menu(game):return null
		game.pending=game.recruitment.menu(game) if game.pending.get("recruit_menu",false) else game.recruitment.dismiss_menu(game,int(game.pending.dismiss_target))
	# An open attack menu must still be possible; its text is regenerated.
	if game.pending.get("attack_menu",false):
		var target: int=int(game.pending.choices[0].get("attack_target",-1))
		if not game.crime.attack_ready(game,target):return null
		game.pending=game.crime.attack_menu(game,target)
	# An open riders picker must still belong to a getaway that needs it; its choices are regenerated.
	if game.pending.get("riders_menu",false):
		var riding: Variant=game.pending.get("riding")
		if not riding is Array or not game.crime.can_choose(game,"ride") or game.crime.Wanted.everyone_rides(game):return null
		riding=riding.map(func(id):return int(id) if (id is int or id is float) and id==floor(id) else -1)
		if not game.crime.Wanted.valid_riders(game,riding):return null
		game.pending=game.crime.Wanted.riders_menu(game,riding)
	# An open list of the dead must still offer exactly what can be done; its text is regenerated.
	if game.pending.get("remains_menu",false):
		var authoritative: Dictionary=game.Remains.menu(game)
		var commands:=func(menu):return menu.choices.map(func(choice):return "%s:%d:%d" % [choice.get("remains_command",""),int(choice.get("remains_id",0)),int(choice.get("member",-1))])
		if commands.call(game.pending)!=commands.call(authoritative) or not game.Remains.within_reach(game):return null
		game.pending=authoritative
	if game.pending.get("crime_menu",false):
		if game.pending.has("crime_place"):
			var selected_place: Variant=game.pending.crime_place
			if not selected_place is String:return null
			if game.crime.record.active.is_empty():
				if selected_place not in game.crime.local_places(game,game.service_return):return null
			elif selected_place!=game.crime.incident().place:return null
		# The menu must still have a target: the active incident, this stop's venue, or the traders on the road.
		var target: String=game.crime.target(game)
		if target.is_empty() or (game.crime.record.active.is_empty() and not game.crime.transient(target) and game.service_return.get("landmark","")!=game.state.landmark):return null
		if game.pending.has("crime_target"):
			var uid: Variant=game.pending.crime_target
			if not uid is String or uid not in game.crime.staff_ids(target):return null
			if game.crime.record.active.is_empty() and game.crime.actor(target,uid).health<=0:return null
			if not game.crime.record.active.is_empty() and uid!=game.crime.incident().target:return null
		# Commands must match the authoritative stage; descriptive text is regenerated so it can change between versions.
		var authoritative: Dictionary=game.crime.menu(game)
		var saved_commands: Array = game.pending.choices.map(func(choice):return choice.get("crime_command",""))
		var current_commands: Array = authoritative.choices.map(func(choice):return choice.crime_command)
		var previous_pursuit: bool=economy_migrated and game.crime.incident().get("action","")=="pursuit" and saved_commands==current_commands.filter(func(command):return command!="flee")
		# Older rules offered riding off only when everyone fit on the horses.
		var before_riders: bool=economy_migrated and saved_commands==current_commands.filter(func(command):return command!="ride")
		if saved_commands != current_commands and not previous_pursuit and not before_riders and not (economy_migrated and saved_commands == current_commands.filter(func(command):return command!="assault")):return null
		game.pending=authoritative
	for profile in game.characters.profiles:
		for memory in profile.memories:
			if memory.has("attack_id"):
				if memory.attack_id>game.crime.record.attacks.size() or game.crime.record.attacks[int(memory.attack_id)-1].day!=memory.day:return null
			if memory.has("remains_id"):
				if memory.remains_id>game.crime.record.remains.size():return null
				var body: Dictionary=game.crime.record.remains[int(memory.remains_id)-1]
				# Opening a grave marks it; butchering is the only other way to harm a body.
				if body.state!="processed" and (memory.kind!="remains_disturbed" or not body.disturbed):return null
			if memory.has("incident_id"):
				if memory.incident_id>game.crime.record.incidents.size():return null
				var incident: Dictionary=game.crime.record.incidents[int(memory.incident_id)-1]
				if memory.kind!="action_"+("murder" if incident.action in ["shoot","assault"] else "robbery") or not incident.knowledge.has(game.crime.person_id(int(s.seed),int(profile.id))):return null
	# Deaths from before the ledger existed are known, but not where the bodies lie.
	game.Remains.sync(game,true)
	if migrated:
		if game.state.status == "arrived" and game.state.landmark == "platte":
			game.state.status = "traveling"
			game.pending = {}
			game._set_next_leg()
		load_note = "Upgraded the previous opening-route save; the road now continues to Oregon City."
		game.journal.append(load_note)
	elif economy_migrated:
		load_note = "Updated compatible survival rules. Your existing cash, supplies and pending offers are unchanged."
		game.journal.append(load_note)
	if value.pending.get("outing_warning",false):
		var warning: Dictionary=normalize(value.pending)
		warning.resume=game.pending.duplicate(true)
		game.pending=warning
	error = ""
	return game

func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = normalize(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(normalize(item))
		return result
	if value is float and value == floor(value):
		return int(value)
	return value
