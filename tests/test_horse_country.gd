extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
const PACKERS={"wagon":0,"oxen":0,"horses":5,"mules":3,"saddles":5,"pack_saddles":3,"saddlebags":5,"food":500,"clothing":5,"bullet_boxes":5,"medicine":2,"salt":5}
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func packers(cart: Dictionary=PACKERS,seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	check(game.depart("banker",["A","B","C","D","E"],5,cart),"Packers depart: "+game.departure_error)
	for member in game.party_health.members:member.health=100
	game.state.health=100
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func thieves(game) -> Dictionary:
	for event in game.trail_events.events:
		if event.id=="horse_thieves":return event.duplicate(true)
	return {}
func count_thieves(game,rolls: int) -> int:
	var seen:=0
	var stock: Array=[game.state.get("horses",0),game.state.get("mules",0)]
	game.survival.data.event_chance=1.0
	for i in range(rolls):
		game.pending={}
		game._roll_trail_event()
		if game.pending.get("id","")=="horse_thieves":seen+=1
		# Put back anything the event took so every roll sees the same outfit.
		if game.state.has("horses"):game.state.horses=stock[0]
		if game.state.has("mules"):game.state.mules=stock[1]
	game.pending={}
	return seen
func run():
	var store=Store.new()
	# Night horse thieves take two horses; riding after them can win both back.
	var game=packers()
	game._present_trail_event(thieves(game))
	check(game.pending.id=="horse_thieves" and game.state.horses==3 and "two horses" in game.pending.text,"Thieves run off two horses in the night")
	check(game.pending.choices.size()==3 and game.pending.choices[0].effects.horses==2 and game.pending.choices[1].effects.horses==1,"The party can chase them, search nearby, or let them go")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A save with horse thieves pending loads")
	game.choose(0)
	check(game.state.horses==5,"Running the thieves down brings both horses back")
	game=packers({"wagon":0,"mules":2,"pack_saddles":2,"food":100,"clothing":5})
	game._present_trail_event(thieves(game))
	check(game.state.mules==0 and "two mules" in game.pending.text and game.pending.choices[0].effects.get("mules",0)==2 and not game.pending.choices[0].effects.has("horses"),"With no horses, thieves take the mules")
	game=packers({"oxen":4,"horses":1,"saddles":1,"food":300,"clothing":5})
	game._present_trail_event(thieves(game))
	check(game.state.horses==0 and "a horse" in game.pending.text and game.pending.choices.size()==2 and game.pending.choices[0].effects.horses==1,"A wagon party's one led horse can be stolen; chasing or letting it go")
	# No animals, no horse thieves; a night guard keeps most of them away.
	var wagon=Simulation.new(57,"classic",true)
	wagon.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":300,"clothing":5})
	wagon.survival.forced_weather="clear"
	check(count_thieves(wagon,300)==0,"A party with no horses or mules never meets horse thieves")
	game=packers()
	var open: int=count_thieves(game,600)
	game.set_night_guard(true)
	var guarded: int=count_thieves(game,600)
	check(open>0 and guarded<open,"A night guard turns away most horse thieves (%d unguarded, %d guarded)" % [open,guarded])
	# The watch costs sleep.
	var rested=packers()
	var watched=packers()
	watched.set_night_guard(true)
	rested.travel()
	watched.travel()
	check(int(watched.state.fatigue)-int(rested.state.fatigue)==int(game.provisions.data.mounts.guard_fatigue),"Standing watch over the stock tires the party")
	var snapshot: Dictionary=store.capture(watched)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and copy.state.night_guard==true,"The night guard order saves")
	snapshot.state.night_guard="yes"
	check(store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null,"A malformed night guard order is rejected")
	check(not wagon.set_night_guard(true),"There is no stock to guard without animals")
	# Butchering stock: a horse gives less meat than an ox.
	game=packers()
	var offer: Dictionary=game.mount_slaughter_offer("horses")
	check(offer.meat==250 and offer.bullets==1 and offer.remaining==4,"A horse in good flesh gives 250 lb of meat for a bullet")
	check(game.mount_slaughter_offer("mules").meat==220,"A mule gives 220 lb")
	game.state["horse_health"]=0
	check(game.mount_slaughter_offer("horses").meat==125,"A worn-out horse gives half as much")
	game.state["horse_health"]=100
	var food: int=game.state.food
	var day: int=game.state.day
	check(game.slaughter_mount("horses") and game.state.horses==4 and game.state.food>food and game.state.day==day+1,"Butchering a horse costs a day and the horse, and feeds the party")
	check(game.journal.any(func(line):return "Butchered a horse" in line),"The journal records the butchering")
	game.state.bullets=0
	check(game.mount_slaughter_offer("mules").is_empty() and not game.mount_slaughter_offer("mules",true).is_empty(),"Without bullets a mule can still be butchered by hand")
	check(game.slaughter_mount("mules",true) and game.state.mules==2,"Butchering by hand works")
	check(game.mount_slaughter_offer("oxen").is_empty(),"Only horses and mules are butchered this way")
	# Nez Perce horse traders at the Grande Ronde.
	game=packers()
	game.state.next_landmark="grande_ronde"
	game._arrive_landmark()
	var index: int=game.pending.choices.find_custom(func(choice):return choice.get("horse_traders",false))
	check(index>=0 and "Nez Perce" in game.pending.choices[index].label,"The Grande Ronde offers horse trading with the Nez Perce")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A save at the Grande Ronde with the horse traders loads")
	check(game.choose(index) and game.pending.title=="Nez Perce horse traders" and game.pending.choices.size()==5,"Their terms: clothing, an ox, bullets or coin, or go back")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A save in the horse traders' menu loads")
	var horses: int=game.state.horses
	var clothing: int=game.state.clothing
	day=game.state.day
	check(game.choose(0) and game.state.horses==horses+1 and game.state.clothing==clothing-2 and game.state.day==day+1,"Two clothing sets buy a horse; the first trade costs the day")
	game.open_horse_traders()
	check("3 left" in game.pending.choices[3].label and " 1 day" not in game.pending.choices[3].label,"Later trades take no time and the herd has fewer to spare")
	game.state.money=100.0
	for i in range(3):
		game.open_horse_traders()
		game.choose(3)
	game.open_horse_traders()
	check(game.state.horses==horses+4 and not game.can_choose(3) and game.state.day==day+1,"The herd parts with only four horses")
	game.choose(game.pending.choices.size()-1)
	check(packers().open_horse_traders()==false,"There are no horse traders away from the Grande Ronde")
	# Goods fetch more where they cost more, and still less than they cost.
	var west=packers()
	west.route_path=west.route.main_path_to("fort_bridger")
	west.state.landmark="fort_bridger"
	west.state.next_landmark="fort_bridger"
	west.state.miles=int(west.route.node_miles()["fort_bridger"])
	west.state.leg_miles=0
	west.state.leg_length=0
	west.pending={}
	west._arrive_landmark(true,false)
	var price: float=float(west.context.region(west).price)
	var under:=true
	var regional:=true
	for row in west.post_store().rows:
		if row.item in ["wagon","produce","dried_produce","food"]:continue
		for lot in west.survival.data.trade_lots:
			if lot.item==row.item and int(row.sell_cents)!=roundi(int(lot.sell_cents)*price):regional=false
		if int(row.sell_cents)>=int(row.buy_cents):under=false
	check(price>1.0 and regional,"Out west, the post pays the regional price for what it buys")
	check(under,"It still pays less than it charges for anything")
	# A save from before horse thieves loads unchanged.
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horse-thieves-save-v1.json"))
	var upgraded=store.restore(old)
	check(upgraded!=null and upgraded.state==store.normalize(old.state),"A save from before horse thieves loads")
	# The Travel and Supplies screens offer the guard and the butchering.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=packers()
	screen._refresh()
	screen._show_section("Travel")
	var guard=screen.find_child("NightGuard",true,false)
	check(guard!=null and "OFF" in guard.text,"Travel offers a night guard on the stock")
	if guard!=null:guard.pressed.emit()
	check(screen.game.state.get("night_guard",false),"The guard button sets the watch")
	screen.section_window.hide()
	screen._show_supplies()
	var texts: Array=[]
	var stack: Array=[screen.supplies_window]
	while not stack.is_empty():
		var node=stack.pop_back()
		if node is Button:texts.append(node.text)
		stack.append_array(node.get_children())
	check(texts.any(func(text):return text.begins_with("BUTCHER 1 HORSE")) and texts.any(func(text):return text.begins_with("BUTCHER 1 MULE")),"Supplies offers to butcher a horse or a mule")
	screen.supplies_window.hide()
	screen.queue_free()
	await process_frame
	print("Horse country: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
