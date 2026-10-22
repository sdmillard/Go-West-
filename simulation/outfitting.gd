extends RefCounted
## Prices are integer cents. Quotes are read-only; the engine commits departure once.
var provisions = preload("res://simulation/provisions.gd").new()
var professions: Array = []
var goods: Array = []
var error := ""

func _init() -> void:
	if not FileAccess.file_exists("res://data/outfitting.json"):
		error = "Missing outfitting data."
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/outfitting.json"))
	load_data(data)

func load_data(data: Variant) -> bool:
	professions = []
	goods = []
	error = ""
	if not data is Dictionary or not data.get("professions") is Array or not data.get("goods") is Array:
		error = "Outfitting data could not be loaded."
		return false
	for section in ["professions", "goods"]:
		var required: Array = ["banker", "carpenter", "farmer"] if section == "professions" else ["oxen", "food", "clothing", "bullet_boxes", "wheels", "axles", "tongues", "medicine", "salt"]
		var seen: Array = []
		for entry in data[section]:
			if not entry is Dictionary or not entry.get("id") is String or entry.id not in required or entry.id in seen or not entry.get("label") is String or entry.label.is_empty():
				error = "Invalid or duplicate outfitting entry."
				return false
			seen.append(entry.id)
			var fields: Array = ["cash_cents"] if section == "professions" else ["price_cents", "maximum", "step", "suggested"]
			for field in fields:
				var number: Variant = entry.get(field)
				if not (number is int or number is float) or not is_finite(float(number)) or number != floor(number) or number < 0 or number > 100000000:
					error = "Invalid outfitting quantity or price."
					return false
			if section == "goods" and (entry.price_cents == 0 or entry.step == 0 or entry.suggested > entry.maximum):
				error = "Invalid outfitting limits."
				return false
		if seen.size() != required.size():
			error = "Missing required outfitting entries."
			return false
	professions = data.professions.duplicate(true)
	goods = data.goods.duplicate(true)
	return true

func quote(profession: String, cart: Dictionary) -> Dictionary:
	var result := {"valid": false, "message": "Choose a profession.", "total_cents": 0, "remaining_cents": 0, "budget_cents": 0}
	if not error.is_empty() or not provisions.error.is_empty():
		result.message = error if not error.is_empty() else provisions.error
		return result
	var found := false
	for entry in professions:
		if entry.id == profession:
			found = true
			result.budget_cents = int(entry.cash_cents)
	if not found:
		return result
	var allowed: Array = []
	for good in goods:
		allowed.append(good.id)
		var count: Variant = cart.get(good.id, 0)
		if not (count is int or count is float) or not is_finite(float(count)) or count != floor(count) or count < 0 or count > good.maximum:
			result.message = "Check the quantity of " + good.id + "."
			return result
		result.total_cents += int(count) * int(good.price_cents)
	for key in cart:
		if key not in allowed:
			result.message = "Unknown supply: " + str(key)
			return result
	result["cargo_lb"] = provisions.cart_cargo(cart)
	result["team_capacity_lb"] = provisions.team_capacity(int(cart.get("oxen",0)))
	result.remaining_cents = result.budget_cents - result.total_cents
	if result.remaining_cents < 0:
		result.message = "Your purchases exceed your cash."
	elif result.cargo_lb > provisions.data.cargo_guideline_lb:
		result.message = "Lighten the cargo to 2,500 lb before departure."
	elif cart.get("oxen", 0) < 1:
		result.message = "Buy at least one ox to pull the wagon."
	else:
		result.valid = true
		result.message = "Ready to depart. Keep some cash for the trail."
		if result.cargo_lb > result.team_capacity_lb:result.message="Ready, but above your team's load guideline. Travel will be slow."
	return result
