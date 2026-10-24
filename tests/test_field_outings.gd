extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Outfit=preload("res://simulation/outing_outfit.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var g=Sim.new(5711,"classic",true)
 g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":2,"mules":1,"saddles":1,"pack_saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10})
 g.pending={}
 g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 g.seen.append("muddy_trail")
 g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear";g.survival.data.event_chance=0
 g.field_outings.rules.mishap_chance=0;g.field_outings.rules.hit_chance=0;g.field_outings.rules.hunter_bonus=0
 for p in g.characters.profiles:
  if int(p.id)>0:p.boundaries.forbidden=[];p.trust=50
 return g
func day(g):
 g.pending={}
 g.rest()
func configure(g):
 g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear";g.survival.data.event_chance=0
 g.field_outings.rules.mishap_chance=0;g.field_outings.rules.hit_chance=0;g.field_outings.rules.hunter_bonus=0
func run():
 var store=Store.new()
 var g=party()
 var before: Dictionary=store.capture(g)
 var foot: Dictionary=Outfit.quote(g,[1],"foot",1,5)
 var leader: Dictionary=g.hunt_outfit_quote([0],"foot",5)
 check(foot.valid and leader.valid and foot.capacity_lb==leader.capacity_lb and foot.catch_lb==leader.catch_lb,"Leader and equal-health companion have identical outfit/carrying limits")
 check(foot.catch_lb<50 and foot.pack_lb>20,"Personal gear, clothing, food reserve and ammunition consume real retrieval room")
 check(store.capture(g)==before,"Outfit quotes do not consume supplies, time or random numbers")
 # Good and Fair carry normally; one curve applies to every human load.
 var curve: Array=g.provisions.data.walking.health_load_curve
 var last:=0.0
 for health in range(101):
  var person: Dictionary=g.party_health.members[0].duplicate(true);person.health=health;person.alive=health>0
  var factor: float=g.provisions.Carrying.factor(person,curve)
  check(factor>=last and factor<=1 and factor-last<=0.025001,"Carrying curve has no downward jump or sudden health-category cliff")
  if health>=50:check(factor==1,"All Fair and Good health retains full human carrying capacity")
  last=factor
 for pair in [[100,1.0],[80,1.0],[50,1.0],[49,59.0/60.0],[35,0.75],[20,0.5],[10,0.25],[0,0.0]]:
  g.party_health.members[0].health=pair[0];g.party_health.members[1].health=pair[0]
  var a: float=Outfit.capacity(g,[0],"foot");var b: float=Outfit.capacity(g,[1],"foot")
  check(is_equal_approx(a,50*pair[1]) and a==b,"Leader and delegated hunter share each configured health breakpoint")
  var walker: Dictionary=g.party_health.members[0]
  check(is_equal_approx(g.provisions.Carrying.capacity([walker],40,curve),snappedf(40*pair[1],0.1)),"Walking uses the same health factor with its own base allowance")
 g=party()
 var mounted: Dictionary=Outfit.quote(g,[1],"ride_horse",3,5)
 check(mounted.valid and mounted.catch_lb>foot.catch_lb,"Allocated riding animal with bags adds real cargo")
 g.state.saddlebags=0
 check(not Outfit.quote(g,[1],"ride_horse",1,5).valid,"Merely owning a horse does not supply missing tack")
 g=party()
 check(g.field_outings.start(g,1,"foot",1,5),"Same-day foot hunter can be sent")
 check(g.state.party_size==4 and g.party_health.members[1].away and g.current_party_slots()[1]==1,"Away hunter is absent from work but keeps the actual roster slot")
 check(not g.characters.can_receive_wages(g,1) and not g.characters.available(g,g.characters.profiles[1].skill),"Away hunter is unavailable for pay and passive specialist benefits")
 check(not g.field_outings.start(g,1,"foot",1,5),"An already-away person cannot depart twice")
 var saved: Dictionary=store.capture(g)
 var loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null,"Active outing survives a JSON save")
 if loaded!=null:
  configure(loaded);day(g);day(loaded)
  check(store.capture(g)==store.capture(loaded),"Return, supplies, health and random streams match after loading")
 check(g.field_outings.record.trips.is_empty() and g.state.party_size==5 and not g.party_health.members[1].has("away"),"Foot hunter returns to the waiting party on the due day")
 check(g.state.food==485 and g.state.clothing==5 and g.state.bullets==99,"Camp and field meals/ammunition are charged once; unused pack supplies return")
 g=party()
 var money: int=roundi(g.state.money*100)
 g.characters.profiles[1].specials=["Mercenary"]
 g.characters.start_contract(g,1,int(g.characters.wage_quote(g.characters.profiles[1]).daily_cents),1)
 g.characters.set_auto_pay(g,1,true)
 check(g.field_outings.start(g,1,"ride_horse",3,5),"Three-day mounted outrider can set out")
 check(g.state.horses==1 and g.state.saddles==0 and g.state.saddlebags==0,"Dispatched horse and tack cannot also carry the main party")
 day(g)
 check(roundi(g.state.money*100)==money and g.characters.profiles[1].contract.arrears_cents>0 and g.characters.payable_due_total(g)==0,"Wages accrue but cannot be paid remotely or cause an impossible-payment alert")
 day(g);day(g)
 check(g.state.horses==2 and g.state.saddles==1 and g.state.saddlebags==1 and g.characters.profiles[1].contract.arrears_cents==0,"Actual animals return once; automatic arrears settle after the hunter rejoins")
 g=party()
 g.field_outings.start(g,1,"foot",1,5)
 saved=store.capture(g)
 check(g.travel() and g.pending.get("outing_warning",false) and g.state.day==0 and g.state.miles==1,"Travel warns before silently leaving a foot hunter")
 loaded=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
 check(loaded!=null and loaded.pending.get("outing_warning",false),"Departure warning and resume menu survive saves")
 g.choose(2)
 check(store.capture(g)==saved,"Back from a departure warning has no simulation side effects")
 g.travel();g.choose(1);g.travel()
 check(g.state.miles>1 and g.field_outings.record.trips[0].stage=="stranded" and g.state.party_size==4,"Leaving is explicit and hunter waits at the original camp")
 saved=store.capture(g);loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null,"Stranded camp survives JSON with independent food and health")
 # Test-only relocation to the exact original road position exercises recovery without a synthetic teleport action.
 g.pending={};g.state.landmark="independence";g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 check(g.field_outings.recover_here(g) and g.state.party_size==5 and g.field_outings.record.trips.is_empty(),"Returning to the marked origin retrieves the actual hunter and pack")
 g=party();g.field_outings.start(g,1,"foot",1,5)
 g.travel();g.choose(1);g.travel();g.pending={}
 check(g.turn_direction("east"),"The actual heading action can turn back for a stranded hunter")
 for step in range(8):
  if g.state.miles<=1:break
  g.pending={};g.travel()
 check(g.state.miles==1 and g.pending.get("id","")=="hunter_camp_reached","Eastbound travel stops exactly at the hunter marker instead of skipping over an unreachable camp")
 check(store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null,"The camp arrival notice saves with the correct route location")
 g.choose(0)
 check(g.field_outings.recover_here(g) and g.state.party_size==5,"Actual return travel and the public recovery action retrieve the hunter")
 g=party()
 g.field_outings.start(g,1,"ride_horse",1,5)
 check(g.travel() and not g.pending.get("outing_warning",false) and g.field_outings.record.trips.is_empty(),"Mounted outrider rejoins the moving party along the same road")
 g=party()
 g.field_outings.rules.mishap_chance=1
 g.field_outings.start(g,1,"ride_horse",1,5)
 day(g)
 check(g.field_outings.record.trips.size()==1 and g.field_outings.record.trips[0].delayed and g.field_outings.record.trips[0].due>1,"A mishap really delays return rather than silently removing the hunter")
 g=party()
 g.field_outings.start(g,1,"ride_horse",2,5)
 g.state.landmark="kansas_river";g.state.next_landmark="kansas_river"
 g._arrive_landmark(true,false)
 var crossing: int=-1
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].get("action","")=="cross" and g.can_choose(i):crossing=i;break
 check(crossing>=0 and g.choose(crossing) and g.pending.get("outing_warning",false),"River crossings warn instead of teleporting an absent rider across")
 g=party()
 var q: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5)
 var supply_food: int=g.state.food
 check(g.start_hunt({"members":[0],"kit":"ride_horse","bullets":5}),"Player hunt uses the shared outfit")
 check(g.hunting_capacity()==q.catch_lb and g.state.horses==1 and g.hunt_ammo()==5,"Player receives only selected hauling and ammunition; its horse is reserved")
 g.hunt_shot(-1)
 check(g.hunt_ammo()==4 and g.state.bullets==95,"A shot consumes field ammunition, not a second main-store bullet")
 g.hunt.meat=0;g.finish_hunt()
 check(g.state.food==supply_food-15 and g.state.bullets==99 and g.state.horses==2 and g.state.clothing==5,"Player outing restores unused supplies and animals around one shared camp meal")
 check(g.state.horse_health<=100,"An outing cannot improve its mount by pretending it rested")
 g=party()
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-field-outings-v4.json"))
 loaded=store.restore(old)
 check(loaded!=null and loaded.field_outings.record.trips.is_empty(),"Genuine prior schema-4 journey loads without invented trips")
 if loaded!=null:check(loaded.state==store.normalize(old.state) and str(loaded.rng.state)==old.random,"Migration preserves inventory and original RNG")
 g.field_outings.start(g,1,"foot",1,5);saved=store.capture(g)
 for field in ["due","member","stock","origin"]:
  var invalid: Dictionary=saved.duplicate(true)
  invalid.field_outings.trips[0][field]=null
  check(store.restore(invalid)==null,"Malformed trip field rejects safely: "+field)
 var invalid: Dictionary=saved.duplicate(true);invalid.party[1].erase("away")
 check(store.restore(invalid)==null,"An outing cannot exist without its reserved roster member")
 # A rider returning during the crossing cannot appear on the far bank.
 g=party();g.route_path=g.route.main_path_to("kansas_river")
 g.state.landmark="kansas_river";g.state.next_landmark="kansas_river";g.state.miles=int(g.route.node_miles().kansas_river);g.state.leg_length=0;g.state.leg_miles=0
 g._arrive_landmark(true,false)
 check(g.field_outings.start(g,1,"ride_horse",1,5),"A hunter can set out from the near-bank camp")
 crossing=g.pending.choices.find_custom(func(c):return c.get("method","")=="ferry")
 g.choose(crossing);g.choose(1);g.choose(crossing)
 check(g.field_outings.record.trips.size()==1 and g.field_outings.record.trips[0].camp.has("crossing") and g.state.party_size==4,"A due rider reaches the river and must resolve their own crossing")
 check(store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null,"Far-bank party and near-bank hunter save as distinct locations")
 var river_departure_snapshot: Dictionary=store.capture(g)
 var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-carry-curve-v5.json"))
 var migrated=store.restore(prior)
 check(migrated!=null and migrated.state==store.normalize(prior.state) and str(migrated.rng.state)==prior.random and migrated.field_outings.snapshot()==store.normalize(prior.field_outings),"Genuine previous-curve outing preserves its reserved animals, packs, health, deadlines and random streams")
 # River pursuit consumes its own day and resolves the actual crossing rules.
 var river_save: Dictionary=river_departure_snapshot
 var crossed_live:=false
 var drowned
 for crossing_seed in range(1,60):
  var candidate=store.restore(river_save)
  configure(candidate)
  candidate.field_outings.rules.lone_crossing_drowning_chance=0
  candidate.field_outings.record.trips[0].camp.crossing.stage="low"
  var random:=RandomNumberGenerator.new();random.seed=crossing_seed
  candidate.field_outings.record.trips[0].camp.camp_random=str(random.state)
  day(candidate)
  if candidate.field_outings.record.trips.is_empty():
   check(candidate.state.day==2 and candidate.state.party_size==5 and candidate.state.horses==2,"An outrider crosses during one actual shared day and reunites on the far bank")
   crossed_live=true;break
 check(crossed_live,"A seeded river crossing survives")
 for crossing_seed in range(1,80):
  var candidate=store.restore(river_save)
  configure(candidate)
  candidate.field_outings.rules.lone_crossing_drowning_chance=1
  candidate.field_outings.record.trips[0].camp.crossing.stage="high"
  var random:=RandomNumberGenerator.new();random.seed=crossing_seed
  candidate.field_outings.record.trips[0].camp.camp_random=str(random.state)
  day(candidate)
  if not candidate.field_outings.record.trips.is_empty() and candidate.field_outings.record.trips[0].camp.get("return_failed",false):
   drowned=candidate;break
 check(drowned!=null,"A lone outrider can actually drown in a crossing")
 if drowned!=null:
  check(drowned.party_health.members[1].alive and drowned.party_health.members[1].away and drowned.state.horses==1,"Unknown death never returns a ghost rider or duplicates the lost horse")
  check(not drowned.journal.any(func(line):return "beginning to fear" in line) and drowned.field_outings.public_status(drowned.field_outings.record.trips[0])=="AWAY" and drowned.field_outings.public_kit(drowned.field_outings.record.trips[0])=="ride_horse","An offscreen death is not announced or revealed by the trip roster instantly")
  loaded=store.restore(JSON.parse_string(JSON.stringify(store.capture(drowned))))
  check(loaded!=null,"Unknown drowning and lost field supplies save safely")
  if loaded!=null:
   configure(loaded);day(drowned);day(loaded)
   check(store.capture(drowned)==store.capture(loaded),"Missing notification and actual hidden fate resume deterministically")
  check(drowned.journal.filter(func(line):return "beginning to fear" in line).size()==1,"Two days overdue produces one uncertain missing-person notification")
  day(drowned)
  check(drowned.journal.filter(func(line):return "beginning to fear" in line).size()==1,"Missing-person notification does not repeat every day")
 # Changing heading toward a mounted hunter does not stop reunion.
 var returning=party();returning.field_outings.start(returning,1,"ride_horse",3,5)
 returning.travel();returning.pending={}
 check(returning.turn_direction("east") and not returning.pending.get("outing_warning",false),"Turning toward an outrider does not require leaving them behind")
 returning.travel();day(returning)
 check(returning.field_outings.record.trips.is_empty() and returning.state.party_size==5,"A reversing train and its outrider can meet")
 for follows in [0.0,1.0]:
  var forked=party()
  forked.route_path=forked.route.main_path_to("little_sandy")
  forked.state.landmark="little_sandy";forked.state.next_landmark="little_sandy";forked.state.miles=int(forked.route.node_miles().little_sandy)
  forked.state.leg_length=0;forked.state.leg_miles=0;forked._arrive_landmark(true,false)
  forked.field_outings.rules.fork_follow_chance=follows
  forked.field_outings.start(forked,1,"ride_horse",1,5)
  var leave: int=forked.pending.choices.find_custom(func(c):return c.get("action","")=="leave")
  forked.choose(leave);forked.choose(1);forked.choose(leave);forked.travel()
  check(forked.field_outings.record.trips.is_empty() if follows==1 else forked.field_outings.record.trips[0].camp.get("wrong_turn",false),"Fork choice can follow the train or lose its trail without an automatic hard block")
  check(store.restore(JSON.parse_string(JSON.stringify(store.capture(forked))))!=null,"Fork outcome and independent hunter location survive a save")
 check(is_equal_approx(Sim.new(1,"classic",true).field_outings.rules.fork_follow_chance,0.5),"Ordinary fork-follow chance is the requested fifty-fifty")
 # Outing conservation and offscreen fates.
 g=party();g.field_outings.rules.hit_chance=10;g.hunting.data.regions.woodland.empty_chance=0;g.hunting.data.regions.plains.empty_chance=0
 g.field_outings.start(g,1,"foot",1,5);day(g)
 check(g.state.food>485 and g.provisions.cargo(g.state)<=g.provisions.storage_capacity(g.state),"Successful hunter brings real meat within available parent storage")
 check(store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null,"Returned meat batches save without private trip markers")
 g=party();g.field_outings.start(g,1,"ride_horse",2,5)
 var trip: Dictionary=g.field_outings.record.trips[0]
 trip.camp.guards[0].health=0;trip.camp.guards[0].alive=false;trip.camp.guards[0].death_day=0;trip.camp.guards[0].cause="test injury"
 day(g)
 check(store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null and g.state.party_size==4,"An unknown offscreen death retains a valid reserved roster entry")
 day(g)
 check(not g.party_health.members[1].alive and not g.party_health.members[1].has("away") and g.state.horses==2,"Finding a dead hunter resolves the slot without duplicating or losing recoverable stock")
 g=party();g.field_outings.start(g,1,"foot",1,5)
 saved=store.capture(g);invalid=saved.duplicate(true);invalid.field_outings.trips[0].mile+=1
 check(store.restore(invalid)==null,"Saved camp mileage must match its actual route path")
 invalid=saved.duplicate(true);invalid.field_outings.trips[0].due=6
 check(store.restore(invalid)==null,"A trip cannot invent a longer return deadline")
 g=party();g.field_outings.start(g,1,"ride_horse",3,5)
 # A noticed crime supplies an authoritative escape menu, not a made-up saved choice.
 g.route_path=g.route.main_path_to("fort_bridger");g.state.landmark="fort_bridger";g.state.next_landmark="fort_bridger"
 g.state.miles=int(g.route.node_miles().fort_bridger);g.state.leg_miles=0;g.state.leg_length=0
 var noticed:=false
 for seed_value in range(1,100):
  g.rng.seed=seed_value;g.pending={};g._arrive_landmark(true,false);g.open_crime("fort_bridger")
  if g.steal({"bullets":5}) and g.crime.incident().get("attempt","")=="noticed":noticed=true;break
  g.crime.record.incidents.clear()
 if noticed:
  var flee: int=g.pending.choices.find_custom(func(c):return c.get("crime_command","")=="flee")
  check(flee>=0 and g.choose(flee) and g.pending.get("outing_warning",false) and g.pending.choices.size()==2,"Flight warns with leave/back only, without a free safe rest option")
  loaded=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
  check(loaded!=null and loaded.pending.get("outing_warning",false),"Authoritative crime escape survives a saved outing warning")
  g.choose(1)
  check(g.pending.get("crime_menu",false),"Back restores the real crime escape menu")
 else:check(false,"Seeded noticed crime available for flight warning test")
 var screen=Main.instantiate();root.add_child(screen);await process_frame
 screen.departure_view.hide();screen.game=party();screen._refresh();screen._open_field_trip(-1)
 check(screen.outing_window.visible and screen.outing_window.actor_id()==-1 and screen.outing_window.quote().valid,"Leader outfitting is a real valid UI choice")
 screen.outing_window.open(screen.game,1)
 check(screen.outing_window.actor_id()==1 and screen.outing_window.quote().valid,"Companion uses the same outfitting screen")
 screen.outing_window.kit.select(1);screen.outing_window.duration.value=3
 screen.outing_window.confirmed.emit()
 check(screen.game.state.party_size==4 and screen.game.field_outings.record.trips.size()==1,"UI dispatches a mounted trip with real resources")
 screen._show_party();screen._select_member(1)
 check("AWAY HUNTING" in screen.member_details.text and not screen.auto_pay_wages.visible,"Party screen shows last-known away status, not remote payment controls")
 screen.queue_free()
 print("Field outings: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
