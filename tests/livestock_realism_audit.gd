extends SceneTree
## Controlled diagnostics of shipped rules, not a survival campaign or expected-bug test.
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var errors: Array[String]=[]
func _initialize():call_deferred("run")
func sample(label: String,cart: Dictionary,days: int=1,month: int=5,working: bool=false,jobs: bool=false) -> Dictionary:
 var g=Sim.new(330001,"classic",true)
 var outfit: Dictionary={"oxen":4,"food":100,"clothing":5,"bullet_boxes":1}
 outfit.merge(cart,true)
 if not g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,outfit):
  errors.append(label+": departure failed");return {}
 g.state.departure_month=month # Winter is an injected diagnostic date, not an offered departure.
 g.pending={};g.survival.weather={"id":"clear"}
 if jobs:
  for id in range(1,5):
   if not g.camp_tasks.assign(g,id,"forage"):errors.append(label+": assignment failed")
 var rows: Array=[]
 var units:=0
 var source_kcal:=0.0
 var expired_kcal:=0.0
 for day in range(1,days+1):
  g.state.day=day
  for p in g.livestock.record.products:
   if int(p.expires)<=day:expired_kcal+=float(p.kcal)
  # Only livestock advances: human health, routes, weather, meals, packing and RNG are held fixed.
  g.livestock.tick(g,not working,working)
  if not g.livestock.valid(g.livestock.record,g.state):errors.append(label+": invalid livestock day "+str(day))
  var result: Dictionary=g.livestock.last
  if result.is_empty():break
  units+=int(result.food)
  # last.milk_lb is rounded to .01 lb; long-run dairy calories are approximate.
  var milk_density: float=313 if int(cart.get("goats",0))>0 and int(cart.get("dairy_cows",0))==0 else 277
  if cart.has("goats") and cart.has("dairy_cows"):
   # Their production factors match in this controlled fixture; split by authored base mass.
   milk_density=(8.0*277+2.0*313)/10.0
  source_kcal+=float(result.milk_lb)*milk_density+int(result.eggs)*0.11*650
  var conditions: Array=[]
  for a in g.livestock.record.animals:conditions.append(int(a.condition))
  rows.append({"day":day,"conditions":conditions,"milk_lb":result.milk_lb,"eggs":result.eggs,"food_units":result.food,"care_factor":result.care_factor,"grain_lb":int(g.state.get("poultry_feed",0))*0.25})
 var pending_kcal:=0.0
 for p in g.livestock.record.products:pending_kcal+=float(p.kcal)
 return {"case":label,"cart":cart,"month":month,"working":working,"standing_forage_jobs":jobs,"isolated_days":rows.size(),"food_units_generated":units,"represented_kcal":units*1000,"source_kcal_from_reported_mass":source_kcal,"unconverted_kcal":pending_kcal,"unconverted_expired_kcal":expired_kcal,"rounding_difference_kcal":units*1000+pending_kcal+expired_kcal-source_kcal,"remaining_animals":g.livestock.record.animals.size(),"rows":rows}
func run():
 if Save.new().fingerprint()!="96f62de645481bd6421bce320de1afcfcd7e2d3dec70483a49ab31dbdd33c4c5":
  printerr("Archived diagnostic: reproduce on commit 1921a8b4b118ee4ec0d1e1254b458937e1c2e1ab. Use test_table_meals.gd for current accounting; the frozen report was not overwritten.")
  quit(1);return
 var cases: Array=[]
 cases.append(sample("cow-rest",{"dairy_cows":1}))
 cases.append(sample("goat-rest",{"goats":1}))
 cases.append(sample("two-goats-rest",{"goats":2}))
 cases.append(sample("cow-and-goat-rest",{"dairy_cows":1,"goats":1}))
 cases.append(sample("cow-travel",{"dairy_cows":1},1,5,true))
 cases.append(sample("cow-travel-standing-forage",{"dairy_cows":1},1,5,true,true))
 cases.append(sample("mixed-travel",{"dairy_cows":1,"goats":1},1,5,true))
 cases.append(sample("mixed-travel-standing-forage",{"dairy_cows":1,"goats":1},1,5,true,true))
 cases.append(sample("six-hens-fed",{"hens":6,"poultry_feed":400},30))
 cases.append(sample("six-hens-no-grain",{"hens":6},30))
 cases.append(sample("cow-winter-rest",{"dairy_cows":1},55,1))
 cases.append(sample("goat-winter-rest",{"goats":1},55,1))
 cases.append(sample("hens-winter-fed-rest",{"hens":6,"poultry_feed":1200},55,1))
 var hashes: Dictionary={}
 for path in ["simulation/livestock.gd","data/livestock.json","simulation/trail_engine.gd","tests/livestock_realism_audit.gd"]:
  hashes[path]=FileAccess.get_file_as_string("res://"+path).replace("\r", "").sha256_text()
 var report: Dictionary={"date":"2026-10-25","baseline_commit":"e09150ffa5a0a65620d1e05b49a0e72fab5389fa","source_hashes_lf":hashes,"scope":"13 controlled livestock-only fixtures; no meals, packing, human deterioration, weather changes, travel or survival outcomes. Dairy source calories use milk reported at .01 lb precision. Conversion totals are gross, not food eaten. Existing fresh batches deliberately retained for output measurement.","rules_fingerprint":Save.new().fingerprint(),"errors":errors,"cases":cases}
 var file=FileAccess.open("res://docs/livestock-realism-audit-01.json",FileAccess.WRITE)
 if file==null:errors.append("Cannot write report")
 else:file.store_string(JSON.stringify(report,"  "));file.close()
 for c in cases:
  if c.is_empty():continue
  print("%s: %s kcal represented; %s source kcal; %s animals remaining" % [c.case,c.represented_kcal,c.source_kcal_from_reported_mass,c.remaining_animals])
 for error in errors:printerr("FAIL: "+error)
 print("Livestock realism audit: %d cases, %d errors" % [cases.size(),errors.size()]);quit(1 if not errors.is_empty() else 0)
