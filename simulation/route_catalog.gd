extends RefCounted
## Explicit directed route edges: one researched main road (each stop's first
## edge) plus historical alternatives that fork at a stop and rejoin later.
var nodes: Dictionary = {}
var start := ""
var error := ""
var total_miles := 0
var longest_miles := 0
var end_id := ""

func _init() -> void:
	if not FileAccess.file_exists("res://data/route.json"):
		error = "Missing route data."
		return
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json")))

func load_data(data: Variant) -> bool:
	nodes = {}
	total_miles = 0
	error = ""
	start = ""
	if not data is Dictionary or not data.get("start") is String or not data.get("nodes") is Array:
		return _fail("Invalid route data.")
	var candidate := {}
	for node in data.nodes:
		if not node is Dictionary:
			return _fail("Invalid landmark.")
		for field in ["id", "name", "kind", "text"]:
			if not node.get(field) is String or node[field].is_empty():
				return _fail("Landmark is missing " + field + ".")
		if candidate.has(node.id) or not node.get("next") is Array or node.kind not in ["town", "camp", "fort", "river", "chapter_end", "destination"]:
			return _fail("Duplicate or invalid landmark.")
		if node.has("ferry_dollars"):
			if not (node.ferry_dollars is int or node.ferry_dollars is float) or not is_finite(float(node.ferry_dollars)) or node.ferry_dollars < 0:
				return _fail("Invalid ferry fare.")
		if node.has("ferry_high_dollars") and (not node.has("ferry_dollars") or not (node.ferry_high_dollars is int or node.ferry_high_dollars is float) or not is_finite(float(node.ferry_high_dollars)) or node.ferry_high_dollars < node.ferry_dollars):
			return _fail("Invalid high-water ferry fare.")
		if node.get("terrain", "plains") not in ["plains","mountains","desert","forest"] or node.get("hunting_region","plains") not in ["woodland","plains","highcountry","sagebrush","forest"]:
			return _fail("Invalid regional terrain.")
		if node.get("river_source","rain") not in ["rain","snowmelt"]:
			return _fail("Invalid river source.")
		for key in ["trade_bulk","descent","portage"]:
			if node.has(key) and not node[key] is bool:
				return _fail("Invalid landmark activity flag.")
		if node.has("snow_country"):
			var snow: Variant=node.snow_country
			if not snow is Dictionary or not snow.get("months") is Array or snow.months.is_empty() or not snow.months.all(func(m):return (m is int or m is float) and m==floor(m) and m>=1 and m<=12):
				return _fail("Invalid snow country months.")
			for key in ["snowbound_chance","death_chance"]:
				if not (snow.get(key) is int or snow.get(key) is float) or snow[key]<0 or snow[key]>1:return _fail("Invalid snow country chance.")
			if not (snow.get("animal_strain") is int or snow.get("animal_strain") is float) or snow.animal_strain<0 or snow.animal_strain>100 or snow.animal_strain!=floor(snow.animal_strain):return _fail("Invalid snow country strain.")
			if not (snow.get("valley_strain") is int or snow.get("valley_strain") is float) or snow.valley_strain<0 or snow.valley_strain>snow.animal_strain or snow.valley_strain!=floor(snow.valley_strain):return _fail("Invalid snow country valley strain.")
		if node.has("river_winter"):
			var river: Variant=node.river_winter
			var month_list:=func(value):return value is Array and not value.is_empty() and value.all(func(m):return (m is int or m is float) and m==floor(m) and m>=1 and m<=12)
			if not river is Dictionary or river.size()!=8 or not river.get("note") is String or not month_list.call(river.get("months")) or not month_list.call(river.get("frozen_months")) or not river.frozen_months.all(func(m):return m in river.months):return _fail("Invalid river winter months.")
			for key in ["windbound_chance","hard_winter_chance","ice_bound_chance"]:
				if not (river.get(key) is int or river.get(key) is float) or river[key]<0 or river[key]>1:return _fail("Invalid river winter chance.")
			if not (river.get("chill_damage") is int or river.get("chill_damage") is float) or river.chill_damage<0 or river.chill_damage>20 or river.chill_damage!=floor(river.chill_damage):return _fail("Invalid river winter chill.")
			if not (river.get("wreck_drowning_factor") is int or river.get("wreck_drowning_factor") is float) or river.wreck_drowning_factor<1 or river.wreck_drowning_factor>5:return _fail("Invalid river winter drowning factor.")
		if node.has("wagon_closed_months") and (not node.wagon_closed_months is Array or node.wagon_closed_months.is_empty() or not node.wagon_closed_months.all(func(m):return (m is int or m is float) and m==floor(m) and m>=1 and m<=12)):
			return _fail("Invalid seasonal road closure.")
		for key in ["toll_dollars","toll_per_ox","bulk_food_cents"]:
			if node.has(key) and (not (node[key] is int or node[key] is float) or not is_finite(float(node[key])) or node[key] < 0):
				return _fail("Invalid landmark price.")
		candidate[node.id] = node.duplicate(true)
	if not candidate.has(data.start):
		return _fail("Route start does not exist.")
	# Every landmark is reachable, every road ends at one destination, and
	# forks happen only at stops (never mid-crossing). next[0] is the main road.
	var ends: Array = []
	for id in candidate:
		var node: Dictionary = candidate[id]
		if node.kind in ["chapter_end", "destination"]:
			if not node.next.is_empty():
				return _fail("Chapter must end after all connected landmarks.")
			ends.append(id)
			continue
		if node.next.is_empty():
			return _fail("Chapter must end after all connected landmarks.")
		if node.kind == "river" and node.next.size() != 1:
			return _fail("This chapter needs exactly one outgoing road from a crossing.")
		var targets: Array = []
		for edge in node.next:
			if not edge is Dictionary or not candidate.has(edge.get("to")) or not (edge.get("miles") is int or edge.get("miles") is float):
				return _fail("Invalid road destination or distance.")
			if not is_finite(float(edge.miles)) or edge.miles <= 0 or edge.miles != floor(edge.miles):
				return _fail("Road distance must be positive whole miles.")
			if edge.to in targets or (edge.has("label") and (not edge.label is String or edge.label.is_empty())) or edge.get("hazard", "") not in ["", "waterless", "river", "unrest"]:
				return _fail("Invalid road choice.")
			if edge.has("effects") and (not edge.effects is Dictionary or edge.effects.keys() != ["days"] or not (edge.effects.days is int or edge.effects.days is float) or edge.effects.days != floor(edge.effects.days) or edge.effects.days < 1 or edge.effects.days > 5):
				return _fail("Invalid road choice.")
			targets.append(edge.to)
	if ends.size() != 1:
		return _fail("Chapter must end after all connected landmarks.")
	var state := {}
	if _has_cycle(candidate, data.start, state):
		return _fail("Route contains a cycle.")
	if state.size() != candidate.size():
		return _fail("Chapter must end after all connected landmarks.")
	nodes = candidate
	start = data.start
	end_id = ends[0]
	total_miles = remaining(start)
	longest_miles = _longest(start, {})
	return true

func _has_cycle(candidate: Dictionary, id: String, state: Dictionary) -> bool:
	state[id] = 1
	for edge in candidate[id].next:
		if state.get(edge.to, 0) == 1:
			return true
		if not state.has(edge.to) and _has_cycle(candidate, edge.to, state):
			return true
	state[id] = 2
	return false

func _longest(id: String, memo: Dictionary) -> int:
	if not memo.has(id):
		var best := 0
		for edge in nodes[id].next:
			best = maxi(best, int(edge.miles) + _longest(edge.to, memo))
		memo[id] = best
	return int(memo[id])

## Guide miles from a stop to the end along the main road (each node's first edge).
func remaining(id: String) -> int:
	var distance := 0
	while not nodes[id].next.is_empty():
		distance += int(nodes[id].next[0].miles)
		id = nodes[id].next[0].to
	return distance

func edge_between(from: String, to: String) -> Dictionary:
	if nodes.has(from):
		for edge in nodes[from].next:
			if edge.to == to:
				return edge
	return {}

## The main-road stops from the start up to and including id; empty if id is off it.
func main_path_to(id: String) -> Array:
	var path: Array = [start]
	while path[-1] != id:
		if nodes[path[-1]].next.is_empty():
			return []
		path.append(nodes[path[-1]].next[0].to)
	return path

func valid_path(path: Variant) -> bool:
	if not path is Array or path.is_empty() or path[0] != start:
		return false
	for index in range(1, path.size()):
		if not path[index] is String or edge_between(path[index - 1], path[index]).is_empty():
			return false
	return true

## Guide miles from the start to every stop, the main road first; a branch stop
## takes the distance along its branch.
func node_miles() -> Dictionary:
	var result := {}
	_walk_miles(start, 0, result)
	return result

func _walk_miles(id: String, distance: int, result: Dictionary) -> void:
	if result.has(id):
		return
	result[id] = distance
	for edge in nodes[id].next:
		_walk_miles(edge.to, distance + int(edge.miles), result)

func truncate_at(id: String) -> bool:
	# Explicit opening-chapter regression fixture; normal play loads the full corridor.
	if not nodes.has(id):
		return false
	if id == end_id:
		return true
	var selected: Dictionary = {}
	var current := start
	var distance := 0
	while true:
		selected[current] = nodes[current].duplicate(true)
		if current == id:
			if selected[current].kind != "destination":
				selected[current].kind = "chapter_end"
			selected[current].next = []
			for kept in selected:
				selected[kept].next = selected[kept].next.filter(func(edge): return selected.has(edge.to))
			nodes = selected
			total_miles = distance
			longest_miles = distance
			end_id = id
			return true
		if nodes[current].next.is_empty():
			return false
		distance += int(nodes[current].next[0].miles)
		current = nodes[current].next[0].to
	return false

func _fail(message: String) -> bool:
	error = message
	return false
