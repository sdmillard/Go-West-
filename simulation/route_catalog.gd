extends RefCounted
## Explicit directed route edges; this chapter is a single researched corridor.
var nodes: Dictionary = {}
var start := ""
var error := ""
var total_miles := 0
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
		if node.get("terrain", "plains") not in ["plains","mountains","desert","forest"] or node.get("hunting_region","plains") not in ["woodland","plains","highcountry","sagebrush","forest"]:
			return _fail("Invalid regional terrain.")
		if node.get("river_source","rain") not in ["rain","snowmelt"]:
			return _fail("Invalid river source.")
		for key in ["trade_bulk","descent"]:
			if node.has(key) and not node[key] is bool:
				return _fail("Invalid landmark activity flag.")
		for key in ["toll_dollars","toll_per_ox","bulk_food_cents"]:
			if node.has(key) and (not (node[key] is int or node[key] is float) or not is_finite(float(node[key])) or node[key] < 0):
				return _fail("Invalid landmark price.")
		candidate[node.id] = node.duplicate(true)
	if not candidate.has(data.start):
		return _fail("Route start does not exist.")
	# Validate the currently supported single corridor; reject branches until UI supports them.
	var current: String = data.start
	var visited: Array = []
	var distance := 0
	while current not in visited:
		visited.append(current)
		var node: Dictionary = candidate[current]
		if node.kind in ["chapter_end", "destination"]:
			if not node.next.is_empty() or visited.size() != candidate.size():
				return _fail("Chapter must end after all connected landmarks.")
			nodes = candidate
			start = data.start
			end_id = current
			total_miles = distance
			return true
		if node.next.size() != 1:
			return _fail("This chapter needs exactly one outgoing road.")
		var edge: Variant = node.next[0]
		if not edge is Dictionary or not candidate.has(edge.get("to")) or not (edge.get("miles") is int or edge.get("miles") is float):
			return _fail("Invalid road destination or distance.")
		if not is_finite(float(edge.miles)) or edge.miles <= 0 or edge.miles != floor(edge.miles):
			return _fail("Road distance must be positive whole miles.")
		distance += int(edge.miles)
		current = edge.to
	return _fail("Route contains a cycle.")

func truncate_at(id: String) -> bool:
	# Explicit opening-chapter regression fixture; normal play loads the full corridor.
	if not nodes.has(id):
		return false
	var selected: Dictionary = {}
	var current := start
	var distance := 0
	while true:
		selected[current] = nodes[current].duplicate(true)
		if current == id:
			if selected[current].kind != "destination":
				selected[current].kind = "chapter_end"
			selected[current].next = []
			nodes = selected
			total_miles = distance
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
