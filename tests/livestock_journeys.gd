extends "res://tests/current_journey_policy.gd"
## Declared integration pilot, not held-out balance evidence. Uses the existing survival policy.
func signatures() -> Dictionary:
 var result: Dictionary={}
 for folder in ["simulation","data"]:
  for source in DirAccess.get_files_at("res://"+folder):
   if source.ends_with(".gd") or source.ends_with(".json"):result[folder+"/"+source]=FileAccess.get_sha256("res://"+folder+"/"+source)
 for source in ["livestock_journeys.gd","current_journey_policy.gd","outlaw_journeys.gd","full_trail_balance.gd"]:result["tests/"+source]=FileAccess.get_sha256("res://tests/"+source)
 return result
func run():
 adaptive=true;hunting_study=true
 var path: String="res://.tools/livestock-journeys-01.json"
 if FileAccess.file_exists(path):printerr("Use a fresh isolated checkout; report already exists");quit(1);return
 var store=Store.new()
 var rules: String=store.fingerprint()
 var sources: Dictionary=signatures()
 var rows: Array=[]
 var errors: Array=[]
 var policy: Dictionary={"id":"livestock_pilot","pace":1,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":90,"adaptive_rations":true,"preserve":"salt","slaughter":true,"slaughter_team_floor":4,"rest_below":55,"health_rest_limit":2,"preserve_meals":3.3,"opportunity":1,"produce":true}
 for profession in ["farmer","carpenter","banker"]:
  for month in [5,7]:
   for cohort in ["none","dairy_mix","spare_oxen"]:
    for seed_value in range(301010,301012):
     var identity: Dictionary={"profession":profession,"month":month,"cohort":cohort,"seed":seed_value}
     var g=Simulation.new(seed_value,"classic",true)
     var cart: Dictionary={}
     for good in g.outfitter.goods:cart[good.id]=int(good.suggested)
     if cohort=="dairy_mix":cart.merge({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200},true)
     if cohort=="spare_oxen":cart.oxen=8
     var opening: Dictionary=g.outfitter.quote(profession,cart)
     if not g.depart(profession,["A","B","C","D","E"],month,cart):errors.append({"run":identity,"error":g.departure_error});continue
     var aim:=RandomNumberGenerator.new();aim.seed=seed_value^0x4f55544c
     var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
     var outcome: String="limit"
     var idle:=0
     var swaps:=0
     for step in range(3000):
      if g.state.status!="traveling":outcome=g.state.status;break
      if g.state.day>=365:outcome="out_of_time";break
      var before_day: int=g.state.day
      var before_mile: int=g.state.miles
      var okay:=true
      if g.can_service() and cohort=="spare_oxen" and int(g.state.ox_health)<70:
       var selection: Array=range(g.team_conditions.record.oxen.size())
       selection.sort_custom(func(a,b):return int(g.team_conditions.record.oxen[a])>int(g.team_conditions.record.oxen[b]))
       selection=selection.filter(func(i):return int(g.team_conditions.record.oxen[i])>0).slice(0,6)
       if selection!=g.team_conditions.record.working and g.team_conditions.select(g,selection):swaps+=1
      var excess: float=g.provisions.cargo(g.state)-g.provisions.storage_capacity(g.state)
      if g.can_service() and g.state.vehicle=="foot" and excess>0 and int(g.state.get("poultry_feed",0))>0:
       okay=g.livestock.drop_grain(g,mini(int(g.state.poultry_feed),ceili(excess/0.25)))
      else:okay=act(g,policy,aim,count)
      if not okay:outcome="policy_blocked";errors.append({"run":identity,"error":outcome,"pending":g.pending.get("id","")});break
      idle=idle+1 if before_day==g.state.day and before_mile==g.state.miles else 0
      if idle>40:outcome="policy_stalled";errors.append({"run":identity,"error":outcome});break
      if g.state.food<0 or g.state.money<0 or g.state.bullets<0 or not g.livestock.valid(g.livestock.record,g.state) or g.provisions.tracked_food(g.state.food)>g.state.food:
       outcome="invariant_failed";errors.append({"run":identity,"error":outcome});break
      if step%80==0:
       var saved: Dictionary=store.capture(g)
       if not saved.is_empty() and store.restore(JSON.parse_string(JSON.stringify(saved)))==null:
        FileAccess.open("res://.tools/livestock-failed-save.json",FileAccess.WRITE).store_string(JSON.stringify(saved))
        outcome="save_failed";errors.append({"run":identity,"error":store.error});break
     if store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))==null:errors.append({"run":identity,"error":"final save"})
     var produced:=0
     var grain:=0
     var eggs:=0
     var milk:=0.0
     for entry in g.supply_history:
      if entry.event=="livestock":
       produced+=int(entry.products.food);grain+=int(entry.products.feed_quarters);eggs+=int(entry.products.eggs);milk+=float(entry.products.milk_lb)
     var row: Dictionary=identity.duplicate();row.merge({"outcome":outcome,"days":g.state.day,"miles":g.state.miles,"survivors":g.state.party_size,"opening_cost_cents":opening.total_cents,"opening_cash_cents":opening.remaining_cents,"cart":cart,"food_produced":produced,"milk_lb":snappedf(milk,0.01),"eggs":eggs,"feed_lb":grain*0.25,"swaps":swaps,"animals":g.livestock.record.animals.duplicate(true),"teams":g.team_conditions.record.duplicate(true)})
     rows.append(row);print("%s: %s, day %d" % [str(identity),outcome,g.state.day])
 if sources!=signatures() or rules!=store.fingerprint():errors.append({"error":"sources changed during pilot"})
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"rules_signature":rules,"source_hashes":sources,"runs":rows,"errors":errors,"policy":policy,"note":"36 journeys, 3 professions x May/July x 3 outfits x 2 development seeds 301010-301011. Same starting budgets; animals cost money and feed/coop mass. Existing current survival policy; no new livestock buying, feeding resupply, milking assignment or slaughter optimization. Spare-ox arm selects the six fittest when working average falls below 70. Grain may be discarded to fit walking packs. Not a completed balance pass or held-out test."},"\t"))
 print("Livestock pilot: %d journeys, %d errors" % [rows.size(),errors.size()]);quit(0 if errors.is_empty() else 1)
