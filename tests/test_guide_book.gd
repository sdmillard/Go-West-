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
	for id in ["preface","outfit","road","rivers","sickness","provisions","winter","callings","law","fighting"]:
		check(id in ids,"The guide has a chapter: %s" % id)
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
	check(not ("PLAIN RULES" in book.page.text),"Period text alone by default")
	book.plain_toggle.button_pressed=true
	check("PLAIN RULES" in book.page.text,"The toggle reveals the plain rules")
	book.open_chapter("outfit")
	check(book.current_id()=="outfit" and "INDEPENDENCE PRICES" in book.page.text and "Total $" in book.page.text,"The outfit chapter prices the guide's outfit at the store")
	book.set_plain_rules(false)
	check(not ("PLAIN RULES" in book.page.text),"Turning the toggle off hides them again")
	for chapter in data.chapters:
		book.open_chapter(chapter.id)
		check(book.page.get_parsed_text().length()>200,"Chapter %s reads" % chapter.id)
	# The store starts empty, and its guide button opens the outfit chapter.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var setup=screen.departure_view
	check(setup.quantities.values().all(func(q):return int(q.value)==0),"Nothing is bought for the player")
	setup.show_store()
	setup.guide_button.pressed.emit()
	await process_frame
	check(screen.guide.visible and screen.guide.current_id()=="outfit","The store's guide button opens the outfit chapter")
	screen.guide.hide()
	setup.party_guide_button.pressed.emit()
	await process_frame
	check(screen.guide.visible and screen.guide.current_id()=="preface","The party screen's guide button opens the preface")
	if "--capture" in OS.get_cmdline_user_args():
		screen.guide.plain_toggle.button_pressed=true
		screen.guide.open_chapter("outfit")
		screen.guide.page.scroll_to_line(14)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.tools/guide-outfit.png")
	print("Guide book: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
