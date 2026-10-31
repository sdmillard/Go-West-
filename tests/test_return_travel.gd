extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func outfit():
 var game=Simulation.new(57,"classic",true)
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 check(game.depart("banker",["Lead","A","B","C","D"],5,cart),"Party outfits legally")
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 game.party_health.daily_onset_chance=0
 for event in game.catalog.events:game.seen.append(event.id)
 game.configure(0,2)
 return game
func action(game,kind: String) -> bool:
 for i in range(game.pending.get("choices",[]).size()):
  if game.pending.choices[i].get("action","")==kind and game.can_choose(i):return game.choose(i)
 return false
func ack(game):
 if not game.pending.is_empty() and not game.pending.has("landmark"):game.choose(0)
func trip(game,message: String):
 var store=Store.new()
 var snap: Dictionary=store.capture(game)
 var copy=store.restore(JSON.parse_string(JSON.stringify(snap)))
 check(copy!=null,message)
 if copy!=null:check(store.capture(copy)==snap,message+" exact")
 return copy
func reach(game,id: String):
 for n in range(300):
  if game.pending.get("landmark","")==id:return
  if game.pending.has("landmark"):
   if game.route.nodes[game.state.landmark].kind=="river":
    game.pending.choices[0].risk=0.0
    action(game,"cross")
   else:action(game,"leave")
  elif not game.pending.is_empty():game.choose(0)
  else:game.travel()
 check(false,"Reach "+id+" within action bound")
func run():
 var game=outfit()
 var before: Dictionary=Store.new().capture(game)
 check(game.turn_direction("east") and game.state.day==0 and game.state.miles==0,"Turning changes heading without teleporting or spending a day")
 check(game.travel() and game.state.status=="returned_east" and game.state.day==1,"Travel beyond Independence ends peacefully after a real trail day")
 trip(game,"Eastward ending saves")
 game=outfit()
 game.travel()
 var mile: int=game.state.miles
 var food: int=game.state.food
 var day: int=game.state.day
 check(mile>0 and game.turn_direction("east"),"Turn around mid-leg")
 check(game.state.miles==mile and game.state.food==food and game.state.day==day,"Turn itself changes no resources or position")
 trip(game,"Mid-leg eastward save")
 for n in range(10):
  if game.pending.has("landmark"):break
  ack(game)
  if game.pending.is_empty():game.travel()
 check(game.state.landmark=="independence" and game.state.miles==0 and game.pending.has("landmark"),"Eastward travel returns to Independence normally")
 check(game.state.day>day and game.state.food<food,"Return journey spends days and meals")
 check(game.turn_direction("west") and action(game,"leave"),"Turn west again at Independence")
 reach(game,"elm_grove")
 check(game.turn_direction("east") and action(game,"leave"),"Leave a revisited stop eastward")
 check(game.state.next_landmark=="elm_grove" and game.state.landmark=="independence" and game.state.leg_miles==33,"Reverse leg retains valid geographic coordinates")
 trip(game,"Reverse leg saves")
 game=outfit()
 reach(game,"wakarusa")
 var crossings: int=game.crossing_history.size()
 check(game.turn_direction("east") and not game.pending.choices.any(func(c):return c.get("action","")=="cross"),"Turning away before a crossing does not require crossing first")
 check(action(game,"leave") and game.crossing_history.size()==crossings,"Retreat from river spends no phantom crossing")
 game=outfit()
 reach(game,"wakarusa")
 game.pending.choices[0].risk=0.0
 check(action(game,"cross"),"First actual crossing")
 crossings=game.crossing_history.size()
 check(game.turn_direction("east") and game.travel() and game.pending.has("landmark"),"Return immediately to the river bank")
 check(game.pending.choices.any(func(c):return c.get("action","")=="cross"),"Coming back from the far bank requires another crossing")
 game.pending.choices[0].risk=0.0
 check(action(game,"cross") and game.crossing_history.size()==crossings+1,"Return crossing has an actual day and history entry")
 trip(game,"Repeated crossing saves")
 game=outfit()
 reach(game,"elm_grove")
 action(game,"leave")
 game.travel()
 var cache_mile: int=game.state.miles
 check(game.abandon_wagon({"food":60,"clothing":5,"bullets":10}),"Leave an actual stocked wagon")
 ack(game)
 check(game.turn_direction("east"),"Walk east away from the cached wagon")
 for n in range(15):
  if game.pending.has("landmark"):break
  ack(game)
  if game.pending.is_empty():game.travel()
 check(game.state.miles<cache_mile,"Wagon can lie west of the returning party")
 trip(game,"Cache ahead of current mileage saves")
 check(game.turn_direction("west") and action(game,"leave"),"Return west toward the marked wagon")
 for n in range(20):
  if game.Direction.at_cache(game):break
  ack(game)
  if game.pending.is_empty():game.travel()
 check(game.state.miles==cache_mile and game.Direction.at_cache(game),"Normal movement stops exactly at the cache rather than overshooting")
 ack(game)
 game.wagon_cache.found=true
 check(game.inspect_cached_wagon() and game.state.vehicle=="wagon" and game.wagon_cache.is_empty(),"Inspect and recover only at the actual wagon position")
 trip(game,"Recovered wagon saves")
 # Fixture at a known fork; subsequent branch and reverse movement are real.
 game=outfit()
 game.route_path=game.route.main_path_to("little_sandy")
 game.state.landmark="little_sandy"
 game.state.next_landmark="little_sandy"
 game.state.miles=int(game.route.node_miles()["little_sandy"])
 game.pending={}
 game._arrive_landmark(true,false)
 var fork_choice: int=-1
 for index in range(game.pending.choices.size()):
  if int(game.pending.choices[index].get("edge",0))==1:fork_choice=index
 check(fork_choice>=0 and game.choose(fork_choice),"Choose actual Greenwood cutoff")
 reach(game,"greenwood_cutoff")
 check(game.turn_direction("east") and action(game,"leave"),"Retreat from the cutoff before crossing")
 check(game.state.landmark=="little_sandy" and game.state.next_landmark=="greenwood_cutoff","East retraces chosen branch rather than inventing the main road")
 trip(game,"Reverse branch saves")
 game=outfit()
 game.route_path=game.route.main_path_to("barlow_pass")
 game.state.landmark="barlow_pass"
 game.state.next_landmark="barlow_pass"
 game.state.miles=int(game.route.node_miles()["barlow_pass"])
 game.pending={}
 game._arrive_landmark(true,false)
 check(game.turn_direction("east"),"Turn away from Barlow toll before passing")
 var purse: float=game.state.money
 check(action(game,"leave") and game.state.money==purse,"Turning away before using the toll road does not charge a phantom toll")
 game=outfit()
 game.route_path=game.route.main_path_to("the_dalles")
 game.state.landmark="the_dalles"
 game.state.next_landmark="columbia_raft"
 game.state.leg_length=40
 game.state.leg_miles=1
 game.state.miles=int(game.route.node_miles()["the_dalles"])+1
 check(not game.turn_direction("east"),"Downstream Columbia raft cannot travel upstream as an invented road")
 # Save validators must not assume every old incident remains east of the party.
 game=outfit()
 game.CacheSupport.relocate(game,20)
 game.party_health.kill(game.party_health.members[1],0,"illness")
 game.state.party_size=game.party_health.living_count()
 game.state.health=game.party_health.average_health()
 game.Remains.sync(game)
 game.CacheSupport.relocate(game,0)
 game.turn_direction("east")
 trip(game,"Remains west of current position remain valid after turning east")
 var corrupt: Dictionary=Store.new().capture(game)
 corrupt.state.travel_direction="north"
 check(Store.new().restore(corrupt)==null,"Invalid travel heading rejects")
 # Both previous produce and bandit checkpoints migrate as full-route economies.
 for signature in ["70ef4aad8342b811479b0122dc1411ba920da95bfdcf7f169d0753110a4391eb","aecf61d91b46ad7eb2924872f40becc9b4b29a1ebb9768cb34dfd836c7c8f2eb"]:
  game=outfit()
  var old: Dictionary=Store.new().capture(game)
  old.rules=signature
  var migration=Store.new()
  var loaded=migration.restore(old)
  check(loaded!=null and not migration.load_note.contains("opening"),"Published checkpoints preserve full-route position and economy")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.game=outfit()
 screen._show_section("Travel")
 check(screen.section_rows.get_node_or_null("TravelDirection")!=null,"Actual Travel menu exposes direction control")
 screen.section_window.hide()
 screen.game.turn_direction("east")
 screen.game.travel()
 screen._refresh()
 check(screen.event_title.text=="Back east." and screen.event_text.text.begins_with("Your character decided to go back east.") and "SCORE" in screen.event_text.text and not ("Oregon City" in screen.event_text.text) and screen.choices.get_child_count()==0,"Peaceful end screen has no death or Oregon victory text")
 screen.game=Simulation.new(1848,"classic",true)
 screen.departure_view.game=screen.game
 var leader: String=screen.departure_view.names[0].text
 var original: Array=screen.departure_view.draft.profiles.duplicate(true)
 screen.departure_view.generate_party_button.pressed.emit()
 check(screen.departure_view.names[0].text==leader and screen.departure_view.draft.profiles[0]==original[0],"Generate Party keeps the leader")
 check(screen.departure_view.draft.profiles.slice(1)!=original.slice(1) and screen.departure_view.selected_bonds().is_empty(),"Generate Party replaces companions and resets old bonds")
 check(not screen.departure_view.generate_party_button.get_global_rect().intersects(screen.departure_view.next_button.get_global_rect()),"Generate and Store buttons do not overlap")
 screen.queue_free()
 await process_frame
 print("Return travel / generation: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
