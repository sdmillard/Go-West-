extends RefCounted
## Persistent local people, finite loot and staged incidents. No UI or global RNG.
const COMMANDS=["theft","robbery","shoot","raid","take","flee","breakout","surrender","finish","back"]
const STAGES=["loot","escape","standoff","report","done"]
const ATTEMPTS=["unseen","noticed","complied","resisted","missed","wounded","killed","raided"]
const RESOLUTIONS=["","left","escaped","captured","surrendered","party_lost"]
const VERSION:=3
const FACTS=["attempt","loot","escape"]
## Venue wording. A store yields food and cash; a toll gate or ferry yields its cash box and passage.
const KINDS={
	"store":{"journal":"Store","noun":"the store","theft":"Take supplies without paying · 1 day","raid":"Enter the store and search for remaining supplies · 1 day"},
	"toll":{"journal":"Toll gate","noun":"the toll gate","theft":"Slip the wagons past the gate without paying · 1 day","raid":"Search the gatekeeper's cabin for the toll money · 1 day","take":"Take $%.2f from the toll box and pass the gate · 1 day","passage":"the gate will be behind you"},
	"fort":{"journal":"Fort","noun":"the army post","theft":"Take rations from the commissary tent · 1 day","raid":"Search the commissary tent for rations and the cash box · 1 day"},
	"traders":{"journal":"Trader","noun":"a trading party","theft":"Take goods from the traders' packs without paying · 1 day","raid":"Search the traders' packs · 1 day"},
	"emigrants":{"journal":"Emigrant","noun":"an emigrant family","theft":"Take food from their wagon while they sleep · 1 day","raid":"Search their wagon · 1 day"},
	"ferry":{"journal":"Ferry","noun":"the ferry","theft":"Cast off with the ferry while the crew is away · 1 day","raid":"Take the ferry and the crew's cash box · 1 day","take":"Take $%.2f and the ferry · 1 day","passage":"the ferry will be yours to work across"}}
## Attempts that reach the loot stage; only these can win passage at a gate or ferry.
const LOOTING=["unseen","complied","killed","raided"]
## The one traders scene is a template: each passing trading party, named by its market key, gets its own people when first targeted.
const TRADERS:="passing_traders"
## Emigrant families camped near the road work the same way, named by their camp.
const EMIGRANTS:="passing_emigrants"
const TEMPLATES={"passing:":TRADERS,"emigrants:":EMIGRANTS}
const TEMPLATE_KINDS={TRADERS:"traders",EMIGRANTS:"emigrants"}
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
		if not KINDS.has(scene.get("kind")):return false
		for key in ["cash_cents","food_lot","loot_limit","injury_damage"]:
			if not whole(scene.get(key),0 if key in ["food_lot","loot_limit"] else 1,100000):return false
		# Only stores sell or hold food; a gate or ferry holds only its cash box.
		if (scene.kind in TEMPLATE_KINDS.values())!=TEMPLATE_KINDS.has(place) or (TEMPLATE_KINDS.has(place) and scene.kind!=TEMPLATE_KINDS[place]):return false
		if (scene.kind=="emigrants")!=scene.has("every_days") or scene.has("every_days")!=scene.has("window_days"):return false
		if scene.kind=="emigrants" and (not whole(scene.every_days,2,60) or not whole(scene.window_days,1,scene.every_days-1)):return false
		# Food lots match what each venue sells: a post's 200 lb lot, a passing party's 50 lb lot.
		if scene.food_lot!={"store":200,"traders":50}.get(scene.kind,0) or scene.loot_limit>(0 if scene.kind in ["toll","ferry"] else 200) or scene.injury_damage>100:return false
		# A fort's commissary holds its own stock; soldiers who stop an escape force a standoff.
		var fort_keys: Array=["food_stock","breakout","breakout_shots"]
		for key in fort_keys:
			if scene.has(key)!=(scene.kind=="fort" or (key=="food_stock" and scene.kind=="emigrants")):return false
		if scene.has("food_stock") and not whole(scene.food_stock,1,2000):return false
		if scene.kind=="fort" and ( not number(scene.breakout) or scene.breakout<0 or scene.breakout>1 or not whole(scene.breakout_shots,1,5)):return false
		if (scene.kind=="ferry")!=scene.has("seized_risk_low") or scene.has("seized_risk_low")!=scene.has("seized_risk_high"):return false
		if scene.kind=="ferry":
			for key in ["seized_risk_low","seized_risk_high"]:
				if not number(scene.get(key)) or scene[key]<0 or scene[key]>1:return false
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
	if not TEMPLATE_KINDS.keys().all(func(key):return value.scenes.has(key)):return false
	scenes=value.scenes.duplicate(true)
	modifiers=mods.duplicate(true)
	news_rules=news.duplicate(true)
	error=""
	return true
func start(seed_value: int) -> void:
	rng.seed=seed_value ^ 0x4352494d
	record={"version":VERSION,"people":{},"actors":{},"services":{},"incidents":[],"active":{},"reports":[]}
	for place in venues():
		for uid in staff_ids(place):record.actors[uid]=fresh_actor(place,uid)
		record.services[place]=fresh_service(place,0)
## Fixed venues; passing traders are added to the record as they are targeted.
func venues() -> Array:return scenes.keys().filter(func(place):return not TEMPLATE_KINDS.has(place))
func trader(place: String) -> bool:return place.begins_with("passing:") and place.length()<=64
## A trading party or emigrant family: met on the road, not a fixed venue.
func transient(place: String) -> bool:return place.length()<=64 and TEMPLATES.keys().any(func(prefix):return place.begins_with(prefix))
func places() -> Array:return venues()+record.services.keys().filter(transient)
func rules(place: String) -> Dictionary:
	for prefix in TEMPLATES:
		if place.begins_with(prefix):return scenes[TEMPLATES[prefix]]
	return scenes[place]
func fresh_actor(place: String,uid: String) -> Dictionary:return {"uid":uid,"place":place,"role":role(place,uid),"health":100}
func fresh_service(place: String,food_sold: int) -> Dictionary:
	return {"owner":owner_id(place),"staff":staff_ids(place),"cash_cents":int(rules(place).cash_cents),"food_taken":0,"food_sold":food_sold,"alarmed":false}
## A trading party's people and stock enter the record on the first committed act; food already bought from it is counted.
func add_transient(game,place: String) -> void:
	if not transient(place) or record.services.has(place):return
	for uid in staff_ids(place):record.actors[uid]=fresh_actor(place,uid)
	record.services[place]=fresh_service(place,int(game.context.record.spent.get(place+"|buy_food",0))*int(rules(place).food_lot))
	record.services[place]["mile"]=int(game.state.miles)
func person_id(seed_value: int,slot: int) -> String:return "party:%d:original:%d" % [seed_value,slot]
func actor_id(place: String,id: String) -> String:return id+":"+place
func staff_ids(place: String) -> Array:
	var ids: Array=[]
	for worker in rules(place).staff:ids.append(actor_id(place,worker.id))
	return ids
func owner_id(place: String) -> String:return staff_ids(place)[0]
func role(place: String,uid: String) -> String:return rules(place).staff[staff_ids(place).find(uid)].role
func kind(place: String) -> Dictionary:return KINDS[rules(place).kind]
## Passage won at a toll gate or ferry: the party took the cash box or the boat and got away with it, or killed the gatekeeper.
func passage(place: String) -> bool:
	if not scenes.has(place) or scenes[place].kind not in ["toll","ferry"]:return false
	# Nobody is left to collect a toll.
	if scenes[place].kind=="toll" and owner(place).health==0:return true
	return record.incidents.any(func(current):return current.place==place and current.resolution in ["left","escaped"] and current.attempt in LOOTING and current.knowledge.values().any(func(facts):return "loot" in facts))
## A ferry the party took, or whose crew it attacked or has heard about it, will not carry the party.
func ferry_refused(game,place: String) -> bool:
	return scenes.has(place) and scenes[place].kind=="ferry" and (closed(place) or refuses(game,place) or passage(place))
func seized_risk(game,place: String) -> float:
	return float(scenes[place].seized_risk_high if game.state.river_stage=="high" else scenes[place].seized_risk_low)
## Untargeted trading parties are read as fresh people and stock without entering the record.
func actor(place: String,uid: String) -> Dictionary:return record.actors[uid] if record.actors.has(uid) else fresh_actor(place,uid)
func owner(place: String) -> Dictionary:return actor(place,owner_id(place))
func service(place: String) -> Dictionary:return record.services[place] if record.services.has(place) else fresh_service(place,0)
func living_staff(place: String) -> Array:
	return staff_ids(place).filter(func(uid):return actor(place,uid).health>0)
func bind_party(game) -> void:
	# Older saves only recorded offer counts. Conservatively retain that depletion.
	if record.people.is_empty():
		for place in venues():service(place).food_sold=int(game.context.record.spent.get("post:"+place+"|buy_food",0))*int(scenes[place].food_lot)
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		if not record.people.has(uid):record.people[uid]={"name":member.name,"slot":int(member.id)}
func eligible(game) -> bool:
	return game.can_service() and not target(game).is_empty()
## What a crime here would be aimed at: the active incident, a staffed venue at this stop, or passing traders on the road.
func target(game) -> String:
	if not incident().is_empty():return incident().place
	var stop: Dictionary=game.service_return if game.pending.get("crime_menu",false) else game.pending
	var landmark: String=game.state.landmark
	if stop.get("landmark","")==landmark and scenes.has(landmark) and not TEMPLATE_KINDS.has(landmark):return landmark if staffed(game,landmark) else ""
	var offer: Dictionary=game.context.market(game)
	if offer.available and not offer.post:return offer.key
	return camp(game)
## An emigrant family camped near the road, on a fixed rhythm per journey; "" when none is near.
func camp(game) -> String:
	var rule: Dictionary=scenes[EMIGRANTS]
	var day: int=int(game.state.day)+posmod(int(game.state.seed),5)
	if posmod(day,int(rule.every_days))>=int(rule.window_days):return ""
	return "emigrants:%s:%d" % [game.context.region_id(game),day/int(rule.every_days)]
## A post still waiting for its builders has nobody to rob.
func staffed(game,place: String) -> bool:
	var node: Dictionary=game.route.nodes[place]
	return not node.has("construction_from_month") or int(game.calendar().year)!=1848 or int(game.calendar().month)>=int(node.construction_from_month)
func closed(place: String) -> bool:
	return record.services.has(place) and (service(place).alarmed or owner(place).health==0)
func food_capacity(game,place: String) -> int:
	if rules(place).has("food_stock"):return int(rules(place).food_stock)
	return int(game.context.data.passing_lots if trader(place) else game.context.data.post_lots)*int(rules(place).food_lot)
func food_left(game,place: String) -> int:
	# Food bought from traders not yet in the record still left their packs.
	var sold: int=int(service(place).food_sold) if record.services.has(place) else int(game.context.record.spent.get(market_prefix(place)+"|buy_food",0))*int(rules(place).food_lot)
	return maxi(0,food_capacity(game,place)-sold-int(service(place).food_taken))
func market_prefix(place: String) -> String:return place if trader(place) else "post:"+place
func consume_trade(choice: Dictionary) -> void:
	for place in places():
		if choice.get("market_key","")==market_prefix(place)+"|buy_food":service(place).food_sold+=maxi(0,int(choice.effects.get("food",0)))
func can_trade(game,choice: Dictionary) -> bool:
	var key: String=choice.get("market_key","")
	if key.begins_with("post:") and refuses(game,key.get_slice("|",0).trim_prefix("post:")):return false
	for place in places():
		if key.begins_with(market_prefix(place)+"|"):
			if closed(place):return false
			if key.ends_with("|buy_food") and int(choice.effects.get("food",0))>food_left(game,place):return false
	return true
func incident() -> Dictionary:
	return {} if record.active.is_empty() else record.incidents[int(record.active.id)-1]
func loot_quote(game,place: String) -> Dictionary:
	var room:=maxi(0,floori(game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)))
	return {"food":mini(mini(food_left(game,place),int(rules(place).loot_limit)),room) if rules(place).kind in ["store","fort","traders","emigrants"] else 0,"money":service(place).cash_cents if not incident().is_empty() and incident().action!="theft" else 0}
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
	var scene: Dictionary=rules(place)
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
	var place: String=target(game)
	var keeper: Dictionary=owner(place)
	var scene: Dictionary=rules(place)
	var words: Dictionary=kind(place)
	var current:=incident()
	var text: String="Your active companions are present and can observe your actions. Theft or an attack uses one day and ordinary meals. A shot spends one bullet. Nearby staff may resist."
	var options: Array=[]
	if current.is_empty():
		if scene.kind=="emigrants":text+="\nHead of the family: %s. Others with them: %d. Food in their wagon: %d lb. Cash: $%.2f. Their company is camped within earshot." % [condition(keeper),living_staff(place).size()-1,food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="traders":text+="\nLead trader: %s. Food in their packs: %d lb. Cash: $%.2f. Nobody else is in sight on this stretch of road." % [condition(keeper),food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="store":text+="\nKeeper: %s. Accessible food stock: %d lb. Cash stash: $%.2f." % [condition(keeper),food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="fort":text+="\n%s: %s. Soldiers on duty nearby: %d. Commissary rations: %d lb. Cash box: $%.2f. If soldiers stop an escape, the party must surrender or shoot its way out." % [keeper.role.capitalize(),condition(keeper),living_staff(place).size()-1,food_left(game,place),service(place).cash_cents/100.0]
		else:text+="\n%s: %s. Cash box: $%.2f." % [keeper.role.capitalize(),condition(keeper),service(place).cash_cents/100.0]
		text+="\nStaff on hand: %d. Your party's condition: %s. Fit, willing participants: %d. Prior successful jobs counted: %d of %d." % [living_staff(place).size(),party_condition(game),able(game,"robbery"),experience(game),int(modifiers.experience_cap)]
		if keeper.health>0:
			options=[option(words.theft,"theft"),option("Threaten the %s with your gun · 1 day" % keeper.role,"robbery"),option("Shoot at the %s · 1 bullet, 1 day" % keeper.role,"shoot")]
		else:options=[option(words.raid,"raid")]
	elif current.stage=="loot":
		var loot:=loot_quote(game,place)
		if scene.kind in ["toll","ferry"]:
			text="%s. You can take $%.2f from the cash box, and %s. Doing it uses one more day. Nearby staff can respond as you leave." % [current.attempt.capitalize(),loot.money/100.0,words.passage]
			options=[option(words.take % (loot.money/100.0),"take"),option("Give it up and try to get away","flee")]
		else:
			text="%s. You can take up to %d lb food and $%.2f from what remains. Cargo space limits food; collecting it uses one more day. Nearby staff can respond as you leave." % [current.attempt.capitalize(),loot.food,loot.money/100.0]
			options=[option("Take %d lb food and $%.2f · 1 day" % [loot.food,loot.money/100.0],"take"),option("Leave the supplies and try to get away","flee")]
	elif current.stage=="escape":
		text="%s. Staff have been alerted. Attempting escape costs one day; you may be injured or captured. Surrender ends this journey in custody." % current.attempt.capitalize()
		options=[option("Try to escape · 1 day","flee"),option("Surrender","surrender")]
	elif current.stage=="standoff":
		var shots: int=mini(int(scene.breakout_shots),int(game.state.bullets))
		text="Soldiers have blocked the way out. Shooting your way out spends up to %d bullets; some of you will likely be hurt, and you may still be taken. Surrender ends this journey in custody." % int(scene.breakout_shots)
		options=[option("Shoot your way out · %d bullet(s)" % shots,"breakout"),option("Surrender","surrender")]
	else:
		text="Incident %d: %s; %s. Food taken: %d lb. Cash taken: $%.2f. Shots: %d. People here who saw it: %d. See the journal and party records for injuries and reactions." % [current.id,current.attempt,current.resolution,current.food,current.cash_cents/100.0,current.shots,local_witnesses(current).size()]
		options=[option("Acknowledge the outcome","finish")]
	options.append(option(({"traders":"Leave the traders alone","emigrants":"Leave the family be"}.get(scene.kind,"Back to the stop")) if current.is_empty() else "Encounter in progress","back"))
	return {"id":"crime","crime_menu":true,"service_menu":true,"title":scene.title,"text":text,"choices":options}
func can_choose(game,command: String) -> bool:
	var current:=incident()
	if current.is_empty():
		if command=="back":return true
		if record.incidents.size()>=10000:return false
		var alive: bool=owner(target(game)).health>0
		return (command in ["theft","robbery","shoot"] and alive and (command=="theft" or game.state.bullets>0)) or (command=="raid" and not alive)
	if current.stage=="report":return command=="finish"
	if current.stage=="loot":
		var quote:=loot_quote(game,current.place)
		# Passage is itself the prize at a gate or ferry, even with an empty cash box.
		return command=="flee" or (command=="take" and (quote.food>0 or quote.money>0 or rules(current.place).kind in ["toll","ferry"]))
	if current.stage=="standoff":return command=="surrender" or (command=="breakout" and game.state.bullets>0)
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
	# A trading party is wherever the party met it.
	if transient(id):return int(service(id).get("mile",0))
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
		var origin: String=where(game,report.origin)
		var noun: String=kind(report.origin).noun
		if report.identified:lines.append("Word reached here by day %d that your party %s %s %s. The people here will not trade with you or help you." % [arrival(game,report,place),act,noun,origin])
		else:lines.append("People here have heard that someone matching a description of your party stole from %s %s." % [noun,origin])
	return " ".join(lines)
## "at Fort Hall", or for a trading party, the stretch of road where it was met.
func where(game,place: String) -> String:
	if not transient(place):return "at "+game.route.nodes[place].name
	var region: String=place.get_slice(":",1)
	return "on the road through the "+str(game.context.data.regions[region].label) if game.context.data.regions.has(region) else "on the road"
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
	game.journal.append("Day %d · %s incident %d: %s; %s. Took %d lb food and $%.2f; fired %d shot(s)." % [game.state.day,kind(current.place).journal,current.id,current.attempt,resolution,current.food,current.cash_cents/100.0,current.shots])
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
		game.refresh_stop_offers()
		return true
	var place: String=target(game)
	# A trading party enters the record only once the party commits to an act against it.
	if incident().is_empty():add_transient(game,place)
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
		game.journal.append("Day %d · %s incident %d: %s; %s %s. Nearby staff %s." % [game.state.day,kind(place).journal,id,command,keeper.role,current.attempt,"were alerted" if store.alarmed else "did not notice the attempt"])
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
				# Soldiers stop the party instead of simply taking it.
				if rules(place).kind=="fort":
					current.stage="standoff"
					observe(game,current,"escape",true)
					game.journal.append("Day %d · Fort incident %d: soldiers block the escape." % [game.state.day,current.id])
					game.pending=menu(game)
					return true
				result(game,"captured")
				return true
			if rng.randf()<scene.escape_injury:wound(game,int(scene.injury_damage),1)
		observe(game,current,"escape",store.alarmed)
		result(game,"escaped" if game.state.status=="traveling" else "party_lost")
	elif command=="breakout":
		var current:=incident()
		var shots: int=mini(int(rules(place).breakout_shots),int(game.state.bullets))
		game._apply({"bullets":-shots})
		current.shots+=shots
		# Each shot may drop a soldier.
		for shot in range(shots):
			var targets: Array=living_staff(place).filter(func(uid):return uid!=owner_id(place))
			if targets.is_empty() or rng.randf()>=scene.shot_hit:continue
			var soldier: Dictionary=record.actors[targets[0]]
			soldier.health=0 if soldier.health<=40 or rng.randf()<scene.shot_fatal else int(soldier.health)-40
			# A soldier killed here carries nothing onward, as a keeper killed by the first shot never does.
			if soldier.health==0:current.knowledge.erase(soldier.uid)
		if not advance(game):return true
		var chance: float=bounded(float(rules(place).breakout),float(rules(place).breakout)+scene.edge,float(modifiers.floor),float(modifiers.ceiling))
		# Soldiers fire back either way; one or two of the party are hurt.
		wound(game,int(scene.injury_damage),1 if rng.randf()<0.5 else 2)
		if game.state.status!="traveling":
			result(game,"party_lost")
			return true
		if rng.randf()>=chance:
			result(game,"captured")
			return true
		observe(game,current,"escape",true)
		result(game,"escaped")
	if game.state.status=="traveling":game.pending=menu(game)
	return true
## Hurts the first active members, as the existing confrontation injuries do.
func wound(game,damage: int,count: int) -> void:
	for member in game.party_health.members:
		if count<=0:break
		if not game.party_health.is_active(member):continue
		count-=1
		game.party_health.affect(member,-damage,game.state.day,"confrontation injuries")
		if member.alive:game.party_health.begin_condition(int(member.id),"wound",int(game.state.day),1)
		game._collect_health_events()
		game.state.health=game.party_health.average_health()
		game.state.party_size=game.party_health.living_count()
		game._check_health()
func snapshot() -> Dictionary:return {"record":record.duplicate(true),"random":str(rng.state)}
## Converts a version 1 snapshot (one keeper record per place and an aggregate "staff:<place>"
## observer) into separate staff people. Anything malformed is returned unchanged for valid() to reject.
func upgrade(value: Variant,game=null) -> Variant:return add_venues(upgrade_v2(upgrade_v1(value)),game)
## Records made before a venue existed gain its untouched people and service. Food already bought there is counted conservatively, as in bind_party.
func add_venues(value: Variant,game) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=VERSION or not value.record.get("actors") is Dictionary or not value.record.get("services") is Dictionary:return value
	var r: Dictionary=value.record.duplicate(true)
	for place in venues():
		if r.services.has(place):continue
		for uid in staff_ids(place):
			if r.actors.has(uid):return value
			r.actors[uid]={"uid":uid,"place":place,"role":role(place,uid),"health":100}
		var offers: int=int(game.context.record.spent.get("post:"+place+"|buy_food",0)) if game!=null else 0
		r.services[place]={"owner":owner_id(place),"staff":staff_ids(place),"cash_cents":int(scenes[place].cash_cents),"food_taken":0,"food_sold":offers*int(scenes[place].food_lot),"alarmed":false}
	return {"record":r,"random":value.get("random")}
func upgrade_v2(value: Variant) -> Variant:
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
	if r.size()!=7 or not r.get("reports") is Array or r.get("version")!=VERSION or not r.get("people") is Dictionary or r.people.size()!=5 or not r.get("actors") is Dictionary or not r.get("services") is Dictionary or not r.services.keys().all(func(place):return scenes.has(place) and not TEMPLATE_KINDS.has(place) or transient(place)) or not r.get("incidents") is Array or r.incidents.size()>10000 or not r.get("active") is Dictionary:return false
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		var person: Variant=r.people.get(uid)
		if not person is Dictionary or person.size()!=2 or person.get("name")!=member.name or person.get("slot")!=member.id:return false
	var actor_count:=0
	var targeted: Array=r.services.keys().filter(transient)
	# Every trading party in the record was the target of an incident.
	if not targeted.all(func(place):return r.incidents.any(func(current):return current is Dictionary and current.get("place")==place)):return false
	for place in venues()+targeted:
		var lots: int=food_capacity(game,place)
		for uid in staff_ids(place):
			var actor: Variant=r.actors.get(uid)
			if not actor is Dictionary or actor.size()!=4 or actor.get("uid")!=uid or actor.get("place")!=place or actor.get("role")!=role(place,uid) or not whole(actor.get("health"),0,100):return false
			actor_count+=1
		var store: Variant=r.services.get(place)
		if not store is Dictionary or store.size()!=(7 if transient(place) else 6) or (transient(place) and not whole(store.get("mile"),0,int(game.state.miles))) or store.get("owner")!=owner_id(place) or store.get("staff")!=staff_ids(place) or not whole(store.get("cash_cents"),0,int(rules(place).cash_cents)) or not whole(store.get("food_taken"),0,lots) or not whole(store.get("food_sold"),0,lots) or not store.get("alarmed") is bool:return false
		if r.actors[owner_id(place)].health==0 and not store.alarmed:return false
		if store.food_taken+store.food_sold>lots:return false
		var offers: int=game.context.record.spent.get(market_prefix(place)+"|buy_food",0)
		if store.food_sold<offers*40 or store.food_sold>offers*int(rules(place).food_lot):return false
	if r.actors.size()!=actor_count:return false
	var food_totals: Dictionary={}
	var cash_totals: Dictionary={}
	var previous_day: int=-1
	for index in range(r.incidents.size()):
		var current: Variant=r.incidents[index]
		if not current is Dictionary or current.size()!=12 or current.get("id")!=index+1 or not whole(current.get("day"),0,int(game.state.day)) or not (current.get("place") is String and r.services.has(current.place) and not TEMPLATE_KINDS.has(current.place)) or current.get("target")!=owner_id(current.place):return false
		if current.get("action") not in ["theft","robbery","shoot","raid"] or current.get("attempt") not in ATTEMPTS or current.get("stage") not in STAGES or current.get("resolution") not in RESOLUTIONS:return false
		if current.day<previous_day:return false
		previous_day=int(current.day)
		if current.attempt not in {"theft":["unseen","noticed"],"robbery":["complied","resisted"],"shoot":["missed","wounded","killed"],"raid":["raided"]}[current.action]:return false
		if (current.stage in ["loot","escape","standoff"])!=(current.resolution==""):return false
		if current.stage=="standoff" and rules(current.place).kind!="fort":return false
		if current.stage=="loot" and current.attempt not in ["unseen","complied","killed","raided"]:return false
		if current.attempt!="unseen" and not r.services[current.place].alarmed:return false
		if current.attempt=="killed" and r.actors[owner_id(current.place)].health!=0:return false
		for key in ["food","cash_cents","shots"]:
			if not whole(current.get(key),0,100000):return false
		# Only soldiers force the extra shots of a breakout.
		var extra: int=int(current.shots)-(1 if current.action=="shoot" else 0)
		if extra<0 or extra>(int(rules(current.place).breakout_shots) if rules(current.place).kind=="fort" else 0) or not current.get("knowledge") is Dictionary or current.knowledge.size()>5+staff_ids(current.place).size():return false
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
	for place in venues()+targeted:
		if int(food_totals.get(place,0))!=r.services[place].food_taken or int(cash_totals.get(place,0))+r.services[place].cash_cents!=rules(place).cash_cents:return false
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
