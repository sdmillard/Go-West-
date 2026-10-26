extends RefCounted
## Inventory transfers and actual backtracking; no UI, global RNG or wall time.
const Provisions=preload("res://simulation/provisions.gd")
static func available(game,from_cache: bool=false) -> Dictionary:
	var result: Dictionary={}
	for key in game.provisions.data.weights_lb:
		result[key]=int(game.state.get(key,0))+(int(game.wagon_cache.inventory.get(key,0)) if from_cache and not game.wagon_cache.is_empty() else 0)
	if from_cache:
		for batch in game.wagon_cache.fresh:
			if batch.expires<=game.state.day:result.food-=int(batch.pounds)
	return result
static func can_pack(game,from_cache: bool=false) -> bool:
	if not game.state.extended_route:return false
	if from_cache:return game.can_service() and game.state.vehicle=="foot" and not game.wagon_cache.is_empty() and game.wagon_cache.found and game.Direction.at_cache(game)
	if not game._can_act():return false
	return game.state.vehicle=="wagon" and game.wagon_cache.is_empty()
## forced: a getaway in the middle of a crime or a chase, when nobody could stop to pack properly.
static func quote(game,cart: Dictionary,from_cache: bool=false,guard_ids: Array=[],selling: bool=false,forced: bool=false) -> Dictionary:
	var result: Dictionary={"valid":false,"message":"Pack only between stops, without an unresolved event."}
	if forced:
		if from_cache or game.state.vehicle!="wagon" or not game.wagon_cache.is_empty():return result
	elif selling:
		if not game.can_service() or game.state.vehicle!="wagon" or game.post_store().is_empty():return result
	elif not can_pack(game,from_cache):return result
	if (from_cache and not guard_ids.is_empty()) or not game.Guards.valid_selection(game,guard_ids):
		result.message="Choose living companions to guard the wagon; the leader must travel."
		return result
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
	pack.carriers.assign(game.party_health.members.duplicate(true))
	for id in guard_ids:pack.carriers[int(id)]["guarding"]=true
	pack.fresh.assign(carried)
	var inventory:=selected.duplicate(true)
	inventory.merge({"vehicle":"foot","party_size":int(game.state.party_size)-guard_ids.size(),"remains_lb":int(game.state.get("remains_lb",0))})
	# Horses, mules and their tack stay with the party and carry what they can.
	inventory.merge(game.Mounts.carried(game.state))
	var cargo: float=pack.cargo(inventory)
	var capacity: float=pack.storage_capacity(inventory)
	var mode: String=game.Mounts.plan(game.provisions.data.mounts,inventory).mode
	var ready: String={"mounted":"Ready to ride on. Money, tools and surviving animals stay with you.","doubled":"Ready to ride on doubled up. That wears the animals out fast.","packing":"Ready to walk with the pack animals. Money, tools and surviving animals stay with you."}.get(mode,"Ready to walk. Money, tools and surviving oxen stay with you.")
	for key in game.Mounts.KEYS+["double_up","lead_mounts","strenuous_load"]:inventory.erase(key)
	result.merge({"valid":cargo<=capacity,"message":ready if cargo<=capacity else "Reduce your pack to the carry limit of your party and animals.","cargo_lb":cargo,"capacity_lb":capacity,"inventory":selected,"carried":carried,"stored":stored,"stock":stock},true)
	return result
static func pack(game,cart: Dictionary,from_cache: bool=false,guard_ids: Array=[],forced: bool=false) -> bool:
	var offer:=quote(game,cart,from_cache,guard_ids,false,forced)
	if not offer.valid:return false
	if from_cache:spoil_cache(game)
	var left: Dictionary={}
	for key in offer.stock:
		left[key]=int(offer.stock[key])-int(offer.inventory[key])
		game.state[key]=int(offer.inventory[key])
	if not from_cache:
		game.wagon_cache={"household_gear_lb":maxf(0.0,game.provisions.household_mass(game.state)-float(game.provisions.data.walking.personal_gear_lb_per_person)*(int(game.state.party_size)-guard_ids.size())),"location":location(game),"mile":int(game.state.miles),"day":int(game.state.day)+(0 if forced else 1),"found":true,"inventory":left,"fresh":offer.stored.duplicate(true)}
		if not game.camp_repair.work.is_empty():
			game.wagon_cache["camp_repair"]=game.camp_repair.work.duplicate(true)
			game.camp_repair.work={}
		game.Guards.assign(game,guard_ids)
	else:
		game.wagon_cache.inventory=left
		game.wagon_cache.fresh=offer.stored.duplicate(true)
	game.provisions.fresh.assign(offer.carried)
	game.state.parts=game.state.wheels+game.state.axles+game.state.tongues
	game.state.vehicle="foot"
	game.state["household_gear_lb"]=float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size)
	if not from_cache:
		if "muddy_trail" not in game.seen:game.seen.append("muddy_trail")
		game.journal.append("Day %d · Abandoned the wagon at guide mile %d. Carried %.1f / %.1f lb; remaining goods cached. Money and surviving livestock stay with the party." % [game.state.day+(0 if forced else 1),game.state.miles,offer.cargo_lb,offer.capacity_lb])
		# A getaway's day is the flight itself.
		if not forced:game._tick_day(false)
	else:game.journal.append("Day %d · Repacked supplies at the cached wagon. Carried %.1f / %.1f lb." % [game.state.day,offer.cargo_lb,offer.capacity_lb])
	if game.state.status=="traveling" and game.pending.is_empty():game._schedule_event(false)
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
	return _recover_here(game)

static func inspect(game) -> bool:
	if not game.can_service() or game.wagon_cache.is_empty() or not game.Direction.at_cache(game):return false
	return _recover_here(game)

static func _recover_here(game) -> bool:
	var stopped: bool=game.pending.has("landmark")
	if not game.Guards.reveal(game):
		game.supply_history.append({"day":game.state.day,"event":"wagon_cache_lost","mile":game.state.miles})
		game.journal.append("Day %d · Found the wagon camp looted or ruined. Its remaining supplies are gone." % game.state.day)
		game.wagon_cache={}
		return true
	if not game.wagon_cache.found and not game.wagon_cache.has("camp_random"):
		var rules: Dictionary=game.provisions.data.walking
		var chance:=minf(float(rules.cache_loss_cap),float(rules.cache_loss_base)+maxi(0,int(game.state.day)-int(game.wagon_cache.day))*float(rules.cache_loss_daily))
		if game.rng.randf()<chance:
			game.supply_history.append({"day":game.state.day,"event":"wagon_cache_lost","mile":game.state.miles,"cached_lost":game.wagon_cache.inventory.duplicate(true)})
			game.journal.append("Day %d · The abandoned wagon is gone or ruined. Its cached supplies are lost; the party remains on foot at mile %d." % [game.state.day,game.state.miles])
			game.wagon_cache={}
			return true
	game.wagon_cache.found=true
	spoil_cache(game)
	if game.state.oxen<1 and game.state.vehicle=="foot":
		game.journal.append("Day %d · Found the wagon, but no ox can pull it. Repack what you can carry, or trade for an animal." % game.state.day)
		return true
	for key in game.wagon_cache.inventory:game.state[key]=int(game.state.get(key,0))+int(game.wagon_cache.inventory[key])
	game.provisions.fresh.append_array(game.wagon_cache.fresh.duplicate(true))
	game.state.parts=game.state.wheels+game.state.axles+game.state.tongues
	game.state["household_gear_lb"]=game.provisions.household_mass(game.state)+float(game.wagon_cache.get("household_gear_lb",maxf(0.0,float(game.provisions.data.household_gear_lb)-float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size))))
	game.state.vehicle="wagon"
	game.camp_repair.work=game.wagon_cache.get("camp_repair",{}).duplicate(true)
	game.wagon_cache={}
	game._tick_day(false)
	game.journal.append("Day %d · Recovered and hitched the wagon. Forward progress resumes from mile %d; backtracking miles must be traveled again." % [game.state.day,game.state.miles])
	if game.state.status=="traveling":
		if stopped:game._arrive_landmark(true,false)
		else:game._schedule_event(false)
	return true
## Where the wagon is left. At a stop, it stands at the end of the leg that led there.
static func location(game) -> Dictionary:
	var path: Array=game.travelled_path().duplicate()
	if game.state.next_landmark==game.state.landmark and path.size()>=2:
		var from: String=str(path[-2])
		return {"from":from,"to":str(game.state.landmark),"offset":int(game.route.edge_between(from,str(game.state.landmark)).miles),"path":path.slice(0,-1)}
	return {"from":str(game.state.landmark),"to":str(game.state.next_landmark),"offset":int(game.state.leg_miles),"path":path}
static func valid(value: Variant,game,day: int) -> bool:
	if not value is Dictionary:return false
	if value.has("household_gear_lb") and (not (value.household_gear_lb is int or value.household_gear_lb is float) or not is_finite(value.household_gear_lb) or value.household_gear_lb<0 or value.household_gear_lb>100000):return false
	if value.is_empty():return true
	for field in ["mile","day"]:
		if (not value.get(field) is int and not value.get(field) is float) or not is_finite(float(value[field])) or value[field]!=floor(value[field]) or value[field]<0:return false
	if value.mile>game.route.longest_miles or value.day>day or not value.get("found") is bool or not value.get("inventory") is Dictionary or not value.get("fresh") is Array:return false
	if value.has("location"):
		var at: Variant=value.location
		if not at is Dictionary or not at.get("from") is String or not at.get("to") is String or not game.route.valid_path(at.get("path",[])) or at.path[-1]!=at.from:return false
		var edge: Dictionary=game.route.edge_between(at.from,at.to)
		if edge.is_empty() or not (at.get("offset") is int or at.get("offset") is float) or at.offset!=floor(at.offset) or at.offset<0 or at.offset>int(edge.miles):return false
		var mileage:=0
		for index in range(at.path.size()-1):mileage+=int(game.route.edge_between(at.path[index],at.path[index+1]).miles)
		if mileage+int(at.offset)!=int(value.mile):return false
	if not game.camp_repair.valid(value.get("camp_repair",{}),game):return false
	if not game.Guards.valid(value,game,day):return false
	if not game.Pelts.valid_inventory(value.inventory,game.provisions.data.weights_lb,game.provisions.data.pelts.goods):return false
	for key in game.provisions.data.weights_lb:
		var count=value.inventory.get(key,0)
		if (not count is int and not count is float) or not is_finite(float(count)) or count!=floor(count) or count<0 or count>1000000:return false
	var pounds:=0
	for batch in value.fresh:
		if not batch is Dictionary:return false
		for field in ["pounds","expires"]:
			var count=batch.get(field)
			if (not count is int and not count is float) or not is_finite(float(count)) or count!=floor(count) or count<1 or count>1000100:return false
		if not Provisions.new().valid_nutrients(batch):return false
		if batch.has("preserved") and not batch.preserved is bool:return false
		if not Provisions.new().valid_mass_ratio(batch):return false
		pounds+=int(batch.pounds)
	return pounds<=value.inventory.food
