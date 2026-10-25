extends "res://tests/current_journey_policy.gd"
const Observed=preload("res://tests/hunt_balance_observer.gd")
var reserve_meals:=2
var player_accuracy:=0.65
var travel_pace:=0
var outfit_profile: String="standard"
const METHODS=["legacy","foot","ride","heavy","lead","wagon","outrider"]
func source_hashes() -> Dictionary:
 var result: Dictionary={}
 for folder in ["simulation","data","tests"]:
  for file in DirAccess.get_files_at("res://"+folder):
   if file.ends_with(".gd") or file.ends_with(".json"):result[folder+"/"+file]=FileAccess.get_sha256("res://"+folder+"/"+file)
 return result
func starting_cart(game,method: String,equipment: String) -> Dictionary:
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 cart.dried_produce=20
 if outfit_profile=="lean":cart.oxen=4;cart.food=1200
 if equipment=="shared" or method in ["ride","heavy","lead","outrider"]:cart.merge({"horses":1,"saddles":1,"saddlebags":1},true)
 return cart
func policy(method: String) -> Dictionary:
 return {"method":method,"pace":travel_pace,"rations":1,"rest":true,"hunt":true,"accuracy":player_accuracy,"hunt_below":90,"rest_below":55,"health_rest_limit":1,"care_below":55,"produce":true,"forage_gap":20,"preserve":"salt","preserve_meals":3.3,"slaughter":true,"slaughter_team_floor":4,"opportunity":1,"cash_reserve":20}
func count_template() -> Dictionary:
 return {"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
func without_hunt(game,p: Dictionary,aim,count: Dictionary) -> bool:
 var other: Dictionary=p.duplicate();other.hunt=false
 return super.act(game,other,aim,count)
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if game.pending.get("outing_warning",false):return service_choice(game,"outing_choice","leave")
 var current: Dictionary=p.duplicate()
 current.hunt_below=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])*maxi(reserve_meals,4 if p.method=="outrider" else reserve_meals)
 return super.act(game,current,aim,count)
func hunters(game) -> Array:
 var members: Array=[]
 for person in game.party_health.members:
  if game.party_health.is_active(person) and game.provisions.Carrying.factor(person,game.provisions.data.walking.health_load_curve)>0 and game.characters.willing(int(person.id),"hunt"):members.append(int(person.id))
 return members
func foot_offer(game) -> Dictionary:
 var members: Array=hunters(game)
 for id in members:
  if id>0:game.camp_tasks.assign(game,id,"hunt_help")
 return {"members":members,"kit":"foot","bullets":mini(30,int(game.state.bullets))}
func hunt_outing(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if p.method=="legacy":return super.hunt_outing(game,p,aim,count)
 var offer: Dictionary={}
 var method: String=p.method
 if method=="outrider":
  if not game.field_outings.record.trips.is_empty() and game.state.food>=int(game.state.party_size)*3:return without_hunt(game,p,aim,count)
  if game.field_outings.record.trips.is_empty():
   for id in hunters(game):
    if id>0 and game.field_outings.start(game,id,"ride_horse",2,10,"lead"):
     bump(count,"dispatches");return true
  bump(count,"outrider_foot_fallback")
  method="foot"
 if method in ["ride","heavy","lead"]:
  var actual: Array=game.party_health.members.filter(func(m):return game.party_health.is_active(m))
  var leader: int=int(actual[0].id) if not actual.is_empty() else -1
  offer={"members":[leader],"kit":"ride_horse","bullets":mini(30,int(game.state.bullets)),"return_mode":{"ride":"ride","heavy":"ride_strenuous","lead":"lead"}[method]}
  if not game.hunt_outfit_quote(offer.members,offer.kit,offer.bullets,offer.return_mode).get("valid",false):
   bump(count,"mounted_foot_fallback");method="foot"
 if method=="wagon":
  offer={"members":game.party_health.members.filter(func(m):return game.party_health.is_active(m)).map(func(m):return int(m.id)),"kit":"wagon","bullets":5}
  if not game.hunt_outfit_quote(offer.members,"wagon",5).get("valid",false):bump(count,"wagon_foot_fallback");method="foot"
 if method=="foot":offer=foot_offer(game)
 if not game.start_hunt(offer):
  var rejected: Dictionary=game.hunt_outfit_quote(offer.members,offer.kit,offer.bullets,str(offer.get("return_mode","ride")))
  if not count.has("unavailable_reasons"):count.unavailable_reasons={}
  var reason: String=str(rejected.get("message","Action unavailable"))
  count.unavailable_reasons[reason]=int(count.unavailable_reasons.get(reason,0))+1
  if not count.has("first_unavailable"):
   count.first_unavailable={"day":int(game.state.day),"food":int(game.state.food),"clothing":int(game.state.clothing),"bullets":int(game.state.bullets),"party":int(game.state.party_size),"offer":offer,"quote":rejected,"members":game.party_health.members.map(func(m):return {"id":int(m.id),"health":int(m.health),"conditions":m.conditions.duplicate(true),"away":m.get("away",false)})}
  bump(count,"hunt_unavailable")
  return without_hunt(game,p,aim,count)
 bump(count,"hunts");bump(count,"method_"+method)
 var bullets: int=game.hunt_ammo()
 var condition: int=game.Mounts.condition(game.state)
 for tick in range(120):
  if game.hunt.ended or game.hunt_ammo()==0:break
  var target: int=-1;var best: int=-1;var obstructed: int=-1
  for index in range(game.hunt.animals.size()):
   if index in game.hunt.targets or game.hunt.animals[index].escaped:continue
   var point: Vector2=game.hunting.bounds(game.hunt,index).get_center()
   if game.hunting.target_at(game.hunt,point)==index:
    if int(game.hunt.animals[index].meat)>best:target=index;best=int(game.hunt.animals[index].meat)
   else:obstructed=index
  if target>=0 and game.hunt.reload<=0:
   game.hunt_fire_at(game.hunting.bounds(game.hunt,target).get_center() if aim.randf()<float(p.accuracy) else Vector2.ZERO)
  elif target<0 and obstructed>=0:game.move_hunter(Vector2(game.hunting.bounds(game.hunt,obstructed).get_center().x,140))
  game.advance_hunt(0.25)
 count.shots+=bullets-game.hunt_ammo()
 count.meat_obtained+=int(game.hunt.meat)
 if game.hunt.meat==0:count.empty_hunts+=1
 var okay: bool=game.finish_hunt()
 if okay:
  count.last_hunt_day=int(game.state.day)
  count.meat_carried+=float(game.last_hunt_recovery.mass)
  bump(count,"meat_food_units",int(game.last_hunt_recovery.food))
  bump(count,"field_meal_units",int(game.last_hunt_recovery.eaten_food))
  bump(count,"leader_net_condition_loss",maxi(0,condition-game.Mounts.condition(game.state)))
 return okay
func run():
 adaptive=true;hunting_study=true
 var label: String="pilot-01"
 var seed_start:=84000;var seeds:=2
 var months: Array=[5];var professions: Array=["farmer"];var equipment: Array=["shared","practical"];var methods: Array=METHODS.duplicate()
 for arg in OS.get_cmdline_user_args():
  var value: String=arg.get_slice("=",1)
  match arg.get_slice("=",0):
   "--label":label=value.validate_filename()
   "--seed-start":seed_start=int(value)
   "--seeds":seeds=clampi(int(value),1,30)
   "--months":months=Array(value.split(",")).map(func(v):return int(v))
   "--professions":professions=Array(value.split(","))
   "--equipment":equipment=Array(value.split(","))
   "--pace":travel_pace=clampi(int(value),0,2)
   "--outfit":outfit_profile=value
   "--accuracy":player_accuracy=clampf(float(value),0,1)
   "--reserve-meals":reserve_meals=clampi(int(value),1,8)
   "--methods":methods=Array(value.split(","))
 var path: String="res://.tools/hunting-"+label+".json"
 if outfit_profile not in ["standard","lean"] or FileAccess.file_exists(path) or not months.all(func(v):return v in [3,4,5,6,7,8]) or not professions.all(func(v):return v in ["farmer","carpenter","banker"]) or not equipment.all(func(v):return v in ["shared","practical"]) or not methods.all(func(v):return v in METHODS):
  printerr("Invalid cohort or existing report");quit(1);return
 var store=Store.new();var frozen: Dictionary=source_hashes();var rules: String=store.fingerprint()
 var rows: Array=[];var errors: Array=[]
 for profession in professions:
  for month in months:
   for kit in equipment:
    for method in methods:
     for seed_value in range(seed_start,seed_start+seeds):
      var game=Observed.new(seed_value,"classic",true)
      var cart: Dictionary=starting_cart(game,method,kit)
      var row: Dictionary={"profession":profession,"month":month,"equipment":kit,"method":method,"seed":seed_value,"outfit":cart}
      var opening: Dictionary=game.outfitter.quote(profession,cart);row.opening_cost_cents=opening.total_cents
      if not game.depart(profession,["A","B","C","D","E"],month,cart):errors.append({"run":row,"error":game.departure_error});continue
      row.opening_cash=game.state.money
      var count: Dictionary=count_template()
      var p: Dictionary=policy(method)
      var aim:=RandomNumberGenerator.new();aim.seed=seed_value^0x41494d
      var outcome: String="action_limit";var idle:=0
      var curve: Array=[];var next_sample:=0
      for step in range(2400):
       if game.state.status!="traveling":outcome=game.state.status;break
       if game.state.day>=365:outcome="year_limit";break
       var day: int=game.state.day;var mile: int=game.state.miles
       if not act(game,p,aim,count):outcome="policy_blocked";errors.append({"run":row,"error":outcome,"pending":game.pending});break
       idle=idle+1 if game.state.day==day and game.state.miles==mile else 0
       if idle>32:outcome="policy_stalled";errors.append({"run":row,"error":outcome});break
       if game.state.miles>mile:count.travel_days+=1
       if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
       if game.state.food<0 or game.state.money<0 or game.state.bullets<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health() or game.audit.days!=game.state.day or not game.error.is_empty():
        outcome="invariant_failed";errors.append({"run":row,"error":outcome});break
       if step%100==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:outcome="save_failed";errors.append({"run":row,"error":outcome});break
       if game.state.day>=next_sample:
        curve.append([game.state.day,game.state.miles,game.state.food,game.state.money,game.state.party_size,game.Mounts.condition(game.state)])
        next_sample=game.state.day+30
      if outcome=="action_limit":errors.append({"run":row,"error":outcome})
      if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":row,"error":"Final save: "+store.error})
      row.merge({"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"original_present":game.party_health.members.slice(0,5).filter(func(m):return game.party_health.is_active(m)).size(),"away":game.field_outings.record.trips.size(),"original_survived":game.party_health.members.slice(0,5).filter(func(m):return game.field_outings.actual_alive(int(m.id)) if m.get("away",false) else game.party_health.is_active(m)).size(),"cash":game.state.money,"food":game.state.food,"oxen":game.state.oxen,"horses":game.Mounts.count(game.state,"horses"),"horse_condition":game.Mounts.condition(game.state),"counts":count,"audit":game.audit,"meals_eaten":game.provisions.eaten_units,"spoilage_food_units":game.provisions.spoiled_units,"field":game.field_outings.audit,"curve":curve,"route":game.travelled_path(),"loss_reason":game.state.loss_reason,"death_causes":game.party_health.members.filter(func(m):return not m.alive).map(func(m):return m.cause)})
      rows.append(row);await process_frame
     print("%s month%d %s %s: %d journeys, %d errors" % [profession,month,kit,method,rows.size(),errors.size()])
 if frozen!=source_hashes() or rules!=store.fingerprint():errors.append({"error":"Sources changed during campaign"})
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"rules_signature":rules,"source_hashes":frozen,"seed_start":seed_start,"seeds":seeds,"reserve_meals":reserve_meals,"player_accuracy":player_accuracy,"pace":travel_pace,"outfit_profile":outfit_profile,"months":months,"professions":professions,"equipment":equipment,"methods":methods,"runs":rows,"errors":errors},"\t"))
 print("Hunting campaign: %d journeys, %d errors" % [rows.size(),errors.size()])
 quit(0 if errors.is_empty() and rows.size()==professions.size()*months.size()*equipment.size()*methods.size()*seeds else 1)
