extends "res://tests/current_journey_policy.gd"
func run():
 hunting_study=true
 var path: String="res://docs/current-hunting-study-01.json"
 if FileAccess.file_exists(path):printerr("Archive exists");quit(1);return
 var rows: Array=[]
 var errors: Array=[]
 for health_case in ["healthy","half_health","broken_legs"]:
  for habitat in ["woodland","plains","highcountry","sagebrush","forest"]:
   for accuracy in [0.35,0.65,0.9]:
    for seed_value in range(3200,3230):
     var game=Simulation.new(seed_value,"classic",true)
     var cart: Dictionary={}
     for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
     game.depart("banker",["A","B","C","D","E"],5,cart)
     game.party_health.daily_onset_chance=0
     game.survival.forced_weather="clear"
     game.state.rations=2
     game.route.nodes.independence.hunting_region=habitat
     for member in game.party_health.members:
      member.health=100 if health_case!="half_health" else 50
      if health_case=="broken_legs" and member.id in [1,2]:game.party_health.begin_condition(int(member.id),"broken_leg",0)
     game.state.health=game.party_health.average_health()
     var count: Dictionary={"hunts":0,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0}
     var aim:=RandomNumberGenerator.new()
     aim.seed=seed_value ^ 0x41494d
     var food: int=game.state.food
     if not hunt_outing(game,{"accuracy":accuracy},aim,count):errors.append({"seed":seed_value,"habitat":habitat})
     rows.append({"case":health_case,"region":habitat,"aim":accuracy,"seed":seed_value,"food_net":int(game.state.food)-food,"meat_lb":count.meat_carried,"shots":count.shots,"empty":count.empty_hunts,"haul_lb":game.hauling_capacity("hunting")})
 var store=Store.new()
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"rules_signature":store.fingerprint(),"note":"Controlled actual hunts:30 matched seeds x5 habitats x3 scripted aim levels x3 explicit health/injury fixtures. Banker's ordinary suggested outfit, full rations, clear weather, spontaneous illness disabled. Food net includes actual day's meals. Not a claim about human aim or historical game abundance.","runs":rows,"errors":errors},"\t"))
 print("Current hunting study: ",rows.size()," hunts; ",errors.size()," errors")
 quit(0 if errors.is_empty() else 1)
