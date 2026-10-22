extends RefCounted
## Versioned plain JSON; never instantiates serialized objects or executes save content.
const Simulation = preload("res://simulation/trail_engine.gd")
const FORMAT := "westward-probably"
const VERSION := 1
const DEFAULT_PATH := "user://journey.json"
const MAX_BYTES := 2097152
const RULE_FILES = ["outfitting", "route", "health_conditions", "survival_rules", "hunting", "provisions", "trail_events", "trail_context", "combat_rules", "party_benefits", "character_catalog", "crime_scenes"]
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
	if not game.state.extended_route or not game.hunt.is_empty() or game.state.status not in ["traveling", "arrived", "lost"]:
		return {}
	return normalize({"format": FORMAT, "version": VERSION, "rules": fingerprint(),
		"crime":game.crime.snapshot(),
		"characters_version":3,"characters":game.characters.profiles.duplicate(true),
		"combat_history":game.combat.history.duplicate(true),"context":game.context.record.duplicate(true),"route_end":game.route.end_id,"wagon_cache":game.wagon_cache.duplicate(true), "state":game.state.duplicate(true), "pending":game.pending.duplicate(true),
		"seen":game.seen.duplicate(), "journal":Array(game.journal),
		"last_crossing":game.last_crossing.duplicate(true), "crossing_history":game.crossing_history.duplicate(true),
		"supply_history":game.supply_history.duplicate(true), "service_return":game.service_return.duplicate(true),
		"party":game.party_health.members.duplicate(true), "health_events":Array(game.health_events),
		"fresh":game.provisions.fresh.duplicate(true), "outings":game.hunting_outings,
		"random":str(game.rng.state), "health_random":str(game.party_health.rng.state),
		"survival_random":str(game.survival.rng.state),
		"weather":game.survival.weather.duplicate(true), "wet_ground":game.survival.wet_ground,
		"last_events":game.survival.last_events.duplicate(true)})

func save_game(game, path: String = DEFAULT_PATH) -> bool:
	error = ""
	var snapshot := capture(game)
	if snapshot.is_empty():
		error = "Finish the hunt or depart before saving."
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

func valid_menu(menu: Dictionary, game) -> bool:
	if menu.is_empty():
		return true
	if not menu.get("id") is String or not menu.get("title") is String or not menu.get("text") is String or not menu.get("choices") is Array or menu.choices.is_empty() or menu.choices.size() > 40:
		return false
	if menu.has("landmark") and not game.route.nodes.has(menu.landmark):
		return false
	for choice in menu.choices:
		if not choice is Dictionary or not choice.get("label") is String:
			return false
		if menu.has("crime_menu") and (menu.crime_menu!=true or menu.id!="crime" or not menu.get("service_menu",false) or choice.get("crime_command","") not in game.crime.COMMANDS):return false
		if choice.has("crime_command") and not menu.get("crime_menu",false):return false
		if choice.has("action") and choice.action not in ["cross", "rest", "leave", "trade", "notes", "activity"]:
			return false
		if choice.has("activity") and (not choice.activity is String or not game.context.data.activities.has(choice.activity)):return false
		if choice.get("action","")=="activity" and (choice.get("activity","")!=menu.get("landmark","") or not game.context.data.activities.get(choice.get("activity",""),{}).has("kind") or not choice.get("result") is String):return false
		if choice.has("market_key")!=choice.has("stock_limit"):return false
		if choice.has("market_key") and (not choice.market_key is String or choice.market_key.length()>128 or not integer(choice.get("stock_limit"),1,8)):return false
		if choice.has("text") and not choice.text is String:return false
		if choice.has("method") and choice.method not in ["ford", "float", "ferry", "swim", "wade"]:
			return false
		if not menu.has("landmark") and not choice.get("result") is String:
			return false
		if not valid_effects(choice.get("effects", {})) or not valid_effects(choice.get("requires", {})):
			return false
		for flag in ["complete", "rest"]:
			if choice.has(flag) and not choice[flag] is bool:
				return false
		if choice.has("departure_review") and (not choice.departure_review is bool or not menu.get("service_menu",false)):return false
		if choice.get("combat","") not in ["","defend","circle"]:return false
		if choice.has("combat") and not choice.get("risk") is Dictionary:return false
		if choice.has("quoted_risk") and (not (choice.quoted_risk is int or choice.quoted_risk is float) or not is_finite(float(choice.quoted_risk)) or choice.quoted_risk<0 or choice.quoted_risk>1):return false
		if choice.has("care") and (not integer(choice.care,0,100) or not integer(choice.get("member_id"),0,4)):
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
		if key not in ["food","health","money","fuel","wheels","axles","tongues","medicine","clothing","bullets","oxen","ox_health","days","item","vehicle","salt"]:
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
	if not integer(s.get("seed"), -2147483648, 2147483647) or s.get("extended_route") != true or s.get("status") not in ["traveling", "arrived", "lost"]:
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
	if s.mode not in ["classic", "unhinged"] or not integer(s.pace,0,2) or not integer(s.rations,0,2) or not integer(s.departure_month,3,8) or not integer(s.health,0,100) or not integer(s.ox_health,0,100) or not integer(s.fatigue,0,100) or not strings(s.party,5) or s.party.size() != 5 or not strings(s.items,100):
		return null
	if not game.route.nodes.has(s.landmark) or (s.next_landmark != "" and not game.route.nodes.has(s.next_landmark)) or not integer(s.day,0,100000) or not integer(s.miles,0,game.destination()) or s.leg_miles > s.leg_length:
		return null
	if not game.combat.valid(value.get("combat_history",[]),int(s.day)):return null
	if not game.context.valid_record(value.get("context",{"spent":{},"activities":[],"prepared":[]}),game.route):return null
	if not Simulation.CacheSupport.valid(value.get("wagon_cache",{}),game,int(s.day)):return null
	if not value.get("wagon_cache",{}).is_empty() and value.wagon_cache.mile>s.miles:return null
	for key in ["pending","service_return","last_crossing","last_events","weather"]:
		if not value.get(key) is Dictionary:
			return null
	if not valid_menu(value.pending, game) or not valid_menu(value.service_return, game):
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
	if not integer(value.get("outings"),0,100000) or not integer(value.get("wet_ground"),0,12):
		return null
	if s.extended_route and value.party.size() != 5:
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
		if member.alive != (member.health > 0):
			return null
		if member.has("departed"):
			if not member.departed is bool or not member.departed or index==0 or not member.alive or not integer(member.get("departure_day"),0,int(s.day)) or not game.route.nodes.has(member.get("departure_place","")) or not member.get("departure_supplies") is Dictionary:return null
			if game.route.nodes[member.departure_place].kind not in ["town","fort"]:return null
			var supplies: Dictionary=member.departure_supplies
			if supplies.size()!=3 or not integer(supplies.get("food"),0,120) or not integer(supplies.get("clothing"),0,1) or supplies.get("gear_lb")!=game.provisions.data.walking.personal_gear_lb_per_person:return null
			departed+=1
		elif member.has("departure_day") or member.has("departure_place") or member.has("departure_supplies"):return null
		alive += 1 if game.party_health.is_active(member) else 0
		health += int(member.health) if game.party_health.is_active(member) else 0
		for condition in member.conditions:
			if not condition is Dictionary or not game.party_health.conditions.has(condition.get("id")) or not integer(condition.get("started_day"),0,int(s.day)) or not integer(condition.get("elapsed"),0,100000) or not integer(condition.get("severity"),1,3):
				return null
	if s.extended_route and (s.party_size != alive or s.health != (roundi(float(health) / alive) if alive else 0)):
		return null
	if not integer(s.get("departed_gear_lb",0),0,4*int(game.provisions.data.walking.personal_gear_lb_per_person)) or s.get("departed_gear_lb",0)!=departed*int(game.provisions.data.walking.personal_gear_lb_per_person):return null
	if departed>0 and value.get("characters_version")!=3:return null
	var fresh := 0
	for batch in value.fresh:
		if batch.has("preserved") and not batch.preserved is bool:return null
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
		if not integer(characters_version,1,3) or not game.characters.valid(value.characters,value.party.size(),int(s.day),int(characters_version)==1,int(characters_version)):return null
		game.characters.profiles.assign(normalize(value.characters))
		if int(characters_version)==1:game.characters.upgrade()
		elif int(characters_version)==2:
			for profile in game.characters.profiles:profile.exit_warning={}
	else:
		if value.has("characters_version"):return null
		# Add a neutral starting profile to older records without inventing past decisions.
		game.characters.start(int(s.seed),value.party.size())
	game.combat.history.assign(normalize(value.get("combat_history",[])))
	game.context.record=normalize(value.get("context",{"spent":{},"activities":[],"prepared":[]}))
	game.wagon_cache=normalize(value.get("wagon_cache",{}))
	game.pending = normalize(value.pending)
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
	game.rng.state = int(value.random)
	game.party_health.rng.state = int(value.health_random)
	game.survival.rng.state = int(value.survival_random)
	game.survival.weather = normalize(value.weather)
	game.survival.wet_ground = int(value.wet_ground)
	game.survival.last_events = normalize(value.last_events)
	if value.has("crime"):
		var crime: Variant=game.crime.upgrade(value.crime)
		if not game.crime.valid(crime,game):return null
		game.crime.record=normalize(crime.record)
		game.crime.rng.state=int(crime.random)
	elif migrated or economy_migrated:game.crime.bind_party(game)
	else:return null
	if game.pending.get("crime_menu",false):
		if not game.crime.scenes.has(game.state.landmark) or not game.service_return.has("landmark") or game.service_return.landmark!=game.state.landmark:return null
		# Commands must match the authoritative stage; descriptive text is regenerated so it can change between versions.
		var authoritative: Dictionary=game.crime.menu(game)
		if game.pending.choices.map(func(choice):return choice.get("crime_command","")) != authoritative.choices.map(func(choice):return choice.crime_command):return null
		game.pending=authoritative
	for profile in game.characters.profiles:
		for memory in profile.memories:
			if memory.has("incident_id"):
				if memory.incident_id>game.crime.record.incidents.size():return null
				var incident: Dictionary=game.crime.record.incidents[int(memory.incident_id)-1]
				if memory.kind!="action_"+("murder" if incident.action=="shoot" else "robbery") or not incident.knowledge.has(game.crime.person_id(int(s.seed),int(profile.id))):return null
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
