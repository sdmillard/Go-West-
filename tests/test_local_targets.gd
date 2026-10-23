extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party(seed_value: int=57):
 var game=Simulation.new(seed_value,"classic",true)
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 game.depart("banker",["A","B","C","D","E"],5,cart)
 game.party_health.daily_onset_chance=0
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 game.seen.append("muddy_trail")
 return game
func stop(game,id: String="fort_bridger"):
 game.state.next_landmark=id
 game._arrive_landmark()
func restore(game):return Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
func run():
 var game=party()
 stop(game)
 var before: Dictionary=Store.new().capture(game)
 var targets: Array=game.crime.local_targets(game)
 check(targets.size()==game.crime.staff_ids("fort_bridger").size(),"Every local worker is a target, not just the keeper")
 check(targets.all(func(person):return not person.name.is_empty() and " · " in person.name),"Local names include the person's role")
 check(game.crime.local_targets(game)==targets and Store.new().capture(game)==before,"Listing/naming locals is deterministic and consumes no RNG, day or supplies")
 var worker: String=targets[1].uid
 check(game.open_local_attack(worker),"A supporting worker can be selected independently")
 check(game.pending.crime_target==worker and game.pending.choices.map(func(choice):return choice.crime_command)==["shoot","assault","back"],"The attack preview has the selected worker and actual attack methods only")
 check(restore(game)!=null,"Selected local target preview saves and loads")
 var bad: Dictionary=Store.new().capture(game)
 bad.pending.crime_target="keeper:barlow_pass"
 check(Store.new().restore(JSON.parse_string(JSON.stringify(bad)))==null,"A target from a different place cannot load")
 game.choose(2)
 check(Store.new().capture(game)==before,"Backing out of a local target preview is pure")
 var scene: Dictionary=game.crime.scenes.fort_bridger
 scene.shot_hit=1.0
 scene.shot_fatal=1.0
 scene.escape_capture=0.0
 game.open_local_attack(worker)
 var ammo: int=game.state.bullets
 game.choose(0)
 check(game.crime.actor("fort_bridger",worker).health==0 and game.crime.owner("fort_bridger").health==100,"A shot hurts the selected worker, leaving the keeper intact")
 check(game.crime.incident().target==worker and game.crime.incident().stage=="escape","The incident records that worker and does not award the keeper's stock")
 check(game.state.bullets==ammo-1 and game.state.day==1,"Local shots retain the bullet, time and daily meal costs")
 check(game.crime.record.remains.any(func(body):return body.person==worker),"A killed supporting worker leaves their own remains")
 check(restore(game)!=null,"Nonkeeper death, witnesses and escape stage round-trip")
 game.choose(0)
 if game.pending.get("crime_menu",false):game.choose(0)
 check(game.crime.local_targets(game).all(func(person):return person.uid!=worker),"Dead local people disappear from the target list")
 check(restore(game)!=null,"A resolved nonkeeper incident preserves save validity")
 game=party()
 stop(game,"barlow_pass")
 var toll: Array=game.crime.local_targets(game)
 check(toll.any(func(person):return "collector" in person.name),"The toll stop lists its actual collector")
 check(toll.any(func(person):return person.place.begins_with("passing:")),"A trader visible beside the toll stop also appears among local targets")
 var passing: Dictionary=toll.filter(func(person):return person.place.begins_with("passing:"))[0]
 check(game.open_local_attack(passing.uid) and game.pending.crime_place==passing.place and restore(game)!=null,"A nearby trader can be targeted without accidentally selecting the toll keeper")
 game=party()
 stop(game,"fort_kearny")
 check(game.crime.local_targets(game).all(func(person):return person.place!="fort_kearny"),"No soldiers are invented before the post is staffed")
 game=party()
 var transient_targets: Array=game.crime.local_targets(game)
 check(not transient_targets.is_empty() and transient_targets[0].place.begins_with("passing:"),"Passing traders supply their own actual local targets")
 var actor_count: int=game.crime.record.actors.size()
 var transient_uid: String=transient_targets[1].uid
 game.open_local_attack(transient_uid)
 check(game.crime.record.actors.size()==actor_count and restore(game)!=null,"Previewing a transient worker does not create actors or consume the encounter")
 game.crime.scenes.passing_traders.shot_hit=1.0
 game.crime.scenes.passing_traders.shot_fatal=1.0
 game.choose(0)
 check(game.crime.record.actors.has(transient_uid) and restore(game)!=null,"Committing against a trader registers and saves that worker's encounter")
 game=party()
 for day in range(50):
  game.state.day=day
  if not game.context.market(game).available and not game.crime.camp(game).is_empty():break
 var camp_site: String=game.recruitment.site(game)
 check(camp_site.begins_with("emigrants:"),"An emigrant camp can provide a companion search when no traders are nearby")
 game.party_health.kill(game.party_health.members[1],int(game.state.day),"test injury")
 game._collect_health_events()
 game.state.party_size=4
 game.state.health=game.party_health.average_health()
 game.recruitment.rules.find_chance=1.0
 game.open_companions()
 game.choose(0)
 check(game.recruitment.record.searches.has(camp_site) and restore(game)!=null,"Camp recruitment keeps its site across the search day and saves")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.departure_view.hide()
 screen.game=party()
 stop(screen.game)
 screen._refresh()
 screen._show_section("Someone here")
 var rows: Array=screen.section_rows.get_children().filter(func(row):return row.has_meta("local_target"))
 check(rows.size()==screen.game.crime.local_targets(screen.game).size(),"Native target list contains each living worker")
 var picked: String=rows[1].get_meta("local_target")
 rows[1].pressed.emit()
 check(screen.service_window.visible and screen.game.pending.crime_target==picked,"Clicking a named local opens that person's attack options")
 check(screen.service_rows.get_children().any(func(row):return row is Button and row.text=="< SOMEONE HERE"),"An attack preview goes back to the list of people here")
 check(not screen.service_rows.get_children().any(func(row):return row is Button and row.text in ["STEAL >","ROB >","ATTACK >","OTHER ACTIONS HERE <"]),"No second crime menu inside the preview")
 screen.service_window.hide()
 screen.game.choose(screen.game.pending.choices.size()-1)
 await villainy_places(screen)
 screen.game.party_health.kill(screen.game.party_health.members[1],0,"test injury")
 screen.game.state.party_size=4
 screen.game.state.health=screen.game.party_health.average_health()
 screen._refresh()
 var labels: Array=screen.place_actions.get_children().map(func(row):return row.text)
 check("STORE" in labels and "FIND COMPANIONS" in labels and "LOCAL ACTIVITIES" in labels,"Stop services and companion search appear below the picture")
 screen.game.pending={}
 screen.game.state.day=2
 screen.game.state.miles=50
 screen._refresh()
 labels=screen.place_actions.get_children().map(func(row):return row.text)
 check(not "STORE" in labels and not "LOCAL ACTIVITIES" in labels,"Stop-only buttons disappear after leaving")
 screen.game.pending={"id":"test","title":"Encounter","text":"Wait","choices":[{"label":"Continue","effects":{},"result":""}]}
 screen._refresh()
 check(screen.place_actions.get_child_count()==0,"Place buttons cannot bypass unresolved encounters")
 screen.queue_free()
 await process_frame
 print("Local targets: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

## VILLAINY > STEAL and ROB list every place within reach (here a post and an emigrant camp) and go straight to that act.
func villainy_places(screen) -> void:
 var game=screen.game
 var day_before: int=game.state.day
 for day in range(day_before,day_before+40):
  game.state.day=day
  if not game.crime.camp(game).is_empty():break
 var camp: String=game.crime.camp(game)
 check(not camp.is_empty() and game.crime.local_places(game,game.pending)==["fort_bridger",camp],"A camp near a post is a second place to rob")
 check(not game.open_crime("passing:nowhere:1") and not game.pending.get("crime_menu",false),"A place that is not here cannot be opened")
 for section in ["Steal","Rob"]:
  screen._show_section(section)
  var rows: Array=screen.section_rows.get_children().filter(func(row):return row.has_meta("crime_place"))
  check(rows.map(func(row):return row.get_meta("crime_place"))==["fort_bridger",camp],section+" lists the post and the camp as branches")
  check(rows[0].text=="FORT BRIDGER · TRADING STORE >" and rows[1].text=="AN EMIGRANT CAMP >",section+" names each place")
  var before: Dictionary=Store.new().capture(game)
  rows[1].pressed.emit()
  var act: String="theft" if section=="Steal" else "robbery"
  var commands: Array=game.pending.get("choices",[]).map(func(choice):return choice.get("crime_command",""))
  check(screen.service_window.visible and game.pending.get("crime_place","")==camp and game.crime.rules(camp).kind=="emigrants",section+" > camp opens the camp's preview")
  var labels: Array=screen.service_rows.get_children().filter(func(row):return row is Button).map(func(row):return row.text)
  check(labels.size()==2 and labels[0]==game.pending.choices[commands.find(act)].label and labels[1]=="< "+section.to_upper(),section+" > camp shows only that act and the way back")
  check(restore(game)!=null and restore(game).pending.crime_place==camp,"A preview of a chosen place saves and loads")
  check(game.state.day==before.state.day and game.crime.record.incidents.is_empty(),"Previewing commits nothing")
  screen.service_rows.get_children().filter(func(row):return row is Button)[1].pressed.emit()
  check(not screen.service_window.visible and screen.section_window.visible and screen.section_window.title==section.to_upper() and not game.pending.get("crime_menu",false),"Back returns to the "+section+" list")
  screen.section_window.hide()
 game.state.day=day_before
