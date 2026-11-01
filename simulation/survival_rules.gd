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
	# Each step up in pace costs the travelers and the team a little more each day, never less.
	for key in ["pace_health_cost", "pace_ox_strain"]:
		if not value.get(key) is Array or value[key].size() != 3 or value[key][0] != 0:
			return _fail("Invalid pace cost table")
		var floor_cost := 0.0
		for amount in value[key]:
			if not (_integer(amount, 0) if key == "pace_health_cost" else _number(amount)) or amount < floor_cost or amount > 6:
				return _fail("Pace costs must not decrease")
			floor_cost = float(amount)
	for chance in value.monthly_cold_chance:
		if not _number(chance) or chance < 0 or chance > 1:
			return _fail("Invalid seasonal chance")
	if not value.get("seasonal") is Dictionary:return _fail("Missing seasonal rules")
	var season: Dictionary=value.seasonal
	for key in ["travel","rest_ox_recovery","working_strain"]:
		if not season.get(key) is Array or season[key].size()!=12:return _fail("Expected twelve seasonal values")
		for amount in season[key]:
			if not _number(amount) or amount<0 or (key=="travel" and (amount<=0 or amount>1)) or (key!="travel" and (amount!=int(amount) or amount>4)):return _fail("Invalid seasonal value")
	for key in ["winter_months","snow_months"]:
		if not season.get(key) is Array or season[key].is_empty():return _fail("Missing seasonal months")
		var seen: Array=[]
		for month in season[key]:
			if not _integer(month,1) or month>12 or month in seen:return _fail("Invalid seasonal month")
			seen.append(month)
	for key in ["winter_snow_chance","autumn_snow_chance"]:
		if not _number(season.get(key)) or season[key]<0 or season[key]>1:return _fail("Invalid snow chance")
	if not _number(season.get("upland_severity")) or season.upland_severity<1 or season.upland_severity>2 or not _integer(season.get("clothed_blizzard_damage"),0) or season.clothed_blizzard_damage>3:return _fail("Invalid upland storm rules")
	var ids: Array = []
	for entry in value.weather:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("label") is String or entry.id in ids or not _integer(entry.get("weight"), 1) or not _number(entry.get("speed")) or entry.speed <= 0 or entry.speed > 1 or not _integer(entry.get("exposure"), 0) or not _integer(entry.get("wet"), 0):
			return _fail("Invalid weather definition")
		if not _valid_climate(entry):
			return _fail("Invalid weather season or region")
		ids.append(entry.id)
	for required in ["clear", "rain", "heavy_rain", "fog", "hail", "cold", "blizzard"]:
		if required not in ids:
			return _fail("Missing weather type")
	var rivers: Variant=season.get("river_high_chance",{})
	if not rivers is Dictionary:return _fail("Invalid river stage chances")
	for source in rivers:
		if source not in ["rain","snowmelt"] or not rivers[source] is Array or rivers[source].size()!=12:return _fail("Invalid river stage chances")
		for chance in rivers[source]:
			if not _number(chance) or chance<0 or chance>1:return _fail("Invalid river stage chances")
	ids.clear()
	for lot in value.trade_lots:
		if not lot is Dictionary or lot.get("item") not in ["food", "bullets", "medicine", "clothing", "oxen", "wheels", "axles", "tongues", "salt", "horses", "mules", "saddles", "pack_saddles", "saddlebags", "rifles", "shotguns", "pistols", "knives", "hatchets"] or (lot.has("post_lots") and (not _integer(lot.post_lots, 1) or lot.post_lots > 8)) or lot.item in ids or not lot.get("label") is String or not _integer(lot.get("amount"), 1) or not _integer(lot.get("buy_cents"), 1) or not _integer(lot.get("sell_cents"), 1) or lot.sell_cents >= lot.buy_cents:
			return _fail("Invalid trade lot")
		ids.append(lot.item)
	data = value.duplicate(true)
	for key in ["winter_months","snow_months"]:data.seasonal[key]=data.seasonal[key].map(func(month):return int(month))
	weather = data.weather[0].duplicate()
	return true

# Optional climate fields: months the weather can occur, regional weight
# multipliers (0 excludes a region), extra team strain and illness risk.
func _valid_climate(entry: Dictionary) -> bool:
	if entry.has("months"):
		if not entry.months is Array or entry.months.is_empty():return false
		for month in entry.months:
			if not _integer(month,1) or month>12:return false
	if entry.has("regions"):
		if not entry.regions is Dictionary:return false
		for region in entry.regions:
			if not _number(entry.regions[region]) or entry.regions[region]<0:return false
	if entry.has("ox_strain") and (not _integer(entry.ox_strain,0) or entry.ox_strain>3):return false
	if entry.has("illness_risk") and (not _number(entry.illness_risk) or entry.illness_risk<0.5 or entry.illness_risk>3):return false
	return true

## Chance that a river is running high on arrival, by its water source and month.
func river_high_chance(month: int, source: String = "rain") -> float:
	var table: Dictionary=data.seasonal.get("river_high_chance",{})
	if not table.has(source):return 0.45
	return float(table[source][clampi(month,1,12)-1])

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
		if (not cold and entry.id in ["cold", "blizzard"]) or (entry.id=="blizzard" and month not in data.seasonal.snow_months):
			continue
		if entry.has("months") and month not in entry.months.map(func(m):return int(m)):
			continue
		var candidate: Dictionary=entry.duplicate()
		var multiplier: float=float(region.get("cold",1.0)) if entry.id in ["cold","blizzard"] else (float(region.get("wet",1.0)) if entry.id in ["rain","heavy_rain","fog","thunderstorm"] else 1.0)
		if entry.has("regions") and region.has("id"):
			multiplier*=float(entry.regions.get(region.id,1.0))
			if multiplier<=0.0:continue
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
		var snow: float=float(data.seasonal.winter_snow_chance) if month in data.seasonal.winter_months else float(data.seasonal.autumn_snow_chance)
		set_weather("blizzard" if month in data.seasonal.snow_months and rng.randf()<snow else "cold")
	if not forced_weather.is_empty():
		set_weather(forced_weather)
	wet_ground = clampi(wet_ground - 1 + int(weather.wet), 0, 12)

func team_factor(oxen: int) -> float:
	return float(data.team_speed_factors[clampi(oxen, 0, 6)])

func movement_factor(oxen: int, ox_health: int, fatigue: int, _food: int, terrain: String = "plains", month: int=6, region: Dictionary={}) -> float:
	var team := team_factor(oxen)
	var condition := 0.45 + 0.55 * clampf(float(ox_health) / 100.0, 0, 1)
	var tired := 1.0 - clampf(float(fatigue) / 300.0, 0, 0.35)
	return float(seasonal(month,terrain,region).travel) * float(weather.speed) * team * condition * tired * (0.8 if terrain == "mountains" else (0.9 if terrain == "forest" else (0.95 if terrain == "desert" else 1.0)))

func eligible(event: Dictionary, day: int) -> bool:
	return day - int(last_events.get(event.id, -1000)) >= int(data.event_cooldown_days) and (not event.has("weather") or weather.id in event.weather)

## Pure calendar preview. It never consumes randomness or grants recovery.
func seasonal(month: int,terrain: String="plains",region: Dictionary={}) -> Dictionary:
	var index: int=clampi(month,1,12)-1
	var upland: bool=terrain=="mountains" or float(region.get("cold",1.0))>=1.4
	var rules: Dictionary=data.seasonal
	var winter: bool=month in rules.winter_months
	return {"travel":maxf(0.35,1.0-(1.0-float(rules.travel[index]))*(float(rules.upland_severity) if upland else 1.0)),"rest_ox_recovery":int(rules.rest_ox_recovery[index]),"working_strain":int(rules.working_strain[index])+(1 if winter and upland else 0),"storm_damage":int(rules.clothed_blizzard_damage) if winter and weather.get("id","")=="blizzard" else 0,"winter":winter,"upland":upland}
