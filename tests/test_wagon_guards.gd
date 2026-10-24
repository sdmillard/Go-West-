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
func outfit(seed_value: int=57):
 var game=Simulation.new(seed_value,"classic",true)
 game.depart("banker",["Lead","A","B","C","D"],5,{"oxen":4,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 game.party_health.daily_onset_chance=0
 for event in game.catalog.events:game.seen.append(event.id)
 for member in game.party_health.members:member.health=100
 game.state.health=100
 game.configure(0,2)
 return game
func trip(game,message: String):
 var store=Store.new()
 var snap: Dictionary=store.capture(game)
 var copy=store.restore(JSON.parse_string(JSON.stringify(snap)))
 check(copy!=null,message)
 if copy!=null:check(store.capture(copy)==snap,message+" exact")
 return copy
func disable_loss(game):
 game.provisions.data.walking.cache_loss_base=0
 game.provisions.data.walking.cache_loss_daily=0
 game.provisions.data.walking.cache_loss_cap=0
func rest_day(game):
 if game.pending.get("id","")=="party_health":game.choose(0)
 return game.rest()
func run():
 var game=outfit()
 var before: Dictionary=Store.new().capture(game)
 check(not game.abandon_wagon({"food":20},[0]),"Leader cannot be assigned as guard")
 check(not game.abandon_wagon({"food":20},[1,1]),"Duplicate guards reject")
 check(not game.abandon_wagon({"food":20},[99]),"Missing guard rejects")
 check(Store.new().capture(game)==before,"Invalid selections are atomic")
 var ordinary: Dictionary=game.pack_quote({"food":20,"clothing":3})
 var guarded: Dictionary=game.pack_quote({"food":20,"clothing":3},false,[1,2])
 check(guarded.valid and ordinary.capacity_lb==200 and guarded.capacity_lb==120 and guarded.cargo_lb==83,"Guard preview excludes their bodies and personal gear from the walking party")
 check(Store.new().capture(game)==before,"Guard preview changes no supplies, roster, random stream or time")
 check(not game.abandon_wagon({"food":150},[1,2]) and Store.new().capture(game)==before,"Reduced carry limit enforced before assigning guards")
 check(game.abandon_wagon({"food":20,"clothing":3,"bullets":10},[1,2]),"Leave two actual companions")
 check(game.state.party_size==3 and game.current_party_slots()==[0,1,2,3,4],"Guards stop traveling but reserve both recruitment slots")
 check(game.state.food==11 and game.wagon_cache.inventory.food==574,"Travelers and guards eat from separate stores on packing day")
 check(game.party_health.members[1].get("guarding",false) and not game.party_health.is_active(game.party_health.members[1]),"Away companions excluded from active survival and hauling")
 check(game.wagon_cache.household_gear_lb+game.state.household_gear_lb==450,"Splitting party conserves household gear")
 var copy=trip(game,"Split camp save")
 if copy!=null:
  disable_loss(game)
  disable_loss(copy)
  copy.survival.forced_weather="clear"
  copy.survival.data.event_chance=0
  copy.party_health.daily_onset_chance=0
  rest_day(game)
  rest_day(copy)
  check(Store.new().capture(copy)==Store.new().capture(game),"Saved camp random stream continues identically")
 check(not game.characters.can_receive_wages(game,1),"Cannot remotely pay an absent guard")
 disable_loss(game)
 check(game.inspect_cached_wagon() and game.state.vehicle=="wagon" and game.state.party_size==5 and game.wagon_cache.is_empty(),"At-site inspection reunites survivors and recovers the wagon")
 check(not game.party_health.members[1].has("guarding") and game.state.household_gear_lb==450,"Reunion restores exactly the original gear and active companion")
 trip(game,"Reunited camp save")
 game=outfit()
 disable_loss(game)
 game.abandon_wagon({"food":0,"clothing":3,"bullets":0},[1,2])
 var packed: int=game.state.food
 var cached: int=game.wagon_cache.inventory.food
 rest_day(game)
 check(game.state.food==packed and game.wagon_cache.inventory.food==cached-6,"Hungry travelers cannot eat the remote cache; guards consume their own meals")
 check(game.party_health.members[1].health==100,"Away roster exposes last-known health")
 game=outfit()
 disable_loss(game)
 game.provisions.data.wagon_guards.departure_chance=0
 game.provisions.data.wagon_guards.hunt_hit_chance=0
 game.state.food=20
 game.abandon_wagon({"food":10,"clothing":3,"bullets":0},[1,2])
 var bullets: int=game.wagon_cache.inventory.bullets
 for n in range(4):rest_day(game)
 check(game.wagon_cache.inventory.bullets<bullets and game.state.bullets==0,"Hungry guards spend only cached ammunition on uncertain hunts")
 check(game.wagon_cache.camp_log.any(func(line):return "empty-handed" in line),"Failed hunts are recorded without free meat")
 check(game.wagon_cache.guards[0].health<100 and game.party_health.members[1].health==100,"Cached hunger damages actual guards without leaking remote condition")
 trip(game,"Hungry hidden camp save")
 game=outfit()
 disable_loss(game)
 game.provisions.data.wagon_guards.departure_chance=0
 game.state.food=10
 game.state.bullets=0
 game.abandon_wagon({"food":10,"clothing":3},[1])
 game.state.food=1000 # Isolate the hidden guard shortage from the traveling party.
 for n in range(40):rest_day(game)
 check(not game.wagon_cache.guards[0].alive and game.party_health.members[1].alive,"A starving guard can die offscreen while the roster stays last-known")
 check(game.current_party_slots()[1]==1,"Unknown guard death does not allow a duplicate replacement")
 check(game.party_health.description(1).contains("GUARDING") and not game.party_health.description(1).contains("DIED"),"Health description does not reveal hidden death")
 game.state.food=100
 for member in game.party_health.members:
  if game.party_health.is_active(member):member.health=100
 game.state.health=100
 game.state.status="traveling"
 game.pending={}
 check(game.inspect_cached_wagon() and not game.party_health.members[1].alive and game.current_party_slots()[1]==-1,"Returning reveals death and releases the reserved slot")
 check(game.crime.record.remains.any(func(body):return body.person==game.crime.person_id(int(game.state.seed),1) and body.mile==game.state.miles),"Guard's remains belong at the wagon camp")
 trip(game,"Discovered guard death save")
 game=outfit()
 disable_loss(game)
 game.provisions.data.wagon_guards.departure_chance=1
 game.state.food=10
 game.state.bullets=0
 game.abandon_wagon({"food":10,"clothing":3},[1])
 check(game.wagon_cache.guards[0].get("departed",false),"Desperate guard may leave")
 game.state.food=80
 game.pending={}
 check(game.inspect_cached_wagon() and game.party_health.members[1].get("guard_departure",false) and game.state.party_size==4,"Return records guard departure without taking player packs")
 trip(game,"Discovered guard departure saves")
 game=outfit()
 game.abandon_wagon({"food":20,"clothing":3},[1,2])
 var protected: float=game.Guards.protection(game,game.wagon_cache)
 var stock: Dictionary=game.wagon_cache.duplicate(true)
 stock.guards=[]
 check(protected<game.Guards.protection(game,stock) and protected>0,"Healthy guards reduce but never eliminate loss risk")
 game.provisions.data.walking.cache_loss_base=1
 game.provisions.data.walking.cache_loss_cap=1
 for actual in game.wagon_cache.guards:
  actual.health=0;actual.alive=false;actual.death_day=game.state.day;actual.cause="lack of food"
 game.wagon_cache.found=false
 game.pending={}
 check(game.inspect_cached_wagon() and game.wagon_cache.is_empty() and game.state.vehicle=="foot" and game.state.party_size==3,"Dead guards cannot protect a doomed cache or grant its goods")
 trip(game,"Lost guarded cache saves")
 game=outfit()
 var valid: Dictionary=Store.new().capture(game)
 valid.party[1]["guarding"]=true
 check(Store.new().restore(valid)==null,"Reject orphan guard flag without a cached camp")
 # Successful guard hunts still obey real physical hauling and food conversion.
 game=outfit()
 disable_loss(game)
 game.provisions.data.wagon_guards.departure_chance=0
 game.provisions.data.wagon_guards.hunt_hit_chance=1
 game.hunting.data.regions.woodland.empty_chance=0
 game.state.food=10
 game.abandon_wagon({"food":10,"clothing":4,"bullets":0},[1])
 for n in range(8):
  if game.wagon_cache.camp_log.any(func(line):return "hauled" in line):break
  rest_day(game)
 check(game.wagon_cache.camp_log.any(func(line):return "hauled" in line),"Armed healthy guards can obtain regional game")
 check(game.wagon_cache.fresh.all(func(batch):return batch.pounds<=game.provisions.meat_units(int(game.hunting.data.carry_per_person_lb))),"Guard meat batches respect one healthy guard's haul and food conversion")
 game=outfit()
 disable_loss(game)
 game.abandon_wagon({"food":20,"clothing":3},[1,2])
 game.state.vehicle="wagon"
 game.state.household_gear_lb=45.0
 game.pending={}
 check(game.inspect_cached_wagon() and game.state.household_gear_lb==450 and game.state.party_size==5,"Return with an empty replacement wagon conserves gear and rejoins both guards")
 game=outfit()
 disable_loss(game)
 game.state.oxen=0
 game.abandon_wagon({"food":20,"clothing":3},[1,2])
 game.pending={}
 check(game.inspect_cached_wagon() and game.state.vehicle=="foot" and game.state.party_size==5,"Guards can rejoin even when no ox can hitch the found wagon")
 var remaining: Dictionary=game.wagon_cache.duplicate(true)
 check(game.inspect_cached_wagon() and game.wagon_cache==remaining and game.state.party_size==5,"Repeated no-ox inspection never duplicates guards or cached gear")
 trip(game,"No-ox reunion saves")
 game=outfit()
 game.abandon_wagon({"food":20,"clothing":4},[1])
 var broken: Dictionary=Store.new().capture(game)
 broken.wagon_cache.location.offset+=1
 check(Store.new().restore(broken)==null,"Cache coordinates must agree with their recorded guide mile")
 broken=Store.new().capture(game)
 broken.wagon_cache.guards[0].vitamin_days=-1
 check(Store.new().restore(broken)==null,"Reject malformed hidden guard nutrition")
 game=outfit()
 disable_loss(game)
 game.provisions.data.wagon_guards.departure_chance=0
 var employee: Dictionary=game.characters.profiles[1]
 employee.specials=["Mercenary"]
 check(game.characters.start_contract(game,1,1000,2),"Set a legal two-day guard wage contract")
 game.abandon_wagon({"food":20,"clothing":4},[1])
 rest_day(game)
 check(employee.contract.arrears_cents==1000 and not game.characters.pay_wages(game,1),"Living guard earns wages but cannot receive remote money")
 var trust: int=employee.trust
 rest_day(game)
 check(employee.contract.misses>0 and employee.trust<trust,"Missed guard wage changes trust and preserves debt")
 game.pending={}
 game.inspect_cached_wagon()
 check(game.characters.pay_wages(game,1) and employee.contract.arrears_cents==0,"Actual reunion permits payment of accumulated guard debt")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.game=outfit()
 screen._show_packing()
 check(screen.packing_guards.size()==4,"Packing offers all four companion guard choices")
 screen.packing_guards[1].button_pressed=true
 screen.packing_quantities.food.value=0
 screen._update_packing_quote()
 check(screen.packing_quote.text.contains("GUARDS: 1"),"Actual packing panel previews selected guards and cached provisions")
 screen.packing_window.hide()
 screen.game.abandon_wagon({"food":20,"clothing":4},[1])
 screen._show_party()
 screen.selected_member=1
 screen._refresh_party()
 check(screen.member_details.text.contains("GUARDING") and not screen.wages_button.visible,"Party UI shows only last-known guard status")
 screen.queue_free()
 await process_frame
 print("Wagon guards: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
