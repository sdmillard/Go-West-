extends RefCounted
## Saddle and pack animals for a party travelling without a wagon. Each animal is either under
## a saddle (one rider and its saddlebags, or two riders doubled up) or under a pack saddle.
## Loads, miles and wear are authored game tuning, not measured 1848 figures.
const ANIMALS=["horses","mules"]
const TACK=["saddles","pack_saddles","saddlebags"]
const KEYS=["horses","mules","saddles","pack_saddles","saddlebags"]
const MODES=["wagon","walking","packing","doubled","mounted"]

static func valid_rules(v: Variant) -> bool:
	if not v is Dictionary or not v.get("note") is String:return false
	for animal in ["horse","mule"]:
		if not v.get(animal) is Dictionary or not whole(v[animal].get("pack_lb"),1,1000) or not whole(v[animal].get("meat_lb"),1,1000):return false
	for key in ["saddlebag_lb","mounted_miles_per_day","doubled_wear","rest_recovery","breakdown_condition","guard_factor","guard_fatigue"]:
		if not whole(v.get(key),1,100):return false
	if not (v.get("light_work_load") is int or v.get("light_work_load") is float) or not is_finite(float(v.light_work_load)) or v.light_work_load<=0 or v.light_work_load>=1:return false
	if not v.get("forage_strain") is Dictionary:return false
	for region in v.forage_strain:
		if not whole(v.forage_strain[region],0,10):return false
	return true
static func whole(v: Variant,low: int,high: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=low and v<=high

## The keys are optional: a party that never owned an animal (and every older record) has none,
## so its state and saves are exactly as before. Read them through count/condition.
static func count(state: Dictionary,key: String) -> int:return int(state.get(key,0))
static func condition(state: Dictionary) -> int:return int(state.get("horse_health",100))
static func valid_state(s: Dictionary) -> bool:
	for key in KEYS:
		if s.has(key) and not whole(s[key],0,1000):return false
	return (not s.has("horse_health") or whole(s.horse_health,0,100)) and (not s.has("double_up") or s.double_up is bool) and (not s.has("night_guard") or s.night_guard is bool)
static func animals(inventory: Dictionary) -> int:return int(inventory.get("horses",0))+int(inventory.get("mules",0))
## Only the stock and tack keys of an inventory, for pack and sale quotes.
static func carried(state: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for key in KEYS:result[key]=int(state.get(key,0))
	result["double_up"]=bool(state.get("double_up",false))
	return result

## How the animals are used. Horses go under the saddles first and mules under the packs,
## as packers preferred; only as many saddles are used as there are riders.
static func plan(rules: Dictionary,inventory: Dictionary) -> Dictionary:
	var riders: int=maxi(0,int(inventory.get("party_size",5)))
	var horses: int=int(inventory.get("horses",0))
	var mules: int=int(inventory.get("mules",0))
	var saddled: int=mini(mini(int(inventory.get("saddles",0)),horses+mules),riders)
	var saddled_horses: int=mini(horses,saddled)
	var saddled_mules: int=saddled-saddled_horses
	var free_mules: int=mules-saddled_mules
	var free_horses: int=horses-saddled_horses
	var packs: int=mini(int(inventory.get("pack_saddles",0)),free_mules+free_horses)
	var pack_mules: int=mini(free_mules,packs)
	var pack_horses: int=packs-pack_mules
	var bags: int=mini(int(inventory.get("saddlebags",0)),saddled)
	var mode: String="wagon"
	if inventory.get("vehicle","")=="foot":
		if riders>0 and saddled>=riders:mode="mounted"
		elif riders>0 and inventory.get("double_up",false) and saddled*2>=riders:mode="doubled"
		elif saddled+packs>0:mode="packing"
		else:mode="walking"
	var lb: float=bags*float(rules.saddlebag_lb)+pack_horses*float(rules.horse.pack_lb)+pack_mules*float(rules.mule.pack_lb)
	return {"mode":mode,"riders":riders,"saddled":saddled,"saddled_horses":saddled_horses,"saddled_mules":saddled_mules,"pack_horses":pack_horses,"pack_mules":pack_mules,"led":horses+mules-saddled-packs,"bags":bags,"animal_lb":lb if mode!="wagon" else 0.0}

static func mounted(plan_: Dictionary) -> bool:return plan_.mode in ["mounted","doubled"]
static func label(plan_: Dictionary) -> String:
	return {"mounted":"MOUNTED","doubled":"DOUBLED UP","packing":"PACK TRAIN / ON FOOT","walking":"ON FOOT / PACKS","wagon":"WAGON"}[plan_.mode]
static func describe(plan_: Dictionary) -> String:
	var parts: Array[String]=[]
	if plan_.saddled>0:parts.append("%d under saddle" % plan_.saddled)
	if plan_.pack_horses+plan_.pack_mules>0:parts.append("%d packing" % (plan_.pack_horses+plan_.pack_mules))
	if plan_.led>0:parts.append("%d led" % plan_.led)
	return ", ".join(parts)

## A day's miles for a mounted party, before load and fatigue; walking parties use the foot rules.
static func base_miles(rules: Dictionary,condition: int,pace: int) -> float:
	return float(rules.mounted_miles_per_day)*[1.0,1.15,1.3][pace]*(0.55+0.45*clampf(condition/100.0,0.0,1.0))

## Daily wear on the animals that carry riders or packs. Returns the strain applied.
static func wear(rules: Dictionary,plan_: Dictionary,region: String,base_strain: int,pace: int,load_ratio: float=1.0) -> int:
	if plan_.mode in ["wagon","walking"]:return 0
	# Light work at a cautious pace can be sustained on good grazing; heavier loads,
	# haste, poor grass and winter still draw down condition. Doubling is always hard work.
	var workload: int=1 if load_ratio>float(rules.light_work_load) else 0
	# Mules thrive on forage that wears horses down: an all-mule string takes no forage strain.
	var forage: int=0 if int(plan_.get("saddled_horses",0))+int(plan_.get("pack_horses",0))==0 else int(rules.forage_strain.get(region,0))
	var strain: int=workload+base_strain+forage+pace
	if plan_.mode=="doubled":strain=maxi(1,strain)*int(rules.doubled_wear)
	return strain

## A worn-out animal gives out under its load: one is lost and the rest are rested a little.
static func breakdown(game) -> void:
	var rules: Dictionary=game.provisions.data.mounts
	var working: Dictionary=game.mount_plan()
	if working.mode not in ["mounted","doubled","packing"]:return
	var horses: int=int(working.saddled_horses)+int(working.pack_horses)
	var mules: int=int(working.saddled_mules)+int(working.pack_mules)
	if horses+mules==0:return
	var kind: String="horses" if horses>0 else "mules"
	game.state[kind]=int(game.state[kind])-1
	game.state["horse_health"]=int(rules.breakdown_condition)
	var name: String="horse" if kind=="horses" else "mule"
	game.journal.append("Day %d · A %s gave out under its load and had to be left on the road." % [game.state.day,name])
	game.health_events.append("A worn-out %s gave out and was left behind. Rest the animals or lighten their loads." % name)
	game.supply_history.append({"day":int(game.state.day),"event":"animal_breakdown","changes":{kind:-1}})
