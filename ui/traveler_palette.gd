extends RefCounted
## Runtime palette substitution on original Aseprite sprites; alpha, outlines and animation geometry stay intact.
const Appearance=preload("res://simulation/traveler_appearance.gd")
static var cache: Dictionary={}
static func texture(source: Texture2D, profile: Dictionary, hunting: bool=false) -> Texture2D:
	if not profile.has("appearance"):return source
	var look: Dictionary=profile.get("appearance",Appearance.default_for(int(profile.get("id",0))))
	var key: String=str(source.get_instance_id())+":"+str(look.skin)+":"+str(look.hair)+":"+str(look.clothing)+":"+str(hunting)
	if cache.has(key):return cache[key]
	var data: Dictionary=Appearance.catalog()
	var colors: Dictionary={Color("e0a878"):Color(data.skin[look.skin][0]),Color("b77f58"):Color(data.skin[look.skin][1]),Color("594537"):Color(data.hair[look.hair])}
	var coat: Array=data.clothing[look.clothing]
	var groups: Array=[["37688e","8db8c3","47796b"],["9e3f33","b4694a","6e3a2c"]]
	if hunting:groups.append(["c18d4d","ddb461","a16b43"])
	for group in groups:
		for i in range(3):colors[Color(group[i])]=Color(coat[i])
	var pixels: Image = source.get_image().duplicate()
	if pixels.is_compressed():pixels.decompress()
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var original := pixels.get_pixel(x,y)
			if colors.has(original):pixels.set_pixel(x,y,colors[original])
	var result := ImageTexture.create_from_image(pixels)
	cache[key]=result
	return result
