extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Discard=preload("res://simulation/discard_plan.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func party(seed_value: int=565001):
 var g=Sim.new(seed_value,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":250,"clothing":5,"bullet_boxes":5}),"Pelt fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear";g.survival.data.event_chance=0
 return g
func shoot(g,kit: String="wagon",kind: int=1):
 check(g.start_hunt({"members":[0,1,2,3,4] if kit=="wagon" else [0],"kit":kit,"bullets":5}),"Actual hunt starts")
 g.hunt.animals=[{"kind":kind,"escaped":false,"x":180.0,"y":116.0,"direction":1,"meat":53 if kind==1 else 300,"kcal_per_lb":550}];g.hunt.targets=[];g.hunt.meat=0
 check(g.hunt_shot(0),"An actual shot produces the controlled kill")
func run():
 var g=party();shoot(g)
 var before: Dictionary=g.state.duplicate(true);var random_state=g.rng.state;var encounter: String=JSON.stringify(g.hunt)
 var q: Dictionary=g.pelt_quote({"deer_hide":1})
 check(q.valid and q.raw_lb==10 and q.packed_lb==3 and q.days==1,"Quote distinguishes raw retrieval, prepared cargo and extra day")
 check(g.state==before and g.rng.state==random_state and JSON.stringify(g.hunt)==encounter,"Pelt preview has no resource, RNG or hunt effects")
 for cart in [{"deer_hide":2},{"deer_hide":0.5},{"deer_hide":-1},{"bison_hide":1},{"unknown":1}]:
  check(not g.pelt_quote(cart).valid and not g.finish_hunt(cart) and g.state==before,"Invalid recovery is rejected atomically")
 var day: int=g.state.day;var bullets: int=g.state.bullets
 check(g.finish_hunt({"deer_hide":1}),"Selected skin settles through the real hunt")
 check(g.state.day==day+2 and g.state.deer_hide==1 and g.state.bullets==bullets,"Hunting plus preparation costs two days and no invented bullet")
 check(g.state.food==int(before.food)+int(g.last_hunt_recovery.generated_food)-30 and g.last_hunt_recovery.preparation_food_units==15,"Preparation consumes and reports its real second party meal")
 check(not g.state.has("_raw_hides_lb") and g.last_hunt_recovery.pelts.deer_hide==1,"Raw load reservation is cleared after actual recovery")
 check(g.provisions.cargo(g.state)<=g.provisions.storage_capacity(g.state),"Finished skins fit actual cargo")
 check(not g.finish_hunt({"deer_hide":1}) and g.state.deer_hide==1,"A settled kill cannot award skins twice")
 check(g.supply_history.any(func(h):return h.event=="prepared_pelts" and h.changes.deer_hide==1),"Recovery enters supply history")
 var snapshot: Dictionary=Save.new().capture(g);var restored=Save.new().restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(restored!=null and Save.new().capture(restored)==snapshot,"Skins and preparation history round-trip exactly")
 for invalid in [-1,0.5,"2",INF]:
  var bad: Dictionary=snapshot.duplicate(true);bad.state.deer_hide=invalid
  check(Save.new().restore(bad)==null,"Invalid saved skin count rejects")
 g.pending={}
 var mass: float=g.provisions.cargo(g.state)
 check(Discard.stock(g).any(func(r):return r.id=="deer_hide" and r.label=="Deer hide" and r.mass_lb==3),"Drop supplies shows actual skin amount, name and weight")
 check(g.discard_supply("deer_hide",1) and is_equal_approx(g.provisions.cargo(g.state),mass-3),"Dropping a skin really frees its weight")
 g=party();shoot(g,"foot")
 var haul: int=g.hunting_capacity()
 check(g.finish_hunt({"deer_hide":1}) and g.last_hunt_recovery.retrieved<=haul-10,"Raw skin weight displaces meat from a solo hunter's haul")
 var baseline=party();shoot(baseline)
 check(baseline.finish_hunt() and baseline.state.day==1 and baseline.state.deer_hide==0,"Existing meat-only hunts keep their original day cost")
 g=party();g.hunt={"activity":"fish"}
 check(not g.pelt_quote({"rabbit_pelt":1}).valid,"Fish cannot yield animal pelts")
 g=party();shoot(g,"wagon",0)
 g.hunt.animals.append(g.hunt.animals[0].duplicate(true));g.hunt.targets.append(1)
 check(not g.pelt_quote({"bison_hide":2}).valid,"Raw-hide batch labor limit cannot be bypassed with a large wagon")
 g.hunt={};g.state.deer_hide=20;g.state.money=0;g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 var counter: Dictionary=g.post_store();var row: Dictionary=counter.rows.filter(func(r):return r.item=="deer_hide")[0]
 check(not row.sells and row.buys and row.can_sell==16 and row.sell_cents==75,"Post buys a finite quantity of rough skins at the period-anchored estimate")
 check(not g.counter_quote({"deer_hide":1}).valid and not g.counter_quote({"deer_hide":-17}).valid,"Counter will not sell skins or buy beyond demand")
 var cash_quote: Dictionary=g.counter_quote({"deer_hide":-5,"food":10})
 check(cash_quote.valid and cash_quote.net_cents>=0,"Real skin proceeds can fund supplies in one basket")
 check(g.counter_checkout({"deer_hide":-16}),"Actual counter pays for real held skins")
 check(g.state.deer_hide==4 and g.state.money==12.0,"Sale removes the exact quantity and pays exact cents")
 check(not g.counter_quote({"deer_hide":-1}).valid,"Repeated visits do not refresh the post's buying demand")
 restored=Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
 check(restored!=null and not restored.counter_quote({"deer_hide":-1}).valid,"Used demand remains used after save/load")
 var road: Dictionary=g.Pelts.rows(g,"passing:test","traders")[0]
 check(road.can_sell==3 and road.sell_cents==56,"Passing trader has its own smaller demand and lower offer")
 # A real save captured on the released rules before changing the price.
 var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-pelt-calibration-save-v1.json"))
 restored=Save.new().restore(prior)
 check(restored!=null,"Actual previous-pelt-rules save loads under calibrated prices")
 if restored!=null:
  check(restored.state==Save.new().normalize(prior.state),"Price migration preserves owned skins, cash and the entire saved state")
  check(restored.rng.state==int(prior.random),"Price migration does not advance the journey random stream")
  restored.state.landmark="fort_laramie";restored.state.next_landmark="fort_laramie";restored._arrive_landmark(true,false)
  var offers: Dictionary={}
  for offer in restored.post_store().rows:
   if offer.item in ["bison_hide","deer_hide","rabbit_pelt"]:offers[offer.item]=offer.sell_cents
  check(offers=={"bison_hide":150,"deer_hide":75,"rabbit_pelt":5},"Migrated goods receive current offers without free goods or a cash adjustment")
  var cash_before: float=restored.state.money
  check(restored.counter_checkout({"bison_hide":-1,"deer_hide":-3,"rabbit_pelt":-4}),"Mixed held skins sell through the actual counter")
  check(is_equal_approx(restored.state.money-cash_before,3.95),"Mixed sale pays exactly $3.95 at current prices")
  check(restored.state.bison_hide==0 and restored.state.deer_hide==0 and restored.state.rabbit_pelt==0,"Mixed sale removes every sold skin")
 g.state.bison_hide=1;g.state.rabbit_pelt=1
 var road_offers: Dictionary={}
 for offer in g.Pelts.rows(g,"passing:calibration","traders"):road_offers[offer.item]=offer.sell_cents
 check(road_offers=={"bison_hide":112,"deer_hide":56,"rabbit_pelt":3},"All road offers floor 75 percent to whole cents")
 var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-pelts-save-v1.json"));var original: Dictionary=legacy.duplicate(true)
 restored=Save.new().restore(legacy)
 check(restored!=null and legacy==original,"Actual pre-pelt save migrates without modifying its input")
 if restored!=null:
  check(restored.state==Save.new().normalize(original.state),"Legacy state dictionary remains exactly intact on load")
  for key in ["food","money","bullets","day","salt"]:check(restored.state[key]==original.state[key],"Migration preserves existing "+key)
  check(restored.state.get("bison_hide",0)==0 and restored.state.get("deer_hide",0)==0 and restored.state.get("rabbit_pelt",0)==0,"Migration invents no trade goods")
 g=party();g.state.deer_hide=2
 check(g.abandon_wagon({"food":20,"clothing":5,"bullets":20,"deer_hide":1}),"Packing without the wagon accepts real trade skins")
 check(g.state.deer_hide==1 and g.wagon_cache.inventory.deer_hide==1,"Pack and cache split skins without duplicating them")
 restored=Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
 check(restored!=null and restored.state.deer_hide==1 and restored.wagon_cache.inventory.deer_hide==1,"Cached and packed skins survive saving")
 g=party();g.state.horses=1;g.state.saddles=1;g.state.saddlebags=1
 check(g.field_outings.start(g,1,"ride_horse",1,5),"Detached legacy-compatibility fixture starts")
 g.state["_raw_hides_lb"]=50.0
 var trip_random:=RandomNumberGenerator.new();trip_random.seed=111
 var child=load("res://simulation/outing_actor.gd").build(g,g.field_outings.record.trips[0],trip_random)
 check(not child.state.has("_raw_hides_lb"),"Detached hunter cannot inherit the wagon's temporary raw-hide load")
 g.state.erase("_raw_hides_lb")
 var old_trip: Dictionary=Save.new().capture(g);old_trip.rules=original.rules
 for key in ["bison_hide","deer_hide","rabbit_pelt"]:
  old_trip.state.erase(key)
  for trip in old_trip.field_outings.trips:trip.camp.inventory.erase(key)
 restored=Save.new().restore(old_trip)
 check(restored!=null and restored.field_outings.record.trips[0].camp.inventory.get("deer_hide",0)==0,"Derived pre-skin detached inventory migrates with empty trade-goods slots")
 if restored!=null:
  restored.state.deer_hide=2
  var old_pack_actor=load("res://simulation/outing_actor.gd").build(restored,restored.field_outings.record.trips[0],trip_random)
  check(old_pack_actor.state.get("deer_hide",0)==0,"A legacy detached pack cannot inherit the wagon's newly acquired trade goods")
 var screen=load("res://ui/main.gd").new();root.add_child(screen);await process_frame
 screen.game=party();shoot(screen.game);screen._open_hunt_window();await process_frame
 screen.pelt_recovery.quantities.deer_hide.value=1;screen._update_hunt_report()
 check(screen.pelt_recovery.cart()=={"deer_hide":1} and screen.pelt_recovery.detail.text.contains("EXTRA CAMP DAY"),"Hunting screen offers explicit quantity and time cost")
 check(screen.pelt_recovery.get_rect().end.y<=273,"Pelt controls fit the hunt dialog's content area")
 check(screen.hunt_window.get_ok_button().is_visible_in_tree(),"The committing return-load button stays visible under the shared X-exit convention")
 if "--capture" in OS.get_cmdline_user_args():
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/pelt-hunting-preview.png")
 screen.hunt_window.get_ok_button().pressed.emit()
 check(screen.game.hunt.is_empty() and screen.game.state.deer_hide==1 and screen.game.state.day==2,"The actual return button commits the selected skins and extra day")
 screen.hunt_window.hide();screen.queue_free();await process_frame
 print("Pelts and trade skins: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
