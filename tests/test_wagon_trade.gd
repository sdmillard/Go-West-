extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func outfit():
 var game=Simulation.new(57,"classic",true)
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 check(game.depart("banker",["Lead","A","B","C","D"],5,cart),"Outfit")
 game.pending={}
 game.survival.data.event_chance=0
 game.party_health.daily_onset_chance=0
 for event in game.catalog.events:game.seen.append(event.id)
 return game
func shop(game,id: String="fort_laramie"):
 game.state.next_landmark=id
 game._arrive_landmark()
 game.state.miles=int(game.route.node_miles()[id])
 game.context.record.spent["post:"+id+"|visit"]=1
func trip(game,message: String):
 var store=Store.new()
 var snap: Dictionary=store.capture(game)
 var restored=store.restore(JSON.parse_string(JSON.stringify(snap)))
 check(restored!=null,message)
 if restored!=null:check(store.capture(restored)==snap,message+" exact")
func run():
 var game=outfit()
 check(game.abandon_wagon({"food":30,"clothing":5,"bullets":10}),"Real abandoned wagon")
 var cached: Dictionary=game.wagon_cache.duplicate(true)
 var foot_mass: float=game.provisions.cargo(game.state)
 shop(game)
 var offer: Dictionary=game.post_store()
 var row: Dictionary=offer.rows.filter(func(r):return r.item=="wagon")[0]
 check(row.can_buy==1 and row.can_sell==0,"Post offers finite replacement wagon only to a walking party")
 var before: Dictionary=Store.new().capture(game)
 var quote: Dictionary=game.post_quote({"wagon":1})
 check(quote.valid and Store.new().capture(game)==before,"Replacement quote is pure")
 var money: float=game.state.money
 var food: int=game.state.food
 var oxen: int=game.state.oxen
 check(game.post_checkout({"wagon":1}) and game.state.vehicle=="wagon","Actual counter purchase restores wagon transport")
 check(game.state.food==food and game.state.oxen==oxen and is_equal_approx(game.state.money,money-row.buy_cents/100.0),"Wagon gives no free oxen or provisions")
 check(is_equal_approx(game.provisions.cargo(game.state),quote.cargo_after_lb) and is_equal_approx(game.provisions.cargo(game.state),foot_mass),"Empty wagon creates no household gear")
 check(game.wagon_cache==cached,"Buying a wagon preserves the abandoned cache")
 check(not game.post_quote({"wagon":1}).valid and not game.post_quote({"wagon":-1}).valid,"Cannot stockpile or sell imaginary wagons")
 trip(game,"Replacement and old cache save")
 game=outfit()
 game.abandon_wagon({"food":30,"clothing":5})
 game.state.oxen=0
 shop(game)
 quote=game.post_quote({"wagon":1,"oxen":2})
 check(quote.valid and game.post_checkout({"wagon":1,"oxen":2}) and game.state.oxen==2 and game.state.vehicle=="wagon","Wagon and a separately paid team share one legal cart")
 trip(game,"Wagon/team purchase saves")
 game=outfit()
 game.abandon_wagon({"food":30,"clothing":5})
 shop(game,"independence")
 check(not game.post_store().is_empty() and game.post_store().rows.any(func(r):return r.item=="wagon"),"Returning to Independence offers replacement wagons")
 game.state.money=0
 before=Store.new().capture(game)
 check(not game.post_checkout({"wagon":1}) and Store.new().capture(game)==before,"Unaffordable wagon rejects atomically")
 print("Replacement wagon: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
