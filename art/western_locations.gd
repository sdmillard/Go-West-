extends RefCounted
## Original 432x150 interpretations of documented places; see WESTERN_REFERENCES.md.
var p
var helpers
func build(canvas) -> void:
	p = canvas
	helpers = preload("res://art/location_art.gd").new()
	helpers.p = canvas
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	for node in data.nodes:
		if node.id in ["independence","elm_grove","wakarusa","kansas_river","big_blue","platte"]:
			continue
		paint(node.id)
	paint("fort_kearny_early")
	for terrain in ["mountains","desert","forest"]:
		base(terrain)
		helpers.finish("travel_"+terrain)
func base(terrain: String = "plains") -> void:
	helpers.sky()
	if terrain == "desert":
		p.rect(0,68,432,82,"ochre")
		p.polygon([[0,78],[70,48],[142,76],[234,58],[350,77],[432,53],[432,94],[0,94]],"rust")
		p.polygon([[0,102],[150,87],[300,101],[432,84],[432,150],[0,150]],"sand")
		for x in range(6,432,31):
			p.rect(x,110+(x*13)%30,11,2,"sage")
	elif terrain == "mountains":
		p.polygon([[0,72],[40,52],[80,68],[135,35],[198,67],[248,46],[310,69],[368,38],[432,72],[432,104],[0,104]],"haze")
		p.polygon([[0,99],[85,77],[170,100],[280,72],[380,91],[432,75],[432,150],[0,150]],"sage")
	elif terrain == "forest":
		p.polygon([[0,72],[72,47],[150,74],[235,50],[330,76],[402,49],[432,66],[432,110],[0,110]],"teal")
		for x in range(6,432,25):
			pine(x,91+(x*3)%12,20+(x*7)%18)
	path()
func path() -> void:
	p.polygon([[184,96],[200,96],[304,150],[235,150]],"ochre")
	for x in [185,196]:
		helpers.line(x,97,x+62,149,"wood")
func pine(x: int,y: int,h: int) -> void:
	p.rect(x-2,y-h,4,h,"wood")
	p.polygon([[x,y-h-5],[x-15,y-7],[x+15,y-7]],"pine")
	p.polygon([[x,y-h-1],[x-10,y-15],[x+9,y-15]],"leaf")
func river(color: String = "water", width: int = 60) -> void:
	p.polygon([[0,93],[432,82],[432,82+width],[0,93+width]],color)
	for x in range(0,432,23):
		p.rect(x,102+(x*7)%maxi(1,width-10),12,1,"foam")
func wall(x: int,y: int,w: int,h: int,color: String = "sand") -> void:
	p.rect(x,y,w,h,color)
	p.rect(x,y,w,3,"cream")
	for row in range(y+5,y+h,5):
		p.rect(x,row,w,1,"ochre")
	p.rect(x+w/2-7,y+h-20,14,20,"deep")
func paint(id: String) -> void:
	var terrain := "plains"
	if id in ["south_pass","fort_bridger","soda_springs","grande_ronde","blue_mountains","barlow_pass","laurel_hill"]:
		terrain = "mountains"
	elif id in ["snake_river","fort_boise","burnt_river","john_day","deschutes"]:
		terrain = "desert"
	elif id in ["eagle_creek","oregon_city"]:
		terrain = "forest"
	base(terrain)
	match id:
		"fort_kearny", "fort_kearny_early":
			p.rect(0,78,432,9,"water")
			for x in [30,105,280]:
				p.polygon([[x,110],[x+19,86],[x+40,110]],"cream")
				p.polygon([[x+19,86],[x+23,110],[x+13,110]],"deep")
			if id == "fort_kearny":
				wall(169,91,80,23,"927e62")
				p.rect(169,88,80,4,"sage")
				for x in [340,360,380]:
					p.rect(x,108,16,9,"wood")
				helpers.person(262,118,"blue")
		"south_platte", "north_platte", "umatilla", "john_day", "deschutes":
			river("water",34 if id in ["umatilla","john_day"] else 48)
			if id == "south_platte":
				p.polygon([[70,110],[195,103],[302,110],[215,120]],"sand")
			elif id == "north_platte":
				p.polygon([[0,75],[100,65],[175,81],[260,67],[432,76],[432,88],[0,95]],"sage")
			elif id == "umatilla":
				for x in [42,83,354,390]:helpers.tree(x,102)
			else:
				p.polygon([[0,72],[80,85],[132,150],[0,150]],"deep" if id=="deschutes" else "rust")
				p.polygon([[432,61],[370,76],[313,150],[432,150]],"rust")
		"ash_hollow":
			p.polygon([[0,48],[95,67],[135,98],[180,150],[0,150]],"sand")
			p.polygon([[432,49],[330,71],[294,111],[238,150],[432,150]],"ochre")
			p.polygon([[145,117],[290,110],[326,134],[177,147]],"grass")
			helpers.line(50,71,177,139,"wood",2)
			helpers.tree(269,133)
		"courthouse_rock":
			p.polygon([[76,102],[91,72],[103,69],[107,39],[152,39],[156,68],[169,72],[185,104]],"sand")
			p.polygon([[247,101],[260,77],[269,44],[286,44],[294,79],[310,102]],"ochre")
			p.rect(110,45,40,4,"cream")
		"chimney_rock":
			p.polygon([[113,106],[174,80],[190,59],[195,19],[203,17],[208,62],[226,80],[273,107]],"sand")
			helpers.line(197,24,198,67,"ochre",2)
			p.polygon([[162,93],[194,77],[208,78],[230,95]],"ochre")
		"scotts_bluff":
			p.polygon([[31,109],[42,53],[70,44],[123,47],[133,65],[167,68],[197,115]],"sand")
			p.polygon([[252,107],[264,51],[312,49],[340,65],[380,69],[409,115]],"ochre")
			for x in range(50,122,13):helpers.line(x,60,x-4,97,"rust")
			p.polygon([[116,150],[153,118],[225,106],[238,110],[176,135],[163,150]],"wood")
		"fort_laramie":
			wall(85,73,248,52)
			wall(76,60,38,65,"ochre")
			wall(306,63,35,62,"sand")
			p.rect(191,65,37,15,"wood")
			for x in range(86,335,9):p.rect(x,70,2,6,"wood")
			helpers.person(250,135)
		"independence_rock":
			p.ellipse(217,86,145,40,"927e62")
			p.ellipse(210,78,132,30,"aaa58b")
			for x in [120,177,231,284]:helpers.line(x,67,x+10,103,"wood")
			p.rect(0,131,432,11,"water")
		"devils_gate":
			p.polygon([[47,110],[63,36],[134,23],[179,44],[188,112]],"deep")
			p.polygon([[211,114],[221,34],[264,23],[317,45],[343,112]],"wood")
			p.polygon([[190,89],[210,86],[237,150],[169,150]],"water")
			p.polygon([[304,150],[347,113],[372,82],[380,86],[367,125],[352,150]],"ochre")
		"south_pass":
			# Broad low saddle. No high alpine notch at the wagon crossing.
			helpers.sky()
			p.polygon([[0,72],[79,56],[157,71],[284,73],[360,59],[432,73],[432,150],[0,150]],"sage")
			p.polygon([[0,102],[160,89],[279,92],[432,103],[432,150],[0,150]],"sand")
			path()
		"little_sandy":
			p.polygon([[0,107],[165,96],[432,108],[432,116],[162,105],[0,117]],"water")
			p.polygon([[195,150],[197,120],[262,93],[270,94],[215,124],[218,150]],"wood")
		"green_river":
			river("teal",57)
			for x in [24,54,347,390]:helpers.tree(x,97)
			p.polygon([[0,132],[87,129],[140,150],[0,150]],"sand")
		"fort_bridger":
			p.rect(0,129,432,9,"water")
			for x in [80,163,258]:helpers.building(x,83,65,32)
			for x in range(58,350,6):p.rect(x,105,4,19,"wood")
			p.rect(194,101,22,25,"deep")
		"soda_springs":
			for point in [[80,107],[203,120],[337,99]]:
				var x: int = point[0]
				var y: int = point[1]
				p.ellipse(x,y,39,12,"cream")
				p.ellipse(x,y,28,7,"teal")
				for off in [-9,0,11]:p.rect(x+off,y-2,2,2,"foam")
		"fort_hall":
			p.rect(0,111,432,9,"blue")
			wall(117,72,201,46,"cream")
			wall(102,60,29,62,"sand")
			wall(301,65,31,57,"ochre")
			for x in [147,171,253,277]:p.rect(x,88,8,9,"deep")
		"snake_river":
			river("blue",68)
			for point in [[70,108],[207,119],[340,103]]:
				var x: int = point[0]
				var y: int = point[1]
				p.polygon([[x-45,y+3],[x+14,y-9],[x+55,y],[x+10,y+9]],"sand")
				p.polygon([[x-27,y],[x+11,y-6],[x+36,y],[x+7,y+4]],"sage")
			p.polygon([[0,143],[91,131],[132,150],[0,150]],"deep")
		"fort_boise":
			p.polygon([[0,103],[197,106],[432,79],[432,97],[216,124],[0,121]],"water")
			p.polygon([[244,150],[221,112],[232,110],[268,150]],"blue")
			wall(113,68,183,36)
			wall(103,57,25,49,"ochre")
			wall(281,59,26,47,"sand")
		"burnt_river":
			p.polygon([[0,44],[123,86],[180,150],[0,150]],"rust")
			p.polygon([[432,35],[320,73],[250,150],[432,150]],"wood")
			p.polygon([[187,83],[206,79],[242,150],[209,150]],"water")
		"powder_river":
			p.polygon([[0,107],[157,93],[432,104],[432,132],[0,139]],"grass")
			p.rect(0,122,432,8,"water")
			p.rect(338,116,14,16,"wood")
			p.rect(336,113,18,4,"sand")
		"grande_ronde":
			p.ellipse(215,112,190,34,"grass")
			p.ellipse(215,110,151,25,"sage")
			for x in [19,39,392,411]:pine(x,123,46)
		"blue_mountains":
			for x in range(0,433,23):pine(x,115+(x%11),45+(x%17))
			p.polygon([[188,150],[218,106],[237,89],[245,92],[238,120],[232,150]],"sand")
		"the_dalles":
			river("blue",62)
			for x in range(15,430,51):
				p.polygon([[x,113],[x+9,89],[x+25,105],[x+29,127]],"deep")
				p.rect(x+3,120,33,2,"foam")
			p.polygon([[0,134],[144,125],[190,150],[0,150]],"sand")
		"barlow_pass":
			p.polygon([[121,86],[232,8],[344,86]],"haze")
			p.polygon([[201,31],[232,8],[263,31],[247,29],[235,39],[220,27]],"cream")
			for x in [18,48,91,345,385,420]:pine(x,127,64)
		"laurel_hill":
			p.polygon([[0,44],[97,62],[432,147],[432,150],[0,150]],"pine")
			p.polygon([[56,64],[74,62],[346,141],[315,144]],"ochre")
			pine(43,81,57)
			helpers.small_wagon(190,112)
			helpers.line(46,69,205,97,"cream",1)
		"eagle_creek":
			for x in [9,37,75,354,395,425]:pine(x,128,63)
			p.polygon([[0,118],[170,106],[432,122],[432,134],[166,117],[0,130]],"water")
			helpers.building(252,92,45,30)
		"oregon_city":
			# City archive's view: river foreground, east-bank town and bluff,
			# distant Mount Hood. Falls are outside this chosen viewpoint.
			helpers.sky()
			p.polygon([[145,70],[228,21],[309,70]],"haze")
			p.polygon([[202,36],[228,21],[254,37],[235,32],[221,40]],"cream")
			p.polygon([[0,82],[85,69],[168,75],[247,61],[345,70],[432,62],[432,108],[0,108]],"pine")
			p.polygon([[174,85],[243,76],[298,82],[368,64],[432,72],[432,112],[184,113]],"sand")
			p.rect(0,108,432,42,"water")
			for house in [[150,22,16],[190,26,21],[232,31,28],[278,25,18],[316,28,26],[360,35,31],[401,24,23]]:
				helpers.building(house[0],109-house[2],house[1],house[2])
			p.rect(127,79,15,20,"cream")
			p.polygon([[123,79],[135,58],[147,79]],"deep")
			p.polygon([[0,123],[68,129],[117,150],[0,150]],"sand")
			helpers.tree(9,139)
			helpers.person(60,142,"pine")

	# Foreground scale cues are invented; no copied photograph or game sprite.
	if id not in ["oregon_city","laurel_hill","fort_kearny_early"]:
		helpers.small_wagon(29,143)
	helpers.finish("location_"+id)
