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
	for key in ["rider_lb","riding_tack_lb","pack_tack_lb","loose_bags_lb","riding_lash_lb","riding_lash_max_lb","led_lash_lb","led_lash_max_lb","overload_wear","improvised_wear"]:
		if not whole(v.get(key),1,1000):return false
	for species in ["horse","mule"]:
		for key in ["max_pack_lb","working_load_lb","max_load_lb"]:
			if not whole(v[species].get(key),1,1000):return false
		if v[species].max_load_lb<v[species].working_load_lb or v[species].max_pack_lb<v[species].pack_lb or v[species].pack_lb+v.pack_tack_lb>v[species].working_load_lb or v[species].max_pack_lb+v.pack_tack_lb>v[species].max_load_lb:return false
	if v.riding_lash_max_lb<v.riding_lash_lb or v.led_lash_max_lb<v.led_lash_lb:return false
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
	return (not s.has("lead_mounts") or s.lead_mounts is bool) and (not s.has("strenuous_load") or s.strenuous_load is bool) and (not s.has("horse_health") or whole(s.horse_health,0,100)) and (not s.has("double_up") or s.double_up is bool) and (not s.has("night_guard") or s.night_guard is bool)
static func animals(inventory: Dictionary) -> int:return int(inventory.get("horses",0))+int(inventory.get("mules",0))
## Only the stock and tack keys of an inventory, for pack and sale quotes.
static func carried(state: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for key in KEYS:result[key]=int(state.get(key,0))
	result["double_up"]=bool(state.get("double_up",false))
	for key in ["lead_mounts","strenuous_load"]:result[key]=bool(state.get(key,false))
	return result

## How the animals are used. Horses go under the saddles first and mules under the packs,
## as packers preferred; only as many saddles are used as there are riders.
static func plan(rules: Dictionary,inventory: Dictionary) -> Dictionary:
	var people: int=maxi(0,int(inventory.get("party_size",5)))
	var horses: int=count(inventory,"horses");var mules: int=count(inventory,"mules")
	var saddled: int=mini(mini(count(inventory,"saddles"),horses+mules),people)
	var saddled_horses: int=mini(horses,saddled);var saddled_mules: int=saddled-saddled_horses
	var packs: int=mini(count(inventory,"pack_saddles"),horses+mules-saddled)
	var pack_mules: int=mini(mules-saddled_mules,packs);var pack_horses: int=packs-pack_mules
	var bags: int=mini(count(inventory,"saddlebags"),saddled)
	var lead: bool=inventory.get("lead_mounts",false)
	var riding_people: int=0 if lead else saddled
	var mode: String="wagon"
	if inventory.get("vehicle","")=="foot":
		if lead:mode="packing" if saddled+packs>0 else "walking"
		elif people>0 and saddled>=people:mode="mounted"
		elif people>0 and inventory.get("double_up",false) and saddled*2>=people:mode="doubled";riding_people=people
		else:mode="packing" if saddled+packs>0 else "walking"
	else:riding_people=0
	var loads: Array=[]
	var extra_riders: int=maxi(0,riding_people-saddled)
	var bag_count: int=bags
	for species in ["horse","mule"]:
		var seats: int=saddled_horses if species=="horse" else saddled_mules
		var packed: int=pack_horses if species=="horse" else pack_mules
		for i in range(seats+packed):
			var saddle: bool=i<seats
			var riders: int=0 if lead or mode=="wagon" or not saddle else 1
			if riders>0 and extra_riders>0:riders+=1;extra_riders-=1
			var bag: bool=saddle and bag_count>0
			if bag:bag_count-=1
			var tack: float=float(rules.riding_tack_lb if saddle else rules.pack_tack_lb)
			var base: float=riders*float(rules.rider_lb)+tack
			var secured: float=float(rules.riding_lash_lb)+(float(rules.saddlebag_lb) if bag else 0.0) if riders>0 else float(rules.led_lash_lb if saddle else rules[species].pack_lb)
			var secured_max: float=float(rules.riding_lash_max_lb)+(float(rules.saddlebag_lb) if bag else 0.0) if riders>0 else float(rules.led_lash_max_lb if saddle else rules[species].max_pack_lb)
			loads.append({"species":species,"riders":riders,"tack_lb":tack,"base_lb":base,"working_total_lb":float(rules[species].working_load_lb),"max_total_lb":float(rules[species].max_load_lb),"working_lb":minf(secured,maxf(0,float(rules[species].working_load_lb)-base)),"max_lb":minf(secured_max,maxf(0,float(rules[species].max_load_lb)-base)),"improvised":saddle and riders==0})
	var working: float=0 if mode=="wagon" else loads.reduce(func(n,row):return n+float(row.working_lb),0.0)
	var maximum: float=0 if mode=="wagon" else loads.reduce(func(n,row):return n+float(row.max_lb),0.0)
	return {"mode":mode,"riders":people,"riding_people":riding_people,"saddled":saddled,"saddled_horses":saddled_horses,"saddled_mules":saddled_mules,"pack_horses":pack_horses,"pack_mules":pack_mules,"led":horses+mules-saddled-packs,"bags":bags,"animal_lb":working,"max_animal_lb":maximum,"loads":loads,"strenuous":inventory.get("strenuous_load",false) or mode=="doubled","leading":lead}
static func freight_limit(plan_: Dictionary) -> float:return float(plan_.max_animal_lb if plan_.strenuous else plan_.animal_lb)
static func walking_members(members: Array,riding: int) -> Array:
	var walkers: Array=[]
	for member in members:
		if not member.alive or member.get("departed",false) or member.get("guarding",false) or member.get("away",false):continue
		if riding>0:riding-=1
		else:walkers.append(member)
	return walkers
static func spare_tack(rules: Dictionary,inventory: Dictionary,plan_: Dictionary) -> float:
	return maxi(0,count(inventory,"saddles")-int(plan_.saddled))*float(rules.riding_tack_lb)+maxi(0,count(inventory,"pack_saddles")-int(plan_.pack_horses)-int(plan_.pack_mules))*float(rules.pack_tack_lb)+maxi(0,count(inventory,"saddlebags")-int(plan_.bags))*float(rules.loose_bags_lb)
static func burden(rules: Dictionary,plan_: Dictionary,cargo: float,human_capacity: float) -> Dictionary:
	var working: float=float(plan_.animal_lb)
	var animal_cargo: float=minf(cargo,working)
	var human_cargo: float=minf(maxf(0,cargo-animal_cargo),human_capacity)
	animal_cargo+=maxf(0,cargo-animal_cargo-human_cargo)
	var extra: float=maxf(0,animal_cargo-working)
	var extra_room: float=maxf(0,float(plan_.max_animal_lb)-working)
	var ratio:=0.0;var kind: String="";var improvised:=false
	var fitted:=0.0;var body:=0.0
	for row in plan_.loads:
		var carried: float=minf(animal_cargo,working)*float(row.working_lb)/working if working>0 else 0.0
		if extra_room>0:carried+=extra*(float(row.max_lb)-float(row.working_lb))/extra_room
		var actual: float=(float(row.base_lb)+carried)/float(row.working_total_lb)
		if actual>ratio:ratio=actual;kind=str(row.species)+"s"
		if row.improvised and carried>0:improvised=true
		fitted+=float(row.tack_lb);body+=float(row.riders)*float(rules.rider_lb)
	return {"ratio":ratio,"human_ratio":human_cargo/human_capacity if human_capacity>0 else 0.0,"worst_kind":kind,"improvised":improvised,"rider_lb":body,"tack_lb":fitted,"animal_cargo_lb":animal_cargo,"human_cargo_lb":human_cargo,"animal_total_lb":body+fitted+animal_cargo}
## Animals slow past 85% of their load. Walkers slow past 80% of their packs: a loaded walker
## still out-walks an ox team (foot-packers passed the trains), but an overfull pack drags.
static func speed_factor(plan_: Dictionary,load_: Dictionary) -> float:
	var ratio: float=maxf(float(load_.ratio),float(load_.human_ratio))
	return clampf(1.0-maxf(0,ratio-(0.85 if plan_.mode!="walking" else 0.8))*(0.6 if plan_.mode!="walking" else 0.5),0.25,1.0)

static func mounted(plan_: Dictionary) -> bool:return plan_.mode in ["mounted","doubled"]
static func label(plan_: Dictionary) -> String:
	return {"mounted":"MOUNTED","doubled":"DOUBLED UP","packing":"PACK TRAIN / ON FOOT","walking":"ON FOOT / PACKS","wagon":"WAGON"}[plan_.mode]
static func describe(plan_: Dictionary) -> String:
	var parts: Array[String]=[]
	if plan_.saddled>0:parts.append("%d led with saddle cargo" % plan_.saddled if plan_.get("leading",false) else "%d under saddle" % plan_.saddled)
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
	var strain: int=workload+base_strain+forage+pace+ceili(maxf(0,load_ratio-1.0)*float(rules.overload_wear))
	if plan_.get("leading",false) and plan_.get("loads",[]).any(func(row):return row.improvised) and load_ratio>float(rules.light_work_load):strain+=int(rules.improvised_wear)
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
	var kind: String=str(game.provisions.load_profile(game.state).worst_kind)
	if kind not in ANIMALS or count(game.state,kind)==0:kind="horses" if horses>0 else "mules"
	game.state[kind]=int(game.state[kind])-1
	game.state["horse_health"]=int(rules.breakdown_condition)
	var name: String="horse" if kind=="horses" else "mule"
	game.journal.append("Day %d · A %s gave out under its load and had to be left on the road." % [game.state.day,name])
	game.health_events.append("A worn-out %s gave out and was left behind. Rest the animals or lighten their loads." % name)
	game.supply_history.append({"day":int(game.state.day),"event":"animal_breakdown","changes":{kind:-1}})

static func loose_tack(rules: Dictionary,inventory: Dictionary) -> Dictionary:
	var p: Dictionary=plan(rules,inventory)
	return {"saddles":maxi(0,count(inventory,"saddles")-int(p.saddled)),"pack_saddles":maxi(0,count(inventory,"pack_saddles")-int(p.pack_horses)-int(p.pack_mules)),"saddlebags":maxi(0,count(inventory,"saddlebags")-int(p.bags))}
