extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
const PACK={"food":80,"clothing":5,"bullets":20,"medicine":1,"salt":1}
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit():
	var game=Simulation.new(57,"classic",true)
	game.depart("farmer",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
	for member in game.party_health.members:member.health=100
	game.state.health=100
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.seen.append("muddy_trail")
	return game
func run():
	var store=Store.new()
	var game=outfit()
	var before:=store.capture(game)
	check(not game.abandon_wagon({"food":500}) and store.capture(game)==before,"Overweight pack rejects without transferring goods or spending time")
	check(not game.abandon_wagon({"free_money":1}) and store.capture(game)==before,"Unknown pack item rejects atomically")
	var offer:=game.pack_quote(PACK)
	check(offer.valid and offer.capacity_lb==200 and offer.cargo_lb==190,"Five survivors can carry two hundred pounds including seventy-five pounds personal gear")
	check(game.abandon_wagon(PACK) and game.state.vehicle=="foot" and game.state.day==1 and game.state.food==65,"Packing costs one day and ordinary rations")
	check(game.wagon_cache.inventory.food+game.state.food==585 and game.wagon_cache.inventory.bullets+game.state.bullets==200,"Cached and carried stock conserves goods apart from meals")
	check(game.wagon_cache.inventory.wheels==1 and game.state.wheels==0 and game.state.money==before.state.money,"Heavy spares stay in cache while money stays with party")
	check(not game.abandon_wagon(PACK),"Cannot abandon a second wagon while already walking")
	var heavy=outfit()
	heavy.abandon_wagon(PACK)
	heavy.state.food+=100
	var heavy_day: int=heavy.state.day
	heavy.travel()
	check(heavy.pending.get("id","")=="packs_too_heavy" and heavy.state.day==heavy_day and heavy.state.miles==0,"Later acquisitions cannot bypass the hard human carry limit")
	heavy.choose(0)
	heavy.discard_supply("food",100)
	heavy.travel()
	check(heavy.state.miles>0,"Dropping excess stock restores walking without destroying unrelated supplies")
	game.state.oxen=0
	check(game.travel() and game.state.miles>0 and game.state.vehicle=="foot","Walking continues with no animals")
	check(not game.wagon_cache.found,"Leaving the location exposes the cached wagon")
	game.state.oxen=1
	game.provisions.data.walking.cache_loss_base=0
	game.provisions.data.walking.cache_loss_daily=0
	check(game.recover_wagon() and game.state.vehicle=="wagon" and game.state.miles==0 and game.wagon_cache.is_empty(),"Recovery actually backtracks to the cache and restores wagon with one ox")
	check(game.state.day==4 and game.state.food==540 and game.state.wheels==1 and game.state.bullets==200,"Return travel and hitching consume meals without duplicating cached stock")
	game=outfit()
	game.CacheSupport.relocate(game,20)
	game.abandon_wagon(PACK)
	game.CacheSupport.relocate(game,55)
	game.wagon_cache.found=false
	game.provisions.data.walking.cache_loss_base=0
	game.provisions.data.walking.cache_loss_daily=0
	check(game.recover_wagon() and game.state.miles==20 and game.state.landmark=="independence" and game.state.leg_miles==20,"Backtracking across multiple route legs restores the correct mile and next landmark")
	game=outfit()
	game.abandon_wagon(PACK)
	game.travel()
	game.provisions.data.walking.cache_loss_base=1
	game.provisions.data.walking.cache_loss_cap=1
	check(game.recover_wagon() and game.state.vehicle=="foot" and game.wagon_cache.is_empty(),"Forced cache loss is permanent and does not grant its inventory")
	check(game.state.miles==0 and game.state.wheels==0,"Failed search still costs real backtracking progress")
	game=outfit()
	game.state.oxen=0
	game.abandon_wagon(PACK)
	check(game.recover_wagon() and game.state.vehicle=="foot" and game.wagon_cache.found,"Returning without oxen finds storage but cannot hitch wagon")
	var total: int=game.state.food+game.wagon_cache.inventory.food
	check(game.repack_wagon_cache({"food":120}) and game.state.food==120 and game.state.food+game.wagon_cache.inventory.food==total,"Repacking from cache transfers goods within pack limit")
	game.open_trade()
	game.choose(18)
	check(game.state.oxen==1 and game.recover_wagon() and game.state.vehicle=="wagon","Trading cached food for an animal allows actual wagon recovery")
	game=outfit()
	game.provisions.add_fresh(100,0)
	game.abandon_wagon({"clothing":1})
	game.rest()
	game.rest()
	check(game.recover_wagon() and game.state.food==485,"Food continues aging in cache and expired meat cannot be rescued")
	game=outfit()
	game.abandon_wagon(PACK)
	game.travel()
	game.party_health.daily_onset_chance=0.03
	game.survival.data.event_chance=0.18
	game.survival.forced_weather=""
	before=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(before)))
	check(copy!=null and store.capture(copy)==before,"Walking mode, pack, cache location and cache inventory survive saves")
	if copy!=null:
		check(game.recover_wagon()==copy.recover_wagon() and store.capture(game)==store.capture(copy),"Save/load preserves cache-risk outcome and return journey exactly")
	var bad:=before.duplicate(true)
	bad.wagon_cache.inventory.food=-1
	check(store.restore(bad)==null,"Malformed negative cache inventory rejects")
	bad=before.duplicate(true)
	bad.wagon_cache.mile=game.destination()+1
	check(store.restore(bad)==null,"Impossible cache location rejects")
	game=outfit()
	game.abandon_wagon(PACK)
	game.state.oxen=0
	game.state.next_landmark="kansas_river"
	game._arrive_landmark()
	check(game.pending.choices.any(func(c):return c.get("method","")=="swim") and not game.pending.choices.any(func(c):return c.get("method","")=="float"),"Walkers swim or use ferry rather than float an absent wagon")
	check(game.pending.choices.any(func(c):return c.get("method","")=="ferry" and not c.has("risk")),"Available ferry remains an accident-free alternative for walkers")
	game.survival.wet_ground=0
	game._update_river_stage()
	check(game.swimming_risk()==0.3 and "swimming" in game.pending.text.to_lower(),"Low-water swimming has thirty percent risk and foot-specific warning")
	game.survival.wet_ground=4
	game._update_river_stage()
	check(game.swimming_risk()==0.8 and game.pending.choices.any(func(c):return c.get("method","")=="swim" and c.risk==0.8),"High water raises swim risk above both wagon methods")
	before=store.capture(game)
	copy=store.restore(JSON.parse_string(JSON.stringify(before)))
	check(copy!=null and store.capture(copy)==before,"Pending swim and ferry choices survive a save exactly")
	var legacy:=before.duplicate(true)
	for choice in legacy.pending.choices:
		if choice.get("method","")=="swim":choice.method="wade"
	copy=store.restore(legacy)
	check(copy!=null and copy.pending.choices.any(func(c):return c.get("method","")=="swim" and c.risk==0.8) and copy.rng.state==game.rng.state,"Old pending wading offer upgrades without rerolling randomness")
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("method","")=="swim":
			game.pending.choices[index].risk=0
			game.choose(index)
			break
	check(game.last_crossing.method=="swim" and "swimming" in game.last_crossing.summary,"Foot crossing resolves and has appropriate history")
	game=outfit()
	game.abandon_wagon(PACK)
	game.state.next_landmark="kansas_river"
	game._arrive_landmark()
	var member_health: int=game.party_health.members[0].health
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("method","")=="swim":
			game.pending.choices[index].risk=1
			game.choose(index)
			break
	check(game.last_crossing.mishap and game.last_crossing.food_lost==30 and game.last_crossing.clothing_lost==1,"Swim mishap records exact supplies separately from crossing-day meals")
	check(game.party_health.members[0].health<member_health and game.last_crossing.health_lost==15,"Swimming accident injures individual travelers through existing health mechanics")
	check(game.crossing_history.back().method=="swim" and game.journal.any(func(entry):return "swimming with packs" in entry and "Lost 30 lb" in entry),"Swimming failure enters dated crossing history and journal")
	before=store.capture(game)
	copy=store.restore(JSON.parse_string(JSON.stringify(before)))
	check(copy!=null and store.capture(copy)==before,"Completed swimming accident and its losses survive saves")
	var ferry_game=outfit()
	ferry_game.abandon_wagon(PACK)
	ferry_game.state.next_landmark="kansas_river"
	ferry_game._arrive_landmark()
	var ferry_cash: float=ferry_game.state.money
	var ferry_day: int=ferry_game.state.day
	var ferry_price:=0.0
	for index in range(ferry_game.pending.choices.size()):
		if ferry_game.pending.choices[index].get("method","")=="ferry":
			ferry_price=ferry_game.pending.choices[index].requires.money
			ferry_game.choose(index)
			break
	check(ferry_game.last_crossing.method=="ferry" and not ferry_game.last_crossing.mishap and ferry_game.state.vehicle=="foot","Walking ferry avoids swimming injuries without restoring a wagon")
	check(ferry_game.state.day==ferry_day+1 and is_equal_approx(ferry_cash-ferry_game.state.money,ferry_price),"Foot ferry charges the advertised fare and crossing day")
	game.state.oxen=0
	game.state.next_landmark="barlow_pass"
	game._arrive_landmark()
	check(game.pending.choices[0].requires.money==0,"No wagon tariff charged to people walking without stock")
	game=outfit()
	game.CacheSupport.relocate(game,1930)
	game.state.oxen=0
	game.abandon_wagon(PACK)
	game.travel()
	check(game.state.status=="arrived" and game.state.miles==1938,"A walking party can finish the route rather than becoming a permanent dead-end mode")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	screen._refresh()
	screen._show_supplies()
	screen._show_packing()
	await process_frame
	check(screen.packing_window.visible and not screen.packing_window.get_ok_button().disabled,"Packing screen provides a valid default pack")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/walking-packs.png")
	screen.packing_window.confirmed.emit()
	check(screen.game.state.vehicle=="foot" and screen.game.provisions.cargo(screen.game.state)<=200,"Actual pack confirmation transfers selected goods and switches mode")
	screen.supplies_window.hide()
	screen.game.travel()
	screen._refresh()
	check(screen.landscape.vehicle=="foot" and "ON FOOT" in screen.stats.text,"Interface and travel renderer show walking mode")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/walking-travel.png")
	screen.game.state.next_landmark="kansas_river"
	screen.game._arrive_landmark()
	screen._refresh()
	for index in range(screen.game.pending.choices.size()):
		if screen.game.pending.choices[index].get("method","")=="swim":
			screen.game.pending.choices[index].risk=0
			screen._choose(index)
			break
	check(not screen.landscape.crossing.is_empty() and "packs" in screen.event_text.text,"Foot crossing reaches the actual animation and appropriate interface text")
	screen.landscape.crossing_paused=true
	screen.landscape.crossing_elapsed=screen.landscape.crossing_duration*0.5
	before=store.capture(screen.game)
	screen.landscape._process(0.1)
	check(store.capture(screen.game)==before and screen.landscape.crossing.method=="swim","Swimming animation is presentation-only and contains no wagon crossing")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/swimming-crossing.png")
	screen.landscape.crossing.mishap=true
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/swimming-mishap.png")
	screen.queue_free()
	await process_frame
	print("Walking/cache: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
