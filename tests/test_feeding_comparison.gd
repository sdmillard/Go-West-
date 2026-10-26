extends SceneTree
const Plain=preload("res://simulation/trail_engine.gd")
const Observed=preload("res://tests/feeding_compare_observer.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func make_game(script,stock: bool):
 var g=script.new(355901,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500,"clothing":5,"bullet_boxes":2}
 if stock:cart.merge({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200})
 check(g.depart("banker",["A","B","C","D","E"],5,cart),"Common observer fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
 return g
func _initialize():call_deferred("run")
func run():
 for stock in [false,true]:
  var plain=make_game(Plain,stock);var seen=make_game(Observed,stock)
  for day in range(30):
   plain.pending={};seen.pending={}
   if day%3==0:plain.rest_in_camp();seen.rest_in_camp()
   else:plain.travel();seen.travel()
   check(Save.new().capture(plain)==Save.new().capture(seen),"Study observation preserves actual state, products, health and all saved random streams")
  check(seen.livestock.audit.meal_requested>=seen.livestock.audit.meal_eaten,"Common measured meals cannot exceed actual requests")
  check(is_equal_approx(seen.livestock.audit.meal_short,seen.livestock.audit.meal_requested-seen.livestock.audit.meal_eaten),"Unmet calories agree with actual meal consumption")
  if stock:check(seen.livestock.audit.dairy_eaten>0 and seen.livestock.audit.food_generated>=seen.livestock.audit.dairy_eaten,"Common observer measures dairy food actually eaten")
 var driver=preload("res://tests/feeding_compare_campaign.gd").new()
 driver.feeding_policy="fodder"
 var g=make_game(Observed,true);g.state.departure_month=7;g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 var count: Dictionary=driver.count_template()
 if "livestock_fodder" in g.livestock.GOODS:
  check(driver.buy_fodder(g,count),"Secondary policy buys real fodder through the open counter")
  check(g.state.money>=20 and count.get("fodder_lb_bought",0)>0 and g.purchases.any(func(p):return p.cart.has("livestock_fodder")),"Fodder buying respects money reserve and records actual purchases")
 else:check(not driver.buy_fodder(g,count),"Previous runtime offers no imaginary fodder purchase")
 driver.free()
 print("Feeding comparison observers/policy: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
