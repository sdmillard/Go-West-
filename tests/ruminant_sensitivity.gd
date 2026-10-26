extends SceneTree
## Actual isolated dairy ticks; variants are assumptions, not alternate journey results.
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var failures: Array=[]
func _initialize():call_deferred("run")
func run():
 var rows: Array=[]
 for kind in ["dairy_cows","goats"]:
  for body in [0.8,1.0,1.2]:
   for quality in [0.45,0.55,0.65]:
    for opportunity in [0.25,0.5,0.75,1.0]:
     for moving in [false,true]:
      for remaining in [0,30,180]:
       for hay in [0,100]:
        for condition in [50,100]:
         var game=Sim.new(425903,"classic",true)
         var cart: Dictionary={"oxen":4,"food":100,"clothing":5,"livestock_fodder":hay};cart[kind]=1
         if not game.depart("banker",["A","B","C","D","E"],5,cart):failures.append("departure");continue
         game.pending={}
         var r: Dictionary=game.livestock.data.feeding.ruminants.animals[kind]
         r.body_lb*=body;r.natural_tdn=quality
         game.livestock.data.feeding.habitats.woodland[kind]=opportunity
         game.livestock.record.animals[0].remaining=remaining;game.livestock.record.animals[0].condition=condition
         game.survival.weather=game.survival.data.weather.filter(func(w):return w.id=="clear")[0].duplicate(true)
         var before: float=game.livestock.Feeding.available(game,"livestock_fodder")
         var offer: Dictionary=game.livestock.outlook(game,not moving)
         game.livestock.tick(game,not moving,moving)
         var feeding: Dictionary=game.livestock.last.feeding
         var energy:=0.0;var milk:=0.0
         for p in game.livestock.record.products:energy+=float(p.kcal);milk+=float(p.lb)
         if not is_equal_approx(before-game.livestock.Feeding.available(game,"livestock_fodder"),float(feeding.fodder_lb)):failures.append("hay conservation")
         if milk>float(game.livestock.data.animals[kind].daily_lb)*clampf(float(remaining)/60,0,1)+0.000000001:failures.append("milk ceiling")
         if Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(game))))==null:failures.append("JSON save")
         rows.append({"kind":kind,"body_lb":r.body_lb,"natural_tdn":quality,"opportunity":opportunity,"moving":moving,"remaining":remaining,"hay_held_lb":hay,"starting_condition":condition,"ending_condition":game.livestock.record.animals[0].condition,"milk_lb":milk,"milk_kcal":energy,"hay_used_lb":feeding.fodder_lb,"nutrition":feeding.animals[kind],"preview_matches":offer.feeding==feeding})
 var hashes: Dictionary={}
 for path in ["simulation/livestock.gd","simulation/livestock_feeding.gd","simulation/ruminant_nutrition.gd","data/livestock.json","tests/ruminant_sensitivity.gd"]:hashes[path]=FileAccess.get_sha256("res://"+path)
 var result: Dictionary={"purpose":"1728 isolated real ticks across authored body/feed assumptions. No journey win rates or historical measurements.","source_hashes":hashes,"rules_signature":Save.new().fingerprint(),"failures":failures,"rows":rows}
 var path: String="res://.tools/ruminant-sensitivity-03.json"
 if FileAccess.file_exists(path):printerr("Refusing to overwrite sensitivity report");quit(1);return
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("Ruminant sensitivity: %d real ticks, %d failures" % [rows.size(),failures.size()]);quit(1 if not failures.is_empty() else 0)
