extends RefCounted
## Per-person state, independent of UI. All numbers are provisional gameplay tuning.
var members: Array[Dictionary] = []
var conditions: Dictionary = {}
var daily_onset_chance := 0.0
var notices: Array[String] = []
var error := ""
var rng := RandomNumberGenerator.new()
# Derived reference to the character profiles; saves store flaws only in that roster.
var character_profiles: Array[Dictionary]=[]
var character_catalog

func _init() -> void:
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json")))

func load_data(data: Variant) -> bool:
	conditions.clear()
	error = ""
	if not data is Dictionary or not data.get("conditions") is Array or data.conditions.is_empty():
		return _fail("Expected health condition data")
	var chance: Variant = data.get("daily_onset_chance")
	if not _number(chance) or chance < 0 or chance > 1:
		return _fail("Invalid health event chance")
	for entry in data.conditions:
		if not entry is Dictionary:
			return _fail("Invalid health condition")
		for key in ["id", "name", "kind"]:
			if not entry.get(key) is String or entry[key].is_empty():
				return _fail("Missing health condition field")
		if conditions.has(entry.id) or entry.kind not in ["illness", "injury"]:
			return _fail("Duplicate or invalid health condition")
		if entry.has("from_year") and (not _number(entry.from_year) or entry.from_year != floor(entry.from_year) or entry.from_year < 1):
			return _fail("Invalid condition chronology")
		for key in ["daily_damage", "recovery_days"]:
			if not _number(entry.get(key)) or entry[key] != floor(entry[key]) or entry[key] <= 0:
				return _fail("Invalid health progression")
		conditions[entry.id] = entry.duplicate(true)
	daily_onset_chance = float(chance)
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _fail(message: String) -> bool:
	conditions.clear()
	daily_onset_chance = 0.0
	error = message
	return false

func start(names: Array, seed_value: int) -> void:
	members.clear()
	notices.clear()
	rng.seed = seed_value ^ 0x50415254
	for index in range(names.size()):
		members.append({"id": index, "name": names[index], "health": 85,
			"alive": true, "conditions": [], "history": [], "death_day": -1, "cause": ""})

static func condition_label(health: int) -> String:
	if health >= 80:
		return "GOOD"
	if health >= 50:
		return "FAIR"
	if health >= 20:
		return "POOR"
	return "VERY POOR"

static func is_active(member: Dictionary) -> bool:
	return member.alive and not member.get("departed",false)

func living_count() -> int:
	var count := 0
	for member in members:
		count += 1 if is_active(member) else 0
	return count

func average_health() -> int:
	var total := 0
	for member in members:
		if is_active(member):
			total += int(member.health)
	return roundi(float(total) / living_count()) if living_count() else 0

func _record(member: Dictionary, day: int, text: String) -> void:
	var entry := "Day %d · %s" % [day, text]
	member.history.append(entry)
	notices.append(entry)

func affect(member: Dictionary, delta: int, day: int, cause: String) -> void:
	if not is_active(member):
		return
	if character_catalog!=null and int(member.id)<character_profiles.size():delta=character_catalog.health_delta(character_profiles[int(member.id)],delta,cause,conditions)
	member.health = clampi(int(member.health) + delta, 0, 100)
	if delta < 0 and cause == "crossing injuries" and member.health > 0:
		member.history.append("Day %d · Suffered injuries during a river crossing." % day)
	if member.health == 0:kill(member,day,cause)

func kill(member: Dictionary,day: int,cause: String) -> void:
	if not is_active(member):return
	member.health=0
	member.alive=false
	member.death_day=day
	member.cause=cause
	_record(member,day,"%s died from %s." % [member.name,cause])

func affect_all(delta: int, day: int, cause: String) -> void:
	for member in members:
		affect(member, delta, day, cause)

func begin_condition(member_id: int, condition_id: String, day: int, severity: int = 1) -> bool:
	if member_id < 0 or member_id >= members.size() or not conditions.has(condition_id):
		return false
	var member: Dictionary = members[member_id]
	if not is_active(member):
		return false
	for active in member.conditions:
		if active.id == condition_id:
			return false
	var definition: Dictionary = conditions[condition_id]
	member.conditions.append({"id": condition_id, "started_day": day, "elapsed": 0, "severity": clampi(severity, 1, 3)})
	_record(member, day, "%s has %s." % [member.name, definition.name.to_lower()])
	return true

func roll_severity(rations: int) -> int:
	# BASIC 6300–6360 conditional severity branching, using our 0–2 ration index.
	if rng.randf() * 100 < 10 + 35 * clampi(rations, 0, 2):
		return 1
	return 3 if rng.randf() * 100 >= 100 - 40.0 / pow(4, clampi(rations, 0, 2)) else 2

func automatic_conditions(year: int) -> Array[String]:
	var candidates: Array[String] = []
	for id in conditions:
		if conditions[id].kind == "illness" and year >= int(conditions[id].get("from_year", 0)):
			candidates.append(id)
	return candidates

func tick(day: int, resting: bool, risk_multiplier: float = 1.0, rations: int = 2, year: int = 1848) -> void:
	for member in members:
		if not is_active(member):
			continue
		for active in member.conditions.duplicate():
			var definition: Dictionary = conditions[active.id]
			affect(member, -int(definition.daily_damage) * int(active.get("severity", 1)), day, definition.name.to_lower())
			if not is_active(member):
				break
			active.elapsed += 2 if resting else 1
			if active.elapsed >= definition.recovery_days:
				member.conditions.erase(active)
				_record(member, day, "%s recovered from %s." % [member.name, definition.name.to_lower()])
	# One provisional party-level onset roll per day; a separate seeded stream
	# keeps watching the party and opening dialogs from changing any outcomes.
	if living_count() == 0 or rng.randf() >= clampf(daily_onset_chance * risk_multiplier, 0, 1):
		return
	var candidates: Array[int] = []
	for member in members:
		if is_active(member) and member.conditions.is_empty():
			candidates.append(int(member.id))
	var available: Array[String] = automatic_conditions(year)
	if not candidates.is_empty() and not available.is_empty():
		begin_condition(candidates[rng.randi_range(0, candidates.size() - 1)],
			available[rng.randi_range(0, available.size() - 1)], day, roll_severity(rations))

func description(member_id: int) -> String:
	var member: Dictionary = members[member_id]
	if member.get("departed",false):
		return "%s\n\nLEFT THE PARTY · DAY %d\nLocation: %s\n\n%s" % [member.name.to_upper(),member.departure_day,member.departure_place,"\n".join(member.history)]
	var lines: Array[String] = [member.name.to_upper()]
	if not is_active(member):
		lines.append("DIED · DAY %d\nCause: %s" % [member.death_day, member.cause])
	else:
		lines.append("Condition: " + condition_label(member.health))
		if member.conditions.is_empty():
			lines.append("No current illness or injury.")
		for active in member.conditions:
			lines.append("%s · %s · since day %d" % [conditions[active.id].name, ["Mild", "Bad", "Serious"][int(active.get("severity", 1)) - 1], active.started_day])
	lines.append("PERSONAL HISTORY")
	lines.append("\n".join(member.history) if not member.history.is_empty() else "No health events recorded.")
	return "\n\n".join(lines)

