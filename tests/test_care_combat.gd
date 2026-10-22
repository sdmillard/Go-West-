extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(value: bool,message: String):
    checks+=1
    if not value:
        failures+=1
        printerr("FAIL: "+message)
func outfit():
    var game=Simulation.new(57,"classic",true)
    game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
    game.seen.append("muddy_trail")
    game.party_health.daily_onset_chance=0
    game.survival.data.event_chance=0
    game.survival.forced_weather="clear"
    return game
func encounter(game,id: String="bandits"):
    game.pending={}
    for event in game.trail_events.events:
        if event.id==id:
            game._present_trail_event(event)
            return
func run():
    var store=Store.new()
    var game=outfit()
    game.open_care()
    check(game.pending.choices.any(func(c):return c.get("care",0)==6) and not game.pending.choices.any(func(c):return c.get("care",0)==12),"Road care offers kits but no magically available paid practitioner")
    game.choose(game.pending.choices.size()-1)
    game.state.next_landmark="fort_laramie"
    game._arrive_landmark()
    game.open_care()
    var paid: int=-1
    for index in range(game.pending.choices.size()):
        if game.pending.choices[index].get("care",0)==12:paid=index
    check(paid>=0 and game.can_choose(paid),"Selected stopped post offers local help")
    var cash: float=game.state.money
    game.choose(paid)
    check(game.state.money==cash-20 and game.state.day==1 and game.pending.landmark=="fort_laramie","Local care charges money, day and meals and returns to stop")
    game=outfit()
    game.open_care()
    game.pending.choices[0]["care"]=12
    check(not game.can_choose(0),"Old or injected paid offer cannot be used on the open road")
    game=outfit()
    var base: float=game.combat.risk(game,"defend",0.25)
    check(is_equal_approx(base,0.25),"Healthy novice defense injury chance is twenty-five percent")
    for member in game.party_health.members:member.health=30
    game.state.health=30
    check(game.combat.risk(game,"defend",0.25)>base,"Poor health and fewer able defenders increase risk")
    game=outfit()
    for index in range(10):game.combat.history.append({"day":0,"event":"bandits","tactic":"defend","outcome":"won","victim":0,"risk":0.25})
    check(is_equal_approx(game.combat.risk(game,"defend",0.25),0.19),"Experience benefit caps at three wins rather than making combat safe")
    check(game.combat.risk(game,"circle",0.15)>0,"Circling never becomes an injury-free choice")
    game.combat.history.clear()
    game.combat.history.append({"day":0,"event":"riders","tactic":"defend","outcome":"friendly","victim":0,"risk":0.25})
    check(game.combat.victories()==0,"Friendly encounters do not farm combat experience")
    encounter(game)
    check("25% injury risk" in game.pending.choices[1].label and game.pending.choices[1].risk.severity==2,"Defense offer explicitly shows injury risk and serious-wound consequence")
    var offer_save:=store.capture(game)
    var offer_copy=store.restore(JSON.parse_string(JSON.stringify(offer_save)))
    check(offer_copy!=null and store.capture(offer_copy)==offer_save,"Pending injury quote, hidden intentions and random state survive loading unchanged")
    var malformed_offer:=offer_save.duplicate(true)
    malformed_offer.pending.choices[1].risk.victim_damage=-20
    check(store.restore(malformed_offer)==null,"Invalid negative personal damage rejects before combat dispatch")
    var victim_id: int=game.pending.member_id
    var old_health: int=game.party_health.members[victim_id].health
    game.pending.choices[1].risk.probability=1
    game.choose(1)
    check(game.state.bullets==190 and game.party_health.members[victim_id].health==old_health-20,"Forced defense injury spends ten bullets and immediately hurts only the selected traveler")
    check(game.party_health.members[victim_id].conditions.any(func(c):return c.id=="wound" and c.severity==2),"Defense creates a serious persistent wound")
    check(game.combat.history.back().outcome=="injured" and game.combat.victories()==0,"Wounded outcome is recorded and grants no clean victory")
    var snapshot:=store.capture(game)
    var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
    check(copy!=null and store.capture(copy)==snapshot,"Combat outcome, wound and journal survive save/load exactly")
    for day in range(8):game._tick_day(false,true)
    check(not game.party_health.members[victim_id].alive and game.party_health.members[victim_id].cause=="wound","Untreated serious wound can kill even a previously healthy defender")
    game=outfit()
    encounter(game)
    victim_id=game.pending.member_id
    game.party_health.members[victim_id].health=10
    game.state.health=game.party_health.average_health()
    game.pending.choices[1].risk.probability=1
    game.choose(1)
    check(not game.party_health.members[victim_id].alive and game.state.party_size==4 and game.party_health.members[victim_id].cause=="confrontation injuries","Impact can kill a weak defender immediately and updates living party size")
    game=outfit()
    encounter(game)
    game.pending.choices[1].risk.probability=0
    game.choose(1)
    check(game.combat.history.back().outcome=="won" and game.combat.victories()==1,"A clean hostile defense records a real victory")
    game=outfit()
    encounter(game,"riders")
    game.pending["friendly"]=true
    game.pending.choices[1].risk.probability=0
    game.choose(1)
    check(game.combat.history.back().outcome=="friendly" and game.combat.victories()==0,"Friendly rider resolution remains harmless but spends the chosen ammunition")
    game=outfit()
    encounter(game,"riders")
    game.pending.erase("friendly")
    game.pending.choices[3].risk.probability=1
    game.choose(3)
    check(game.state.day==1 and game.state.bullets==195 and game.combat.history.back().outcome=="injured","Circling costs five bullets and one fed day, with its own actual injury roll")
    var bad:=store.capture(game)
    bad.combat_history[0].risk=-1
    check(store.restore(bad)==null,"Invalid combat history rejects")
    var combat_data: Dictionary=game.combat.data.duplicate(true)
    combat_data.defense_floor=0
    check(not game.combat.load_data(combat_data),"Rules cannot accidentally make experienced defense risk-free")
    game=outfit()
    var before:=store.capture(game)
    check(game.provisions.forecast_days(1000,5,2,0)==3 and store.capture(game)==before,"Three-day supply forecast does not mutate inventory or random state")
    game.provisions.fresh.assign([{"pounds":1000,"expires":1}])
    check(game.provisions.forecast_days(1000,5,2,0)==0,"Forecast includes meat spoiling before tomorrow's meals")
    game.provisions.fresh.clear()
    check(game.provisions.forecast_days(44,5,2,0)==2,"Food forecast catches the two-full-day threshold before starvation")
    var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-care-combat-save-v1.json"))
    copy=store.restore(previous)
    check(copy!=null and copy.state==store.normalize(previous.state) and copy.combat.history.is_empty(),"Actual pre-care/combat save migrates with state intact and no invented victories")
    var screen=Main.instantiate()
    root.add_child(screen)
    await process_frame
    screen.departure_view.hide()
    screen.game=outfit()
    encounter(screen.game)
    screen._refresh()
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/defense-risk.png")
    screen.game=outfit()
    screen.game.state.food=23
    screen._refresh()
    before=store.capture(screen.game)
    screen.traveling=true
    screen._advance_day()
    check(not screen.traveling and screen.food_notice.visible and store.capture(screen.game)==before,"Low-food warning pauses automatic travel before another day or resource loss")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/food-warning.png")
    screen.food_notice.hide()
    check(not screen._warn_food(),"Acknowledged low-food warning does not repeat on every click")
    screen.game.state.food=0
    before=store.capture(screen.game)
    check(screen._warn_food() and screen.food_notice.visible and store.capture(screen.game)==before,"Empty food escalates to a separate starvation warning without spending a day")
    screen.food_notice.hide()
    screen.game=outfit()
    screen.last_food_alert=0
    screen._open_care()
    check(not screen.game.pending.choices.any(func(c):return c.get("care",0)==12),"Actual care interface hides paid roadside medical attention")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/roadside-care.png")
    screen.queue_free()
    await process_frame
    print("Care/combat/warnings: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
