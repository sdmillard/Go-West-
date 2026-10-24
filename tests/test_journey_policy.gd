extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Policy=preload("res://tests/journey_trade_policy.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func at_toll(day: int):
	var game=Simulation.new(0,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("farmer",["A","B","C","D","E"],4,cart)
	game.state.day=day
	game.state.next_landmark="barlow_pass"
	game._arrive_landmark()
	game.state.money=3.3
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	game.party_health.daily_onset_chance=0
	return game
func run():
	var game=at_toll(244)
	var count: Dictionary={"trades":0}
	var food: int=game.state.food
	check(not game.context.market(game).available,"Regression date has no passing trader")
	check(Policy.raise_toll_money(game,count),"Unavailable trader uses an actual wait")
	check(game.state.day==245 and game.state.food==food-15 and is_equal_approx(game.state.money,3.3),"Waiting spends a day and meals without inventing a sale")
	check(count.trades==0 and count.trade_waits==1,"Back is never counted as trade")
	check(game.pending.get("landmark","")=="barlow_pass","Waiting returns to the unresolved toll")
	game=at_toll(240)
	count={"trades":0}
	var bullets: int=game.state.bullets
	check(Policy.raise_toll_money(game,count),"An available trader buys actual supplies")
	check(game.state.day==241 and is_equal_approx(game.state.money,4.5) and game.state.bullets==bullets-20,"Sale exchanges bullets for cash at the regional price and spends its real day")
	check(count.trades==1 and not count.has("trade_waits"),"Only an actual sale increments trades")
	game=at_toll(240)
	for item in ["bullets","wheels","axles","tongues","food","oxen"]:game.state[item]=0
	game.state.parts=0
	count={"trades":0}
	check(not Policy.raise_toll_money(game,count),"No saleable goods is reported as a policy block")
	check(game.state.day==240 and count.trades==0 and game.pending.get("landmark","")=="barlow_pass","Blocked sale closes the menu without claiming progress")
	print("Journey trade policy: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
