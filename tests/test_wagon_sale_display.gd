extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func outfit():
 var game=Simulation.new(57,"classic",true)
 game.depart("banker",["Lead","A","B","C","D"],5,{"oxen":6,"food":1700,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10,"produce":3,"dried_produce":3})
 game.state.next_landmark="independence"
 game._arrive_landmark(true,false)
 game.survival.forced_weather="clear"
 game.party_health.daily_onset_chance=0
 return game
func run():
 var game=outfit()
 var food_row: Dictionary=game.post_store().rows.filter(func(row):return row.item=="food")[0]
 check(food_row.sell_cents<food_row.buy_cents,"Departure-town food cannot be bought and resold for immediate profit")
 var before: Dictionary=Store.new().capture(game)
 var pack: Dictionary={"food":20,"clothing":5,"bullets":20}
 var offer: Dictionary=game.wagon_sale_quote(pack,4)
 check(offer.valid and offer.payout_cents>=3750 and offer.sold.has("food") and offer.dropped.has("food"),"Sale prices wagon and accepted leftovers while exposing unaccepted stock")
 check(offer.keep_oxen==4 and offer.sold.get("oxen",0)==2,"Extra oxen can be sold while retained animals stay with travelers")
 check(Store.new().capture(game)==before,"Sale preview is read-only")
 check(not game.wagon_sale_quote({"food":1000}).valid and not game.sell_wagon({"food":1000}) and Store.new().capture(game)==before,"Overweight sale cannot strand an overloaded walking party")
 var money: float=game.state.money
 check(game.sell_wagon(pack,4) and game.state.vehicle=="foot" and game.state.oxen==4 and game.wagon_cache.is_empty(),"Actual sale walks away with selected packs and animals, without inventing a cache")
 check(is_equal_approx(game.state.money,money+offer.payout_cents/100.0) and game.state.food==5,"Payout matches review exactly and first store visit costs ordinary walking meals")
 check(game.state.wheels==0 and game.state.axles==0 and game.state.tongues==0,"Unsaved supplies never remain secretly in sold wagon")
 check(game.provisions.cargo(game.state)<=game.provisions.capacity(game.state),"Actual final cargo fits preview capacity")
 var saved: Dictionary=Store.new().capture(game)
 check(Store.new().restore(JSON.parse_string(JSON.stringify(saved)))!=null,"Post-sale state and exact stock ledgers save")
 check(not game.sell_wagon(pack),"Cannot sell an absent wagon twice")
 check(game.post_quote({"wagon":1}).valid and game.post_store().rows[0].can_buy==2,"Sold frame enters that post's finite replacement inventory")
 game=outfit()
 game.context.record.spent["post:independence|visit"]=1
 offer=game.wagon_sale_quote(pack)
 check(offer.valid and offer.days==0,"Wagon sale shares a visit already paid at the store")
 check(game.sell_wagon(pack) and game.state.day==0 and game.state.food==20,"Same-visit sale does not charge another day or meal")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.departure_view.hide()
 screen.game=outfit()
 screen._show_packing(false,true)
 screen.packing_quantities.food.value=20
 screen._update_packing_quote()
 check(screen.packing_quote.text.contains("PAYOUT") and screen.packing_review.text.contains("LEFT BEHIND PERMANENTLY") and screen.packing_window.get_ok_button().text=="SELL WAGON","Actual sale form exposes payout, discards and explicit confirmation")
 screen.packing_window.hide()
 screen.display_fit.select(0)
 screen._apply_preferences(false)
 check(root.content_scale_stretch==Window.CONTENT_SCALE_STRETCH_FRACTIONAL and root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_KEEP,"Fit continuously scales without changing aspect")
 screen.display_fit.select(1)
 screen._apply_preferences(false)
 check(root.content_scale_stretch==Window.CONTENT_SCALE_STRETCH_FRACTIONAL and root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_IGNORE,"Fill uses the whole resized window")
 screen.display_fit.select(2)
 screen._apply_preferences(false)
 check(root.content_scale_stretch==Window.CONTENT_SCALE_STRETCH_INTEGER,"Crisp integer scaling remains optional")
 screen.queue_free()
 await process_frame
 print("Wagon sale / resizing: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
