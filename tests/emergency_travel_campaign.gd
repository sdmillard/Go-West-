extends "res://tests/mount_provisioned_campaign.gd"
## Controlled plausible emergencies, not fictitious full journeys from Missouri.
## Initial location, lost team and health scenario are fixtures; all following actions are real.
func source_hashes() -> Dictionary:
 var hashes: Dictionary=super.source_hashes()
 hashes[get_script().resource_path]=FileAccess.get_sha256(get_script().resource_path)
 return hashes
func run():
 adaptive=true
 hunting_study=true
 var label: String="emergency-development-01"
 var start: int=67000
 var seeds: int=4
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--label="):label=argument.get_slice("=",1).validate_filename()
  if argument.begins_with("--seed-start="):start=int(argument.get_slice("=",1))
  if argument.begins_with("--seeds="):seeds=clampi(int(argument.get_slice("=",1)),1,30)
 var path: String="res://docs/"+label+".json"
 if FileAccess.file_exists(path):printerr("Archive exists");quit(1);return
 var frozen: Dictionary=source_hashes()
 var store=Store.new()
 var rows: Array=[]
 var errors: Array=[]
 var probe=Simulation.new(1,"classic",true)
 var road: Array=probe.route.main_path_to("fort_laramie")
 var target: int=0
 for index in range(road.size()-1):target+=int(probe.route.edge_between(road[index],road[index+1]).miles)
 for mode in ["wagon","walking","packing","mounted"]:
  for health in ["ordinary","weakened","broken_leg"]:
   for distance in [30,75,150]:
    for month in [6,8]:
     for seed_value in range(start,start+seeds):
      var game=Observed.new(seed_value,"classic",true)
      var cart: Dictionary=outfit(game,"wagon")
      cart.food=600
      if mode=="packing":cart.merge({"mules":3,"pack_saddles":3},true)
      if mode=="mounted":cart.merge({"horses":5,"mules":3,"saddles":5,"pack_saddles":3,"saddlebags":5},true)
      var identity: Array=[mode,health,distance,month,seed_value]
      if not game.depart("banker",["A","B","C","D","E"],month,cart):errors.append({"run":identity,"error":game.departure_error});continue
      game.configure(0,1)
      game.CacheSupport.relocate(game,target-distance)
      if mode!="wagon":game.state.oxen=0
      if health=="weakened":
       for member in game.party_health.members:member.health=60
      if health=="broken_leg":game.party_health.begin_condition(1,"broken_leg",0)
      game.state.health=game.party_health.average_health()
      var initial: Dictionary=store.capture(game)
      if store.restore(JSON.parse_string(JSON.stringify(initial)))==null:errors.append({"run":identity,"error":"Initial fixture save invalid"});continue
      var count: Dictionary={"hunts":0,"rests":0,"trades":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
      if mode!="wagon" and not abandon(game,count):errors.append({"run":identity,"error":"Could not pack legally"});continue
      var profile: Dictionary=policy(mode,"salt")
      var aim:=RandomNumberGenerator.new()
      aim.seed=seed_value ^ 0x41494d
      var outcome: String="time_limit"
      var idle: int=0
      for step in range(400):
       if game.state.status!="traveling":outcome=game.state.status;break
       if game.state.landmark=="fort_laramie":outcome="reached_help";break
       if game.state.day>=45:break
       var day: int=game.state.day
       var mile: int=game.state.miles
       if not act(game,profile,aim,count):outcome="policy_blocked";errors.append({"run":identity,"error":outcome,"pending":game.pending});break
       idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
       if idle>32:outcome="policy_stalled";errors.append({"run":identity,"error":outcome});break
       if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health():errors.append({"run":identity,"error":"State invariant"});break
       if step%20==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":identity,"error":"Save round trip"});break
      rows.append({"mode":mode,"health_case":health,"distance":distance,"month":month,"seed":seed_value,"initial_fixture":initial,"outcome":outcome,"days":game.state.day,"progress":int(game.state.miles)-(target-distance),"survivors":game.state.party_size,"original_present":game.party_health.members.slice(0,5).filter(func(m):return game.party_health.is_active(m)).size(),"cash":game.state.money,"food":game.state.food,"audit":game.audit,"counts":count,"death_causes":game.party_health.members.filter(func(m):return not m.alive).map(func(m):return m.cause)})
      await process_frame
    print("%s %s %dmi: %d cases, %d errors" % [mode,health,distance,rows.size(),errors.size()])
 if source_hashes()!=frozen:errors.append({"error":"Source files changed during campaign"})
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"rules_signature":store.fingerprint(),"source_hashes":frozen,"seed_start":start,"seed_count":seeds,"protocol":"Controlled emergency 30/75/150 guide miles east of Fort John/Laramie; June/August, banker liquidity, ordinary/health60/one broken leg. All oxen lost outside wagon controls. Real legal abandonment pack, natural illness/weather/events and public provision-first actions. Reach the staffed post within45 elapsed days. No free health, food or transport after the declared initial fixture.","runs":rows,"errors":errors},"\t"))
 print("Emergency campaign: %d cases, %d errors" % [rows.size(),errors.size()])
 quit(0 if rows.size()==4*3*3*2*seeds and errors.is_empty() else 1)
