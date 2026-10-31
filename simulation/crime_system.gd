extends RefCounted
## Persistent local people, finite loot and staged incidents. No UI or global RNG.
const COMMANDS=["theft","robbery","shoot","assault","raid","take","flee","breakout","surrender","finish","payoff","back","ride","wait","bail","vouch","jailbreak","mask"]
const STAGES=["loot","escape","standoff","custody","report","done"]
const ATTEMPTS=["unseen","noticed","complied","resisted","missed","wounded","killed","raided","caught"]
const RESOLUTIONS=["","left","escaped","captured","surrendered","party_lost","tried","paid"]
const VERSION:=10
const FACTS=["attempt","loot","escape"]
## Venue wording. A store yields food and cash; a toll gate or ferry yields its cash box and passage.
const KINDS={
	"pursuers":{"journal":"Wanted","noun":"the pursuers"},
	"jail":{"journal":"Jailbreak","noun":"the guards"},
	"store":{"journal":"Store","noun":"the store","theft":"Take supplies without paying · 1 day","raid":"Enter the store and search for remaining supplies · 1 day"},
	"toll":{"journal":"Toll gate","noun":"the toll gate","theft":"Slip the wagons past the gate without paying · 1 day","raid":"Search the gatekeeper's cabin for the toll money · 1 day","take":"Take $%.2f from the toll box and pass the gate · 1 day","passage":"the gate will be behind you"},
	"fort":{"journal":"Fort","noun":"the army post","theft":"Take rations from the commissary tent · 1 day","raid":"Search the commissary tent for rations and the cash box · 1 day"},
	"traders":{"journal":"Trader","noun":"a trading party","theft":"Take goods from the traders' packs without paying · 1 day","raid":"Search the traders' packs · 1 day"},
	"emigrants":{"journal":"Emigrant","noun":"an emigrant family","theft":"Take from their camp while they sleep · 1 day","raid":"Search their wagon · 1 day"},
	"ferry":{"journal":"Ferry","noun":"the ferry","theft":"Cast off with the ferry while the crew is away · 1 day","raid":"Take the ferry and the crew's cash box · 1 day","take":"Take $%.2f and the ferry · 1 day","passage":"the ferry will be yours to work across"},
	"household":{"journal":"Household","noun":"a Native household","theft":"Take from the household's stores unseen · 1 day","raid":"Search the household's lodges for what is left · 1 day"}}
## A Native household is the people at one of the existing visits, keyed by the route stop it lives at.
const HOUSEHOLD:="native:"
## Attempts that reach the loot stage; only these can win passage at a gate or ferry.
const LOOTING=["unseen","complied","killed","raided"]
## Sparse named bonds between companions, and how each companion answers an attack on another.
const BONDS=["family","partner","friend","rival"]
const CLOSE=["family","partner","friend"]
const RESPONSES=["stood by","objected","fled","retaliated"]
const ATTACK_RESULTS=["missed","wounded","killed"]
## What a companion at the betrayal point does: robs the wagon and slips away, or shoots the leader first.
const BETRAYAL_RESULTS={"theft":["stole","stopped"],"attack":["missed","wounded","killed"]}
## The one traders scene is a template: each passing trading party, named by its market key, gets its own people when first targeted.
const TRADERS:="passing_traders"
## Emigrant families camped near the road work the same way, named by their camp.
const EMIGRANTS:="passing_emigrants"
const TEMPLATES={"passing:":TRADERS,"emigrants:":EMIGRANTS,"wanted_posse:":"posse","wanted_regulators:":"regulators","wanted_hunters:":"bounty_hunters","jail_county:":"jail_county","jail_army:":"jail_army","jail_company:":"jail_company"}
const TEMPLATE_KINDS={TRADERS:"traders",EMIGRANTS:"emigrants","posse":"pursuers","regulators":"pursuers","bounty_hunters":"pursuers","jail_county":"jail","jail_army":"jail","jail_company":"jail"}
const Wanted=preload("res://simulation/wanted_system.gd")
const Detention=preload("res://simulation/detention.gd")
var wanted_data: Dictionary={}
var detention_data: Dictionary={}
const Remains=preload("res://simulation/remains.gd")
var scenes: Dictionary={}
var modifiers: Dictionary={}
var news_rules: Dictionary={}
var recognition: Dictionary={}
var reputation: Dictionary={}
var companion_rules: Dictionary={}
var unarmed_data: Dictionary={}
var remains_rules: Dictionary={}
var miles: Dictionary={}
var record: Dictionary={}
var rng:=RandomNumberGenerator.new()
var error: String=""
func _init():load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json")))
func load_data(value: Variant) -> bool:
	error="Invalid crime scene rules"
	if not value is Dictionary or value.get("version")!=1 or not value.get("scenes") is Dictionary or value.scenes.is_empty() or not value.get("modifiers") is Dictionary:return false
	if not Wanted.valid_rules(value.get("wanted")):return false
	wanted_data=value.wanted.duplicate(true)
	if not Detention.valid_rules(value.get("detention")):return false
	detention_data=value.detention.duplicate(true)
	var unarmed: Variant = value.get("unarmed")
	if not unarmed is Dictionary:return false
	for key in ["hit_penalty","fatal_factor","mishap_chance"]:
		if not number(unarmed.get(key)) or unarmed[key]<0 or unarmed[key]>1:return false
	if not whole(unarmed.get("mishap_damage"),1,100):return false
	unarmed_data=unarmed.duplicate(true)
	var mods: Dictionary=value.modifiers
	if not mods.get("note") is String:return false
	for key in ["experience_step","stealth_step","staff_step","poor_condition_penalty","fair_condition_penalty","small_party_penalty","floor","ceiling"]:
		if not number(mods.get(key)) or mods[key]<0 or mods[key]>1:return false
	for key in ["experience_cap","minimum_able"]:
		if not whole(mods.get(key),0,5):return false
	var party: Variant=value.get("companions")
	if not party is Dictionary or not party.get("note") is String or not party.get("bond_chances") is Dictionary or party.bond_chances.keys()!=BONDS:return false
	var total:=0.0
	for kind in BONDS:
		if not number(party.bond_chances[kind]) or party.bond_chances[kind]<0:return false
		total+=float(party.bond_chances[kind])
	if total>1:return false
	for key in ["hit","fatal","participant_step","retaliate_hit"]:
		if not number(party.get(key)) or party[key]<0 or party[key]>1:return false
	for key in ["wound_damage","retaliate_damage"]:
		if not whole(party.get(key),1,100):return false
	var betrayal: Variant=party.get("betrayal")
	if not betrayal is Dictionary or betrayal.size()!=7 or not ["daily","food_share","cash_share","bullet_share","notice","ambush_hit","guard_step"].all(func(key):return number(betrayal.get(key)) and betrayal[key]>=0 and betrayal[key]<=1):return false
	var bodies: Variant=Remains.load_rules(value.get("remains"))
	if bodies==null:return false
	var news: Variant=value.get("reports")
	if not news is Dictionary or not news.get("note") is String or not whole(news.get("delay_days"),0,30) or not whole(news.get("miles_per_day"),1,200):return false
	if not valid_recognition(value.get("recognition")):return false
	var fame: Variant=value.get("reputation")
	if not fame is Dictionary or fame.size()!=4 or not fame.get("note") is String or not number(fame.get("step")) or fame.step<0 or fame.step>0.1 or not number(fame.get("cap")) or fame.cap<0 or fame.cap>0.3 or not fame.get("kinds") is Array or not fame.kinds.all(func(k):return KINDS.has(k) and k not in ["fort","pursuers","jail","household"]):return false
	if mods.floor>=mods.ceiling or mods.experience_step*mods.experience_cap>0.25 or mods.stealth_step>mods.experience_step:return false
	for place in value.scenes:
		var scene: Variant=value.scenes[place]
		if not place is String or not scene is Dictionary:return false
		for key in ["title","note"]:
			if not scene.get(key) is String or scene[key].is_empty():return false
		if not KINDS.has(scene.get("kind")) or not scene.get("wagon_access") is bool:return false
		for key in ["cash_cents","food_lot","loot_limit","injury_damage"]:
			# A household carries no cash; every other venue keeps a cash box.
			if not whole(scene.get(key),0 if key in ["food_lot","loot_limit"] or (key=="cash_cents" and scene.get("kind")=="household") else 1,100000):return false
		# Only stores sell or hold food; a gate or ferry holds only its cash box.
		if (scene.kind in TEMPLATE_KINDS.values())!=TEMPLATE_KINDS.has(place) or (TEMPLATE_KINDS.has(place) and scene.kind!=TEMPLATE_KINDS[place]):return false
		if (scene.kind=="household")!=place.begins_with(HOUSEHOLD) or (scene.kind=="household" and scene.cash_cents!=0):return false
		if (scene.kind=="emigrants")!=scene.has("every_days") or scene.has("every_days")!=scene.has("window_days"):return false
		if scene.kind=="emigrants" and (not whole(scene.every_days,2,60) or not whole(scene.window_days,1,scene.every_days-1)):return false
		# Food lots match what each venue sells: a post's 200 lb lot, a passing party's 50 lb lot.
		if scene.food_lot!={"store":200,"traders":50}.get(scene.kind,0) or scene.loot_limit>(0 if scene.kind in ["toll","ferry"] else 200) or scene.injury_damage>100:return false
		# A fort's commissary holds its own stock; soldiers who stop an escape force a standoff.
		var fort_keys: Array=["food_stock","breakout","breakout_shots"]
		for key in fort_keys:
			if scene.has(key)!=((scene.kind in ["fort","pursuers","household","jail"] and key!="food_stock") or scene.kind=="fort" or (key=="food_stock" and scene.kind=="emigrants")):return false
		if scene.has("food_stock") and not whole(scene.food_stock,1,2000):return false
		if scene.kind in ["fort","pursuers","household","jail"] and ( not number(scene.breakout) or scene.breakout<0 or scene.breakout>1 or not whole(scene.breakout_shots,1,5)):return false
		# Only soldiers and a household's kin ride after a party; a chase ends in the same standoff as a blocked escape.
		if scene.has("pursuit"):
			var chase: Variant=scene.pursuit
			if scene.kind not in ["fort","household"] or not chase is Dictionary or chase.size()!=3 or not chase.get("note") is String or not whole(chase.get("days"),1,14) or not number(chase.get("daily")) or chase.daily<0 or chase.daily>1:return false
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
	recognition=value.recognition.duplicate(true)
	reputation=fame.duplicate(true)
	companion_rules=party.duplicate(true)
	remains_rules=bodies
	error=""
	return true
const RECOGNIZED_ACTS=["theft","robbery","raid","shoot","assault","pursuit","wanted","killed","tale"]
const MASKS=["covered","hidden","slipped","known"]
func valid_recognition(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=5 or not value.get("note") is String or not value.get("acts") is Dictionary or value.acts.size()!=RECOGNIZED_ACTS.size():return false
	if not RECOGNIZED_ACTS.all(func(act):return number(value.acts.get(act)) and value.acts[act]>=0 and value.acts[act]<=1):return false
	if not ["masked_factor","mask_slip"].all(func(key):return number(value.get(key)) and value[key]>=0 and value[key]<=1):return false
	return whole(value.get("half_life_days"),1,3650)
func start(seed_value: int) -> void:
	rng.seed=seed_value ^ 0x4352494d
	record={"version":VERSION,"people":{},"actors":{},"services":{},"incidents":[],"active":{},"reports":[],"bonds":[],"attacks":[],"remains":[],"human_food":[],"meals":{},"betrayals":[],"bounties":[]}
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
func household(place: String) -> bool:return place.begins_with(HOUSEHOLD) and scenes.has(place)
## The route stop a fixed venue stands at. A household shares its stop with any post there but is a separate venue.
func node_of(place: String) -> String:return place.trim_prefix(HOUSEHOLD) if household(place) else place
## How news and VILLAINY lists name a venue: a household by its own title, everything else by its kind.
func venue_noun(place: String) -> String:return str(rules(place).title).to_lower() if household(place) else str(kind(place).noun)
## Why the household at a Native visit will not deal with the party, or "" when it will. Only what they saw or heard counts:
## an unseen theft changes nothing until word of it arrives.
func household_refusal(game,site: String) -> String:
	var place: String=HOUSEHOLD+site
	# A route that never reaches this visit has no household to refuse.
	if not scenes.has(place) or not game.route.nodes.has(site):return ""
	if record.services.has(place) and owner(place).health==0:return "The %s is dead. Nobody of the household will deal with your party." % role(place,owner_id(place))
	if record.services.has(place) and service(place).alarmed:return "This household saw what your party did. They will not trade, work, guide or carry for you."
	if driven_out(game,site):return "Their council drove your party out of this country. Nobody here will deal with you."
	if refuses(game,place):return news_text(game,place)
	return ""
## A council's banishment covers every Native visit in the same country as the household that tried the party.
func driven_out(game,site: String) -> bool:
	var country: String=str(game.route.nodes.get(site,{}).get("hunting_region",""))
	return record.incidents.any(func(item):return item.get("sentence",{}).get("authority","")=="council" and item.sentence.kind in ["driven_out","price"] and str(game.route.nodes.get(node_of(item.place),{}).get("hunting_region",""))==country)
## Whether a venue holds anything to steal or demand; a pilot or a portage crew has only themselves.
func stocked(game,place: String) -> bool:
	if not household(place):return true
	var goods: Dictionary=game.RobberyDemand.stock(game,place)
	goods.erase("cash_cents")
	return goods.values().any(func(amount):return int(amount)>0)
## Passage won at a toll gate or ferry: the party took the cash box or the boat and got away with it, or killed the gatekeeper.
func passage(place: String) -> bool:
	if not scenes.has(place) or scenes[place].kind not in ["toll","ferry"]:return false
	# Nobody is left to collect a toll.
	if scenes[place].kind=="toll" and owner(place).health==0:return true
	return record.incidents.any(func(current):return current.place==place and current.resolution in ["left","escaped"] and current.attempt in LOOTING and current.knowledge.values().any(func(facts):return "loot" in facts))
## A ferry the party took, or whose crew it attacked or has heard about it, will not carry the party.
func ferry_refused(game,place: String) -> bool:
	if scenes.has(place):return scenes[place].kind=="ferry" and (closed(place) or refuses(game,place) or passage(place))
	# A hired ferry with no crime scene of its own (Green River) cannot be robbed, but its crew hears the same news.
	return game.route.nodes.has(place) and game.route.nodes[place].has("ferry_dollars") and refuses(game,place)
func seized_risk(game,place: String) -> float:
	return float(scenes[place].seized_risk_high if game.state.river_stage=="high" else scenes[place].seized_risk_low)
## Untargeted trading parties are read as fresh people and stock without entering the record.
func actor(place: String,uid: String) -> Dictionary:return record.actors[uid] if record.actors.has(uid) else fresh_actor(place,uid)
func owner(place: String) -> Dictionary:return actor(place,owner_id(place))
## Cosmetic names derive from actor identity on a separate RNG; no incident rolls are consumed.
func display_name(game,place: String,uid: String) -> String:
	# The household keeps the contact's own authored identity; no invented personal names.
	if household(place):
		if uid==owner_id(place):return str(game.native_encounters.data.sites[node_of(place)].contact.label)
		return "%s · %s" % [str(rules(place).title).trim_prefix("An ").trim_prefix("A "),role(place,uid)]
	var random:=RandomNumberGenerator.new()
	random.seed=int(game.state.seed) ^ int(uid.hash()) ^ 0x4e414d45
	var names: Array=game.characters.catalog.data.first_names
	var title: String="toll collector" if rules(place).kind=="toll" and uid==owner_id(place) else role(place,uid)
	return "%s · %s" % [names[random.randi_range(0,names.size()-1)],title]
func attack_target(game,place: String) -> String:
	return str(incident().get("target",game.pending.get("crime_target",owner_id(place))))
func local_places(game,stop: Dictionary) -> Array:
	var places_here: Array=[]
	var landmark: String=game.state.landmark
	if stop.get("landmark","")==landmark and scenes.has(landmark) and not TEMPLATE_KINDS.has(landmark) and staffed(game,landmark):places_here.append(landmark)
	var at_post: bool=stop.has("landmark") and game.route.nodes[landmark].get("trade_bulk",false)
	if not at_post:
		var market: Dictionary=game.context.market(game)
		if market.available and not market.post:places_here.append(market.key)
	var nearby_camp:=camp(game)
	if not nearby_camp.is_empty():places_here.append(nearby_camp)
	# The household at a Native visit, while anyone of it is left.
	if stop.get("landmark","")==landmark and scenes.has(HOUSEHOLD+landmark) and not living_staff(HOUSEHOLD+landmark).is_empty():places_here.append(HOUSEHOLD+landmark)
	return places_here
## How a place reads in the VILLAINY lists: the post's name for a fixed venue, the scene's own title on the road.
func place_label(game,place: String) -> String:
	if transient(place):return rules(place).title
	if household(place):return "%s · %s" % [game.route.nodes[node_of(place)].name,rules(place).title]
	return "%s · %s" % [game.route.nodes[place].name,str(rules(place).title).trim_prefix("The ")]
func local_targets(game) -> Array:
	if not game.can_service() or not incident().is_empty():return []
	var people: Array=[]
	for place in local_places(game,game.pending):
		for uid in living_staff(place):people.append({"uid":uid,"place":place,"name":display_name(game,place,uid)})
	return people

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
	if game.pending.get("crime_menu",false) and game.pending.has("crime_place"):return game.pending.crime_place
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
	var node: Dictionary=game.route.nodes[node_of(place)]
	return not node.has("construction_from_month") or int(game.calendar().year)!=1848 or int(game.calendar().month)>=int(node.construction_from_month)
func closed(place: String) -> bool:
	return record.services.has(place) and (service(place).alarmed or owner(place).health==0)
func food_capacity(game,place: String) -> int:
	if rules(place).has("food_stock"):return int(rules(place).food_stock)
	# A household holds exactly the preserved provisions its visit sells, and no more.
	if household(place):
		var total:=0
		for offer in game.native_encounters.data.sites[node_of(place)].offers:
			if offer.item=="food":total+=int(offer.amount)*int(offer.lots)
		return total
	# A passing party carries its own load of food, seeded per meeting.
	if trader(place) and game!=null:return int(game.context.barter_goods(game,place).stock.get("food",0))
	return int(game.context.data.passing_lots if trader(place) else game.context.data.post_lots)*int(rules(place).food_lot)
func food_left(game,place: String) -> int:
	# Food bought from traders not yet in the record still left their packs.
	if household(place):return maxi(0,food_capacity(game,place)-game.native_encounters.food_sold(node_of(place))-int(service(place).food_taken))
	var sold: int=int(service(place).food_sold) if record.services.has(place) else int(game.context.record.spent.get(market_prefix(place)+"|buy_food|units",int(game.context.record.spent.get(market_prefix(place)+"|buy_food",0))*int(rules(place).food_lot)))
	# An emigrant family's food traded away on a peaceful visit is no longer in their wagon.
	if rules(place).kind=="emigrants":sold+=int(game.context.record.spent.get(place+"|barter_food",0))*int(game.context.data.emigrant_camp.barter_food)+int(game.context.record.spent.get(place+"|buy_food|units",0))
	return maxi(0,food_capacity(game,place)-sold-int(service(place).food_taken))
func market_prefix(place: String) -> String:return place if trader(place) else "post:"+place
func consume_trade(choice: Dictionary) -> void:
	for place in places():
		if choice.get("market_key","")==market_prefix(place)+"|buy_food":service(place).food_sold+=maxi(0,int(choice.effects.get("food",0)))
func can_trade(game,choice: Dictionary) -> bool:
	var key: String=choice.get("market_key","")
	if key.begins_with("post:") and refuses(game,key.get_slice("|",0).trim_prefix("post:")):return false
	# Passing traders hear the same news as the posts and refuse a party named in it.
	if key.begins_with("passing:") and refuses(game,key.get_slice("|",0)):return false
	# A camp the party wronged, or one that has heard of it, will not deal with it.
	if key.begins_with("emigrants:"):
		var camp_id: String=key.get_slice("|",0)
		if record.services.has(camp_id) or refuses(game,camp_id):return false
		if key.ends_with("|barter_food") and int(choice.effects.get("food",0))>food_left(game,camp_id):return false
	for place in places():
		if key.begins_with(market_prefix(place)+"|"):
			if closed(place):return false
			if key.ends_with("|buy_food") and int(choice.effects.get("food",0))>food_left(game,place):return false
	return true
func incident() -> Dictionary:
	return {} if record.active.is_empty() else record.incidents[int(record.active.id)-1]
func loot_quote(game,place: String) -> Dictionary:
	if incident().has("demand"):return game.RobberyDemand.loot(game,incident())
	var room:=maxi(0,floori(game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)))
	var current:=incident()
	# Theft is carried away quietly. The commissary lies inside the post; roadside
	# parties and ordinary stores allow loading alongside the wagon after a holdup.
	var alongside: bool=game.state.vehicle=="wagon" and rules(place).wagon_access and current.get("action","")!="theft"
	var hauling: int=game.hauling_capacity("murder" if current.get("action","") in ["shoot","assault"] else "robbery")
	var food_space:=floori(mini(room,room if alongside else hauling)/float(game.provisions.data.weights_lb.food))
	return {"food":mini(mini(food_left(game,place),int(rules(place).loot_limit)),food_space) if rules(place).kind in ["store","fort","traders","emigrants","household"] else 0,"money":service(place).cash_cents if not current.is_empty() and current.action!="theft" else 0,"wagon_access":alongside,"haul_limit_lb":hauling}
func option(label: String,command: String) -> Dictionary:
	return {"label":label,"crime_command":command,"effects":{},"result":""}
## Distinct targets the party got away from, plus clean defensive victories. Capped; the same target never counts twice.
func experience(game) -> int:
	var targets: Array=[]
	for current in record.incidents:
		if current.resolution in ["left","escaped"] and current.attempt!="noticed" and current.attempt!="resisted" and current.attempt!="missed" and current.attempt!="caught" and current.target not in targets:targets.append(current.target)
	return mini(targets.size()+game.combat.victories()+(int(game.characters.benefits.outlaw_experience) if game.characters.available(game,"Outlawry") else 0),int(modifiers.experience_cap))
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
	return {"edge":edge,"fame":fame(game,place),
		"theft_success":bounded(float(scene.theft_success),float(scene.theft_success)+missing*float(modifiers.staff_step)+experience(game)*float(modifiers.stealth_step),low,high),
		"compliance":bounded(float(scene.compliance),float(scene.compliance)+edge+fame(game,place),low,high),
		"shot_hit":bounded(float(scene.shot_hit),float(scene.shot_hit)+edge,low,high),
		"escape_capture":bounded(float(scene.escape_capture),float(scene.escape_capture)-edge,low,high),
		"escape_injury":bounded(float(scene.escape_injury),float(scene.escape_injury)-edge,low,high),
		"shot_fatal":float(scene.shot_fatal),"injury_damage":int(scene.injury_damage)}
## A bare-faced party whose name has reached ordinary folk (not soldiers, posses, jailers or a household with its
## council behind it) is believed when it threatens: victims give in more often. A masked party is nobody.
func fame(game,place: String) -> float:
	if game.pending.get("crime_masked",false) or rules(place).kind not in reputation.kinds:return 0.0
	var named: float=0.0
	for item in Wanted.evidence(self,game,place):
		if item.identified and item.origin!=place:named+=float(item.weight)
	return minf(float(reputation.cap),named*float(reputation.step))
## Modifiers cannot push a value past the floor/ceiling, but authored extremes are kept.
func bounded(base: float,value: float,low: float,high: float) -> float:return clampf(value,minf(base,low),maxf(base,high))
func condition(actor: Dictionary) -> String:
	return "dead" if actor.health==0 else ("wounded" if actor.health<100 else "uninjured")
func menu(game) -> Dictionary:
	var place: String=target(game)
	var keeper: Dictionary=actor(place,attack_target(game,place))
	var scene: Dictionary=rules(place)
	var words: Dictionary=kind(place)
	var current:=incident()
	if current.get("stage","")=="custody":return Detention.menu(self,game,current)
	if current.get("action","")=="wanted":return Wanted.menu(self,game,current)
	var text: String="Your active companions are present and can observe your actions. Theft or an attack uses one day and ordinary meals. A shot spends one bullet. Nearby staff may resist."
	var options: Array=[]
	if current.is_empty():
		if scene.kind=="emigrants":text+="\nHead of the family: %s. Others with them: %d. Food in their wagon: %d lb. Cash: $%.2f. Their company is camped within earshot." % [condition(keeper),living_staff(place).size()-1,food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="traders":text+="\nLead trader: %s. Food in their packs: %d lb. Cash: $%.2f. Nobody else is in sight on this stretch of road." % [condition(keeper),food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="store":text+="\nKeeper: %s. Accessible food stock: %d lb. Cash stash: $%.2f." % [condition(keeper),food_left(game,place),service(place).cash_cents/100.0]
		elif scene.kind=="household":text+="\n%s: %s. Others of the household nearby: %d. Food in their stores: %d lb. They carry no cash. They are on home ground: they resist, remember faces and may ride after the party." % [display_name(game,place,keeper.uid),condition(keeper),living_staff(place).size()-1,food_left(game,place)]
		elif scene.kind=="fort":text+="\n%s: %s. Soldiers on duty nearby: %d. Commissary rations: %d lb. Cash box: $%.2f. If soldiers stop an escape, the party must surrender or shoot its way out." % [keeper.role.capitalize(),condition(keeper),living_staff(place).size()-1,food_left(game,place),service(place).cash_cents/100.0]
		else:text+="\n%s: %s. Cash box: $%.2f." % [keeper.role.capitalize(),condition(keeper),service(place).cash_cents/100.0]
		text+="\nStaff on hand: %d. Your party's condition: %s. Fit, willing participants: %d. Prior successful jobs counted: %d of %d." % [living_staff(place).size(),party_condition(game),able(game,"robbery"),experience(game),int(modifiers.experience_cap)]
		if keeper.health>0:
			options=[option(words.theft,"theft"),option("Threaten the %s with your gun · 1 day" % keeper.role,"robbery"),option("Shoot at the %s · 1 bullet, 1 day" % keeper.role,"shoot"),option("Attack the %s unarmed · 1 day, higher injury risk" % keeper.role,"assault")]
		else:options=[option(words.raid,"raid")]
		# A pilot or a portage crew has nothing to carry off; only an attack is possible.
		if not stocked(game,place):options=options.filter(func(choice):return choice.crime_command in ["shoot","assault"])
		var masked: bool=game.pending.get("crime_masked",false)
		text+="\n"+("Your faces are covered with kerchiefs. If you get away, word will describe a masked party, not name yours; a slipped mask, people who have dealt with you here, or anyone who catches you will still know you." if masked else "Your faces are bare. Anyone who sees you can name your party.")
		if masked and faces_seen(game,place):text+=" These people have seen your faces already; a kerchief will not fool them."
		if fame(game,place)>0:text+="\nWord of your party's deeds has reached these people. Bare-faced, a threat from you will be believed more readily; masked, you are nobody."
		options.append(option("Take off the kerchiefs" if masked else "Tie kerchiefs over your faces","mask"))
		if game.pending.has("crime_target"):
			text="Target: %s (%s).\nNearby staff: %d. Your companions can observe this. An attack uses one day and meals; a shot spends one bullet. Unarmed attacks have higher injury risk. Staff may resist or pursue the party." % [display_name(game,place,keeper.uid),condition(keeper),living_staff(place).size()]
			text+="\n"+("Your faces are covered with kerchiefs." if masked else "Your faces are bare.")
			options=options.filter(func(choice):return choice.crime_command in ["shoot","assault","mask"])
	elif current.stage=="loot":
		var loot:=loot_quote(game,place)
		if current.has("demand"):
			if current.action=="theft":
				text="Unseen so far. To take: "+game.RobberyDemand.describe(current.demand)+". Carrying it off uses one day. "+str(loot.get("message",""))
				options=[option("Carry off the goods · 1 day","take"),option("Leave it all and slip away","flee")]
			else:
				text=current.attempt.capitalize()+". Demand: "+game.RobberyDemand.describe(current.demand)+". Collecting uses one day. Witnesses and escape risks still apply. "+str(loot.get("message",""))
				options=[option("Collect the demanded goods · 1 day","take"),option("Leave the demand and try to get away","flee")]
		elif scene.kind in ["toll","ferry"]:
			text="%s. You can take $%.2f from the cash box, and %s. Doing it uses one more day. Nearby staff can respond as you leave." % [current.attempt.capitalize(),loot.money/100.0,words.passage]
			options=[option(words.take % (loot.money/100.0),"take"),option("Give it up and try to get away","flee")]
		else:
			text="%s. You can take up to %d lb food and $%.2f from what remains. Cargo space limits food; collecting it uses one more day. Nearby staff can respond as you leave." % [current.attempt.capitalize(),loot.food,loot.money/100.0]
			options=[option("Take %d lb food and $%.2f · 1 day" % [loot.food,loot.money/100.0],"take"),option("Leave the supplies and try to get away","flee")]
	elif current.stage=="escape":
		text="%s. Staff have been alerted. Attempting escape costs one day; you may be injured or captured. Surrender brings a trial; a known killing can mean hanging." % current.attempt.capitalize()
		options=[option(("Ride for it · 1 day" if game.Mounts.mounted(Wanted.flight_plan(game)) else "Try to escape · 1 day"),"flee"),option("Surrender","surrender")]
		if Wanted.can_ride_off(game):options.append(option(Wanted.ride_label(game),"ride"))
	elif current.stage=="standoff":
		var shots: int=mini(int(scene.breakout_shots),int(game.state.bullets))
		var captors: String="Men of the household" if household(place) else "Soldiers"
		if Detention.jailbreak_incident(self,current):
			text="%s stand between your party and the prisoners. Breaking them out is a fight: some of you will likely be hurt, the prisoners have no arms, and you may all be taken. Surrender brings a trial for this too." % ("The household's kin" if household(place) else str(rules(place).title))
			options=[option("Break them out · fight","breakout"),option("Surrender","surrender")]
		else:
			text=("%s from %s rode after you and have caught up. " % [captors,game.route.nodes[node_of(place)].name] if current.action=="pursuit" else "%s have blocked the way out. " % captors)+"Shooting your way out spends up to %d bullets; some of you will likely be hurt, and you may still be taken. Surrender brings a trial; a known killing can mean hanging." % int(scene.breakout_shots)
			options=[option("Shoot your way out · %d bullet(s)" % shots,"breakout"),option("Surrender","surrender")]
		if current.action=="pursuit":
			options.append(option("Flee the detachment · 1 day, risk of capture","flee"))
			if Wanted.can_ride_off(game):options.append(option(Wanted.ride_label(game),"ride"))
	elif current.has("sentence"):
		text=current.sentence.text
		options=[option("Acknowledge the sentence","finish")]
	else:
		text="Incident %d: %s; %s. Food taken: %d lb. Cash taken: $%.2f. Shots: %d. People here who saw it: %d. See the journal and party records for injuries and reactions." % [current.id,current.attempt,current.resolution,current.food,current.cash_cents/100.0,current.shots,local_witnesses(current).size()]
		options=[option("Acknowledge the outcome","finish")]
	if current.has("demand") and current.action=="theft":
		if current.stage!="loot":text+="\nMeant to take: "+game.RobberyDemand.describe(current.demand)
	elif current.has("demand"):
		text+="\nDemand: "+game.RobberyDemand.describe(current.demand)
		if current.stage=="loot":text+="\nOnly the agreed demand can be collected. Extra goods require another dangerous attempt."
	options.append(option(({"traders":"Leave the traders alone","emigrants":"Leave the family be"}.get(scene.kind,"Back to the stop")) if current.is_empty() else "Encounter in progress","back"))
	var result_menu: Dictionary={"id":"crime","crime_menu":true,"service_menu":true,"title":scene.title,"text":text,"choices":options}
	# A place picked from the VILLAINY lists stays picked while the preview is open.
	if game.pending.has("crime_place"):result_menu["crime_place"]=place
	if current.is_empty() and game.pending.get("crime_masked",false):result_menu["crime_masked"]=true
	if game.pending.has("crime_target"):
		result_menu["crime_target"]=keeper.uid
		result_menu["crime_place"]=place
		if current.is_empty():result_menu.title="Attack "+display_name(game,place,keeper.uid)
	return result_menu
func can_choose(game,command: String) -> bool:
	var current:=incident()
	if current.get("stage","")=="custody":return Detention.can_choose(self,game,current,command)
	if current.get("action","")=="wanted":return Wanted.can_choose(self,game,current,command)
	if current.is_empty():
		if command in ["back","mask"]:return true
		if record.incidents.size()>=10000:return false
		var place:=target(game)
		if game.pending.has("crime_target") and command not in ["shoot","assault"]:return false
		var alive: bool=actor(place,attack_target(game,place)).health>0
		return (command in ["theft","robbery","shoot","assault"] and alive and (command in ["theft","assault"] or game.can_fire())) or (command=="raid" and not alive)
	if current.stage=="report":return command=="finish"
	if current.stage=="loot":
		var quote:=loot_quote(game,current.place)
		# Passage is itself the prize at a gate or ferry, even with an empty cash box.
		return command=="flee" or (command=="take" and (quote.food>0 or quote.money>0 or not quote.get("goods",{}).is_empty() or rules(current.place).kind in ["toll","ferry"]))
	if current.stage=="standoff":return command=="surrender" or (command=="flee" and current.action=="pursuit") or (command=="ride" and current.action=="pursuit" and Wanted.can_ride_off(game)) or (command=="breakout" and game.can_fire())
	return current.stage=="escape" and (command in ["flee","surrender"] or (command=="ride" and Wanted.can_ride_off(game)))
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
	return {"incident":current.id,"origin":current.place,"day":day,"senders":local_witnesses(current),"facts":facts,"identified":current.action!="theft" and current.get("mask","")!="hidden"}
## Guide miles from the start of the road to each stop.
func mile(game,id: String) -> int:
	if miles.is_empty():miles=game.route.node_miles()
	# A trading party is wherever the party met it; one not yet in the record is here.
	if transient(id):return int(record.services[id].mile) if record.services.has(id) else int(game.state.miles)
	return int(miles.get(node_of(id),0))
## News moves along the road with other travelers and traders, in both directions.
func arrival(game,report: Dictionary,place: String) -> int:
	if place==report.origin:return int(report.day)
	return int(report.day)+int(news_rules.delay_days)+ceili(absi(mile(game,place)-mile(game,report.origin))/float(news_rules.miles_per_day))
func heard(game,place: String) -> Array:
	return record.reports.filter(func(report):return arrival(game,report,place)<=int(game.state.day))
## What a companion who left the party tells others: only the acts they object to, that they saw for themselves.
func tale(game,slot: int) -> Dictionary:
	var uid:=person_id(int(game.state.seed),slot)
	var member: Dictionary=game.party_health.members[slot]
	var objects:=func(action):return game.characters.response(slot,action) in ["forbidden","reluctant","disapproved"]
	var acts: Array=record.incidents.filter(func(current):return current.knowledge.has(uid) and (current.action not in ["pursuit","wanted"] or int(current.shots)>0) and objects.call("murder" if current.action in ["shoot","assault","pursuit","wanted"] or current.attempt=="killed" or not current.get("kills",[]).is_empty() else "robbery")).map(func(current):return int(current.id))
	var attacks: Array=record.attacks.filter(func(attack):return int(attack.day)<=int(member.departure_day) and (int(attack.target)==slot or attack.responses.has(str(slot))) and (int(attack.target)==slot or bond(slot,int(attack.target)) in CLOSE or objects.call("murder"))).map(func(attack):return int(attack.id))
	var bodies: Array=record.remains.filter(func(item):return slot in item.witnesses and (objects.call("cannibalism") or (record.people.has(item.person) and bond(slot,int(record.people[item.person].slot)) in CLOSE))).map(func(item):return int(item.id))
	return {"teller":slot,"origin":member.departure_place,"day":int(member.departure_day),"incidents":acts,"attacks":attacks,"remains":bodies}
## Every companion who left and has something to tell. Derived from the record; nothing new is stored.
func tales(game) -> Array:
	var result: Array=[]
	for member in game.party_health.members:
		if not member.get("departed",false):continue
		var told:=tale(game,int(member.id))
		if not (told.incidents.is_empty() and told.attacks.is_empty() and told.remains.is_empty()):result.append(told)
	return result
func heard_tales(game,place: String) -> Array:
	return tales(game).filter(func(told):return arrival(game,told,place)<=int(game.state.day))
## A post refuses only when news of the party has actually arrived there, from witnesses or from a former companion,
## and the people there know the party for the ones it describes.
func refuses(game,place: String) -> bool:
	return heard(game,place).any(func(report):return recognized(game,place,report)) or heard_tales(game,place).any(func(told):return recognized_tale(game,place,told))
## The act people talk about: any killing counts as one, whatever was first attempted.
func act_of(current: Dictionary) -> String:
	return "killed" if current.get("attempt","")=="killed" or not current.get("kills",[]).is_empty() else str(current.action)
## How likely people who have heard of an act are to know the party for the ones who did it. Named parties are
## known more often the worse the act; a masked party that got away clean is known only by its outfit; a quiet
## theft never names anyone. Faces and descriptions fade as the news grows old.
func recognition_chance(game,report: Dictionary) -> float:
	var current: Dictionary=record.incidents[int(report.incident)-1]
	var chance: float=float(recognition.acts[act_of(current)])
	if not report.identified:
		if current.get("mask","")!="hidden":return 0.0
		chance*=float(recognition.masked_factor)
	return chance*fade(game,int(current.day))
func fade(game,day: int) -> float:
	return pow(0.5,maxi(0,int(game.state.day)-day)/float(recognition.half_life_days))
## One fixed draw per place and piece of news, apart from the game's own dice: asking twice, saving or waiting a
## day changes nothing, but as the news grows old a place that knew the party may stop knowing it.
func recognition_roll(game,place: String,key: String) -> float:
	var dice:=RandomNumberGenerator.new()
	dice.seed=("%d|%s|%s" % [int(game.state.seed),place,key]).hash()
	return dice.randf()
func recognized(game,place: String,report: Dictionary) -> bool:
	return report.origin!=place and recognition_roll(game,place,"incident:%d" % int(report.incident))<recognition_chance(game,report)
## A former companion names the party outright, but the people hearing it still have to put the face to the name.
func recognized_tale(game,place: String,told: Dictionary) -> bool:
	return recognition_roll(game,place,"tale:%d" % int(told.teller))<float(recognition.acts.tale)*fade(game,int(told.day))
## News of the party's acts that has reached a place without anyone there taking the party for the ones who did them.
func rumor_text(game,place: String) -> String:
	var lines: Array=[]
	for report in heard(game,place):
		# A quiet theft is told as a description by news_text.
		if report.origin==place or recognized(game,place,report) or (not report.identified and record.incidents[int(report.incident)-1].get("mask","")!="hidden"):continue
		var act: String={"theft":"stole from","robbery":"robbed","shoot":"shot at","assault":"attacked","raid":"looted","pursuit":"fought off soldiers from","wanted":"fought"}[record.incidents[int(report.incident)-1].action]
		lines.append("People here talk of a party that %s %s %s, but nobody takes you for them." % [act,venue_noun(report.origin),where(game,report.origin)])
	for told in heard_tales(game,place):
		if not recognized_tale(game,place,told):lines.append("A traveler here tells of a party a former companion named, but nobody puts your faces to it.")
	return " ".join(lines)
## Everything said about the party at a place: what makes people refuse it, and what they say without knowing it.
func talk(game,place: String) -> String:
	return " ".join([news_text(game,place),rumor_text(game,place)].filter(func(text):return not text.is_empty()))
## Whether kerchiefs would hide the party here: people it traded with, or who saw its faces in an earlier act, know them.
func faces_seen(game,place: String) -> bool:
	var prefixes: Array=[market_prefix(place)+"|",place+"|"]
	if game.context.record.spent.keys().any(func(key):return prefixes.any(func(prefix):return str(key).begins_with(prefix))):return true
	return record.incidents.any(func(other):return other.place==place and other.attempt!="unseen" and other.get("mask","") not in ["covered","hidden"])
func mask_on(game,current: Dictionary,place: String) -> void:
	if game.pending.get("crime_masked",false):current["mask"]="known" if faces_seen(game,place) else "covered"
func news_text(game,place: String) -> String:
	var lines: Array=[]
	for report in heard(game,place):
		if report.origin==place or (report.identified and not recognized(game,place,report)):continue
		var act: String={"theft":"stole from","robbery":"robbed","shoot":"shot at","assault":"attacked unarmed","raid":"looted","pursuit":"fought off soldiers from","wanted":"fought"}[record.incidents[int(report.incident)-1].action]
		var origin: String=where(game,report.origin)
		var noun: String=venue_noun(report.origin)
		if report.identified:lines.append("Word reached here by day %d that your party %s %s %s. The people here will not trade with you or help you." % [arrival(game,report,place),act,noun,origin])
		elif recognized(game,place,report):lines.append("Word reached here by day %d that a masked party %s %s %s. People here take your outfit for theirs and will not trade with you or help you." % [arrival(game,report,place),act,noun,origin])
		elif record.incidents[int(report.incident)-1].action=="theft":lines.append("People here have heard that someone matching a description of your party stole from %s %s." % [noun,origin])
	for told in heard_tales(game,place):
		if not recognized_tale(game,place,told):continue
		var said: Array=[]
		for id in told.incidents:said.append("%s %s %s" % [{"theft":"stole from","robbery":"robbed","shoot":"shot at","assault":"attacked unarmed","raid":"looted","pursuit":"fought soldiers from","wanted":"fought"}[record.incidents[id-1].action],venue_noun(record.incidents[id-1].place),where(game,record.incidents[id-1].place)])
		for id in told.attacks:said.append(("attacked unarmed " if record.attacks[id-1].get("weapon","gun")=="unarmed" else "shot at ")+("them" if int(record.attacks[id-1].target)==int(told.teller) else game.party_health.members[int(record.attacks[id-1].target)].name))
		for id in told.remains:said.append("butchered %s's remains for food" % Remains.entry(game,id).name)
		lines.append("%s, who left your party on day %d, has told people here that you %s. They will not trade with you or help you." % [game.party_health.members[int(told.teller)].name,told.day,", ".join(said)])
	return " ".join(lines)
## "at Fort Hall", or for a trading party, the stretch of road where it was met.
func where(game,place: String) -> String:
	if not transient(place):return "at "+game.route.nodes[node_of(place)].name
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
	Remains.sync(game)
	var current:=incident()
	if resolution in ["captured","surrendered"]:
		# Anyone taken is seen bare-faced.
		if current.has("mask"):current.mask="known"
		Detention.arrest(self,game,current,resolution=="surrendered")
		if game.state.status=="traveling":game.pending=menu(game)
		return
	if current.action=="wanted":current.ended_day=int(game.state.day)
	current.resolution=resolution
	current.stage="report"
	game.journal.append("Day %d · %s incident %d: %s; %s. Took %d lb food and $%.2f; fired %d shot(s)." % [game.state.day,kind(current.place).journal,current.id,current.attempt,resolution,current.food,current.cash_cents/100.0,current.shots])
	# A mask holds only if it stayed on through the getaway.
	if current.has("custody") and current.get("mask","")=="covered":current.mask="known"
	if resolution in ["left","escaped"] and current.get("mask","")=="covered":current.mask="slipped" if rng.randf()<float(recognition.mask_slip) else "hidden"
	if resolution in ["left","escaped"] and (current.action not in ["wanted","pursuit"] or int(current.shots)>0) and not local_witnesses(current).is_empty():record.reports.append(report_for(current,int(game.state.day)))
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
## left: companions staying with the wagon when the party cuts loose; chosen on the riders menu.
func choose(game,command: String,left: Array=[]) -> bool:
	if not can_choose(game,command):return false
	# Too few saddles for everyone: first pick who rides.
	if command=="ride" and left.is_empty() and not Wanted.everyone_rides(game):
		game.pending=Wanted.riders_menu(game,Wanted.default_riders(game))
		return true
	if incident().get("stage","")=="custody":return Detention.choose(self,game,incident(),command)
	if incident().get("action","")=="wanted":return Wanted.choose(self,game,incident(),command,left)
	if incident().get("action","")=="pursuit" and command in ["flee","ride"]:return Wanted.flee_pursuit(self,game,incident(),command=="ride",left)
	if command in ["back","finish"]:
		if command=="finish":
			incident().stage="done"
			record.active={}
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		game.refresh_stop_offers()
		return true
	if command=="mask":
		game.pending["crime_masked"]=not game.pending.get("crime_masked",false)
		game.pending=menu(game)
		return true
	var place: String=target(game)
	# A trading party enters the record only once the party commits to an act against it.
	if incident().is_empty():add_transient(game,place)
	var keeper: Dictionary=actor(place,attack_target(game,place))
	var store: Dictionary=service(place)
	var kind: String=incident().get("action",command)
	var scene: Dictionary=odds(game,place,"murder" if kind in ["shoot","assault"] else "robbery")
	if incident().is_empty():
		var id: int=record.incidents.size()+1
		var current: Dictionary={"id":id,"day":int(game.state.day),"place":place,"target":keeper.uid,"action":command,"attempt":"raided","resolution":"","stage":"escape","food":0,"cash_cents":0,"shots":0,"knowledge":{}}
		current["joining"]=game.party_health.members.filter(func(member):return game.party_health.is_active(member) and game.characters.willing(int(member.id),"murder" if command in ["shoot","assault"] else "robbery")).map(func(member):return int(member.id))
		mask_on(game,current,place)
		if command=="robbery" and game.pending.has("robbery_demand"):
			var demanded: Dictionary=game.RobberyDemand.quote(game,game.pending.robbery_demand,place)
			if not demanded.valid:return false
			current["demand"]=demanded.basket.duplicate(true)
			scene.compliance=demanded.compliance
		elif command=="theft" and game.pending.has("theft_demand"):
			var chosen: Dictionary=game.RobberyDemand.quote(game,game.pending.theft_demand,place,"theft")
			if not chosen.valid:return false
			current["demand"]=chosen.basket.duplicate(true)
			scene.theft_success=chosen.unseen
		record.incidents.append(current)
		record.active={"id":id}
		if command=="theft":current.attempt="unseen" if rng.randf()<scene.theft_success else "noticed"
		elif command=="robbery":current.attempt="complied" if rng.randf()<scene.compliance else "resisted"
		elif command in ["shoot","assault"]:
			var unarmed: bool = command == "assault"
			if not unarmed:
				game._apply({"bullets":-1})
				current.shots=1
			current.attempt="missed"
			if rng.randf()<scene.shot_hit - (float(unarmed_rules().hit_penalty) if unarmed else 0.0):
				keeper.health=0 if keeper.health<=40 or rng.randf()<scene.shot_fatal * (float(unarmed_rules().fatal_factor) if unarmed else 1.0) else maxi(0,int(keeper.health)-40)
				current.attempt="killed" if keeper.health==0 else "wounded"
		if command == "assault": unarmed_mishap(game)
		if current.attempt!="unseen":store.alarmed=true
		if current.attempt in ["unseen","complied","killed","raided"]:current.stage="loot"
		# Attacking a supporting worker does not seize the keeper's stock or passage.
		if keeper.uid!=owner_id(place):current.stage="escape"
		game.journal.append("Day %d · %s incident %d: %s; %s %s. Nearby staff %s." % [game.state.day,kind(place).journal,id,command,display_name(game,place,keeper.uid),current.attempt,"were alerted" if store.alarmed else "did not notice the attempt"])
		observe(game,current,"attempt",current.attempt!="unseen")
		game.characters.react_to_incident(game,"murder" if command in ["shoot","assault"] else "robbery",id)
		if command=="robbery" and current.has("demand") and current.attempt=="resisted" and rng.randf()<float(scene.escape_injury):
			wound(game,int(scene.injury_damage),1)
			game.journal.append("Day %d · The robbery target fought back; a traveler was hurt." % game.state.day)
		if not advance(game):return true
	elif command=="take":
		var current:=incident()
		var loot:=loot_quote(game,place)
		if current.has("demand"):game.RobberyDemand.take(game,current,loot.goods)
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
	elif command in ["flee","ride"]:
		var current:=incident()
		if command=="ride":
			if not Wanted.cut_loose(self,game,left):return false
			Wanted.left_at_wagon(self,game,store.alarmed)
		# Riders get clear of the scene more often, though never surely.
		var capture: float=maxf(minf(float(scene.escape_capture),float(modifiers.floor)),float(scene.escape_capture)-Wanted.flight_bonus(self,game))
		if store.alarmed:Wanted.ride_hard(game)
		if store.alarmed:
			if not advance(game):return true
			if rng.randf()<capture:
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
			var targets: Array=living_staff(place).filter(func(uid):return uid!=owner_id(place) or Detention.jailbreak_incident(self,current))
			if targets.is_empty() or rng.randf()>=scene.shot_hit:continue
			var soldier: Dictionary=record.actors[targets[0]]
			soldier.health=0 if soldier.health<=40 or rng.randf()<scene.shot_fatal else int(soldier.health)-40
			# A soldier killed here carries nothing onward, as a keeper killed by the first shot never does.
			if soldier.health==0:
				current.knowledge.erase(soldier.uid)
				if not current.has("kills"):current["kills"]=[]
				current.kills.append(soldier.uid)
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
		if Detention.jailbreak_incident(self,current):
			if actor(place,current.target).health==0:current.attempt="killed"
			elif actor(place,current.target).health<100:current.attempt="wounded"
			Detention.recover_arms(self,game,current)
		observe(game,current,"escape",true)
		result(game,"escaped")
	Remains.sync(game)
	if game.state.status=="traveling":game.pending=menu(game)
	return true
## The post whose soldiers are riding after the party: it escaped them within the last few days, they have not chased it yet, and some are left to ride.
func pursuer(game) -> String:
	if not record.active.is_empty():return ""
	for place in venues():
		var chase: Dictionary=rules(place).get("pursuit",{})
		if chase.is_empty() or living_staff(place).filter(func(uid):return uid!=owner_id(place)).is_empty():continue
		if record.incidents.any(func(current):return current.place==place and current.action=="pursuit"):continue
		# The chase starts from the day of the getaway, which is the day its report left.
		var answered: Array=Wanted.settled(self)
		var getaways: Array=record.reports.filter(func(report):return report.origin==place and "incident:%d" % int(report.incident) not in answered and record.incidents[int(report.incident)-1].resolution=="escaped")
		if not getaways.is_empty() and int(game.state.day)-int(getaways.back().day)<=Wanted.pursuit_days(self,game,place):return place
	return ""
## Rolled once for each day the party travels or rests; a catch opens the standoff where the party must surrender or shoot its way out.
func check_pursuit(game) -> bool:
	var place:=pursuer(game)
	if place.is_empty() or game.state.status!="traveling" or record.incidents.size()>=10000:return false
	if rng.randf()>=float(rules(place).pursuit.daily):return false
	var id: int=record.incidents.size()+1
	var current: Dictionary={"id":id,"day":int(game.state.day),"place":place,"target":owner_id(place),"action":"pursuit","attempt":"caught","resolution":"","stage":"standoff","food":0,"cash_cents":0,"shots":0,"knowledge":{}}
	record.incidents.append(current)
	record.active={"id":id}
	observe(game,current,"attempt",true)
	var captors: String="Men of %s" % str(rules(place).title).to_lower() if household(place) else "Soldiers"
	game.journal.append("Day %d · %s from %s rode after the party and caught up." % [game.state.day,captors,game.route.nodes[node_of(place)].name])
	game.health_events.append("%s from %s have caught up with the party." % [captors,game.route.nodes[node_of(place)].name])
	game.service_return=game.pending.duplicate(true)
	game.pending=menu(game)
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
## Bonds are generated once, for new journeys only, from their own random stream.
func make_bonds(game) -> void:
	if not record.bonds.is_empty() or int(game.state.day)!=0:return
	record.bonds=roll_bonds(int(game.state.seed),game.party_health.members.size())

func roll_bonds(seed_value: int, count: int = 5) -> Array:
	var random:=RandomNumberGenerator.new()
	random.seed=seed_value ^ 0x424f4e44
	var partnered: Array=[]
	var result: Array=[]
	for a in range(1,count):
		for b in range(a+1,count):
			var roll: float=random.randf()
			for kind in BONDS:
				var chance: float=float(companion_rules.bond_chances[kind])
				if roll<chance:
					if kind=="partner" and (a in partnered or b in partnered):break
					if kind=="partner":partnered.append_array([a,b])
					result.append({"a":a,"b":b,"kind":kind})
					break
				roll-=chance
	return result
func bond(a: int,b: int) -> String:
	for item in record.bonds:
		if (int(item.a)==a and int(item.b)==b) or (int(item.a)==b and int(item.b)==a):return item.kind
	return ""
func bond_text(game,id: int) -> String:
	var lines: Array=[]
	for item in record.bonds:
		if int(item.a)==id or int(item.b)==id:lines.append("%s: %s" % [item.kind.capitalize(),game.party_health.members[int(item.b) if int(item.a)==id else int(item.a)].name])
	return "Bonds: "+(", ".join(lines) if not lines.is_empty() else "None")
## Who joins the leader against a companion, and who refuses: anyone close to the target, or unwilling to kill.
func attack_side(game,target: int) -> Dictionary:
	var joining: Array=[0]
	var refusing: Array=[]
	for member in game.party_health.members:
		var id: int=int(member.id)
		if id==0 or id==target or not game.party_health.is_active(member):continue
		if bond(id,target) in CLOSE or not game.characters.willing(id,"murder"):refusing.append(id)
		else:joining.append(id)
	return {"joining":joining,"refusing":refusing}
func attack_chance(game,target: int) -> float:
	return clampf(float(companion_rules.hit)+float(companion_rules.participant_step)*(attack_side(game,target).joining.size()-1),float(modifiers.floor),float(modifiers.ceiling))
func attack_ready(game,target: int) -> bool:
	var members: Array=game.party_health.members
	return target>0 and target<members.size() and game.party_health.is_active(members[target]) and game.party_health.is_active(members[0]) and record.active.is_empty() and record.attacks.size()<100
func can_attack(game,target: int) -> bool:return game.can_service() and attack_ready(game,target)
## Pure: shows the target, who joins, who refuses and the odds before anything is committed.
func attack_menu(game,target: int) -> Dictionary:
	var members: Array=game.party_health.members
	var side:=attack_side(game,target)
	var name: String=members[target].name
	var names:=func(ids):return ", ".join(ids.map(func(id):return members[id].name)) if not ids.is_empty() else "nobody"
	var text: String="You intend to attack %s. Joining you: %s. Refusing: %s. Chance to hit: %d%%. A hit may kill or only wound. Unarmed attacks have a 25-point lower hit chance and a 45%% additional injury risk. Everyone with the wagon sees it; companions close to %s may fight you or flee at once, and others who object may leave." % [name,names.call(side.joining),names.call(side.refusing),roundi(attack_chance(game,target)*100),name]
	for item in record.bonds:
		if int(item.a)==target or int(item.b)==target:text+="\n%s and %s: %s." % [members[int(item.a)].name,members[int(item.b)].name,item.kind]
	return {"id":"attack","attack_menu":true,"service_menu":true,"title":"Attack "+name,"text":text,"choices":[{"label":"Shoot %s · 1 bullet" % name,"attack_target":target,"effects":{},"result":""},{"label":"Attack %s unarmed · higher injury risk" % name,"attack_target":target,"unarmed":true,"effects":{},"result":""},{"label":"Back","attack_target":-1,"effects":{},"result":""}]}
func choose_attack(game,index: int) -> bool:
	var target: int=int(game.pending.choices[index].attack_target)
	var unarmed: bool = game.pending.choices[index].get("unarmed",false)
	if target>=0 and (not attack_ready(game,target) or (not unarmed and not game.can_fire())):return false
	game.pending=game.service_return.duplicate(true)
	game.service_return={}
	if target>=0:attack(game,target,unarmed)
	return true
func attack(game,target: int, unarmed: bool = false) -> void:
	if not attack_ready(game,target) or (not unarmed and not game.can_fire()): return
	var members: Array=game.party_health.members
	var leader: Dictionary=members[0]
	var victim: Dictionary=members[target]
	var day: int=int(game.state.day)
	var side:=attack_side(game,target)
	var chance:=maxf(0.05,attack_chance(game,target) - (float(unarmed_rules().hit_penalty) if unarmed else 0.0))
	var verb := "attacked unarmed" if unarmed else "shot at"
	if not unarmed: game._apply({"bullets":-1})
	var attempt: String="missed"
	if rng.randf()<chance:attempt="killed" if victim.health<=int(companion_rules.wound_damage) or rng.randf()<float(companion_rules.fatal) * (float(unarmed_rules().fatal_factor) if unarmed else 1.0) else "wounded"
	if attempt=="killed":game.party_health.kill(victim,day,("an unarmed attack by " if unarmed else "being shot by ")+leader.name)
	elif attempt=="wounded":
		game.party_health.affect(victim,-int(companion_rules.wound_damage),day,("an unarmed attack by " if unarmed else "a gunshot wound from ")+leader.name)
		game.party_health.begin_condition(target,"wound",day,1)
		if not victim.alive:attempt="killed"
	var id: int=record.attacks.size()+1
	var responses: Dictionary={}
	var poor: int=int(game.combat.data.poor_health)
	for member in members:
		var other: int=int(member.id)
		if other==0 or other in side.joining or not game.party_health.is_active(member):continue
		var profile: Dictionary=game.characters.profiles[other]
		var fighter: bool=profile.traits[0] in ["Bold","Reckless"] and member.health>=poor
		var answer: String="stood by"
		if other==target or bond(other,target) in CLOSE:answer="retaliated" if fighter else "fled"
		elif bond(other,target)!="rival" and game.characters.response(other,"murder") in ["forbidden","reluctant"]:answer="fled" if attempt=="killed" else "objected"
		responses[str(other)]=answer
		# Harm to oneself or a loved one is never an ordinary trust loss; a rival is unmoved.
		if other==target or bond(other,target) in CLOSE:game.characters.remember(game,profile,"action_murder",-12,"You %s %s." % [verb,"them" if other==target else victim.name],true,0,id)
		elif bond(other,target)!="rival":
			var reaction: String=game.characters.response(other,"murder")
			if reaction!="neutral":game.characters.remember(game,profile,"action_murder",-12 if reaction in ["forbidden","reluctant"] else (2 if reaction=="approved" else -2),"You %s %s. Response: %s." % [verb,victim.name,reaction],reaction in ["forbidden","reluctant"],0,id)
	record.attacks.append({"id":id,"day":day,"target":target,"attempt":attempt,"joining":side.joining,"responses":responses,"weapon":"unarmed" if unarmed else "gun"})
	game.journal.append("Day %d · You %s %s: %s." % [day,verb,victim.name,attempt])
	var leaving: Array=[]
	for key in responses:
		var member: Dictionary=members[int(key)]
		if responses[key]=="retaliated" and game.party_health.is_active(leader):
			var hit: bool=rng.randf()<float(companion_rules.retaliate_hit)
			if hit:
				game.party_health.affect(leader,-int(companion_rules.retaliate_damage),day,"being shot by "+member.name)
				game.party_health.begin_condition(0,"wound",day,1)
			game.journal.append("Day %d · %s fought back%s." % [day,member.name," and hit you" if hit else " and missed"])
		if responses[key] in ["fled","retaliated"]:leaving.append(int(key))
		elif responses[key]=="objected":game.journal.append("Day %d · %s objects to the attack." % [day,member.name])
	if unarmed: unarmed_mishap(game)
	game._collect_health_events()
	game.flee(leaving,"after you "+verb+" "+victim.name)
	game.health_events.append("You %s %s: %s.%s" % [verb,victim.name,attempt,(" Leaving at once: "+", ".join(leaving.map(func(other):return members[other].name))+".") if not leaving.is_empty() else ""])
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
## Ruthless or opportunistic companions whose trust has fallen to their betrayal point (shown as a warning in View Party).
func betrayer(game,slot: int) -> bool:
	var profile: Dictionary=game.characters.profiles[slot]
	return slot>0 and game.party_health.is_active(game.party_health.members[slot]) and game.characters.may_betray(profile) and float(profile.trust)<=maxi(0,int(profile.thresholds.betrayal)-game.characters.attachment(profile))
## Each night, at most one companion at the betrayal point may turn on the party. Chance-based; nobody else is affected by the roll.
func check_betrayal(game) -> void:
	if game.state.status!="traveling" or not record.has("betrayals"):return
	for member in game.party_health.members:
		var slot: int=int(member.id)
		if betrayer(game,slot) and rng.randf()<float(companion_rules.betrayal.daily):
			betray(game,slot)
			return
## The ruthless, willing to kill, shoot the leader first and take what they can either way. Others rob the stores in the night;
## anyone who wakes stops the theft, but the thief still runs. Either way the betrayer is gone by morning.
func betray(game,slot: int) -> void:
	var rules: Dictionary=companion_rules.betrayal
	var members: Array=game.party_health.members
	var leader: Dictionary=members[0]
	var member: Dictionary=members[slot]
	var day: int=int(game.state.day)
	var profile: Dictionary=game.characters.profiles[slot]
	var others: Array=members.filter(func(other):return int(other.id)>0 and int(other.id)!=slot and game.party_health.is_active(other)).map(func(other):return int(other.id))
	var act: String="attack" if profile.traits[1]=="Ruthless" and game.characters.response(slot,"murder") not in ["forbidden","reluctant"] and game.party_health.is_active(leader) and game.can_fire() else "theft"
	var attempt: String="stole"
	var noticed: Array=[]
	if act=="attack":
		game._apply({"bullets":-1})
		# A shot wakes the camp; companions willing to defend the wagon spoil the aim.
		noticed=others.duplicate()
		var guards: int=others.filter(func(other):return game.characters.willing(other,"defend")).size()
		var chance: float=clampf(float(rules.ambush_hit)-float(rules.guard_step)*guards,float(modifiers.floor),float(modifiers.ceiling))
		attempt="missed"
		if rng.randf()<chance:attempt="killed" if leader.health<=int(companion_rules.wound_damage) or rng.randf()<float(companion_rules.fatal) else "wounded"
		if attempt=="killed":game.party_health.kill(leader,day,"being shot by "+member.name)
		elif attempt=="wounded":
			game.party_health.affect(leader,-int(companion_rules.wound_damage),day,"a gunshot wound from "+member.name)
			game.party_health.begin_condition(0,"wound",day,1)
			if not leader.alive:attempt="killed"
	else:
		for other in others:
			if rng.randf()<float(rules.notice):noticed.append(other)
		if not noticed.is_empty():attempt="stopped"
	var taken: Dictionary={"food":0,"cents":0,"bullets":0}
	if attempt!="stopped":
		taken.food=int(floor(int(game.state.food)*float(rules.food_share)))
		taken.cents=int(floor(roundi(float(game.state.money)*100)*float(rules.cash_share)))
		taken.bullets=int(floor(int(game.state.bullets)*float(rules.bullet_share)))
		game._apply({"food":-taken.food,"money":-taken.cents/100.0,"bullets":-taken.bullets})
	record.betrayals.append({"id":record.betrayals.size()+1,"day":day,"member":slot,"act":act,"attempt":attempt,"taken":taken,"noticed":noticed})
	var goods: String="%d lb food, $%.2f and %d bullets" % [taken.food,taken.cents/100.0,taken.bullets]
	var text: String
	if act=="attack":text="%s shot at you in the night: %s, then ran with %s." % [member.name,attempt,goods]
	elif attempt=="stole":text="%s robbed the wagon in the night and slipped away with %s." % [member.name,goods]
	else:text="%s tried to rob the wagon in the night; %s woke and stopped it. %s ran." % [member.name,", ".join(noticed.map(func(other):return members[other].name)),member.name]
	game.journal.append("Day %d · %s" % [day,text])
	game.health_events.append(text)
	game._collect_health_events()
	game.flee([slot],"after turning on the party")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
func snapshot() -> Dictionary:return {"record":record.duplicate(true),"random":str(rng.state)}
## Converts a version 1 snapshot (one keeper record per place and an aggregate "staff:<place>"
## observer) into separate staff people. Anything malformed is returned unchanged for valid() to reject.
func upgrade(value: Variant,game=null) -> Variant:return add_venues(upgrade_v9(upgrade_v8(upgrade_v7(upgrade_v6(upgrade_v5(upgrade_v4(upgrade_v3(upgrade_v2(upgrade_v1(value))))))))),game)
## Version 4 kept no remains. Deaths already recorded join the ledger as lost when the save is restored; nobody knows where they lie.
func upgrade_v4(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=4 or value.record.has("remains"):return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=5
	r.remains=[]
	return {"record":r,"random":value.get("random")}
## Version 5 had remains but no human-derived food or meal plans.
func upgrade_v5(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=5 or value.record.has("human_food") or value.record.has("meals"):return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=6
	r.human_food=[]
	r.meals={}
	return {"record":r,"random":value.get("random")}
## Version 6 kept who knew of butchering only on meat still held. Those companions become the body's witnesses.
func upgrade_v6(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=6 or not value.record.get("remains") is Array or not value.record.get("human_food") is Array:return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=7
	for item in r.remains:
		if not item is Dictionary or item.has("witnesses"):return value
		item.witnesses=[]
		for meat in r.human_food:
			if meat is Dictionary and meat.get("remains")==item.get("id") and meat.get("known") is Array:
				for slot in meat.known:
					if number(slot) and int(slot)>0 and int(slot) not in item.witnesses:item.witnesses.append(int(slot))
		item.witnesses.sort()
	return {"record":r,"random":value.get("random")}
## Version 7 had no betrayals; nobody had yet turned on the party.
func upgrade_v7(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=7 or value.record.has("betrayals"):return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=8
	r.betrayals=[]
	return {"record":r,"random":value.get("random")}
## Version 8 predates posted rewards. Existing evidence and random state stay intact.
func upgrade_v8(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=8 or value.record.has("bounties"):return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=9
	r.bounties=[]
	return {"record":r,"random":value.get("random")}
## Version 9 tried every capture on the spot before an emigrant-style tribunal. Those sentences stand as they were.
func upgrade_v9(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=9 or not value.record.get("incidents") is Array:return value
	var r: Dictionary=value.record.duplicate(true)
	r.version=VERSION
	for item in r.incidents:
		if item is Dictionary and item.get("sentence") is Dictionary and not item.sentence.has("authority"):item.sentence.merge({"authority":"company","verdict":"convicted","jail_days":0,"imprisoned":[]})
	return {"record":r,"random":value.get("random")}
func notoriety(game,place_or_mile: Variant="") -> float:return Wanted.notoriety(self,game,place_or_mile)
func wanted_label(game) -> String:
	var score:=notoriety(game,int(game.state.miles))
	return "Wanted: "+("not known" if score<=0 else ("talked about" if score<4 else ("wanted" if score<9 else "notorious")))
func check_wanted(game) -> bool:return Wanted.check_wanted(self,game)
## Version 3 had no companion bonds or attacks. Existing travelers are never given invented bonds.
func upgrade_v3(value: Variant) -> Variant:
	if not value is Dictionary or not value.get("record") is Dictionary or value.record.get("version")!=3:return value
	var r: Dictionary=value.record.duplicate(true)
	if r.has("bonds") or r.has("attacks"):return value
	r.version=4
	r.bonds=[]
	r.attacks=[]
	return {"record":r,"random":value.get("random")}
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
	r.version=3
	r.reports=[]
	for current in r.incidents:
		if not current is Dictionary or not current.get("knowledge") is Dictionary or not scenes.has(current.get("place","")):return value
		if current.get("resolution") in ["left","escaped"] and (current.action not in ["wanted","pursuit"] or int(current.shots)>0) and not local_witnesses(current).is_empty():r.reports.append(report_for(current,int(current.get("day",0))))
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
## Bonds are sparse pairs of companions; each attack is consistent with who died, who left and how each companion answered.
func valid_party(r: Dictionary,game) -> bool:
	var members: Array=game.party_health.members
	if not r.get("bonds") is Array or r.bonds.size()>(members.size()*(members.size()-1))/2 or not r.get("attacks") is Array or r.attacks.size()>100:return false
	var pairs: Array=[]
	var partnered: Array=[]
	for item in r.bonds:
		if not item is Dictionary or item.size()!=3 or not whole(item.get("a"),1,members.size()-1) or not whole(item.get("b"),int(item.get("a"))+1,members.size()-1) or item.get("kind") not in BONDS:return false
		var pair: String="%d:%d" % [item.a,item.b]
		if pair in pairs:return false
		pairs.append(pair)
		if item.kind=="partner":
			if int(item.a) in partnered or int(item.b) in partnered:return false
			partnered.append_array([int(item.a),int(item.b)])
	var previous_day:=0
	for index in range(r.attacks.size()):
		var attack: Variant=r.attacks[index]
		if not attack is Dictionary or attack.size() not in [6,7] or attack.get("id")!=index+1 or not whole(attack.get("day"),previous_day,int(game.state.day)) or not whole(attack.get("target"),1,members.size()-1) or attack.get("attempt") not in ATTACK_RESULTS:return false
		if attack.get("weapon","gun") not in ["gun","unarmed"]:return false
		previous_day=int(attack.day)
		var victim: Dictionary=members[int(attack.target)]
		if attack.attempt=="killed" and (victim.alive or victim.death_day!=attack.day):return false
		if not attack.get("joining") is Array or attack.joining.is_empty() or attack.joining[0]!=0 or not attack.get("responses") is Dictionary:return false
		for id in attack.joining:
			if not whole(id,0,members.size()-1) or id==attack.target or attack.joining.count(id)!=1:return false
		for key in attack.responses:
			if not key is String or not key.is_valid_int() or not whole(int(key),1,members.size()-1) or int(key) in attack.joining or attack.responses[key] not in RESPONSES:return false
			# Whoever fled or fought back is no longer with the party (unless they died there).
			var member: Dictionary=members[int(key)]
			if attack.responses[key] in ["fled","retaliated"] and member.alive and not member.get("departed",false):return false
		if (str(int(attack.target)) in attack.responses)==(attack.attempt=="killed"):return false
	if not valid_betrayals(r,game):return false
	# Nobody fled the party except in answer to an attack, or after turning on it.
	for member in members:
		if member.get("fled",false) and not r.attacks.any(func(attack):return attack is Dictionary and attack.get("responses") is Dictionary and attack.responses.get(str(int(member.id)),"") in ["fled","retaliated"] and attack.day==member.departure_day) and not r.betrayals.any(func(item):return int(item.member)==int(member.id) and int(item.day)==int(member.departure_day)) and not r.incidents.any(func(item):return (item.get("sentence",{}).get("banished",[])+item.get("sentence",{}).get("imprisoned",[])).any(func(id):return number(id) and int(id)==int(member.id)) and int(item.sentence.day)==int(member.departure_day)) and not r.incidents.any(func(item):return item.get("custody") is Dictionary and item.custody.get("abandoned") is Array and item.custody.abandoned.any(func(id):return number(id) and int(id)==int(member.id))):return false
	return true
func valid_betrayals(r: Dictionary,game) -> bool:
	var members: Array=game.party_health.members
	if not r.get("betrayals") is Array or r.betrayals.size()>members.size():return false
	var previous_day:=0
	for index in range(r.betrayals.size()):
		var item: Variant=r.betrayals[index]
		if not item is Dictionary or item.size()!=7 or item.get("id")!=index+1 or not whole(item.get("day"),previous_day,int(game.state.day)) or not whole(item.get("member"),1,members.size()-1):return false
		previous_day=int(item.day)
		if not BETRAYAL_RESULTS.has(item.get("act")) or item.get("attempt") not in BETRAYAL_RESULTS[item.act]:return false
		# The betrayer left that night; they turn on the party only once.
		var member: Dictionary=members[int(item.member)]
		if not member.get("fled",false) or int(member.get("departure_day",-1))!=int(item.day) or r.betrayals.filter(func(other):return other is Dictionary and other.get("member")==item.member).size()!=1:return false
		var taken: Variant=item.get("taken")
		if not taken is Dictionary or taken.size()!=3 or not whole(taken.get("food"),0,100000) or not whole(taken.get("cents"),0,100000000) or not whole(taken.get("bullets"),0,100000):return false
		if item.attempt=="stopped" and (taken.food+taken.cents+taken.bullets)>0:return false
		# The leader died of this shot exactly when the record says it killed.
		var shot: bool=not members[0].alive and int(members[0].death_day)==int(item.day) and str(members[0].get("cause",""))=="being shot by "+str(member.name)
		if (item.attempt=="killed")!=shot:return false
		if not item.get("noticed") is Array:return false
		for slot in item.noticed:
			if not whole(slot,1,members.size()-1) or int(slot)==int(item.member) or item.noticed.count(slot)!=1:return false
		if (item.attempt=="stopped")==item.noticed.is_empty() and item.act=="theft":return false
	return true
func valid(value: Variant,game) -> bool:
	if not value is Dictionary or value.size()!=2 or not value.get("record") is Dictionary or not value.get("random") is String or not value.random.is_valid_int() or str(int(value.random))!=value.random:return false
	var r: Dictionary=value.record
	if r.size()!=14 or not valid_party(r,game) or not r.get("reports") is Array or r.get("version")!=VERSION or not r.get("people") is Dictionary or r.people.size()!=game.party_health.members.size() or not r.get("actors") is Dictionary or not r.get("services") is Dictionary or not r.services.keys().all(func(place):return scenes.has(place) and not TEMPLATE_KINDS.has(place) or transient(place)) or not r.get("incidents") is Array or r.incidents.size()>10000 or not r.get("active") is Dictionary or not r.get("bounties") is Array:return false
	for member in game.party_health.members:
		var uid:=person_id(int(game.state.seed),int(member.id))
		var person: Variant=r.people.get(uid)
		if not person is Dictionary or person.size()!=2 or person.get("name")!=member.name or person.get("slot")!=member.id:return false
	var actor_count:=0
	var targeted: Array=r.services.keys().filter(transient)
	# Every trading party in the record was the target of an incident.
	if not targeted.all(func(place):return r.incidents.any(func(current):return current is Dictionary and current.get("place")==place)):return false
	for place in venues()+targeted:
		# Saves from before traders carried their own goods allowed every party three 50 lb lots.
		var lots: int=maxi(food_capacity(game,place),int(game.context.data.passing_lots)*int(rules(place).food_lot) if trader(place) else 0)
		for uid in staff_ids(place):
			var actor: Variant=r.actors.get(uid)
			if not actor is Dictionary or actor.size()!=4 or actor.get("uid")!=uid or actor.get("place")!=place or actor.get("role")!=role(place,uid) or not whole(actor.get("health"),0,100):return false
			actor_count+=1
		var store: Variant=r.services.get(place)
		if not store is Dictionary or store.size()!=(7 if transient(place) else 6) or (transient(place) and not whole(store.get("mile"),0,int(game.route.longest_miles) if game.state.has("travel_direction") else int(game.state.miles))) or store.get("owner")!=owner_id(place) or store.get("staff")!=staff_ids(place) or not whole(store.get("cash_cents"),0,int(rules(place).cash_cents)) or not whole(store.get("food_taken"),0,lots) or not whole(store.get("food_sold"),0,lots) or not store.get("alarmed") is bool:return false
		if r.actors[owner_id(place)].health==0 and not store.alarmed:return false
		if store.food_taken+store.food_sold>lots:return false
		var offers: int=game.context.record.spent.get(market_prefix(place)+"|buy_food",0)
		# Lots record whole offers; the store counter sells by the pound, so a lot it opened may be only partly sold.
		if (offers>0)!=(store.food_sold>0) or store.food_sold>offers*int(rules(place).food_lot):return false
	if r.actors.size()!=actor_count:return false
	var food_totals: Dictionary={}
	var cash_totals: Dictionary={}
	var previous_day: int=-1
	for index in range(r.incidents.size()):
		var current: Variant=r.incidents[index]
		if not current is Dictionary or (current.get("action")!="wanted" and current.size()!=12+int(current.has("sentence"))+int(current.has("custody"))+int(current.has("joining"))+int(current.has("kills"))+int(current.has("demand"))+int(current.has("taken_goods"))+int(current.has("mask"))) or current.get("id")!=index+1 or not whole(current.get("day"),0,int(game.state.day)) or not (current.get("place") is String and r.services.has(current.place) and not TEMPLATE_KINDS.has(current.place)) or current.get("target") not in staff_ids(current.place):return false
		if not Wanted.valid_extras(self,r,current,game) or not Detention.valid_custody(self,r,current,game):return false
		if current.get("action")=="wanted":
			if not Wanted.valid_incident(self,r,current,game,index,previous_day):return false
			previous_day=int(current.day)
			continue
		if current.get("action") not in ["shoot","assault"] and current.target!=owner_id(current.place):return false
		if current.get("action") not in ["theft","robbery","shoot","assault","raid","pursuit"] or current.get("attempt") not in ATTEMPTS or current.get("stage") not in STAGES or current.get("resolution") not in RESOLUTIONS:return false
		if not game.RobberyDemand.valid(game,current):return false
		# A mask is tied on before the act and holds or slips once the party gets away.
		if current.has("mask") and (current.mask not in MASKS or ((current.mask in ["hidden","slipped"])!=(current.resolution in ["left","escaped"]) and current.mask!="known")):return false
		if current.day<previous_day:return false
		previous_day=int(current.day)
		if current.attempt not in {"theft":["unseen","noticed"],"robbery":["complied","resisted","killed"],"shoot":["missed","wounded","killed"],"assault":["missed","wounded","killed"],"raid":["raided"],"pursuit":["caught"]}[current.action]:return false
		# A chase follows an escape from the same post, within its days, and happens once.
		if current.action=="pursuit":
			var chase: Dictionary=rules(current.place).get("pursuit",{})
			if chase.is_empty() or current.stage in ["loot","escape"] or r.incidents.slice(0,index).any(func(other):return other.get("place")==current.place and other.get("action")=="pursuit"):return false
			if not r.reports.any(func(report):return report is Dictionary and report.get("origin")==current.place and whole(report.get("incident"),1,index) and r.incidents[int(report.incident)-1].get("resolution")=="escaped" and int(current.day)-int(report.get("day",0))<=int(wanted_data.army_max_days) and int(current.day)>=int(report.get("day",0))):return false
		if (current.stage in ["loot","escape","standoff","custody"])!=(current.resolution==""):return false
		if current.stage=="standoff" and rules(current.place).kind not in ["fort","household","jail"]:return false
		if rules(current.place).kind=="jail" and current.action!="assault":return false
		if current.stage=="loot" and current.attempt not in ["unseen","complied","killed","raided","resisted"]:return false
		if current.attempt!="unseen" and not r.services[current.place].alarmed:return false
		if current.attempt=="killed" and r.actors[current.target].health!=0:return false
		for key in ["food","cash_cents","shots"]:
			if not whole(current.get(key),0,100000):return false
		if current.target!=owner_id(current.place) and (current.stage=="loot" or current.food>0 or current.cash_cents>0):return false
		# Only soldiers force the extra shots of a breakout.
		var extra: int=int(current.shots)-(1 if current.action=="shoot" else 0)
		if extra<0 or extra>(int(rules(current.place).breakout_shots) if rules(current.place).kind in ["fort","household","jail"] else 0) or not current.get("knowledge") is Dictionary or current.knowledge.size()>game.party_health.members.size()+staff_ids(current.place).size():return false
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
	var expected: Array=r.incidents.filter(func(current):return current.resolution in ["left","escaped"] and (current.action not in ["wanted","pursuit"] or int(current.shots)>0) and not local_witnesses(current).is_empty())
	if r.reports.size()!=expected.size():return false
	for index in range(expected.size()):
		var report: Variant=r.reports[index]
		var current: Dictionary=expected[index]
		if not report is Dictionary or report.size()!=6 or not whole(report.get("day"),int(current.day),int(game.state.day)):return false
		var derived: Dictionary=report_for(current,int(report.day))
		if report.get("incident")!=derived.incident or report.get("origin")!=derived.origin or report.get("identified")!=derived.identified or report.get("senders")!=derived.senders or report.get("facts")!=derived.facts:return false
	if not Wanted.valid_bounties(self,r,game):return false
	if not r.active.is_empty():
		if r.active.size()!=1 or not whole(r.active.get("id"),1,r.incidents.size()) or r.active.id!=r.incidents.size() or r.incidents[int(r.active.id)-1].stage=="done" or not (game.pending.get("crime_menu",false) or game.pending.get("riders_menu",false)):return false
	return Remains.valid(r,game)


func unarmed_rules() -> Dictionary:
	return unarmed_data

func unarmed_mishap(game) -> void:
	if game.party_health.is_active(game.party_health.members[0]) and rng.randf() < float(unarmed_rules().mishap_chance):
		game.party_health.affect(game.party_health.members[0],-int(unarmed_rules().mishap_damage),int(game.state.day),"an unarmed struggle")
		game.party_health.begin_condition(0,"wound",int(game.state.day),1)
		game._collect_health_events()
		game.state.health=game.party_health.average_health()
		game.state.party_size=game.party_health.living_count()
		game._check_health()
		game.journal.append("Day %d · Hurt in the unarmed struggle." % game.state.day)
		game.health_events.append("You were hurt in the unarmed struggle.")


func begin_tactical_shoot(game) -> bool:
	if not incident().is_empty() or not can_choose(game, "shoot"):
		return false
	var place: String = target(game)
	add_transient(game, place)
	var keeper: Dictionary = actor(place, attack_target(game, place))
	var store: Dictionary = service(place)
	var id: int = record.incidents.size() + 1
	var current: Dictionary = {
		"id": id,
		"day": int(game.state.day),
		"place": place,
		"target": keeper.uid,
		"action": "shoot",
		"attempt": "wounded",
		"resolution": "",
		"stage": "escape",
		"food": 0,
		"cash_cents": 0,
		"shots": 1,
		"knowledge": {},
	}
	current["joining"] = game.party_health.members.filter(func(member):
		return game.party_health.is_active(member) and game.characters.willing(int(member.id), "murder")
	).map(func(member): return int(member.id))
	mask_on(game, current, place)
	record.incidents.append(current)
	record.active = {"id": id}
	store.alarmed = true
	observe(game, current, "attempt", true)
	game.characters.react_to_incident(game, "murder", id)
	game.journal.append("Day %d · %s incident %d: gunfire opened at %s." % [
		game.state.day,
		kind(place).journal,
		id,
		display_name(game, place, keeper.uid),
	])
	if not advance(game):
		return false
	if game.state.status == "traveling":
		game.pending = menu(game)
	return true


func build_tactical_config(game, command: String = "") -> Dictionary:
	var current := incident()
	var place: String = current.get("place", target(game))
	if place.is_empty():
		return {}
	add_transient(game, place)
	var scene: Dictionary = rules(place)
	var venue_kind: String = String(scene.get("kind", "store"))
	if venue_kind == "pursuers":
		venue_kind = "traders" if place.begins_with("wanted_") else "fort"
	# A household fights among its lodges and stores, laid out like a camp.
	if venue_kind == "household":
		venue_kind = "emigrants"
	# Guards are fought where they hold the prisoners: the county's brick jail, the army's guard tent, a company's camp.
	if venue_kind == "jail":
		venue_kind = {"jail_county": "jail_county", "jail_army": "jail_army"}.get(TEMPLATES[place.substr(0, place.find(":") + 1)], "emigrants")
	var place_title: String = String(scene.get("title", place))
	if game.route.nodes.has(node_of(place)):
		place_title = String(game.route.nodes[node_of(place)].get("name", place_title))

	var is_defensive: bool = String(current.get("action", "")) in ["pursuit", "wanted"]
	var action_kind: String = "defend" if is_defensive else ("murder" if (command == "shoot" or String(current.get("action", "")) in ["shoot", "assault"]) else "robbery")
	var squad: Array = []
	var joined_slots: Array = []
	for member in game.party_health.members:
		if not game.party_health.is_active(member):
			continue
		var mid := int(member.id)
		var joins: bool = (mid == 0) or bool(game.characters.willing(mid, action_kind))
		if not joins:
			continue
		joined_slots.append(mid)
		var has_leg: bool = member.conditions.any(func(c): return c.id == "broken_leg")
		var has_arm: bool = member.conditions.any(func(c): return c.id == "broken_arm")
		var has_wound: bool = member.conditions.any(func(c): return c.id == "wound")
		var profile: Dictionary = game.characters.profiles[mid] if mid < game.characters.profiles.size() else {}
		squad.append({
			"id": str(mid),
			"slot": mid,
			"name": String(member.name),
			"role": "leader" if mid == 0 else "companion",
			"health": int(member.health),
			"broken_leg": has_leg,
			"broken_arm": has_arm,
			"wound": has_wound,
			"profile": profile,
		})
	if squad.is_empty():
		for member in game.party_health.members:
			if game.party_health.is_active(member):
				var mid := int(member.id)
				joined_slots.append(mid)
				squad.append({
					"id": str(mid),
					"slot": mid,
					"name": String(member.name),
					"role": "leader",
					"health": int(member.health),
					"broken_leg": member.conditions.any(func(c): return c.id == "broken_leg"),
					"broken_arm": member.conditions.any(func(c): return c.id == "broken_arm"),
					"wound": member.conditions.any(func(c): return c.id == "wound"),
					"profile": game.characters.profiles[mid] if mid < game.characters.profiles.size() else {},
				})
				break
	if not current.is_empty():
		current["joining"] = joined_slots.duplicate()

	var enemies: Array = []
	var staff_list: Array = living_staff(place)
	# Every guard stands against a jailbreak.
	if (command == "breakout" or current.get("stage", "") == "standoff") and String(current.get("action", "")) != "wanted" and not Detention.jailbreak_incident(self, current):
		var non_owner := staff_list.filter(func(uid): return uid != owner_id(place))
		if not non_owner.is_empty():
			staff_list = non_owner
	for uid in staff_list:
		var act: Dictionary = actor(place, uid)
		var r_name: String = role(place, uid)
		var is_soldier := venue_kind == "fort" or r_name in ["soldier", "sergeant", "corporal", "deputy", "marshal", "hunter", "regulator"]
		enemies.append({
			"uid": uid,
			"id": uid,
			"name": display_name(game, place, uid),
			"role": "owner" if uid == owner_id(place) else r_name,
			"health": int(act.get("health", 100)),
			"soldier": is_soldier,
			"profile": _actor_profile(game, uid),
		})
	if enemies.is_empty():
		return {}

	var reason := command
	if reason.is_empty():
		if current.get("stage", "") == "standoff":
			reason = "breakout"
		elif current.get("action", "") == "shoot":
			reason = "shoot"
		else:
			reason = "resisted"

	var seed_val: int = int(game.state.seed) ^ (int(game.state.day) * 2654435761) ^ (record.incidents.size() * 40503) ^ int(place.hash())
	return {
		"seed": seed_val,
		"venue_kind": venue_kind,
		"place": place,
		"place_name": place_title,
		"reason": reason,
		"command": command,
		"bullets": int(game.state.bullets),
		"squad": squad,
		"enemies": enemies,
	}


func _actor_profile(game, uid: String) -> Dictionary:
	var h := absi(int(uid.hash()))
	return {
		"appearance": preload("res://simulation/traveler_appearance.gd").generate(int(game.state.seed), h)
	}


func apply_tactical_result(game, session: Dictionary) -> void:
	var current := incident()
	if current.is_empty():
		return
	var place: String = String(current.get("place", target(game)))
	var scene: Dictionary = rules(place)
	var outcome: String = String(session.get("outcome", "retreated"))
	var reason: String = String(session.get("reason", "resisted"))
	var day := int(game.state.day)

	# 1. Sync ammunition spent.
	var fired := maxi(0, int(session.get("shots_fired", 0)))
	var base_shot: int = 1 if String(current.get("action", "")) == "shoot" else 0
	var min_spent: int = maxi(fired, base_shot)
	game.state.bullets = maxi(0, mini(int(session.get("bullets_left", game.state.bullets)), int(game.state.bullets) - min_spent))

	# 2. Apply squad health & gunshot wound / fracture conditions into party_health.
	for u in session.get("units", []):
		if String(u.get("team", "")) != "player":
			continue
		var slot := int(str(u.get("id", "0")))
		if slot < 0 or slot >= game.party_health.members.size():
			continue
		var member: Dictionary = game.party_health.members[slot]
		if not game.party_health.is_active(member):
			continue
		var new_hp := clampi(int(u.get("health", member.health)), 0, 100)
		var delta := new_hp - int(member.health)
		if new_hp <= 0:
			game.party_health.kill(member, day, "gunshot wounds at " + String(session.get("place_name", place)))
			continue
		if delta < 0:
			member.health = new_hp
			member.history.append("Day %d · Hit by gunfire at %s." % [day, String(session.get("place_name", place))])
		if int(u.get("wounds_taken", 0)) > 0:
			var sev := clampi(int(u.get("wound_severity", 2)), 1, 3)
			if not game.party_health.begin_condition(slot, "wound", day, sev):
				for active in member.conditions:
					if active.id == "wound":
						active.severity = maxi(int(active.severity), sev)
		if bool(u.get("new_broken_leg", false)):
			game.party_health.begin_condition(slot, "broken_leg", day, 2)
		if bool(u.get("new_broken_arm", false)):
			game.party_health.begin_condition(slot, "broken_arm", day, 2)

	game._collect_health_events()
	if not game.party_health.members.is_empty():
		game.state.health = game.party_health.average_health()
		game.state.party_size = game.party_health.living_count()
	game._check_health()

	# 3. Apply enemy actor health & witness/kill bookkeeping while respecting save validator bounds.
	var is_wanted_act: bool = String(current.get("action", "")) == "wanted"
	var is_fort_like: bool = String(scene.get("kind", "")) in ["fort", "pursuers", "household", "jail"]
	var max_breakout_shots: int = int(scene.get("breakout_shots", 0)) if is_fort_like else 0
	var max_kills_allowed: int = max_breakout_shots if is_wanted_act else 99

	var kills_added := 0
	for u in session.get("units", []):
		if String(u.get("team", "")) != "enemy":
			continue
		var uid := String(u.get("uid", u.get("id", "")))
		if not record.actors.has(uid):
			continue
		var act: Dictionary = record.actors[uid]
		var yielded := bool(u.get("yielded", false)) or bool(u.get("surrendered", false))
		var hp := clampi(int(u.get("health", act.health)), 0, 100)
		if yielded and hp <= 0:
			hp = maxi(1, int(act.health))
		if hp == 0 and kills_added >= max_kills_allowed:
			hp = maxi(1, mini(int(act.health), 10))
		act.health = hp
		u["health"] = hp
		u["yielded"] = yielded
		u["surrendered"] = yielded
		if hp == 0 and not yielded:
			kills_added += 1
			current.knowledge.erase(uid)
			if not current.has("kills"):
				current["kills"] = []
			if uid not in current.kills:
				current.kills.append(uid)

	var kill_floor: int = mini(current.get("kills", []).size(), max_breakout_shots)
	if is_wanted_act:
		current.shots = clampi(maxi(fired, kill_floor), 0, max_breakout_shots)
	elif reason == "breakout" or String(current.get("action", "")) == "pursuit":
		var extra := clampi(maxi(fired, kill_floor), 0, max_breakout_shots)
		current.shots = base_shot + extra
	else:
		current.shots = base_shot

	var target_uid := String(current.get("target", owner_id(place)))
	var keeper := actor(place, target_uid)
	var any_killed: bool = int(keeper.health) == 0 or not current.get("kills", []).is_empty()
	if String(current.get("action", "")) == "shoot" or Detention.jailbreak_incident(self, current):
		if int(keeper.health) == 0:
			current.knowledge.erase(target_uid)
			current.attempt = "killed"
		else:
			current.attempt = "wounded" if int(keeper.health) < 100 else "missed"
	elif String(current.get("action", "")) == "robbery":
		if int(keeper.health) == 0:
			current.attempt = "killed"
		elif outcome == "victory":
			current.attempt = "resisted" if any_killed else "complied"

	# 4. Advance day for breakout and settle incident stage/outcome.
	if reason == "breakout":
		if not advance(game):
			return
	if game.state.status != "traveling":
		result(game, "party_lost")
		return

	if outcome == "victory":
		if reason == "breakout" or String(current.get("action", "")) in ["pursuit", "wanted"]:
			if Detention.jailbreak_incident(self, current):Detention.recover_arms(self, game, current)
			observe(game, current, "escape", true)
			result(game, "escaped")
		elif String(current.get("action", "")) == "shoot":
			current.stage = ("loot" if target_uid == owner_id(place) else "escape") if int(keeper.health) == 0 else "escape"
			game.pending = menu(game)
		elif String(current.get("action", "")) == "robbery":
			current.stage = "loot"
			game.pending = menu(game)
		else:
			observe(game, current, "escape", true)
			result(game, "escaped")
	elif outcome == "retreated":
		# Pulling back from the fight is still an escape attempt, with the scene's usual odds of capture.
		if current.stage == "standoff" and String(current.get("action", "")) != "pursuit":
			var edge: float = float(odds(game, place, "murder" if String(current.get("action", "")) in ["shoot", "assault"] else "robbery").edge)
			var chance: float = bounded(float(scene.breakout), float(scene.breakout) + edge, float(modifiers.floor), float(modifiers.ceiling))
			if rng.randf() >= chance:
				result(game, "captured")
				return
			observe(game, current, "escape", true)
			result(game, "escaped")
		else:
			if current.stage != "standoff":
				current.stage = "escape"
			if not choose(game, "flee"):
				observe(game, current, "escape", true)
				result(game, "escaped")
	elif outcome == "surrendered":
		result(game, "surrendered")
	else:
		result(game, "captured")
	Remains.sync(game)
	# The panel underneath the fight shows where the incident now stands.
	if game.state.status == "traveling" and not incident().is_empty():
		game.pending = menu(game)

