extends RefCounted
## Presentation registry: adding artwork does not change simulation code or RNG.
const FALLBACK = preload("res://art/pixels/prairie.png")
var textures: Dictionary = {}
var encounters: Dictionary = {}
var awaiting: Array = [] # stops whose arrival picture is still being painted
var error := ""

func _init() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/location_scenes.json"))
	if not data is Dictionary or not data.get("scenes") is Dictionary:
		error = "Invalid location scene registry."
		return
	for id in data.scenes:
		var name: Variant = data.scenes[id]
		if not name is String or name.get_file() != name or not name.ends_with(".png"):
			error = "Invalid location image: " + str(id)
			textures.clear()
			return
		var path: String = "res://art/pixels/" + name
		if not ResourceLoader.exists(path):
			error = "Missing location image: " + str(id)
			textures.clear()
			return
		textures[id] = load(path)

	var visits: Variant=data.get("encounters",{})
	if not visits is Dictionary:
		error="Invalid encounter scene registry."
		return
	for site in visits:
		if not site is String or not visits[site] is String or not textures.has(visits[site]):
			error="Invalid encounter image: "+str(site)
			encounters.clear()
			return
	encounters=visits.duplicate()
	var pending: Variant=data.get("awaiting_art",[])
	if not pending is Array or not pending.all(func(id):return id is String and not textures.has(id)):
		error="Invalid awaiting-art list."
		return
	awaiting=pending.duplicate()

func encounter_for(site: String) -> String:
	return encounters.get(site,"")

func texture_for(id: String) -> Texture2D:
	return textures.get(id, FALLBACK)
