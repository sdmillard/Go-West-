extends RefCounted
## Persistent local people, finite loot and staged incidents. No UI or global RNG.
const COMMANDS=["theft","robbery","shoot","raid","take","flee","surrender","finish","back"]
const STAGES=["loot","escape","report","done"]
const ATTEMPTS=["unseen","noticed","complied","resisted","missed","wounded","killed","raided"]
const RESOLUTIONS=["","left","escaped","captured","surrendered","party_lost"]
var scenes: Dictionary={}
var record: Dictionary={}
var rng:=RandomNumberGenerator.new()
var error: String=""
func _init():load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json")))
func load_data(value: Variant) -> bool:
	error="Invalid crime scene rules"
	if not value is Dictionary or value.get("version")!=1 or not value.get("scenes") is Dictionary or value.scenes.is_empty():return false
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
	scenes=value.scenes.duplicate(true)
	error=""
	return true
func start(seed_value: int) -> void:
	rng.seed=seed_value ^ 0x4352494d
	record={"version":1,"people":{},"actors":{},"incidents":[],"active":{}}
	for place in scenes:
		record.actors[place]={"uid":"keeper:"+place,"health":100,"cash_cents":int(scenes[place].cash_cents),"food_taken":0,"food_sold":0,"alarmed":false}
func person_id(seed_value: int,slot: int) -> String:return "party:%d:original:%d" % [seed_value,slot]
func bind_party(game) -> void:
	# Older saves only recorded offer counts. Conservatively retain that depletion.
	if record.people.is_empty():
		for place in scenes:record.actors[place].food_sold=int(game.context.record.spent.get("post:"+place+"|buy_food",0))*int(scenes[place].food_lot)
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		if not record.people.has(uid):record.people[uid]={"name":member.name,"slot":int(member.id)}
func eligible(game) -> bool:
	return game.can_service() and game.pending.has("landmark") and game.pending.landmark==game.state.landmark and scenes.has(game.state.landmark)
func closed(place: String) -> bool:
	return record.actors.has(place) and (record.actors[place].alarmed or record.actors[place].health==0)
func food_left(game,place: String) -> int:
	return maxi(0,int(game.context.data.post_lots)*int(scenes[place].food_lot)-int(record.actors[place].food_sold)-int(record.actors[place].food_taken))
func consume_trade(choice: Dictionary) -> void:
	for place in scenes:
		if choice.get("market_key","")=="post:"+place+"|buy_food":record.actors[place].food_sold+=maxi(0,int(choice.effects.get("food",0)))
func can_trade(game,choice: Dictionary) -> bool:
	var key: String=choice.get("market_key","")
	for place in scenes:
		if key.begins_with("post:"+place+"|"):
			if closed(place):return false
			if key.ends_with("|buy_food") and int(choice.effects.get("food",0))>food_left(game,place):return false
	return true
func incident() -> Dictionary:
	return {} if record.active.is_empty() else record.incidents[int(record.active.id)-1]
func loot_quote(game,place: String) -> Dictionary:
	var room:=maxi(0,floori(game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)))
	return {"food":mini(mini(food_left(game,place),int(scenes[place].loot_limit)),room),"money":record.actors[place].cash_cents if not incident().is_empty() and incident().action!="theft" else 0}
func option(label: String,command: String) -> Dictionary:
	return {"label":label,"crime_command":command,"effects":{},"result":""}
func menu(game) -> Dictionary:
	var place: String=game.state.landmark
	var actor: Dictionary=record.actors[place]
	var scene: Dictionary=scenes[place]
	var current:=incident()
	var text: String="Your active companions are present and can observe your actions. Theft or an attack uses one day and ordinary meals. A shot spends one bullet. Nearby staff may resist."
	var options: Array=[]
	if current.is_empty():
		text+="\nKeeper: %s. Accessible food stock: %d lb. Cash stash: $%.2f." % ["dead" if actor.health==0 else ("wounded" if actor.health<100 else "uninjured"),food_left(game,place),actor.cash_cents/100.0]
		if actor.health>0:
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
		text="Incident %d: %s; %s. Food taken: %d lb. Cash taken: $%.2f. Shots: %d. See the journal and party records for injuries and reactions." % [current.id,current.attempt,current.resolution,current.food,current.cash_cents/100.0,current.shots]
		options=[option("Acknowledge the outcome","finish")]
	options.append(option("Back to the stop" if current.is_empty() else "Encounter in progress","back"))
	return {"id":"crime","crime_menu":true,"service_menu":true,"title":scene.title,"text":text,"choices":options}
func can_choose(game,command: String) -> bool:
	var current:=incident()
	if current.is_empty():
		if command=="back":return true
		if record.incidents.size()>=10000:return false
		var alive: bool=record.actors[game.state.landmark].health>0
		return (command in ["theft","robbery","shoot"] and alive and (command=="theft" or game.state.bullets>0)) or (command=="raid" and not alive)
	if current.stage=="report":return command=="finish"
	if current.stage=="loot":
		var quote:=loot_quote(game,current.place)
		return command=="flee" or (command=="take" and (quote.food>0 or quote.money>0))
	return current.stage=="escape" and command in ["flee","surrender"]
func observe(game,current: Dictionary,fact: String,staff: bool) -> void:
	var observers: Array=[]
	for member in game.party_health.members:
		if game.party_health.is_active(member):observers.append(person_id(int(game.state.seed),int(member.id)))
	if staff:observers.append("staff:"+current.place)
	for uid in observers:
		if not current.knowledge.has(uid):current.knowledge[uid]=[]
		if fact not in current.knowledge[uid]:current.knowledge[uid].append(fact)
func result(game,resolution: String) -> void:
	var current:=incident()
	current.resolution=resolution
	current.stage="report"
	game.journal.append("Day %d · Store incident %d: %s; %s. Took %d lb food and $%.2f; fired %d shot(s)." % [game.state.day,current.id,current.attempt,resolution,current.food,current.cash_cents/100.0,current.shots])
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
	var actor: Dictionary=record.actors[place]
	var scene: Dictionary=scenes[place]
	if incident().is_empty():
		var id: int=record.incidents.size()+1
		var current: Dictionary={"id":id,"day":int(game.state.day),"place":place,"target":actor.uid,"action":command,"attempt":"raided","resolution":"","stage":"escape","food":0,"cash_cents":0,"shots":0,"knowledge":{}}
		record.incidents.append(current)
		record.active={"id":id}
		if command=="theft":current.attempt="unseen" if rng.randf()<scene.theft_success else "noticed"
		elif command=="robbery":current.attempt="complied" if rng.randf()<scene.compliance else "resisted"
		elif command=="shoot":
			game._apply({"bullets":-1})
			current.shots=1
			current.attempt="missed"
			if rng.randf()<scene.shot_hit:
				actor.health=0 if actor.health<=40 or rng.randf()<scene.shot_fatal else maxi(0,int(actor.health)-40)
				current.attempt="killed" if actor.health==0 else "wounded"
		if current.attempt!="unseen":actor.alarmed=true
		if current.attempt in ["unseen","complied","killed","raided"]:current.stage="loot"
		game.journal.append("Day %d · Store incident %d: %s; keeper %s. Nearby staff %s." % [game.state.day,id,command,current.attempt,"were alerted" if actor.alarmed else "did not notice the attempt"])
		observe(game,current,"attempt",current.attempt!="unseen")
		game.characters.react_to_incident(game,"murder" if command=="shoot" else "robbery",id)
		if not advance(game):return true
	elif command=="take":
		var current:=incident()
		var loot:=loot_quote(game,place)
		actor.food_taken+=int(loot.food)
		actor.cash_cents-=int(loot.money)
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
		if actor.alarmed:
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
		observe(game,current,"escape",actor.alarmed)
		result(game,"escaped" if game.state.status=="traveling" else "party_lost")
	if game.state.status=="traveling":game.pending=menu(game)
	return true
func snapshot() -> Dictionary:return {"record":record.duplicate(true),"random":str(rng.state)}
func number(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
func whole(value: Variant,low: int,high: int) -> bool:return number(value) and value==floor(value) and value>=low and value<=high
func valid(value: Variant,game) -> bool:
	if not value is Dictionary or value.size()!=2 or not value.get("record") is Dictionary or not value.get("random") is String or not value.random.is_valid_int() or str(int(value.random))!=value.random:return false
	var r: Dictionary=value.record
	if r.size()!=5 or r.get("version")!=1 or not r.get("people") is Dictionary or r.people.size()!=5 or not r.get("actors") is Dictionary or r.actors.size()!=scenes.size() or not r.get("incidents") is Array or r.incidents.size()>10000 or not r.get("active") is Dictionary:return false
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		var person: Variant=r.people.get(uid)
		if not person is Dictionary or person.size()!=2 or person.get("name")!=member.name or person.get("slot")!=member.id:return false
	for place in scenes:
		var actor: Variant=r.actors.get(place)
		if not actor is Dictionary or actor.size()!=6 or actor.get("uid")!="keeper:"+place or not whole(actor.get("health"),0,100) or not whole(actor.get("cash_cents"),0,int(scenes[place].cash_cents)) or not whole(actor.get("food_taken"),0,int(game.context.data.post_lots)*int(scenes[place].food_lot)) or not whole(actor.get("food_sold"),0,int(game.context.data.post_lots)*int(scenes[place].food_lot)) or not actor.get("alarmed") is bool:return false
		if actor.health==0 and not actor.alarmed:return false
		if actor.food_taken+actor.food_sold>int(game.context.data.post_lots)*int(scenes[place].food_lot):return false
		var offers: int=game.context.record.spent.get("post:"+place+"|buy_food",0)
		if actor.food_sold<offers*40 or actor.food_sold>offers*int(scenes[place].food_lot):return false
	var food_totals: Dictionary={}
	var cash_totals: Dictionary={}
	var previous_day: int=-1
	for index in range(r.incidents.size()):
		var current: Variant=r.incidents[index]
		if not current is Dictionary or current.size()!=12 or current.get("id")!=index+1 or not whole(current.get("day"),0,int(game.state.day)) or not scenes.has(current.get("place","")) or current.get("target")!="keeper:"+current.place:return false
		if current.get("action") not in ["theft","robbery","shoot","raid"] or current.get("attempt") not in ATTEMPTS or current.get("stage") not in STAGES or current.get("resolution") not in RESOLUTIONS:return false
		if current.day<previous_day:return false
		previous_day=int(current.day)
		if current.attempt not in {"theft":["unseen","noticed"],"robbery":["complied","resisted"],"shoot":["missed","wounded","killed"],"raid":["raided"]}[current.action]:return false
		if (current.stage in ["loot","escape"])!=(current.resolution==""):return false
		if current.stage=="loot" and current.attempt not in ["unseen","complied","killed","raided"]:return false
		if current.attempt!="unseen" and not r.actors[current.place].alarmed:return false
		if current.attempt=="killed" and r.actors[current.place].health!=0:return false
		for key in ["food","cash_cents","shots"]:
			if not whole(current.get(key),0,100000):return false
		if current.shots!=(1 if current.action=="shoot" else 0) or not current.get("knowledge") is Dictionary or current.knowledge.size()>6:return false
		for uid in current.knowledge:
			if not r.people.has(uid) and uid!="staff:"+current.place:return false
			if not current.knowledge[uid] is Array or current.knowledge[uid].size()>3:return false
			var seen: Array=[]
			for fact in current.knowledge[uid]:
				if fact not in ["attempt","loot","escape"] or fact in seen:return false
				seen.append(fact)
		food_totals[current.place]=int(food_totals.get(current.place,0))+int(current.food)
		cash_totals[current.place]=int(cash_totals.get(current.place,0))+int(current.cash_cents)
		if current.stage!="done" and r.active.get("id",0)!=current.id:return false
	for place in scenes:
		if int(food_totals.get(place,0))!=r.actors[place].food_taken or int(cash_totals.get(place,0))+r.actors[place].cash_cents!=scenes[place].cash_cents:return false
	if not r.active.is_empty():
		if r.active.size()!=1 or not whole(r.active.get("id"),1,r.incidents.size()) or r.active.id!=r.incidents.size() or r.incidents[int(r.active.id)-1].stage=="done" or not game.pending.get("crime_menu",false):return false
	return true
