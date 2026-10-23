extends RefCounted
## Pair feelings are separate from trust in the leader. Only the four adult companions are paired.
const START_KINDS = ["none","family","friend","partner","rival"]
var rules: Dictionary = {}
var error := ""
var pairs: Array = []
var last_day := 0
var romance := true

func _init() -> void:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/social_rules.json"))
	if valid_rules(value):rules=value
	else:error="Invalid social rules"

func valid_rules(value: Variant) -> bool:
	if not value is Dictionary or not whole(value.get("interval_days"),1,30) or not value.get("starting_affinity") is Dictionary:return false
	for kind in START_KINDS:
		if not whole(value.starting_affinity.get(kind),-100,100):return false
	for key in ["friend_threshold","rival_threshold","romance_threshold","separation_threshold","hostility_departure"]:
		if not whole(value.get(key),-100,100):return false
	if value.rival_threshold>=0 or value.friend_threshold<=0 or value.romance_threshold<value.friend_threshold or value.separation_threshold>=0:return false
	for key in ["matching_gain","opposed_loss","hunger_loss"]:
		if not whole(value.get(key),0,20):return false
	if not (value.get("romance_chance") is int or value.get("romance_chance") is float) or not is_finite(value.romance_chance) or value.romance_chance<0 or value.romance_chance>1:return false
	if not value.get("opposed_values") is Array:return false
	for pair in value.opposed_values:
		if not pair is Array or pair.size()!=2 or not pair[0] is String or not pair[1] is String or pair[0]==pair[1]:return false
	return true

static func valid_bonds(value: Variant) -> bool:
	if not value is Array or value.size()>6:return false
	var seen := []
	var partnered := []
	for item in value:
		if not item is Dictionary or item.size()!=3 or not whole(item.get("a"),1,4) or not whole(item.get("b"),int(item.a)+1,4) or item.get("kind") not in START_KINDS.slice(1):return false
		var key := "%d:%d" % [item.a,item.b]
		if key in seen:return false
		seen.append(key)
		if item.kind=="partner":
			if int(item.a) in partnered or int(item.b) in partnered:return false
			partnered.append_array([int(item.a),int(item.b)])
	return true

static func valid_commitments(bonds: Array, profiles: Array) -> bool:
	for bond in bonds:
		if bond.kind=="partner" and (profiles[int(bond.a)].relationship=="partner" or profiles[int(bond.b)].relationship=="partner"):return false
	return true

static func whole(value: Variant, lo: int, hi: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value) and value>=lo and value<=hi

func start(game, allow_romance: bool = true) -> void:
	pairs=[]
	last_day=int(game.state.day)
	romance=allow_romance
	for a in range(1,4):
		for b in range(a+1,5):
			var kind: String=game.crime.bond(a,b)
			pairs.append({"a":a,"b":b,"affinity":int(rules.starting_affinity.get(kind,0)),"history":[]})

func snapshot() -> Dictionary:
	return {"pairs":pairs.duplicate(true),"last_day":last_day,"romance":romance}

func valid(value: Variant, day: int, count: int=5) -> bool:
	if not value is Dictionary or value.size()!=3 or not value.get("romance") is bool or not whole(value.get("last_day"),0,day) or not value.get("pairs") is Array or (value.pairs.size()<6 or value.pairs.size()>count*(count-1)/2):return false
	var seen := []
	for pair in value.pairs:
		if not pair is Dictionary or pair.size()!=4 or not whole(pair.get("a"),1,count-1) or not whole(pair.get("b"),int(pair.a)+1,count-1) or not whole(pair.get("affinity"),-100,100) or not pair.get("history") is Array or pair.history.size()>8:return false
		var key := "%d:%d" % [pair.a,pair.b]
		if key in seen:return false
		seen.append(key)
		var previous := 0
		for memory in pair.history:
			if not memory is Dictionary or memory.size()!=2 or not whole(memory.get("day"),previous,day) or not memory.get("text") is String or memory.text.length()>240:return false
			previous=int(memory.day)
	return true

func restore(value: Dictionary) -> void:
	pairs=value.pairs.duplicate(true)
	last_day=int(value.last_day)
	romance=value.romance

func active(game, id: int) -> bool:
	return game.party_health.is_active(game.party_health.members[id])

func pair_for(a: int, b: int) -> Dictionary:
	for pair in pairs:
		if int(pair.a)==mini(a,b) and int(pair.b)==maxi(a,b):return pair
	return {}

func partner(game, id: int) -> int:
	if game.characters.profiles[id].relationship=="partner" and active(game,0):return 0
	for bond in game.crime.record.bonds:
		if bond.kind=="partner" and id in [int(bond.a),int(bond.b)]:
			var other: int=int(bond.b) if int(bond.a)==id else int(bond.a)
			if active(game,other):return other
	return -1

func family_connected(game, a: int, b: int) -> bool:
	var seen := [a]
	var kin := ["family","sibling","cousin","parent","adult_child"]
	if game.characters.profiles[a].relationship in kin:
		seen.append(0)
		for slot in range(1,game.characters.profiles.size()):
			if game.characters.profiles[slot].relationship in kin:seen.append(slot)
	for _step in range(4):
		for bond in game.crime.record.bonds:
			if bond.kind!="family":continue
			if int(bond.a) in seen and int(bond.b) not in seen:seen.append(int(bond.b))
			if int(bond.b) in seen and int(bond.a) not in seen:seen.append(int(bond.a))
	return b in seen

func change_kind(game, pair: Dictionary, kind: String, text: String) -> void:
	game.crime.record.bonds=game.crime.record.bonds.filter(func(bond):return not (int(bond.a)==int(pair.a) and int(bond.b)==int(pair.b)))
	if kind!="none":game.crime.record.bonds.append({"a":int(pair.a),"b":int(pair.b),"kind":kind})
	record_change(game,pair,text)

func record_change(game, pair: Dictionary, text: String) -> void:
	pair.history.append({"day":int(game.state.day),"text":text})
	if pair.history.size()>8:pair.history.pop_front()
	game.journal.append("Day %d · %s" % [game.state.day,text])
	game.health_events.append(text)

func evolve(game, pair: Dictionary, roll: float) -> void:
	var a: int=int(pair.a)
	var b: int=int(pair.b)
	var kind: String=game.crime.bond(a,b)
	var names: String=game.party_health.members[a].name+" and "+game.party_health.members[b].name
	if kind=="family":return # Blood/kinship is not erased by a quarrel.
	if kind=="partner":
		if pair.affinity<=int(rules.separation_threshold):change_kind(game,pair,"rival",names+" have separated after repeated conflict.")
		return
	if pair.affinity<=int(rules.rival_threshold) and kind!="rival":
		change_kind(game,pair,"rival",names+" have become rivals.")
	elif pair.affinity>=int(rules.friend_threshold) and kind not in ["friend","partner"]:
		change_kind(game,pair,"friend",names+" have become friends.")
	elif kind=="friend" and pair.affinity<10:
		change_kind(game,pair,"none",names+" have drifted apart.")
	elif kind=="rival" and pair.affinity> -10:
		change_kind(game,pair,"none",names+" have set aside their rivalry.")
	if romance and pair.affinity>=int(rules.romance_threshold) and partner(game,a)<0 and partner(game,b)<0 and not family_connected(game,a,b) and roll<float(rules.romance_chance):
		clear_inactive_partners(game,a)
		clear_inactive_partners(game,b)
		change_kind(game,pair,"partner",names+" have fallen in love on the trail.")

func clear_inactive_partners(game, id: int) -> void:
	for bond in game.crime.record.bonds.duplicate():
		if bond.kind!="partner" or id not in [int(bond.a),int(bond.b)]:continue
		var other: int=int(bond.b) if int(bond.a)==id else int(bond.a)
		if not active(game,other):
			game.crime.record.bonds.erase(bond)
			record_change(game,pair_for(id,other),game.party_health.members[id].name+" remembers their former partnership with "+game.party_health.members[other].name+".")

func tick(game, resting: bool, fed: bool) -> void:
	if pairs.is_empty():return
	if int(game.state.day)-last_day<int(rules.interval_days):return
	last_day=int(game.state.day)
	# Date-keyed stream avoids changing illness, travel, hunting or crime random streams.
	var random := RandomNumberGenerator.new()
	random.seed=int(game.state.seed) ^ (last_day * 7919) ^ 0x534f4349
	for pair in pairs:
		if not active(game,int(pair.a)) or not active(game,int(pair.b)):continue
		var left: Dictionary=game.characters.profiles[int(pair.a)]
		var right: Dictionary=game.characters.profiles[int(pair.b)]
		var delta := random.randi_range(-2,2)
		var reason := "camp conversations"
		if left.traits[1]==right.traits[1]:delta+=int(rules.matching_gain)
		for opposed in rules.opposed_values:
			if left.traits[1] in opposed and right.traits[1] in opposed and left.traits[1]!=right.traits[1]:delta-=int(rules.opposed_loss);reason="clashing values"
		if not fed:delta-=int(rules.hunger_loss);reason="shared hardship"
		elif resting and game.characters.has_sick(game):delta+=1;reason+="; support during illness"
		pair.affinity=clampi(int(pair.affinity)+delta,-100,100)
		var text: String="%s and %s: %s (%+d closeness)." % [game.party_health.members[int(pair.a)].name,game.party_health.members[int(pair.b)].name,reason,delta]
		pair.history.append({"day":last_day,"text":text})
		if pair.history.size()>8:pair.history.pop_front()
		evolve(game,pair,random.randf())

func departure_group(game, candidates: Array) -> Array:
	var result: Array=candidates.duplicate()
	for id in candidates:
		var other := partner(game,int(id))
		if other>0 and other not in result:result.append(other)
	result.sort()
	return result

func exit_reason(game, id: int) -> String:
	for pair in pairs:
		if id not in [int(pair.a),int(pair.b)] or pair.affinity>int(rules.hostility_departure):continue
		var other: int=int(pair.b) if int(pair.a)==id else int(pair.a)
		if active(game,other):return "hostile companion"
	return ""

func description(game, id: int) -> String:
	var lines: Array[String]=["RELATIONSHIPS WITH COMPANIONS"]
	for pair in pairs:
		if id not in [int(pair.a),int(pair.b)]:continue
		var other: int=int(pair.b) if int(pair.a)==id else int(pair.a)
		var feeling: String="close" if pair.affinity>=60 else ("friendly" if pair.affinity>=20 else ("hostile" if pair.affinity<=-60 else ("strained" if pair.affinity<=-20 else "neutral")))
		var kind: String=game.crime.bond(id,other)
		lines.append("%s: %s; %s (%d)." % [game.party_health.members[other].name,kind if not kind.is_empty() else "fellow travelers",feeling,int(pair.affinity)])
		if not pair.history.is_empty():lines.append("  "+pair.history.back().text)
	return "\n".join(lines)


func add_member(game, id: int) -> void:
	for member in game.party_health.members:
		var other: int=int(member.id)
		if other==0 or other==id or not active(game,other):continue
		pairs.append({"a":mini(other,id),"b":maxi(other,id),"affinity":0,"history":[]})
