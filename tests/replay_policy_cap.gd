extends "res://tests/full_trail_balance.gd"
## Replays the former six-cent diagnostic setup with the corrected shared policy.
## The setup override is explicit: only the departure quote uses the former food price.
func run() -> void:
	adaptive=true
	hunting_study=true
	var game=Simulation.new(0,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:
		cart[good.id]=int(good.suggested)
		if good.id=="food":good.price_cents=6
	cart.oxen=4
	if not game.depart("farmer",["A","B","C","D","E"],4,cart):
		printerr("Replay setup failed")
		quit(1)
		return
	var policy: Dictionary={"id":"dry","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"dry","slaughter":false}
	var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
	var aim:=RandomNumberGenerator.new()
	aim.seed=0 ^ 0x41494d
	var outcome: String="action_limit"
	var toll_trace: Array=[]
	for step in range(2400):
		if game.state.status!="traveling":outcome=game.state.status;break
		if game.state.day>=365:outcome="out_of_time";break
		var day: int=game.state.day
		var miles: int=game.state.miles
		if not act(game,policy,aim,count):outcome="policy_blocked";break
		if game.state.miles>miles:count.travel_days+=1
		if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
		if game.state.day!=day and game.state.landmark=="barlow_pass":toll_trace.append({"day":game.state.day,"cash":game.state.money,"food":game.state.food,"party":game.state.party_size,"pending":game.pending.get("id","")})
	var path: String="res://docs/historical-policy-cap-replay.json"
	if FileAccess.file_exists(path):printerr("Replay archive already exists");quit(1);return
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"setup":"Former six-cent departure quote only; farmer, April, four oxen, dry, seed0. Other current rules unchanged. This is an explicit historical setup replay, not a live rule change.","outcome":outcome,"day":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"counts":count,"toll_trace":toll_trace,"recent_journal":game.journal.slice(maxi(0,game.journal.size()-6))},"\t"))
	file.close()
	print("Former policy cap replay: %s day%d, %d actual sales and %d wait days" % [outcome,game.state.day,count.trades,int(count.get("trade_waits",0))])
	quit(1 if outcome in ["action_limit","policy_blocked"] else 0)
