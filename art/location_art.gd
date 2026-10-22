extends RefCounted
## Original interpretations; dated visual sources and limits live in LOCATION_REFERENCES.md.
var p
var random := RandomNumberGenerator.new()

func build(canvas) -> void:
	p = canvas
	town(false)
	town(true)
	store()
	grove()
	for place in ["wakarusa", "kansas_river", "big_blue", "platte"]:
		river(place)
	camp()
	travel_layers()

func line(x: int, y: int, end_x: int, end_y: int, color: String, width: int = 1) -> void:
	var steps := maxi(absi(end_x - x), absi(end_y - y))
	for i in range(steps + 1):
		var t := float(i) / maxi(1, steps)
		p.rect(roundi(lerpf(x, end_x, t)), roundi(lerpf(y, end_y, t)), width, width, color)

func finish(name: String) -> void:
	# Small clustered marks supply grain, pebbles, leaves and ripples on the native grid.
	random.seed = name.hash()
	var shades := {"grass": ["sage", "leaf"], "sage": ["grass", "gold"],
		"sand": ["cream", "ochre"], "ochre": ["gold", "rust"], "rust": ["wood", "ochre"],
		"wood": ["rust", "deep"], "pine": ["leaf", "pine"], "leaf": ["grass", "pine"],
		"water": ["sky", "foam"], "927e62": ["sand", "wood"]}
	for i in range(2100 * p.image.get_width() * p.image.get_height() / 64800):
		var x := random.randi_range(0, p.image.get_width() - 1)
		var y := random.randi_range(0, p.image.get_height() - 1)
		var pixel: Color = p.image.get_pixel(x, y)
		for base in shades:
			if pixel == p.c(base):
				var color: String = shades[base][i % 2]
				for offset in range(1 + i % 3):
					if x + offset < p.image.get_width() and p.image.get_pixel(x + offset, y) == pixel:
						p.dot(x + offset, y, color)
				break
	p.save_asset(name)

func sky(w: int = 432, h: int = 150) -> void:
	p.fresh(w, h)
	p.rect(0, 0, w, h, "sky")
	p.rect(0, 35, w, 35, "light_blue")
	p.cloud(43, 17, 67)
	p.cloud(w - 128, 12, 83)
	p.rect(0, 68, w, h - 68, "sage")
	for i in range(500):
		p.dot(random.randi_range(0, w - 1), random.randi_range(80, h - 1), "grass" if i % 2 else "gold")

func tree(x: int, y: int, scale: int = 1) -> void:
	p.rect(x, y - 28 * scale, 4 * scale, 29 * scale, "deep")
	line(x, y - 10 * scale, x - 12 * scale, y - 32 * scale, "wood", scale + 1)
	line(x + 2 * scale, y - 16 * scale, x + 17 * scale, y - 38 * scale, "wood", scale + 1)
	for crown in [[-13, -33, 15, 10], [10, -38, 20, 12], [0, -46, 17, 13]]:
		p.ellipse(x + crown[0] * scale, y + crown[1] * scale, crown[2] * scale, crown[3] * scale, "pine")
		p.ellipse(x + crown[0] * scale - 2, y + crown[1] * scale - 3, maxi(1, (crown[2] - 3) * scale), maxi(1, (crown[3] - 3) * scale), "leaf")
		p.rect(x + (crown[0] - 7) * scale, y + (crown[1] - 6) * scale, 10 * scale, 2 * scale, "grass")

func small_wagon(x: int, y: int) -> void:
	p.ellipse(x + 9, y + 15, 6, 6, "deep")
	p.ellipse(x + 33, y + 15, 6, 6, "deep")
	for wx in [x + 9, x + 33]:
		p.ellipse(wx, y + 15, 4, 4, "ochre")
		line(wx - 4, y + 15, wx + 4, y + 15, "wood")
		line(wx, y + 11, wx, y + 19, "wood")
	p.rect(x, y + 4, 43, 9, "wood")
	p.polygon([[x + 2, y + 4], [x + 3, y - 10], [x + 8, y - 17], [x + 30, y - 17], [x + 37, y - 10], [x + 39, y + 5]], "cream")
	for offset in [7, 17, 28]:
		line(x + offset, y - 14, x + offset + 2, y + 3, "sand")
	p.rect(x + 36, y - 6, 4, 10, "deep")
	p.rect(x + 3, y + 7, 37, 1, "ochre")

func person(x: int, y: int, coat: String = "wood") -> void:
	p.rect(x, y - 16, 5, 5, "sand")
	p.rect(x - 2, y - 17, 9, 2, "deep")
	p.rect(x, y - 11, 6, 8, coat)
	p.rect(x, y - 3, 2, 5, "deep")
	p.rect(x + 4, y - 3, 2, 5, "deep")

func building(x: int, y: int, w: int, h: int, brick: bool = false) -> void:
	p.rect(x, y, w, h, "rust" if brick else "sand")
	p.polygon([[x - 6, y], [x + 8, y - 17], [x + w - 8, y - 17], [x + w + 6, y]], "deep")
	for yy in range(y + 4, y + h, 5):
		p.rect(x + 1, yy, w - 2, 1, "wood" if brick else "ochre")
	p.rect(x + w / 2 - 5, y + h - 21, 10, 21, "deep")
	var rows: Array = [y + 7] if h < 45 else [y + 7, y + h - 20]
	for xx in range(x + 7, x + w - 7, 17):
		for yy in rows:
			# Reserve the whole doorway and its trim on the lower floor.
			if yy + 10 > y + h - 22 and xx < x + w / 2 + 8 and xx + 7 > x + w / 2 - 8:
				continue
			p.rect(xx, yy, 7, 10, "deep")
			p.rect(xx + 1, yy + 1, 5, 7, "light_blue")
			p.rect(xx + 3, yy + 1, 1, 8, "cream")
			p.rect(xx + 1, yy + 4, 5, 1, "cream")
	p.rect(x + w / 2 - 6, y + h - 22, 12, 22, "sand")
	p.rect(x + w / 2 - 5, y + h - 21, 10, 21, "deep")

func town(setup: bool) -> void:
	random.seed = 110
	var w := 622 if setup else 432
	var h := 273 if setup else 150
	sky(w, h)
	var ground := 173 if setup else 114
	p.rect(0, ground, w, h - ground, "ochre")
	var center := 435 if setup else 254
	building(center - 36, ground - 67, 77, 59, true)
	# Restrained courthouse cupola silhouette from the later engraving, not the 1933 building.
	p.rect(center - 6, ground - 87, 15, 18, "sand")
	p.polygon([[center - 9, ground - 87], [center + 1, ground - 100], [center + 12, ground - 87]], "deep")
	line(center + 1, ground - 107, center + 1, ground - 99, "deep")
	building(center - 133, ground - 39, 63, 35)
	building(center + 87, ground - 46, 53, 41)
	for x in range(center - 160, w, 12):
		p.rect(x, ground - 7, 2, 12, "cream")
	p.rect(maxi(0, center - 160), ground - 4, w, 1, "cream")
	p.rect(maxi(0, center - 160), ground + 1, w, 1, "wood")
	for i in range(200):
		p.rect(random.randi_range(0, w - 1), random.randi_range(ground + 12, h - 1), 3, 1, "gold" if i % 2 else "rust")
	small_wagon(center - 110, ground + 26)
	small_wagon(center + 39, ground + 37)
	person(center - 36, ground + 31, "blue")
	person(center + 110, ground + 49)
	finish("location_town_setup" if setup else "location_independence")

func barrel(x: int, y: int, w: int = 22, h: int = 32) -> void:
	p.rect(x + 2, y, w - 4, h, "ochre")
	p.ellipse(x + w / 2, y + h / 2, w / 2, h / 2, "wood")
	for xx in range(x + 4, x + w - 2, 4):
		p.rect(xx, y + 3, 1, h - 5, "rust")
	p.ellipse(x + w / 2, y + 2, w / 2 - 1, 3, "sand")
	p.rect(x, y + 8, w, 2, "deep")
	p.rect(x, y + h - 8, w, 2, "deep")

func store() -> void:
	p.fresh(622, 273)
	p.rect(0, 0, 622, 273, "wood")
	p.rect(8, 8, 606, 180, "rust")
	for x in range(10, 622, 14):
		p.rect(x, 8, 1, 180, "ochre")
	p.rect(0, 190, 622, 83, "ochre")
	for x in range(-100, 700, 27):
		line(x + 50, 191, x, 272, "wood")
	for y in [210, 240, 269]:
		p.rect(0, y, 622, 1, "rust")
	# Stock and counter composition informed by the Asa Knight museum interior.
	p.rect(26, 29, 226, 117, "deep")
	for y in [34, 61, 88, 115]:
		for x in range(33, 243, 18):
			var shade: String = ["cream", "sand", "blue", "pine"][int(x / 18 + y) % 4]
			if y == 88:
				p.rect(x, y + 9, 14, 4, shade)
				p.rect(x + 2, y + 4, 12, 4, "gold")
			elif y == 61:
				p.ellipse(x + 5, y + 10, 6, 4, shade)
				p.rect(x, y + 8, 12, 2, "cream")
			else:
				p.rect(x + 3, y + 3, 5, 13, shade)
				p.rect(x + 4, y, 3, 5, shade)
		p.rect(26, y + 18, 226, 4, "wood")
		p.rect(27, y + 18, 224, 1, "gold")
	for x in [26, 100, 174, 248]:
		p.rect(x, 28, 4, 117, "wood")
	# Counter and barrels; a fictional attendant, not a copied museum visitor.
	p.ellipse(186, 134, 6, 8, "cream")
	p.rect(184, 131, 6, 8, "sand")
	p.rect(180, 142, 13, 13, "blue")
	line(181, 145, 168, 150, "sand", 2)
	p.rect(16, 151, 246, 8, "gold")
	p.rect(18, 159, 242, 31, "deep")
	p.rect(20, 159, 238, 3, "wood")
	for x in [24, 65, 107, 215]:
		barrel(x, 183, 28, 37)
	p.rect(137, 145, 23, 5, "cream")
	p.rect(139, 147, 19, 1, "blue")
	# Hanging baskets and a plain wooden beam, without a later cash register.
	p.rect(0, 16, 622, 7, "deep")
	for x in [48, 115, 224]:
		line(x, 21, x, 31, "sand")
		p.ellipse(x, 33, 11, 6, "ochre")
		p.rect(x - 8, 30, 16, 2, "sand")
	finish("location_store")

func grove() -> void:
	random.seed = 145
	sky()
	p.polygon([[0, 122], [432, 112], [432, 150], [0, 150]], "ochre")
	tree(82, 114, 2)
	tree(332, 96)
	p.polygon([[149, 122], [173, 90], [198, 123]], "cream")
	p.polygon([[173, 90], [179, 123], [198, 123]], "sand")
	p.polygon([[171, 111], [171, 122], [178, 123]], "deep")
	small_wagon(252, 120)
	person(218, 124)
	p.rect(0, 143, 432, 7, "leaf")
	finish("location_elm_grove")

func river(place: String) -> void:
	random.seed = 240 + place.length()
	sky()
	if place == "wakarusa":
		# Creek enclosed by wooded, layered limestone banks, rather than open prairie.
		p.rect(0, 63, 432, 87, "leaf")
		p.polygon([[112, 66], [215, 70], [269, 96], [290, 150], [97, 150], [173, 100]], "water")
		for y in range(77, 150, 9):
			var offset := (y - 77) / 3
			var edge := 106 + offset + random.randi_range(-7, 9)
			p.polygon([[0, y], [edge - 8, y], [edge + 3, y + 4], [edge - 3, y + 8], [0, y + 8]], "sand")
			p.rect(1, y + 6, edge - 5, 2, "wood")
			var bank := 287 - offset / 2 + random.randi_range(-5, 6)
			p.polygon([[bank, y], [432, y], [432, y + 8], [bank - 7, y + 8], [bank + 3, y + 3]], "ochre")
			p.rect(bank + 1, y + 6, 145, 2, "sand")
		tree(31, 93, 2)
		tree(369, 91, 2)
		for x in [93, 143, 262, 310]:
			tree(x, 73)
		line(121, 89, 152, 126, "cream")
	elif place == "kansas_river":
		p.rect(0, 76, 432, 74, "927e62")
		p.rect(0, 71, 432, 7, "leaf")
		p.polygon([[0, 102], [42, 114], [106, 150], [0, 150]], "sand")
		for i in range(90):
			p.rect(random.randi_range(90, 425), random.randi_range(81, 149), 6, 1, "sand" if i % 3 == 0 else "wood")
		# Plank platform over dugout-like hulls described in the NPS account.
		for y in [116, 124]:
			p.ellipse(229, y, 46, 4, "deep")
			p.ellipse(229, y - 1, 42, 2, "wood")
		p.rect(189, 108, 80, 15, "ochre")
		for x in range(191, 270, 8):
			p.rect(x, 108, 1, 14, "sand")
		small_wagon(204, 102)
		person(252, 109)
		line(184, 111, 146, 81, "sand")
		tree(20, 114)
	elif place == "big_blue":
		p.polygon([[0, 77], [432, 86], [432, 132], [0, 118]], "blue")
		p.polygon([[0, 113], [90, 118], [220, 136], [432, 120], [432, 150], [0, 150]], "sand")
		for x in range(110, 315, 7):
			var y := 113 - (x - 110) / 10
			p.ellipse(x, y, 3, 1, "ochre")
		for x in [18, 60, 350, 402]:
			tree(x, 89)
		small_wagon(50, 130)
		person(121, 132)
	else:
		# Broad, shallow braided Platte; no mountains or later military buildings.
		p.rect(0, 75, 432, 75, "sand")
		for shape in [ [[0, 83], [432, 76], [432, 86], [0, 104]], [[0, 123], [170, 94], [432, 109], [432, 120], [170, 106], [0, 137]] ]:
			p.polygon(shape, "water")
		p.polygon([[168, 83], [254, 87], [308, 97], [220, 100], [142, 95]], "sage")
		for x in [180, 213, 242]:
			tree(x, 92)
		p.rect(0, 139, 432, 11, "grass")
		small_wagon(337, 133)
	finish("location_" + place)

func camp() -> void:
	random.seed = 401
	sky()
	p.rect(0, 0, 432, 43, "blue")
	p.rect(0, 43, 432, 25, "rust")
	p.rect(0, 68, 432, 82, "leaf")
	p.cloud(33, 34, 58)
	p.cloud(310, 40, 82)
	p.rect(0, 65, 432, 4, "gold")
	p.polygon([[0, 79], [52, 73], [95, 78], [162, 72], [224, 79], [293, 72], [361, 77], [432, 71], [432, 95], [0, 95]], "pine")
	small_wagon(121, 111)
	p.polygon([[236, 125], [264, 88], [296, 125]], "sand")
	p.polygon([[264, 88], [269, 125], [296, 125]], "ochre")
	p.ellipse(213, 133, 26, 5, "wood")
	for x in [201, 209, 217, 225]:
		p.ellipse(x, 133, 4, 2, "sand")
	p.polygon([[208, 131], [205, 121], [213, 125], [218, 113], [220, 131]], "gold")
	p.polygon([[211, 131], [215, 122], [218, 131]], "cream")
	person(178, 132, "blue")
	finish("location_camp")

func travel_layers() -> void:
	random.seed = 973
	p.fresh(432, 50)
	for x in range(432):
		var hill := 13 + roundi(sin(TAU * x / 432.0) * 4 + cos(TAU * x / 216.0) * 3)
		p.rect(x, hill, 1, 50 - hill, "teal")
		p.rect(x, hill + 9, 1, 41 - hill, "sage")
	for i in range(280):
		var x := random.randi_range(0, 431)
		var y := random.randi_range(30, 49)
		p.rect(x, y, 2, 1, "leaf" if i % 3 else "grass")
	p.save_asset("travel_horizon")
	p.fresh(432, 50)
	p.rect(0, 0, 432, 50, "grass")
	for x in range(432):
		var top := 12 + roundi(2 * sin(TAU * x / 432.0))
		p.rect(x, top, 1, 27, "ochre")
	for i in range(1400):
		var x := random.randi_range(0, 431)
		var y := random.randi_range(0, 49)
		var base: Color = p.image.get_pixel(x, y)
		p.dot(x, y, "gold" if base == p.c("ochre") else "leaf")
		if i % 4 == 0:
			p.dot((x + 1) % 432, y, "sand" if base == p.c("ochre") else "sage")
	for x in range(432):
		if x % 24 < 18:
			p.dot(x, 23, "rust")
			p.dot(x, 33, "rust")
	p.save_asset("travel_ground")
