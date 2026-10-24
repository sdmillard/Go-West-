extends "res://tests/current_journey_policy.gd"
## Declared public-action policy; no injected health, money, food, weather or random outcomes.
const Observed=preload("res://tests/balance_observer.gd")
const MODES=["wagon","mounted","packing","walking"]
func outfit(game,mode: String) -> Dictionary:
 var cart: Dictionary={}
 if mode=="wagon":
  for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
  cart.dried_produce=20
 else:
  cart={"wagon":0,"oxen":0,"food":45 if mode=="walking" else 450,"clothing":5,"bullet_boxes":1 if mode=="walking" else 5,"medicine":1,"salt":2 if mode=="walking" else 5,"dried_produce":3 if mode=="walking" else 10}
  if mode=="mounted":cart.merge({"horses":5,"mules":3,"saddles":5,"pack_saddles":3,"saddlebags":5},true)
  if mode=="packing":cart.merge({"mules":3,"pack_saddles":3},true)
 return cart
func policy(mode: String,strategy: String,accuracy: float=0.65) -> Dictionary:
 return {"pace":0,"rations":1,"rest":true,"hunt":strategy!="no_hunt","accuracy":accuracy,"hunt_below":90,"rest_below":55,"care_below":55,"produce":true,"forage_gap":20,"preserve":"" if strategy=="no_hunt" else "salt","preserve_meals":3.3,"slaughter":true,"slaughter_team_floor":4,"opportunity":1,"cash_reserve":20,"mount_support":true,"mount_rest_below":65,"mount_targets":{"horses":5,"mules":3} if mode=="mounted" else ({"mules":3} if mode=="packing" else {})}
func source_hashes() -> Dictionary:
 var hashes: Dictionary={}
 for folder in ["simulation","data","tests"]:
  for file in DirAccess.get_files_at("res://"+folder):
   if file.ends_with(".gd") or file.ends_with(".json"):hashes[folder+"/"+file]=FileAccess.get_sha256("res://"+folder+"/"+file)
 return hashes
func run():
 adaptive=true
 hunting_study=true
 var label: String="mount-development-01"
 var seed_start: int=61000
 var seeds: int=3
 var accuracy: float=0.65
 var stress: String="none"
 var modes: Array=MODES.duplicate()
 var months: Array=[4,5,8]
 var strategies: Array=["salt","no_hunt"]
 var professions: Array=["farmer","carpenter","banker"]
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--label="):label=argument.get_slice("=",1).validate_filename()
  if argument.begins_with("--seed-start="):seed_start=int(argument.get_slice("=",1))
  if argument.begins_with("--seeds="):seeds=clampi(int(argument.get_slice("=",1)),1,30)
  if argument.begins_with("--accuracy="):accuracy=float(argument.get_slice("=",1))
  if argument.begins_with("--stress="):stress=argument.get_slice("=",1)
  if argument.begins_with("--modes="):modes=Array(argument.get_slice("=",1).split(","))
  if argument.begins_with("--months="):months=Array(argument.get_slice("=",1).split(",")).map(func(v):return int(v))
  if argument.begins_with("--strategies="):strategies=Array(argument.get_slice("=",1).split(","))
  if argument.begins_with("--professions="):professions=Array(argument.get_slice("=",1).split(","))
 var path: String="res://docs/balance-"+label+".json"
 if FileAccess.file_exists(path) or not modes.all(func(v):return v in MODES) or not months.all(func(v):return v in [3,4,5,6,7,8]) or not strategies.all(func(v):return v in ["salt","no_hunt"]) or not professions.all(func(v):return v in ["farmer","carpenter","banker"]) or accuracy<0 or accuracy>1 or stress not in ["none","guard","doubled","four_oxen","abandon","heavy_pack"] or (stress=="heavy_pack" and modes!=["packing"]) or (stress=="doubled" and modes!=["mounted"]) or (stress in ["four_oxen","abandon"] and modes!=["wagon"]):
  printerr("Invalid cohort or archive already exists");quit(1);return
 var hashes: Dictionary=source_hashes()
 var store=Store.new()
 var rules: String=store.fingerprint()
 var rows: Array=[]
 var errors: Array=[]
 for profession in professions:
  for mode in modes:
   for month in months:
    for strategy in strategies:
     for seed_value in range(seed_start,seed_start+seeds):
      var game=Observed.new(seed_value,"classic",true)
      var cart: Dictionary=outfit(game,mode)
      if stress=="four_oxen":cart.oxen=4
      if stress=="heavy_pack":cart.mules=8;cart.pack_saddles=8;cart.food=1400
      if stress=="doubled":
       cart.horses=3;cart.saddles=3;cart.saddlebags=3
      var quote: Dictionary=game.outfitter.quote(profession,cart)
      var row: Dictionary={"profession":profession,"mode":mode,"month":month,"strategy":strategy,"seed":seed_value,"outfit":cart,"opening_quote":quote}
      if not game.depart(profession,["A","B","C","D","E"],month,cart):
       errors.append({"run":row,"error":"Departure: "+game.departure_error});continue
      if stress=="doubled" and not game.set_double_up(true):errors.append({"error":"Could not order doubled riding"})
      if stress=="guard":game.set_night_guard(true)
      if stress=="abandon" and not abandon(game,{}):errors.append({"error":"Could not abandon wagon legally"})
      var profile: Dictionary=policy(mode,strategy,accuracy)
      if stress=="doubled":profile.mount_targets={"horses":3,"mules":3}
      if stress=="heavy_pack":profile.mount_targets={"mules":8}
      var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
      var aim:=RandomNumberGenerator.new()
      aim.seed=seed_value ^ 0x41494d
      var outcome: String="action_limit"
      var idle: int=0
      var miles_moved: int=0
      var modes_used: Dictionary={}
      var places: Array=[]
      for step in range(2400):
       if game.state.status!="traveling":outcome=game.state.status;break
       if game.state.day>=365:outcome="year_limit";break
       var day: int=game.state.day
       var mile: int=game.state.miles
       var travel_mode: String=game.mount_plan().mode
       modes_used[travel_mode]=int(modes_used.get(travel_mode,0))+1
       var okay: bool=act(game,profile,aim,count)
       if not okay:
        outcome="policy_blocked";errors.append({"run":[profession,mode,month,strategy,seed_value],"error":outcome,"pending":game.pending});break
       idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
       if idle>32:
        outcome="policy_stalled";errors.append({"run":[profession,mode,month,strategy,seed_value],"error":outcome,"pending":game.pending});break
       if game.state.miles>mile:
        count.travel_days+=1
        miles_moved+=game.state.miles-mile
       if game.state.day>day and game.pending.has("landmark"):
        places.append({"place":game.state.landmark,"day":game.state.day,"month":game.calendar().month,"stock":game.Mounts.animals(game.state),"condition":game.Mounts.condition(game.state)})
       if game.state.food<0 or game.state.money<0 or game.state.bullets<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health() or int(game.audit.days)!=int(game.state.day) or not game.error.is_empty():
        errors.append({"run":[profession,mode,month,strategy,seed_value],"error":"State invariant"});outcome="invariant_failed";break
       if step%100==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:
        errors.append({"run":[profession,mode,month,strategy,seed_value],"error":"Save: "+store.error});outcome="save_failed";break
      if outcome=="action_limit":errors.append({"run":[profession,mode,month,strategy,seed_value],"error":outcome})
      if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":[profession,mode,month,strategy,seed_value],"error":"Final save: "+store.error})
      row.merge({"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"original_present":game.party_health.members.slice(0,5).filter(func(m):return game.party_health.is_active(m)).size(),"cash":game.state.money,"food":game.state.food,"oxen":game.state.oxen,"horses":game.Mounts.count(game.state,"horses"),"mules":game.Mounts.count(game.state,"mules"),"horse_condition":game.Mounts.condition(game.state),"arrival_month":game.calendar().month,"counts":count,"audit":game.audit,"miles_per_moving_day":float(miles_moved)/maxi(1,int(count.travel_days)),"modes_used":modes_used,"places":places,"breakdowns":game.supply_history.filter(func(h):return h.event=="animal_breakdown").size(),"loss_reason":game.state.loss_reason,"death_causes":game.party_health.members.filter(func(m):return not m.alive).map(func(m):return m.cause),"scurvy_cases":game.party_health.members.reduce(func(n,m):return n+m.history.filter(func(h):return str(h).contains("has scurvy.")).size(),0)})
      rows.append(row)
      await process_frame
     print("%s %s month%d %s: %d journeys, %d errors" % [profession,mode,month,strategy,rows.size(),errors.size()])
 if hashes!=source_hashes() or rules!=store.fingerprint():errors.append({"error":"Sources changed during campaign"})
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"rules_signature":rules,"source_hashes":hashes,"seed_start":seed_start,"seed_count":seeds,"accuracy":accuracy,"stress":stress,"months":months,"modes":modes,"strategies":strategies,"professions":professions,"runs":rows,"errors":errors},"\t"))
 print("Mount campaign: %d journeys, %d errors" % [rows.size(),errors.size()])
 quit(0 if errors.is_empty() and rows.size()==professions.size()*modes.size()*months.size()*strategies.size()*seeds else 1)
