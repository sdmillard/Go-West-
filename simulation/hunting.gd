extends RefCounted
## Seeded activity model; all encounter odds and yields are authored tuning.
var data: Dictionary = {}
var error := ""

func _init() -> void:
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/hunting.json")))

func load_data(value: Variant) -> bool:
	data = {}
	error = "Invalid hunting rules"
	if not value is Dictionary:
		return false
	if not value.get("wagon_noise_chance") is float or not is_finite(value.wagon_noise_chance) or value.wagon_noise_chance<0 or value.wagon_noise_chance>1:return false
	for key in ["duration", "reload_seconds", "shot_limit", "carry_limit", "carry_per_person_lb"]:
		if not value.get(key) is float and not value.get(key) is int:
			return false
		if not is_finite(float(value[key])) or value[key] <= 0:
			return false
	if value.shot_limit != int(value.shot_limit) or value.carry_limit != int(value.carry_limit):
		return false
	if value.carry_per_person_lb!=int(value.carry_per_person_lb) or value.carry_per_person_lb>value.carry_limit:return false
	if not value.get("species") is Array or value.species.size() != 3 or not value.get("regions") is Dictionary:
		return false
	var ids: Array = []
	for species in value.species:
		if not species is Dictionary or not species.get("id") is String or species.id in ids or not species.get("label") is String:
			return false
		ids.append(species.id)
		for key in ["meat", "meat_min", "meat_max", "width", "height", "speed"]:
			if not species.get(key) is float and not species.get(key) is int:
				return false
			if not is_finite(float(species[key])) or species[key] <= 0 or species[key] != int(species[key]):
				return false
		if species.meat_min > species.meat_max:
			return false
	for key in ["woodland", "plains", "highcountry", "sagebrush", "forest"]:
		var region = value.regions.get(key)
		if not region is Dictionary or not region.get("label") is String or not region.get("weights") is Array or region.weights.size() != 3:
			return false
		if not region.get("wagon_access") is bool:return false
		var total := 0
		for weight in region.weights:
			if (not weight is float and not weight is int) or weight < 0 or weight != int(weight):
				return false
			total += int(weight)
		if total < 1 or (not region.get("empty_chance") is float and not region.get("empty_chance") is int) or region.empty_chance < 0 or region.empty_chance > 1:
			return false
	data = value.duplicate(true)
	error = ""
	return true
var rng := RandomNumberGenerator.new()

func begin(seed_value: int, outing: int, miles: int, habitat: String = "", wagon: bool = false) -> Dictionary:
	rng.seed = seed_value + 719 * outing + 98471
	var region := habitat if data.regions.has(habitat) else ("woodland" if miles < 81 else "plains")
	var rules: Dictionary = data.regions[region]
	var animals: Array = []
	var count := 0 if rng.randf() < rules.empty_chance else rng.randi_range(1, 3)
	for index in range(count):
		var total := 0
		for weight in rules.weights:
			total += int(weight)
		var roll := rng.randi_range(1, total)
		var kind := 0
		for weight in rules.weights:
			roll -= int(weight)
			if roll <= 0:
				break
			kind += 1
		var species: Dictionary = data.species[kind]
		animals.append({"kind": kind, "x": rng.randf_range(45, 330), "y": 96 + index * 10,
			"direction": -1 if rng.randf() < 0.5 else 1, "escaped": false,
			"meat": rng.randi_range(int(species.meat_min), int(species.meat_max))})
	# Noise rolls are separate, preserving on-foot seeds and shot mechanics.
	if wagon:
		var noise:=RandomNumberGenerator.new()
		noise.seed=seed_value+719*outing+801737
		animals=animals.filter(func(_animal):return noise.randf()>=float(data.wagon_noise_chance))
		count=animals.size()
	var cover: Array = []
	for index in range(4):
		cover.append(Rect2(rng.randi_range(40, 385), rng.randi_range(101, 126), 12, 14))
	return {"shots": 0, "meat": 0, "targets": [], "animals": animals, "cover": cover,
		"region": region, "region_label": rules.label, "wagon": wagon, "elapsed": 0.0, "reload": 0.0,
		"ended": false, "hunter": Vector2(216, 140), "destination": Vector2(216, 140),
		"message": "No game in sight. Return to camp." if count == 0 else "Watch for a clear shot.",
		"flash": 0.0, "aim": Vector2.ZERO}

func bounds(hunt: Dictionary, index: int) -> Rect2:
	var animal: Dictionary = hunt.animals[index]
	var species: Dictionary = data.species[animal.kind]
	return Rect2(roundf(animal.x), animal.y, species.width, species.height)

func tick(hunt: Dictionary, delta: float) -> void:
	if hunt.ended:
		return
	var step := clampf(delta, 0, float(data.duration) - float(hunt.elapsed))
	hunt.elapsed += step
	hunt.reload = maxf(0, hunt.reload - step)
	hunt.flash = maxf(0, hunt.flash - step)
	var next: Vector2 = hunt.hunter.move_toward(hunt.destination, 55 * step)
	var blocked := false
	for obstacle in hunt.cover:
		if blocks(obstacle.grow(3), hunt.hunter, next):
			blocked = true
	if not blocked:
		hunt.hunter = next
	var remaining := 0
	for index in range(hunt.animals.size()):
		var animal: Dictionary = hunt.animals[index]
		if index in hunt.targets or animal.escaped:
			continue
		var speed: float = data.species[animal.kind].speed * (2.2 if hunt.shots > 0 else 1.0)
		animal.x += animal.direction * speed * step
		if animal.x < -45 or animal.x > 432:
			animal.escaped = true
		else:
			remaining += 1
	if hunt.elapsed >= data.duration or remaining == 0:
		hunt.ended = true
		hunt.message = "No more game in sight. Return to camp."

func target_at(hunt: Dictionary, point: Vector2) -> int:
	for obstacle in hunt.cover:
		if blocks(obstacle, hunt.hunter, point):
			return -1
	for index in range(hunt.animals.size() - 1, -1, -1):
		if index not in hunt.targets and not hunt.animals[index].escaped and bounds(hunt, index).has_point(point):
			return index
	return -1

func blocks(rect: Rect2, origin: Vector2, end: Vector2) -> bool:
	if rect.has_point(origin) or rect.has_point(end):
		return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in range(4):
		if Geometry2D.segment_intersects_segment(origin, end, corners[index], corners[(index + 1) % 4]) != null:
			return true
	return false
