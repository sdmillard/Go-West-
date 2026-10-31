extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Provisions=preload("res://simulation/provisions.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	return game
func run():
	var p=Provisions.new()
	var inventory: Dictionary={"food":0,"oxen":6,"party_size":5}
	var base: float=p.cargo(inventory)
	inventory.food=p.add_meat(100,0)
	check(inventory.food==50 and is_equal_approx(p.cargo(inventory)-base,100),"Hundred-pound haul holds fifty meal units and one hundred physical pounds")
	p.remove(15);inventory.food-=15
	check(is_equal_approx(p.cargo(inventory)-base,70),"Eating fifteen meat units removes thirty physical pounds")
	var before: Array=p.fresh.duplicate(true)
	var plan: Dictionary=p.preservation_plan(0,inventory.food,15)
	check(p.fresh==before and plan.input==20 and plan.mass==40,"Preview accounts for next day's actual meal removal without mutation")
	p.remove(15);inventory.food-=15
	var dry: Dictionary=p.preserve(plan.input,1,true)
	inventory.food-=dry.lost
	check(dry.kept==20 and dry.salt==2 and is_equal_approx(dry.weight,14.0),"Salt and dried weight follow physical forty-pound input while meals retain all food value")
	check(is_equal_approx(p.cargo(inventory)-base,14.0),"Dried cargo reconciles with retained food")
	check(p.preserve(20,1,false).input==0,"Preserved food cannot be dried again")
	p=Provisions.new();p.add_meat(400,0)
	check(p.processable()==50 and p.fresh_mass(p.processable())==100,"Processing cap is physical pounds, not ration units")
	p=Provisions.new();p.add_fresh(20,0);p.add_meat(100,0)
	check(p.tracked_mass(70)==120,"Legacy and new batches keep distinct physical ratios")
	p.remove(25)
	check(p.tracked_mass(45)==90,"Oldest mixed-batch meal removal conserves remaining physical mass")
	var game=outfit()
	check(game.hunting_capacity()==200,"Fit willing party can share a bounded two-hundred-pound haul")
	for member in game.party_health.members:member.health=50
	check(game.hunting_capacity()==200,"Fair health retains full hunting allowance")
	game.party_health.begin_condition(1,"broken_leg",0)
	game.party_health.begin_condition(2,"broken_leg",0)
	check(game.hunting_capacity()==150,"Broken leg removes that traveler's entire hauling contribution")
	game.state.vehicle="foot"
	check(game.provisions.capacity(game.state)==150,"Walking moderates illness penalties while broken legs still remove a carrier")
	game.state.vehicle="wagon"
	check(game.provisions.capacity(game.state)==2500,"Human hauling injuries do not reduce wagon storage")
	game.party_health.members[1].conditions.clear()
	game.party_health.members[2].conditions.clear()
	for member in game.party_health.members:member.health=85
	var original: int=game.state.food
	game.state.food+=game.provisions.add_meat(100,0)
	var store=Store.new()
	var saved: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(copy!=null and store.capture(copy)==saved,"Meat value and weight round-trip together")
	for bad in [-1,0,11,"two",null]:
		var broken: Dictionary=saved.duplicate(true)
		broken.fresh[0].mass_ratio=bad
		check(store.restore(broken)==null,"Reject invalid physical mass ratio")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-meat-value-save-v1.json"))
	copy=store.restore(previous)
	check(copy!=null and copy.state==store.upgraded_state(previous.state),"Authentic pre-change save retains cash, supplies and date")
	previous=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-slaughter-save-v1.json"))
	copy=store.restore(previous)
	check(copy!=null and copy.provisions.fresh==store.normalize(previous.fresh),"Actual legacy dried batch is not repriced or reweighed on load")
	if copy!=null:
		check(copy.provisions.mass_ratio(copy.provisions.fresh[0])==float(copy.provisions.data.preservation.dried_weight),"Missing legacy ratio retains its historical dried-weight rule")
	var before_cargo: float=game.provisions.cargo(game.state)
	check(game.discard_supply("food",10) and game.state.food==original+40 and is_equal_approx(game.provisions.cargo(game.state),before_cargo-20),"Discarding meal units removes their actual meat mass")
	game.state.food=400
	game.provisions.fresh.clear()
	var old_cargo: float=game.provisions.cargo(game.state)
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
	for member in game.party_health.members:member.health=50
	game.state.health=50
	for person in game.characters.profiles.slice(1):
		person.boundaries=game.characters.catalog.boundaries("Opportunistic")
		person.trust=100
	var quote: Dictionary=game.crime.loot_quote(game,"fort_bridger")
	check(quote.wagon_access and quote.food==200,"Robbing a roadside store with wagon alongside uses its cargo room")
	game.crime.scenes.fort_bridger.wagon_access=false
	quote=game.crime.loot_quote(game,"fort_bridger")
	check(not quote.wagon_access and quote.haul_limit_lb==200 and quote.food==200,"Away from wagon, loot is bounded by health-scaled willing helpers")
	game.party_health.begin_condition(1,"broken_leg",0)
	quote=game.crime.loot_quote(game,"fort_bridger")
	check(quote.food==200,"Injured helpers cannot haul robbery food")
	for person in game.characters.profiles.slice(1):
		person.boundaries=game.characters.catalog.boundaries("Compassionate")
		person.trust=50
	quote=game.crime.loot_quote(game,"fort_bridger")
	check(quote.food==50,"Companions who forbid robbery do not carry its loot")
	check(is_equal_approx(old_cargo,game.provisions.cargo(game.state)),"Hauling previews change neither inventory nor physical cargo")
	game.crime.scenes.fort_bridger.wagon_access=true
	game.open_crime()
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("crime_command","")=="theft":
			game.choose(index)
			break
	quote=game.crime.loot_quote(game,"fort_bridger")
	check(not quote.wagon_access and quote.food<=game.hauling_capacity("robbery"),"Quiet theft requires carrying goods away even from a roadside store")
	var walking=outfit()
	walking.state.vehicle="foot"
	for member in walking.party_health.members:member.health=50
	walking.state.health=50
	var restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(walking))))
	check(restored!=null and restored.provisions.capacity(restored.state)==250,"Loaded packs derive their capacity from restored live health")
	if restored!=null:
		restored.party_health.members[0].health=100
		check(restored.provisions.capacity(restored.state)==250,"Recovery within Fair/Good keeps full pack capacity without a second stored health value")
	for member in walking.party_health.members:walking.party_health.begin_condition(int(member.id),"broken_leg",0)
	check(walking.hunting_capacity()==0 and walking.provisions.capacity(walking.state)==0,"All broken legs means no human hauling; no artificial minimum bypass")
	game=outfit()
	game.state.food+=game.provisions.add_meat(100,0)
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=game
	screen._refresh()
	screen._show_supplies()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.tools/meat-cargo-preview.png")
	print("Meat accounting: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
