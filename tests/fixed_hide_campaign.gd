extends SceneTree
const Driver=preload("res://tests/crew_craft_campaign.gd")
const Observed=preload("res://tests/fixed_hide_observer.gd")
const Store=preload("res://simulation/save_store.gd")
var errors: Array=[]
func _initialize():call_deferred("run")
func driver(stock: String,contract: String,arm: String):
 var d=Driver.new();d.adaptive=true;d.hunting_study=true;d.mastery="skilled";d.motion_policy="mobile";d.camp_policy="support";d.fishing_policy="support";d.livestock_arm=stock;d.stock_policy="aware";d.feeding_policy="fodder";d.travel_pace=1;d.player_accuracy=.65;d.reserve_meals=2;d.income_arm=arm;d.contract_arm=contract
 return d
func clone(snapshot: Dictionary):
 var loaded=Store.new().restore(snapshot)
 if loaded==null:return null
 var g=Observed.new(int(loaded.state.seed),"classic",true)
 # Copy restored production variables, including modules and their bound carrier arrays.
 # Each clone uses a fresh restore; nothing mutable is shared between the two arms.
 for property in loaded.get_property_list():
  if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:g.set(property.name,loaded.get(property.name))
 if Store.new().capture(g)!=Store.new().capture(loaded):errors.append("Clone differs from actual restored save")
 return g
func valid(g) -> bool:return g.error.is_empty() and g.state.food>=0 and g.state.money>=0 and g.state.bullets>=0 and g.state.party_size==g.party_health.living_count() and g.state.health==g.party_health.average_health()
func eligible(g) -> bool:
 return g.state.status=="traveling" and g.can_service() and g.hunt.is_empty() and int(g.state.get("deer_hide",0))>0 and g.leathercraft.quote(g,2,"tan_leather").valid
func continuation(snapshot: Dictionary,aim_state: int,initial_count: Dictionary,stock: String,contract: String,arm: String) -> Dictionary:
 var g=clone(snapshot);var d=driver(stock,contract,arm);var count: Dictionary=initial_count.duplicate(true)
 var aim=RandomNumberGenerator.new();aim.seed=int(g.state.seed)^0x41494d;aim.state=aim_state
 var start_sha: String=JSON.stringify(Store.new().capture(g)).sha256_text()
 var history: int=g.supply_history.size();var idle:=0;var outcome: String="action_limit"
 for step in range(2400):
  if g.state.status!="traveling":outcome=g.state.status;break
  if g.state.day>=365:outcome="year_limit";break
  var day: int=int(g.state.day);var mile: int=int(g.state.miles)
  if not d.act(g,d.policy("foot"),aim,count):outcome="policy_blocked";errors.append(outcome);break
  idle=idle+1 if day==g.state.day and mile==g.state.miles else 0
  if idle>32 or not valid(g):errors.append("Continuation stalled or invariant failed");break
  if step%100==0 and Store.new().restore(Store.new().capture(g))==null:errors.append("Continuation save failed");break
 if outcome=="action_limit":errors.append("Continuation action limit")
 var goods: Dictionary={}
 for k in g.leathercraft.items()+["deer_hide","bison_hide","rabbit_pelt"]:goods[k]=int(g.state.get(k,0))
 var result: Dictionary={"arm":arm,"start_sha256":start_sha,"harvested_after_fork":g.harvested_after_fork,"outcome":outcome,"days":int(g.state.day),"miles":int(g.state.miles),"original_present":g.party_health.members.slice(0,5).filter(func(m):return g.party_health.is_active(m)).size(),"cash":g.state.money,"food":g.state.food,"days_after_fork":g.days,"sales":g.sales,"events":g.supply_history.slice(history).filter(func(e):return e.event in ["leathercraft","settlement_wages","wages"]),"final_goods":goods,"final_contract":g.characters.profiles[2].contract,"death_causes":g.party_health.members.filter(func(m):return not m.alive).map(func(m):return m.cause),"counts":count}
 if Store.new().restore(Store.new().capture(g))==null:errors.append("Final save failed")
 d.free();return result
func run():
 var label: String="fixed-hide-pilot-01";var start:=572900;var seeds:=1;var months: Array=[4];var stocks: Array=["none"];var contracts: Array=["free"]
 for arg in OS.get_cmdline_user_args():
  if arg=="--confirmation":label="fixed-hide-01";start=572000;seeds=4;months=[4,5];stocks=["none","goats"];contracts=["free","hired"]
 var path: String="res://.tools/"+label+".json"
 if FileAccess.file_exists(path):printerr("Refusing to overwrite fixed-hide study");quit(1);return
 var hash_driver=Driver.new();var frozen: Dictionary=hash_driver.source_hashes();hash_driver.free()
 var rows: Array=[]
 for contract in contracts:
  for stock in stocks:
   for month in months:
    for seed_value in range(start,start+seeds):
     var d=driver(stock,contract,"crew");var g=d.make_study_game(seed_value)
     var row: Dictionary={"seed":seed_value,"month":month,"stock":stock,"contract":contract,"checkpoint":{},"branches":[]}
     if not g.depart("farmer",["A","B","C","D","E"],month,d.starting_cart(g,"foot","shared")):errors.append(g.departure_error);d.free();continue
     var count: Dictionary=d.count_template();var aim=RandomNumberGenerator.new();aim.seed=seed_value^0x41494d
     var root_outcome: String="action_limit";var idle:=0
     for step in range(2400):
      if eligible(g):
       var snapshot: Dictionary=Store.new().capture(g)
       row.checkpoint={"day":g.state.day,"miles":g.state.miles,"cash":g.state.money,"food":g.state.food,"deer_hide":g.state.deer_hide,"save_sha256":JSON.stringify(snapshot).sha256_text(),"aim_state":str(aim.state),"save":snapshot}
       for arm in ["crew","craft"]:row.branches.append(continuation(snapshot,aim.state,count,stock,contract,arm))
       root_outcome="forked";break
      if g.state.status!="traveling":root_outcome=g.state.status;break
      if g.state.day>=365:root_outcome="year_limit";break
      var day: int=int(g.state.day);var mile: int=int(g.state.miles)
      if not d.act(g,d.policy("foot"),aim,count):errors.append("Root policy blocked");break
      idle=idle+1 if day==g.state.day and mile==g.state.miles else 0
      if idle>32 or not valid(g):errors.append("Root stalled or invariant failed");break
     if root_outcome=="action_limit":errors.append(root_outcome)
     row.root_outcome=root_outcome;row.root_days=g.state.day;row.root_hides_recovered=g.pelt_recoveries
     rows.append(row);d.free();await process_frame
    print("%s %s month%d: %d roots, %d errors" % [contract,stock,month,rows.size(),errors.size()])
 var final_driver=Driver.new()
 if final_driver.source_hashes()!=frozen:errors.append("Sources changed during campaign")
 final_driver.free()
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"protocol":1,"seed_start":start,"seeds":seeds,"source_hashes":frozen,"rules":Store.new().fingerprint(),"rows":rows,"errors":errors},"\t"))
 print("Fixed hides: %d roots, %d errors" % [rows.size(),errors.size()]);quit(1 if not errors.is_empty() else 0)
