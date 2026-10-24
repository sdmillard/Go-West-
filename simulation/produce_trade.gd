extends RefCounted
## Four-pound fresh-equivalent baskets, kept separate from ordinary staples and meat.
const WagonTrade=preload("res://simulation/wagon_trade.gd")
const ITEMS=["produce","dried_produce"]
static func valid_rules(value: Variant) -> bool:
	if not value is Dictionary or not value.get("note") is String:return false
	for key in ["fresh_cents","dried_cents","post_stock","trader_stock","camp_stock","dry_days","batch_units"]:
		if not numeric(value.get(key)) or value[key]!=floor(value[key]) or value[key]<1 or value[key]>10000:return false
	for key in ["sell_factor","fresh_chance","dried_chance","dry_weight","vitamin_retention"]:
		if not numeric(value.get(key)) or value[key]<=0 or value[key]>1:return false
	return true
static func numeric(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
static func units(model,item: String,day: int) -> int:
	var total:=0
	for batch in model.fresh:
		if batch.get("vitamin_c",false) and bool(batch.get("preserved",false))==(item=="dried_produce") and int(batch.expires)>day:total+=int(batch.pounds)
	return total
static func take(model,item: String,amount: int,day: int) -> int:
	var remaining:=amount
	model.fresh.sort_custom(func(a,b):return a.expires<b.expires)
	for batch in model.fresh:
		if not batch.get("vitamin_c",false) or bool(batch.get("preserved",false))!=(item=="dried_produce") or int(batch.expires)<=day:continue
		var n: int=mini(int(batch.pounds),remaining)
		batch.pounds-=n
		remaining-=n
	model.fresh=model.fresh.filter(func(batch):return batch.pounds>0)
	return amount-remaining
static func add(model,item: String,amount: int,day: int) -> void:
	if amount<=0:return
	if item=="produce":model.add_produce(amount*int(model.data.foraging.mass_ratio),day)
	else:
		var rule: Dictionary=model.data.produce_trade
		model.fresh.append({"pounds":amount,"expires":day+int(rule.dry_days)+1,"mass_ratio":float(model.data.foraging.mass_ratio)*float(rule.dry_weight),"vitamin_c":true,"preserved":true,"vitamin_c_per_unit":float(model.data.foraging.mass_ratio)*float(rule.vitamin_retention)})
static func rows(game,key: String,kind: String) -> Array:
	var rule: Dictionary=game.provisions.data.produce_trade
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("produce|%d|%s" % [int(game.state.seed),key])
	var season: float=game.provisions.data.foraging.months[int(game.calendar().month)-1]
	var base: int=int(rule.post_stock if kind=="post" else (rule.trader_stock if kind=="traders" else rule.camp_stock))
	var result: Array=[]
	for item in ITEMS:
		var dried: bool=item=="dried_produce"
		var stock: int=rng.randi_range(1,base) if rng.randf()<float(rule.dried_chance if dried else rule.fresh_chance) else 0
		if not dried:stock=floori(stock*season)
		var buy_key: String=key+"|buy_"+item
		var sell_key: String=key+"|sell_"+item
		var held:=units(game.provisions,item,int(game.state.day))
		var base_price: float=float(rule.dried_cents if dried else rule.fresh_cents)*float(game.context.region(game).price)
		var buy_factor:=1.0
		var sell_factor:=1.0
		if kind=="traders":
			var goods: Dictionary=game.context.barter_goods(game,key)
			buy_factor=float(game.context.data.passing_price_markup)*float(goods.buy)
			sell_factor=float(goods.sell)
		elif kind=="camp":buy_factor=float(game.context.camp_goods(game,key).reluctance)
		if kind!="camp" and game.characters.available(game,"Trading"):buy_factor*=float(game.characters.benefits.trade_buy_factor)
		var cents: int=roundi(base_price*buy_factor)
		var buy: int=maxi(0,stock-int(game.context.record.spent.get(buy_key+"|units",0)))
		var sell: int=mini(held,maxi(0,base-int(game.context.record.spent.get(sell_key+"|units",0))))
		result.append({"item":item,"label":"Dried fruit" if dried else "Fresh fruit / greens","amount":1,"buy_cents":cents,"sell_cents":floori(base_price*float(rule.sell_factor)*sell_factor),"can_buy":buy,"can_sell":sell,"held":held,"buy_key":buy_key,"sell_key":sell_key,"sells":true,"buys":true})
	return result
static func model_after(game,effects: Dictionary) -> Dictionary:
	var inventory: Dictionary=game.state.duplicate(true)
	var model=game.provisions.get_script().new()
	model.data=game.provisions.data.duplicate(true)
	model.fresh.assign(game.provisions.fresh.duplicate(true))
	for item in ITEMS:
		var n: int=int(effects.get(item,0))
		if n<0 and take(model,item,-n,int(game.state.day))!=-n:return {"valid":false}
		if n>0:add(model,item,n,int(game.state.day))
		inventory.food+=n
	for item in effects:
		if item in ITEMS:continue
		if item=="wagon":
			if not WagonTrade.apply_inventory(game,inventory,int(effects[item])):return {"valid":false}
			continue
		var n: int=int(effects[item])
		if item=="food" and n<0:model.remove(-n)
		inventory[item]=int(inventory.get(item,0))+n
	return {"valid":inventory.food>=0,"cargo":model.cargo(inventory),"inventory":inventory}
static func commit(game,effects: Dictionary) -> void:
	WagonTrade.commit(game,effects)
	for item in ITEMS:
		var n: int=int(effects.get(item,0))
		if n<0:take(game.provisions,item,-n,int(game.state.day))
		if n>0:add(game.provisions,item,n,int(game.state.day))
		game.state.food+=n
		effects.erase(item)
static func drying_offer(game) -> Dictionary:
	if not game.can_service():return {}
	var amount:=0
	for batch in game.provisions.fresh:
		if batch.get("vitamin_c",false) and not batch.get("preserved",false) and int(batch.expires)>int(game.state.day)+1:amount+=int(batch.pounds)
	amount=mini(amount,int(game.provisions.data.produce_trade.batch_units))
	return {} if amount<=0 else {"input":amount,"mass":amount*float(game.provisions.data.foraging.mass_ratio),"weight":amount*float(game.provisions.data.foraging.mass_ratio)*float(game.provisions.data.produce_trade.dry_weight),"days":int(game.provisions.data.produce_trade.dry_days)}
static func dry(game) -> bool:
	var offer:=drying_offer(game)
	if offer.is_empty():return false
	# Set this batch aside; it cannot also feed today's meals. Other food pays the work day.
	take(game.provisions,"produce",int(offer.input),int(game.state.day)+1)
	game.state.food-=int(offer.input)
	game._tick_day(false,false,"dry_produce")
	if game.state.status!="traveling":return true
	add(game.provisions,"dried_produce",int(offer.input),int(game.state.day))
	game.state.food+=int(offer.input)
	game.journal.append("Day %d · Dried %.0f lb fruit and greens into %.1f lb cargo (%d food units). Less vitamin C than fresh; keeps up to %d days. Today's meals used other provisions." % [game.state.day,offer.mass,offer.weight,offer.input,offer.days])
	game.supply_history.append({"day":int(game.state.day),"event":"produce_drying","changes":{},"processed":offer.input,"processed_mass_lb":offer.mass,"dried_weight_lb":offer.weight})
	game._update_river_stage()
	if game.pending.is_empty():game._schedule_event(false)
	return true
