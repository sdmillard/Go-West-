extends RefCounted
## Authored regional pressures and deterministic trading opportunities.
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
	for id in value.activities:
		var activity=value.activities[id]
		if not activity is Dictionary or not activity.get("talk") is String:return false
		if activity.has("kind") and (activity.kind not in ["graze","prepare"] or not activity.get("label") is String):return false
	data=value.duplicate(true)
	error=""
	return true
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
		for item in game.provisions.data.weights_lb.keys()+["oxen"]:
			if (side=="buy" and effects.get(item,0)>0) or (side=="sell" and effects.get(item,0)<0):
				choice["market_key"]=offer.key+"|"+side+"_"+item
				choice["stock_limit"]=offer.lots
				var left: int=offer.lots-int(record.spent.get(choice.market_key,0))
				choice.label+=" · %d offer(s) left" % maxi(0,left)
				break
func can_trade(choice: Dictionary) -> bool:
	return not choice.has("market_key") or int(record.spent.get(choice.market_key,0))<int(choice.stock_limit)
func consume(choice: Dictionary) -> void:
	if choice.has("market_key"):
		record.spent[choice.market_key]=int(record.spent.get(choice.market_key,0))+1
		# Once the store counter has sold by the unit, the unit ledger is the exact count; a whole lot adds its amount.
		var units: String=choice.market_key+"|units"
		if record.spent.has(units):record.spent[units]=int(record.spent[units])+absi(int(choice.effects.get(choice.market_key.substr(choice.market_key.rfind("|")+1).get_slice("_",1),0)))
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
	if activity.has("kind") and (activity.kind!="graze" or game.state.oxen>0):
		var choice: Dictionary={"label":activity.label+" · 1 day, meals consumed","action":"activity","activity":id,"effects":{"days":1},"result":"Took time to "+activity.label.to_lower()+"."}
		if activity.kind=="graze":
			choice.effects["ox_health"]=8
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
