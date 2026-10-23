extends RefCounted
## The remains ledger: one entry per dead person the party could reach, kept in the crime record.
## A body lies where its person died, rides in the wagon, or rests in a grave. Death grants no food;
## butchering is a separate decision, and its meat stays a separate, provenance-tracked batch that
## the ordinary ration never touches. Each eater is chosen by name: openly, or without being told.
const STATES=["lying","carried","buried","lost","processed"]
const COMMANDS=["bury","carry","set_down","search","disturb","butcher_open","butcher_secret","dry","salt","eat","offer","deceive","stop","back"]
const MEALS=["informed","deceived"]
const MEAL_COMMANDS=["eat","offer","deceive","stop"]
const INDIFFERENT=["Ruthless","Self-serving","Opportunistic"]

static func load_rules(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("note") is String:return null
	for key in ["body_lb","stranger_goods_cents"]:
		if not whole(value.get(key),1,100000):return null
	for key in ["bury_days","disturb_days"]:
		if not whole(value.get(key),0,3):return null
	if not whole(value.get("carry_limit"),1,4) or not whole(value.get("disturb_close"),-12,0) or not whole(value.get("disturb_other"),-12,0):return null
	if not whole(value.get("butcher_days"),1,3) or not whole(value.get("yield_lb"),1,200):return null
	for key in ["secret_notice","deceit_notice"]:
		if not (value.get(key) is int or value.get(key) is float) or value[key]<0 or value[key]>1:return null
	return value.duplicate(true)

static func whole(value: Variant,low: int,high: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value) and value>=low and value<=high

## Adds every death not yet in the ledger, where the party is now. With lost, the place is unknown and the body cannot be reached.
static func sync(game,lost: bool=false) -> void:
	var crime=game.crime
	if not crime.record.has("remains"):return
	# Death or departure after the morning meal must not leave a standing order
	# attached to an inactive traveler until tomorrow (including terminal saves).
	for key in crime.record.meals.keys():
		if not game.party_health.is_active(game.party_health.members[int(key)]):crime.record.meals.erase(key)
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
	entries.append({"id":entries.size()+1,"person":uid,"name":name,"cause":cause,"day":day,"mile":int(game.state.miles),"state":"lost" if lost else "lying","goods_cents":goods,"disturbed":false,"witnesses":[]})

static func entry(game,id: int) -> Dictionary:
	var entries: Array=game.crime.record.remains
	return entries[id-1] if id>=1 and id<=entries.size() else {}

## Survivors of a trading party or post keep their own dead; a body in the wagon is always within reach.
static func accessible(game,item: Dictionary) -> bool:
	if item.state=="carried":return true
	if item.state not in ["lying","buried"] or int(item.mile)!=int(game.state.miles):return false
	if not game.crime.record.actors.has(item.person):return true
	return game.crime.living_staff(game.crime.record.actors[item.person].place).is_empty()

static func within_reach(game) -> bool:return not here(game).is_empty() or not food(game).is_empty()
static func here(game) -> Array:
	return game.crime.record.get("remains",[]).filter(func(item):return accessible(game,item))

static func food(game) -> Array:return game.crime.record.get("human_food",[])
static func batch(game,id: int) -> Dictionary:
	for item in food(game):
		if int(item.remains)==id:return item
	return {}
static func human_pounds(game) -> int:
	var total:=0
	for item in food(game):total+=int(item.pounds)
	return total
## Carried bodies plus human-derived food, at its physical weight: dried meat weighs less than the meals it holds.
static func weight(game) -> int:return weight_of(game.crime.record,game)
static func reweigh(game) -> void:
	var pounds:=weight(game)
	if pounds>0 or game.state.has("remains_lb"):game.state["remains_lb"]=pounds

static func carried(game) -> int:
	return game.crime.record.get("remains",[]).filter(func(item):return item.state=="carried").size()

static func room(game) -> bool:
	var rules: Dictionary=game.crime.remains_rules
	return carried(game)<int(rules.carry_limit) and game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)>=float(rules.body_lb)

static func option(label: String,command: String,id: int,member: int=-1) -> Dictionary:
	var result: Dictionary={"label":label,"remains_command":command,"remains_id":id,"effects":{},"result":""}
	if member>=0:result["member"]=member
	return result
static func name_of(game,slot: int) -> String:return game.party_health.members[slot].name
static func knows(game,slot: int) -> bool:return food(game).any(func(item):return slot in item.known)
## Willing to eat human remains knowingly: no boundary against it, or the Cannibal special.
static func willing(game,slot: int) -> bool:return slot==0 or game.characters.response(slot,"cannibalism") not in ["forbidden","reluctant"]

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
		if item.state in ["lying","carried"]:
			choices.append(option("Butcher %s openly · %d day(s), about %d lb" % [name,int(rules.butcher_days),int(rules.yield_lb)],"butcher_open",id))
			choices.append(option("Butcher %s in secret · %d day(s), about %d lb" % [name,int(rules.butcher_days),int(rules.yield_lb)],"butcher_secret",id))
	for item in food(game):
		var source: String=entry(game,int(item.remains)).name
		lines.append("Meat from %s: %d ration-lb, %s, keeps until day %d. Knows where it came from: %s." % [source,item.pounds,"dried" if item.preserved else "fresh",int(item.expires)-1,", ".join(item.known.map(func(slot):return name_of(game,slot)))])
		if not item.preserved:
			choices.append(option("Dry the meat from %s · 1 day" % source,"dry",int(item.remains)))
			choices.append(option("Salt and dry the meat from %s · 1 day, %d lb salt" % [source,salt_needed(game,item)],"salt",int(item.remains)))
	if not food(game).is_empty():
		var meals: Dictionary=game.crime.record.meals
		var eating: Array=[]
		for key in meals:eating.append("%s (%s)" % [name_of(game,int(key)),"knows" if meals[key]=="informed" else "not told"])
		lines.append("Eating it each day instead of ordinary rations: %s. Nobody else is served it." % (", ".join(eating) if not eating.is_empty() else "nobody"))
		for member in game.party_health.members:
			var slot: int=int(member.id)
			if not game.party_health.is_active(member):continue
			if meals.has(str(slot)):choices.append(option("Stop serving %s human meat" % member.name,"stop",0,slot))
			elif slot==0:choices.append(option("Eat it yourself","eat",0,0))
			else:
				choices.append(option("Offer it to %s openly%s" % [member.name,"" if willing(game,slot) else " (will refuse)"],"offer",0,slot))
				if not knows(game,slot):choices.append(option("Serve it to %s without telling them" % member.name,"deceive",0,slot))
	choices.append(option("Back","back",0))
	return {"id":"remains","remains_menu":true,"service_menu":true,"title":"The dead","text":"\n".join(lines) if not lines.is_empty() else "Nobody's remains are within reach.","choices":choices}

static func salt_needed(game,item: Dictionary) -> int:return ceili(int(item.pounds)*game.provisions.mass_ratio(item)*float(game.provisions.data.preservation.salt_per_food_lb))

static func can_choose(game,command: String,id: int,member: int=-1) -> bool:
	if command=="back":return true
	if game.state.status!="traveling":return false
	if command in MEAL_COMMANDS:
		if food(game).is_empty() or member<0 or member>=game.party_health.members.size() or not game.party_health.is_active(game.party_health.members[member]):return false
		var serving: bool=game.crime.record.meals.has(str(member))
		match command:
			"stop":return serving
			"eat":return member==0 and not serving
			"offer":return member>0 and not serving and willing(game,member)
			"deceive":return member>0 and not serving and not knows(game,member)
		return false
	if command in ["dry","salt"]:
		var meat:=batch(game,id)
		return not meat.is_empty() and not meat.preserved and (command=="dry" or int(game.state.salt)>=salt_needed(game,meat))
	var item:=entry(game,id)
	if item.is_empty() or not accessible(game,item) or game.state.status!="traveling":return false
	match command:
		"bury":return item.state in ["lying","carried"]
		"carry":return item.state=="lying" and room(game)
		"set_down":return item.state=="carried"
		"search":return item.state in ["lying","carried"] and int(item.goods_cents)>0
		"disturb":return item.state=="buried"
		"butcher_open","butcher_secret":return item.state in ["lying","carried"] and food(game).size()<200
	return false

static func choose(game,index: int) -> bool:
	var choice: Dictionary=game.pending.choices[index]
	var command: String=choice.remains_command
	var id: int=int(choice.remains_id)
	var member: int=int(choice.get("member",-1))
	if not can_choose(game,command,id,member):return false
	if command=="back":
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		return true
	var rules: Dictionary=game.crime.remains_rules
	var item:=entry(game,id)
	var day: int=int(game.state.day)
	var days: int=0
	if command in MEAL_COMMANDS:
		serve_choice(game,command,member)
	elif command in ["dry","salt"]:
		# Meals and spoilage come first, as with any meat; spoiled meat is never rescued.
		game._apply({"days":1})
		var meat:=batch(game,id)
		if game.state.status=="traveling" and not meat.is_empty():preserve(game,meat,command=="salt")
	elif command=="bury":
		item.state="buried"
		item.mile=int(game.state.miles)
		game.journal.append("Day %d · Buried %s at mile %d." % [day,item.name,item.mile])
		days=int(rules.bury_days)
	elif command=="carry":
		item.state="carried"
		game.journal.append("Day %d · Wrapped %s and loaded the body into the wagon (%d lb)." % [day,item.name,int(rules.body_lb)])
	elif command=="set_down":
		item.state="lying"
		item.mile=int(game.state.miles)
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
	elif command in ["butcher_open","butcher_secret"]:
		butcher(game,item,command=="butcher_secret")
		days=int(rules.butcher_days)
	reweigh(game)
	if days>0:game._apply({"days":days})
	if game.state.status!="traveling":
		game.pending={}
		game.service_return={}
		return true
	game.pending=menu(game)
	return true

## The body becomes one fresh batch, usable for today's meals. Openly, everyone with the wagon knows; in secret, each companion may still notice.
static func butcher(game,item: Dictionary,secret: bool) -> void:
	var rules: Dictionary=game.crime.remains_rules
	var day: int=int(game.state.day)
	item.state="processed"
	var meat: Dictionary={"remains":int(item.id),"pounds":game.provisions.meat_units(int(rules.yield_lb)),"mass_ratio":float(rules.yield_lb)/game.provisions.meat_units(int(rules.yield_lb)),"expires":day+1+int(game.provisions.data.fresh_days)+1,"preserved":false,"known":[0]}
	game.crime.record.human_food.append(meat)
	game.journal.append("Day %d · Butchered %s's remains%s: %d ration-lb of fresh meat, kept apart from the ordinary food." % [day,item.name," in secret" if secret else "",int(meat.pounds)])
	for member in game.party_health.members:
		var slot: int=int(member.id)
		if slot==0 or not game.party_health.is_active(member):continue
		if secret and game.crime.rng.randf()>=float(rules.secret_notice):continue
		if secret:game.journal.append("Day %d · %s saw what you were doing." % [day,member.name])
		learn(game,slot,meat)
	# Those already eating human meat knowingly are told about the new batch too.
	for key in game.crime.record.meals.keys():
		if game.crime.record.meals[key]=="informed":learn(game,int(key),meat)

## Someone learns where a batch came from. Their own boundary decides how they take it; harm to a loved one's body is its own wrong.
static func learn(game,slot: int,meat: Dictionary) -> void:
	if slot in meat.known:return
	meat.known.append(slot)
	meat.known.sort()
	if slot==0:return
	var body:=entry(game,int(meat.remains))
	if slot not in body.witnesses:
		body.witnesses.append(slot)
		body.witnesses.sort()
	# Someone who learns the truth is no longer being deceived.
	if game.crime.record.meals.get(str(slot),"")=="deceived":game.crime.record.meals.erase(str(slot))
	var item:=entry(game,int(meat.remains))
	var profile: Dictionary=game.characters.profiles[slot]
	var reaction: String=game.characters.response(slot,"cannibalism")
	if reaction!="neutral":game.characters.remember(game,profile,"action_cannibalism",-12 if reaction in ["forbidden","reluctant"] else (2 if reaction=="approved" else -2),"You butchered %s's remains for food. Response: %s." % [item.name,reaction],reaction in ["forbidden","reluctant"],0,0,int(item.id))
	var crime=game.crime
	if crime.record.people.has(item.person):
		var dead: int=int(crime.record.people[item.person].slot)
		if crime.bond(slot,dead) in crime.CLOSE:game.characters.remember(game,profile,"remains_disturbed",int(crime.remains_rules.disturb_close),"You butchered %s's body." % item.name,true,0,0,int(item.id))

static func preserve(game,meat: Dictionary,salted: bool) -> void:
	var rules: Dictionary=game.provisions.data.preservation
	var before: int=int(meat.pounds)
	var salt: int=salt_needed(game,meat) if salted else 0
	if int(game.state.salt)<salt:return
	game.state.salt-=salt
	meat.pounds=floori(before*float(rules.salted_retained_food if salted else rules.retained_food))
	meat.mass_ratio=game.provisions.mass_ratio(meat)*float(rules.dried_weight)
	meat.preserved=true
	meat.expires=int(game.state.day)+int(rules.salted_days if salted else rules.days)+1
	game.journal.append("Day %d · %s the meat from %s: %d ration-lb became %d; %d lb salt used. It is still human meat and stays apart." % [game.state.day,"Salted and dried" if salted else "Dried",entry(game,int(meat.remains)).name,before,meat.pounds,salt])
	if meat.pounds<=0:food(game).erase(meat)
	if food(game).is_empty():game.crime.record.meals.clear()

static func serve_choice(game,command: String,slot: int) -> void:
	var meals: Dictionary=game.crime.record.meals
	var day: int=int(game.state.day)
	var name: String=name_of(game,slot)
	if command=="stop":
		meals.erase(str(slot))
		game.journal.append("Day %d · Stopped serving human meat to %s." % [day,name])
		return
	if command in ["eat","offer"]:
		# Offering openly tells them where every batch came from, before they choose.
		for meat in food(game):learn(game,slot,meat)
		meals[str(slot)]="informed"
		game.journal.append("Day %d · %s" % [day,"You will eat the human meat yourself." if slot==0 else "%s agreed to eat the human meat, knowing what it is." % name])
	elif command=="deceive":
		meals[str(slot)]="deceived"
		game.journal.append("Day %d · You will serve human meat to %s without telling them." % [day,name])

## Called each day before ordinary meals: each chosen eater is fed from human meat while it lasts. Returns the ordinary food no longer needed.
static func serve(game) -> int:
	var record: Dictionary=game.crime.record
	if not record.has("meals") or record.meals.is_empty():return 0
	var ration: int=int(game.provisions.data.rations_lb[game.state.rations])
	var covered:=0
	var keys: Array=record.meals.keys()
	keys.sort()
	for key in keys:
		var slot: int=int(key)
		if not game.party_health.is_active(game.party_health.members[slot]) or human_pounds(game)<ration:
			record.meals.erase(key)
			continue
		var meals_from: Array=take(game,ration)
		covered+=ration
		if record.meals[key]=="deceived" and game.crime.rng.randf()<float(game.crime.remains_rules.deceit_notice):
			record.meals.erase(key)
			var profile: Dictionary=game.characters.profiles[slot]
			game.characters.remember(game,profile,"meal_deceived",-12,"You fed them human meat without telling them.",true,0,0,int(meals_from[0]))
			for meat in food(game):learn(game,slot,meat)
			var text: String="%s discovered that you have been feeding them human meat." % name_of(game,slot)
			game.journal.append("Day %d · %s" % [game.state.day,text])
			game.health_events.append(text)
	if food(game).is_empty():record.meals.clear()
	reweigh(game)
	return covered

## Takes the oldest meat first; returns which bodies it came from.
static func take(game,pounds: int) -> Array:
	var sources: Array=[]
	var batches: Array=food(game)
	batches.sort_custom(func(a,b):return a.expires<b.expires or (a.expires==b.expires and a.remains<b.remains))
	for meat in batches:
		if pounds<=0:break
		var used: int=mini(pounds,int(meat.pounds))
		meat.pounds-=used
		pounds-=used
		sources.append(int(meat.remains))
	game.crime.record.human_food=batches.filter(func(meat):return meat.pounds>0)
	return sources

static func spoil(game) -> void:
	var record: Dictionary=game.crime.record
	if not record.has("human_food"):return
	var day: int=int(game.state.day)
	for meat in record.human_food:
		if day>=int(meat.expires):game.journal.append("Day %d · Discarded %d ration-lb of spoiled meat from %s's remains." % [day,meat.pounds,entry(game,int(meat.remains)).name])
	record.human_food=record.human_food.filter(func(meat):return day<int(meat.expires))
	if record.human_food.is_empty():record.meals.clear()
	reweigh(game)

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
		if not item is Dictionary or item.size()!=10 or item.get("id")!=index+1 or not item.get("person") is String or item.person in seen:return false
		seen.append(item.person)
		if not item.get("name") is String or item.name.is_empty() or item.name.length()>120 or not item.get("cause") is String or item.cause.length()>120:return false
		if not whole(item.get("day"),0,day) or not whole(item.get("mile"),0,int(game.state.miles)) or item.get("state") not in STATES or not item.get("disturbed") is bool:return false
		if item.disturbed and item.state=="lost":return false
		# Companions who know this body was butchered; they remember it after the meat is gone.
		if not item.get("witnesses") is Array or (item.state!="processed" and not item.witnesses.is_empty()):return false
		var previous:=0
		for slot in item.witnesses:
			if not whole(slot,1,game.party_health.members.size()-1) or int(slot)<=previous:return false
			previous=int(slot)
		# Only the dead have remains: a party member who died, or a stranger with no health left.
		if r.people.has(item.person):
			var member: Dictionary=game.party_health.members[int(r.people[item.person].slot)]
			if member.alive or int(member.death_day)!=int(item.day) or item.name!=member.name or item.cause!=member.cause or item.goods_cents!=0:return false
		elif not r.actors.has(item.person) or r.actors[item.person].health!=0 or not whole(item.get("goods_cents"),0,int(game.crime.remains_rules.stranger_goods_cents)):return false
		if item.state=="carried":carrying+=1
	if carrying>int(game.crime.remains_rules.carry_limit):return false
	if not valid_food(r,game):return false
	var pounds: Variant=game.state.get("remains_lb",0)
	return whole(pounds,0,100000) and int(pounds)==weight_of(r,game)

static func weight_of(r: Dictionary,game) -> int:
	var pounds: int=r.remains.filter(func(item):return item.state=="carried").size()*int(game.crime.remains_rules.body_lb)
	for item in r.human_food:pounds+=ceili(int(item.pounds)*game.provisions.mass_ratio(item))
	return pounds

## One batch per butchered body, never more than it yielded; each eater either knows where every batch came from or knows of none.
static func valid_food(r: Dictionary,game) -> bool:
	var batches: Variant=r.get("human_food")
	var meals: Variant=r.get("meals")
	if not batches is Array or batches.size()>200 or not meals is Dictionary:return false
	var day: int=int(game.state.day)
	var rules: Dictionary=game.provisions.data.preservation
	var sources: Array=[]
	var members: Array=game.party_health.members
	for meat in batches:
		if not meat is Dictionary or meat.size() not in [5,6] or not whole(meat.get("remains"),1,r.remains.size()) or int(meat.remains) in sources or r.remains[int(meat.remains)-1].state!="processed":return false
		sources.append(int(meat.remains))
		if not whole(meat.get("pounds"),1,int(game.crime.remains_rules.yield_lb)) or not meat.get("preserved") is bool:return false
		if not game.provisions.valid_mass_ratio(meat):return false
		if int(meat.pounds)*game.provisions.mass_ratio(meat)>float(game.crime.remains_rules.yield_lb)+0.001:return false
		var longest: int=int(rules.salted_days) if meat.preserved else int(game.provisions.data.fresh_days)+1
		if not whole(meat.get("expires"),day+1,day+longest+1):return false
		if not meat.get("known") is Array or meat.known.is_empty() or meat.known[0]!=0:return false
		var witnesses: Array=r.remains[int(meat.remains)-1].witnesses
		if not meat.known.all(func(slot):return int(slot)==0 or witnesses.any(func(other):return int(other)==int(slot))):return false
		var previous:=-1
		for slot in meat.known:
			if not whole(slot,0,members.size()-1) or int(slot)<=previous:return false
			previous=int(slot)
	if not meals.is_empty() and batches.is_empty():return false
	for key in meals:
		if not key is String or not key.is_valid_int() or not whole(int(key),0,members.size()-1) or str(int(key))!=key or meals[key] not in MEALS:return false
		var slot: int=int(key)
		if not game.party_health.is_active(members[slot]):return false
		# Saved numbers come back as floats; compare them as whole numbers.
		var told: Callable=func(meat):return meat.known.any(func(other):return int(other)==slot)
		if meals[key]=="informed" and not batches.all(told):return false
		if meals[key]=="deceived" and (slot==0 or batches.any(told)):return false
	return true
