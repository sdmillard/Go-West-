extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const News=preload("res://simulation/trail_news.gd")
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
## Arrive at a stop on a given day, with the guide mileage the road gives it.
func at(game,id: String,day: int):
    game.state.next_landmark=id
    game._arrive_landmark()
    game.state.miles=int(game.route.node_miles()[id])
    game.state.day=day
    return game
func section(told: Dictionary,heading: String) -> Array:
    for part in told.get("sections",[]):
        if part.heading==heading:return part.lines
    return []
func run():
    var news=News.new()
    var game=outfit()
    check(news.error=="" and news.valid_for(game.route),"News data loads and every stop it names is on the route")
    var data: Dictionary=news.data.duplicate(true)
    var bad:=data.duplicate(true)
    bad.headlines[0].known="March 1848"
    check(not news.load_data(bad) and news.data.is_empty(),"Reject a headline without a dated arrival")
    bad=data.duplicate(true)
    bad.headlines.append(bad.headlines[0].duplicate())
    check(not news.load_data(bad),"Reject duplicate headlines")
    bad=data.duplicate(true)
    bad.road["nowhere"]="A road note for a stop that does not exist."
    check(news.load_data(bad) and not news.valid_for(game.route),"A road note must name a real stop")
    check(news.load_data(data),"News data recovers after rejection")

    # News travels: the States' news reaches the Missouri border in days and Fort Hall weeks later.
    var start: Array=game.news.headlines(game)
    check(start.any(func(said):return said.contains("Louis Philippe")) and not start.any(func(said):return said.contains("Cass")),"At the start in May the border has the spring's news but not the conventions")
    check(not start.any(func(said):return said.contains("gold dust")),"California gold by way of Oregon has not reached the border in May")
    game.state.day=40
    check(game.news.headlines(game)[0].contains("Wisconsin"),"Newest arrivals come first")
    game=at(outfit(),"fort_hall",112)
    var hall: Array=game.news.headlines(game)
    check(hall.any(func(said):return said.contains("Gilliam")) and not hall.any(func(said):return said.contains("Oregon a territory")),"Fort Hall in late August has Oregon's spring news but not August's news from Washington")
    check(not hall.any(func(said):return said.contains("gold dust")),"Gold talk from Oregon has not reached Fort Hall in August")
    game.state.day=135
    check(game.news.headlines(game).any(func(said):return said.contains("gold dust")),"By mid-September gold talk has come up the road from Oregon")
    game.state.day=171
    check(game.news.headlines(game).any(func(said):return said.contains("Oregon a territory")),"Washington's August news reaches Fort Hall only in October")

    # At a post: the clerk's news, the road ahead, nothing about an innocent party, and no time or money spent.
    game=at(outfit(),"fort_hall",112)
    var day: int=game.state.day
    var money: float=game.state.money
    var rng_state: int=game.rng.state
    var journal: int=game.journal.size()
    var told: Dictionary=game.ask_news()
    check(told.kind=="post" and section(told,"FROM THE STATES AND OREGON").size()<=3 and not section(told,"FROM THE STATES AND OREGON").is_empty(),"A post's clerk passes on up to three headlines")
    var road: Array=section(told,"THE ROAD AHEAD")
    check(road.any(func(said):return said.begins_with("Snake River") or said.contains("Snake")),"The road ahead names the next stop")
    check(road.any(func(said):return said.contains("next store is at Fort Boise")),"The road ahead names the next store and its prices")
    check(section(told,"ABOUT YOUR PARTY").is_empty(),"A party with nothing to hide hears nothing about itself")
    check(game.state.day==day and game.state.money==money and game.rng.state==rng_state and game.journal.size()==journal,"Asking for news takes no time, money or chance")
    game.state.food=10
    check(section(game.ask_news(),"THE ROAD AHEAD").any(func(said):return said.contains("food lasts about")),"Short food for the road to the next store is mentioned")
    game.state.day=125
    check(section(game.ask_news(),"THE ROAD AHEAD").any(func(said):return said.contains("Blue Mountains and the Cascades")),"Late in the year the people warn of snow in the mountains")
    game.crime.record.incidents.append({"id":1,"action":"theft","place":"fort_laramie","knowledge":{}})
    check(section(game.ask_news(),"ABOUT YOUR PARTY")==["Nobody here has said anything about your party."],"A party with a past hears whether word has reached here")
    game.crime.record.incidents.clear()

    # A river ahead running high after rain.
    game=at(outfit(),"south_pass",60)
    game.survival.wet_ground=6
    var river: Array=section(game.ask_news(),"THE ROAD AHEAD")
    check(river.any(func(said):return said.contains("high water at")) or game.ask_news().is_empty(),"Wet weather warns of high water at the next river")
    check(game.news.stops_ahead(game).map(func(stop):return stop[0])==["little_sandy","green_river"],"Ahead of South Pass: the Little Sandy, then the southern road")
    game=at(outfit(),"little_sandy",62)
    check(game.news.stops_ahead(game).map(func(stop):return stop[0])==["green_river","greenwood_cutoff"],"At a fork both roads are described")

    # Passing traders tell one headline; nobody to talk to means no news.
    game=outfit()
    told=game.ask_news()
    check(told.kind=="traders" and section(told,"FROM THE STATES AND OREGON").size()<=1,"Passing traders know the road better than the news")
    game.state.day=5
    check(game.ask_news().is_empty(),"No trading party, no news")

    # The counter screen: ASK FOR NEWS swaps the goods for the news sheet and back.
    var screen=Main.instantiate()
    root.add_child(screen)
    await process_frame
    screen.departure_view.hide()
    screen.game=at(outfit(),"fort_hall",112)
    screen._open_trade()
    var view=screen.post_store_view
    check(screen.post_store_window.visible and view.kind=="post" and not view.news_panel.visible and view.news_button.text=="ASK FOR NEWS","The store counter opens on its goods")
    view.news_button.pressed.emit()
    check(view.news_panel.visible and not view.rows_layer.visible and not view.settle_button.visible and view.news_rows.get_child_count()>=4 and view.news_button.text=="BACK TO TRADING","ASK FOR NEWS shows the news sheet over the goods")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
    view.news_button.pressed.emit()
    check(not view.news_panel.visible and view.rows_layer.visible and view.settle_button.visible,"BACK TO TRADING returns to the goods")
    screen.queue_free()
    print("News checks: %d, failures: %d" % [checks,failures])
    quit(1 if failures>0 else 0)
