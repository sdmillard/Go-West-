extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Produce=preload("res://simulation/produce_trade.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func outfit(seed_value: int=57,fresh: int=0,dried: int=0):
 var game=Simulation.new(seed_value,"classic",true)
 var cart: Dictionary={"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10,"produce":fresh,"dried_produce":dried}
 var quote: Dictionary=game.outfitter.quote("banker",cart)
 check(quote.valid and game.depart("banker",["A","B","C","D","E"],5,cart),"Outfitter sells produce and commits departure")
 check(is_equal_approx(float(quote.cargo_lb),game.provisions.cargo(game.state)),"Opening quote matches real produce cargo")
 game.party_health.daily_onset_chance=0
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 return game
func trip(game,message: String):
 var store=Store.new()
 var snap: Dictionary=store.capture(game)
 var restored=store.restore(JSON.parse_string(JSON.stringify(snap)))
 check(restored!=null,message)
 if restored!=null:check(store.capture(restored)==snap,message+" exact")
func shop(game):
 game.state.next_landmark="fort_bridger"
 game._arrive_landmark()
 game.state.miles=int(game.route.node_miles().fort_bridger)
 game.context.record.spent["post:fort_bridger|visit"]=1
 return game
func run():
 var game=outfit(57,2,3)
 check(game.state.food==1005 and Produce.units(game.provisions,"produce",0)==2 and Produce.units(game.provisions,"dried_produce",0)==3,"Fresh/dried starting food is tagged and included in totals")
 trip(game,"Starting produce saves")
 var fresh=game.provisions.get_script().new()
 Produce.add(fresh,"produce",1,0)
 var dried=game.provisions.get_script().new()
 Produce.add(dried,"dried_produce",1,0)
 check(is_equal_approx(fresh.remove(1),4.0) and is_equal_approx(dried.remove(1),1.0),"Dried produce retains a quarter of the fresh-equivalent vitamin C per food unit")
 game=outfit(57,4,0)
 game.party_health.days_without_fresh=30
 var day: int=game.state.day
 var food: int=game.state.food
 var offer: Dictionary=game.produce_drying_offer()
 check(offer.input==4 and offer.mass==16,"Produce drying previews actual batch mass")
 check(game.dry_produce() and game.state.day==day+1,"Drying uses one actual work day")
 check(Produce.units(game.provisions,"produce",1)==0 and Produce.units(game.provisions,"dried_produce",1)==4,"Drying converts the reserved fruit batch")
 check(game.state.food==food-15 and game.party_health.days_without_fresh==31,"Reserved fruit cannot also feed or provide vitamins during the work day")
 check(game.provisions.fresh[0].expires==92 and is_equal_approx(game.provisions.fresh[0].mass_ratio,0.7),"Dried fruit keeps longer and weighs less")
 trip(game,"Dried produce saves")
 var bad: Dictionary=Store.new().capture(game)
 bad.fresh[0].vitamin_c_per_unit=999
 check(Store.new().restore(bad)==null,"Forged nutrient concentration rejects")
 game=shop(outfit(57,4,2))
 var stock: Dictionary=game.trade_counter()
 check(stock.rows.size()==11 and stock.rows.any(func(row):return row.item=="produce") and stock.rows.any(func(row):return row.item=="dried_produce"),"Post counter exposes both produce types")
 var before: Dictionary=Store.new().capture(game)
 var quote: Dictionary=game.counter_quote({"produce":-2,"dried_produce":-1})
 check(quote.valid and Store.new().capture(game)==before,"Sale preview is pure")
 check(game.counter_checkout({"produce":-2,"dried_produce":-1}),"Actual fresh and dried produce can be sold")
 check(Produce.units(game.provisions,"produce",0)==2 and Produce.units(game.provisions,"dried_produce",0)==1,"Sale removes the right tagged batches")
 check(is_equal_approx(game.provisions.cargo(game.state),float(quote.cargo_after_lb)),"Counter cargo predicts the produce sale")
 trip(game,"Produce sale saves")
 before=Store.new().capture(game)
 check(not game.counter_checkout({"produce":-999}) and Store.new().capture(game)==before,"Overselling produce rejects atomically")
 game=shop(outfit(57,2,0))
 game.state.food=2
 game.provisions.reconcile(2)
 check(not game.counter_quote({"produce":-2,"food":-2}).valid,"A mixed basket cannot sell the same food twice")
 var found:=false
 for seed_value in range(20):
  game=shop(outfit(seed_value))
  var row: Dictionary=game.trade_counter().rows.filter(func(r):return r.item=="produce")[0]
  if row.can_buy<=0:continue
  var quantity: int=mini(2,int(row.can_buy))
  quote=game.counter_quote({"produce":quantity})
  var deficiency: int=game.party_health.days_without_fresh
  check(game.counter_checkout({"produce":quantity}),"Fresh stock can be bought")
  check(Produce.units(game.provisions,"produce",int(game.state.day))==quantity and game.party_health.days_without_fresh==deficiency,"Buying without a meal does not reset deficiency")
  check(is_equal_approx(game.provisions.cargo(game.state),float(quote.cargo_after_lb)),"Counter cargo predicts the purchase")
  trip(game,"Produce purchase saves")
  found=true
  break
 check(found,"Seeded seasonal stock includes an obtainable fresh offer")
 game=shop(outfit())
 game.state.departure_month=12
 check(game.trade_counter().rows.filter(func(r):return r.item=="produce")[0].can_buy==0,"Winter has no fresh seasonal stock")
 game=outfit(57,4,2)
 game.pending={}
 var pack: Dictionary={"food":20,"clothing":5,"bullets":10}
 check(game.abandon_wagon(pack),"Produce batches can be carried on foot")
 trip(game,"Produce and dried nutrients survive cache transfers")
 game=outfit()
 check(game.produce_drying_offer().is_empty() and not game.dry_produce(),"Drying unavailable without fresh produce")
 game=outfit(57,4,0)
 game.state.food+=game.provisions.add_meat(40,0)
 offer=game.preservation_offer()
 check(offer.input==6,"Meat preservation preview shares produce before taking the work-day meal")
 check(game.preserve_meat() and game.supply_history.back().processed==offer.input,"Meat processing matches the mixed-diet preview")
 print("Produce food: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
