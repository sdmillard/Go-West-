extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Outfit=preload("res://simulation/outing_outfit.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party(seed_value: int=5711):
 var g=Sim.new(seed_value,"classic",true)
 g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"horses":1,"saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":2,"salt":10})
 g.pending={}
 return g
func run():
 var g=party()
 var before: Dictionary=Save.new().capture(g)
 var normal: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"ride")
 var heavy: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"ride_strenuous")
 var lead: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"lead")
 var led_heavy: Dictionary=g.hunt_outfit_quote([0],"ride_horse",5,"lead_strenuous")
 check(normal.valid and normal.search_factor==1,"Normal riding keeps baseline search opportunities")
 check(normal.search_factor>heavy.search_factor and heavy.search_factor>lead.search_factor and lead.search_factor>led_heavy.search_factor,"Greater return time consistently reserves search time")
 check(lead.capacity_lb>normal.capacity_lb and heavy.capacity_lb>normal.capacity_lb,"Time cost leaves actual carrying allowances intact")
 check(lead.return_hours>normal.return_hours and lead.search_hours<normal.search_hours,"Leader quote exposes actual planned return/search tradeoff")
 var away_quote: Dictionary=Outfit.quote(g,[1],"ride_horse",2,5,"lead")
 check(away_quote.search_factor>lead.search_factor and away_quote.search_factor<1,"A hunter already out reserves return time without charging the outward journey again")
 check(Save.new().capture(g)==before,"Planning changes no state, inventory, time, assignments or RNG")
 var rules: Dictionary=g.hunting.data.duplicate(true)
 for value in [0,-1,INF,"hours"]:
  var bad: Dictionary=rules.duplicate(true);bad.return_time.radius_miles=value
  check(not g.hunting.load_data(bad),"Malformed return planning rule rejects")
 check(g.hunting.load_data(rules),"Planning rules reload")
 var a_count:=0;var b_count:=0
 for seed_value in range(200):
  var a: Dictionary=g.hunting.begin(seed_value,1,90,"plains",false)
  var b: Dictionary=g.hunting.begin(seed_value,1,90,"plains",false,lead.search_factor)
  check(a.cover==b.cover and b.animals.size()<=a.animals.size(),"Lost search time changes only opportunities, not cover or yields")
  for animal in b.animals:check(animal in a.animals,"Retained game keeps the same carcass and shot target")
  a_count+=a.animals.size();b_count+=b.animals.size()
 check(b_count>0 and b_count<a_count,"Slower return has an effective opportunity cost, while still allowing successful hunts")
 check(g.start_hunt({"members":[0],"kit":"ride_horse","bullets":5,"return_mode":"lead"}),"Leader can choose the slower return")
 var expected: Dictionary=g.hunting.begin(5711,1,0,"woodland",false,lead.search_factor)
 check(g.hunt.animals==expected.animals,"Interactive hunt applies the quoted search budget")
 var day: int=g.state.day;g.hunt.meat=60
 check(g.finish_hunt() and g.state.day==day+1 and g.last_hunt_recovery.eaten_food==15,"Reduced search still settles exactly one day and one actual party meal")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-hunt-time-v5.json"))
 var copy=Save.new().restore(old)
 check(copy!=null and copy.state==Save.new().normalize(old.state) and str(copy.rng.state)==old.random,"Genuine previous-rule active outing restores stock, state and main RNG")
 if copy!=null:check(copy.field_outings.snapshot()==Save.new().normalize(old.field_outings),"Migration preserves the actual trip and private random stream")
 var first_day_same:=true;var normal_hits:=0;var led_hits:=0
 for seed_value in range(600,700):
  for at in [1,2]:
   var hits: Array=[]
   for mode in ["ride","lead"]:
    var field=party(seed_value)
    check(field.field_outings.start(field,1,"ride_horse",2,5,mode),"Real companion outfit can start for return-time comparison")
    var trip: Dictionary=field.field_outings.record.trips[0]
    field.state.day=at
    var prior: int=trip.camp.inventory.food
    var ammunition: int=trip.camp.inventory.bullets
    var random:=RandomNumberGenerator.new();random.seed=seed_value+at*1701
    field.field_outings._hunt(field,trip,random)
    hits.append(int(trip.camp.inventory.food)>prior)
    check(trip.camp.inventory.bullets==ammunition-1,"Return planning does not duplicate field ammunition costs")
   if at==1:first_day_same=first_day_same and hits[0]==hits[1]
   else:
    if hits[0]:normal_hits+=1
    if hits[1]:led_hits+=1
    check(not hits[1] or hits[0],"Reduced field search only removes existing opportunities")
 check(first_day_same,"Companion's earlier hunting days are not penalized for the later return")
 check(led_hits>0 and led_hits<normal_hits,"Companion return day uses the same effective search tradeoff")
 var main=load("res://ui/main.tscn").instantiate();root.add_child(main);await process_frame
 main.game=party();main.departure_view.hide()
 main.outing_window.open(main.game,-1)
 main.outing_window.kit.select(1);main.outing_window.return_load.select(2)
 for box in main.outing_window.helper_checks.values():box.button_pressed=false
 main.outing_window.refresh();await process_frame
 check("SLOWER RETURN" in main.outing_window.summary.text and not main.outing_window.get_ok_button().disabled,"Outfit UI shows the tradeoff before confirming")
 main.queue_free();await process_frame
 print("Hunt return planning: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
