extends RefCounted
## Presentation registry: adding artwork does not change simulation code or RNG.
const FALLBACK = preload("res://art/pixels/prairie.png")
var textures: Dictionary = {}
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

func texture_for(id: String) -> Texture2D:
	return textures.get(id, FALLBACK)
