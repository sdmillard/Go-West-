extends SceneTree
## The overland guide is a period survival book; the store starts empty (Spencer, October 31).
const Simulation=preload("res://simulation/trail_engine.gd")
const GuideBook=preload("res://ui/guide_book.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
	var data: Dictionary=GuideBook.load_data()
	check(not data.is_empty(),"data/guide.json loads and validates")
	var ids: Array=data.get("chapters",[]).map(func(c):return c.id)
	for id in ["preface","outfit","mounts","road","rivers","camp","keeping","provisions","dogs","sickness","winter","trade","natives","callings","law","arms","fighting"]:
		check(id in ids,"The guide has a chapter: %s" % id)
	for chapter in data.get("chapters",[]):
		check(ResourceLoader.exists("res://art/pixels/%s.png" % chapter.get("plate","")) and not str(chapter.get("caption","")).is_empty(),"Chapter %s has an engraved plate and caption" % chapter.id)
	check(not GuideBook.valid({"title":"x","subtitle":"y","chapters":[{"id":"a","title":"A","period":"p","plain":""}],"outfit":{"food":1}}),"A chapter without plain rules is rejected")
	check(not GuideBook.valid({"title":"x","subtitle":"y","chapters":[{"id":"a","title":"A","period":"p","plain":"q"},{"id":"a","title":"B","period":"p","plain":"q"}],"outfit":{"food":1}}),"Duplicate chapters are rejected")
	var game=Simulation.new(5,"classic",true)
	for good in data.outfit:check(game.outfitter.goods.any(func(g):return g.id==good),"The guide's outfit names a real store good: %s" % good)
	var cart: Dictionary=data.outfit.duplicate()
	for good in game.outfitter.goods:if not cart.has(good.id):cart[good.id]=0
	var farmer: Dictionary=game.outfitter.quote("farmer",cart)
	check(farmer.get("valid",false),"A farmer can buy the guide's whole outfit: %s" % farmer.get("message",""))
	check(game.outfitter.quote("outlaw",cart).get("valid",false),"So can the poorest profession")
	check(int(farmer.get("cargo_lb",0))<=2500,"The guide's outfit fits the wagon")
	var book=GuideBook.new(game)
	root.add_child(book)
	await process_frame
	check(book.current_id()=="preface" and not book.plain_toggle.button_pressed,"The book opens at its preface with plain rules hidden")
	check(not ("PLAIN RULES" in book.page_text("preface",false)),"Period text alone by default")
	check("TO THE EMIGRANT" in book.spread_text() and book.left_folio.text=="- 1 -","The preface opens on page one")
	book.plain_toggle.button_pressed=true
	check("PLAIN RULES" in book.page_text("preface",true) and "PLAIN RULES" in "\n".join(book.pages("preface").map(func(p):return "\n".join(p.map(func(l):return l[0])))),"The toggle reveals the plain rules")
	book.open_chapter("outfit")
	check(book.current_id()=="outfit" and "INDEPENDENCE PRICES" in book.page_text("outfit",true) and "Total" in book.page_text("outfit",true),"The outfit chapter prices the guide's outfit at the store")
	book.set_plain_rules(false)
	check(not ("PLAIN RULES" in book.page_text("outfit",false)),"Turning the toggle off hides them again")
	# Pages: every line fits the page width, pages hold LINES_PER_PAGE lines, chapters open on a left page.
	var all_fit:=true
	var folio:=1
	for plain in [false,true]:
		book.set_plain_rules(plain)
		folio=1
		for chapter in data.chapters:
			check(book.first_folio(chapter.id)==folio and folio%2==1,"Chapter %s opens on a left-hand page (plain %s)" % [chapter.id,plain])
			for page in book.pages(chapter.id):
				check(page.size()<=book.LINES_PER_PAGE,"A page holds at most %d lines" % book.LINES_PER_PAGE)
				for line in page:
					if book.FONT.get_string_size(str(line[0]).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x>book.TEXT_W:all_fit=false;printerr(line[0])
			folio+=book.spreads(chapter.id)*2
	check(all_fit,"Every line fits the page")
	book.set_plain_rules(false)
	for chapter in data.chapters:
		book.open_chapter(chapter.id)
		check(book.spread_text().length()>200,"Chapter %s reads" % chapter.id)
	# Turning pages runs through the whole book onto the back cover, and back to the front cover.
	book.open_chapter("preface")
	var seen: Array=[]
	var turns:=0
	while book.cover=="" and turns<200:
		book.turn(1);turns+=1
		if book.cover=="" and not book.current_id() in seen:seen.append(book.current_id())
	check(book.cover=="back" and book.current_id()=="fighting" and seen.size()==data.chapters.size()-1,"Paging on past the last page closes the book onto its back cover")
	check(not book.left_page.visible and not book.tabs[0].visible and book.back_nodes.all(func(n):return n.visible),"The back cover hides the pages and tabs")
	book.turn(1)
	check(book.cover=="back","Nothing lies past the back cover")
	book.turn(-1)
	check(book.cover=="" and book.current_id()=="fighting" and book.spread==book.spreads("fighting")-1,"Paging back from the back cover opens the last page")
	while book.cover=="" and turns<400:book.turn(-1);turns+=1
	check(book.cover=="front" and book.front_nodes.all(func(n):return n.visible) and not book.right_page.visible,"Paging back past page one closes the book onto its front cover")
	book.turn(-1)
	check(book.cover=="front","Nothing lies before the front cover")
	book.turn(1)
	check(book.cover=="" and book.current_id()=="preface" and book.spread==0 and book.left_page.visible,"Opening the front cover shows page one")
	book.turn(-1)
	book.open_chapter("road")
	check(book.cover=="" and book.current_id()=="road","Opening a chapter from the cover opens the book")
	book.turn(-1);book.turn(-1);book.turn(-1);book.turn(-1);book.turn(-1);book.turn(-1);book.turn(-1);book.turn(-1)
	book.tabs[3].pressed.emit()
	check(book.cover=="","A thumb tab opens the book")
	book.tabs[3].pressed.emit()
	check(book.current_id()==data.chapters[3].id and book.spread==0,"A thumb tab opens its chapter")
	# The store starts empty, and its guide button opens the outfit chapter.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var setup=screen.departure_view
	check(setup.quantities.values().all(func(q):return int(q.value)==0),"Nothing is bought for the player")
	# One GUIDE button for the whole game (Spencer, November 1): no extra guide buttons on the
	# setup screens. At the store counter it opens the outfit chapter.
	check(not ("guide_button" in setup) and not ("party_guide_button" in setup),"The setup screens carry no guide buttons of their own")
	screen.guide.open_chapter("road")
	screen._show_guide()
	await process_frame
	check(screen.guide.visible and screen.guide.current_id()=="road","Outside the store the guide opens where it was left")
	screen.guide.hide()
	setup.show_store()
	screen._show_guide()
	await process_frame
	check(screen.guide.visible and screen.guide.current_id()=="outfit","At the store the guide opens at the outfit chapter")
	if "--capture" in OS.get_cmdline_user_args():
		for shot in [["outfit",false,0],["outfit",true,0],["road",true,1],["preface",false,0],["mounts",false,0],["arms",true,0],["dogs",false,0],["keeping",true,0]]:
			screen.guide.set_plain_rules(shot[1])
			screen.guide.open_chapter(shot[0])
			for i in range(shot[2]):screen.guide.turn(1)
			screen.guide._turn_t=1.0
			screen.guide._turn.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.tools/guide-%s-%s-%d.png" % shot)
		for side in ["front","back"]:
			screen.guide._set_cover(side,0,0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.tools/guide-cover-%s.png" % side)
		screen.guide.open_chapter("outfit")
		screen.guide.turn(1)
		screen.guide._turn_t=0.3
		screen.guide._turn.queue_redraw()
		screen.guide.set_process(false)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.tools/guide-turning.png")
		screen.guide.hide()
		await process_frame
		for view in ["party","store"]:
			if view=="party":setup.show_party()
			else:setup.show_store()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.tools/setup-%s.png" % view)
	print("Guide book: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
