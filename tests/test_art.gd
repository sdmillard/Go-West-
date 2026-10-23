extends SceneTree
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	for name in ["prairie", "river", "wagon", "oxen", "walker", "cross_wagon", "cross_swim_ox", "cross_raft", "cross_ferryman", "cross_people", "cross_swimmer", "river_crossing", "elder", "corolla", "lightsaber", "location_independence", "location_town_setup", "location_store", "location_elm_grove", "location_wakarusa", "location_kansas_river", "location_big_blue", "location_platte", "location_camp", "travel_horizon", "travel_ground", "hunt_bison", "hunt_deer", "hunt_rabbit", "hunt_cover", "hunt_hunter", "gravestone_frame", "ledger_icons"]:
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
		if name in ["wagon", "oxen", "walker", "cross_wagon", "cross_swim_ox", "cross_ferryman", "cross_people", "cross_swimmer"]:
			var frame_width: int = {"wagon": 96, "oxen": 48, "walker": 16, "cross_wagon": 64, "cross_swim_ox": 32, "cross_ferryman": 32, "cross_people": 16, "cross_swimmer": 16}[name]
			check(image.get_width() == frame_width * 8, name + " has eight exact frames")
			check(image.get_region(Rect2i(0, 0, frame_width, image.get_height())).get_data() != image.get_region(Rect2i(frame_width, 0, frame_width, image.get_height())).get_data(), name + " frames actually animate")
	# Hunting sheets hold eight frames exactly the size of each species' hitbox, in three rows.
	var species: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/hunting.json")).species
	for index in range(3):
		var sheet: Texture2D = load("res://art/pixels/hunt_" + ["bison", "deer", "rabbit"][index] + ".png")
		check(sheet.get_size() == Vector2(species[index].width * 8, species[index].height * 3), "Hunting sprite matches its hitbox: " + species[index].id)
	check(load("res://art/pixels/hunt_cover.png").get_size() == Vector2(24, 14), "Cover sheet holds two 12 x 14 frames")
	check(load("res://art/pixels/hunt_hunter.png").get_size() == Vector2(128, 36), "Hunter sheet holds standing and walking rows of 16 x 18 frames")
	check(load("res://art/pixels/hunt_smoke.png").get_size() == Vector2(128, 16), "Rifle smoke holds eight 16 x 16 frames")
	check(load("res://art/pixels/gravestone_frame.png").get_size() == Vector2(432, 150), "Headstone fills the memorial view")
	var scenes = preload("res://ui/location_scenes.gd").new()
	# Ambient effects sit inside the pictures they decorate.
	var ambience: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/scene_ambience.json"))
	for id in ambience.scenes:
		check(scenes.textures.has(id), "Ambience names a real scene: " + id)
		for kind in ambience.scenes[id]:
			for point in ambience.scenes[id][kind]:
				check(Rect2(0, 0, 432, 150).has_point(Vector2(point[0], point[1])), "Ambient %s sits inside %s" % [kind, id])
	# Every parallax layer the travel view scrolls is a full-width tile.
	for set_name in preload("res://ui/trail_view.gd").PARALLAX:
		for layer in preload("res://ui/trail_view.gd").PARALLAX[set_name]:
			var tile: Texture2D = load("res://art/pixels/%s_%s.png" % [set_name, layer[0]])
			check(tile != null and tile.get_size() == Vector2(432, 150), "Parallax layer is a 432 x 150 tile: %s %s" % [set_name, layer[0]])
	for name in ["ambient_smoke", "ambient_flag", "ambient_bird"]:
		check(load("res://art/pixels/" + name + ".png").get_width() % 8 == 0, name + " holds eight frames")
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
