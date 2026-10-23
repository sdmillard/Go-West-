extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const News=preload("res://simulation/trail_news.gd")
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
## Arrive at a stop on a given day, with the guide mileage the road gives it.
func at(game,id: String,day: int):
    game.state.next_landmark=id
    game._arrive_landmark()
    game.state.miles=int(game.route.node_miles()[id])
    game.state.day=day
    return game
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

    # At a post: the clerk's news, the road ahead, nothing about an innocent party.
    game=at(outfit(),"fort_hall",112)
    var headline_texts: Array=game.news.data.headlines.map(func(item):return item.text)
    var told: Array=game.news.fragments(game,"post","fort_hall")
    var heard: int=told.filter(func(said):return said in headline_texts).size()
    check(heard>0 and heard<=3,"A post's clerk passes on up to three headlines")
    check(told.has(game.news.data.road.snake_river),"The road ahead describes the next stop")
    check(told.any(func(said):return said.contains("next store is at Fort Boise")),"The road ahead names the next store and its prices")
    check(not told.any(func(said):return said.contains("your party")),"A party with nothing to hide hears nothing about itself")
    game.state.food=10
    check(game.news.fragments(game,"post","fort_hall").any(func(said):return said.contains("food lasts about")),"Short food for the road to the next store is mentioned")
    game.state.day=125
    check(game.news.fragments(game,"post","fort_hall").any(func(said):return said.contains("Blue Mountains and the Cascades")),"Late in the year the people warn of snow in the mountains")
    game.crime.record.incidents.append({"id":1,"action":"theft","place":"fort_laramie","knowledge":{}})
    check(game.news.fragments(game,"post","fort_hall").has("Nobody here has said anything about your party."),"A party with a past hears whether word has reached here")
    game.crime.record.incidents.clear()

    # Asking: one fragment at a time, a fair clerk answers three times, and it costs nothing else.
    game=at(outfit(),"fort_hall",112)
    var day: int=game.state.day
    var money: float=game.state.money
    var rng_state: int=game.rng.state
    var journal: int=game.journal.size()
    check(game.news_left()==3,"A post's clerk is fair: three questions")
    var answers: Array=[]
    for ask in range(3):answers.append(game.ask_news())
    told=game.news.fragments(game,"post","fort_hall")
    check(answers.all(func(said):return said in told) and answers[0]!=answers[1] and answers[1]!=answers[2] and answers[0]!=answers[2],"Each ask tells a different fragment of what they know")
    check(game.news_left()==0 and game.ask_news()=="","After three answers the clerk says no more")
    check(game.state.day==day and game.state.money==money and game.rng.state==rng_state and game.journal.size()==journal,"Asking for news takes no time, money or chance")
    var copy=Store.new().restore(Store.new().capture(game))
    check(copy!=null and copy.news_left()==0,"Questions asked at a counter round-trip through a save")
    var again=at(outfit(),"fort_hall",112)
    check(again.ask_news()==answers[0],"The same journey hears the same first fragment")

    # A river ahead running high after rain.
    game=at(outfit(),"south_pass",60)
    game.survival.wet_ground=6
    check(game.news.road_ahead(game).any(func(said):return said.contains("high water at")),"Wet weather warns of high water at the next river")
    check(game.news.stops_ahead(game).map(func(stop):return stop[0])==["little_sandy","green_river"],"Ahead of South Pass: the Little Sandy, then the southern road")
    game=at(outfit(),"little_sandy",62)
    check(game.news.stops_ahead(game).map(func(stop):return stop[0])==["green_river","greenwood_cutoff"],"At a fork both roads are described")

    # Passing traders talk as freely as their mood; nobody to talk to means no news.
    game=outfit()
    var traders: Dictionary=game.trade_counter()
    check(game.news_left()==int(game.news.data.asks[traders.mood]),"Passing traders answer as many times as their mood allows")
    check(game.news.fragments(game,"traders",traders.key).filter(func(said):return said in headline_texts).size()<=1,"Passing traders know the road better than the news")
    game.state.day=5
    check(game.news_left()==0 and game.ask_news()=="","No trading party, no news")

    # The counter screen: ASK FOR NEWS shows a speech bubble over the picture and counts down.
    var screen=Main.instantiate()
    root.add_child(screen)
    await process_frame
    screen.departure_view.hide()
    screen.game=at(outfit(),"fort_hall",112)
    screen._open_trade()
    var view=screen.post_store_view
    check(screen.post_store_window.visible and view.kind=="post" and not view.bubble.visible and view.news_button.text=="ASK FOR NEWS (3)","The store counter offers three questions")
    view.news_button.pressed.emit()
    check(view.bubble.visible and not view.bubble.text.text.is_empty() and view.rows_layer.visible and view.news_button.text=="ASK FOR NEWS (2)","ASK FOR NEWS shows a fragment in a speech bubble beside the goods")
    check(view.bubble.panel.position.x+view.bubble.panel.size.x<=244 and view.bubble.panel.position.y>=0,"The bubble stays over the picture")
    view.news_button.pressed.emit()
    view.news_button.pressed.emit()
    check(view.news_button.disabled and view.news_button.text=="NO MORE NEWS","The button closes when they have said all they will")
    view.open(view.venue)
    check(not view.bubble.visible and view.news_button.disabled,"Reopening the counter clears the bubble but not the questions spent")
    view.open(view.venue)
    screen._close_post_store()

    # An emigrant camp: ASK FOR NEWS on the camp menu itself, sharing its questions with the family's counter.
    game=outfit()
    var camp_place:=""
    for day_index in range(200):
        game.state.day=day_index
        if not game.crime.camp(game).is_empty():
            camp_place=game.crime.camp(game)
            break
    screen.game=game
    screen._open_camp()
    var ask: int=-1
    for index in range(game.pending.choices.size()):
        if game.pending.choices[index].has("news"):ask=index
    check(ask>=0 and not game.pending.choices.any(func(choice):return str(choice.get("label","")).begins_with("Share news")),"The camp menu has one way to ask for news")
    var allowed: int=game.news_left("camp")
    screen._service_choice(ask)
    check(screen.service_window.visible and not game.last_news.is_empty() and game.news_left("camp")==allowed-1 and game.state.day==camp_day_of(game),"Asking on the camp menu answers in place and spends a question")
    check(_find_bubble(screen.service_rows)!=null and _find_bubble(screen.service_rows).visible,"The family's answer shows as a speech bubble on the camp picture")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
    if allowed>1:
        screen.service_window.hide()
        screen._open_counter("camp")
        check(screen.post_store_view.news_button.text=="ASK FOR NEWS (%d)" % (allowed-1),"The family's counter shares the camp menu's questions")
        screen._close_post_store()
    screen.queue_free()
    print("News checks: %d, failures: %d" % [checks,failures])
    quit(1 if failures>0 else 0)

func camp_day_of(game) -> int:
    return int(game.state.day)
func _find_bubble(node: Node):
    for child in node.get_children():
        if child.get_script()==preload("res://ui/speech_bubble.gd"):return child
        var found=_find_bubble(child)
        if found!=null:return found
    return null
