extends SceneTree
## Original pixel assets, authored in code. Run with Godot --headless --script art/build_art.gd.
## Every mark is an integer pixel; no resampling, antialiasing, or generated-image input.
const OUT := "res://art/pixels/"
const COLORS := {
	"ink": "302b2c", "deep": "45372f", "wood": "76503c", "rust": "a16b43",
	"ochre": "c18d4d", "gold": "ddb461", "sand": "ecd097", "cream": "f6e7bc",
	"white": "fff4d4", "sage": "8d9b53", "grass": "667c44", "leaf": "425e3b",
	"pine": "2c493f", "teal": "47796b", "haze": "84b3a1", "sky": "548db3",
	"blue": "37688e", "light_blue": "8db8c3", "water": "3d7f99", "foam": "afd5ce"
}
var image: Image
var rng := RandomNumberGenerator.new()

func c(name: String) -> Color:
	return Color(COLORS.get(name, name))

func rect(x: int, y: int, w: int, h: int, color: String) -> void:
	image.fill_rect(Rect2i(x, y, w, h), c(color))

func dot(x: int, y: int, color: String) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, c(color))

func polygon(points: Array, color: String) -> void:
	var vertices := PackedVector2Array()
	var bounds := Rect2(Vector2(points[0][0], points[0][1]), Vector2.ZERO)
	for point in points:
		var v := Vector2(point[0], point[1])
		vertices.append(v)
		bounds = bounds.expand(v)
	for y in range(int(bounds.position.y), int(bounds.end.y) + 1):
		for x in range(int(bounds.position.x), int(bounds.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), vertices):
				dot(x, y, color)

func ellipse(cx: int, cy: int, rx: int, ry: int, color: String) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if pow(float(x - cx) / rx, 2) + pow(float(y - cy) / ry, 2) <= 1.0:
				dot(x, y, color)

func fresh(w: int, h: int) -> void:
	image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

func save_asset(name: String) -> void:
	var result := image.save_png(OUT + name + ".png")
	assert(result == OK, "Could not write pixel art")

func cloud(x: int, y: int, wide: int) -> void:
	for puff in [[0, 7, 17, 4], [10, 3, 13, 7], [22, 0, 10, 10], [33, 5, 15, 5], [45, 8, 12, 3]]:
		var px: int = x + puff[0] * wide / 60
		var pw: int = maxi(4, puff[2] * wide / 60)
		ellipse(px, y + puff[1], pw, puff[3], "light_blue")
		ellipse(px - 1, y + puff[1] - 2, maxi(3, pw - 2), maxi(2, puff[3] - 1), "cream")
	rect(x - 5, y + 9, wide + 8, 1, "haze")

func landscape(river: bool) -> void:
	fresh(432, 150)
	for y in range(76):
		var bands := ["37688e", "447eaa", "548db3", "6e9fb9", "8db8c3"]
		rect(0, y, 432, 1, bands[mini(4, y / 16)])
	cloud(28, 24, 75)
	cloud(177, 18, 51)
	cloud(314, 27, 90)
	cloud(116, 43, 33)
	polygon([[0, 76], [32, 66], [55, 69], [90, 61], [132, 70], [164, 65], [206, 73], [242, 62], [294, 70], [342, 59], [389, 67], [432, 62], [432, 95], [0, 95]], "haze")
	polygon([[0, 82], [41, 77], [79, 81], [117, 72], [154, 80], [199, 74], [245, 84], [289, 75], [341, 80], [392, 72], [432, 81], [432, 101], [0, 101]], "teal")
	rect(0, 89, 432, 61, "grass")
	polygon([[0, 100], [61, 90], [121, 98], [173, 87], [230, 94], [282, 91], [336, 99], [388, 88], [432, 95], [432, 120], [0, 120]], "sage")
	# Distant tree clusters and prairie textures, with a fixed art-only seed.
	for i in range(80):
		var x := rng.randi_range(0, 431)
		var y := rng.randi_range(85, 102)
		rect(x, y, rng.randi_range(2, 5), 2, "leaf")
		dot(x+1, y-1, "grass")
	for i in range(1500):
		var x := rng.randi_range(0, 431)
		var y := rng.randi_range(94, 149)
		var shade: String = ["gold", "ochre", "grass", "leaf", "sage"][i % 5]
		rect(x, y, 1 + int(y > 124), 1, shade)
	# The road is a separate horizontal band with ruts, not a smooth gradient.
	polygon([[0, 116], [80, 114], [150, 116], [232, 113], [310, 115], [432, 112], [432, 140], [323, 136], [240, 139], [122, 137], [0, 140]], "ochre")
	for y in range(118, 138):
		for x in range(432):
			if rng.randf() < 0.13:
				dot(x, y, ["rust", "gold", "sand"][rng.randi_range(0, 2)])
	for x in range(432):
		if x % 17 < 13:
			dot(x, 123 + int(sin(x * 0.03)), "rust")
			dot(x, 132 + int(cos(x * 0.04)), "rust")
	if river:
		polygon([[355, 88], [370, 99], [352, 112], [326, 125], [295, 150], [432, 150], [432, 94]], "water")
		for i in range(55):
			var y := rng.randi_range(102, 148)
			var x := rng.randi_range(355 - (y - 100), 431)
			rect(x, y, rng.randi_range(2, 8), 1, "foam" if i % 3 == 0 else "sky")
	# Foreground grass clumps and seed heads frame the scene.
	for x in [3, 24, 61, 103, 163, 244, 301, 379, 421]:
		for j in range(7):
			var px: int = x + j * 2
			var tip := rng.randi_range(137, 144)
			rect(px, tip, 1, 150 - tip, "leaf")
			dot(px-1, tip+2, "sage")
			dot(px, tip-1, "gold")
	for x in [17, 79, 285, 405]:
		ellipse(x, 143, 4, 2, "deep")
		ellipse(x-1, 142, 3, 1, "sand")
	save_asset("river" if river else "prairie")

func wheel(cx: int, cy: int, frame: int) -> void:
	ellipse(cx, cy, 8, 8, "ink")
	ellipse(cx, cy, 6, 6, "ochre")
	ellipse(cx, cy, 4, 4, "deep")
	for spoke in range(6):
		var angle := float(spoke) * TAU / 6.0 + frame * TAU / 24.0
		for r in range(1, 6):
			dot(cx + roundi(cos(angle) * r), cy + roundi(sin(angle) * r), "gold")
	rect(cx-1, cy-1, 3, 3, "sand")
	dot(cx, cy, "rust")

func wagon() -> void:
	fresh(384, 64)
	for frame in range(4):
		var x := frame * 96
		ellipse(x+37, 56, 34, 3, "45372f88")
		# Canvas silhouette and stepped highlights.
		polygon([[x+8, 39], [x+8, 21], [x+11, 12], [x+17, 7], [x+47, 7], [x+55, 13], [x+59, 23], [x+59, 39]], "deep")
		polygon([[x+10, 37], [x+10, 22], [x+13, 14], [x+19, 9], [x+46, 9], [x+53, 15], [x+57, 24], [x+57, 37]], "sand")
		rect(x+17, 13, 29, 22, "cream")
		rect(x+22, 10, 21, 4, "white")
		for seam in [17, 29, 42, 52]:
			rect(x+seam, 16 if seam < 50 else 23, 1, 20 if seam < 50 else 13, "ochre")
			dot(x+seam+1, 16, "gold")
		rect(x+10, 34, 46, 3, "gold")
		rect(x+7, 38, 54, 11, "deep")
		rect(x+8, 38, 52, 3, "rust")
		rect(x+9, 43, 50, 3, "wood")
		rect(x+9, 47, 52, 1, "ochre")
		for plank in [18, 34, 49]:
			rect(x+plank, 38, 1, 9, "deep")
			dot(x+plank+2, 40, "sand")
		rect(x+58, 42, 29, 2, "wood")
		rect(x+59, 41, 27, 1, "gold")
		# Barrel lashed to the rear and a small driver's seat.
		rect(x+3, 32, 8, 15, "rust")
		rect(x+2, 35, 10, 2, "ink")
		rect(x+2, 43, 10, 2, "ink")
		rect(x+5, 33, 1, 13, "gold")
		rect(x+59, 34, 8, 3, "wood")
		wheel(x+19, 51, frame)
		wheel(x+52, 51, frame)
	save_asset("wagon")

func oxen() -> void:
	fresh(192, 32)
	for frame in range(4):
		var x := frame * 48
		ellipse(x+22, 29, 20, 2, "45372f66")
		var step: int = [-1, 0, 1, 0][frame]
		for leg in [9, 15, 28, 33]:
			var dx: int = step if leg % 2 == 0 else -step
			rect(x+leg+dx, 19, 3, 9, "wood")
			rect(x+leg+dx-1, 27, 4, 2, "ink")
		polygon([[x+4, 14], [x+8, 8], [x+29, 7], [x+35, 11], [x+35, 22], [x+10, 22], [x+5, 19]], "deep")
		polygon([[x+6, 14], [x+10, 10], [x+28, 9], [x+33, 12], [x+33, 20], [x+11, 20], [x+7, 18]], "ochre")
		rect(x+12, 10, 16, 4, "sand")
		rect(x+25, 16, 9, 4, "rust")
		polygon([[x+31, 8], [x+37, 5], [x+42, 9], [x+44, 18], [x+39, 22], [x+33, 18]], "sand")
		rect(x+39, 16, 6, 4, "wood")
		dot(x+40, 11, "ink")
		rect(x+33, 4, 2, 5, "cream")
		rect(x+32, 3, 2, 2, "cream")
		rect(x+40, 3, 2, 5, "cream")
		rect(x+41, 2, 2, 2, "white")
		rect(x+29, 10, 4, 4, "wood")
		rect(x+27, 8, 9, 2, "deep")
		rect(x+4, 17, 1, 8, "wood")
	save_asset("oxen")

func corolla() -> void:
	fresh(80, 40)
	ellipse(39, 35, 35, 3, "45372f88")
	polygon([[3, 23], [13, 20], [23, 10], [51, 10], [62, 20], [75, 23], [77, 31], [4, 32]], "ink")
	polygon([[5, 23], [15, 22], [24, 12], [50, 12], [61, 22], [73, 24], [74, 29], [5, 30]], "sand")
	polygon([[24, 14], [34, 14], [34, 21], [17, 21]], "blue")
	polygon([[37, 14], [49, 14], [57, 21], [37, 21]], "blue")
	rect(24, 15, 9, 2, "light_blue")
	rect(39, 15, 10, 2, "light_blue")
	rect(7, 25, 64, 2, "cream")
	rect(7, 29, 65, 2, "rust")
	rect(36, 23, 1, 7, "ochre")
	rect(30, 23, 4, 1, "wood")
	rect(54, 23, 4, 1, "wood")
	rect(70, 23, 5, 2, "white")
	rect(4, 23, 3, 2, "rust")
	for x in [17, 62]:
		ellipse(x, 31, 6, 6, "ink")
		ellipse(x, 31, 3, 3, "haze")
		dot(x, 31, "deep")
	save_asset("corolla")

func elder() -> void:
	fresh(72, 80)
	# Stepped tentacles, faceted skull and a restrained gold eye glow.
	for i in range(7):
		var x := 8 + i * 8
		polygon([[x, 36], [x+8, 37], [x+6, 57], [x+12, 69], [x+8, 75], [x, 64], [x-2, 53]], "pine")
		rect(x+1, 45, 2, 14, "teal")
		rect(x+6, 66, 3, 3, "sage")
	polygon([[13, 39], [12, 21], [20, 7], [36, 2], [52, 9], [60, 25], [56, 42], [42, 52], [25, 49]], "pine")
	polygon([[17, 35], [17, 22], [24, 11], [35, 7], [48, 12], [54, 25], [50, 39], [39, 45], [26, 42]], "teal")
	polygon([[22, 20], [29, 12], [37, 11], [44, 17], [32, 25]], "haze")
	polygon([[20, 27], [30, 29], [29, 34], [23, 32]], "deep")
	polygon([[40, 29], [51, 27], [47, 33], [40, 34]], "deep")
	rect(23, 29, 5, 2, "gold")
	rect(42, 29, 5, 2, "gold")
	dot(25, 29, "white")
	dot(44, 29, "white")
	for x in [28, 34, 40]:
		rect(x, 36, 3, 17, "pine")
		rect(x, 38, 1, 10, "sage")
	save_asset("elder")

func saber() -> void:
	fresh(40, 16)
	rect(3, 8, 9, 4, "ink")
	rect(4, 8, 7, 2, "haze")
	for x in [5, 8]:
		rect(x, 8, 1, 3, "wood")
	rect(11, 7, 2, 6, "sand")
	rect(13, 8, 23, 4, "blue")
	rect(13, 9, 24, 2, "foam")
	rect(13, 9, 22, 1, "white")
	save_asset("lightsaber")

func font() -> void:
	# Original compact 5x7 bitmap alphabet, with lowercase aliases for readable prose.
	var glyphs := {
	"A":"01110/10001/10001/11111/10001/10001/10001", "B":"11110/10001/10001/11110/10001/10001/11110",
	"C":"01111/10000/10000/10000/10000/10000/01111", "D":"11110/10001/10001/10001/10001/10001/11110",
	"E":"11111/10000/10000/11110/10000/10000/11111", "F":"11111/10000/10000/11110/10000/10000/10000",
	"G":"01111/10000/10000/10111/10001/10001/01110", "H":"10001/10001/10001/11111/10001/10001/10001",
	"I":"11111/00100/00100/00100/00100/00100/11111", "J":"00111/00010/00010/00010/10010/10010/01100",
	"K":"10001/10010/10100/11000/10100/10010/10001", "L":"10000/10000/10000/10000/10000/10000/11111",
	"M":"10001/11011/10101/10101/10001/10001/10001", "N":"10001/11001/10101/10011/10001/10001/10001",
	"O":"01110/10001/10001/10001/10001/10001/01110", "P":"11110/10001/10001/11110/10000/10000/10000",
	"Q":"01110/10001/10001/10001/10101/10010/01101", "R":"11110/10001/10001/11110/10100/10010/10001",
	"S":"01111/10000/10000/01110/00001/00001/11110", "T":"11111/00100/00100/00100/00100/00100/00100",
	"U":"10001/10001/10001/10001/10001/10001/01110", "V":"10001/10001/10001/10001/10001/01010/00100",
	"W":"10001/10001/10001/10101/10101/10101/01010", "X":"10001/10001/01010/00100/01010/10001/10001",
	"Y":"10001/10001/01010/00100/00100/00100/00100", "Z":"11111/00001/00010/00100/01000/10000/11111",
	"0":"01110/10001/10011/10101/11001/10001/01110", "1":"00100/01100/00100/00100/00100/00100/01110",
	"2":"01110/10001/00001/00010/00100/01000/11111", "3":"11110/00001/00001/01110/00001/00001/11110",
	"4":"00010/00110/01010/10010/11111/00010/00010", "5":"11111/10000/10000/11110/00001/00001/11110",
	"6":"01110/10000/10000/11110/10001/10001/01110", "7":"11111/00001/00010/00100/01000/01000/01000",
	"8":"01110/10001/10001/01110/10001/10001/01110", "9":"01110/10001/10001/01111/00001/00001/01110",
	".":"00000/00000/00000/00000/00000/00110/00110", ",":"00000/00000/00000/00000/00110/00110/00100",
	":":"00000/00110/00110/00000/00110/00110/00000", ";":"00000/00110/00110/00000/00110/00110/00100",
	"!":"00100/00100/00100/00100/00100/00000/00100", "?":"01110/10001/00001/00010/00100/00000/00100",
	"-":"00000/00000/00000/11111/00000/00000/00000", "+":"00000/00100/00100/11111/00100/00100/00000",
	"/":"00001/00010/00010/00100/01000/01000/10000", "\\":"10000/01000/01000/00100/00010/00010/00001",
	"'":"00100/00100/00000/00000/00000/00000/00000", "\"":"01010/01010/00000/00000/00000/00000/00000",
	"(":"00010/00100/01000/01000/01000/00100/00010", ")":"01000/00100/00010/00010/00010/00100/01000",
	"$":"00100/01111/10100/01110/00101/11110/00100", "%":"11001/11010/00010/00100/01000/01011/10011",
	"=":"00000/00000/11111/00000/11111/00000/00000", "<":"00010/00100/01000/10000/01000/00100/00010",
	">":"01000/00100/00010/00001/00010/00100/01000", "*":"00000/10101/01110/11111/01110/10101/00000",
	"[":"01110/01000/01000/01000/01000/01000/01110", "]":"01110/00010/00010/00010/00010/00010/01110",
	"_":"00000/00000/00000/00000/00000/00000/11111", "|":"00100/00100/00100/00100/00100/00100/00100",
	"#":"01010/01010/11111/01010/11111/01010/01010", "~":"00000/00000/01001/10110/00000/00000/00000",
	"@":"01110/10001/10111/10101/10111/10000/01111", "&":"01100/10010/10100/01000/10101/10010/01101"
	}
	var aliases := {183: ".", 8226: "*", 8594: ">", 8212: "-", 8211: "-", 8217: "'", 8216: "'", 8220: "\"", 8221: "\""}
	var codes: Array[int] = []
	for i in range(32, 127):
		codes.append(i)
	for code in aliases:
		codes.append(code)
	fresh(128, 80)
	var lines := "info face=\"Trail Serif Pixel\" size=8 unicode=1 smooth=0 aa=1\ncommon lineHeight=9 base=7 scaleW=128 scaleH=80 pages=1 packed=0\npage id=0 file=\"trail_font.png\"\nchars count=%d\n" % codes.size()
	for index in range(codes.size()):
		var code: int = codes[index]
		var ch: String = String.chr(code).to_upper() if code < 127 else aliases[code]
		var x: int = (index % 16) * 8
		var y: int = (index / 16) * 10
		var pattern: PackedStringArray = glyphs.get(ch, "00000/00000/00000/00000/00000/00000/00000").split("/")
		for row in range(7):
			for col in range(5):
				if pattern[row][col] == "1":
					dot(x+col, y+row, "ffffff")
		lines += "char id=%d x=%d y=%d width=5 height=7 xoffset=0 yoffset=0 xadvance=6 page=0 chnl=15\n" % [code, x, y]
	save_asset("trail_font")
	var file := FileAccess.open(OUT + "trail_font.fnt", FileAccess.WRITE)
	file.store_string(lines)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	rng.seed = 73421
	landscape(false)
	rng.seed = 73421
	landscape(true)
	wagon()
	oxen()
	corolla()
	elder()
	saber()
	preload("res://art/location_art.gd").new().build(self)
	preload("res://art/western_locations.gd").new().build(self)
	font()
	print("Original pixel assets rebuilt.")
	quit()
