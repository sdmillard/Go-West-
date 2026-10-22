extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Context=preload("res://simulation/trail_context.gd")
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
func run():
    var store=Store.new()
    var context=Context.new()
    check(context.error=="","Regional data loads")
    var data: Dictionary=context.data.duplicate(true)
    for field in ["price","strain","period","wet","cold"]:
        var bad:=data.duplicate(true)
        bad.regions.sagebrush[field]=-1
        check(not context.load_data(bad) and context.data.is_empty(),"Reject negative regional "+field)
    check(context.load_data(data),"Regional data recovers after rejection")
    var game=outfit()
    var rng_before: int=game.rng.state
    check(game.context.market(game).available and game.context.market(game)==game.context.market(game) and game.rng.state==rng_before,"Inspecting opportunity neither rerolls nor spends RNG")
    for purchase in range(3):
        check(game.open_trade() and game.can_choose(0),"Initial passing stock allows purchase %d" % purchase)
        game.choose(0)
    game.open_trade()
    var before:=store.capture(game)
    check(not game.can_choose(0) and not game.choose(0) and store.capture(game)==before,"Exhausted food stock disables purchase without spending time or money")
    game.choose(game.pending.choices.size()-1)
    game.open_trade()
    check(not game.can_choose(0),"Reopening trader cannot refill exhausted stock")
    game.choose(game.pending.choices.size()-1)
    game.rest()
    game.open_trade()
    check(game.pending.title=="No traders nearby" and game.pending.choices[0].effects.days==1,"Outside the window, trading offers waiting rather than an instant store")
    var day: int=game.state.day
    var food: int=game.state.food
    game.choose(0)
    check(game.state.day==day+1 and game.state.food==food-15,"Waiting costs real time and ordinary meals")
    while game.state.day<8:game.rest()
    game.open_trade()
    check(game.pending.title=="Passing traders" and game.can_choose(0),"A later trading party has its own limited inventory")
    before=store.capture(game)
    var copy=store.restore(JSON.parse_string(JSON.stringify(before)))
    check(copy!=null and store.capture(copy)==before,"Open offers and consumed trader stock round-trip exactly")
    var bad_save:=before.duplicate(true)
    bad_save.erase("context")
    check(store.restore(bad_save)==null,"Current saves cannot erase the inventory ledger to refill stock")
    bad_save=before.duplicate(true)
    bad_save.context.spent["bad"]=-1
    check(store.restore(bad_save)==null,"Negative trader usage rejects")
    game=outfit()
    game.state.next_landmark="fort_hall"
    game._arrive_landmark()
    game.state.day=20
    game.open_trade()
    check(game.pending.title=="Trading post" and game.pending.choices[0].effects.food==200 and game.pending.choices[0].effects.money==-38,"Established post bulk price receives the trading companion's five percent discount")
    check(game.pending.choices[8].effects.money==-57.71,"Other goods retain regional price premium before the trading discount")
    for purchase in range(8):
        check(game.can_choose(0),"Finite post stock allows advertised lot")
        game.choose(0)
        game.open_trade()
    check(not game.can_choose(0),"Post inventory does not regenerate by reopening or spending days")
    game=outfit()
    game.state.next_landmark="kansas_river"
    game._arrive_landmark()
    var activity_index: int=-1
    var talk_index: int=-1
    for index in range(game.pending.choices.size()):
        if game.pending.choices[index].get("action","")=="activity":activity_index=index
        if game.pending.choices[index].has("text"):talk_index=index
    check(activity_index>=0 and talk_index>=0,"Named stop supplies contextual conversation and practical activity")
    day=game.state.day
    rng_before=game.rng.state
    game.choose(talk_index)
    check(game.state.day==day and game.rng.state==rng_before and "Inspect" in game.pending.text,"Conversation is original useful guidance without charging time or rerolling hazards")
    game.choose(activity_index)
    check(game.state.day==day+1 and game.state.medicine==1 and game.pending.landmark=="kansas_river","Preparing consumes a kit and day without leaving the stop")
    check(is_equal_approx(game.context.crossing_factor("kansas_river"),0.85) and not game.can_choose(activity_index),"Preparation has a bounded real effect and cannot be farmed repeatedly")
    before=store.capture(game)
    copy=store.restore(JSON.parse_string(JSON.stringify(before)))
    check(copy!=null and store.capture(copy)==before,"Prepared crossing and one-time activity survive saves")
    bad_save=before.duplicate(true)
    bad_save.pending.choices[activity_index].erase("activity")
    check(store.restore(bad_save)==null,"Incomplete saved activity rejects before engine dispatch")
    bad_save=before.duplicate(true)
    bad_save.context.prepared.append("oregon_city")
    check(store.restore(bad_save)==null,"Impossible preparation record rejects")
    game=outfit()
    game.state.next_landmark="grande_ronde"
    game._arrive_landmark()
    game.state.ox_health=50
    for index in range(game.pending.choices.size()):
        if game.pending.choices[index].get("action","")=="activity":
            game.choose(index)
            break
    check(game.state.ox_health==62 and game.state.day==1 and game.pending.landmark=="grande_ronde","Meadow activity gives normal rest plus eight team-condition points, stays at stop")
    game=outfit()
    game.state.next_landmark="fort_hall"
    game._arrive_landmark()
    game.pending={}
    game.state.day=70
    game._tick_day(false,true)
    check(game.state.ox_health==98,"Summer sagebrush travel applies daily forage strain")
    game.rest()
    check(game.state.ox_health>98,"Rest restores a strained team")
    var wet_counts: Dictionary={}
    for id in ["sagebrush","forest"]:
        var rules=Simulation.Survival.new()
        rules.start(44)
        var wet:=0
        for trial in range(1000):
            rules.advance(6,"plains",data.regions[id])
            if rules.weather.id in ["rain","heavy_rain","fog"]:wet+=1
        wet_counts[id]=wet
    check(wet_counts.forest>wet_counts.sagebrush,"Regional weights produce a wetter forest sample than sage country with matched seeds")
    var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-regional-save-v1.json"))
    copy=store.restore(previous)
    check(copy!=null and copy.state==store.normalize(previous.state) and copy.context.record=={"spent":{},"activities":[],"prepared":[]},"Real pre-regional save migrates without altering animals, time, cash or supplies")
    var screen=Main.instantiate()
    root.add_child(screen)
    await process_frame
    screen.departure_view.hide()
    screen.game=outfit()
    screen._open_trade()
    check(screen.game.pending.choices[0].has("market_key"),"Actual available trade screen carries stock-controlled offers")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/trader-stock.png")
    screen._cancel_service()
    screen.game.state.day=5
    screen._open_trade()
    check(screen.service_window.visible and screen.game.pending.title=="No traders nearby","Actual trade UI opens the unavailable-trader choice")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/trader-wait.png")
    screen.service_window.hide()
    screen.game=outfit()
    screen.game.state.next_landmark="kansas_river"
    screen.game._arrive_landmark()
    screen._refresh()
    screen._show_stop_activities()
    check(screen.stop_window.visible and screen.stop_rows.get_child_count()>=4,"Local conditions menu exposes actual stop activities without scrolling the travel pane")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/landmark-activities.png")
    screen.stop_rows.get_child(screen.stop_rows.get_child_count()-1).pressed.emit()
    check(not screen.stop_window.visible and screen.game.state.medicine==1 and screen.game.pending.landmark=="kansas_river","Activity menu button performs actual preparation and remains at the crossing")
    screen._show_stop_activities()
    screen._new_journey()
    check(not screen.stop_window.visible,"New journey closes stale local activity dialog")
    screen.queue_free()
    await process_frame
    print("Regional context: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)

