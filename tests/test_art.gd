extends SceneTree
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	for name in ["prairie", "river", "wagon", "oxen", "elder", "corolla", "lightsaber", "location_independence", "location_town_setup", "location_store", "location_elm_grove", "location_wakarusa", "location_kansas_river", "location_big_blue", "location_platte", "location_camp", "travel_horizon", "travel_ground", "hunt_bison", "hunt_deer", "hunt_rabbit", "hunt_cover", "hunt_hunter", "gravestone_frame", "ledger_icons"]:
		var texture: Texture2D = load("res://art/pixels/" + name + ".png")
		check(texture != null, name + " texture imports")
		var image := texture.get_image()
		var soft_alpha := false
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha := image.get_pixel(x, y).a
				# Only deliberately translucent ground shadows may have partial alpha.
				if alpha != 0.0 and alpha != 1.0 and absf(alpha - 0.4) > 0.005 and absf(alpha - 0.5333) > 0.005:
					soft_alpha = true
		check(not soft_alpha, name + " has crisp edges without antialiased alpha")
		if name in ["wagon", "oxen"]:
			var frame_width: int = 96 if name == "wagon" else 48
			check(image.get_width() == frame_width * 4, name + " has four exact frames")
			check(image.get_region(Rect2i(0, 0, frame_width, image.get_height())).get_data() != image.get_region(Rect2i(frame_width, 0, frame_width, image.get_height())).get_data(), name + " frames actually animate")
	# Hunting sheets hold two frames exactly the size of each species' hitbox.
	var species: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/hunting.json")).species
	for index in range(3):
		var sheet: Texture2D = load("res://art/pixels/hunt_" + ["bison", "deer", "rabbit"][index] + ".png")
		check(sheet.get_size() == Vector2(species[index].width * 2, species[index].height), "Hunting sprite matches its hitbox: " + species[index].id)
	check(load("res://art/pixels/hunt_cover.png").get_size() == Vector2(24, 14), "Cover sheet holds two 12 x 14 frames")
	check(load("res://art/pixels/gravestone_frame.png").get_size() == Vector2(432, 150), "Headstone fills the memorial view")
	var scenes = preload("res://ui/location_scenes.gd").new()
	check(scenes.error.is_empty(), "Scene registry loads every image")
	var route = preload("res://simulation/route_catalog.gd").new()
	var fingerprints: Dictionary = {}
	for id in scenes.textures:
		var texture: Texture2D = scenes.texture_for(id)
		var expected := Vector2(622, 273) if id in ["town_setup", "store"] else Vector2(432, 150)
		check(texture.get_size() == expected, "Scene has exact native-pixel dimensions: " + id)
		var fingerprint := texture.get_image().get_data().hex_encode().sha256_text()
		check(not fingerprints.has(fingerprint), "Location art is distinct, not another name for the same image: " + id)
		fingerprints[fingerprint] = true
	for id in route.nodes:
		check(scenes.textures.has(id), "Every route location has arrival art: " + id)
	check(scenes.texture_for("missing-scene") != null, "Unknown scene has a safe presentation fallback")
	var font: Font = load("res://art/pixels/trail_font.fnt")
	check(font.has_char(65) and font.has_char(97) and font.has_char(183), "Bitmap font covers interface and encounter text")
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "viewport", "Whole scene renders on a fixed pixel grid")
	check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer", "Presentation scales in whole-pixel multiples")
	print("Art: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
