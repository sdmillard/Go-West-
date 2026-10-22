extends RefCounted
## Persistent local people, finite loot and staged incidents. No UI or global RNG.
const COMMANDS=["theft","robbery","shoot","raid","take","flee","surrender","finish","back"]
const STAGES=["loot","escape","report","done"]
const ATTEMPTS=["unseen","noticed","complied","resisted","missed","wounded","killed","raided"]
const RESOLUTIONS=["","left","escaped","captured","surrendered","party_lost"]
const VERSION:=3
const FACTS=["attempt","loot","escape"]
var scenes: Dictionary={}
var modifiers: Dictionary={}
var news_rules: Dictionary={}
var miles: Dictionary={}
var record: Dictionary={}
var rng:=RandomNumberGenerator.new()
var error: String=""
func _init():load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json")))
func load_data(value: Variant) -> bool:
	error="Invalid crime scene rules"
	if not value is Dictionary or value.get("version")!=1 or not value.get("scenes") is Dictionary or value.scenes.is_empty() or not value.get("modifiers") is Dictionary:return false
	var mods: Dictionary=value.modifiers
	if not mods.get("note") is String:return false
	for key in ["experience_step","stealth_step","staff_step","poor_condition_penalty","fair_condition_penalty","small_party_penalty","floor","ceiling"]:
		if not number(mods.get(key)) or mods[key]<0 or mods[key]>1:return false
	for key in ["experience_cap","minimum_able"]:
		if not whole(mods.get(key),0,5):return false
	var news: Variant=value.get("reports")
	if not news is Dictionary or not news.get("note") is String or not whole(news.get("delay_days"),0,30) or not whole(news.get("miles_per_day"),1,200):return false
	if mods.floor>=mods.ceiling or mods.experience_step*mods.experience_cap>0.25 or mods.stealth_step>mods.experience_step:return false
	for place in value.scenes:
		var scene: Variant=value.scenes[place]
		if not place is String or not scene is Dictionary:return false
		for key in ["title","note"]:
			if not scene.get(key) is String or scene[key].is_empty():return false
		for key in ["cash_cents","food_lot","loot_limit","injury_damage"]:
			if not whole(scene.get(key),1,100000):return false
		if scene.food_lot!=200 or scene.loot_limit>200 or scene.injury_damage>100:return false
		for key in ["theft_success","compliance","shot_hit","shot_fatal","escape_capture","escape_injury"]:
			if not number(scene.get(key)) or scene[key]<0 or scene[key]>1:return false
		# The first staff entry owns the service; everyone listed is a separate persistent person.
		if not scene.get("staff") is Array or scene.staff.is_empty() or scene.staff.size()>8:return false
		var ids: Array=[]
		for worker in scene.staff:
			if not worker is Dictionary or worker.size()!=2 or not worker.get("id") is String or not worker.get("role") is String or worker.role.is_empty() or worker.id in ids:return false
			if worker.id.is_empty() or not worker.id.is_valid_ascii_identifier():return false
			ids.append(worker.id)
		if ids[0]!="keeper":return false
	scenes=value.scenes.duplicate(true)
	modifiers=mods.duplicate(true)
	news_rules=news.duplicate(true)
	error=""
	return true
func start(seed_value: int) -> void:
	rng.seed=seed_value ^ 0x4352494d
	record={"version":VERSION,"people":{},"actors":{},"services":{},"incidents":[],"active":{},"reports":[]}
	for place in scenes:
		for uid in staff_ids(place):record.actors[uid]={"uid":uid,"place":place,"role":role(place,uid),"health":100}
		record.services[place]={"owner":owner_id(place),"staff":staff_ids(place),"cash_cents":int(scenes[place].cash_cents),"food_taken":0,"food_sold":0,"alarmed":false}
func person_id(seed_value: int,slot: int) -> String:return "party:%d:original:%d" % [seed_value,slot]
func actor_id(place: String,id: String) -> String:return id+":"+place
func staff_ids(place: String) -> Array:
	var ids: Array=[]
	for worker in scenes[place].staff:ids.append(actor_id(place,worker.id))
	return ids
func owner_id(place: String) -> String:return staff_ids(place)[0]
func role(place: String,uid: String) -> String:return scenes[place].staff[staff_ids(place).find(uid)].role
func owner(place: String) -> Dictionary:return record.actors[owner_id(place)]
func service(place: String) -> Dictionary:return record.services[place]
func living_staff(place: String) -> Array:
	return staff_ids(place).filter(func(uid):return record.actors[uid].health>0)
func bind_party(game) -> void:
	# Older saves only recorded offer counts. Conservatively retain that depletion.
	if record.people.is_empty():
		for place in scenes:service(place).food_sold=int(game.context.record.spent.get("post:"+place+"|buy_food",0))*int(scenes[place].food_lot)
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		if not record.people.has(uid):record.people[uid]={"name":member.name,"slot":int(member.id)}
func eligible(game) -> bool:
	return game.can_service() and game.pending.has("landmark") and game.pending.landmark==game.state.landmark and scenes.has(game.state.landmark)
func closed(place: String) -> bool:
	return record.services.has(place) and (service(place).alarmed or owner(place).health==0)
func food_left(game,place: String) -> int:
	return maxi(0,int(game.context.data.post_lots)*int(scenes[place].food_lot)-int(service(place).food_sold)-int(service(place).food_taken))
func consume_trade(choice: Dictionary) -> void:
	for place in scenes:
		if choice.get("market_key","")=="post:"+place+"|buy_food":service(place).food_sold+=maxi(0,int(choice.effects.get("food",0)))
func can_trade(game,choice: Dictionary) -> bool:
	var key: String=choice.get("market_key","")
	if key.begins_with("post:") and refuses(game,key.get_slice("|",0).trim_prefix("post:")):return false
	for place in scenes:
		if key.begins_with("post:"+place+"|"):
			if closed(place):return false
			if key.ends_with("|buy_food") and int(choice.effects.get("food",0))>food_left(game,place):return false
	return true
func incident() -> Dictionary:
	return {} if record.active.is_empty() else record.incidents[int(record.active.id)-1]
func loot_quote(game,place: String) -> Dictionary:
	var room:=maxi(0,floori(game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)))
	return {"food":mini(mini(food_left(game,place),int(scenes[place].loot_limit)),room),"money":service(place).cash_cents if not incident().is_empty() and incident().action!="theft" else 0}
func option(label: String,command: String) -> Dictionary:
	return {"label":label,"crime_command":command,"effects":{},"result":""}
## Distinct targets the party got away from, plus clean defensive victories. Capped; the same target never counts twice.
func experience(game) -> int:
	var targets: Array=[]
	for current in record.incidents:
		if current.resolution in ["left","escaped"] and current.attempt!="noticed" and current.attempt!="resisted" and current.attempt!="missed" and current.target not in targets:targets.append(current.target)
	return mini(targets.size()+game.combat.victories(),int(modifiers.experience_cap))
## Party members fit and willing to take part in this kind of act.
func able(game,action: String) -> int:
	return game.party_health.members.filter(func(member):return game.party_health.is_active(member) and member.health>=int(game.combat.data.poor_health) and game.characters.willing(int(member.id),action)).size()
func party_condition(game) -> String:
	var health: int=game.party_health.average_health()
	return "poor" if health<int(game.combat.data.poor_health) else ("fair" if health<int(game.combat.data.fair_health) else "good")
## Pure: no RNG, no state change. Experience and the situation shift intimidation, aim and escape.
## Whether a theft is noticed depends on who is there to notice it, plus a smaller experience bonus; never on party condition.
func odds(game,place: String,action: String="robbery") -> Dictionary:
	var scene: Dictionary=scenes[place]
	# Scene odds assume all of its staff are alive; each one already dead weakens resistance.
	var missing: int=staff_ids(place).size()-living_staff(place).size()
	var penalty: float=-missing*float(modifiers.staff_step)+{"poor":float(modifiers.poor_condition_penalty),"fair":float(modifiers.fair_condition_penalty),"good":0.0}[party_condition(game)]
	if able(game,action)<int(modifiers.minimum_able):penalty+=float(modifiers.small_party_penalty)
	var edge: float=experience(game)*float(modifiers.experience_step)-penalty
	var low: float=float(modifiers.floor)
	var high: float=float(modifiers.ceiling)
	return {"edge":edge,
		"theft_success":bounded(float(scene.theft_success),float(scene.theft_success)+missing*float(modifiers.staff_step)+experience(game)*float(modifiers.stealth_step),low,high),
		"compliance":bounded(float(scene.compliance),float(scene.compliance)+edge,low,high),
		"shot_hit":bounded(float(scene.shot_hit),float(scene.shot_hit)+edge,low,high),
		"escape_capture":bounded(float(scene.escape_capture),float(scene.escape_capture)-edge,low,high),
		"escape_injury":bounded(float(scene.escape_injury),float(scene.escape_injury)-edge,low,high),
		"shot_fatal":float(scene.shot_fatal),"injury_damage":int(scene.injury_damage)}
## Modifiers cannot push a value past the floor/ceiling, but authored extremes are kept.
func bounded(base: float,value: float,low: float,high: float) -> float:return clampf(value,minf(base,low),maxf(base,high))
func condition(actor: Dictionary) -> String:
	return "dead" if actor.health==0 else ("wounded" if actor.health<100 else "uninjured")
func menu(game) -> Dictionary:
	var place: String=game.state.landmark
	var keeper: Dictionary=owner(place)
	var scene: Dictionary=scenes[place]
	var current:=incident()
	var text: String="Your active companions are present and can observe your actions. Theft or an attack uses one day and ordinary meals. A shot spends one bullet. Nearby staff may resist."
	var options: Array=[]
	if current.is_empty():
		text+="\nKeeper: %s. Accessible food stock: %d lb. Cash stash: $%.2f." % [condition(keeper),food_left(game,place),service(place).cash_cents/100.0]
		text+="\nStaff on hand: %d. Your party's condition: %s. Fit, willing participants: %d. Prior successful jobs counted: %d of %d." % [living_staff(place).size(),party_condition(game),able(game,"robbery"),experience(game),int(modifiers.experience_cap)]
		if keeper.health>0:
			options=[option("Take supplies without paying · 1 day","theft"),option("Threaten the keeper with your gun · 1 day","robbery"),option("Shoot at the keeper · 1 bullet, 1 day","shoot")]
		else:options=[option("Enter the store and search for remaining supplies · 1 day","raid")]
	elif current.stage=="loot":
		var loot:=loot_quote(game,place)
		text="%s. You can take up to %d lb food and $%.2f from what remains. Cargo space limits food; collecting it uses one more day. Nearby staff can respond as you leave." % [current.attempt.capitalize(),loot.food,loot.money/100.0]
		options=[option("Take %d lb food and $%.2f · 1 day" % [loot.food,loot.money/100.0],"take"),option("Leave the supplies and try to get away","flee")]
	elif current.stage=="escape":
		text="%s. Staff have been alerted. Attempting escape costs one day; you may be injured or captured. Surrender ends this journey in custody." % current.attempt.capitalize()
		options=[option("Try to escape · 1 day","flee"),option("Surrender","surrender")]
	else:
		text="Incident %d: %s; %s. Food taken: %d lb. Cash taken: $%.2f. Shots: %d. People here who saw it: %d. See the journal and party records for injuries and reactions." % [current.id,current.attempt,current.resolution,current.food,current.cash_cents/100.0,current.shots,local_witnesses(current).size()]
		options=[option("Acknowledge the outcome","finish")]
	options.append(option("Back to the stop" if current.is_empty() else "Encounter in progress","back"))
	return {"id":"crime","crime_menu":true,"service_menu":true,"title":scene.title,"text":text,"choices":options}
func can_choose(game,command: String) -> bool:
	var current:=incident()
	if current.is_empty():
		if command=="back":return true
		if record.incidents.size()>=10000:return false
		var alive: bool=owner(game.state.landmark).health>0
		return (command in ["theft","robbery","shoot"] and alive and (command=="theft" or game.state.bullets>0)) or (command=="raid" and not alive)
	if current.stage=="report":return command=="finish"
	if current.stage=="loot":
		var quote:=loot_quote(game,current.place)
		return command=="flee" or (command=="take" and (quote.food>0 or quote.money>0))
	return current.stage=="escape" and command in ["flee","surrender"]
## Local people who hold any knowledge of this incident; later reports can only come from them.
func local_witnesses(current: Dictionary) -> Array:
	# Staff order, not dictionary order: saved JSON sorts keys.
	return staff_ids(current.place).filter(func(uid):return current.knowledge.has(uid))
## What the local witnesses of an incident pass on. Face-to-face acts identify the party; a noticed theft gives only a description.
func report_for(current: Dictionary,day: int) -> Dictionary:
	var facts: Array=[]
	for fact in FACTS:
		for uid in local_witnesses(current):
			if fact in current.knowledge[uid] and fact not in facts:facts.append(fact)
	return {"incident":current.id,"origin":current.place,"day":day,"senders":local_witnesses(current),"facts":facts,"identified":current.action!="theft"}
## Guide miles from the start of the road to each stop.
func mile(game,id: String) -> int:
	if miles.is_empty():
		var current: String=game.route.start
		var distance:=0
		while true:
			miles[current]=distance
			var next: Array=game.route.nodes[current].get("next",[])
			if next.is_empty() or not game.route.nodes.has(next[0].to):break
			distance+=int(next[0].miles)
			current=next[0].to
	return int(miles.get(id,0))
## News moves along the road with other travelers and traders, in both directions.
func arrival(game,report: Dictionary,place: String) -> int:
	if place==report.origin:return int(report.day)
	return int(report.day)+int(news_rules.delay_days)+ceili(absi(mile(game,place)-mile(game,report.origin))/float(news_rules.miles_per_day))
func heard(game,place: String) -> Array:
	return record.reports.filter(func(report):return arrival(game,report,place)<=int(game.state.day))
## A post refuses only when news that names the party has actually arrived there.
func refuses(game,place: String) -> bool:
	return heard(game,place).any(func(report):return report.identified and report.origin!=place)
func news_text(game,place: String) -> String:
	var lines: Array=[]
	for report in heard(game,place):
		if report.origin==place:continue
		var act: String={"theft":"stole from","robbery":"robbed","shoot":"shot at","raid":"looted"}[record.incidents[int(report.incident)-1].action]
		var origin: String=game.route.nodes[report.origin].name
		if report.identified:lines.append("Word reached here by day %d that your party %s the store at %s. The people here will not trade with you or help you." % [arrival(game,report,place),act,origin])
		else:lines.append("People here have heard that someone matching a description of your party stole from the store at %s." % origin)
	return " ".join(lines)
func observe(game,current: Dictionary,fact: String,staff: bool) -> void:
	var observers: Array=[]
	for member in game.party_health.members:
		if game.party_health.is_active(member):observers.append(person_id(int(game.state.seed),int(member.id)))
	# Each living staff member sees a noticed act for themselves. The dead learn nothing further.
	if staff:observers.append_array(living_staff(current.place))
	for uid in observers:
		if not current.knowledge.has(uid):current.knowledge[uid]=[]
		if fact not in current.knowledge[uid]:current.knowledge[uid].append(fact)
func result(game,resolution: String) -> void:
	var current:=incident()
	current.resolution=resolution
	current.stage="report"
	game.journal.append("Day %d · Store incident %d: %s; %s. Took %d lb food and $%.2f; fired %d shot(s)." % [game.state.day,current.id,current.attempt,resolution,current.food,current.cash_cents/100.0,current.shots])
	if resolution in ["left","escaped"] and not local_witnesses(current).is_empty():record.reports.append(report_for(current,int(game.state.day)))
	if resolution in ["captured","surrendered","party_lost"]:
		current.stage="done"
		record.active={}
		game.state.status="lost"
		game.state.loss_reason="The party's journey ended in custody." if resolution!="party_lost" else "The party did not survive."
		game.pending={}
		game.service_return={}
func advance(game,days: int=1) -> bool:
	game._apply({"days":days})
	if game.state.status!="traveling":
		result(game,"party_lost")
		return false
	return true
func choose(game,command: String) -> bool:
	if not can_choose(game,command):return false
	if command in ["back","finish"]:
		if command=="finish":
			incident().stage="done"
			record.active={}
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		return true
	var place: String=game.state.landmark
	var keeper: Dictionary=owner(place)
	var store: Dictionary=service(place)
	var kind: String=incident().get("action",command)
	var scene: Dictionary=odds(game,place,"murder" if kind=="shoot" else "robbery")
	if incident().is_empty():
		var id: int=record.incidents.size()+1
		var current: Dictionary={"id":id,"day":int(game.state.day),"place":place,"target":keeper.uid,"action":command,"attempt":"raided","resolution":"","stage":"escape","food":0,"cash_cents":0,"shots":0,"knowledge":{}}
		record.incidents.append(current)
		record.active={"id":id}
		if command=="theft":current.attempt="unseen" if rng.randf()<scene.theft_success else "noticed"
		elif command=="robbery":current.attempt="complied" if rng.randf()<scene.compliance else "resisted"
		elif command=="shoot":
			game._apply({"bullets":-1})
			current.shots=1
			current.attempt="missed"
			if rng.randf()<scene.shot_hit:
				keeper.health=0 if keeper.health<=40 or rng.randf()<scene.shot_fatal else maxi(0,int(keeper.health)-40)
				current.attempt="killed" if keeper.health==0 else "wounded"
		if current.attempt!="unseen":store.alarmed=true
		if current.attempt in ["unseen","complied","killed","raided"]:current.stage="loot"
		game.journal.append("Day %d · Store incident %d: %s; keeper %s. Nearby staff %s." % [game.state.day,id,command,current.attempt,"were alerted" if store.alarmed else "did not notice the attempt"])
		observe(game,current,"attempt",current.attempt!="unseen")
		game.characters.react_to_incident(game,"murder" if command=="shoot" else "robbery",id)
		if not advance(game):return true
	elif command=="take":
		var current:=incident()
		var loot:=loot_quote(game,place)
		store.food_taken+=int(loot.food)
		store.cash_cents-=int(loot.money)
		current.food+=int(loot.food)
		current.cash_cents+=int(loot.money)
		game._apply({"food":int(loot.food),"money":loot.money/100.0})
		observe(game,current,"loot",current.attempt!="unseen")
		if not advance(game):return true
		if current.attempt=="unseen":result(game,"left")
		else:current.stage="escape"
	elif command=="surrender":result(game,"surrendered")
	elif command=="flee":
		var current:=incident()
		if store.alarmed:
			if not advance(game):return true
			if rng.randf()<scene.escape_capture:
				result(game,"captured")
				return true
			if rng.randf()<scene.escape_injury:
				for member in game.party_health.members:
					if not game.party_health.is_active(member):continue
					game.party_health.affect(member,-int(scene.injury_damage),game.state.day,"confrontation injuries")
					if member.alive:game.party_health.begin_condition(int(member.id),"wound",int(game.state.day),1)
					game._collect_health_events()
					game.state.health=game.party_health.average_health()
					game.state.party_size=game.party_health.living_count()
					game._check_health()
					break
		observe(game,current,"escape",store.alarmed)
		result(game,"escaped" if game.state.status=="traveling" else "party_lost")
	if game.state.status=="traveling":game.pending=menu(game)
	return true
func snapshot() -> Dictionary:return {"record":record.duplicate(true),"random":str(rng.state)}
## Converts a version 1 snapshot (one keeper record per place and an aggregate "staff:<place>"
## observer) into separate staff people. Anything malformed is returned unchanged for valid() to reject.
func upgrade(value: Variant) -> Variant:
	value=upgrade_v1(value)
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=2 or not value.record.get("incidents") is Array:return value
	# Version 2 had witnesses but no reports. Their reports are dated to the incident day.
	var r: Dictionary=value.record.duplicate(true)
	r.version=VERSION
	r.reports=[]
	for current in r.incidents:
		if not current is Dictionary or not current.get("knowledge") is Dictionary or not scenes.has(current.get("place","")):return value
		if current.get("resolution") in ["left","escaped"] and not local_witnesses(current).is_empty():r.reports.append(report_for(current,int(current.get("day",0))))
	return {"record":r,"random":value.get("random")}
func upgrade_v1(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=1:return value
	var old: Dictionary=value.record
	if not old.get("actors") is Dictionary or not old.get("incidents") is Array:return value
	var r: Dictionary={"version":2,"people":old.get("people"),"actors":{},"services":{},"incidents":[],"active":old.get("active")}
	for place in old.actors:
		var actor: Variant=old.actors[place]
		if not scenes.has(place) or not actor is Dictionary or actor.size()!=6 or actor.get("uid")!=owner_id(place):return value
		for uid in staff_ids(place):r.actors[uid]={"uid":uid,"place":place,"role":role(place,uid),"health":actor.get("health") if uid==owner_id(place) else 100}
		r.services[place]={"owner":owner_id(place),"staff":staff_ids(place),"cash_cents":actor.get("cash_cents"),"food_taken":actor.get("food_taken"),"food_sold":actor.get("food_sold"),"alarmed":actor.get("alarmed")}
	for current in old.incidents:
		if not current is Dictionary or not current.get("knowledge") is Dictionary or not scenes.has(current.get("place","")):return value
		var copy: Dictionary=current.duplicate(true)
		var aggregate: Variant=copy.knowledge.get("staff:"+current.place)
		copy.knowledge.erase("staff:"+current.place)
		# Version 1 could not say which worker saw what; give the facts to the staff still alive.
		if aggregate is Array:
			for uid in staff_ids(current.place):
				if number(r.actors[uid].health) and r.actors[uid].health>0:copy.knowledge[uid]=aggregate.duplicate()
		r.incidents.append(copy)
	return {"record":r,"random":value.get("random")}
func number(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
func whole(value: Variant,low: int,high: int) -> bool:return number(value) and value==floor(value) and value>=low and value<=high
func valid(value: Variant,game) -> bool:
	if not value is Dictionary or value.size()!=2 or not value.get("record") is Dictionary or not value.get("random") is String or not value.random.is_valid_int() or str(int(value.random))!=value.random:return false
	var r: Dictionary=value.record
	if r.size()!=7 or not r.get("reports") is Array or r.get("version")!=VERSION or not r.get("people") is Dictionary or r.people.size()!=5 or not r.get("actors") is Dictionary or not r.get("services") is Dictionary or r.services.size()!=scenes.size() or not r.get("incidents") is Array or r.incidents.size()>10000 or not r.get("active") is Dictionary:return false
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		var person: Variant=r.people.get(uid)
		if not person is Dictionary or person.size()!=2 or person.get("name")!=member.name or person.get("slot")!=member.id:return false
	var actor_count:=0
	for place in scenes:
		var lots: int=int(game.context.data.post_lots)*int(scenes[place].food_lot)
		for uid in staff_ids(place):
			var actor: Variant=r.actors.get(uid)
			if not actor is Dictionary or actor.size()!=4 or actor.get("uid")!=uid or actor.get("place")!=place or actor.get("role")!=role(place,uid) or not whole(actor.get("health"),0,100):return false
			actor_count+=1
		var store: Variant=r.services.get(place)
		if not store is Dictionary or store.size()!=6 or store.get("owner")!=owner_id(place) or store.get("staff")!=staff_ids(place) or not whole(store.get("cash_cents"),0,int(scenes[place].cash_cents)) or not whole(store.get("food_taken"),0,lots) or not whole(store.get("food_sold"),0,lots) or not store.get("alarmed") is bool:return false
		if r.actors[owner_id(place)].health==0 and not store.alarmed:return false
		if store.food_taken+store.food_sold>lots:return false
		var offers: int=game.context.record.spent.get("post:"+place+"|buy_food",0)
		if store.food_sold<offers*40 or store.food_sold>offers*int(scenes[place].food_lot):return false
	if r.actors.size()!=actor_count:return false
	var food_totals: Dictionary={}
	var cash_totals: Dictionary={}
	var previous_day: int=-1
	for index in range(r.incidents.size()):
		var current: Variant=r.incidents[index]
		if not current is Dictionary or current.size()!=12 or current.get("id")!=index+1 or not whole(current.get("day"),0,int(game.state.day)) or not scenes.has(current.get("place","")) or current.get("target")!=owner_id(current.place):return false
		if current.get("action") not in ["theft","robbery","shoot","raid"] or current.get("attempt") not in ATTEMPTS or current.get("stage") not in STAGES or current.get("resolution") not in RESOLUTIONS:return false
		if current.day<previous_day:return false
		previous_day=int(current.day)
		if current.attempt not in {"theft":["unseen","noticed"],"robbery":["complied","resisted"],"shoot":["missed","wounded","killed"],"raid":["raided"]}[current.action]:return false
		if (current.stage in ["loot","escape"])!=(current.resolution==""):return false
		if current.stage=="loot" and current.attempt not in ["unseen","complied","killed","raided"]:return false
		if current.attempt!="unseen" and not r.services[current.place].alarmed:return false
		if current.attempt=="killed" and r.actors[owner_id(current.place)].health!=0:return false
		for key in ["food","cash_cents","shots"]:
			if not whole(current.get(key),0,100000):return false
		if current.shots!=(1 if current.action=="shoot" else 0) or not current.get("knowledge") is Dictionary or current.knowledge.size()>5+staff_ids(current.place).size():return false
		var local:=0
		for uid in current.knowledge:
			if not r.people.has(uid) and uid not in staff_ids(current.place):return false
			if not current.knowledge[uid] is Array or current.knowledge[uid].is_empty() or current.knowledge[uid].size()>3:return false
			var seen: Array=[]
			for fact in current.knowledge[uid]:
				if fact not in ["attempt","loot","escape"] or fact in seen:return false
				seen.append(fact)
			if uid in staff_ids(current.place):local+=1
		# Nobody local knows of an unseen act; every staff member still alive saw a noticed one. Witnesses cannot be edited away.
		if current.attempt=="unseen" and local>0:return false
		if current.attempt!="unseen":
			for uid in staff_ids(current.place):
				if r.actors[uid].health>0 and "attempt" not in current.knowledge.get(uid,[]):return false
		food_totals[current.place]=int(food_totals.get(current.place,0))+int(current.food)
		cash_totals[current.place]=int(cash_totals.get(current.place,0))+int(current.cash_cents)
		if current.stage!="done" and r.active.get("id",0)!=current.id:return false
	for place in scenes:
		if int(food_totals.get(place,0))!=r.services[place].food_taken or int(cash_totals.get(place,0))+r.services[place].cash_cents!=scenes[place].cash_cents:return false
	# Every resolved, witnessed getaway has exactly one report, in incident order, saying exactly what its witnesses know.
	var expected: Array=r.incidents.filter(func(current):return current.resolution in ["left","escaped"] and not local_witnesses(current).is_empty())
	if r.reports.size()!=expected.size():return false
	for index in range(expected.size()):
		var report: Variant=r.reports[index]
		var current: Dictionary=expected[index]
		if not report is Dictionary or report.size()!=6 or not whole(report.get("day"),int(current.day),int(game.state.day)):return false
		var derived: Dictionary=report_for(current,int(report.day))
		if report.get("incident")!=derived.incident or report.get("origin")!=derived.origin or report.get("identified")!=derived.identified or report.get("senders")!=derived.senders or report.get("facts")!=derived.facts:return false
	if not r.active.is_empty():
		if r.active.size()!=1 or not whole(r.active.get("id"),1,r.incidents.size()) or r.active.id!=r.incidents.size() or r.incidents[int(r.active.id)-1].stage=="done" or not game.pending.get("crime_menu",false):return false
	return true
