extends RefCounted
## Validated declarative content. No scripts or expressions are executed from JSON.

const NUMERIC = ["food", "health", "money", "fuel", "days", "wheels", "axles", "tongues", "medicine", "oxen", "clothing", "bullets", "ox_health", "salt"]
var events: Array = []
var error: String = ""

func load_file(path: String = "res://data/events.json", repeatable: bool = false) -> bool:
	events.clear()
	error = ""
	if not FileAccess.file_exists(path):
		error = "Missing event file: " + path
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		error = "Invalid JSON: " + parser.get_error_message()
		return false
	return load_data(parser.data, repeatable)

func load_data(data: Variant, repeatable: bool = false) -> bool:
	events.clear()
	error = ""
	if not data is Array or data.is_empty():
		return _fail("Expected a nonempty event array")
	var ids: Dictionary = {}
	for event in data:
		if not event is Dictionary:
			return _fail("Event must be an object")
		for key in ["id", "title", "text", "category", "trigger"]:
			if not event.get(key) is String or event[key].is_empty():
				return _fail("Missing text field: " + key)
		if ids.has(event.id):
			return _fail("Duplicate event: " + event.id)
		ids[event.id] = true
		if not _effects(event.get("onset_effects", {})):
			return _fail("Invalid onset effects")
		if event.has("weight") and (not _number(event.weight) or event.weight <= 0 or event.weight != floor(event.weight)):
			return _fail("Invalid event weight")
		if event.has("weather") and (not event.weather is Array or event.weather.is_empty()):
			return _fail("Invalid weather eligibility")
		for weather in event.get("weather", []):
			if weather not in ["clear", "rain", "heavy_rain", "fog", "hail", "cold", "blizzard"]:
				return _fail("Unknown weather eligibility")
		if event.get("condition", "") not in ["", "broken_arm", "broken_leg", "dysentery", "cholera", "typhoid", "measles", "exhaustion", "snakebite", "wound"]:
			return _fail("Invalid personal condition")
		if event.has("condition_choices"):
			if not event.condition_choices is Array or event.condition_choices.is_empty():
				return _fail("Invalid injury alternatives")
			for injury in event.condition_choices:
				if injury not in ["broken_arm", "broken_leg"]:
					return _fail("Unknown injury alternative")
		if event.category not in ["historical", "absurd"] or event.trigger not in ["day", "mile", "random"]:
			return _fail("Unknown category or trigger")
		if event.category == "absurd" and event.trigger != "random":
			return _fail("Absurd events must use random trigger")
		if repeatable and (event.category != "historical" or event.trigger != "random" or not event.has("weight")):
			return _fail("Repeatable events require a historical random trigger and weight")
		if event.trigger != "random" and (not _number(event.get("at")) or event.at < 0):
			return _fail("Invalid trigger threshold")
		if not event.get("choices") is Array or event.choices.is_empty():
			return _fail("Choices must be a nonempty array")
		for choice in event.choices:
			if not choice is Dictionary or not choice.get("label") is String or not choice.get("result") is String:
				return _fail("Choice needs label and result")
			if not _effects(choice.get("effects", {})):
				return _fail("Invalid effects")
			if choice.get("service", "") not in ["", "repair", "defend"]:
				return _fail("Invalid event action")
			if not choice.get("complete", false) is bool:
				return _fail("Complete must be boolean")
			if not choice.get("rest", false) is bool:
				return _fail("Rest must be boolean")
			var requirements: Variant = choice.get("requires", {})
			if not requirements is Dictionary:
				return _fail("Requirements must be an object")
			for key in requirements:
				if key not in NUMERIC or key == "days" or not _number(requirements[key]) or requirements[key] < 0:
					return _fail("Invalid requirement")
			if choice.get("combat","") not in ["","defend","circle"]:return _fail("Invalid combat tactic")
			if choice.has("combat") and (not choice.get("risk") is Dictionary or choice.risk.get("condition","")!="wound" or not choice.risk.has("victim_damage") or not choice.risk.has("severity")):return _fail("Combat needs explicit personal injury consequences")
			if choice.has("risk"):
				var risk: Variant = choice.risk
				if not risk is Dictionary or not _number(risk.get("probability")):
					return _fail("Invalid risk")
				for key in ["victim_damage","severity"]:
					if risk.has(key) and (not _number(risk[key]) or risk[key]!=int(risk[key]) or risk[key]<(1 if key=="severity" else 0) or risk[key]>(3 if key=="severity" else 100)):return _fail("Invalid personal injury risk")
				if risk.probability < 0 or risk.probability > 1 or not _effects(risk.get("effects", {})) or not risk.get("text") is String:
					return _fail("Invalid risk details")
				if risk.get("condition", "") not in ["", "dysentery", "wound", "broken_leg", "snakebite"]:
					return _fail("Invalid risk condition")
		events.append(event.duplicate(true))
	return true

func _effects(effects: Variant) -> bool:
	if not effects is Dictionary:
		return false
	for key in effects:
		if key in NUMERIC:
			if not _number(effects[key]):
				return false
			if key == "days" and (effects[key] < 0 or effects[key] != floor(effects[key]) or effects[key] > 30):
				return false
		elif key == "item":
			if not effects[key] is String or effects[key].is_empty():
				return false
		elif key == "vehicle":
			if effects[key] not in ["wagon", "corolla"]:
				return false
		else:
			return false
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _fail(message: String) -> bool:
	events.clear()
	error = message
	return false
