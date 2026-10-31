extends RefCounted
## Pounds of carried supplies, excluding wagon, people and livestock.
## Gear/item masses, spoilage interval and load response are explicit game estimates.
var data: Dictionary = {}
var error := ""
var fresh: Array[Dictionary] = []
var carriers: Array[Dictionary] = []
# Source of the last whole serving, for retaining an uneaten fractional portion.
var last_serving: Dictionary={}
const Pelts=preload("res://simulation/pelts.gd")
const WagonTrade=preload("res://simulation/wagon_trade.gd")
const Produce=preload("res://simulation/produce_trade.gd")
const Carrying=preload("res://simulation/carrying.gd")
const Mounts=preload("res://simulation/mounts.gd")
const Shortfall=preload("res://simulation/food_shortage.gd")
func _init() -> void:
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/provisions.json")))
func load_data(value: Variant) -> bool:
	data = {}
	error = "Invalid provisions rules"
	if not value is Dictionary or not value.get("weights_lb") is Dictionary or not value.get("rations_lb") is Array or value.rations_lb.size() != 3:
		return false
	for key in ["cargo_guideline_lb", "household_gear_lb", "fresh_days", "light_load_lb", "full_load_speed", "working_load_per_ox_lb"]:
		if not number(value.get(key)) or value[key] <= 0:
			return false
	if value.light_load_lb >= value.cargo_guideline_lb or value.full_load_speed > 1 or value.fresh_days != int(value.fresh_days):
		return false
	if not value.get("preservation") is Dictionary:return false
	if not value.get("walking") is Dictionary:return false
	for key in ["carry_lb_per_person","personal_gear_lb_per_person","miles_per_day","packing_miles_per_day"]:
		if not number(value.walking.get(key)) or value.walking[key]<=0:return false
	if value.walking.personal_gear_lb_per_person>=value.walking.carry_lb_per_person or not Shortfall.valid_rules(value.get("shortfall")):return false
	for key in ["cache_loss_base","cache_loss_daily","cache_loss_cap"]:
		if not number(value.walking.get(key)) or value.walking[key]<0 or value.walking[key]>1:return false
	if not Carrying.valid_curve(value.walking.get("health_load_curve")):return false
	if not value.get("ox_slaughter") is Dictionary:return false
	if not number(value.ox_slaughter.get("minimum_team")) or value.ox_slaughter.minimum_team < 0 or value.ox_slaughter.minimum_team != int(value.ox_slaughter.minimum_team):return false
	for key in ["usable_meat_lb","bullets"]:
		if not number(value.ox_slaughter.get(key)) or value.ox_slaughter[key] < 1 or value.ox_slaughter[key] != int(value.ox_slaughter[key]):return false
	if not number(value.ox_slaughter.get("minimum_yield_factor")) or value.ox_slaughter.minimum_yield_factor <= 0 or value.ox_slaughter.minimum_yield_factor > 1:return false
	if not number(value.ox_slaughter.get("hand_injury_chance")) or value.ox_slaughter.hand_injury_chance < 0 or value.ox_slaughter.hand_injury_chance > 1:return false
	for key in ["batch_lb","days","salted_days"]:
		if not number(value.preservation.get(key)) or value.preservation[key] < 1 or value.preservation[key] != int(value.preservation[key]):return false
	for key in ["retained_food","salted_retained_food","dried_weight","salt_per_food_lb"]:
		if not number(value.preservation.get(key)) or value.preservation[key] <= 0 or value.preservation[key] > 1:return false
	if value.preservation.salted_retained_food < value.preservation.retained_food or value.preservation.salted_days < value.preservation.days:return false
	for key in ["food", "clothing", "bullets", "wheels", "axles", "tongues", "medicine", "salt"]:
		if not number(value.weights_lb.get(key)) or value.weights_lb[key] <= 0:
			return false
	if not Pelts.valid(value.get("pelts"),value.weights_lb):return false
	var energy: Variant=value.get("food_energy")
	if not energy is Dictionary or not energy.get("note") is String:return false
	for key in ["unit_kcal","generic_meat_kcal_per_lb"]:
		if not number(energy.get(key)) or energy[key]<=0 or energy[key]>10000:return false
	var previous := 0
	for amount in value.rations_lb:
		if not number(amount) or amount <= previous or amount != int(amount):
			return false
		previous = int(amount)
	if not number(value.get("meat_food_per_lb")) or value.meat_food_per_lb<=0 or value.meat_food_per_lb>1:return false
	var forage: Variant = value.get("foraging")
	if not forage is Dictionary or not forage.get("months") is Array or forage.months.size()!=12 or not forage.get("regions") is Dictionary or not forage.get("lb_per_worker") is Array or forage.lb_per_worker.size()!=2:return false
	for factor in forage.months + forage.regions.values():
		if not number(factor) or factor<0 or factor>1:return false
	for key in ["maximum_lb","fresh_days","mass_ratio","vitamin_c_lb_per_person"]:
		if not number(forage.get(key)) or forage[key]<=0:return false
	if forage.fresh_days!=floor(forage.fresh_days):return false
	for amount in forage.lb_per_worker:
		if not number(amount) or amount<0 or amount!=floor(amount):return false
	if forage.lb_per_worker[0]>forage.lb_per_worker[1]:return false
	if not Mounts.valid_rules(value.get("mounts")):return false
	if not Produce.valid_rules(value.get("produce_trade")) or not WagonTrade.valid_rules(value.get("replacement_wagon")):return false
	var guards: Variant=value.get("wagon_guards")
	if not guards is Dictionary or not guards.get("note") is String or not number(guards.get("hunt_below_days")) or guards.hunt_below_days<1 or guards.hunt_below_days>7 or guards.hunt_below_days!=floor(guards.hunt_below_days):return false
	for key in ["hunt_hit_chance","departure_chance","raid_injury"]:
		if not number(guards.get(key)) or guards[key]<0 or guards[key]>1:return false
	data = value.duplicate(true)
	if not preload("res://simulation/trail_income.gd").configure(self):return false
	if not preload("res://simulation/leathercraft.gd").configure(self):return false
	error = ""
	return true
func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
func household_mass(inventory: Dictionary) -> float:
	return float(inventory.household_gear_lb) if inventory.has("household_gear_lb") else float(data.household_gear_lb)+float(inventory.get("recruited_gear_lb",0))-float(inventory.get("departed_gear_lb",0))
func cargo(inventory: Dictionary) -> float:
	var pounds: float = float(data.walking.personal_gear_lb_per_person)*int(inventory.get("party_size",5)) if inventory.get("vehicle","")=="foot" else household_mass(inventory)
	pounds+=Mounts.spare_tack(data.mounts,inventory,Mounts.plan(data.mounts,inventory))
	# Bodies carried with the party weigh what they weigh, on foot or in the wagon.
	pounds+=preload("res://simulation/livestock.gd").cargo(inventory)+float(inventory.get("livestock_products_lb",0))+int(inventory.get("poultry_feed",0))*0.25+int(inventory.get("livestock_fodder",0))+float(inventory.get("poultry_feed_remainder_lb",0))+float(inventory.get("livestock_fodder_remainder_lb",0))
	pounds+=float(inventory.get("_raw_hides_lb",0))
	pounds+=preload("res://simulation/armory.gd").extra_weight(inventory)
	pounds+=float(inventory.get("remains_lb",0))+float(inventory.get("camp_greens_lb",0))
	for key in data.weights_lb:
		pounds += maxf(0, float(inventory.get(key, 0))) * float(data.weights_lb[key])
	# Food is staple-equivalent ration weight. Dried meat supplies the same
	# retained meals with less physical cargo; water loss is not calorie loss.
	pounds += tracked_mass(int(inventory.get("food",0)))-tracked_food(int(inventory.get("food",0)))
	return snappedf(pounds, 0.1)
func cart_cargo(cart: Dictionary) -> float:
	var inventory := cart.duplicate()
	inventory.bullets = int(cart.get("bullet_boxes", 0)) * 20
	return cargo(inventory)+int(cart.get("produce",0))*float(data.foraging.mass_ratio)+int(cart.get("dried_produce",0))*float(data.foraging.mass_ratio)*float(data.produce_trade.dry_weight)
func team_capacity(oxen: int) -> float:
	return minf(float(data.cargo_guideline_lb),maxi(0,oxen)*float(data.working_load_per_ox_lb))
func human_capacity(inventory: Dictionary,plan: Dictionary) -> float:
	var walkers: Array=Mounts.walking_members(carriers,int(plan.riding_people))
	return Carrying.capacity(walkers,float(data.walking.carry_lb_per_person),data.walking.health_load_curve) if not carriers.is_empty() else float(data.walking.carry_lb_per_person)*maxi(0,int(inventory.party_size)-int(plan.riding_people))
func capacity(inventory: Dictionary) -> float:
	if inventory.get("vehicle","")!="foot" and inventory.has("wagon_train"):return preload("res://simulation/wagon_train.gd").capacity(inventory,float(data.working_load_per_ox_lb),float(data.cargo_guideline_lb))
	if inventory.get("vehicle","")!="foot":return team_capacity(preload("res://simulation/team_conditions.gd").pulling(inventory))
	var plan: Dictionary=Mounts.plan(data.mounts,inventory)
	return snappedf(human_capacity(inventory,plan)+float(plan.animal_lb),0.1)
func storage_capacity(inventory: Dictionary) -> float:
	if inventory.get("vehicle","")!="foot":return float(data.cargo_guideline_lb)*preload("res://simulation/wagon_train.gd").count(inventory)
	var plan: Dictionary=Mounts.plan(data.mounts,inventory)
	return snappedf(human_capacity(inventory,plan)+Mounts.freight_limit(plan),0.1)
func load_profile(inventory: Dictionary) -> Dictionary:
	var plan: Dictionary=Mounts.plan(data.mounts,inventory)
	return Mounts.burden(data.mounts,plan,cargo(inventory),human_capacity(inventory,plan))
func movement_factor(pounds: float, oxen: int = 4) -> float:
	var capacity := team_capacity(oxen)
	if capacity <= 0:return 0.0
	var light := float(data.light_load_lb)*capacity/float(data.cargo_guideline_lb)
	var burden := maxf(0, (pounds - light) / (capacity - light))
	return clampf(1.0 - (1.0 - float(data.full_load_speed)) * burden, 0.35, 1.0)
func fresh_pounds(total: int) -> int:
	var count := 0
	for batch in fresh:
		if not batch.get("preserved",false):count += int(batch.pounds)
	return mini(total, count)
func preserved_pounds(total: int) -> int:
	var count := 0
	for batch in fresh:
		if batch.get("preserved",false):count += int(batch.pounds)
	return mini(total,count)
func tracked_food(total: int) -> int:
	return mini(total,fresh_pounds(total)+preserved_pounds(total))
func mass_ratio(batch: Dictionary) -> float:
	return float(batch.get("mass_ratio",data.preservation.dried_weight if batch.get("preserved",false) else 1.0))
func valid_mass_ratio(batch: Dictionary) -> bool:
	return not batch.has("mass_ratio") or (number(batch.mass_ratio) and batch.mass_ratio>=0.01 and batch.mass_ratio<=10)
func tracked_mass(total: int) -> float:
	var left:=total
	var mass:=0.0
	for batch in fresh:
		var used:=mini(left,int(batch.pounds))
		mass+=used*mass_ratio(batch)
		left-=used
	return mass
func fresh_mass(amount: int) -> float:
	var left:=amount
	var mass:=0.0
	for batch in fresh:
		if batch.get("preserved",false) or batch.get("vitamin_c",false) or batch.get("table_product",false):continue
		var used:=mini(left,int(batch.pounds))
		mass+=used*mass_ratio(batch)
		left-=used
	return mass
func processable() -> int:
	var room: float=data.preservation.batch_lb
	var amount:=0
	for batch in fresh:
		if batch.get("preserved",false) or batch.get("vitamin_c",false) or batch.get("table_product",false):continue
		var used:=mini(int(batch.pounds),floori((room+0.000001)/mass_ratio(batch)))
		amount+=used
		room-=used*mass_ratio(batch)
		if used<int(batch.pounds):break
	return amount
func preservation_plan(day: int,total: int,meal: int,party_size: int=5) -> Dictionary:
	var model=get_script().new()
	model.data=data.duplicate(true)
	model.fresh.assign(fresh.duplicate(true))
	var spoiled: int=model.spoil(day+1,total)
	model.eat(mini(meal,maxi(0,total-spoiled)),party_size,maxi(0,total-spoiled))
	var amount: int=model.processable()
	return {"input":amount,"mass":model.fresh_mass(amount)}
func preservable_next_day(day: int, total: int, meal: int) -> int:
	return int(preservation_plan(day,total,meal).input)
func preserve(amount: int, day: int, salted: bool) -> Dictionary:
	var input:=mini(maxi(0,amount),processable())
	var mass:=fresh_mass(input)
	var remaining:=input
	for batch in fresh:
		if batch.get("preserved",false) or batch.get("vitamin_c",false) or batch.get("table_product",false):continue
		var used:=mini(remaining,int(batch.pounds))
		batch.pounds-=used
		remaining-=used
	fresh=fresh.filter(func(batch):return batch.pounds>0)
	var kept:=floori(input*float(data.preservation.salted_retained_food if salted else data.preservation.retained_food))
	var ratio: float=float("%.12f" % ((mass/input if input>0 else 1.0)*float(data.preservation.dried_weight)))
	var expires:=day+int(data.preservation.salted_days if salted else data.preservation.days)+1
	if kept>0:fresh.append({"pounds":kept,"expires":expires,"preserved":true,"mass_ratio":ratio})
	return {"input":input,"mass":mass,"kept":kept,"lost":input-kept,"expires":expires,"weight":float(roundi(kept*ratio*10.0+0.0000001))/10.0,"salt":ceili(mass*float(data.preservation.salt_per_food_lb)) if salted else 0}
func meat_calories(physical_lb: float,kcal_per_lb: float=-1.0) -> float:
	return maxf(0,physical_lb)*float(data.food_energy.generic_meat_kcal_per_lb if kcal_per_lb<0 else kcal_per_lb)
func food_calories(units: float) -> float:return maxf(0,units)*float(data.food_energy.unit_kcal)
func meat_units(physical_lb: float,kcal_per_lb: float=-1.0,minimum_one: bool=true) -> int:
	return maxi(1 if minimum_one else 0,roundi(meat_calories(physical_lb,kcal_per_lb)/float(data.food_energy.unit_kcal))) if physical_lb>0 else 0
func add_meat(physical_lb: float,day: int,kcal_per_lb: float=-1.0,minimum_one: bool=true) -> int:
	var units:=meat_units(physical_lb,kcal_per_lb,minimum_one)
	if units>0:fresh.append({"pounds":units,"expires":day+int(data.fresh_days)+1,"mass_ratio":float("%.12f" % (float(physical_lb)/units))})
	return units
func add_produce(physical_lb: int, day: int) -> int:
	var units := floori(physical_lb / float(data.foraging.mass_ratio))
	if units > 0:
		fresh.append({"pounds": units, "expires": day + int(data.foraging.fresh_days) + 1, "mass_ratio": float(data.foraging.mass_ratio), "vitamin_c": true})
	return units

func remove(amount: int) -> float:
	# Eat/remove oldest tracked food first, then use the undifferentiated trail staples.
	var vitamin_c_eaten := 0.0
	fresh.sort_custom(func(a,b):return a.expires<b.expires)
	for batch in fresh:
		var used := mini(amount, int(batch.pounds))
		if batch.get("vitamin_c",false): vitamin_c_eaten += used * float(batch.get("vitamin_c_per_unit",mass_ratio(batch)))
		batch.pounds -= used
		amount -= used
	fresh = fresh.filter(func(batch): return batch.pounds > 0)
	return vitamin_c_eaten
func reconcile(total: int) -> void:
	var tracked := 0
	for batch in fresh:
		tracked += int(batch.pounds)
	if tracked > total:
		remove(tracked - total)
# Compatibility helper for old one-pound-per-unit ledgers; new meat uses add_meat.
func add_fresh(pounds: int, day: int) -> void:
	if pounds > 0:
		fresh.append({"pounds": pounds, "expires": day + int(data.fresh_days) + 1})
func spoil(day: int, total: int) -> int:
	reconcile(total)
	var lost := 0
	for batch in fresh:
		if day >= batch.expires:
			lost += int(batch.pounds)
	fresh = fresh.filter(func(batch): return day < batch.expires)
	return lost
func expected_days(total: int, party_size: int, rations: int) -> int:
	return floori(float(total) / maxi(1, party_size * int(data.rations_lb[rations])))
func forecast_days(total: int, party_size: int, rations: int, day: int, horizon: int=3) -> int:
	# Preview the same spoil-before-meals order without mutating the live ledger.
	var model=get_script().new()
	model.data=data.duplicate(true)
	model.fresh.assign(fresh.duplicate(true))
	var meal: int=maxi(1,party_size*int(data.rations_lb[rations]))
	for offset in range(1,horizon+1):
		total-=model.spoil(day+offset,total)
		if total<meal:return offset-1
		model.eat(meal,party_size,total)
		total-=meal
	return horizon

func valid_nutrients(batch: Dictionary) -> bool:
	if batch.has("vitamin_c") and not batch.vitamin_c is bool:return false
	if batch.has("vitamin_c_per_unit"):
		if not batch.get("vitamin_c",false) or not batch.get("preserved",false) or not number(batch.vitamin_c_per_unit) or batch.vitamin_c_per_unit<=0 or batch.vitamin_c_per_unit>float(data.foraging.mass_ratio):return false
	return not (batch.get("vitamin_c",false) and batch.get("preserved",false) and not batch.has("vitamin_c_per_unit"))

## Meals share a produce serving, then use other food; extra produce feeds shortages.
## Discarding/selling still uses remove(), without crediting dietary vitamins.
func eat(amount: int,party_size: int,total: int,vitamin_offset: float=0.0) -> float:
	var remaining:=amount
	last_serving={"lb":float(data.weights_lb.food),"expires":1000100,"vitamin_c_lb":0.0}
	var vitamin:=vitamin_offset
	var target: float=party_size*float(data.foraging.vitamin_c_lb_per_person)
	var produce_total:=0
	for batch in fresh:
		if batch.get("vitamin_c",false):produce_total+=int(batch.pounds)
	var ordinary:=maxi(0,total-produce_total)
	fresh.sort_custom(func(a,b):return a.expires<b.expires)
	for batch in fresh:
		if remaining<=0 or vitamin>=target:break
		if not batch.get("vitamin_c",false):continue
		var per_unit: float=float(batch.get("vitamin_c_per_unit",mass_ratio(batch)))
		var used: int=mini(mini(remaining,int(batch.pounds)),ceili((target-vitamin)/per_unit))
		if used>0:last_serving={"lb":mass_ratio(batch),"expires":int(batch.expires),"vitamin_c_lb":per_unit}
		batch.pounds-=used
		remaining-=used
		vitamin+=used*per_unit
	var other: int=mini(remaining,ordinary)
	remaining-=other
	for batch in fresh:
		if batch.get("vitamin_c",false):continue
		var used: int=mini(other,int(batch.pounds))
		if used>0:last_serving={"lb":mass_ratio(batch),"expires":int(batch.expires),"vitamin_c_lb":0.0,"hunt":bool(batch.get("_hunt_meal",false))}
		batch.pounds-=used
		other-=used
	if other>0:last_serving={"lb":float(data.weights_lb.food),"expires":1000100,"vitamin_c_lb":0.0}
	# Any remainder of 'other' was untracked staples. Food totals are committed by the engine.
	for batch in fresh:
		if remaining<=0:break
		if not batch.get("vitamin_c",false):continue
		var used: int=mini(remaining,int(batch.pounds))
		if used>0:last_serving={"lb":mass_ratio(batch),"expires":int(batch.expires),"vitamin_c_lb":float(batch.get("vitamin_c_per_unit",mass_ratio(batch)))}
		batch.pounds-=used
		remaining-=used
		vitamin+=used*float(batch.get("vitamin_c_per_unit",mass_ratio(batch)))
	fresh=fresh.filter(func(batch):return batch.pounds>0)
	return vitamin
