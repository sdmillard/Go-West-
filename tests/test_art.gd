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
	# Sprite headroom is visual padding; the physical shot targets keep their original size.
	var species: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/hunting.json")).species
	for index in range(3):
		var sheet: Texture2D = load("res://art/pixels/hunt_" + ["bison", "deer", "rabbit"][index] + ".png")
		check(sheet.get_size() == Vector2(species[index].width * 8, (species[index].height+[0,7,3][index])*3), "Hunting sprite has complete padded animation cells: " + species[index].id)
	# A clear top border in every deer frame protects antlers through the whole jump.
	var deer: Image=load("res://art/pixels/hunt_deer.png").get_image()
	for gait in range(3):
		for frame in range(8):
			for x in range(27):
				check(deer.get_pixel(frame*27+x,gait*29).a==0,"Antlers stay inside their animation cell")
	check(load("res://art/pixels/hunt_cover.png").get_size() == Vector2(24, 14), "Cover sheet holds two 12 x 14 frames")
	check(load("res://art/pixels/hunt_hunter.png").get_size() == Vector2(128, 36), "Hunter sheet holds standing and walking rows of 16 x 18 frames")
	check(load("res://art/pixels/hunt_smoke.png").get_size() == Vector2(128, 16), "Rifle smoke holds eight 16 x 16 frames")
	check(load("res://art/pixels/gravestone_frame.png").get_size() == Vector2(432, 150), "Headstone fills the memorial view")
	check(load("res://art/pixels/trail_map.png").get_size() == Vector2(616, 288), "Trail map fills the map screen")
	# Weather and event overlays keep the frame layouts ui/trail_view.gd slices them by.
	for sheet in [["storm_clouds", 432, 56], ["weather_bolt", 96, 96], ["dust_devil", 64, 40], ["trail_dust", 48, 12], ["stampede_ox", 104, 16], ["flotsam", 48, 12], ["rain_clouds", 432, 56], ["rain_splash", 32, 4], ["fog_bank", 432, 40], ["snow_squall", 432, 150], ["cross_ripple", 48, 6], ["cloud_shadow", 256, 64], ["mist_wisp", 256, 48]]:
		check(load("res://art/pixels/%s.png" % sheet[0]).get_size() == Vector2(sheet[1], sheet[2]), "Overlay sheet keeps its layout: " + sheet[0])
	# Horse travel sheets (not wired yet) keep the frame grids the design names: 48x44 travel frames,
	# 48x40 crossing frames, 16x16 store icons.
	for sheet in [["horses", 384, 308], ["cross_horses", 384, 320], ["horse_icons", 80, 16], ["weapon_icons", 96, 16]]:
		check(load("res://art/pixels/%s.png" % sheet[0]).get_size() == Vector2(sheet[1], sheet[2]), "Horse sheet keeps its layout: " + sheet[0])
	# Approved Cascades pack: exact runtime slicing and hard pixel edges.
	for asset in [["rafting_obstacles",128,96,32,32],["rafting_foam",128,16,32,16],["rafting_raft",72,48,72,48]]:
		var image: Image=load("res://art/pixels/%s.png" % asset[0]).get_image()
		check(image.get_size()==Vector2i(asset[1],asset[2]),"Rafting art keeps its cell layout: "+asset[0])
		var crisp:=true
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha:=image.get_pixel(x,y).a
				if alpha!=0 and alpha!=1:crisp=false
		check(crisp,"Rafting art has binary alpha: "+asset[0])
		for row in range(int(asset[2])/int(asset[4])):
			var frames: Dictionary={}
			for frame in range(int(asset[1])/int(asset[3])):
				var cell:=image.get_region(Rect2i(frame*asset[3],row*asset[4],asset[3],asset[4]))
				check(not cell.is_invisible(),"Rafting cell is populated: %s/%d/%d" % [asset[0],row,frame])
				frames[cell.get_data().hex_encode()]=true
			if asset[0]!="rafting_raft":check(frames.size()>=3,"Rafting water/debris frames visibly animate: %s/%d" % [asset[0],row])
	# Isometric tactical combat Aseprite sheets: exact 32x32 cell layouts and binary alpha.
	for asset in [["tactical_tiles",192,32,32,32],["tactical_cover",192,96,32,32],["tactical_units",192,96,32,32],["tactical_arms",192,448,32,32]]:
		var image: Image=load("res://art/pixels/%s.png" % asset[0]).get_image()
		check(image.get_size()==Vector2i(asset[1],asset[2]),"Tactical combat art keeps its cell layout: "+asset[0])
		var crisp:=true
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha:=image.get_pixel(x,y).a
				if alpha!=0 and alpha!=1:crisp=false
		check(crisp,"Tactical combat art has binary alpha: "+asset[0])
		for row in range(int(asset[2])/int(asset[4])):
			for frame in range(int(asset[1])/int(asset[3])):
				var cell:=image.get_region(Rect2i(frame*asset[3],row*asset[4],asset[3],asset[4]))
				check(not cell.is_invisible(),"Tactical combat cell is populated: %s/%d/%d" % [asset[0],row,frame])
	# Approved farm-shepherd asset: idle, walking and sitting, eight 48x44 cells each.
	var dog: Image = load("res://art/pixels/dog.png").get_image()
	check(dog.get_size() == Vector2i(384,132), "Dog keeps the three-row animation layout")
	var dog_crisp := true
	for y in range(dog.get_height()):
		for x in range(dog.get_width()):
			var alpha := dog.get_pixel(x,y).a
			if alpha != 0.0 and alpha != 1.0: dog_crisp = false
	check(dog_crisp,"Dog has binary alpha for nearest-neighbor drawing")
	for row in range(3):
		var distinct: Dictionary = {}
		for frame in range(8):
			var cell := dog.get_region(Rect2i(frame*48,row*44,48,44))
			distinct[cell.get_data().hex_encode()] = true
			check(not cell.is_invisible(),"Dog animation cell is populated")
			var bounds := cell.get_used_rect()
			check(bounds.position.x > 0 and bounds.end.x < 48 and bounds.position.y > 0 and bounds.end.y <= 40,"Dog stays inside its cell and ground baseline")
		check(distinct.size() >= (6 if row == 1 else 2),"Dog poses animate with distinct frames")
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
		var expected := Vector2(622, 273) if id in ["town_setup", "store", "post_store", "trader_camp", "camp_trade"] else Vector2(432, 150)
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
	check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "fractional", "Presentation follows window resizing continuously; crisp integer scaling is optional")
	print("Art: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
