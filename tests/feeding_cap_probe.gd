extends SceneTree
## Controlled module probes; no historical yield claims or full-journey outcomes.
const Sim=preload("res://simulation/trail_engine.gd")
func _initialize():
 var rows: Array=[]
 for month in [5,7]:
  for region in ["woodland","plains","highcountry","sagebrush","forest"]:
   for condition in [50,100]:
    for fodder in [0,100]:
     var game=Sim.new(405901,"classic",true)
     if not game.depart("banker",["A","B","C","D","E"],month,{"oxen":4,"food":100,"clothing":5,"dairy_cows":1,"goats":1,"livestock_fodder":fodder}):quit(1);return
     for node in game.route.nodes:
      if game.route.nodes[node].get("hunting_region","")==region:game.state.landmark=node;game.state.next_landmark=node;break
     for a in game.livestock.record.animals:a.condition=condition
     game.survival.weather=game.survival.data.weather.filter(func(w):return w.id=="clear")[0].duplicate(true)
     var offer: Dictionary=game.livestock.outlook(game,true)
     game.livestock.tick(game,true,false)
     var cow:=0.0;var goat:=0.0
     for p in game.livestock.record.products:
      if p.kind!="milk":continue
      if is_equal_approx(float(p.kcal)/float(p.lb),277):cow+=float(p.lb)
      else:goat+=float(p.lb)
     rows.append({"month":month,"region":region,"condition":condition,"initial_fodder_lb":fodder,"cow_milk_lb":cow,"goat_milk_lb":goat,"feeding":offer.feeding,"fodder_used":game.livestock.last.feeding.fodder_lb})
 var result: Dictionary={"purpose":"Forty controlled clear-weather, full-care rest-day probes, full lactation. Actual module output; resource caps are authored assumptions.","stock_sha256":FileAccess.get_sha256("res://simulation/livestock.gd"),"feeding_sha256":FileAccess.get_sha256("res://simulation/livestock_feeding.gd"),"rows":rows}
 var f=FileAccess.open("res://.tools/feeding-cap-probe-01.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("Controlled forage probes: %d cases" % rows.size());quit()
