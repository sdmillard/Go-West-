extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
const MOUNTS=["horses","mules","saddles","pack_saddles","saddlebags"]
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func calm(game) -> void:
	game.survival.forced_weather="clear"
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	for member in game.party_health.members:member.health=100
	game.state.health=100
## A wagon party stopped at Fort Bridger's store, the way the robbery suite sets it up.
func at_bridger(seed_value: int=57,crime: bool=false):
	var game=Simulation.new(seed_value,"classic",true)
	game.depart("banker",["Lead","A","B","C","D"],5,{"oxen":4,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
	calm(game)
	game.state.money=500.0
	game.route_path=game.route.main_path_to("fort_bridger")
	game.state.landmark="fort_bridger"
	game.state.next_landmark="fort_bridger"
	game.state.miles=int(game.route.node_miles()["fort_bridger"])
	game.state.leg_miles=0
	game.state.leg_length=0
	game.pending={}
	game._arrive_landmark(true,false)
	if crime:game.open_crime("fort_bridger")
	return game
## A trading party met on the road that has horses to sell.
func traders_with_horses():
	for seed_value in range(1,60):
		var game=Simulation.new(seed_value,"classic",true)
		game.depart("banker",["Lead","A","B","C","D"],5,{"oxen":4,"food":600,"clothing":5,"bullet_boxes":10,"medicine":2})
		calm(game)
		game.state.money=500.0
		game.pending={}
		for day in range(2,40):
			game.state.day=day
			var offer: Dictionary=game.context.market(game)
			if offer.available and not offer.post and int(game.context.barter_goods(game,offer.key).stock.get("horses",0))>0:return game
	return null
func row(counter: Dictionary,item: String) -> Dictionary:
	for each in counter.rows:
		if each.item==item:return each
	return {}
func run():
	var store=Store.new()
	# The post's counter sells a few horses, mules and tack at regional prices.
	var game=at_bridger()
	var counter: Dictionary=game.post_store()
	var price: float=float(game.context.region(game).price)
	check(row(counter,"horses").can_buy==4 and row(counter,"mules").can_buy==3 and row(counter,"saddlebags").can_buy==6,"A post keeps a few horses and mules and more tack")
	check(row(counter,"horses").buy_cents>=roundi(4000*price*0.95) and row(counter,"horses").sell_cents==1500,"Horses sell at the regional price and are bought back for less")
	# No buy-and-sell-back loop: anything bought anywhere sells for less than it cost at Independence or here.
	var outfit: Dictionary={}
	for good in game.outfitter.goods:outfit[good.id]=int(good.price_cents)
	var looped:=false
	for item in MOUNTS:
		var each: Dictionary=row(counter,item)
		if each.is_empty() or int(each.sell_cents)>=int(each.buy_cents) or int(each.sell_cents)>=outfit[item]:looped=true
	check(not looped,"Selling stock or tack back never pays more than it cost")
	var horses: int=game.Mounts.count(game.state,"horses")
	check(game.counter_checkout({"horses":2,"saddles":2,"saddlebags":2}),"The party buys horses and tack at the post counter")
	check(game.state.horses==horses+2 and game.state.saddles==2 and game.state.saddlebags==2 and game.journal.any(func(line):return "bought 2 horses" in line),"Bought horses and tack join the outfit and the journal")
	check(game.post_store().rows.filter(func(each):return each.item=="horses")[0].can_buy==2,"The post has two horses left")
	var money: float=game.state.money
	check(game.counter_checkout({"horses":-1}) and is_equal_approx(game.state.money,money+15.0) and game.state.horses==horses+1,"A horse sells back to the post for its lower price")
	var restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(restored!=null and restored.state.horses==game.state.horses and restored.post_store().rows.filter(func(each):return each.item=="horses")[0].can_buy==2,"Horse trades survive a save")
	# The lot menu offers horses too, after every older offer, and saves with it.
	game=at_bridger()
	game.open_trade()
	var labels: Array=game.pending.choices.map(func(choice):return str(choice.label))
	check(labels.any(func(label):return label.begins_with("Buy 1 horse")) and labels.find_custom(func(label):return label.begins_with("Buy 1 horse"))>labels.find_custom(func(label):return label.begins_with("Sell 10 lb salt")),"The trade menu lists horses after the older goods")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A save with horse offers on the trade menu loads")
	var pack: Dictionary=game.pending.choices.filter(func(choice):return str(choice.label).begins_with("Buy 1 pack saddle"))[0]
	check(pack.market_key.ends_with("|buy_pack_saddles") and pack.stock_limit==4,"Pack saddles keep their whole name in the market ledger")
	# Passing traders carry their own stock; older meetings keep the goods and purse they always had.
	var road=traders_with_horses()
	check(road!=null,"Some passing traders carry horses")
	if road!=null:
		var key: String=road.context.market(road).key
		var goods: Dictionary=road.context.barter_goods(road,key)
		var data: Dictionary=road.context.data.passing_goods
		var saved: Array=[data.mount_stock,data.mount_wants]
		data.mount_stock={}
		data.mount_wants={}
		var plain: Dictionary=road.context.barter_goods(road,key)
		data.mount_stock=saved[0]
		data.mount_wants=saved[1]
		var same: bool=plain.purse_cents==goods.purse_cents and plain.mood==goods.mood
		for side in ["stock","wants"]:
			for item in plain[side]:same=same and plain[side][item]==goods[side][item]
		check(same,"Horses and tack are rolled after everything else a trading party carries")
		var traders: Dictionary=road.trade_counter()
		var horse_row: Dictionary=row(traders,"horses")
		check(horse_row.can_buy==int(goods.stock.horses) and horse_row.buy_cents>=roundi(4000*float(road.context.region(road).price)*1.2*0.85),"The traders sell their horses at their markup")
		# Robbing traders of their last animals leaves them stranded; they resist harder.
		road.open_crime()
		var stock: Dictionary=road.RobberyDemand.stock(road,key)
		var all_animals: Dictionary={"horses":int(stock.get("horses",0))}
		if int(stock.get("mules",0))>0:all_animals["mules"]=int(stock.mules)
		var with: Dictionary=road.robbery_quote(all_animals)
		road.RobberyDemand.data.mount_penalty=0.0
		var without: Dictionary=road.robbery_quote(all_animals)
		road.RobberyDemand.data.mount_penalty=0.15
		check(all_animals.horses==0 or (with.valid and with.compliance<without.compliance),"Taking a trading party's last animals makes resistance likelier")
		road.crime.choose(road,"back")
		check(road.counter_checkout({"horses":1}) and road.state.horses==1,"The party buys a horse from passing traders")
	# Robbery demands and quiet thefts can take horses.
	game=at_bridger(57,true)
	check(game.RobberyDemand.stock(game,"fort_bridger").horses==4,"A post's horses can be demanded")
	var demand: Dictionary=game.robbery_quote({"horses":2,"saddles":2})
	check(demand.valid and demand.value_cents==2*4000+2*1500,"Demanded horses are valued at their Independence prices")
	game.state.vehicle="foot"
	game.state.oxen=0
	check(not game.robbery_quote({"wagon":1}).valid and game.robbery_quote({"wagon":1,"oxen":2}).valid,"A wagon can't be demanded without oxen to pull it")
	game=at_bridger(57,true)
	var stock_here: Dictionary=game.RobberyDemand.theft_stock(game,"fort_bridger")
	check(not stock_here.has("cash_cents") and not stock_here.has("wagon") and stock_here.has("horses"),"A quiet theft takes goods, not the cash box or a wagon")
	var small: Dictionary=game.theft_quote({"bullets":5})
	var large: Dictionary=game.theft_quote({"bullets":5,"medicine":3})
	var horse: Dictionary=game.theft_quote({"bullets":5,"horses":1})
	check(small.valid and large.valid and small.unseen>large.unseen,"Taking more makes a theft likelier to be noticed")
	check(horse.valid and horse.unseen<small.unseen-float(game.RobberyDemand.data.animal_noise)+0.001,"Leading off a horse is noisy as well as costly")
	check(not game.theft_quote({"food":5000}).valid and not game.theft_quote({"cash_cents":100}).valid,"A theft can't take more than the helpers can carry, or the cash box")
	var before: Dictionary=store.capture(game)
	game.theft_quote({"horses":2})
	check(store.capture(game)==before,"Previewing a theft spends no time, goods or chance")
	var unseen:=false
	var noticed:=false
	for seed_value in range(40):
		game=at_bridger(seed_value,true)
		var had: int=game.Mounts.count(game.state,"horses")
		check(game.steal({"horses":1,"saddles":1}),"The party commits to a quiet horse theft")
		var current: Dictionary=game.crime.incident()
		check(current.action=="theft" and current.demand=={"horses":1,"saddles":1},"The chosen goods are fixed on the incident")
		restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
		check(restored!=null,"A theft in progress saves")
		if current.attempt=="unseen":
			unseen=true
			var take: int=game.pending.choices.find_custom(func(choice):return choice.get("crime_command","")=="take")
			check(take>=0 and game.choose(take) and game.state.horses==had+1 and game.state.saddles==1 and current.resolution=="left","Unseen, the party leads the horse away")
			check(game.RobberyDemand.stock(game,"fort_bridger").horses==3 and game.journal.any(func(line):return "Carried off unseen" in line),"The stolen horse is gone from the post")
			check(game.crime.Wanted.value_of(game,current)>=5500,"A stolen horse and saddle count toward restitution")
			restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
			check(restored!=null and restored.state.horses==game.state.horses,"After the theft the game saves")
		else:
			noticed=true
			check(game.Mounts.count(game.state,"horses")==had and current.stage=="escape","Noticed, the party gets nothing and must run")
		if unseen and noticed:break
	check(unseen and noticed,"Seeded thefts include both outcomes")
	# A save from before horses were traded loads unchanged.
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horse-trade-save-v1.json"))
	var upgraded=store.restore(old)
	check(upgraded!=null and upgraded.state==store.normalize(old.state) and str(upgraded.rng.state)==old.random,"A save from before horse trading loads")
	# The STEAL button opens the goods picker, as ROB does.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=at_bridger(57,true)
	screen._show_service()
	var theft_index: int=-1
	for i in range(screen.game.pending.choices.size()):
		if screen.game.pending.choices[i].get("crime_command","")=="theft":theft_index=i
	var day: int=screen.game.state.day
	screen._service_choice(theft_index)
	check(screen.robbery_demand_view.visible and screen.robbery_demand_view.action=="theft" and screen.game.state.day==day and screen.game.crime.incident().is_empty(),"Steal opens the goods picker without committing")
	screen.robbery_demand_view.quantities.horses.value=1
	check(screen.robbery_demand_view.quote_label.text.contains("CHANCE UNSEEN") and not screen.robbery_demand_view.quantities.has("cash_cents"),"The picker shows the chance of going unseen and no cash box")
	screen.robbery_demand_view.hide()
	screen.queue_free()
	await process_frame
	print("Horse trade: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
