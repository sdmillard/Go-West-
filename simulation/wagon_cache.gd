extends RefCounted
## Inventory transfers and actual backtracking; no UI, global RNG or wall time.
const Provisions=preload("res://simulation/provisions.gd")
static func available(game,from_cache: bool=false) -> Dictionary:
	var result: Dictionary={}
	for key in game.provisions.data.weights_lb:
		result[key]=int(game.state[key])+(int(game.wagon_cache.inventory[key]) if from_cache and not game.wagon_cache.is_empty() else 0)
	if from_cache:
		for batch in game.wagon_cache.fresh:
			if batch.expires<=game.state.day:result.food-=int(batch.pounds)
	return result
static func can_pack(game,from_cache: bool=false) -> bool:
	if not game.state.extended_route or not game._can_act():return false
	if from_cache:return game.state.vehicle=="foot" and not game.wagon_cache.is_empty() and game.wagon_cache.found and game.state.miles==game.wagon_cache.mile
	return game.state.vehicle=="wagon" and game.wagon_cache.is_empty()
static func quote(game,cart: Dictionary,from_cache: bool=false) -> Dictionary:
	var result: Dictionary={"valid":false,"message":"Pack only between stops, without an unresolved event."}
	if not can_pack(game,from_cache):return result
	var stock:=available(game,from_cache)
	var selected: Dictionary={}
	for key in cart:
		if not stock.has(key):return result
	for key in stock:
		var count=cart.get(key,0)
		if (not count is int and not count is float) or not is_finite(float(count)) or count!=floor(count) or count<0 or count>stock[key]:
			result.message="Check your carried quantities."
			return result
		selected[key]=int(count)
	var batches: Array=game.provisions.fresh.duplicate(true)
	if from_cache:batches.append_array(game.wagon_cache.fresh.filter(func(batch):return batch.expires>game.state.day).duplicate(true))
	batches.sort_custom(func(a,b):return a.expires<b.expires)
	var carried: Array=[]
	var stored: Array=[]
	var remaining: int=selected.food
	for batch in batches:
		var take:=mini(remaining,int(batch.pounds))
		if take>0:
			var piece: Dictionary=batch.duplicate(true)
			piece.pounds=take
			carried.append(piece)
		if take<int(batch.pounds):
			var piece: Dictionary=batch.duplicate(true)
			piece.pounds-=take
			stored.append(piece)
		remaining-=take
	var pack:=Provisions.new()
	pack.data=game.provisions.data.duplicate(true)
	pack.carriers=game.party_health.members
	pack.fresh.assign(carried)
	var inventory:=selected.duplicate(true)
	inventory.merge({"vehicle":"foot","party_size":game.state.party_size,"remains_lb":int(game.state.get("remains_lb",0))})
	var cargo: float=pack.cargo(inventory)
	var capacity: float=pack.capacity(inventory)
	result.merge({"valid":cargo<=capacity,"message":"Ready to walk. Money, tools and surviving oxen stay with you." if cargo<=capacity else "Reduce your pack to the walking carry limit.","cargo_lb":cargo,"capacity_lb":capacity,"inventory":selected,"carried":carried,"stored":stored,"stock":stock},true)
	return result
static func pack(game,cart: Dictionary,from_cache: bool=false) -> bool:
	var offer:=quote(game,cart,from_cache)
	if not offer.valid:return false
	if from_cache:spoil_cache(game)
	var left: Dictionary={}
	for key in offer.stock:
		left[key]=int(offer.stock[key])-int(offer.inventory[key])
		game.state[key]=int(offer.inventory[key])
	if not from_cache:
		game.wagon_cache={"mile":int(game.state.miles),"day":int(game.state.day)+1,"found":true,"inventory":left,"fresh":offer.stored.duplicate(true)}
	else:
		game.wagon_cache.inventory=left
		game.wagon_cache.fresh=offer.stored.duplicate(true)
	game.provisions.fresh.assign(offer.carried)
	game.state.parts=game.state.wheels+game.state.axles+game.state.tongues
	game.state.vehicle="foot"
	if not from_cache:
		if "muddy_trail" not in game.seen:game.seen.append("muddy_trail")
		game.journal.append("Day %d · Abandoned the wagon at guide mile %d. Carried %.1f / %.1f lb; remaining goods cached. Money and surviving livestock stay with the party." % [game.state.day+1,game.state.miles,offer.cargo_lb,offer.capacity_lb])
		game._tick_day(false)
	else:game.journal.append("Day %d · Repacked supplies at the cached wagon. Carried %.1f / %.1f lb." % [game.state.day,offer.cargo_lb,offer.capacity_lb])
	if game.state.status=="traveling":game._schedule_event(false)
	return true
static func spoil_cache(game) -> void:
	var model:=Provisions.new()
	model.data=game.provisions.data.duplicate(true)
	model.fresh.assign(game.wagon_cache.fresh)
	var lost: int=model.spoil(int(game.state.day),int(game.wagon_cache.inventory.food))
	game.wagon_cache.inventory.food-=lost
	game.wagon_cache.fresh=model.fresh.duplicate(true)
	if lost>0:game.journal.append("Day %d · %d ration-lb of food spoiled in the abandoned wagon." % [game.state.day,lost])
static func relocate(game,miles: int) -> void:
	# Walk back along the road actually taken, then the leg in progress.
	var stops: Array=game.travelled_path().duplicate()
	if game.state.next_landmark!="" and game.state.next_landmark!=game.state.landmark:stops.append(game.state.next_landmark)
	# Beyond that (scenario fixtures), the main road onward.
	while not game.route.nodes[stops[-1]].next.is_empty():stops.append(game.route.nodes[stops[-1]].next[0].to)
	var base:=0
	for index in range(stops.size()-1):
		var id: String=stops[index]
		var edge: Dictionary=game.route.edge_between(id,stops[index+1])
		if miles<base+int(edge.miles):
			game.state.merge({"miles":miles,"landmark":id,"next_landmark":edge.to,"leg_length":int(edge.miles),"leg_miles":miles-base,"terrain":game.route.nodes[id].get("terrain","plains"),"river_stage":""},true)
			game.route_path=stops.slice(0,index+1)
			return
		base+=int(edge.miles)
static func recover(game) -> bool:
	if not game._can_act() or game.state.vehicle!="foot" or game.wagon_cache.is_empty():return false
	var target: int=game.wagon_cache.mile
	if game.state.miles>target and game.walking_overloaded():return true
	game.journal.append("Day %d · Backtracking from mile %d toward the abandoned wagon at mile %d." % [game.state.day,game.state.miles,target])
	while game.state.miles>target:
		game._tick_day(false,true)
		if game.state.status!="traveling":return true
		if game.walking_overloaded():return true
		var distance: int=game.walking_distance()
		relocate(game,maxi(target,int(game.state.miles)-distance))
	if not game.wagon_cache.found:
		var rules: Dictionary=game.provisions.data.walking
		var chance:=minf(float(rules.cache_loss_cap),float(rules.cache_loss_base)+maxi(0,int(game.state.day)-int(game.wagon_cache.day))*float(rules.cache_loss_daily))
		if game.rng.randf()<chance:
			game.supply_history.append({"day":game.state.day,"event":"wagon_cache_lost","mile":game.state.miles,"cached_lost":game.wagon_cache.inventory.duplicate(true)})
			game.journal.append("Day %d · The abandoned wagon is gone or ruined. Its cached supplies are lost; the party remains on foot at mile %d." % [game.state.day,game.state.miles])
			game.wagon_cache={}
			return true
	game.wagon_cache.found=true
	spoil_cache(game)
	if game.state.oxen<1:
		game.journal.append("Day %d · Found the wagon, but no ox can pull it. Repack what you can carry, or trade for an animal." % game.state.day)
		return true
	for key in game.wagon_cache.inventory:game.state[key]+=int(game.wagon_cache.inventory[key])
	game.provisions.fresh.append_array(game.wagon_cache.fresh.duplicate(true))
	game.state.parts=game.state.wheels+game.state.axles+game.state.tongues
	game.state.vehicle="wagon"
	game.wagon_cache={}
	game._tick_day(false)
	game.journal.append("Day %d · Recovered and hitched the wagon. Forward progress resumes from mile %d; backtracking miles must be traveled again." % [game.state.day,game.state.miles])
	if game.state.status=="traveling":game._schedule_event(false)
	return true
static func valid(value: Variant,game,day: int) -> bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	for field in ["mile","day"]:
		if (not value.get(field) is int and not value.get(field) is float) or not is_finite(float(value[field])) or value[field]!=floor(value[field]) or value[field]<0:return false
	if value.mile>game.route.longest_miles or value.day>day or not value.get("found") is bool or not value.get("inventory") is Dictionary or not value.get("fresh") is Array:return false
	if value.inventory.size()!=game.provisions.data.weights_lb.size():return false
	for key in game.provisions.data.weights_lb:
		var count=value.inventory.get(key)
		if (not count is int and not count is float) or not is_finite(float(count)) or count!=floor(count) or count<0 or count>1000000:return false
	var pounds:=0
	for batch in value.fresh:
		if not batch is Dictionary:return false
		for field in ["pounds","expires"]:
			var count=batch.get(field)
			if (not count is int and not count is float) or not is_finite(float(count)) or count!=floor(count) or count<1 or count>1000100:return false
		if batch.has("vitamin_c") and (not batch.vitamin_c is bool or (batch.vitamin_c and batch.get("preserved",false))):return false
		if batch.has("preserved") and not batch.preserved is bool:return false
		if not Provisions.new().valid_mass_ratio(batch):return false
		pounds+=int(batch.pounds)
	return pounds<=value.inventory.food
