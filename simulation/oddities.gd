extends RefCounted
## Unhinged mode: each journey's seed deals its own assortment of impossible things.
## Places sit at a fixed mile on one stretch of road and are marked on the trail map;
## road encounters wait at a fixed guide mile. The same seed always deals the same set.
## Classic journeys deal nothing. Content lives in data/events.json (category "absurd").

## Places: [{"id","from","to","at"}] (at = miles into the from->to stretch).
## Road: [{"id","mile"}] (mile = guide miles travelled).
var places: Array = []
var road: Array = []

## A modest, authored benefit from the impossible laundromat, applied to spontaneous onset only.
const CLEAN_ONSET_FACTOR := 0.8
static func clean_onset_factor(state: Dictionary) -> float:
	return CLEAN_ONSET_FACTOR if state.get("mode","")=="unhinged" and int(state.get("clean_until",0))>0 and int(state.day)<=int(state.clean_until) else 1.0

## The Civet occupies one existing vehicle slot; its identity survives fuel expiry and caching.
static func civet_index(state: Dictionary) -> int:
	if state.get("mode","")!="unhinged" or state.get("vehicle","")!="wagon":return -1
	if not state.has("civet_wagon_id"):return 0 if int(state.get("fuel",0))>0 else -1 # older powered saves
	var wagons: Array=state.get("wagon_train",[{"id":0}])
	for i in range(wagons.size()):
		if int(wagons[i].id)==int(state.civet_wagon_id):return i
	return -1
static func powered_civet(state: Dictionary) -> bool:
	return civet_index(state)>=0 and int(state.get("fuel",0))>0

## Deals from the catalog with an RNG of its own, so the main game's dice are untouched.
func deal(seed_value: int, mode: String, catalog, route) -> void:
	places = []
	road = []
	if mode != "unhinged":
		return
	var dice := RandomNumberGenerator.new()
	dice.seed = hash("oddities:%d" % seed_value)
	for event in catalog.events:
		if event.category != "absurd":
			continue
		# Always draw so one entry's odds never shift another's.
		var drawn := dice.randf() < float(event.get("chance", 0.0))
		var spot := dice.randf()
		var mark := dice.randf()
		if not drawn:
			continue
		if event.get("oddity", "road") == "place":
			var stretches: Array = stretches_for(event, route)
			if stretches.is_empty():
				continue
			var total := 0
			for stretch in stretches:
				total += int(stretch.miles)
			var pick := spot * total
			for stretch in stretches:
				if pick < int(stretch.miles) or stretch == stretches[-1]:
					var length := int(stretch.miles)
					var near: Array = event.get("near", [0.25, 0.75])
					var at := clampi(int(round(length * lerpf(float(near[0]), float(near[1]), mark))), 1, maxi(1, length - 1))
					places.append({"id": event.id, "from": stretch.from, "to": stretch.to, "at": at})
					break
				pick -= int(stretch.miles)
		else:
			var window: Array = event.get("miles", [50, 1800])
			road.append({"id": event.id, "mile": int(round(lerpf(float(window[0]), float(window[1]), spot)))})

## The stretches of road a place may stand on: listed [from, to] pairs, or every main-road
## stretch between two stops ("span").
static func stretches_for(event: Dictionary, route) -> Array:
	var result: Array = []
	for pair in event.get("edges", []):
		var edge: Dictionary = route.edge_between(str(pair[0]), str(pair[1]))
		if not edge.is_empty():
			result.append({"from": str(pair[0]), "to": str(pair[1]), "miles": int(edge.miles)})
	if event.has("span"):
		var path: Array = route.main_path_to(str(event.span[1]))
		var inside := false
		for index in range(path.size() - 1):
			if path[index] == event.span[0]:
				inside = true
			if inside:
				result.append({"from": path[index], "to": path[index + 1], "miles": int(route.edge_between(path[index], path[index + 1]).miles)})
	return result

static func valid_event(event: Dictionary, route) -> String:
	if event.category != "absurd":
		return ""
	if not (event.get("chance") is float or event.get("chance") is int) or event.chance < 0 or event.chance > 1:
		return "Oddity needs a chance from 0 to 1"
	if event.get("needs", "") not in ["", "wagon"]:
		return "Unknown oddity need"
	match event.get("oddity", "road"):
		"place":
			if not event.get("label") is String or event.label.is_empty() or event.label.length() > 18:
				return "Oddity place needs a short map label"
			var near: Variant = event.get("near", [0.25, 0.75])
			if not near is Array or near.size() != 2 or not near.all(func(v): return v is int or v is float) or near[0] < 0 or near[1] > 1 or near[1] < near[0]:
				return "Oddity place 'near' must be [low, high] fractions of its stretch"
			if route != null and stretches_for(event, route).is_empty():
				return "Oddity place has no road to stand on"
		"road":
			var window: Variant = event.get("miles", [50, 1800])
			if not window is Array or window.size() != 2 or not window.all(func(v): return v is int or v is float) or window[0] < 0 or window[1] < window[0]:
				return "Oddity road window must be [low, high] miles"
		_:
			return "Oddity must be a place or a road encounter"
	return ""

## The oddity waiting right here, or {}. Westbound travel only.
func due(game) -> Dictionary:
	if game.state.mode != "unhinged" or game.Direction.heading(game) != "west":
		return {}
	for place in places:
		if place.id in game.seen:
			continue
		if game.state.landmark == place.from and game.state.next_landmark == place.to and int(game.state.leg_miles) >= int(place.at):
			return _event(game, place.id)
	for entry in road:
		if entry.id in game.seen or int(game.state.miles) < int(entry.mile):
			continue
		var event: Dictionary = _event(game, entry.id)
		if event.get("needs", "") == "wagon" and (game.state.vehicle != "wagon" or not game.raft.is_empty()):
			continue # Nothing to hitch; it waits further down the road.
		return event
	return {}

func _event(game, id: String) -> Dictionary:
	for event in game.catalog.events:
		if event.id == id:
			return event.duplicate(true)
	return {}

## Dealt places big enough to see from far off ("visible_from" stops) that stand in view now.
func in_view(game) -> Array:
	var out: Array = []
	for place in places:
		var event: Dictionary = _event(game, place.id)
		if str(game.state.landmark) in event.get("visible_from", []):
			out.append(place.id)
	return out

## A line for the day's journal now and then while something huge is in view (no dice: by day).
func daily_note(game) -> String:
	for id in in_view(game):
		var event: Dictionary = _event(game, id)
		var lines: Array = event.get("view_notes", [])
		if not lines.is_empty() and hash("%s:%d" % [id, int(game.state.day)]) % 3 == 0:
			return str(lines[hash("%d:%s" % [int(game.state.day), id]) % lines.size()])
	return ""

## Places for the trail map: [{"id","label","from","to","fraction","seen"}].
func map_marks(game) -> Array:
	var marks: Array = []
	for place in places:
		var edge: Dictionary = game.route.edge_between(place.from, place.to)
		var event: Dictionary = _event(game, place.id)
		if edge.is_empty() or event.is_empty():
			continue
		marks.append({"id": place.id, "label": str(event.label), "from": place.from, "to": place.to, "fraction": float(place.at) / maxf(1.0, float(edge.miles)), "seen": place.id in game.seen})
	return marks

## Unhinged blades found on the road sell at a post or to passing traders (traders pay three quarters).
func counter_rows(game, venue: String, kind: String) -> Array:
	var rows: Array = []
	if kind not in ["post", "traders"]:
		return rows
	for key in game.Armory.ODD_BLADES:
		if int(game.state.get(key, 0)) < 1:
			continue
		var price: int = int(game.Armory.data.blades[key].get("sell_cents", 0))
		if kind == "traders":
			price = floori(price * 0.75)
		rows.append({"item": key, "label": str(game.Armory.ODD_BLADES[key]), "amount": 1, "buy_cents": 0, "sell_cents": price, "can_buy": 0, "can_sell": 1, "held": 1, "buy_key": venue + "|buy_" + key, "sell_key": venue + "|sell_" + key, "sells": false, "buys": true})
	return rows
