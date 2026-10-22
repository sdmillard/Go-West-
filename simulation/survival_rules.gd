extends RefCounted
## A daily gameplay model, not reconstructed 1848 climate or event frequencies.
var rng := RandomNumberGenerator.new()
var data: Dictionary = {}
var weather: Dictionary = {}
var wet_ground := 0
var last_events: Dictionary = {}
var error := ""
var forced_weather := "" # Deterministic scenario/testing hook; empty in normal play.

func _init() -> void:
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json")))

func load_data(value: Variant) -> bool:
	data = {}
	error = ""
	if not value is Dictionary or not value.get("weather") is Array or value.weather.is_empty() or not value.get("trade_lots") is Array or not value.get("monthly_cold_chance") is Array or value.monthly_cold_chance.size() != 12:
		return _fail("Invalid survival rules")
	if not _number(value.get("event_chance")) or value.event_chance < 0 or value.event_chance > 1 or not _integer(value.get("event_cooldown_days"), 1):
		return _fail("Invalid event frequency")
	if not value.get("team_speed_factors") is Array or value.team_speed_factors.size() != 7:
		return _fail("Expected team speed factors for zero through six oxen")
	var previous_team := -1.0
	for factor in value.team_speed_factors:
		if not _number(factor) or factor < 0 or factor > 1.25 or factor < previous_team:
			return _fail("Team speed factors must not decrease; cap bonuses at a modest level")
		previous_team = float(factor)
	if value.team_speed_factors[0] != 0 or value.team_speed_factors[4] != 1:
		return _fail("Zero oxen must stop; four must be the baseline")
	for key in ["pace_miles", "rest_recovery"]:
		if not value.get(key) is Array or value[key].size() != 3:
			return _fail("Invalid pace or recovery table")
		var previous := 0
		for amount in value[key]:
			if not _integer(amount, 1) or amount <= previous:
				return _fail("Pace and recovery values must increase")
			previous = int(amount)
	for chance in value.monthly_cold_chance:
		if not _number(chance) or chance < 0 or chance > 1:
			return _fail("Invalid seasonal chance")
	var ids: Array = []
	for entry in value.weather:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("label") is String or entry.id in ids or not _integer(entry.get("weight"), 1) or not _number(entry.get("speed")) or entry.speed <= 0 or entry.speed > 1 or not _integer(entry.get("exposure"), 0) or not _integer(entry.get("wet"), 0):
			return _fail("Invalid weather definition")
		ids.append(entry.id)
	for required in ["clear", "rain", "heavy_rain", "fog", "hail", "cold", "blizzard"]:
		if required not in ids:
			return _fail("Missing weather type")
	ids.clear()
	for lot in value.trade_lots:
		if not lot is Dictionary or lot.get("item") not in ["food", "bullets", "medicine", "clothing", "oxen", "wheels", "axles", "tongues", "salt"] or lot.item in ids or not lot.get("label") is String or not _integer(lot.get("amount"), 1) or not _integer(lot.get("buy_cents"), 1) or not _integer(lot.get("sell_cents"), 1) or lot.sell_cents >= lot.buy_cents:
			return _fail("Invalid trade lot")
		ids.append(lot.item)
	data = value.duplicate(true)
	weather = data.weather[0].duplicate()
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _integer(value: Variant, minimum: int) -> bool:
	return _number(value) and value == floor(value) and value >= minimum

func _fail(message: String) -> bool:
	error = message
	data = {}
	return false

func start(seed_value: int) -> void:
	rng.seed = seed_value ^ 0x54524149
	wet_ground = 0
	last_events.clear()
	weather = data.weather[0].duplicate()

func set_weather(id: String) -> void:
	for entry in data.weather:
		if entry.id == id:
			weather = entry.duplicate()
			return

func advance(month: int, terrain: String = "plains", region: Dictionary = {}) -> void:
	var cold: bool = rng.randf() < minf(1.0, float(data.monthly_cold_chance[month - 1]) + (0.25 if terrain == "mountains" else 0.0))
	var candidates: Array = []
	var total := 0
	for entry in data.weather:
		if not cold and entry.id in ["cold", "blizzard"]:
			continue
		var candidate: Dictionary=entry.duplicate()
		var multiplier: float=float(region.get("cold",1.0)) if entry.id in ["cold","blizzard"] else (float(region.get("wet",1.0)) if entry.id in ["rain","heavy_rain","fog"] else 1.0)
		candidate.weight=maxi(1,roundi(float(entry.weight)*multiplier))
		candidates.append(candidate)
		total += int(candidate.weight)
	var roll := rng.randi_range(1, total)
	for entry in candidates:
		roll -= int(entry.weight)
		if roll <= 0:
			set_weather(entry.id)
			break
	# Cold days preferentially become cold or snowy, rather than always clear.
	if cold and rng.randf() < 0.6:
		set_weather("blizzard" if month in [1, 2, 3, 11, 12] and rng.randf() < 0.15 else "cold")
	if not forced_weather.is_empty():
		set_weather(forced_weather)
	wet_ground = clampi(wet_ground - 1 + int(weather.wet), 0, 12)

func team_factor(oxen: int) -> float:
	return float(data.team_speed_factors[clampi(oxen, 0, 6)])

func movement_factor(oxen: int, ox_health: int, fatigue: int, _food: int, terrain: String = "plains") -> float:
	var team := team_factor(oxen)
	var condition := 0.45 + 0.55 * clampf(float(ox_health) / 100.0, 0, 1)
	var tired := 1.0 - clampf(float(fatigue) / 300.0, 0, 0.35)
	return float(weather.speed) * team * condition * tired * (0.8 if terrain == "mountains" else (0.9 if terrain == "forest" else (0.95 if terrain == "desert" else 1.0)))

func eligible(event: Dictionary, day: int) -> bool:
	return day - int(last_events.get(event.id, -1000)) >= int(data.event_cooldown_days) and (not event.has("weather") or weather.id in event.weather)
