extends RefCounted
## Authored regional pressures and deterministic trading opportunities.
## Saddle and pack animals and their tack, traded alongside the staples.
const MOUNT_GOODS=["horses","mules","saddles","pack_saddles","saddlebags"]
const ARMS=preload("res://simulation/armory.gd").KEYS
var data: Dictionary={}
var error: String=""
var record: Dictionary={"spent":{},"activities":[],"prepared":[]}
func _init():
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_context.json")))
func load_data(value: Variant) -> bool:
	data={}
	error="Invalid regional context rules"
	if not value is Dictionary or not value.get("regions") is Dictionary or not value.get("activities") is Dictionary:return false
	if not value.get("care_posts") is Array:return false
	var care_ids: Array=[]
	for id in value.care_posts:
		if not id is String or id in care_ids:return false
		care_ids.append(id)
	for id in ["woodland","plains","highcountry","sagebrush","forest"]:
		var region=value.regions.get(id)
		if not region is Dictionary or not region.get("label") is String or not region.get("note") is String:return false
		for key in ["period","price","strain","wet","cold"]:
			if not numeric(region.get(key)) or region[key]<0:return false
		if region.period!=int(region.period) or region.period<5 or region.period>30 or region.price<1 or region.price>3 or region.strain>3 or region.strain!=int(region.strain) or region.wet<=0 or region.wet>3 or region.cold<=0 or region.cold>3:return false
	for key in ["passing_window_days","passing_lots","post_lots"]:
		if not numeric(value.get(key)) or value[key]!=int(value[key]) or value[key]<1 or value[key]>8:return false
	if value.passing_lots>value.post_lots:return false
	if not numeric(value.get("passing_price_markup")) or value.passing_price_markup<1 or value.passing_price_markup>2:return false
	if value.passing_window_days>=5 or not numeric(value.get("prepared_risk_factor")) or value.prepared_risk_factor<=0 or value.prepared_risk_factor>1:return false
	var camp: Variant=value.get("emigrant_camp")
	if not camp is Dictionary or camp.size()!=5 or not camp.get("note") is String:return false
	for key in ["barter_bullets","barter_food","barter_lots","care"]:
		if not numeric(camp.get(key)) or camp[key]!=int(camp[key]) or camp[key]<1:return false
	if camp.barter_lots>value.post_lots or camp.care>=12 or camp.barter_food>100:return false
	if not valid_goods(value.get("passing_goods"),true) or not valid_goods(value.get("emigrant_goods"),false):return false
	if not valid_horse_traders(value.get("horse_traders")):return false
	for id in value.activities:
		var activity=value.activities[id]
		if not activity is Dictionary or not activity.get("talk") is String:return false
		if activity.has("kind") and (activity.kind not in ["graze","prepare"] or not activity.get("label") is String):return false
	data=value.duplicate(true)
	error=""
	return true
## A trading party's goods: moods whose chances sum to one, and per item a [chance, least, most] for what it carries and wants.
## An emigrant family instead has a reluctance range for what it sells and a need range for what it buys.
func valid_goods(goods: Variant,traders: bool) -> bool:
	if not goods is Dictionary or not goods.get("note") is String:return false
	if traders:
		if not goods.get("moods") is Array or goods.moods.is_empty():return false
		var total:=0.0
		for mood in goods.moods:
			if not mood is Dictionary or not mood.get("id") is String:return false
			for key in ["chance","buy","sell"]:
				if not numeric(mood.get(key)) or mood[key]<=0 or mood[key]>2:return false
			total+=float(mood.chance)
		if not is_equal_approx(total,1.0):return false
		if not numeric(goods.get("late_food_factor")) or goods.late_food_factor<1 or goods.late_food_factor>2:return false
		if not numeric(goods.get("late_food_month")) or goods.late_food_month!=int(goods.late_food_month) or goods.late_food_month<1 or goods.late_food_month>12:return false
	else:
		for key in ["reluctance","need"]:
			var spread: Variant=goods.get(key)
			if not spread is Array or spread.size()!=2 or not spread.all(numeric) or spread[0]<=0 or spread[1]<spread[0] or spread[1]>3:return false
	for side in ["stock","wants","mount_stock","mount_wants"]:
		if not goods.get(side) is Dictionary:return false
		for item in goods[side]:
			var spread: Variant=goods[side][item]
			if not item in (MOUNT_GOODS if side.begins_with("mount_") else ["food","bullets","medicine","clothing","oxen","wheels","axles","tongues","salt"]) or not spread is Array or spread.size()!=3:return false
			if not spread.all(numeric) or spread[0]<0 or spread[0]>1 or spread[1]<1 or spread[1]!=int(spread[1]) or spread[2]!=int(spread[2]) or spread[2]<spread[1] or spread[2]>1000:return false
	var purse: Variant=goods.get("purse_dollars")
	return purse is Array and purse.size()==2 and purse.all(numeric) and purse[0]>=0 and purse[1]>=purse[0] and purse[1]<=80
## Horse herds at a stop: a name, terms, how many horses they will part with, and what each horse costs.
func valid_horse_traders(value: Variant) -> bool:
	if not value is Dictionary or not value.get("note") is String:return false
	for id in value:
		if id=="note":continue
		var herd: Variant=value[id]
		if not herd is Dictionary or not herd.get("name") is String or not herd.get("text") is String or not numeric(herd.get("horses")) or herd.horses!=int(herd.horses) or herd.horses<1 or herd.horses>8:return false
		if not herd.get("offers") is Array or herd.offers.is_empty():return false
		for offer in herd.offers:
			if not offer is Dictionary or not offer.get("label") is String or not offer.get("give") is Dictionary or offer.give.is_empty():return false
			for item in offer.give:
				if item not in ["clothing","oxen","bullets","money","medicine"] or not numeric(offer.give[item]) or offer.give[item]<=0 or offer.give[item]>1000:return false
	return true
## What a trading party met on the road carries, wants and pays out, and its temper. Seeded by the journey and the meeting,
## so it holds for the whole visit and through saves.
func barter_goods(game,key: String) -> Dictionary:
	var goods: Dictionary=data.passing_goods
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s" % [int(game.state.seed),key])
	var roll:=rng.randf()
	var mood: Dictionary=goods.moods[-1]
	for candidate in goods.moods:
		roll-=float(candidate.chance)
		if roll<0:
			mood=candidate
			break
	var result: Dictionary={"mood":mood.id,"buy":float(mood.buy),"sell":float(mood.sell)}
	result.merge(_roll_goods(goods,rng))
	return result
## The emigrant family camped at this place: its spare goods, how reluctantly it parts with them, and how much it needs each thing it wants.
func camp_goods(game,place: String) -> Dictionary:
	var goods: Dictionary=data.emigrant_goods
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s" % [int(game.state.seed),place])
	var result: Dictionary={"reluctance":snappedf(rng.randf_range(float(goods.reluctance[0]),float(goods.reluctance[1])),0.05)}
	result.merge(_roll_goods(goods,rng))
	var need: Dictionary={}
	for item in result.wants:need[item]=snappedf(rng.randf_range(float(goods.need[0]),float(goods.need[1])),0.05)
	result["need"]=need
	return result
func _roll_goods(goods: Dictionary,rng: RandomNumberGenerator) -> Dictionary:
	var result: Dictionary={"stock":{},"wants":{}}
	for side in ["stock","wants"]:
		for item in goods[side]:
			var spread: Array=goods[side][item]
			if rng.randf()<float(spread[0]):result[side][item]=rng.randi_range(int(spread[1]),int(spread[2]))
	result["purse_cents"]=rng.randi_range(int(goods.purse_dollars[0]),int(goods.purse_dollars[1]))*100
	# Stock and tack are rolled last, so every older meeting keeps the goods and purse it always had.
	for side in ["stock","wants"]:
		for item in goods["mount_"+side]:
			var spread: Array=goods["mount_"+side][item]
			if rng.randf()<float(spread[0]):result[side][item]=rng.randi_range(int(spread[1]),int(spread[2]))
	return result
func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
func region_id(game) -> String:
	return game.route.nodes[game.state.landmark].get("hunting_region","plains")
func region(game) -> Dictionary:
	return data.regions[region_id(game)]
func local_care(game) -> bool:
	var stop: Dictionary=game.service_return if game.pending.get("service_menu",false) else game.pending
	return stop.has("landmark") and stop.landmark in data.care_posts
func market(game) -> Dictionary:
	var at_post: bool=game.pending.has("landmark") and game.route.nodes[game.state.landmark].get("trade_bulk",false)
	if at_post:return {"available":true,"key":"post:"+game.state.landmark,"lots":int(data.post_lots),"price":float(region(game).price),"post":true}
	var period: int=region(game).period
	var phase: int=posmod(int(game.state.day)+posmod(int(game.state.seed),3),period)
	return {"available":phase<int(data.passing_window_days),"key":"passing:%s:%d" % [region_id(game),(int(game.state.day)+posmod(int(game.state.seed),3))/period],"lots":int(data.passing_lots),"price":float(region(game).price)*float(data.passing_price_markup),"post":false}
func decorate(game,options: Array,offer: Dictionary) -> void:
	for choice in options:
		var effects: Dictionary=choice.effects
		var side: String="sell" if effects.get("money",0)>0 else "buy"
		for item in game.provisions.data.weights_lb.keys()+["oxen"]+MOUNT_GOODS+ARMS:
			if (side=="buy" and effects.get(item,0)>0) or (side=="sell" and effects.get(item,0)<0):
				choice["market_key"]=offer.key+"|"+side+"_"+item
				# A post keeps only a few horses and saddles on hand.
				choice["stock_limit"]=mini(int(offer.lots),int(choice.get("lot",{}).get("post_lots",offer.lots))) if offer.post else offer.lots
				var left: int=int(choice.stock_limit)-int(record.spent.get(choice.market_key,0))
				choice.label+=" · %d offer(s) left" % maxi(0,left)
				break
func can_trade(choice: Dictionary) -> bool:
	return not choice.has("market_key") or int(record.spent.get(choice.market_key,0))<int(choice.stock_limit)
func consume(choice: Dictionary) -> void:
	if choice.has("market_key"):
		record.spent[choice.market_key]=int(record.spent.get(choice.market_key,0))+1
		# Once the store counter has sold by the unit, the unit ledger is the exact count; a whole lot adds its amount.
		var units: String=choice.market_key+"|units"
		if record.spent.has(units):record.spent[units]=int(record.spent[units])+absi(int(choice.effects.get(choice.market_key.substr(choice.market_key.rfind("|")+1).split("_",true,1)[1],0)))
	if choice.has("visit_key"):record.spent[choice.visit_key]=1
## A trading visit costs one day, charged on its first transaction, at a post or with passing traders.
func trade_days(offer: Dictionary) -> int:
	return 0 if record.spent.has(offer.key+"|visit") else 1
func crossing_factor(place: String) -> float:
	return float(data.prepared_risk_factor) if place in record.prepared else 1.0
func activity_choices(game) -> Array:
	var id: String=game.state.landmark
	if not data.activities.has(id):return []
	var activity: Dictionary=data.activities[id]
	var choices: Array=[{"label":"Talk with travelers about this stop","action":"notes","text":activity.talk}]
	if activity.has("kind") and (activity.kind!="graze" or game.Pasture.grazers(game)>0):
		var choice: Dictionary={"label":activity.label+" · 1 day, meals consumed","action":"activity","activity":id,"effects":{"days":1},"result":"Took time to "+activity.label.to_lower()+"."}
		if activity.kind=="graze":
			if game.state.oxen>0:choice.effects["ox_health"]=8
			choice["rest"]=true
		else:
			choice["requires"]={"medicine":1}
			choice.effects["medicine"]=-1
		choices.append(choice)
	return choices
func valid_record(value: Variant,route) -> bool:
	if not value is Dictionary or value.size()!=3 or not value.get("spent") is Dictionary or value.spent.size()>10000:return false
	for key in ["activities","prepared"]:
		if not value.get(key) is Array or value[key].size()>route.nodes.size():return false
		var unique: Array=[]
		for id in value[key]:
			if not id is String or id in unique or not route.nodes.has(id) or not data.activities.has(id) or not data.activities[id].has("kind"):return false
			if key=="prepared" and (data.activities[id].kind!="prepare" or id not in value.activities):return false
			unique.append(id)
	for key in value.spent:
		if not key is String or key.length()>128 or not numeric(value.spent[key]) or value.spent[key]!=int(value.spent[key]) or value.spent[key]<0 or value.spent[key]>int(data.post_lots)*(1000 if key.ends_with("|units") else 1):return false
	return true
