extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Food=preload("res://simulation/provisions.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func _initialize():call_deferred("run")
func run():
 var food=Food.new()
 check(food.food_calories(3)==3000,"Filling remains three energy units per person, not one daily ration")
 for pair in [[550.0,55],[600.0,60],[520.0,52]]:
  food=Food.new()
  var units: int=food.add_meat(100,0,pair[0])
  check(units==pair[1] and is_equal_approx(food.tracked_mass(units),100.0),"Species energy converts recovered physical meat without changing its mass")
  for salted in [false,true]:
   var sample=Food.new();sample.add_meat(100,0,pair[0])
   var dried: Dictionary=sample.preserve(units,0,salted)
   check(dried.kept==units and dried.lost==0 and is_equal_approx(sample.food_calories(dried.kept),pair[0]*100),"Drying retains energy, with or without salt")
   check(is_equal_approx(dried.weight,35.0),"Only water weight is removed from the retained input")
 for pounds in [1,2,3]:
  for salted in [false,true]:
   food=Food.new();var amount: int=food.add_meat(pounds,0)
   check(food.preserve(amount,0,salted).kept==amount,"Tiny batches no longer disappear through retention rounding")
 var g=Sim.new(8612,"classic",true)
 check(g.depart("farmer",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":5,"salt":10}),"Fixture departs")
 g.pending={};g.start_hunt()
 g.hunt.animals=[{"kind":1,"meat":80,"kcal_per_lb":550.0},{"kind":2,"meat":20,"kcal_per_lb":520.0}]
 g.hunt.targets=[0,1];g.hunt.meat=100
 check(is_equal_approx(g.hunt_calorie_density(),544.0),"Mixed catch energy weights its actual species")
 check(g.finish_hunt() and g.last_hunt_recovery.retrieved==100 and g.last_hunt_recovery.retrieved_kcal==54400,"Recovery applies physical retrieval once before calorie conversion")
 var snapshot: Dictionary=Save.new().capture(g)
 var loaded=Save.new().restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(loaded!=null and Save.new().capture(loaded)==snapshot,"Calibrated mixed-meat batches round-trip exactly")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-calorie-food-v5.json"))
 var copy=Save.new().restore(old)
 check(copy!=null,"Authentic prior-rule meat and active-outing save loads")
 if copy!=null:
  check(copy.state==Save.new().normalize(old.state) and copy.provisions.fresh==Save.new().normalize(old.fresh) and copy.field_outings.snapshot()==Save.new().normalize(old.field_outings),"Old supplies, physical batches and reserved trips remain unchanged")
  check(str(copy.rng.state)==old.random,"Migration does not reroll the main random stream")
 print("Calorie food model: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
