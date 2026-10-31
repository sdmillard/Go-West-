extends SceneTree
const Sim=preload("res://tests/dog_usefulness_observer.gd")
const Policy=preload("res://tests/dog_usefulness_policy.gd")
const Save=preload("res://simulation/save_store.gd")
var errors: Array=[]
var pilot:=false
var out_path: String="res://.tools/dog-usefulness-03.json"
func _initialize():call_deferred("run")
func make(seed_value: int,profession: String,month: int,arm: String,habitat: String=""):
 var g=Sim.new(seed_value,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500 if profession=="banker" else 250,"clothing":5,"bullet_boxes":5,"medicine":2,"wheels":1,"salt":5,"dried_produce":4,"horses":1,"saddles":1}
 if arm!="none":cart["dog"]=1
 if not g.depart(profession,["Ada","Sam","Jo","Lou","Pat"],month,cart):errors.append({"phase":"departure","reason":g.departure_error,"profession":profession})
 if not habitat.is_empty():
  # Controlled outings isolate habitat; no weather/disease/supply rules are replaced.
  g.pending={};g.route.nodes[g.state.landmark].hunting_region=habitat
 if arm!="none":g.dogs.configure(g,"BUDDY","hunt" if arm=="hunt" else "watch","share")
 return g
func count() -> Dictionary:
 return {"hunts":0,"shots":0,"meat_obtained":0,"empty_hunts":0,"meat_carried":0.0,"care":0,"last_care":-100,"rests":0,"trades":0,"forages":0}
func snapshot(g) -> Dictionary:
 var rabbit:=0;var located:=0;var assisted:=0;var attempt:=0;var raw:=0;var stored:=0.0;var units:=0.0
 for row in g.hunts:
  rabbit+=int(row.get("rabbit_lb",0));located+=int(row.get("located",false));assisted+=int(row.get("dog",false));attempt+=int(row.get("dog_attempt",false));raw+=int(row.raw_lb);stored+=float(row.stored_lb);units+=float(row.stored_units)+float(row.human_hunt_meal_units)
 return {"status":str(g.state.status),"day":int(g.state.day),"miles":int(g.state.miles),"people":int(g.state.party_size),"food_units":float(g.state.food)+g.livestock.available_kcal()/1000.0,"cash":float(g.state.money),"dog_food_units":g.dog_kcal/1000.0,"dog_days":g.dog_days,"dog_alive":g.dogs.alive(),"dog_condition":g.dogs.record.dog.get("condition",0),"dog_fatigue":g.dogs.record.dog.get("fatigue",0),"fit_hunt_days":g.fit_hunt_days,"fit_watch_days":g.fit_watch_days,"warnings":g.warnings,"dog_injuries":g.dog_injuries,"encounters":g.encounters,"hunts":g.hunts.size(),"assisted_hunts":assisted,"dog_attempts":attempt,"located_game":located,"rabbit_lb":rabbit,"raw_meat_lb":raw,"stored_meat_lb":stored,"hunt_food_delivered_units":units,"horse_thieves":int(g.encounters.get("horse_thieves",0)),"mounts":g.Mounts.animals(g.state),"dog_crossing_losses":g.crossing_history.filter(func(c):return c.has("dog_lost")).size()}
func run():
 for arg in OS.get_cmdline_user_args():
  if arg=="--pilot":pilot=true;out_path="res://.tools/dog-usefulness-pilot-03.json"
 if FileAccess.file_exists(out_path):printerr("Refusing to overwrite "+out_path);quit(1);return
 var results: Dictionary={"rules":Save.new().fingerprint(),"controlled":[],"journeys":[],"errors":errors,"settings":{"version":3,"controlled_seed_start":790000,"journey_seed_start":791000,"pilot":pilot,"journey_cap_days":360,"journey_cap_steps":2400,"journey_wait_seconds":0,"extra_dog_only_rest_days":false}}
 var paths: Array=["simulation/working_dog.gd","simulation/trail_engine.gd","tests/dog_usefulness_policy.gd","tests/current_journey_policy.gd","tests/dog_usefulness_campaign.gd","tests/dog_usefulness_observer.gd"]
 results["sources"]={}
 for path in paths:results.sources[path]=FileAccess.get_file_as_string("res://"+path).replace("\r","").sha256_text()
 var policy=Policy.new()
 for region in ["woodland","plains","highcountry","sagebrush","forest"]:
  for offset in range(2 if pilot else 40):
   for wait in [false,true]:
    for arm in ["none","hunt"]:
     var seed_value: int=790000+offset
     var g=make(seed_value,"banker",5,arm,region)
     var aim:=RandomNumberGenerator.new();aim.seed=seed_value+888
     policy.wait_for_dog=wait
     if not policy.hunt_outing(g,{"rations":1,"pace":1},aim,count()):errors.append({"phase":"controlled_hunt","seed":seed_value})
     var row: Dictionary=snapshot(g);row.merge({"seed":seed_value,"region":region,"wait":wait,"arm":arm,"details":g.hunts.duplicate(true)},true)
     results.controlled.append(row)
 for profession in ["farmer","banker"]:
  for month in [4,5]:
   for offset in range(1 if pilot else 8):
    for arm in ["none","hunt","watch"]:
     var seed_value: int=791000+offset
     var g=make(seed_value,profession,month,arm)
     var counters: Dictionary=count()
     var aim:=RandomNumberGenerator.new();aim.seed=seed_value+888
     policy.dog_arm=arm;policy.wait_for_dog=false
     var profile: Dictionary={"id":"dog-audit","pace":1,"rations":1,"rest":true,"hunt":true,"preserve":"salt","preserve_meals":1,"rest_below":45,"health_rest_limit":2,"forage_gap":12,"adaptive_rations":false,"care_below":45,"post_food":400,"road_food":90,"hunt_below":75,"slaughter":false}
     var stale:=0;var steps:=0
     while g.state.status=="traveling" and g.state.day<360 and steps<2400:
      steps+=1;policy.manage_dog(g)
      var before: int=g.state.day;var mile: int=g.state.miles;var pending: String=JSON.stringify(g.pending)
      if not policy.act(g,profile,aim,counters):errors.append({"phase":"action","seed":seed_value,"profession":profession,"arm":arm,"day":int(g.state.day)});break
      if g.state.day==before and g.state.miles==mile and JSON.stringify(g.pending)==pending:stale+=1
      else:stale=0
      if stale>=12:errors.append({"phase":"stalled","seed":seed_value,"arm":arm});break
     var save=Save.new();var restored=save.restore(JSON.parse_string(JSON.stringify(save.capture(g))))
     if restored==null:errors.append({"phase":"save","seed":seed_value,"arm":arm,"reason":save.error})
     var row: Dictionary=snapshot(g);row.merge({"seed":seed_value,"profession":profession,"month":month,"arm":arm,"steps":steps,"counters":counters,"save_ok":restored!=null},true);results.journeys.append(row)
     print("DOG JOURNEY ",profession," ",month," ",seed_value," ",arm," ",g.state.status," day ",g.state.day)
 results.errors=errors
 var file:=FileAccess.open(out_path,FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 policy.free()
 print("DOG AUDIT: ",results.controlled.size()," controlled, ",results.journeys.size()," journeys, ",errors.size()," errors; ",out_path)
 quit(1 if not errors.is_empty() else 0)
