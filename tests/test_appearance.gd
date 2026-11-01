extends SceneTree
const Appearance=preload("res://simulation/traveler_appearance.gd")
const Palette=preload("res://ui/traveler_palette.gd")
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool, text: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+text)
func party():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,cart)
	return game
func run():
	var skins: Dictionary={}
	var heritages: Dictionary={}
	for seed_value in range(128):
		var look=Appearance.generate(seed_value,3)
		check(look==Appearance.generate(seed_value,3) and Appearance.valid(look),"Generated appearance is reproducible and valid")
		skins[look.skin]=true
		heritages[look.heritage]=true
	check(skins.size()==6 and heritages.size()==Appearance.catalog().heritage.size(),"Generation covers skin palettes and descriptive heritage options")
	for edit in [{"skin":"missing"},{"outfit":2},{"hair":"missing"},{"clothing":"missing"},{"heritage":"x".repeat(65)},{"heritage":"bad\nline"}]:
		var look=Appearance.default_for(1)
		look.merge(edit,true)
		check(not Appearance.valid(look),"Malformed cosmetic field rejected")
	var game=party()
	var offer=game.characters.generate_candidate(57,12)
	check(Appearance.valid(offer.profile.appearance),"Candidate generator includes appearance and personal background")
	var quote: Dictionary=game.characters.wage_quote(offer.profile)
	offer.profile.appearance=Appearance.generate(999,2)
	check(game.characters.wage_quote(offer.profile)==quote,"Appearance and heritage do not change wages or occupational value")
	var variant=party()
	for profile in variant.characters.profiles:profile.appearance=Appearance.generate(9999,int(profile.id))
	for step in range(12):
		for model in [game,variant]:
			if model.pending.is_empty():model.travel()
			else:
				for index in range(model.pending.choices.size()):
					if model.can_choose(index):model.choose(index);break
	check(game.state==variant.state and game.journal==variant.journal and game.rng.state==variant.rng.state,"Different looks and heritage leave journey outcomes, trust and RNG unchanged")
	var store=Store.new()
	var document=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(document)))
	check(copy!=null and copy.characters.profiles==game.characters.profiles,"Appearance round-trips in actual journey saves")
	var bad=store.capture(game)
	bad.characters[1].appearance.skin="invalid"
	check(store.restore(bad)==null,"Save validation rejects invalid appearance")
	var old=store.capture(game)
	for profile in old.characters:profile.erase("appearance")
	copy=store.restore(JSON.parse_string(JSON.stringify(old)))
	check(copy!=null and not copy.characters.profiles[1].has("appearance"),"Existing saves keep their prior unspecified appearance")
	for path in ["walker","hunt_hunter","cross_people","cross_swimmer"]:
		var source: Texture2D=load("res://art/pixels/%s.png" % path)
		var original: Image=source.get_image().duplicate()
		var profile={"id":1,"appearance":Appearance.default_for(1)}
		profile.appearance.skin="Deep"
		profile.appearance.hair="Blond"
		profile.appearance.clothing="Green"
		var texture: Texture2D=Palette.texture(source,profile,path=="hunt_hunter")
		var pixels=texture.get_image()
		var changed:=0
		var alpha_ok:=true
		var skin_found:=false
		for y in range(original.get_height()):
			for x in range(original.get_width()):
				var color=original.get_pixel(x,y)
				var actual=pixels.get_pixel(x,y)
				if color!=actual:changed+=1
				if color.a!=actual.a:alpha_ok=false
				if color==Color("e0a878") and actual==Color("63412f"):skin_found=true
		check(changed>0 and skin_found and alpha_ok and pixels.get_size()==original.get_size(),"Palette changes visible skin across every original sprite sheet without changing silhouettes: "+path)
		check(source.get_image().get_data()==original.get_data(),"Runtime palette never changes source art")
		check(texture==Palette.texture(source,profile,path=="hunt_hunter"),"Palette caches generated textures")
		check(Palette.texture(source,{"id":1})==source,"Legacy unspecified appearance keeps original colors")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var view=screen.departure_view
	view.use_preset_party()
	view.open_appearance(0)
	view.look_boxes.skin.select(Appearance.catalog().skin.keys().find("Deep"))
	view.heritage_entry.text="Custom family history"
	view._store_appearance()
	check(view.draft.profiles[0].appearance.skin=="Deep" and view.customization().profiles[0].appearance.heritage=="Custom family history","Leader appearance edits reach the departure transaction")
	check(view.look_preview.texture!=null,"Appearance editor has a live sprite preview")
	view.appearance_window.hide()
	view.open_editor(1)
	view._generate_companion()
	check(Appearance.valid(view.customization().profiles[1].appearance),"UI-generated companion keeps its generated appearance")
	screen.game=game
	game.party_health.members[1]["departed"]=true
	screen._refresh()
	check(screen.landscape.traveler_profiles.map(func(profile):return int(profile.id))==[0,2,3,4],"Moving travelers keep their own appearances after a companion leaves")
	screen.queue_free()
	await process_frame
	print("Appearance: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
