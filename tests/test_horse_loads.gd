extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Discards=preload("res://simulation/discard_plan.gd")
const Outfit=preload("res://simulation/outing_outfit.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var g=Sim.new(5711,"classic",true)
 check(g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":2,"mules":1,"saddles":1,"pack_saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10}),"Test party departs")
 g.pending={}
 g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 g.seen.append("muddy_trail")
 g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear";g.survival.data.event_chance=0
 g.field_outings.rules.mishap_chance=0;g.field_outings.rules.hit_chance=0;g.field_outings.rules.bandit_daily_chance=0
 for person in g.party_health.members:person.health=100
 g.state.health=g.party_health.average_health()
 for profile in g.characters.profiles:
  if int(profile.id)>0:profile.boundaries.forbidden=[];profile.trust=60
 return g
func run():
 var g=party()
 var store=Save.new()
 var before: Dictionary=store.capture(g)
 for pair in [["ride_horse",75,150],["ride_horse_light",50,125],["pack_horse",275,350],["pack_mule",275,350],["horse_and_mule",300,450]]:
  check(Outfit.capacity(g,[0],pair[0])==pair[1] and Outfit.capacity(g,[0],pair[0],{},"ride_strenuous")==pair[2],"Physical working/hard budgets for "+pair[0])
 check(Outfit.capacity(g,[0],"ride_horse",{},"lead")==275 and Outfit.capacity(g,[0],"ride_horse",{},"lead_strenuous")==350,"Leading frees rider load and adds actual human retrieval")
 var normal: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5)
 var heavy: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"ride_strenuous")
 var lead: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"lead")
 check(normal.rider_lb==150 and normal.tack_lb==25 and normal.pack_lb>15,"Rider, fitted tack and packed personal gear are separate real loads")
 check(heavy.catch_lb-normal.catch_lb==75 and lead.catch_lb>heavy.catch_lb,"Heavy and led returns offer distinct retrieval limits")
 check(store.capture(g)==before,"Quotes preserve stock, state, assignments and RNG")
 var plan: Dictionary=g.Mounts.plan(g.provisions.data.mounts,Outfit.transport(g,[0],"ride_horse"))
 var light: Dictionary=Outfit.load_profile(g,[0],"ride_horse",20)
 var loaded: Dictionary=Outfit.load_profile(g,[0],"ride_horse",150,{},"ride_strenuous")
 check(light.animal_total_lb==195 and loaded.animal_total_lb==325 and loaded.human_cargo_lb==0,"Seated rider does not also contribute a walking backpack")
 check(g.Mounts.speed_factor(plan,loaded)<g.Mounts.speed_factor(plan,light),"Physical heavy load slows a mounted return")
 check(Outfit.wear(g,"ride_horse",1,"plains",loaded.ratio)>Outfit.wear(g,"ride_horse",1,"plains",light.ratio),"Actual excess weight causes extra wear")
 check(Outfit.load_profile(g,[0],"ride_horse",20,{},"ride_strenuous")==light,"Selecting heavy allowance alone invents no actual burden")
 for health in [100,75,50]:
  g.party_health.members[0].health=health
  check(Outfit.capacity(g,[0],"foot")==50,"Good and Fair retain full human retrieval")
 g.party_health.members[0].health=30
 check(Outfit.capacity(g,[0],"foot")<50,"Poor health reduces human retrieval")
 g.party_health.begin_condition(0,"broken_leg",0)
 check(Outfit.capacity(g,[0],"foot")==0,"Broken leg prevents hauling")
 g=party()
 g.state.vehicle="foot";g.state.party_size=5
 check(g.provisions.capacity(g.state)==75+225+160,"Mixed train counts four walkers and one rider without double counting")
 check(g.set_strenuous_load(true) and g.provisions.storage_capacity(g.state)>g.provisions.capacity(g.state),"Explicit heavy transport allowance raises permitted storage")
 check(g.set_lead_mounts(true) and g.mount_plan().riding_people==0 and g.mount_plan().mode=="packing","Lead command switches everyone to walking pace")
 var saved: Dictionary=store.capture(g)
 var copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(copy!=null and copy.state.lead_mounts and copy.state.strenuous_load,"Travel load orders survive saving")
 saved.state.lead_mounts="yes"
 check(store.restore(saved)==null,"Malformed transport load flag is rejected")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horse-loads-v5.json"))
 copy=store.restore(old)
 check(copy!=null and copy.state==store.normalize(old.state) and str(copy.rng.state)==old.random,"Genuine pre-load-revision journey restores without invented state or RNG changes")
 g=party()
 check(g.field_outings.start(g,1,"ride_horse",2,5,"lead_strenuous"),"A companion can plan to ride out and lead home")
 copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
 check(copy!=null and copy.field_outings.record.trips[0].camp.return_mode=="lead_strenuous","Loaded field return and preference survive saving")
 g=party()
 g.party_health.members[0].health=60;g.state.health=g.party_health.average_health()
 g.camp_tasks.assign(g,1,"nurse",0)
 g.state.ox_health=90
 g.camp_tasks.assign(g,3,"forage")
 var jobs: Dictionary=g.camp_tasks.assignments.duplicate(true)
 check(not g.hunt_outfit_quote([0,1],"wagon",5).valid,"Leaving companions at camp prevents bringing the wagon")
 var wagon: Dictionary=g.hunt_outfit_quote([0,1,2,3,4],"wagon",5)
 check(wagon.valid and wagon.catch_lb==floori(g.provisions.storage_capacity(g.state)-g.provisions.cargo(g.state)),"Wagon hunt uses real free cargo")
 check(g.start_hunt({"members":[0,1,2,3,4],"kit":"wagon","bullets":5}),"Whole-party wagon hunt starts")
 check(g.hunt.wagon and g.camp_tasks.day_plan.jobs.is_empty(),"Wagon hunt suspends all camp work including nursing")
 var ammo: int=g.state.bullets
 check(g.hunt_shot(-1) and g.state.bullets==ammo-1,"Wagon hunt spends main inventory bullets exactly once")
 var food: int=g.state.food;var medicine: int=g.state.medicine;var day: int=g.state.day
 check(g.finish_hunt() and g.state.day==day+1 and g.state.food==food-15,"Whole-party wagon outing costs one day and one party meal")
 check(g.state.ox_health<=90,"Working ox team does not get idle-day recovery")
 check(g.state.medicine==medicine and g.camp_tasks.assignments==jobs,"Suspended chores spend no kit and standing orders remain")
 check(not g.finish_hunt(),"Wagon return cannot duplicate supplies")
 g=party()
 for id in [2,3,4]:g.party_health.members[id].alive=false
 g.state.party_size=2
 g.party_health.begin_condition(1,"broken_leg",0)
 check(g.hunt_outfit_quote([0,1],"wagon",5).valid,"Two survivors including an injured passenger can bring the wagon")
 g.state.oxen=0
 check(not g.hunt_outfit_quote([0,1],"wagon",5).valid,"A wagon without a team cannot go hunting")
 g.state.oxen=4;g.state.landmark="south_pass"
 check(not g.hunt_outfit_quote([0,1],"wagon",5).valid,"Inaccessible high-country hunting excludes wagon")
 g=party()
 check(g.field_outings.start(g,1,"foot",1,5),"One companion leaves on foot")
 check(g.hunt_outfit_quote([0,2,3,4],"wagon",5).valid,"Currently absent companions do not need to join the wagon")
 g=party()
 g.state.horses=1
 check(g.field_outings.start(g,1,"ride_horse",1,5,"ride_strenuous"),"Heavy trip reserves its sole horse")
 var trip: Dictionary=g.field_outings.record.trips[0]
 trip.condition=1;trip.camp.inventory.food=120
 g.rest()
 check(g.field_outings.record.trips.size()==1 and trip.stage=="stranded" and trip.stock.horses==0,"A loaded animal can give out; no phantom mounted return")
 check(trip.camp.cached_tack.saddles==1 and trip.stock.saddles==0,"Lost animal leaves real tack at its camp")
 copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
 check(copy!=null,"Stranded hunter and cached tack survive saving")
 g.pending={}
 check(g.field_outings.recover_here(g) and g.state.horses==0 and g.state.saddles==1,"Recovery returns surviving tack without resurrecting horse")
 var tack: int=g.state.saddles
 check(not g.field_outings.recover_here(g) and g.state.saddles==tack,"Cached tack cannot be collected twice")
 var mass: float=g.provisions.cargo(g.state)
 var discards: Dictionary=Discards.quote(g,{"pack_saddles":1})
 check(discards.valid and is_equal_approx(discards.dropped_lb,25),"Unused pack saddle has actual discardable cargo weight")
 check(g.discard_supply("pack_saddles",1) and is_equal_approx(mass-g.provisions.cargo(g.state),25),"Dropping loose tack frees the quoted weight")
 g=party()
 check(not Discards.quote(g,{"saddles":1}).valid,"Fitted saddle cannot be discarded through loose-tack rows")
 var invalid: Dictionary=store.capture(g)
 invalid.state.strenuous_load=1
 check(store.restore(invalid)==null,"Non-boolean heavy-load order is rejected")
 g.field_outings.start(g,1,"ride_horse",1,5)
 invalid=store.capture(g)
 invalid.field_outings.trips[0].camp.return_mode="teleport"
 check(store.restore(invalid)==null,"Unknown outing return mode is rejected")
 var ordinary:=0;var noisy:=0
 for seed_value in range(300):
  var a: Dictionary=g.hunting.begin(seed_value,1,90,"plains")
  var b: Dictionary=g.hunting.begin(seed_value,1,90,"plains",true)
  ordinary+=a.animals.size();noisy+=b.animals.size()
  check(b.animals.size()<=a.animals.size() and b.cover==a.cover,"Wagon noise only removes potential encounters; cover stays seeded")
  for animal in b.animals:check(animal in a.animals,"Noise does not change animal yields, speed or shot targets")
  for animal in a.animals:
   var bounds: Rect2=g.hunting.bounds(a,a.animals.find(animal))
   check(bounds.position.y>=96 and bounds.end.y<=150,"Hunt sprites spawn on usable ground")
 check(noisy>0 and noisy<ordinary,"Wagon noise reduces opportunities without making hunts impossible")
 g.pending={};g.start_hunt()
 g.move_hunter(Vector2(200,0))
 check(g.hunt.destination.y>=120,"Hunter feet cannot walk into the sky")
 print("Horse loads / wagon hunting: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
