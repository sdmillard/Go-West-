extends RefCounted
## Pounds of carried supplies, excluding wagon, people and livestock.
## Gear/item masses, spoilage interval and load response are explicit game estimates.
var data: Dictionary = {}
var error := ""
var fresh: Array[Dictionary] = []
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
	for key in ["carry_lb_per_person","personal_gear_lb_per_person","miles_per_day"]:
		if not number(value.walking.get(key)) or value.walking[key]<=0:return false
	if value.walking.personal_gear_lb_per_person>=value.walking.carry_lb_per_person:return false
	for key in ["cache_loss_base","cache_loss_daily","cache_loss_cap"]:
		if not number(value.walking.get(key)) or value.walking[key]<0 or value.walking[key]>1:return false
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
	var previous := 0
	for amount in value.rations_lb:
		if not number(amount) or amount <= previous or amount != int(amount):
			return false
		previous = int(amount)
	data = value.duplicate(true)
	error = ""
	return true
func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
func cargo(inventory: Dictionary) -> float:
	var pounds: float = float(data.walking.personal_gear_lb_per_person)*int(inventory.get("party_size",5)) if inventory.get("vehicle","")=="foot" else float(data.household_gear_lb)
	if inventory.get("vehicle","")!="foot":pounds-=float(inventory.get("departed_gear_lb",0))
	for key in data.weights_lb:
		pounds += maxf(0, float(inventory.get(key, 0))) * float(data.weights_lb[key])
	# Food is staple-equivalent ration weight. Dried meat supplies the same
	# retained meals with less physical cargo; water loss is not calorie loss.
	pounds -= preserved_pounds(int(inventory.get("food",0))) * (1.0-float(data.preservation.dried_weight))
	return snappedf(pounds, 0.1)
func cart_cargo(cart: Dictionary) -> float:
	var inventory := cart.duplicate()
	inventory.bullets = int(cart.get("bullet_boxes", 0)) * 20
	return cargo(inventory)
func team_capacity(oxen: int) -> float:
	return minf(float(data.cargo_guideline_lb),maxi(0,oxen)*float(data.working_load_per_ox_lb))
func capacity(inventory: Dictionary) -> float:
	return float(data.walking.carry_lb_per_person)*int(inventory.party_size) if inventory.get("vehicle","")=="foot" else team_capacity(int(inventory.oxen))
func storage_capacity(inventory: Dictionary) -> float:
	return capacity(inventory) if inventory.get("vehicle","")=="foot" else float(data.cargo_guideline_lb)
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
func preservable_next_day(day: int, total: int, meal: int) -> int:
	var count := 0
	for batch in fresh:
		if not batch.get("preserved",false) and batch.expires > day+1:count+=int(batch.pounds)
	return mini(int(data.preservation.batch_lb),maxi(0,mini(total,count)-meal))
func preserve(amount: int, day: int, salted: bool) -> Dictionary:
	var input := maxi(0,mini(amount,fresh_pounds(2147483647)))
	var remaining := input
	for batch in fresh:
		if batch.get("preserved",false):continue
		var used := mini(remaining,int(batch.pounds))
		batch.pounds-=used
		remaining-=used
	fresh = fresh.filter(func(batch):return batch.pounds>0)
	var kept := floori(input*float(data.preservation.salted_retained_food if salted else data.preservation.retained_food))
	var expires := day+int(data.preservation.salted_days if salted else data.preservation.days)+1
	if kept > 0:fresh.append({"pounds":kept,"expires":expires,"preserved":true})
	return {"input":input,"kept":kept,"lost":input-kept,"expires":expires,"weight":snappedf(kept*float(data.preservation.dried_weight),0.1)}
func remove(amount: int) -> void:
	# Eat/remove oldest meat first, then use the undifferentiated trail staples.
	fresh.sort_custom(func(a,b):return a.expires<b.expires)
	for batch in fresh:
		var used := mini(amount, int(batch.pounds))
		batch.pounds -= used
		amount -= used
	fresh = fresh.filter(func(batch): return batch.pounds > 0)
func reconcile(total: int) -> void:
	var tracked := 0
	for batch in fresh:
		tracked += int(batch.pounds)
	if tracked > total:
		remove(tracked - total)
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
		model.remove(meal)
		total-=meal
	return horizon
