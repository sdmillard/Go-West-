extends RefCounted
## The remains ledger: one entry per dead person the party could reach, kept in the crime record.
## A body lies where its person died, rides in the wagon, or rests in a grave. Nothing here grants food.
const STATES=["lying","carried","buried","lost"]
const COMMANDS=["bury","carry","set_down","search","disturb","back"]
const INDIFFERENT=["Ruthless","Self-serving","Opportunistic"]

static func load_rules(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("note") is String:return null
	for key in ["body_lb","stranger_goods_cents"]:
		if not whole(value.get(key),1,100000):return null
	for key in ["bury_days","disturb_days"]:
		if not whole(value.get(key),0,3):return null
	if not whole(value.get("carry_limit"),1,4) or not whole(value.get("disturb_close"),-12,0) or not whole(value.get("disturb_other"),-12,0):return null
	return value.duplicate(true)

static func whole(value: Variant,low: int,high: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value) and value>=low and value<=high

## Adds every death not yet in the ledger, where the party is now. With lost, the place is unknown and the body cannot be reached.
static func sync(game,lost: bool=false) -> void:
	var crime=game.crime
	if not crime.record.has("remains"):return
	var known: Array=crime.record.remains.map(func(entry):return entry.person)
	for member in game.party_health.members:
		var uid: String=crime.person_id(int(game.state.seed),int(member.id))
		if member.alive or uid in known:continue
		add(game,uid,member.name,member.cause,int(member.death_day),0,lost)
	for uid in crime.record.actors:
		var actor: Dictionary=crime.record.actors[uid]
		if actor.health>0 or uid in known:continue
		add(game,uid,"the %s %s" % [actor.role,crime.where(game,actor.place)],"shot by your party",int(game.state.day),int(crime.remains_rules.stranger_goods_cents),lost)

static func add(game,uid: String,name: String,cause: String,day: int,goods: int,lost: bool) -> void:
	var entries: Array=game.crime.record.remains
	entries.append({"id":entries.size()+1,"person":uid,"name":name,"cause":cause,"day":day,"mile":int(game.state.miles),"state":"lost" if lost else "lying","goods_cents":goods,"disturbed":false})

static func entry(game,id: int) -> Dictionary:
	var entries: Array=game.crime.record.remains
	return entries[id-1] if id>=1 and id<=entries.size() else {}

## Survivors of a trading party or post keep their own dead; a body in the wagon is always within reach.
static func accessible(game,item: Dictionary) -> bool:
	if item.state=="carried":return true
	if item.state not in ["lying","buried"] or int(item.mile)!=int(game.state.miles):return false
	if not game.crime.record.actors.has(item.person):return true
	return game.crime.living_staff(game.crime.record.actors[item.person].place).is_empty()

static func here(game) -> Array:
	return game.crime.record.get("remains",[]).filter(func(item):return accessible(game,item))

static func carried(game) -> int:
	return game.crime.record.get("remains",[]).filter(func(item):return item.state=="carried").size()

static func room(game) -> bool:
	var rules: Dictionary=game.crime.remains_rules
	return carried(game)<int(rules.carry_limit) and game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)>=float(rules.body_lb)

static func option(label: String,command: String,id: int) -> Dictionary:
	return {"label":label,"remains_command":command,"remains_id":id,"effects":{},"result":""}

## Pure: describes each body within reach and offers what can be done with it.
static func menu(game) -> Dictionary:
	var rules: Dictionary=game.crime.remains_rules
	var lines: Array=[]
	var choices: Array=[]
	for item in here(game):
		var id: int=int(item.id)
		var name: String=item.name
		lines.append("%s, dead of %s on day %d: %s." % [name[0].to_upper()+name.substr(1),item.cause,item.day,{"lying":"lying here","carried":"in the wagon","buried":"buried here"}[item.state]+(" (the grave was disturbed)" if item.disturbed else "")])
		var days: String="%d day" % int(rules.bury_days) if int(rules.bury_days)==1 else "%d days" % int(rules.bury_days)
		if item.state in ["lying","carried"]:choices.append(option("Bury %s here · %s" % [name,days],"bury",id))
		if item.state=="lying":choices.append(option("Carry %s in the wagon · %d lb" % [name,int(rules.body_lb)],"carry",id))
		if item.state=="carried":choices.append(option("Set %s down here" % name,"set_down",id))
		if item.state in ["lying","carried"] and int(item.goods_cents)>0:choices.append(option("Search %s's belongings" % name,"search",id))
		if item.state=="buried":choices.append(option("Dig up %s's grave · %d day(s)" % [name,int(rules.disturb_days)],"disturb",id))
	choices.append(option("Back","back",0))
	return {"id":"remains","remains_menu":true,"service_menu":true,"title":"The dead","text":"\n".join(lines) if not lines.is_empty() else "Nobody's remains are within reach.","choices":choices}

static func can_choose(game,command: String,id: int) -> bool:
	if command=="back":return true
	var item:=entry(game,id)
	if item.is_empty() or not accessible(game,item) or game.state.status!="traveling":return false
	match command:
		"bury":return item.state in ["lying","carried"]
		"carry":return item.state=="lying" and room(game)
		"set_down":return item.state=="carried"
		"search":return item.state in ["lying","carried"] and int(item.goods_cents)>0
		"disturb":return item.state=="buried"
	return false

static func choose(game,index: int) -> bool:
	var choice: Dictionary=game.pending.choices[index]
	var command: String=choice.remains_command
	var id: int=int(choice.remains_id)
	if not can_choose(game,command,id):return false
	if command=="back":
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		return true
	var rules: Dictionary=game.crime.remains_rules
	var item:=entry(game,id)
	var day: int=int(game.state.day)
	var days: int=0
	if command=="bury":
		if item.state=="carried":game.state.remains_lb=int(game.state.get("remains_lb",0))-int(rules.body_lb)
		item.state="buried"
		item.mile=int(game.state.miles)
		game.journal.append("Day %d · Buried %s at mile %d." % [day,item.name,item.mile])
		days=int(rules.bury_days)
	elif command=="carry":
		item.state="carried"
		game.state["remains_lb"]=int(game.state.get("remains_lb",0))+int(rules.body_lb)
		game.journal.append("Day %d · Wrapped %s and loaded the body into the wagon (%d lb)." % [day,item.name,int(rules.body_lb)])
	elif command=="set_down":
		item.state="lying"
		item.mile=int(game.state.miles)
		game.state.remains_lb=int(game.state.remains_lb)-int(rules.body_lb)
		game.journal.append("Day %d · Set %s's body down at mile %d." % [day,item.name,item.mile])
	elif command=="search":
		var cents: int=int(item.goods_cents)
		item.goods_cents=0
		game._apply({"money":cents/100.0})
		game.journal.append("Day %d · Took $%.2f from %s's belongings." % [day,cents/100.0,item.name])
	elif command=="disturb":
		item.state="lying"
		item.disturbed=true
		game.journal.append("Day %d · Dug up %s's grave." % [day,item.name])
		react_to_disturbance(game,item)
		days=int(rules.disturb_days)
	if days>0:game._apply({"days":days})
	if game.state.status!="traveling":
		game.pending={}
		game.service_return={}
		return true
	game.pending=menu(game)
	return true

## Everyone with the wagon sees a grave opened. Those close to the dead take it as a grievous wrong; the callous shrug.
static func react_to_disturbance(game,item: Dictionary) -> void:
	var crime=game.crime
	var rules: Dictionary=crime.remains_rules
	var slot: int=-1
	if crime.record.people.has(item.person):slot=int(crime.record.people[item.person].slot)
	for profile in game.characters.profiles:
		var other: int=int(profile.id)
		if other==0 or other==slot or not game.party_health.is_active(game.party_health.members[other]):continue
		var close: bool=slot>0 and crime.bond(other,slot) in crime.CLOSE
		if close:game.characters.remember(game,profile,"remains_disturbed",int(rules.disturb_close),"You dug up %s's grave." % item.name,true,0,0,int(item.id))
		elif profile.traits[1] not in INDIFFERENT and int(rules.disturb_other)<0:game.characters.remember(game,profile,"remains_disturbed",int(rules.disturb_other),"You dug up %s's grave." % item.name,false,0,0,int(item.id))

static func valid(r: Dictionary,game) -> bool:
	var entries: Variant=r.get("remains")
	if not entries is Array or entries.size()>200:return false
	var seen: Array=[]
	var carrying:=0
	var day: int=int(game.state.day)
	for index in range(entries.size()):
		var item: Variant=entries[index]
		if not item is Dictionary or item.size()!=9 or item.get("id")!=index+1 or not item.get("person") is String or item.person in seen:return false
		seen.append(item.person)
		if not item.get("name") is String or item.name.is_empty() or item.name.length()>120 or not item.get("cause") is String or item.cause.length()>120:return false
		if not whole(item.get("day"),0,day) or not whole(item.get("mile"),0,int(game.state.miles)) or item.get("state") not in STATES or not item.get("disturbed") is bool:return false
		if item.disturbed and item.state=="lost":return false
		# Only the dead have remains: a party member who died, or a stranger with no health left.
		if r.people.has(item.person):
			var member: Dictionary=game.party_health.members[int(r.people[item.person].slot)]
			if member.alive or int(member.death_day)!=int(item.day) or item.name!=member.name or item.cause!=member.cause or item.goods_cents!=0:return false
		elif not r.actors.has(item.person) or r.actors[item.person].health!=0 or not whole(item.get("goods_cents"),0,int(game.crime.remains_rules.stranger_goods_cents)):return false
		if item.state=="carried":carrying+=1
	if carrying>int(game.crime.remains_rules.carry_limit):return false
	var weight: Variant=game.state.get("remains_lb",0)
	return whole(weight,0,100000) and int(weight)==carrying*int(game.crime.remains_rules.body_lb)
