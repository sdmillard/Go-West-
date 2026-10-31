extends RefCounted
## The party's arms, counted in game.state like other goods. Every traveler brings a rifle and a belt knife from home;
## the outfitter sells more. In a fight each traveler takes one firearm and one blade from what the party holds.
## Authored game values in data/weapons.json, not measured historical data.
const KEYS=["rifles","shotguns","pistols","revolvers","knives","hatchets"]
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func whole(v: Variant,low: int,high: int) -> bool:return number(v) and v==floor(v) and v>=low and v<=high
static func valid_rules(v: Variant) -> bool:
	if not v is Dictionary or not v.get("note") is String or not v.get("firearms") is Dictionary or not v.get("blades") is Dictionary or not v.get("fists") is Dictionary:return false
	if not v.get("weights_lb") is Dictionary or v.weights_lb.keys().size()!=KEYS.size() or not KEYS.all(func(key):return number(v.weights_lb.get(key)) and v.weights_lb[key]>0):return false
	if not v.get("home_kit") is Dictionary or not v.home_kit.keys().all(func(key):return key in KEYS and whole(v.home_kit[key],0,2)):return false
	if not v.get("loadout_order") is Array or v.loadout_order.size()!=v.firearms.size() or not v.loadout_order.all(func(key):return v.firearms.has(key)):return false
	if not v.get("blade_order") is Array or v.blade_order.size()!=v.blades.size() or not v.blade_order.all(func(key):return v.blades.has(key)):return false
	for key in v.firearms:
		var gun: Variant=v.firearms[key]
		if key not in KEYS or not gun is Dictionary or not gun.get("label") is String or not gun.get("long_gun") is bool:return false
		for field in ["capacity","max_range","optimal_range","snap_cost","called_cost","reload_cost"]:
			if not whole(gun.get(field),1,12):return false
		if gun.optimal_range>gun.max_range:return false
		for field in ["range_falloff","hit_mod","damage_factor"]:
			if not number(gun.get(field)) or absf(gun[field])>2:return false
	for blade in v.blades.values()+[v.fists]:
		if not blade is Dictionary or not blade.get("label") is String or not number(blade.get("hit")) or blade.hit<0 or blade.hit>1 or not whole(blade.get("damage_min"),1,100) or not whole(blade.get("damage_max"),int(blade.damage_min),100) or not whole(blade.get("cost"),1,8):return false
	return v.blades.keys().all(func(key):return key in KEYS)
## Arms counts are optional in a saved state; journeys from before arms carry none.
static func valid_state(state: Dictionary) -> bool:
	if state.has("arms_home") and not whole(state.arms_home,0,100):return false
	return KEYS.all(func(key):return not state.has(key) or whole(state[key],0,10000)) and (KEYS.all(func(key):return not state.has(key)) or state.has("arms_home"))
static func count(state: Dictionary,key: String) -> int:return maxi(0,int(state.get(key,0)))
## Journeys saved before arms were counted: every traveler still has the rifle and knife they set out with.
static func settle(state: Dictionary) -> void:
	if not state.has("arms_home") and state.get("party") is Array:home_kit(state,state.party.size())
## Each traveler's own rifle and knife. "arms_home" records how many travelers brought theirs, so their weight stays in personal gear.
static func home_kit(state: Dictionary,travelers: int) -> void:
	for key in data.home_kit:state[key]=maxi(0,int(state.get(key,0)))+int(data.home_kit[key])*travelers
	state["arms_home"]=travelers
static func firearms(state: Dictionary) -> int:
	var total:=0
	for key in data.firearms:total+=count(state,key)
	return total
static func long_guns(state: Dictionary) -> int:
	var total:=0
	for key in data.firearms:
		if data.firearms[key].long_gun:total+=count(state,key)
	return total
## Arms beyond the travelers' own add to the load; a dead traveler's rifle is carried by the others.
static func extra_weight(inventory: Dictionary) -> float:
	var home: int=int(inventory.get("arms_home",0))
	var pounds:=0.0
	for key in KEYS:pounds+=maxi(0,count(inventory,key)-int(data.home_kit.get(key,0))*home)*float(data.weights_lb[key])
	return pounds
## One firearm and one blade per fighter, in squad order (the leader first). Scarcer, closer-range arms go first,
## so a bought Colt or shotgun is always in someone's hands; anyone left over fights with a blade or bare hands.
static func loadout(state: Dictionary,fighters: int) -> Array:
	var guns: Array=[]
	for key in data.loadout_order:
		for i in range(count(state,key)):guns.append(key)
	var blades: Array=[]
	for key in data.blade_order:
		for i in range(count(state,key)):blades.append(key)
	var result: Array=[]
	for i in range(fighters):result.append({"weapon":guns[i] if i<guns.size() else "","blade":blades[i] if i<blades.size() else ""})
	return result
## Fill in each squad member's arms on a tactical config. Prisoners (unarmed, by squad id) fight bare-handed
## and take nothing from the party's stock.
static func equip(config: Dictionary,state: Dictionary,unarmed: Array=[]) -> Dictionary:
	var armed: Array=config.get("squad",[]).filter(func(member):return str(member.get("id","")) not in unarmed.map(func(id):return str(id)))
	var kit: Array=loadout(state,armed.size())
	for i in range(kit.size()):
		armed[i]["weapon"]=kit[i].weapon
		armed[i]["blade"]=kit[i].blade
	for member in config.get("squad",[]):
		if not member.has("weapon"):
			member["weapon"]=""
			member["blade"]=""
	return config
const NAMES={"rifles":["rifle","rifles"],"shotguns":["shotgun","shotguns"],"pistols":["pistol","pistols"],"revolvers":["Colt revolver","Colt revolvers"],"knives":["knife","knives"],"hatchets":["hatchet","hatchets"]}
## "1 Colt revolver, 2 knives", in KEYS order.
static func describe(arms: Dictionary) -> String:
	return ", ".join(KEYS.filter(func(key):return int(arms.get(key,0))>0).map(func(key):return "%d %s" % [int(arms[key]),NAMES[key][0 if int(arms[key])==1 else 1]]))
static func label(key: String) -> String:
	if data.firearms.has(key):return str(data.firearms[key].label)
	if data.blades.has(key):return str(data.blades[key].label)
	return ""
