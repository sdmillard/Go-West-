extends SceneTree
const Plain=preload("res://simulation/trail_engine.gd")
const Observed=preload("res://tests/dairy_balance_observer.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func game(script,stock: bool):
 var g=script.new(445990,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500,"clothing":5,"bullet_boxes":2}
 if stock:cart.merge({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200})
 check(g.depart("banker",["A","B","C","D","E"],5,cart),"Dairy observer fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
 return g
func run():
 for stock in [false,true]:
  var plain=game(Plain,stock);var observed=game(Observed,stock)
  var animal_days: Dictionary={};var points: Dictionary={}
  for day in range(30):
   plain.pending={};observed.pending={}
   if day%3==0:plain.rest_in_camp();observed.rest_in_camp()
   else:plain.travel();observed.travel()
   check(Save.new().capture(plain)==Save.new().capture(observed),"Condition observation preserves saved state and every random stream")
   for a in plain.livestock.record.animals:
    animal_days[a.kind]=int(animal_days.get(a.kind,0))+1
    points[a.kind]=int(points.get(a.kind,0))+int(a.condition)
  check(observed.livestock.audit.animal_days==animal_days and observed.livestock.audit.condition_points==points,"Time-weighted condition records actual living animals")
 var a=game(Plain,true);var b=game(Observed,true)
 for g in [a,b]:g.state.landmark="fort_laramie";g.state.next_landmark="fort_laramie";g._arrive_landmark(true,false)
 var cart: Dictionary={"poultry_feed":4,"livestock_fodder":5}
 var quote: Dictionary=a.counter_quote(cart)
 check(quote.valid and a.counter_checkout(cart) and b.counter_checkout(cart),"Actual feed basket checked out through both public engines")
 check(Save.new().capture(a)==Save.new().capture(b),"Price observation changes no purchases, stock, meals or random streams")
 check(int(b.feed_spent_cents.poultry_feed)+int(b.feed_spent_cents.livestock_fodder)==-int(quote.net_cents),"Feed costs equal the actual feed-only basket price")
 var spent: Dictionary=b.feed_spent_cents.duplicate()
 check(not b.counter_checkout({"poultry_feed":1000000}) and b.feed_spent_cents==spent,"Rejected baskets record no fictional feed spending")
 print("Dairy balance observers: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
